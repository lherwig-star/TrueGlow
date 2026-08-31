import {
  ALTER,
  AUFNAHMEN,
  BUDGET,
  ALLTAGSZWECK,
  FOKUS,
  KLEIDUNGSBUDGET,
  MODULE,
  ankerListe,
  kapitelUeberschrift,
  PFLEGEAUFWAND,
  PRODUKTKATEGORIEN,
  sektion,
  RICHTUNGSVORGABE,
  RICHTUNGSZIEL,
  TECHNIK,
  wochenankerListe,
  type Techniknamen,
  ZEIT,
  ZIELKAPITEL,
  label,
  labels,
  type Modul,
} from './labels';
import {
  AUSGABESPRACHE,
  AUSGABESPRACHE_KURZ,
  type Sprache,
} from './sprache';
import { kontextzeile, type Ausrichtung } from './ausrichtung';
import {
  datenblock,
  datenblockRegel,
  neueMarke,
  SCHLUSSREGELN,
} from './nutzertext';
import {
  auftrag,
  entdeckenRegeln,
  gesamtbildRegeln,
  kapitelZusatz,
  planRegeln,
  type Modus,
} from './modus';

/**
 * Der System-Prompt der Analyse.
 *
 * Portierung von `lib/features/analysis/logic/analysis_prompt.dart`. Der
 * Prompt liegt bewusst auf dem Server: Er ist der inhaltlich heikelste Teil
 * der App, enthaelt saemtliche Leitplanken (keine Scores, keine Diagnosen,
 * kein Attraktivitaetsurteil) und soll weder im APK lesbar noch vom Client
 * veraenderbar sein.
 */

/** Angaben der Person, wie sie der Client schickt: ausschliesslich Enum-Namen. */
export interface Profilangaben {
  alter?: string;
  budget?: string;
  zeit?: string;
  fokus: string[];
}

export interface Figurangaben {
  groesseCm?: number;
  gewichtKg?: number;
}

export interface Stilangaben {
  /** Stilrichtungen – dieselben Namen wie bei der Richtung. */
  ziele: string[];
  /** Wofuer der Stil funktionieren soll. Darf leer sein. */
  zwecke: string[];
  budget?: string;
  pflegeaufwand?: string;
}

export interface Richtungsangaben {
  ziele: string[];
  freitext: string;
}

export interface AnalysePromptDaten {
  /** In welcher Sprache der Report geschrieben wird. */
  sprache: Sprache;
  /**
   * Die Marke des Datenblocks, in dem der Freitext des Nutzers steht.
   *
   * Kommt aus `leseAnalyse` und ist pro Anfrage zufaellig. Fehlt sie, wird
   * hier eine erzeugt: Eine vergessene Marke darf nie „gar keine Marke"
   * heissen (SECURITY_AUDIT D1).
   */
  marke?: string;
  /** Wonach die Empfehlungen ausgerichtet werden. */
  ausrichtung: Ausrichtung;
  /** Ob der vorhandene Look verbessert oder ein neuer entworfen wird. */
  modus: Modus;
  module: Modul[];
  profil: Profilangaben;
  figur: Figurangaben;
  stil: Stilangaben;
  richtung: Richtungsangaben;
  /** Was der Nutzer ausprobieren will – bereits gefiltert (DECISIONS 79). */
  techniken: Techniknamen[];
}

/** Nachfassen, wenn die erste Antwort kein gueltiges JSON war. */
export const JSON_NACHFASSEN =
  'Deine letzte Antwort war kein gültiges JSON. Antworte nur mit validem ' +
  'JSON nach dem vorgegebenen Schema – ohne Erklärung, ohne Markdown-' +
  'Codefences.';

