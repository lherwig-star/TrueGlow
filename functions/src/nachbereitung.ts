import { type Ausrichtung } from './ausrichtung';
import {
  techniklabels,
  ZIELKAPITEL,
  type Modul,
  type Techniknamen,
} from './labels';
import { SPRACHEN, type Sprache } from './sprache';

/**
 * Was zwischen der Modellantwort und dem Client passiert.
 *
 * Der Prompt sagt dem Modell, was es liefern soll. Das ist eine Bitte, keine
 * Zusicherung: Ein Sprachmodell kann eine Anweisung ueberlesen, und beim
 * Bart ist der Schaden nicht kosmetisch – im weiblichen Modus steht dann ein
 * Kapitel im Report, das dort nichts zu suchen hat.
 *
 * Deshalb wird die Antwort hier nachgesehen. Zwei Dinge passieren:
 *
 *  1. **Ausgesiebt** wird, was gegen die Auswahl verstoesst – fremde Module,
 *     und im weiblichen Modus alles, was von Bart oder Rasur handelt.
 *  2. **Gemeldet** wird, wenn der Report offenbar in der falschen Sprache
 *     zurueckkommt, wenn das Zielkapitel fehlt, obwohl der Nutzer etwas
 *     geschrieben hat, wenn eine ausdruecklich gewaehlte Technik nirgends
 *     auftaucht, und wenn Tagesaufgaben zurueckkommen, die auch ohne die
 *     Fotos dagestanden haetten. Aussieben laesst sich nichts davon; ein
 *     Protokolleintrag sorgt wenigstens dafuer, dass es auffaellt, statt
 *     still beim Nutzer zu landen.
 */

/** Woran ein Bart-Abschnitt zu erkennen ist. */
const BART = /\b(bart|bärte|barts|beard|bartpflege|rasur|rasier|shav)/i;

/**
 * Tagesaufgaben, die auch ohne die Fotos dagestanden haetten.
 *
 * Bewusst nur **ganze** Aufgaben: "Gesicht waschen" ist ein Gemeinplatz,
 * "Morgens vor dem Rasieren mit lauwarmem Wasser waschen" nicht. Deshalb
 * steht in jedem Ausdruck ein Anker vorn und hinten – ein Treffer heisst,
 * dass die Aufgabe aus nichts als dem Gemeinplatz besteht.
 *
 * Die Liste findet nur, was jemand vorhergesehen hat, und ist damit keine
 * Qualitaetsmessung. Sie ist ein Zaehlwerk: Wir wollen sehen, wie oft so
 * etwas noch durchkommt, seit der Prompt Tiefe verlangt (DECISIONS 40).
 */
const FLOSKELN: RegExp[] = [
  /^(das )?gesicht (waschen|reinigen)$/,
  /^(gesicht |haut )?eincremen$/,
  /^(mehr |genug |ausreichend )?wasser trinken$/,
  /^(genug|ausreichend|mehr) schlafen$/,
  /^zähne putzen$/,
  /^sonnencreme (auftragen|benutzen)$/,
  /^wash (your )?face$/,
  /^(apply )?moisturi[sz]er?$/,
  /^drink (more |enough )?water$/,
  /^get (more |enough )?sleep$/,
  /^brush (your )?teeth$/,
  /^(apply |wear )?sunscreen$/,
];

/** Ob eine Aufgabe aus nichts als einem Gemeinplatz besteht. */
export function istFloskel(habit: string): boolean {
  const rein = habit
    .toLowerCase()
    .replace(/[.!]+$/, '')
    .replace(/\s+/g, ' ')
    .trim();
  return FLOSKELN.some((muster) => muster.test(rein));
}

/**
 * Was in keiner Antwort stehen darf – und wonach sich zuverlaessig suchen
 * laesst.
 *
 * **Warum die Liste so kurz ist.** Sie entscheidet ueber das Verwerfen einer
 * fertigen, bezahlten Antwort. Ein Fehlalarm kostet den Nutzer eine seiner
 * zehn Analysen im Monat – deshalb steht hier nur, was ohne jeden Kontext
 * eindeutig ist:
 *
 * - `8/10` mit Schraegstrich ist eine Bewertungszahl und sonst nichts.
 * - „Score: 7" und „Note: 3" ebenso.
 * - „1200 kcal" ist eine Kalorienvorgabe.
 *
 * Bewusst **nicht** hier: „von 10", weil „an 3 von 10 Tagen" ein voellig
 * normaler Satz in einem Plan ist. Und keine Diagnosewoerter: „Rosazea" kann
 * genauso gut in „das gehoert dermatologisch abgeklaert" stehen, und genau
 * das soll der Report ja sagen duerfen.
 *
 * Was diese Liste nicht faengt, faengt der Prompt – dreimal, zuletzt in den
 * Schlussregeln nach allen Nutzerdaten (SECURITY_AUDIT D1/D2).
 */
