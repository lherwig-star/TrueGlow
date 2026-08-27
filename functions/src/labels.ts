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
  'persoenlicheZiele',
] as const;

export type Modul = (typeof MODULE)[number];

/**
 * Das Kapitel, das aus dem Freitext entsteht – und nur daraus.
 *
 * Es steht in [MODULE], weil es ein Kapitel wie jedes andere ist: Der Report
 * traegt es, die Tagesliste zeigt es, der Check-in passt seine Aufgaben an.
 * Bestellen kann es niemand – [moduleFuer] laesst es nicht durch. Ueber
 * seine Existenz entscheidet allein, ob im Freitextfeld etwas steht.
 *
 * Warum es das gibt: Die Aufgaben aus dem Freitext lagen bisher im
 * "inhaltlich am besten passenden" Kapitel. Bei „aufhoeren zu rauchen" gibt
 * es kein passendes – sie landeten unter „Haare & Bart" und liessen das
 * Kapitel zusammengewuerfelt aussehen. Siehe DECISIONS 39.
 */
export const ZIELKAPITEL: Modul = 'persoenlicheZiele';

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
  // Das Zielkapitel ist nicht waehlbar: Es haengt am Freitext, nicht an einem
  // Haken im Modul-Bildschirm.
  const waehlbar = MODULE.filter((m) => m !== ZIELKAPITEL);
  if (ausrichtung !== 'maennlich') return waehlbar;
  return waehlbar.filter((m) => m !== 'makeupAusstrahlung');
}

/**
 * Abschnittsnamen, die der Prompt dem Modell vorgibt.
 *
 * Sie sind der Grund fuer einen Fehler, der erst am Geraet aufgefallen ist:
 * Ein Name, den der Prompt woertlich nennt, landet woertlich im Report. Stand
 * dort "Sektionen: Frisur, Augenbrauen", schrieb das Modell "Frisur" und
 * "Augenbrauen" auch in einen englischen Report – die Kapitelueberschriften
 * darueber waren laengst englisch.
 *
 * Der uebrige Prompt bleibt einsprachig (Begruendung in DECISIONS 31). Was
 * das Modell abschreiben soll, kann es aber nicht: Diese Namen sind Ausgabe,
 * keine Anweisung.
 */
export const SEKTIONEN = {
  frisur: { de: 'Frisur', en: 'Hair' },
  bart: { de: 'Bart', en: 'Beard' },
  brillenform: { de: 'Brillenform', en: 'Glasses' },
  augenbrauen: { de: 'Augenbrauen', en: 'Eyebrows' },
  alltagsLook: { de: 'Alltags-Look', en: 'Everyday look' },
  farben: { de: 'Farben', en: 'Colours' },
  ziel: { de: 'Dein Ziel', en: 'Your goal' },
  neuerLook: { de: 'Dein neuer Look', en: 'Your new look' },
} as const satisfies Record<string, Zweisprachig>;

export function sektion(
  name: keyof typeof SEKTIONEN,
  sprache: Sprache,
): string {
  return SEKTIONEN[name][sprache];
}

/**
 * Alltagsroutinen, an die sich eine Tagesaufgabe haengen laesst.
 *
 * Der Grund steht in DECISIONS 44: Eine Aufgabe wird eher zur Gewohnheit,
 * wenn sie an etwas gekoppelt ist, das ohnehin jeden Tag passiert. Der
 * Prompt verlangt diese Kopplung, und er nennt dem Modell dafuer eine
 * Auswahl, die praktisch jeder Alltag hergibt.
 *
 * Zweisprachig aus demselben Grund wie die Sektionsnamen (DECISIONS 36):
 * Was der Prompt woertlich nennt, schreibt das Modell woertlich ab. Stuende
 * hier nur Deutsch, begaenne jede Aufgabe im englischen Report mit „Nach dem
 * Zaehneputzen".
 */
export const ANKER: readonly Zweisprachig[] = [
  { de: 'nach dem Aufstehen', en: 'after getting up' },
  { de: 'nach dem Zähneputzen', en: 'after brushing your teeth' },
  { de: 'beim Duschen', en: 'in the shower' },
  { de: 'nach dem Duschen', en: 'after your shower' },
  { de: 'nach dem Frühstück', en: 'after breakfast' },
  { de: 'nach dem Abendessen', en: 'after dinner' },
  { de: 'vor dem Schlafengehen', en: 'before bed' },
];

/** Die Anker als Aufzaehlung fuer den Prompt. */
export function ankerListe(sprache: Sprache): string {
  return ANKER.map((a) => `"${a[sprache]}"`).join(', ');
}

