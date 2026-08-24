import {
  CHECKIN_TYP,
  HABIT_BEWERTUNG,
  MODUL_KAPITEL,
  PASST_NICHT_GRUND,
  RICHTUNGSZIEL,
  WIRKUNGS_ANTWORT,
  label,
  labels,
  mitFortschrittsfoto,
  type Modul,
} from './labels';
import type { Richtungsangaben } from './analyse_prompt';

/**
 * Baut den Prompt, mit dem das Modell einen Check-in auswertet und den Plan
 * nachjustiert.
 *
 * Portierung von `lib/features/checkin/logic/checkin_prompt.dart`. Wie beim
 * Analyse-Prompt liegt hier die inhaltliche Leitplanke: nur nachbessern, nie
 * neu schreiben.
 */

export interface HabitRueckmeldung {
  habit: string;
  bewertung: string;
  grund?: string;
  notiz: string;
}

export interface WirkungsRueckmeldung {
  frage: string;
  antwort: string;
  notiz: string;
}

export interface Kapitelplan {
  modul: Modul;
  habits: string[];
}

export interface Historieneintrag {
  /** ISO-8601, Tag der Erledigung bzw. Faelligkeit. */
  datum: string;
  typ: string;
  probleme: { habit: string; grund?: string }[];
}

export interface CheckinPromptDaten {
  typ: string;
  habits: HabitRueckmeldung[];
  wirkung: WirkungsRueckmeldung[];
  plan: Kapitelplan[];
  richtung: Richtungsangaben;
  historie: Historieneintrag[];
  mitFotos: boolean;
}

/** Hoechstzahl der Aenderungen pro Check-in. */
const MAX_ANPASSUNGEN = 4;

/** Nachfassen, wenn die erste Antwort kein gueltiges JSON war. */
export const JSON_NACHFASSEN =
  'Deine letzte Antwort war kein gültiges JSON. Antworte nur mit validem ' +
  'JSON nach dem vorgegebenen Schema – ohne Erklärung, ohne Markdown-' +
  'Codefences.';

export function systemPrompt(daten: CheckinPromptDaten): string {
  const titel = label(CHECKIN_TYP, daten.typ) ?? 'Check-in';
  const mitFoto = mitFortschrittsfoto(daten.typ);

  return `Du bist derselbe Styling- und Grooming-Coach, der den Plan dieser Person
erstellt hat. Sie meldet sich zum ${titel} zurück.

${planUeberblick(daten.plan)}
${richtungsText(daten.richtung)}
${antworten(daten)}
${historieText(daten.historie)}
${daten.mitFotos ? fotoHinweis() : ''}
Deine Aufgabe: den bestehenden Plan minimal-invasiv nachjustieren.

Verbindliche Regeln:
- Ändere NUR das, was der Nutzer bemängelt hat. Alles andere bleibt exakt so
  stehen – kein Umschreiben des ganzen Plans, keine kosmetischen Umformulierungen.
- Ein Habit mit "Passt nicht" wird ersetzt, vereinfacht oder seltener gemacht,
  passend zum genannten Grund.
- Ein Habit mit "Geht so" bleibt bestehen; nur wenn ein Grund genannt wurde,
  darfst du ihn leichter machen.
- Ein Habit mit "Läuft gut" bleibt unverändert. Beim Wirkungs-Check darfst du
  dafür EINE nächste Stufe vorschlagen, wenn sie sinnvoll ist.
- Streiche nie ersatzlos, wenn der Zweck des Habits noch gebraucht wird –
  such lieber eine leichtere Variante.
- Höchstens ${MAX_ANPASSUNGEN} Änderungen insgesamt.
- Vergib keine Noten, Punkte oder Vergleiche. Bewertet werden Aufgaben, nie
  die Person.
- Keine medizinischen Diagnosen; bei Auffälligkeiten freundlich an eine
  Fachpraxis verweisen.
- Deutsch, per Du, warm und sachlich.

Antworte AUSSCHLIESSLICH mit einem JSON-Objekt nach diesem Schema. Kein
Fließtext davor oder danach, keine Markdown-Codefences:

{
  "zusammenfassung": "1-2 Sätze: was wir anpassen und warum",
  "fazit": "${fazitVorgabe(mitFoto)}",
  "anpassungen": [
    {
      "modul": "basis",
      "alt": "der bisherige Habit im exakten Wortlaut",
      "neu": "der neue Habit, unter 60 Zeichen",
      "grund": "ein kurzer Satz für den Nutzer"
    }
  ]
}

Vorgaben zum Inhalt:
- "modul" ist exakt einer der oben genannten Bezeichner.
- "alt" muss WORTGLEICH einem bestehenden Habit entsprechen, sonst greift die
  Änderung nicht. Für einen zusätzlichen Habit "alt" leer lassen, für eine
  Streichung "neu" leer lassen.
- "neu" ist eine konkrete, täglich abhakbare Aufgabe unter 60 Zeichen und
  gehört inhaltlich zum selben Modul wie "alt".
- Gibt es nichts zu ändern, ist "anpassungen" eine leere Liste und
  "zusammenfassung" sagt freundlich, dass der Plan so bleibt.
${mitFoto ? '' : '- "fazit" bleibt ein leerer String.'}
`;
}