const VERBOTEN: { name: string; muster: RegExp }[] = [
  { name: 'Bewertungszahl', muster: /\b\d{1,2}\s*\/\s*10\b/ },
  { name: 'Score', muster: /\b(?:score|rating|bewertung)\s*[:=]\s*\d/i },
  { name: 'Note', muster: /\bnote\s*[:=]\s*[1-6]\b/i },
  {
    name: 'Kalorienvorgabe',
    muster: /\b\d{3,4}\s*(?:kcal|kalorien|calories)\b/i,
  },
];

/**
 * Sucht verbotene Inhalte in der gesamten Antwort.
 *
 * Liefert die Namen der Treffer, jeweils mit dem Fundstueck – leer heisst
 * sauber. Der Aufrufer entscheidet, was damit passiert; bei Analyse und
 * Check-in ist das: verwerfen und einen zweiten Versuch starten
 * (siehe `index.ts`).
 */
export function verboteneInhalte(json: Record<string, unknown>): string[] {
  const funde: string[] = [];
  const probe = alleTexte(json);

  for (const { name, muster } of VERBOTEN) {
    const treffer = probe.match(muster);
    if (treffer !== null) funde.push(`${name}: "${kurz(treffer[0])}"`);
  }
  return funde;
}

/** Alle Zeichenketten der Antwort, aneinandergehaengt. */
function alleTexte(wert: unknown, tiefe = 0): string {
  if (tiefe > 8) return '';
  if (typeof wert === 'string') return ` ${wert}`;
  if (Array.isArray(wert)) {
    return wert.map((e) => alleTexte(e, tiefe + 1)).join('');
  }
  if (wert !== null && typeof wert === 'object') {
    return Object.values(wert)
      .map((e) => alleTexte(e, tiefe + 1))
      .join('');
  }
  return '';
}

/** Ergebnis der Nachbereitung, fuer Protokoll und Tests. */
export interface Nachbereitet {
  ergebnis: Record<string, unknown>;
  /** Kapitel, die gar nicht angefordert waren. */
  fremdeKapitel: string[];
  /** Entfernte Sektionsueberschriften. */
  entfernteSektionen: string[];
  /** Entfernte Tagesaufgaben. */
  entfernteHabits: number;
  /** Tagesaufgaben, die nichts als ein Gemeinplatz sind. Nur gezaehlt. */
  floskeln: string[];
  /** Das Zielkapitel fehlt, obwohl der Nutzer etwas geschrieben hat. */
  zielkapitelFehlt: boolean;
  /** Die geschaetzte Sprache, wenn sie nicht der Zielsprache entspricht. */
  falscheSprache?: Sprache;
  /** Namen, die in einem Kapitel stehen und schon im Gesamtbild vorkommen. */
  doppelteNamen: string[];
  /** Eintraege in "neu", die keine gewaehlte Technik sind. Entfernt. */
  erfundeneMarken: string[];
  /** Gewaehlte Techniken, die im Report nirgends markiert sind. */
  fehlendeTechniken: string[];
}