/**
 * Die Kategorie eines Produkts – als Kennung, nicht als Wort.
 *
 * Frueher standen im Prompt deutsche Beispiele ("z.B. Reinigung, Pflege,
 * Styling"), und genau die kamen im englischen Report wieder heraus. Jetzt
 * waehlt das Modell aus einer festen Liste, wie bei "modul", und die App
 * schreibt das Wort dazu. Damit folgt die Kategorie auch dann der
 * App-Sprache, wenn jemand sie nach der Analyse umstellt.
 */
export const PRODUKTKATEGORIEN = [
  'reinigung',
  'pflege',
  'styling',
  'werkzeug',
  'makeup',
  'kleidung',
  'sonstiges',
] as const;

/** Ueberschrift des Report-Kapitels (AnalyseModul.kapitel). */
export const MODUL_KAPITEL: Record<Modul, Zweisprachig> = {
  basis: { de: 'Gesicht, Haare & Bart', en: 'Face, hair & beard' },
  hautFarbtyp: { de: 'Haut & Farbtyp', en: 'Skin & colour type' },
  makeupAusstrahlung: { de: 'Make-up & Ausstrahlung', en: 'Make-up & presence' },
  zaehneLaecheln: { de: 'Zähne & Lächeln', en: 'Teeth & smile' },
  figurPassform: { de: 'Figur & Passform', en: 'Figure & fit' },
  stilKleiderschrank: { de: 'Stil & Kleiderschrank', en: 'Style & wardrobe' },
  persoenlicheZiele: { de: 'Persönliche Ziele', en: 'Personal goals' },
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
  cleanGepflegt: { de: 'Clean & gepflegt', en: 'clean & groomed' },
  markantMaskulin: { de: 'Markant & maskulin', en: 'striking & masculine' },
  natuerlichEntspannt: {
    de: 'Natürlich & entspannt',
    en: 'natural & relaxed',
  },
  weichElegant: { de: 'Weich & elegant', en: 'soft & elegant' },
  streetwearLaessig: { de: 'Streetwear & lässig', en: 'streetwear & casual' },
  smartHochwertig: { de: 'Smart & hochwertig', en: 'smart & refined' },
  sportlichFunktional: {
    de: 'Sportlich & funktional',
    en: 'sporty & functional',
  },
  kreativAuffaellig: { de: 'Kreativ & auffällig', en: 'creative & bold' },
};

/**
 * Was aus den Werten der alten Liste geworden ist.
 *
 * Spiegelt `Richtungsziel._alteNamen` in `richtung.dart`. Der Client fuehrt
 * seine gespeicherte Auswahl beim Lesen selbst ueber; diese Tabelle faengt
 * den anderen Fall ab: eine App-Fassung, die noch nicht aktualisiert wurde
 * und weiterhin die alten Namen schickt. Ohne sie fiele deren Richtung
 * stillschweigend aus dem Prompt heraus – der Nutzer haette etwas gewaehlt,
 * das nirgends ankommt.
 */
export const RICHTUNGSZIEL_ALT: Record<string, string> = {
  maskuliner: 'markantMaskulin',
  markanter: 'markantMaskulin',
  weicher: 'weichElegant',
  gepflegter: 'cleanGepflegt',
  serioeser: 'smartHochwertig',
  reifer: 'smartHochwertig',
  juenger: 'streetwearLaessig',
  natuerlicher: 'natuerlichEntspannt',
  auffaelliger: 'kreativAuffaellig',
  sportlicher: 'sportlichFunktional',
};

/** Fuehrt alte Namen ueber, wirft Unbekanntes und Dubletten weg. */
export function normalisiereRichtungsziele(namen: string[]): string[] {
  const gesehen = new Set<string>();
  for (const name of namen) {
    const neu = RICHTUNGSZIEL_ALT[name] ?? name;
    if (neu in RICHTUNGSZIEL) gesehen.add(neu);
  }
  // Reihenfolge der Tabelle, nicht die der Klicks – damit dieselbe Auswahl
  // immer denselben Prompt ergibt.
  return Object.keys(RICHTUNGSZIEL).filter((n) => gesehen.has(n));
}

/**
 * Was eine gewaehlte Richtung fuer Frisur, Bart und Kleidung konkret heisst.
 *
 * Der Anlass steht in DECISIONS 58: Die Wahl faerbte vorher nur den Ton der
 * Fliesstexte ein. „Richte die Empfehlungen daran aus" ist fuer ein Modell
 * eine Stimmung, keine Vorgabe – im fertigen Report war anschliessend nicht
 * zu erkennen, ob jemand „Streetwear" oder „Smart" gewaehlt hatte.
 *
 * Jeder Eintrag nennt deshalb dieselben drei Dinge beim Namen: Frisur, Bart,
 * Kleidung. Die Kleidungsstuecke sind Gattungsbegriffe, keine Marken.
 */