export function systemPrompt(daten: AnalysePromptDaten): string {
  // Reihenfolge der Deklaration, damit Prompt und Report gleich sortiert sind.
  const bestellt = MODULE.filter(
    (m) => m !== ZIELKAPITEL && daten.module.includes(m),
  );
  // Das Zielkapitel bestellt niemand – es entsteht, sobald im Freitextfeld
  // etwas steht, und faellt sonst weg. Es steht am Ende, weil die
  // Look-Kapitel den Report tragen.
  const gewaehlt = hatFreitext(daten.richtung)
    ? [...bestellt, ZIELKAPITEL]
    : bestellt;
  const sprache = daten.sprache;
  const ausrichtung = daten.ausrichtung;
  const entdecken = daten.modus === 'entdecken';
  const marke = daten.marke ?? neueMarke();

  return `Du bist ein erfahrener, freundlicher Styling- und Grooming-Coach. Du siehst
mehrere Fotos derselben Person.

${kontextzeile(ausrichtung, sprache)}

${kontext(daten, gewaehlt)}
${ziele(daten.richtung, sprache, marke)}
${auftrag(daten.modus)}

Verbindliche Regeln:
- Vergib KEINE Bewertungszahlen, Scores, Noten oder Rankings. Kein "7/10", kein
  "überdurchschnittlich", kein Vergleich mit anderen Menschen.
- Bewerte nicht die Attraktivität der Person und nicht ihr Gewicht. Beschreibe
  Merkmale neutral und leite daraus ab, was gut dazu passt.
- Stelle KEINE medizinischen Diagnosen. Wenn dir etwas an Haut oder Zähnen
  auffällt, das fachlich abgeklärt gehört, verweise freundlich an eine
  dermatologische bzw. zahnärztliche Praxis.
- Bleib bei dem, was auf den Fotos wirklich zu sehen ist. Rate nicht.
${fotoumfangRegel(gewaehlt)}- Richte Aufwand und Preisniveau der Empfehlungen am Budget und am Zeitbudget
  der Person aus.
- ${AUSGABESPRACHE[sprache]}
- Jede Empfehlung ist ein konkreter Schritt, keine Allgemeinplatitüde.
${zielRegeln(daten.richtung, sprache, marke)}${entdecken ? `
${planRegeln()}` : ''}
${QUALITAET}
${tiefeRegel(bestellt, sprache)}
${gesamtbildRegeln(daten.modus, sprache)}
${ausprobierenRegeln(daten.techniken, sprache)}${entdecken ? `${entdeckenRegeln()}
` : ''}${ankerRegeln(sprache)}
${SCHLUSSREGELN}

Antworte AUSSCHLIESSLICH mit einem JSON-Objekt nach diesem Schema. Kein
Fließtext davor oder danach, keine Markdown-Codefences:

{
  "gesamtbild": "2-4 Sätze: die Richtung als Bild im Kopf, ohne Namen",
  "kapitel": [
    {
      "modul": "${gewaehlt[0]}",
      "kurzfazit": "höchstens 8 Wörter, eine vollständige Aussage",
      "einleitung": "2-3 Sätze als Einstieg ins Kapitel",
      "habits": ["kurze, täglich abhakbare Aufgabe aus DIESEM Kapitel"],
      "sektionen": [
        {
          "titel": "kurzer Bereichsname",
${neuFeld(daten.techniken)}          "einschaetzung": "2-3 Sätze, was auffällt und warum das relevant ist",
          "empfehlungen": ["konkreter Schritt", "konkreter Schritt"],
          "produkte": [
            {
              "name": "Produkttyp oder konkretes Produkt",
              "kategorie": "${PRODUKTKATEGORIEN.join(' | ')}",
              "beschreibung": "wofür und wie anzuwenden",
              "affiliateUrl": null
            }
          ]
        }
      ]
    }
  ],
  "plan": {
    "sofort": ["was heute umsetzbar ist"],
    "dreissigTage": ["was in den ersten 30 Tagen passiert"],
    "langfristig": ["was über Monate wirkt"]
  }
}

Erzeuge GENAU diese Kapitel, in dieser Reihenfolge, und keine weiteren:
${gewaehlt
  .map(
    (m) =>
      kapitelVorgabe(m, ausrichtung, sprache) +
      zusatz(m, daten.modus, sprache),
  )
  .join('\n')}

Vorgaben zum Inhalt:
- "gesamtbild" ist der Einstieg des ganzen Reports. Dafuer gilt die Regel
  weiter oben, und sie ist streng: Wirkung ja, Namen nein.
- "modul" ist exakt einer der genannten Bezeichner – nicht übersetzen.
- "kategorie" ist exakt einer der aufgezählten Bezeichner – kleingeschrieben,
  nicht übersetzen, nichts anderes. Das Wort dazu setzt die App.
- "titel" ist Anzeigetext und steht deshalb in der Zielsprache, genau wie
  jedes andere Textfeld. ${AUSGABESPRACHE_KURZ[sprache]}
- "kurzfazit": die Kernaussage des Kapitels in HÖCHSTENS 8 Wörtern. Es steht
  in der Übersicht unter dem Bereichsnamen, wo nur eine Zeile Platz hat.
  Deshalb: eine **vollständige Aussage**, kein angefangener Satz und kein
  Anfang der Einleitung. Kein Punkt am Ende, keine Anrede, keine Frage.
  So sieht es aus: "Kieferlinie betonen, Bart klar konturieren" oder
  "Warmer Unterton – erdige Töne stehen dir".
  So nicht: "Dein Gesicht zeichnet sich durch eine ausgewogene" – das ist
  ein abgeschnittener Satz und keine Aussage.
- "sektionen": ${entdecken ? 3 : 2} bis ${entdecken ? 5 : 4} pro Kapitel.
- "empfehlungen": 2 bis 4 pro Sektion.
${neuVorgabe(daten.techniken)}
- "produkte": 0 bis 3 pro Sektion, "affiliateUrl" immer null.
- "habits": 4 bis 7 pro Kapitel, jeder unter 80 Zeichen. Jeder Eintrag ist eine
  konkrete Alltagsaufgabe, die sich täglich abhaken lässt, und gehört
  inhaltlich AUSSCHLIESSLICH zu diesem Kapitel. Eine Haltungsübung gehört zu
  "figurPassform", Zahnseide zu "zaehneLaecheln", Sonnenschutz zu
  "hautFarbtyp" – niemals ins falsche Kapitel und niemals in ein Kapitel, das
  hier nicht angefordert wurde.${habitAusnahme(daten.richtung)}
- Formuliere die Habits über alle Kapitel hinweg unterschiedlich, damit sich
  kein Eintrag doppelt.
- "plan" gilt für alle Kapitel zusammen und enthält KEINE Tagesaufgaben.
- ${AUSGABESPRACHE_KURZ[sprache]}
`;
}

/**
 * Nutzer-Nachricht, die die Bilder begleitet – benennt jedes Bild in der
 * Reihenfolge, in der es angehaengt wird.
 */
export function nutzerText(
  reihenfolge: string[],
  sprache: Sprache,
  ausrichtung: Ausrichtung,
): string {
  const liste = reihenfolge
    .map((typ, i) => {
      const eintrag = AUFNAHMEN[typ];
      // `leseAnalyse` laesst nur Typen aus AUFNAHMEN durch, hier kann also
      // regulaer nichts fehlen. Der Rueckfall steht trotzdem: Ein unbekannter
      // Name darf die Nummerierung nicht verschieben, weil sie die Bilder in
      // genau dieser Reihenfolge beschriftet. Ein uebersprungener Eintrag
      // wuerde jedem folgenden Bild die falsche Beschriftung geben.
      return eintrag
        ? `${i + 1}. ${eintrag.label[sprache]} ` +
            `(${kapitelUeberschrift(eintrag.modul, ausrichtung, sprache)})`
        : `${i + 1}. Weiteres Foto`;
    })
    .join('\n');

  return (
    `Hier sind meine Fotos in dieser Reihenfolge:\n${liste}\n\n` +
    'Bitte analysiere sie und antworte im vorgegebenen JSON-Schema.'
  );
}

/**
 * Woran ein guter Report sich messen lassen muss.
 *
 * Der Anlass steht in DECISIONS 40: Ueber mehrere Analysen hinweg kamen
 * Empfehlungen zurueck, die auch ohne die Fotos richtig gewesen waeren –
 * Gesicht waschen, eincremen, Wasser trinken – und Tagesaufgaben, deren
 * Zeitpunkt keinen Sinn ergab. Das Modell hat die Fotos gesehen; es muss nur
 * dazu gebracht werden, sie auch zu benutzen.
 *
 * Drei Forderungen, jede pruefbar an einer einzelnen Zeile des Reports:
 * Beobachtung, Zeitpunkt, Tiefe.
 *
 * Die Beispiele sind bewusst **beschrieben** und nicht als fertiger Satz
 * zitiert. Was der Prompt woertlich nennt, schreibt das Modell woertlich ab
 * (DECISIONS 36) – ein deutsches Musterhabit stuende sonst in einem
 * englischen Report.
 */