export function nachbereiten(
  roh: Record<string, unknown>,
  vorgabe: {
    sprache: Sprache;
    ausrichtung: Ausrichtung;
    module: Modul[];
    richtung?: { freitext: string };
    techniken?: readonly Techniknamen[];
  },
): Nachbereitet {
  // Das Zielkapitel steht in keiner Modulauswahl – es haengt am Freitext.
  // Ohne Freitext ist es ein Kapitel, das niemand angefordert hat, und
  // faellt unten mit den fremden heraus.
  const mitZielkapitel = (vorgabe.richtung?.freitext ?? '').trim().length > 0;
  const erlaubt = new Set<string>(vorgabe.module);
  if (mitZielkapitel) erlaubt.add(ZIELKAPITEL);
  const ohneBart = vorgabe.ausrichtung === 'weiblich';

  const fremdeKapitel: string[] = [];
  const entfernteSektionen: string[] = [];
  let entfernteHabits = 0;

  const kapitel: unknown[] = [];
  for (const eintrag of liste(roh.kapitel)) {
    const k = objekt(eintrag);
    const modul = typeof k.modul === 'string' ? k.modul : '';

    // Ein Kapitel, das niemand angefordert hat, faellt weg. Das trifft im
    // maennlichen Modus auch ein Make-up-Kapitel – nicht nur den Bart.
    if (!erlaubt.has(modul)) {
      fremdeKapitel.push(modul || '(ohne Modul)');
      continue;
    }

    if (ohneBart) {
      const sektionen = liste(k.sektionen).filter((s) => {
        const titel = text(objekt(s).titel);
        if (!BART.test(titel)) return true;
        entfernteSektionen.push(titel);
        return false;
      });

      const habits = liste(k.habits).filter((h) => {
        if (typeof h !== 'string' || !BART.test(h)) return true;
        entfernteHabits += 1;
        return false;
      });

      // Ein Kapitel ohne jede Sektion ist keins mehr. Das kann nur
      // passieren, wenn das Modell die Basis komplett zum Bart-Kapitel
      // gemacht hat – dann ist der Rest ohnehin nicht zu retten.
      if (sektionen.length === 0) {
        fremdeKapitel.push(modul);
        continue;
      }

      kapitel.push({ ...k, sektionen, habits });
      continue;
    }

    kapitel.push(k);
  }

  // Die Marken zum Schluss und in einem eigenen Durchgang: So werden sie in
  // jedem Zweig gleich behandelt – auch in dem, der oben schon Sektionen
  // entfernt hat.
  const gewaehlt = techniklabels(vorgabe.techniken ?? [], vorgabe.sprache);
  const bekannteMarken = new Map(
    gewaehlt.map((label) => [schluessel(label), label]),
  );
  const erfundeneMarken: string[] = [];
  const markiert = new Set<string>();

  const gesaeubert = kapitel.map((eintrag) => {
    const k = objekt(eintrag);
    const sektionen = liste(k.sektionen).map((roheSektion) => {
      const sektion = { ...objekt(roheSektion) };
      sektion.produkte = ohneLinks(sektion.produkte);
      if (sektion.neu === undefined) return sektion;

      const behalten: string[] = [];
      for (const gegeben of liste(sektion.neu)) {
        // Auf die kanonische Schreibweise zurueckgefuehrt: Das Modell
        // schreibt „gua sha" statt „Gua Sha", und die App erkennt den Namen
        // sonst nicht wieder.
        const treffer =
          typeof gegeben === 'string'
            ? bekannteMarken.get(schluessel(gegeben))
            : undefined;
        if (treffer === undefined) {
          // Eine Marke, die keine gewaehlte Technik ist, waere im Report
          // eine Behauptung: „Neu fuer dich" an etwas, das der Nutzer nie
          // angetippt hat. Sie faellt weg.
          erfundeneMarken.push(kurz(gegeben));
          continue;
        }
        if (!behalten.includes(treffer)) behalten.push(treffer);
        markiert.add(treffer);
      }

      if (behalten.length === 0) {
        delete sektion.neu;
        return sektion;
      }
      sektion.neu = behalten;
      return sektion;
    });
    return { ...k, sektionen };
  });

  const ergebnis: Record<string, unknown> = { ...roh, kapitel: gesaeubert };

  if (ohneBart && ergebnis.plan !== undefined) {
    ergebnis.plan = planOhneBart(ergebnis.plan);
  }

  const doppelteNamen = namenImGesamtbild(ergebnis);

  const geschaetzt = spracheSchaetzen(textprobe(ergebnis));

  return {
    ergebnis,
    fremdeKapitel,
    entfernteSektionen,
    entfernteHabits,
    doppelteNamen,
    erfundeneMarken,
    fehlendeTechniken: gewaehlt.filter((label) => !markiert.has(label)),
    floskeln: alleHabits(kapitel).filter(istFloskel),
    zielkapitelFehlt:
      mitZielkapitel &&
      !kapitel.some((k) => objekt(k).modul === ZIELKAPITEL),
    falscheSprache:
      geschaetzt !== undefined && geschaetzt !== vorgabe.sprache
        ? geschaetzt
        : undefined,
  };
}