export const RICHTUNGSVORGABE: Beschriftungen = {
  cleanGepflegt: {
    de: 'Saubere Konturen und ein Schnitt, der ohne Styling in Form bleibt; '
      + 'Bart kurz und exakt konturiert oder glatt rasiert; Kleidung '
      + 'schlicht und gut sitzend, wenige Farben, keine Aufdrucke.',
    en: 'Clean outlines and a cut that holds its shape without styling; '
      + 'beard short and precisely lined or clean-shaven; clothing plain '
      + 'and well-fitting, few colours, no prints.',
  },
  markantMaskulin: {
    de: 'Kurze Seiten mit klarer Kante und Länge oben; ein Bart, der die '
      + 'Kieferlinie betont; Kleidung mit Struktur in den Schultern, '
      + 'kräftige Stoffe, dunkle und erdige Töne.',
    en: 'Short sides with a defined edge and length on top; a beard that '
      + 'emphasises the jawline; clothing with structure in the shoulders, '
      + 'sturdy fabrics, dark and earthy tones.',
  },
  natuerlichEntspannt: {
    de: 'Ein Schnitt, der mitwächst und keine tägliche Formgebung '
      + 'braucht; Bart gepflegt, aber nicht scharf gezogen; Kleidung '
      + 'bequem, weiche Stoffe, gedeckte Farben, nichts Auffälliges.',
    en: 'A cut that grows out well and needs no daily styling; beard tidy '
      + 'but not sharply lined; clothing comfortable, soft fabrics, muted '
      + 'colours, nothing showy.',
  },
  weichElegant: {
    de: 'Ein Schnitt mit weichen Übergängen statt harter Kanten, längere '
      + 'Partien dürfen fallen; Bart weich konturiert oder glatt rasiert; '
      + 'Kleidung mit fließendem Fall, feine Stoffe, helle und ruhige Töne.',
    en: 'A cut with soft transitions instead of hard edges, longer sections '
      + 'may fall freely; beard softly shaped or clean-shaven; clothing '
      + 'with drape, fine fabrics, light and calm tones.',
  },
  streetwearLaessig: {
    de: 'Schnitt mit sichtbarer Textur, gern länger oben oder im Nacken; '
      + 'Bart locker gehalten; Kleidung weit geschnitten – Baggy- oder '
      + 'Loose-Fit-Hosen, Oversize-Oberteile, Hoodies, Sneaker als '
      + 'Mittelpunkt des Outfits.',
    en: 'A cut with visible texture, happily longer on top or at the neck; '
      + 'beard kept loose; clothing cut wide – baggy or loose-fit trousers, '
      + 'oversized tops, hoodies, sneakers as the centre of the outfit.',
  },
  smartHochwertig: {
    de: 'Eine sauber geschnittene, klassische Form, die immer ordentlich '
      + 'aussieht; Bart kurz und exakt oder glatt; Kleidung in klaren '
      + 'Silhouetten – Polo, Feinstrick, Hemd, gerade Hose, Ledersneaker '
      + 'oder Loafer, gedeckte Farben, sichtbar gute Stoffe.',
    en: 'A cleanly cut classic shape that always looks tidy; beard short '
      + 'and precise or clean-shaven; clothing in clean silhouettes – '
      + 'polo, fine knit, shirt, straight trousers, leather sneakers or '
      + 'loafers, muted colours, visibly good fabrics.',
  },
  sportlichFunktional: {
    de: 'Kurzer, pflegeleichter Schnitt, der Schweiß und Mütze '
      + 'übersteht; Bart kurz; Kleidung mit Bewegungsfreiheit, '
      + 'atmungsaktive und robuste Stoffe, technische Details, '
      + 'Sportschuhe.',
    en: 'A short, low-maintenance cut that survives sweat and a cap; beard '
      + 'short; clothing with freedom of movement, breathable and '
      + 'hard-wearing fabrics, technical details, athletic shoes.',
  },
  kreativAuffaellig: {
    de: 'Ein Schnitt mit einer bewussten Besonderheit – asymmetrisch, '
      + 'kontrastreich oder mit farblichem Akzent; Bart als Teil der Form; '
      + 'Kleidung mit einem Statement-Teil pro Outfit, mutigere Schnitte, '
      + 'Farbe oder Muster, der Rest ruhig dazu.',
    en: 'A cut with one deliberate feature – asymmetric, high-contrast or '
      + 'with a colour accent; beard as part of the shape; clothing with '
      + 'one statement piece per outfit, braver cuts, colour or pattern, '
      + 'the rest kept quiet.',
  },
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
