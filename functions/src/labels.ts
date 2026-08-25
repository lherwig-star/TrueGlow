import { type Sprache, type Zweisprachig } from './sprache';
import { type Ausrichtung } from './ausrichtung';

/**
 * Beschriftungen zu den stabilen Enum-Namen der App – in beiden Sprachen.
 *
 * Der Client schickt ausschliesslich Enum-*Namen* (`mittel`, `basisFrontal`,
 * `markanter` …), nie fertige Prompt-Texte. Damit kann kein manipulierter
 * Client Anweisungen in den Prompt schmuggeln: Alles, was hier nicht
 * eingetragen ist, faellt heraus.
 *
 * Die Werte spiegeln die Dart-Enums in `lib/features/**\/models`. Wer dort ein
 * Label aendert, aendert nur die Anzeige – der Prompt haengt an dieser Datei.
 *
 * Deutsch und Englisch stehen absichtlich im selben Eintrag und nicht in zwei
 * Tabellen: So laesst sich keine Sprache nachtragen, ohne die andere zu
 * sehen, und ein vergessener Eintrag faellt beim Lesen auf statt erst im
 * Report.
 */

/** Tabelle mit zweisprachigen Werten. */
export type Beschriftungen = Record<string, Zweisprachig>;

/** Schlaegt einen Namen nach; unbekannte Namen liefern `undefined`. */
export function label(
  tabelle: Beschriftungen,
  name: unknown,
  sprache: Sprache,
): string | undefined {
  if (typeof name !== 'string') return undefined;
  return tabelle[name]?.[sprache];
}

/** Mehrere Namen auf einmal, unbekannte fallen weg, Reihenfolge der Tabelle. */
export function labels(
  tabelle: Beschriftungen,
  namen: unknown,
  sprache: Sprache,
): string[] {
  if (!Array.isArray(namen)) return [];
  const gesetzt = new Set(namen.filter((n) => typeof n === 'string'));
  return Object.entries(tabelle)
    .filter(([name]) => gesetzt.has(name))
    .map(([, wert]) => wert[sprache]);
}

// --- Module ------------------------------------------------------------

export const MODULE = [
  'basis',
  'hautFarbtyp',
  'makeupAusstrahlung',
  'zaehneLaecheln',
  'figurPassform',
  'stilKleiderschrank',
] as const;

export type Modul = (typeof MODULE)[number];

export function istModul(name: unknown): name is Modul {
  return typeof name === 'string' && (MODULE as readonly string[]).includes(name);
}

/**
 * Die Module, die es in dieser Ausrichtung ueberhaupt gibt.
 *
 * Spiegelt `AnalyseModul.waehlbareFuer` im Client. Es steht hier ein zweites
 * Mal, weil der Client nicht vertrauenswuerdig ist: Eine alte oder
 * manipulierte Fassung darf kein Kapitel bestellen koennen, das es in ihrem
 * Modus nicht gibt.
 *
 * Bart ist bewusst nicht dabei – er ist kein Modul, sondern ein Abschnitt der
 * Basis. Ihn haelt die Nachbereitung heraus, nicht diese Liste.
 */
export function moduleFuer(ausrichtung: Ausrichtung): readonly Modul[] {
  if (ausrichtung !== 'maennlich') return MODULE;
  return MODULE.filter((m) => m !== 'makeupAusstrahlung');
}

/** Ueberschrift des Report-Kapitels (AnalyseModul.kapitel). */
export const MODUL_KAPITEL: Record<Modul, Zweisprachig> = {
  basis: { de: 'Gesicht, Haare & Bart', en: 'Face, hair & beard' },
  hautFarbtyp: { de: 'Haut & Farbtyp', en: 'Skin & colour type' },
  makeupAusstrahlung: { de: 'Make-up & Ausstrahlung', en: 'Make-up & presence' },
  zaehneLaecheln: { de: 'Zähne & Lächeln', en: 'Teeth & smile' },
  figurPassform: { de: 'Figur & Passform', en: 'Figure & fit' },
  stilKleiderschrank: { de: 'Stil & Kleiderschrank', en: 'Style & wardrobe' },
};

/**
 * Die Basis heisst im weiblichen Modus anders, weil sie dort etwas anderes
 * enthaelt – dieselbe Regel wie in `AnalyseModulText.titel` auf dem Client.
 */
export const MODUL_KAPITEL_WEIBLICH: Partial<Record<Modul, Zweisprachig>> = {
  basis: { de: 'Gesicht & Haare', en: 'Face & hair' },
};