const QUALITAET = `Qualität der Empfehlungen – daran wird dieser Report gemessen:
- BEOBACHTUNG: Jede Empfehlung knüpft an ein Merkmal an, das du auf den Fotos
  wirklich gesehen hast, und benennt es. Haarstruktur und Wuchsrichtung,
  Bartdichte und die Stellen, an denen sie fehlt, Hautbild, Gesichtsform,
  Proportionen. Was ohne die Fotos genauso dastünde, ist keine Empfehlung,
  sondern eine Floskel – streich es und schreib etwas, das nur zu dieser
  Person passt.
- ZEITPUNKT: Jede Tagesaufgabe nennt oder impliziert eine Tageszeit, die zu
  ihrem Zweck passt, und der Zweck muss erkennbar sein. Prüfe jede Aufgabe
  einzeln: Was bringt sie zu genau dieser Tageszeit? Eine Aufgabe, die den
  Bart am Abend in Form bringt, ist der Musterfall einer sinnlosen Aufgabe –
  danach wird geschlafen, am Morgen ist die Form dahin. Dieselbe Handlung
  gehört an den Morgen. Was über Nacht wirken soll (Pflege, Einwirkzeit),
  gehört dagegen an den Abend.
- TIEFE: Basics dürfen vorkommen – Gesicht waschen, eincremen, Wasser
  trinken –, aber niemals allein. In JEDEM Kapitel steht mindestens eine
  Empfehlung, die über die erste Seite einer Suchmaschine hinausgeht: eine
  Technik (wie genau, in welcher Richtung, mit welchem Druck), eine
  Reihenfolge (was vor was und warum), ein typischer Fehler samt Erklärung,
  woran man ihn merkt, oder ein Kniff, den ein guter Friseur, Barbier oder
  Stylist kennt und ein Laie nicht. Nenn ihn beim Namen und erklär, warum er
  wirkt.
- Schreib wie jemand, der die Fotos vor sich hat und die Person kennt – nicht
  wie ein Ratgebertext, der für alle gilt.
- Keine Empfehlung und keine Tagesaufgabe wiederholt eine andere, auch nicht
  in anderer Formulierung oder in einem anderen Kapitel.`;

/**
 * Was die Ganzkoerper- und Outfit-Fotos wirklich zeigen.
 *
 * Sie heissen "Ganzkoerper", zeigen aber seit DECISIONS 76 den Koerper vom
 * Kopf bis mindestens zu den Oberschenkeln – die Fuesse sind kein Kriterium
 * mehr, weil man dafuer unangenehm weit weg stehen musste.
 *
 * Ohne diesen Satz stolpert das Modell darueber: Es sieht ein Foto, das
 * "Ganzkoerper frontal" heisst und unten abgeschnitten ist, und schreibt
 * einen Hinweis auf das fehlende Bild statt einer Empfehlung.
 *
 * Nur wenn es die betroffenen Kapitel ueberhaupt gibt – ein Prompt ohne sie
 * soll Wort fuer Wort derselbe bleiben wie vorher.
 */
function fotoumfangRegel(module: readonly Modul[]): string {
  const betroffen =
    module.includes('figurPassform') || module.includes('stilKleiderschrank');
  if (!betroffen) return '';

  return `- Die Ganzkörper- und Outfit-Fotos zeigen die Person vom Kopf bis
  mindestens zu den Oberschenkeln. Fehlende Füße oder Unterschenkel sind
  KEIN Mangel: Beurteile Silhouette, Proportionen und Passform aus dem, was
  zu sehen ist, und weise nicht darauf hin, dass etwas fehlt.
`;
}

/**
 * Was der Nutzer ausdruecklich ausprobieren will (DECISIONS 79).
 *
 * Der Block steht nur da, wenn wirklich etwas gewaehlt wurde. Ein Prompt
 * ohne Auswahl bleibt Wort fuer Wort derselbe wie vorher — sonst liesse
 * sich nie sagen, ob eine Aenderung an der Antwort von der Auswahl kommt.
 *
 * **Warum Takt und Vertraeglichkeit hier stehen und nicht im Ermessen des
 * Modells liegen.** Ein Modell, das „Gua Sha" hoert, schreibt bereitwillig
 * eine taegliche Aufgabe daraus — und genau das ist fachlich falsch. Der
 * Takt kommt deshalb aus der Tabelle, nicht aus dem Sprachgefuehl. Beim
 * Peeling ist der Unterschied nicht kosmetisch: dreimal die Woche schadet.
 *
 * **Warum es „MUSS" heisst.** Wer diesen Schritt ausfuellt, hat eine
 * Erwartung an den Report. Eine Technik, die er gewaehlt hat und die
 * nirgends auftaucht, ist fuer ihn nicht „nicht so wichtig" — sie ist ein
 * Fehler. Die Nachbereitung zaehlt mit, wie oft das passiert.
 */
function ausprobierenRegeln(
  techniken: readonly Techniknamen[],
  sprache: Sprache,
): string {
  if (techniken.length === 0) return '';

  const liste = techniken
    .map((name) => {
      const technik = TECHNIK[name];
      return (
        `- "${technik.label[sprache]}" (Kapitel "${technik.modul}").\n` +
        `  Takt: ${technik.takt[sprache]}.\n` +
        `  Verträglichkeit: ${technik.hinweis[sprache]}.`
      );
    })
    .join('\n');

  return `Das will ich ausprobieren – der Nutzer hat diese Techniken ausdrücklich
angetippt. Sie sind kein Vorschlag von dir, sondern sein Wunsch:
${liste}

Verbindlich für JEDE dieser Techniken:
- Sie MUSS im Report vorkommen, und zwar in dem Kapitel, das oben dabeisteht,
  und nirgendwo sonst. Keine einzige darf fehlen.
- Sie steht dort als eigene "empfehlung" mit einer kurzen Anleitung: 2-3
  Sätze, die sagen WAS, WIE und WIE OFT. Nicht "probier mal Gua Sha", sondern
  die Handgriffe, in der richtigen Reihenfolge.
- Verbinde sie mit dem, was du auf den Fotos siehst. Warum ausgerechnet bei
  dieser Person? Eine Anleitung, die für jeden gleich lautet, ist keine.
- Übernimm den Takt von oben. Erfinde keinen eigenen und mach nichts täglich,
  was dort nicht täglich steht.
- Der Satz zur Verträglichkeit gehört dazu. Er ist kein Kleingedrucktes,
  sondern Teil der Anleitung – schreib ihn in eigenen Worten aus.
- Sie bekommt zusätzlich eine Aufgabe in "habits" desselben Kapitels, im
  Takt von oben.
- Bleibt der Name der Technik unverändert: Schreib ihn genau so, wie er oben
  steht, und trag ihn im Feld "neu" derjenigen Sektion ein, in der die
  Empfehlung steht.
${wochenaufgabenRegel(techniken, sprache)}- Nichts Invasives und nichts Medizinisches kommt dazu. Keine Dermaroller,
  kein Microneedling zu Hause, keine rezeptpflichtigen Wirkstoffe, kein
  Mewing, kein Kiefer-Kautraining, keine Fasten- oder Diät-Regime – auch
  nicht als Ergänzung, als Steigerung oder als "wenn du weitergehen willst".
`;
}