/** Schreibt in die Logs, was aufgefallen ist. Ohne Fund passiert nichts. */
export function melde(befund: Nachbereitet, vorgabe: { sprache: Sprache }): void {
  if (befund.fremdeKapitel.length > 0) {
    console.warn(
      'Nachbereitung: nicht angeforderte Kapitel entfernt ' +
        `(${befund.fremdeKapitel.join(', ')})`,
    );
  }
  if (befund.entfernteSektionen.length > 0) {
    console.warn(
      'Nachbereitung: Bart-Sektionen im weiblichen Modus entfernt ' +
        `(${befund.entfernteSektionen.join(', ')})`,
    );
  }
  if (befund.entfernteHabits > 0) {
    console.warn(
      `Nachbereitung: ${befund.entfernteHabits} Bart-Aufgaben entfernt`,
    );
  }
  if (befund.zielkapitelFehlt) {
    console.warn(
      'Nachbereitung: Der Nutzer hat einen Freitext geschrieben, das ' +
        `Kapitel "${ZIELKAPITEL}" fehlt aber im Report. Seine Wuensche ` +
        'stehen dann nirgends in der Tagesliste.',
    );
  }
  if (befund.doppelteNamen.length > 0) {
    // Bewusst nur gemeldet, nicht repariert: Ein Name laesst sich aus einem
    // Fliesstext nicht herausschneiden, ohne den Satz zu zerstoeren. Die
    // Zahl sagt uns, ob die Prompt-Regel wirkt (DECISIONS 67).
    console.warn(
      'Nachbereitung: Diese Namen stehen im Gesamtbild UND im Kapitel – das ' +
        `Gesamtbild soll sie nicht nennen (${befund.doppelteNamen.join(', ')})`,
    );
  }
  if (befund.erfundeneMarken.length > 0) {
    // Nur gemeldet, weil das Aussieben schon passiert ist: Die Sektion zeigt
    // dann keine Marke, der Report bleibt vollstaendig.
    console.warn(
      'Nachbereitung: erfundene „Neu fuer dich"-Marken entfernt ' +
        `(${befund.erfundeneMarken.join(' | ')})`,
    );
  }
  if (befund.fehlendeTechniken.length > 0) {
    // Das ist der Fund, der wirklich beim Nutzer ankommt: Er hat eine
    // Technik ausdruecklich angetippt und findet sie im Report nicht
    // wieder. Reparieren laesst sich das nicht – eine Empfehlung, die das
    // Modell nicht geschrieben hat, koennen wir nicht nachtragen
    // (DECISIONS 80).
    console.warn(
      'Nachbereitung: gewaehlte Techniken fehlen im Report ' +
        `(${befund.fehlendeTechniken.join(', ')})`,
    );
  }
  if (befund.floskeln.length > 0) {
    // Bewusst nur gezaehlt, nicht entfernt: Eine Aufgabe faellt hier
    // ersatzlos weg, und eine Checkliste mit zwei Punkten ist schlechter als
    // eine mit einem flachen darin. Die Zahl sagt uns, ob der Prompt wirkt.
    console.warn(
      `Nachbereitung: ${befund.floskeln.length} Tagesaufgaben ohne Bezug ` +
        `zu den Fotos (${befund.floskeln.join(', ')})`,
    );
  }
  if (befund.falscheSprache !== undefined) {
    console.error(
      `Nachbereitung: Report kam offenbar auf "${befund.falscheSprache}" ` +
        `zurueck, angefordert war "${vorgabe.sprache}". Der Report geht ` +
        'trotzdem raus – abweisen hiesse, dem Nutzer fuer sein Kontingent ' +
        'gar nichts zu geben.',
    );
  }
}

/**
 * Grobe Spracherkennung ueber Funktionswoerter.
 *
 * Bewusst klein gehalten: Sie muss nicht Franzoesisch von Spanisch
 * unterscheiden, sondern nur merken, ob ein Report, der englisch sein
 * sollte, durchgehend deutsch ist. Dafuer reichen Woerter, die in jedem
 * laengeren Text vorkommen und die es in der jeweils anderen Sprache nicht
 * gibt.
 *
 * Gibt `undefined` zurueck, wenn die Probe zu kurz ist oder beide Sprachen
 * gleichauf liegen – lieber nichts sagen als etwas Falsches melden.
 */
