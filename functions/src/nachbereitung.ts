import { type Ausrichtung } from './ausrichtung';
import { type Modul } from './labels';
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
 *     zurueckkommt. Aussieben laesst sich das nicht; ein Protokolleintrag
 *     sorgt wenigstens dafuer, dass es auffaellt, statt still beim Nutzer zu
 *     landen.
 */

/** Woran ein Bart-Abschnitt zu erkennen ist. */
const BART = /\b(bart|bärte|barts|beard|bartpflege|rasur|rasier|shav)/i;

/** Ergebnis der Nachbereitung, fuer Protokoll und Tests. */
export interface Nachbereitet {
  ergebnis: Record<string, unknown>;
  /** Kapitel, die gar nicht angefordert waren. */
  fremdeKapitel: string[];
  /** Entfernte Sektionsueberschriften. */
  entfernteSektionen: string[];
  /** Entfernte Tagesaufgaben. */
  entfernteHabits: number;
  /** Die geschaetzte Sprache, wenn sie nicht der Zielsprache entspricht. */
  falscheSprache?: Sprache;
}

export function nachbereiten(
  roh: Record<string, unknown>,
  vorgabe: { sprache: Sprache; ausrichtung: Ausrichtung; module: Modul[] },
): Nachbereitet {
  const erlaubt = new Set<string>(vorgabe.module);
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

  const ergebnis: Record<string, unknown> = { ...roh, kapitel };

  if (ohneBart && ergebnis.plan !== undefined) {
    ergebnis.plan = planOhneBart(ergebnis.plan);
  }

  const geschaetzt = spracheSchaetzen(textprobe(ergebnis));

  return {
    ergebnis,
    fremdeKapitel,
    entfernteSektionen,
    entfernteHabits,
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