/**
 * Wie eine Aufgabe aussieht, die nicht taeglich ansteht.
 *
 * Nur wenn wirklich eine gewaehlte Technik so einen Takt hat: Bei lauter
 * taeglichen Techniken waere die Regel eine Einladung, sich eine
 * Wochenaufgabe auszudenken.
 */
function wochenaufgabenRegel(
  techniken: readonly Techniknamen[],
  sprache: Sprache,
): string {
  const woechentlich = techniken.some(
    (name) => !TAEGLICH.test(TECHNIK[name].takt.de),
  );
  if (!woechentlich) return '';

  return `- Steht im Takt nicht "täglich", ist die Aufgabe KEINE Tagesaufgabe. Sie
  beginnt dann statt mit einem Wenn-dann-Anker mit einem dieser Auslöser,
  wörtlich so geschrieben: ${wochenankerListe(sprache)}. Danach ein
  Doppelpunkt, dann die Handlung – zum Beispiel der Wochentag oder die
  Gelegenheit, an der sie am ehesten passt. Die App sortiert solche
  Aufgaben in einen eigenen Abschnitt der Tagesliste ein. Das ist die
  einzige Ausnahme von "täglich abhakbar" weiter unten.
`;
}

/** Ob ein Takt eine taegliche Anwendung beschreibt. */
const TAEGLICH = /täglich|jede nacht|jedem tag|nach jeder/i;

/**
 * Die Tiefe-Regel, die auch ohne jede Auswahl gilt (DECISIONS 80).
 *
 * `QUALITAET` verlangt seit DECISIONS 40 schon Tiefe, und der Befund am
 * Geraet war trotzdem: Gesicht waschen, Zahnseide, Feuchtigkeitscreme. Das
 * Wort „Tiefe" ist eben eine Stimmung. Diese Regel macht daraus eine Zahl
 * — mindestens ein Vorschlag je Kapitel — und sagt am Beispiel, was mit
 * dem Niveau gemeint ist.
 *
 * **Warum die Namen woertlich gelten sollen (DECISIONS 88).** Zu jeder
 * Technik aus dem Katalog liegt in der App eine feste Erklaerung; gefunden
 * wird sie ueber den Namen im Text. Ein abgewandelter Name findet sie nicht.
 * Der Prompt bittet deshalb um die genaue Schreibweise — er *zwingt* aber
 * nicht dazu, und er listet auch nicht alle 32 Namen auf: Was der Prompt
 * aufzaehlt, waehlt das Modell aus (DECISIONS 36), und aus einer Tiefe-Regel
 * wuerde so eine Speisekarte. Die Robustheit kommt von der anderen Seite —
 * die Bibliothek kennt zu jedem Eintrag Schreibvarianten.
 *
 * **Warum die Beispiele mit einer Warnung kommen.** Was der Prompt
 * woertlich nennt, schreibt das Modell woertlich ab (DECISIONS 36). Ohne
 * den Zusatz „nicht abschreiben" stuende in jedem Haut-Kapitel Gua Sha,
 * egal ob es zu der Person passt. Die Beispiele stehen deshalb
 * ausdruecklich als Muster fuer das NIVEAU da, nicht fuer den Inhalt — und
 * in der Zielsprache, weil das Modell sie sonst uebersetzt.
 */
function tiefeRegel(module: readonly Modul[], sprache: Sprache): string {
  const zeilen = module
    .map((modul) => {
      const beispiele = (Object.keys(TECHNIK) as Techniknamen[])
        .filter((name) => TECHNIK[name].modul === modul)
        .slice(0, 3)
        .map((name) => `"${TECHNIK[name].label[sprache]}"`);
      if (beispiele.length === 0) return undefined;
      return `  ${modul}: ${beispiele.join(', ')}`;
    })
    .filter((zeile): zeile is string => zeile !== undefined);

  return `Mehr als die Basics – eine Zahl, keine Stimmung:
- In JEDEM angeforderten Kapitel steht mindestens EIN Vorschlag, der über das
  hinausgeht, was jeder ohnehin weiß. Nicht "benutz eine Feuchtigkeitscreme",
  sondern eine Technik mit Namen, die man kennen muss, um sie zu nennen.
- Er wird erklärt, nicht nur genannt: was er bewirkt, wie oft, worauf zu
  achten ist – und warum er zu dieser Person und diesen Fotos passt.
- Die Basics bleiben stehen. Sie sind der Anfang der Liste und nicht ihr Ende.
- Nichts Invasives, nichts Medizinisches, nichts ohne Grundlage. Keine
  Dermaroller, kein Microneedling zu Hause, keine rezeptpflichtigen
  Wirkstoffe, kein Mewing, kein Kiefer-Kautraining, keine Fasten- oder
  Diät-Regime.
- So sieht das Niveau aus (Muster für das NIVEAU, nicht für den Inhalt –
  übernimm keinen dieser Namen, wenn etwas anderes besser zu der Person
  passt):
${zeilen.join('\n')}
- Meinst du aber wirklich eine der oben genannten Techniken, dann schreib
  ihren Namen genau so, wie er dort steht. Die App hat zu diesen Namen eine
  Erklärung hinterlegt und zeigt sie dem Nutzer an der Aufgabe an.`;
}

/** Die Zeile fuer "neu" im Schema. Ohne Auswahl gibt es das Feld nicht. */
function neuFeld(techniken: readonly Techniknamen[]): string {
  if (techniken.length === 0) return '';
  return '          "neu": ["Name einer ausprobierten Technik aus dieser ' +
    'Sektion"],\n';
}

/** Die Erlaeuterung dazu unter "Vorgaben zum Inhalt". */
function neuVorgabe(techniken: readonly Techniknamen[]): string {
  if (techniken.length === 0) return '';
  return `- "neu": nur die Namen der oben ausdrücklich gewählten Techniken, und nur
  in der Sektion, in der die zugehörige Empfehlung steht. Wörtlich wie oben
  geschrieben. Keine anderen Vorschläge, keine eigenen Formulierungen; hat
  eine Sektion keine, lass das Feld weg.`;
}

