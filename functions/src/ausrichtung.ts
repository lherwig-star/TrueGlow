import { type Sprache, type Zweisprachig } from './sprache';

/**
 * Wonach der Report ausgerichtet wird.
 *
 * Spiegelt das Dart-Enum `Ausrichtung` in
 * `lib/features/onboarding/models/onboarding_profile.dart`. Der Client
 * schickt den Namen mit; alles andere faellt hier heraus.
 *
 * Der Rueckfall ist `maennlich` – aus demselben Grund wie beim Rueckfall auf
 * Deutsch: Ein alter Client, der das Feld noch nicht kennt, bekommt genau
 * das, was er bisher bekommen hat.
 */
export const AUSRICHTUNGEN = ['maennlich', 'weiblich', 'neutral'] as const;

export type Ausrichtung = (typeof AUSRICHTUNGEN)[number];

export function leseAusrichtung(roh: unknown): Ausrichtung {
  return typeof roh === 'string' &&
    (AUSRICHTUNGEN as readonly string[]).includes(roh)
    ? (roh as Ausrichtung)
    : 'maennlich';
}

/**
 * Die Zeile, mit der der Prompt die Person einordnet.
 *
 * Bewusst als Angabe formuliert und nicht als Anweisung, wie jemand
 * auszusehen habe: Das Modell soll wissen, wonach die Empfehlungen sich
 * richten sollen, und nicht, welches Aussehen es erwarten darf.
 */
export const AUSRICHTUNG_KONTEXT: Record<Ausrichtung, Zweisprachig> = {
  maennlich: {
    de: 'Die Person hat angegeben: männlich. Richte Frisur-, Bart- und '
      + 'Stilempfehlungen entsprechend aus.',
    en: 'The person stated: male. Aim your hair, beard and style '
      + 'recommendations accordingly.',
  },
  weiblich: {
    de: 'Die Person hat angegeben: weiblich. Richte Frisur-, Make-up- und '
      + 'Stilempfehlungen entsprechend aus. Es gibt in diesem Report KEINE '
      + 'Bart- oder Rasurempfehlungen.',
    en: 'The person stated: female. Aim your hair, make-up and style '
      + 'recommendations accordingly. This report contains NO beard or '
      + 'shaving advice.',
  },
  neutral: {
    de: 'Die Person hat keine Angabe zum Geschlecht gemacht oder „divers" '
      + 'gewählt. Formuliere geschlechtsneutral, unterstelle keine '
      + 'Zugehörigkeit und richte dich nach dem, was auf den Fotos zu sehen '
      + 'ist.',
    en: 'The person gave no gender or chose non-binary. Write in '
      + 'gender-neutral terms, assume nothing, and go by what the photos '
      + 'actually show.',
  },
};

/** Nimmt den passenden Zweig. */
export function kontextzeile(
  ausrichtung: Ausrichtung,
  sprache: Sprache,
): string {
  return AUSRICHTUNG_KONTEXT[ausrichtung][sprache];
}