/** Kapitelueberschrift, passend zur Ausrichtung. */
export function kapitelUeberschrift(
  modul: Modul,
  ausrichtung: string,
  sprache: Sprache,
): string {
  const abweichend =
    ausrichtung === 'weiblich' ? MODUL_KAPITEL_WEIBLICH[modul] : undefined;
  return (abweichend ?? MODUL_KAPITEL[modul])[sprache];
}

// --- Aufnahmen ---------------------------------------------------------

/** AufnahmeTyp-Name → { Beschriftung, Modul }. Reihenfolge = Flow-Reihenfolge. */
export const AUFNAHMEN: Record<string, { label: Zweisprachig; modul: Modul }> = {
  basisFrontal: {
    label: { de: 'Frontalfoto', en: 'Front photo' },
    modul: 'basis',
  },
  basisProfilLinks: {
    label: { de: 'Profil links', en: 'Left profile' },
    modul: 'basis',
  },
  basisProfilRechts: {
    label: { de: 'Profil rechts', en: 'Right profile' },
    modul: 'basis',
  },
  basisWinkel45: {
    label: { de: '45°-Winkel', en: '45° angle' },
    modul: 'basis',
  },
  // hautFarbtyp bringt keine eigene Aufnahme mehr mit – die Hautton-Analyse
  // liest das Frontalfoto der Basis. Siehe DECISIONS.md.
  zaehneLaecheln: {
    label: { de: 'Lächeln', en: 'Smile' },
    modul: 'zaehneLaecheln',
  },
  figurGanzkoerperFrontal: {
    label: { de: 'Ganzkörper frontal', en: 'Full body, front' },
    modul: 'figurPassform',
  },
  figurGanzkoerperSeitlich: {
    label: { de: 'Ganzkörper seitlich', en: 'Full body, side' },
    modul: 'figurPassform',
  },
  stilOutfitEins: {
    label: { de: 'Outfit 1', en: 'Outfit 1' },
    modul: 'stilKleiderschrank',
  },
  stilOutfitZwei: {
    label: { de: 'Outfit 2', en: 'Outfit 2' },
    modul: 'stilKleiderschrank',
  },
  stilOutfitDrei: {
    label: { de: 'Outfit 3', en: 'Outfit 3' },
    modul: 'stilKleiderschrank',
  },
};

// --- Onboarding --------------------------------------------------------

/**
 * Altersbereiche. „unter 18" fehlt hier absichtlich: Die App ist ab 18, und
 * ein unbekannter Name faellt in `label()` ohnehin heraus.
 */
export const ALTER: Beschriftungen = {
  a18bis24: { de: '18–24', en: '18–24' },
  a25bis34: { de: '25–34', en: '25–34' },
  a35bis44: { de: '35–44', en: '35–44' },
  ab45: { de: '45+', en: '45+' },
};

/** Budget mit Beschreibung, so wie der Prompt es formuliert. */
export const BUDGET: Beschriftungen = {
  niedrig: {
    de: 'Niedrig (Drogerie, unter 30 € im Monat)',
    en: 'Low (drugstore, under €30 a month)',
  },
  mittel: {
    de: 'Mittel (30–80 € im Monat)',
    en: 'Medium (€30–80 a month)',
  },
  hoch: {
    de: 'Hoch (über 80 € im Monat)',
    en: 'High (over €80 a month)',
  },
};

export const ZEIT: Beschriftungen = {
  kurz: { de: '5 Minuten', en: '5 minutes' },
  mittel: { de: '15 Minuten', en: '15 minutes' },
  lang: { de: '30+ Minuten', en: '30+ minutes' },
};

export const FOKUS: Beschriftungen = {
  haut: { de: 'Haut', en: 'skin' },
  haare: { de: 'Haare', en: 'hair' },
  bart: { de: 'Bart', en: 'beard' },
  style: { de: 'Style', en: 'style' },
  fitness: { de: 'Fitness-Habits', en: 'fitness habits' },
};

// --- Stil-Fragebogen ---------------------------------------------------

export const STILZIEL: Beschriftungen = {
  klassisch: { de: 'Klassisch', en: 'classic' },
  minimalistisch: { de: 'Minimalistisch', en: 'minimalist' },
  sportlich: { de: 'Sportlich', en: 'sporty' },
  smartCasual: { de: 'Smart Casual', en: 'smart casual' },
  kreativ: { de: 'Kreativ', en: 'creative' },
  rockig: { de: 'Rockig', en: 'rock' },
};

