/**
 * Die Sprachen, in denen ein Report geschrieben werden kann.
 *
 * Spiegelt das Dart-Enum `Sprache` in `lib/core/l10n/sprache.dart`. Der
 * Client schickt den ISO-Code mit; alles andere faellt hier heraus und wird
 * zu Deutsch.
 *
 * Warum Deutsch der Rueckfall ist und nicht Englisch: Die App gab es
 * zuerst nur auf Deutsch. Ein alter Client, der noch kein Feld `sprache`
 * kennt, bekommt damit weiterhin genau das, was er erwartet.
 */
export const SPRACHEN = ['de', 'en'] as const;

export type Sprache = (typeof SPRACHEN)[number];

export function leseSprache(roh: unknown): Sprache {
  return typeof roh === 'string' && (SPRACHEN as readonly string[]).includes(roh)
    ? (roh as Sprache)
    : 'de';
}

/** Ein Text in beiden Sprachen. */
export type Zweisprachig = { de: string; en: string };

/** Nimmt den passenden Zweig. */
export function inSprache(text: Zweisprachig, sprache: Sprache): string {
  return text[sprache];
}

/**
 * Die Anweisung, in welcher Sprache das Modell antworten soll.
 *
 * Der uebrige Prompt bleibt bewusst auf Deutsch, auch wenn der Report
 * englisch werden soll. Er enthaelt saemtliche Leitplanken – keine Scores,
 * keine Diagnosen, kein Attraktivitaetsurteil – und die duerfen es nur
 * einmal geben. Zwei Uebersetzungen desselben Regelwerks laufen frueher oder
 * spaeter auseinander, und dann gilt in einer Sprache eine Regel, die in der
 * anderen jemand vergessen hat.
 *
 * Deshalb steht die Sprachvorgabe zweimal im Prompt: einmal bei den Regeln
 * und einmal ganz am Ende bei den Feldvorgaben. Ein Modell, das eine
 * deutschsprachige Anweisung liest, faellt sonst gern in die Sprache der
 * Anweisung zurueck.
 */
export const AUSGABESPRACHE: Record<Sprache, string> = {
  de: 'Formuliere auf Deutsch, per Du, warm und sachlich.',
  en:
    'Write every word of your answer in ENGLISH – not in German, auch wenn ' +
    'diese Anweisung auf Deutsch steht. Address the person directly as "you", ' +
    'warm and matter-of-fact.',
};

/** Dieselbe Vorgabe als kurze Wiederholung am Ende des Prompts. */
export const AUSGABESPRACHE_KURZ: Record<Sprache, string> = {
  de: 'Alle Textfelder auf Deutsch.',
  en: 'Every text field in ENGLISH.',
};