/**
 * Der Wenn-dann-Anker an jeder Tagesaufgabe.
 *
 * Begruendung in DECISIONS 44: Eine Aufgabe wird eher zur Gewohnheit, wenn
 * sie an etwas haengt, das ohnehin jeden Tag passiert. "Gesicht eincremen"
 * ist ein Vorsatz, "Nach dem Zaehneputzen: Gesicht eincremen" ist ein
 * Ablauf.
 *
 * Sprachabhaengig, deshalb eine Funktion und kein fester Text: Die Anker
 * schreibt das Modell woertlich ab (DECISIONS 36). Stuenden sie nur auf
 * Deutsch im Prompt, begaenne jede Aufgabe im englischen Report mit "Nach
 * dem Zaehneputzen".
 */
function ankerRegeln(sprache: Sprache): string {
  return `Wenn-dann-Anker – gilt für JEDE Aufgabe in "habits", in jedem Kapitel:
- Jede Aufgabe nennt zuerst den Auslöser, an den sie gekoppelt ist, dann
  einen Doppelpunkt, dann die Handlung. Der Auslöser ist eine feste Routine,
  die praktisch jeder Alltag hergibt. Nimm eine aus dieser Liste und schreib
  sie WÖRTLICH so, wie sie hier steht: ${ankerListe(sprache)}.
- Passt keine davon, nimm eine andere Alltagsroutine, die aus den Angaben
  dieser Person hervorgeht. Niemals eine Uhrzeit ("um 7 Uhr"), niemals etwas
  Vages ("regelmäßig", "täglich", "wenn du Zeit hast").
- Bei einer Aufgabe aus dem Freitext darf der Auslöser stattdessen die
  Situation sein, in der der Wunsch auftritt – das Verlangen, der Stress,
  die Pause. Die Form bleibt dieselbe: Auslöser, Doppelpunkt, Handlung.
- Derselbe Anker steht höchstens zweimal im ganzen Report. Sieben Aufgaben
  am selben Auslöser sind keine Routine, sondern ein Stau.
- Das ersetzt die Zeitpunkt-Regel nicht, es erfüllt sie: Der Anker sagt,
  wann die Handlung passiert, und er muss zu ihrem Zweck passen. Was über
  Nacht wirken soll, hängt an einem Anker am Abend.
- Der Anker ist Anzeigetext und steht deshalb in der Zielsprache.
  ${AUSGABESPRACHE_KURZ[sprache]}`;
}

/** Ob im Freitextfeld ueberhaupt etwas steht. */
function hatFreitext(richtung: Richtungsangaben): boolean {
  return richtung.freitext.trim().length > 0;
}

/**
 * Die Ausnahme von "4 bis 7 Aufgaben pro Kapitel".
 *
 * Steht nur da, wenn es das Zielkapitel ueberhaupt gibt. Ein Prompt ohne
 * Freitext soll Wort fuer Wort derselbe bleiben wie vorher – sonst laesst
 * sich nie sagen, ob eine Aenderung an der Antwort vom Freitext kommt.
 */
function habitAusnahme(richtung: Richtungsangaben): string {
  if (!hatFreitext(richtung)) return '';
  return (
    ` Einzige Ausnahme von der Zahl 4 bis 7 ist\n  "${ZIELKAPITEL}": Dort` +
    ' stehen so viele Aufgaben, wie die Wünsche im\n  Freitext hergeben, und' +
    ' keine einzige mehr.'
  );
}

/**
 * Der Abschnitt "Persoenliche Ziele des Nutzers". Leer, wenn der Nutzer den
 * Schritt uebersprungen hat – dann analysiert das Modell neutral.
 *
 * Der Freitext ist die einzige Stelle, an der ein Mensch frei formulierten
 * Text in diesen Prompt schreibt. Er steht deshalb in einem Datenblock mit
 * einer zufaelligen Marke, nicht mehr in einem Zitat aus Anfuehrungszeichen:
 * Aus einem Zitat kam man mit drei Anfuehrungszeichen heraus, aus dem Block
 * kommt man nicht heraus (SECURITY_AUDIT D1, `nutzertext.ts`).
 */
function ziele(
  richtung: Richtungsangaben,
  sprache: Sprache,
  marke: string,
): string {
  const gewaehlt = labels(RICHTUNGSZIEL, richtung.ziele, sprache);
  const freitext = richtung.freitext.trim();
  if (gewaehlt.length === 0 && freitext.length === 0) return '';

  const zeilen: string[] = [];
  if (gewaehlt.length > 0) {
    zeilen.push(`- Gewählte Richtung: ${gewaehlt.join(', ')}`);
    // Und was das heisst. Ohne diese Zeilen war die Wahl nur Stimmung: Am
    // fertigen Report liess sich nicht erkennen, ob jemand „Streetwear" oder
    // „Smart" angetippt hatte (DECISIONS 58).
    zeilen.push('- Was diese Richtung konkret bedeutet:');
    for (const name of richtung.ziele) {
      const titel = label(RICHTUNGSZIEL, name, sprache);
      const vorgabe = label(RICHTUNGSVORGABE, name, sprache);
      if (titel === undefined || vorgabe === undefined) continue;
      zeilen.push(`  • ${titel}: ${vorgabe}`);
    }
  }
  if (freitext.length > 0) {
    zeilen.push(
      '- In eigenen Worten:\n' +
        `${datenblock(FREITEXT_FELD, freitext, marke)}\n` +
        datenblockRegel(FREITEXT_FELD, marke),
    );
  }

  return `\nPersönliche Ziele des Nutzers:\n${zeilen.join('\n')}\n`;
}

/** Der Name des Datenblocks mit dem Freitext. */
const FREITEXT_FELD = 'nutzerwunsch';

/** Zusatzregeln, die nur greifen, wenn eine Richtung vorliegt. */
function zielRegeln(
  richtung: Richtungsangaben,
  sprache: Sprache,
  marke: string,
): string {
  const hatZiele =
    labels(RICHTUNGSZIEL, richtung.ziele, sprache).length > 0 ||
    hatFreitext(richtung);
  if (!hatZiele) return '';

  return `- Richte ALLE Empfehlungen in sämtlichen Kapiteln an den persönlichen Zielen
  aus und nimm dort, wo es passt, ausdrücklich Bezug darauf.
- Die gewählte Richtung ist eine Vorgabe, keine Stimmung. Setz die oben
  genannten Punkte zu Frisur, Bart und Kleidung wirklich um: Ein Report, dem
  man die Wahl nicht ansieht, hat sie ignoriert. Sind mehrere Richtungen
  gewählt, verbinde sie zu einem stimmigen Bild und erkläre in einem Satz,
  wie du das gemacht hast.
- Widersprechen sich zwei gewählte Richtungen an einem Punkt, entscheide dich
  sichtbar für eine und sag, warum – nicht die Mitte aus beiden.
${bezugRegel(richtung, sprache)}
- Wenn ein Ziel dem widerspricht, was auf den Fotos zu sehen ist, wäge beides
  offen ab und erkläre den Zielkonflikt – ignoriere das Ziel nicht und rede es
  auch nicht klein.
- Enthält der Freitext gesundheitlich bedenkliche Ziele (z. B. sehr schnelles
  Abnehmen, Verzicht auf Essen, Selbstbehandlung von Hautproblemen), baue
  darauf keinen Plan. Nimm das Anliegen ernst, benenne freundlich das Risiko
  und schlage einen gesunden Weg zum gleichen Wunschbild vor.
${freitextRegeln(richtung, marke)}`;
}

