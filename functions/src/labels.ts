/**
 * Deutsche Beschriftungen zu den stabilen Enum-Namen der App.
 *
 * Der Client schickt ausschliesslich Enum-*Namen* (`mittel`, `basisFrontal`,
 * `markanter` …), nie fertige Prompt-Texte. Damit kann kein manipulierter
 * Client Anweisungen in den Prompt schmuggeln: Alles, was hier nicht
 * eingetragen ist, faellt heraus.
 *
 * Die Werte spiegeln die Dart-Enums in `lib/features/**\/models`. Wer dort ein
 * Label aendert, aendert nur die Anzeige – der Prompt haengt an dieser Datei.
 */

/** Hilfsfunktion: schlaegt einen Namen nach und liefert `undefined`, wenn er unbekannt ist. */
export function label(
  tabelle: Record<string, string>,
  name: unknown,
): string | undefined {
  return typeof name === 'string' ? tabelle[name] : undefined;
}

/** Mehrere Namen auf einmal, unbekannte fallen weg, Reihenfolge der Tabelle. */
export function labels(
  tabelle: Record<string, string>,
  namen: unknown,
): string[] {
  if (!Array.isArray(namen)) return [];
  const gesetzt = new Set(namen.filter((n) => typeof n === 'string'));
  return Object.entries(tabelle)
    .filter(([name]) => gesetzt.has(name))
    .map(([, wert]) => wert);
}

// --- Module ------------------------------------------------------------

export const MODULE = [
  'basis',
  'hautFarbtyp',
  'zaehneLaecheln',
  'figurPassform',
  'stilKleiderschrank',
] as const;

export type Modul = (typeof MODULE)[number];

export function istModul(name: unknown): name is Modul {
  return typeof name === 'string' && (MODULE as readonly string[]).includes(name);
}

/** Ueberschrift des Report-Kapitels (AnalyseModul.kapitel). */
export const MODUL_KAPITEL: Record<Modul, string> = {
  basis: 'Gesicht, Haare & Bart',
  hautFarbtyp: 'Haut & Farbtyp',
  zaehneLaecheln: 'Zähne & Lächeln',
  figurPassform: 'Figur & Passform',
  stilKleiderschrank: 'Stil & Kleiderschrank',
};

// --- Aufnahmen ---------------------------------------------------------

/** AufnahmeTyp-Name → { Beschriftung, Modul }. Reihenfolge = Flow-Reihenfolge. */
export const AUFNAHMEN: Record<string, { label: string; modul: Modul }> = {
  basisFrontal: { label: 'Frontalfoto', modul: 'basis' },
  basisProfilLinks: { label: 'Profil links', modul: 'basis' },
  basisProfilRechts: { label: 'Profil rechts', modul: 'basis' },
  basisWinkel45: { label: '45°-Winkel', modul: 'basis' },
  hautNahaufnahme: { label: 'Nahaufnahme', modul: 'hautFarbtyp' },
  zaehneLaecheln: { label: 'Lächeln', modul: 'zaehneLaecheln' },
  figurGanzkoerperFrontal: {
    label: 'Ganzkörper frontal',
    modul: 'figurPassform',
  },
  figurGanzkoerperSeitlich: {
    label: 'Ganzkörper seitlich',
    modul: 'figurPassform',
  },
  stilOutfitEins: { label: 'Outfit 1', modul: 'stilKleiderschrank' },
  stilOutfitZwei: { label: 'Outfit 2', modul: 'stilKleiderschrank' },
  stilOutfitDrei: { label: 'Outfit 3', modul: 'stilKleiderschrank' },
};

// --- Onboarding --------------------------------------------------------

export const ALTER: Record<string, string> = {
  unter18: 'unter 18',
  a18bis24: '18–24',
  a25bis34: '25–34',
  a35bis44: '35–44',
  ab45: '45+',
};