export function nutzerText(typ: string, mitFotos: boolean): string {
  const titel = label(CHECKIN_TYP, typ) ?? 'Check-in';
  const bilder = mitFotos
    ? '\n\nDie Bilder sind: 1. das Foto der Erstanalyse, 2. das heutige ' +
      'Fortschrittsfoto. Vergleiche sie sachlich und ohne ' +
      'Attraktivitätsurteil.'
    : '';

  return (
    `Hier ist mein ${titel}. Bitte passe meinen Plan an ` +
    `und antworte im vorgegebenen JSON-Schema.${bilder}`
  );
}

function fazitVorgabe(mitFoto: boolean): string {
  return mitFoto
    ? '2-4 Sätze Zwischenfazit: was sich verändert hat, was gut läuft, ' +
        'was wir nachschärfen'
    : '';
}

/**
 * Der aktuelle Plan, gegliedert nach Kapiteln – nur die Habits, denn nur die
 * werden angepasst.
 */
function planUeberblick(plan: Kapitelplan[]): string {
  const zeilen: string[] = [];
  for (const kapitel of plan) {
    zeilen.push(`- Modul "${kapitel.modul}" (${MODUL_KAPITEL[kapitel.modul]}):`);
    for (const habit of kapitel.habits) {
      zeilen.push(`  * ${habit}`);
    }
  }

  if (zeilen.length === 0) return 'Der Plan enthält aktuell keine Tagesaufgaben.';
  return `Aktuelle Tagesaufgaben:\n${zeilen.join('\n')}`;
}

function richtungsText(richtung: Richtungsangaben): string {
  const gewaehlt = labels(RICHTUNGSZIEL, richtung.ziele);
  const freitext = richtung.freitext.trim();
  if (gewaehlt.length === 0 && freitext.length === 0) return '';

  const teile: string[] = [];
  if (gewaehlt.length > 0) teile.push(gewaehlt.join(', '));
  if (freitext.length > 0) teile.push(`in eigenen Worten: "${freitext}"`);

  return `\nDie Person verfolgt weiterhin diese Richtung: ${teile.join(' – ')}\n`;
}

/** Die Antworten dieses Check-ins. */
function antworten(daten: CheckinPromptDaten): string {
  const zeilen: string[] = [];

  for (const feedback of daten.habits) {
    const bewertung = label(HABIT_BEWERTUNG, feedback.bewertung);
    if (!bewertung) continue;

    const grund = feedback.grund ? PASST_NICHT_GRUND[feedback.grund] : undefined;
    const zusatz = grund ? ` – Grund: ${grund.label} (${grund.anweisung})` : '';
    const notiz =
      feedback.notiz.trim().length === 0
        ? ''
        : ` – Anmerkung: "${feedback.notiz.trim()}"`;
    zeilen.push(`- "${feedback.habit}": ${bewertung}${zusatz}${notiz}`);
  }

  const wirkung = daten.wirkung.filter((w) =>
    label(WIRKUNGS_ANTWORT, w.antwort),
  );
  if (wirkung.length > 0) {
    zeilen.push('Wirkung aus Sicht der Person:');
    for (const w of wirkung) {
      const notiz = w.notiz.trim().length === 0 ? '' : ` – "${w.notiz.trim()}"`;
      zeilen.push(`- ${w.frage} ${label(WIRKUNGS_ANTWORT, w.antwort)}${notiz}`);
    }
  }

  if (zeilen.length === 0) return 'Es liegen keine Antworten vor.';
  return `\nAntworten aus diesem Check-in:\n${zeilen.join('\n')}\n`;
}

/**
 * Verdichtete Feedback-Historie: Was frueher schon bemaengelt wurde, darf
 * nicht erneut in derselben Form vorgeschlagen werden.
 */
function historieText(historie: Historieneintrag[]): string {
  if (historie.length === 0) return '';

  const zeilen: string[] = [];
  for (const eintrag of historie) {
    const probleme = eintrag.probleme
      .map((p) => {
        const grund = p.grund ? PASST_NICHT_GRUND[p.grund]?.label : undefined;
        return `"${p.habit}" (${grund ?? 'ohne Grund'})`;
      })
      .join(', ');

    const typ = label(CHECKIN_TYP, eintrag.typ) ?? 'Check-in';
    zeilen.push(
      `- ${datum(eintrag.datum)}, ${typ}: ` +
        `${probleme.length === 0 ? 'nichts bemängelt' : `passte nicht: ${probleme}`}`,
    );
  }

  return (
    `\nFrühere Check-ins:\n${zeilen.join('\n')}\n` +
    'Schlage nichts vor, was schon einmal als unpassend gemeldet wurde.\n'
  );
}

function fotoHinweis(): string {
  return (
    '\nZu diesem Check-in liegen zwei Fotos vor: das Foto der Erstanalyse ' +
    'und ein heutiges Fortschrittsfoto unter denselben Bedingungen. Nutze ' +
    'sie für das Zwischenfazit – beschreibe Veränderungen sachlich, ohne ' +
    'Bewertung der Attraktivität und ohne Gewichtsurteil.\n'
  );
}

/**
 * ISO-8601 → tt.mm.jjjj, wie in der App.
 *
 * Bewusst ueber den Datumsteil der Zeichenkette statt ueber `new Date`: Der
 * Client schickt lokale Zeitstempel ohne Zeitzone, die Function laeuft in UTC.
 * Ein Umweg ueber `Date` wuerde den Tag je nach Uhrzeit um eins verschieben.
 */
function datum(iso: string): string {
  const treffer = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso);
  if (!treffer) return iso;
  return `${treffer[3]}.${treffer[2]}.${treffer[1]}`;
}