/**
 * Der halbe Satz, der die Wahl sichtbar macht (DECISIONS 87).
 *
 * Der Befund: Die gewaehlte Richtung floss in den Prompt ein und praegte die
 * Empfehlungen — nur stand nirgends, dass sie es tat. Am fertigen Report war
 * die Wahl unsichtbar, und was unsichtbar ist, fuehlt sich folgenlos an. Das
 * Ausprobieren-Paket macht es mit „Neu fuer dich" vor; hier ist dasselbe in
 * Worten statt in einer Pille.
 *
 * **Warum mit Positiv- und Negativbeispiel.** Was der Prompt woertlich nennt,
 * schreibt das Modell woertlich ab (DECISIONS 36) — und das ist hier
 * ausnahmsweise erwuenscht: Die Wendung soll wiedererkennbar sein. Das
 * Negativbeispiel steht daneben, weil die Gefahr nicht das Fehlen ist,
 * sondern die Flut: ein Report, in dem jeder zweite Satz mit „Passend zu
 * deiner Richtung" beginnt, liest sich wie ein Formbrief.
 *
 * **Warum in der Zielsprache.** Stuende die Wendung nur auf Deutsch im
 * Prompt, begaenne jede englische Empfehlung mit „Passend zu deiner
 * Richtung" — derselbe Fehler, den die Anker-Liste schon einmal gemacht hat.
 */
function bezugRegel(richtung: Richtungsangaben, sprache: Sprache): string {
  const gewaehlt = labels(RICHTUNGSZIEL, richtung.ziele, sprache);
  if (gewaehlt.length === 0) return '';

  const beispiel = BEZUG_BEISPIEL[sprache](gewaehlt[0]);
  return `- Sag es dort, wo es zutrifft. Ist eine Empfehlung von einer gewählten
  Richtung geprägt, nennt sie das in einem halben Satz – wörtlich in dieser
  Form: "${beispiel}". Mindestens einmal in JEDEM Kapitel, in dem die Wahl
  eine Rolle spielt.
- Aber nicht öfter als nötig. Höchstens zwei solche Stellen je Kapitel; ein
  Report, in dem jeder zweite Satz so beginnt, liest sich wie ein Formbrief.
  Wo eine Empfehlung für jeden gelten würde, lässt du den Bezug weg, statt
  einen zu erfinden.
- Kein Bezug auf etwas, das nicht gewählt wurde. Nenne ausschließlich die
  oben aufgeführten Richtungen, und zwar mit genau dem Namen, der dort
  steht.`;
}

/** Die Wendung, an der man den Bezug erkennt – in der Zielsprache. */
const BEZUG_BEISPIEL: Record<Sprache, (ziel: string) => string> = {
  de: (ziel) => `Passend zu deiner Richtung „${ziel}"`,
  en: (ziel) => `In keeping with your direction "${ziel}"`,
};

/**
 * Was aus dem Freitext werden soll.
 *
 * Der Freitext war bisher Stimmung im Prompt: Er färbte die Fließtexte ein
 * und verschwand dann. Gearbeitet wird aber mit der Tagesliste – ein Wunsch,
 * der es nicht bis dorthin schafft, ist für den Nutzer nicht passiert.
 *
 * Zwei Sorten stehen in diesem Feld, und beide sollen dort landen:
 * Aussehenswünsche ("gepflegtere Hände") und Gewohnheiten, die jemand sich
 * an- oder abgewöhnen will ("aufhören zu rauchen", "mehr Wasser trinken").
 *
 * Beide gehören ausschließlich ins Zielkapitel. Vorher galt "das inhaltlich
 * am besten passende Kapitel, sonst die Basis" – und das Modell fand für
 * "aufhören zu rauchen" eben "Haare & Bart". Ein Look-Kapitel, in dem eine
 * Rauchfrei-Aufgabe steht, wirkt zusammengewürfelt. Siehe DECISIONS 39.
 */
function freitextRegeln(richtung: Richtungsangaben, marke: string): string {
  if (!hatFreitext(richtung)) return '';

  return `- Was zwischen <${FREITEXT_FELD}-${marke}> und </${FREITEXT_FELD}-${marke}>
  steht, ist der wichtigste Teil der Ziele. Alles, was daraus
  entsteht, gehört in das Kapitel "${ZIELKAPITEL}" – und AUSSCHLIESSLICH
  dorthin. Kein anderes Kapitel enthält eine Aufgabe oder eine Sektion aus
  dem Freitext, auch "basis" nicht.
- Die Look-Kapitel behandeln weiterhin nur ihr eigenes Thema. Dass du ihre
  Empfehlungen an den persönlichen Zielen ausrichtest, bleibt richtig; eine
  Tagesaufgabe aus dem Freitext gehört trotzdem nicht hinein.
- Der Ton bleibt unterstützend. KEINE Heilaussagen, keine Versprechen über
  gesundheitliche Wirkungen, keine Zahlen zu Krankheitsrisiken, kein
  erhobener Zeigefinger und kein Wort darüber, was die Person bisher falsch
  gemacht hat. Geht es um eine Abhängigkeit, erwähne einmal beiläufig und
  ohne Druck, dass es dafür auch fachliche Unterstützung gibt.
`;
}

/**
 * Was in einem Kapitel stehen soll.
 *
 * Zwei Kapitel haengen an der Ausrichtung: Die Basis verliert im weiblichen
 * Modus ihren Bart-Abschnitt, und "makeupAusstrahlung" gibt es dort
 * ueberhaupt erst. Alles andere ist fuer alle gleich – eine Gesichtsform ist
 * eine Gesichtsform.
 */