/** Budget mit Beschreibung, so wie der Prompt es formuliert. */
export const BUDGET: Record<string, string> = {
  niedrig: 'Niedrig (Drogerie, unter 30 € im Monat)',
  mittel: 'Mittel (30–80 € im Monat)',
  hoch: 'Hoch (über 80 € im Monat)',
};

export const ZEIT: Record<string, string> = {
  kurz: '5 Minuten',
  mittel: '15 Minuten',
  lang: '30+ Minuten',
};

export const FOKUS: Record<string, string> = {
  haut: 'Haut',
  haare: 'Haare',
  bart: 'Bart',
  style: 'Style',
  fitness: 'Fitness-Habits',
};

// --- Stil-Fragebogen ---------------------------------------------------

export const STILZIEL: Record<string, string> = {
  klassisch: 'Klassisch',
  minimalistisch: 'Minimalistisch',
  sportlich: 'Sportlich',
  smartCasual: 'Smart Casual',
  kreativ: 'Kreativ',
  rockig: 'Rockig',
};

export const DRESSCODE: Record<string, string> = {
  buero: 'Büro / formell',
  businessCasual: 'Business Casual',
  handwerk: 'Handwerk / Arbeitskleidung',
  homeoffice: 'Homeoffice',
  uniform: 'Uniform / Dienstkleidung',
  frei: 'Keine Vorgaben',
};

export const KLEIDUNGSBUDGET: Record<string, string> = {
  klein: 'Bis 50 € pro Teil',
  mittel: '50–150 € pro Teil',
  gross: 'Über 150 € pro Teil',
};

export const PFLEGEAUFWAND: Record<string, string> = {
  minimal: 'So wenig wie möglich',
  mittel: 'Etwas Aufwand ist okay',
  hoch: 'Ich investiere gern Zeit',
};

// --- Richtung ----------------------------------------------------------

export const RICHTUNGSZIEL: Record<string, string> = {
  maskuliner: 'Maskuliner',
  weicher: 'Weicher / Sanfter',
  markanter: 'Markanter',
  gepflegter: 'Gepflegter',
  serioeser: 'Seriöser / Professioneller',
  juenger: 'Jünger wirken',
  reifer: 'Reifer wirken',
  natuerlicher: 'Natürlicher',
  auffaelliger: 'Auffälliger / Mutiger',
  sportlicher: 'Sportlicher',
};

// --- Check-in ----------------------------------------------------------

export const CHECKIN_TYP: Record<string, string> = {
  alltag: 'Alltags-Check',
  zwischen: 'Zwischencheck',
  wirkung: 'Wirkungs-Check',
};

/** Nur der Wirkungs-Check bringt ein Fortschrittsfoto mit. */
export function mitFortschrittsfoto(typ: unknown): boolean {
  return typ === 'wirkung';
}

export const HABIT_BEWERTUNG: Record<string, string> = {
  laeuftGut: 'Läuft gut',
  gehtSo: 'Geht so',
  passtNicht: 'Passt nicht',
};

/** Grund plus Anweisung an das Modell (PasstNichtGrund.label / .anweisung). */
export const PASST_NICHT_GRUND: Record<
  string,
  { label: string; anweisung: string }
> = {
  zeit: {
    label: 'Zu zeitaufwendig',
    anweisung: 'kürzere Alternative oder geringere Frequenz wählen',
  },
  vergessen: {
    label: 'Vergesse ich',
    anweisung: 'an eine bestehende Alltagsroutine koppeln (Trigger nennen)',
  },
  unangenehm: {
    label: 'Unangenehm / mag ich nicht',
    anweisung:
      'durch etwas ersetzen, das denselben Zweck angenehmer erreicht',
  },
  teuer: {
    label: 'Zu teuer',
    anweisung: 'günstigere Alternative mit gleichem Zweck vorschlagen',
  },
  anderer: {
    label: 'Anderer Grund',
    anweisung: 'den genannten Grund berücksichtigen',
  },
};

export const WIRKUNGS_ANTWORT: Record<string, string> = {
  besser: 'Besser',
  gleich: 'Gleich',
  schlechter: 'Schlechter',
};