export function spracheSchaetzen(probe: string): Sprache | undefined {
  const treffer: Record<Sprache, number> = { de: 0, en: 0 };
  const woerter: Record<Sprache, RegExp> = {
    de: /\b(und|oder|nicht|dein|deine|dich|mit|ist|sind|wird|noch|auch|dass|eine|einen|schon|beim|zum|zur)\b/gi,
    en: /\b(and|the|your|you|with|is|are|will|not|that|this|for|from|into|about|keep|make)\b/gi,
  };

  for (const sprache of SPRACHEN) {
    treffer[sprache] = probe.match(woerter[sprache])?.length ?? 0;
  }

  const gesamt = treffer.de + treffer.en;
  if (gesamt < 12) return undefined;

  // Ein deutlicher Abstand, nicht ein knapper Vorsprung: Fachbegriffe und
  // Produktnamen wandern zwischen den Sprachen, „Make-up" und „Look" stehen
  // auch in einem deutschen Report.
  if (treffer.de >= treffer.en * 2) return 'de';
  if (treffer.en >= treffer.de * 2) return 'en';
  return undefined;
}

// --- Bausteine ---------------------------------------------------------

/** Sammelt die Textfelder, auf denen die Spracherkennung arbeitet. */
function textprobe(ergebnis: Record<string, unknown>): string {
  const teile: string[] = [];

  const sammle = (wert: unknown, tiefe: number): void => {
    if (tiefe > 6) return;
    if (typeof wert === 'string') {
      teile.push(wert);
    } else if (Array.isArray(wert)) {
      for (const eintrag of wert) sammle(eintrag, tiefe + 1);
    } else if (wert !== null && typeof wert === 'object') {
      for (const [schluessel, eintrag] of Object.entries(wert)) {
        // Modulbezeichner sind Kennungen, keine Sprache.
        if (schluessel === 'modul' || schluessel === 'affiliateUrl') continue;
        sammle(eintrag, tiefe + 1);
      }
    }
  };

  // Der Einstiegstext des entdeckenden Modus gehoert dazu: Er ist der erste
  // Satz, den jemand liest, und faellt sonst durch die Sprachpruefung.
  sammle(ergebnis.gesamtbild, 0);
  sammle(ergebnis.kapitel, 0);
  sammle(ergebnis.plan, 0);
  return teile.join(' ');
}

function planOhneBart(roh: unknown): unknown {
  const plan = objekt(roh);
  const gefiltert: Record<string, unknown> = {};
  for (const [schluessel, wert] of Object.entries(plan)) {
    gefiltert[schluessel] = Array.isArray(wert)
      ? wert.filter((e) => typeof e !== 'string' || !BART.test(e))
      : wert;
  }
  return gefiltert;
}

/** Alle Tagesaufgaben ueber alle Kapitel – Grundlage der Floskel-Zaehlung. */
function alleHabits(kapitel: unknown[]): string[] {
  return kapitel.flatMap((k) =>
    liste(objekt(k).habits).filter((h): h is string => typeof h === 'string'),
  );
}

/**
 * Nimmt jedem Produkt seinen Link.
 *
 * Das Feld `affiliateUrl` gehoert der Struktur, nicht dem Modell: Der Prompt
 * verlangt dort `null`, und angezeigt wird es ohnehin nirgends. Solange das
 * so ist, kostet es nichts, es hier hart zu setzen — und sobald daraus ein
 * anklickbarer Link wird, ist es keine Adresse, die ein Sprachmodell
 * erfunden hat (SECURITY_AUDIT D2).
 *
 * Kommen die Links eines Tages von uns, gehoert die Zeile hier ersetzt durch
 * eine Pruefung gegen die eigene Partnerliste — nicht durch Vertrauen.
 */
function ohneLinks(roh: unknown): unknown[] {
  return liste(roh).map((p) => ({ ...objekt(p), affiliateUrl: null }));
}

/** Fuer den Vergleich von Namen: klein, ohne doppelte Leerzeichen. */
function schluessel(text: string): string {
  return text.toLowerCase().replace(/\s+/g, ' ').trim();
}