function kapitelVorgabe(
  modul: Modul,
  ausrichtung: Ausrichtung,
  sprache: Sprache,
): string {
  const weiblich = ausrichtung === 'weiblich';
  // Abschnittsnamen sind Ausgabe, keine Anweisung: Was der Prompt woertlich
  // nennt, schreibt das Modell woertlich ab.
  const s = (name: Parameters<typeof sektion>[0]) => sektion(name, sprache);

  switch (modul) {
    case 'basis':
      if (weiblich) {
        return (
          '- "basis" – Gesicht & Haare. Die "einleitung" beschreibt die ' +
          'Gesichtsform neutral und was formal dazu passt. Sektionen, ' +
          `deren "titel" GENAU so lautet: "${s('frisur')}" (Schnitt, Länge ` +
          'und Scheitel passend zu Gesichtsform und Proportionen; nenne ' +
          `konkrete Schnittnamen), "${s('augenbrauen')}" (Form und Pflege, ` +
          `keine Behandlung), bei Bedarf "${s('brillenform')}". Es gibt ` +
          'KEINEN Bart-Abschnitt und keine Rasurempfehlung.'
        );
      }
      return (
        '- "basis" – Gesicht, Haare & Bart. Die "einleitung" beschreibt die ' +
        'Gesichtsform neutral und was formal dazu passt. Sektionen, deren ' +
        `"titel" GENAU so lautet: "${s('frisur')}", "${s('bart')}" ` +
        '(weglassen, wenn kein Bartwuchs erkennbar ist), bei Bedarf ' +
        `"${s('brillenform')}".`
      );
    case 'hautFarbtyp':
      return (
        '- "hautFarbtyp" – Haut & Farbtyp. Es gibt für dieses Kapitel KEINE ' +
        'eigene Aufnahme: Beurteile Hautbild und Unterton anhand des ' +
        'Frontalfotos der Basis. Warmer oder kalter Unterton, dazu eine ' +
        'konkrete Farbpalette für Kleidung (Farben benennen)' +
        (weiblich
          ? ' und, falls das Kapitel "makeupAusstrahlung" nicht angefordert ' +
            'wurde, ein Satz dazu, welche Make-up-Töne zu diesem Unterton ' +
            'passen'
          : '') +
        '. Wenn das Frontalfoto für eine Aussage zum Hautbild nicht hergibt ' +
        '(zu wenig Licht, zu geringe Auflösung), sag das offen und ' +
        'beschränke dich auf den Unterton und die Farbpalette – rate nicht.'
      );

    case 'makeupAusstrahlung':
      return (
        '- "makeupAusstrahlung" – Make-up & Ausstrahlung. Auch hierfür gibt ' +
        'es KEINE eigene Aufnahme: Lies Gesichtszüge, Augenpartie und ' +
        'Farbwirkung aus dem Frontalfoto der Basis. Sektionen, deren ' +
        `"titel" GENAU so lautet: "${s('alltagsLook')}" (Teint, Augen, ` +
        'Brauen, Lippen – je ein konkreter Handgriff, keine ' +
        `Produktschlacht) und "${s('farben')}" (welche Töne für Lider, ` +
        'Lippen und Rouge zum Unterton passen, mit Namen). Richte ' +
        'Aufwand und Preisniveau am Zeit- und Pflegebudget aus. Empfiehl ' +
        'NICHTS, das eine kosmetische Behandlung, einen Eingriff oder ein ' +
        'Permanent-Make-up voraussetzt. Wenn auf dem Foto bereits Make-up ' +
        'zu sehen ist, beurteile den vorhandenen Look, statt ihn zu ' +
        'ignorieren.'
      );
    case 'zaehneLaecheln':
      return (
        '- "zaehneLaecheln" – Zähne & Lächeln. Zahnfarbe, Zahnstellung und ' +
        'Mimik beim Lächeln, dazu Pflege- und Optimierungstipps. Keine ' +
        'zahnmedizinische Diagnose.'
      );
    case 'figurPassform':
      return (
        '- "figurPassform" – Figur & Passform. Körpertyp, ' +
        'Schulter-Hüft-Verhältnis, empfohlene Schnitte und Passformen, ' +
        'Haltungshinweise aus dem Seitenprofil. Sachlich und ohne ' +
        'Gewichtsurteil.' +
        (weiblich
          ? ' Ordne die Figur einem der gängigen Grundtypen zu (Sanduhr, ' +
            'Birne, Apfel, gerade/rechteckig, umgekehrtes Dreieck), benenne ' +
            'ihn beim Namen und leite daraus konkrete Schnitte ab: ' +
            'Taillenhöhe, Rock- und Hosenformen, Ausschnitte, Längen. ' +
            'Der Typ ist eine Beschreibung von Proportionen, kein Urteil – ' +
            'formuliere ihn auch so.'
          : '')
      );
    case 'stilKleiderschrank':
      return (
        '- "stilKleiderschrank" – Stil & Kleiderschrank. Gleiche die ' +
        'gezeigten Outfits mit der Stilrichtung ab und gib konkrete ' +
        'Look-Vorschläge unter Berücksichtigung von Budget und ' +
        'Pflegeaufwand. SCHWERPUNKT: Outfits zum Ausgehen und für Dates. ' +
        'Genau dafür wird dieser Report gelesen. Der Alltag – Uni, Schule, ' +
        'Arbeit, Sport – ist Nebenbedingung: Die Vorschläge dürfen ihn ' +
        'nicht unmöglich machen, aber sie richten sich nicht nach ihm. ' +
        'Auch wenn oben andere Zwecke angegeben sind, bleibt der ' +
        'Schwerpunkt auf Ausgeh- und Date-Outfits; die Angabe verschiebt ' +
        'nur, worauf du zusätzlich Rücksicht nimmst.'
      );
    case 'persoenlicheZiele':
      return [
        `- "${ZIELKAPITEL}" – Persönliche Ziele. Dieses Kapitel gehört allein ` +
          'dem, was die Person oben in eigenen Worten geschrieben hat. Es ' +
          'kommt nichts aus den Fotos hinein, und nichts aus diesem Kapitel ' +
          'taucht in einem anderen wieder auf.',
        '  Die "einleitung" fasst in 2-3 Sätzen zusammen, was sich die ' +
          'Person vorgenommen hat – in ihren Worten, ohne Bewertung und ohne ' +
          'Vorrede.',
        '  "habits": ein bis drei Aufgaben je Wunsch aus dem Freitext, sonst ' +
          'nichts. Jede ist heute abhakbar, dauert wenige Minuten und ' +
          'benennt eine konkrete Handlung – nicht "weniger rauchen", sondern ' +
          'was genau zu tun ist, wenn das Verlangen kommt. Der Wenn-dann-' +
          'Anker gilt auch hier; der Auslöser darf die Situation sein.',
        '  "sektionen": eine je Wunsch, höchstens drei. Geht es um eine ' +
          'Gewohnheit, die die Person sich ab- oder angewöhnen möchte, ' +
          `lautet der "titel" dieser Sektion GENAU "${s('ziel')}". Ihre ` +
          '"einschaetzung" beschreibt, wofür der Wunsch im Alltag steht und ' +
          'was ihn schwer macht – beschreibend, nicht belehrend. Ihre ' +
          '"empfehlungen" sind Auslöser-Strategien: Benenne die typischen ' +
          'Situationen (Feierabend, Kaffee, Stress, Warten) und gib für ' +
          'jede eine konkrete Alternative oder einen Ersatzgriff – ein ' +
          'Ritual, das dieselbe Lücke füllt, oder etwas, das die Hand ' +
          'beschäftigt.',
        '  Geht es um einen Wunsch ans Aussehen, für den es kein eigenes ' +
          'Kapitel gibt (gepflegtere Hände, gesündere Nägel, aufrechtere ' +
          'Haltung), bekommt er eine eigene Sektion mit einem kurzen, ' +
          'sachlichen "titel" in der Zielsprache.',
        '  "produkte" nur, wenn ein Produkt für diesen Wunsch wirklich ' +
          'etwas ändert; sonst eine leere Liste.',
      ].join('\n');
  }
}