export const DRESSCODE: Beschriftungen = {
  buero: { de: 'Büro / formell', en: 'office / formal' },
  businessCasual: { de: 'Business Casual', en: 'business casual' },
  handwerk: { de: 'Handwerk / Arbeitskleidung', en: 'trades / workwear' },
  homeoffice: { de: 'Homeoffice', en: 'working from home' },
  uniform: { de: 'Uniform / Dienstkleidung', en: 'uniform / service dress' },
  frei: { de: 'Keine Vorgaben', en: 'no dress code' },
};

export const KLEIDUNGSBUDGET: Beschriftungen = {
  klein: { de: 'Bis 50 € pro Teil', en: 'up to €50 per item' },
  mittel: { de: '50–150 € pro Teil', en: '€50–150 per item' },
  gross: { de: 'Über 150 € pro Teil', en: 'over €150 per item' },
};

export const PFLEGEAUFWAND: Beschriftungen = {
  minimal: { de: 'So wenig wie möglich', en: 'as little as possible' },
  mittel: { de: 'Etwas Aufwand ist okay', en: 'a bit of effort is fine' },
  hoch: { de: 'Ich investiere gern Zeit', en: 'happy to put time in' },
};

// --- Richtung ----------------------------------------------------------

export const RICHTUNGSZIEL: Beschriftungen = {
  maskuliner: { de: 'Maskuliner', en: 'more masculine' },
  weicher: { de: 'Weicher / Sanfter', en: 'softer / gentler' },
  markanter: { de: 'Markanter', en: 'more striking' },
  gepflegter: { de: 'Gepflegter', en: 'better groomed' },
  serioeser: {
    de: 'Seriöser / Professioneller',
    en: 'more serious / professional',
  },
  juenger: { de: 'Jünger wirken', en: 'look younger' },
  reifer: { de: 'Reifer wirken', en: 'look more mature' },
  natuerlicher: { de: 'Natürlicher', en: 'more natural' },
  auffaelliger: { de: 'Auffälliger / Mutiger', en: 'bolder' },
  sportlicher: { de: 'Sportlicher', en: 'more athletic' },
};

// --- Check-in ----------------------------------------------------------

export const CHECKIN_TYP: Beschriftungen = {
  alltag: { de: 'Alltags-Check', en: 'everyday check' },
  zwischen: { de: 'Zwischencheck', en: 'halfway check' },
  wirkung: { de: 'Wirkungs-Check', en: 'results check' },
};

/** Nur der Wirkungs-Check bringt ein Fortschrittsfoto mit. */
export function mitFortschrittsfoto(typ: unknown): boolean {
  return typ === 'wirkung';
}

export const HABIT_BEWERTUNG: Beschriftungen = {
  laeuftGut: { de: 'Läuft gut', en: 'going well' },
  gehtSo: { de: 'Geht so', en: 'so-so' },
  passtNicht: { de: 'Passt nicht', en: 'not working' },
};

/** Grund plus Anweisung an das Modell (PasstNichtGrund). */
export const PASST_NICHT_GRUND: Record<
  string,
  { label: Zweisprachig; anweisung: Zweisprachig }
> = {
  zeit: {
    label: { de: 'Zu zeitaufwendig', en: 'takes too long' },
    anweisung: {
      de: 'kürzere Alternative oder geringere Frequenz wählen',
      en: 'pick a shorter alternative or a lower frequency',
    },
  },
  vergessen: {
    label: { de: 'Vergesse ich', en: 'I forget' },
    anweisung: {
      de: 'an eine bestehende Alltagsroutine koppeln (Trigger nennen)',
      en: 'attach it to an existing daily routine (name the trigger)',
    },
  },
  unangenehm: {
    label: { de: 'Unangenehm / mag ich nicht', en: "unpleasant / don't like it" },
    anweisung: {
      de: 'durch etwas ersetzen, das denselben Zweck angenehmer erreicht',
      en: 'replace it with something that serves the same purpose more pleasantly',
    },
  },
  teuer: {
    label: { de: 'Zu teuer', en: 'too expensive' },
    anweisung: {
      de: 'günstigere Alternative mit gleichem Zweck vorschlagen',
      en: 'suggest a cheaper alternative with the same purpose',
    },
  },
  anderer: {
    label: { de: 'Anderer Grund', en: 'another reason' },
    anweisung: {
      de: 'den genannten Grund berücksichtigen',
      en: 'take the stated reason into account',
    },
  },
};

export const WIRKUNGS_ANTWORT: Beschriftungen = {
  besser: { de: 'Besser', en: 'better' },
  gleich: { de: 'Gleich', en: 'the same' },
  schlechter: { de: 'Schlechter', en: 'worse' },
};