/** Fuer die Logzeile: lang genug zum Erkennen, kurz genug fuer eine Zeile. */
function kurz(wert: unknown): string {
  const text = typeof wert === 'string' ? wert : JSON.stringify(wert);
  return text.length > 60 ? `${text.slice(0, 57)}...` : text;
}

function liste(roh: unknown): unknown[] {
  return Array.isArray(roh) ? roh : [];
}

function objekt(roh: unknown): Record<string, unknown> {
  return roh !== null && typeof roh === 'object' && !Array.isArray(roh)
    ? (roh as Record<string, unknown>)
    : {};
}

function text(roh: unknown): string {
  return typeof roh === 'string' ? roh : '';
}


/**
 * Namen, die das Gesamtbild schon nennt, obwohl sie ins Kapitel gehoeren.
 *
 * Der Anlass steht in DECISIONS 67: Die Karte ganz oben zaehlte die
 * konkreten Vorschlaege auf, und die Kapitel wiederholten sie.
 *
 * **Was hier erkannt wird und was nicht.** Gesucht werden Eigennamen – zwei
 * oder drei grossgeschriebene Woerter hintereinander, mitten im Satz. Das
 * trifft "Textured Crop", "Modern Mullet" oder "Smart Casual" und verfehlt
 * "kuerzere Seiten": Eine Umschreibung ist keine Doppelung im Sinne der
 * Regel, sondern hoechstens eine Unschoenheit. Bei freiem Text geht es nicht
 * genauer, und die Hauptarbeit leistet ohnehin der Prompt.
 *
 * Satzanfaenge fallen heraus – im Deutschen steht dort jedes Wort gross, und
 * "Deine Kieferlinie" waere sonst ein Treffer.
 */
function namenImGesamtbild(ergebnis: Record<string, unknown>): string[] {
  const gesamtbild = text(ergebnis.gesamtbild);
  if (gesamtbild.length === 0) return [];

  const ausKapiteln = new Set<string>();
  for (const eintrag of liste(ergebnis.kapitel)) {
    for (const s of liste(objekt(eintrag).sektionen)) {
      const sektion = objekt(s);
      for (const feld of [
        text(sektion.titel),
        text(sektion.einschaetzung),
        ...textliste(sektion.empfehlungen),
      ]) {
        for (const name of eigennamen(feld)) ausKapiteln.add(name);
      }
    }
  }

  return [...ausKapiteln].filter((name) => gesamtbild.includes(name)).sort();
}

/**
 * Zwei bis drei grossgeschriebene Woerter am Stueck, nicht am Satzanfang.
 *
 * Bewusst ohne regulaeren Ausdruck: Das Muster braeuchte Umlaut-Klassen und
 * eine Ausnahme fuer den Satzanfang, und beides ist als Zeichenkette
 * schwerer zu lesen als die Schleife darunter.
 */
function eigennamen(satz: string): string[] {
  const gross = (w: string) => w.length > 0 && w[0] === w[0].toUpperCase()
      && w[0] !== w[0].toLowerCase();

  const treffer: string[] = [];
  const woerter = satz.split(/\s+/);
  let satzanfang = true;
  let lauf: string[] = [];

  const abschliessen = () => {
    // Zwei bis drei Woerter – ein einzelnes waere im Deutschen jedes
    // Substantiv, vier hintereinander ist kein Name mehr.
    if (lauf.length >= 2) {
      for (let laenge = 2; laenge <= Math.min(3, lauf.length); laenge += 1) {
        for (let i = 0; i + laenge <= lauf.length; i += 1) {
          treffer.push(lauf.slice(i, i + laenge).join(' '));
        }
      }
    }
    lauf = [];
  };

  for (const roh of woerter) {
    const wort = roh.replace(/^[(„"'»–-]+/u, '');
    const rein = wort.replace(/[.,;:!?)”"'«]+$/u, '');
    const satzende = /[.!?:]$/u.test(wort);

    if (!satzanfang && rein.length > 1 && gross(rein)) {
      lauf.push(rein);
    } else {
      abschliessen();
    }

    satzanfang = satzende;
    if (satzende) abschliessen();
  }
  abschliessen();

  return treffer;
}

/** Eine Liste von Texten, leere Eintraege fallen weg. */
function textliste(roh: unknown): string[] {
  return Array.isArray(roh) ? roh.map(text).filter((s) => s.length > 0) : [];
}