/**
 * Was im entdeckenden Modus zu jeder Kapitelvorgabe dazukommt.
 *
 * Das Zielkapitel bleibt aussen vor: Es gehoert allein dem Freitext
 * (DECISIONS 39), und ein Frisurvorschlag darin waere genau die Vermischung,
 * die dort abgeschafft wurde. Auch im neuen Look ist "aufhoeren zu rauchen"
 * kein Look-Thema.
 */
function zusatz(modul: Modul, modus: Modus, sprache: Sprache): string {
  if (modus !== 'entdecken' || modul === ZIELKAPITEL) return '';
  return kapitelZusatz(sektion('neuerLook', sprache));
}

/** Uebersetzt Onboarding-Antworten und Modul-Eingaben in Prompt-Kontext. */
function kontext(daten: AnalysePromptDaten, module: readonly Modul[]): string {
  const zeilen: string[] = [];
  const sprache = daten.sprache;

  const alter = label(ALTER, daten.profil.alter, sprache);
  if (alter) zeilen.push(`- Altersbereich: ${alter}`);

  const budget = label(BUDGET, daten.profil.budget, sprache);
  if (budget) zeilen.push(`- Budget für Pflege und Styling: ${budget}`);

  const zeit = label(ZEIT, daten.profil.zeit, sprache);
  if (zeit) zeilen.push(`- Zeit pro Tag: ${zeit}`);

  const fokus = labels(FOKUS, daten.profil.fokus, sprache);
  if (fokus.length > 0) {
    zeilen.push(`- Gewünschte Schwerpunkte: ${fokus.join(', ')}`);
  }

  if (module.includes('figurPassform')) {
    if (daten.figur.groesseCm !== undefined) {
      zeilen.push(`- Körpergröße: ${daten.figur.groesseCm} cm`);
    }
    if (daten.figur.gewichtKg !== undefined) {
      zeilen.push(`- Gewicht: ${daten.figur.gewichtKg} kg`);
    }
  }

  if (module.includes('stilKleiderschrank')) {
    const stilziele = labels(RICHTUNGSZIEL, daten.stil.ziele, sprache);
    if (stilziele.length > 0) {
      zeilen.push(`- Stilrichtung für Kleidung: ${stilziele.join(', ')}`);
    }
    const zwecke = labels(ALLTAGSZWECK, daten.stil.zwecke, sprache);
    if (zwecke.length > 0) {
      zeilen.push(`- Der Stil soll funktionieren für: ${zwecke.join(', ')}`);
    }

    const kleidung = label(KLEIDUNGSBUDGET, daten.stil.budget, sprache);
    if (kleidung) zeilen.push(`- Budget pro Kleidungsstück: ${kleidung}`);

    const pflege = label(PFLEGEAUFWAND, daten.stil.pflegeaufwand, sprache);
    if (pflege) zeilen.push(`- Bereitschaft zu Pflegeaufwand: ${pflege}`);
  }

  if (zeilen.length === 0) {
    // Auch ohne jede Angabe muss dastehen, wie zu gewichten ist – sonst
    // sucht sich das Modell selbst einen Schwerpunkt.
    return `Zur Person liegen keine weiteren Angaben vor.
${schwerpunktRegel([])}`;
  }

  return (
    `Angaben der Person:\n${zeilen.join('\n')}\n` +
    schwerpunktRegel(daten.profil.fokus)
  );
}

/**
 * Was ein Schwerpunkt heisst.
 *
 * Der Anlass steht in DECISIONS 60: Die Frage „Worauf willst du dich
 * konzentrieren?" wirkte bis dahin nur ueber diese eine Zeile — „gewichte
 * staerker" —, und am fertigen Report war nicht zu erkennen, ob jemand
 * ueberhaupt etwas angekreuzt hatte. Eine Gewichtung, die niemand sieht, ist
 * keine.
 *
 * Deshalb steht hier jetzt eine Zahl statt eines Adverbs: eine Empfehlung
 * mehr und eine Tagesaufgabe, die genau darauf zielt. Das ist an einer
 * einzelnen Zeile des Reports nachzuzaehlen.
 *
 * Die Kapitelgrenze bleibt unangetastet (DECISIONS 39): Ein Schwerpunkt
 * verschiebt Gewicht **innerhalb** der bestellten Kapitel, er erfindet keins
 * und traegt nichts in ein fremdes hinein.
 */
function schwerpunktRegel(fokus: string[]): string {
  if (fokus.length === 0) {
    return 'Behandle alle angeforderten Kapitel gleich gewichtet.';
  }

  return (
    'Die genannten Schwerpunkte sind eine Vorgabe, keine Stimmung: In dem '
    + 'Kapitel, zu dem ein Schwerpunkt gehört, steht mindestens eine '
    + 'Empfehlung mehr als in den übrigen und mindestens eine Tagesaufgabe, '
    + 'die genau auf diesen Schwerpunkt zielt. Gehört ein Schwerpunkt zu '
    + 'keinem der angeforderten Kapitel, lass ihn weg – erfinde dafür kein '
    + 'Kapitel und trag ihn in kein fremdes hinein. Die übrigen Bereiche '
    + 'werden dadurch nicht dünner, sie bekommen nur nicht das Zusätzliche.'
  );
}
