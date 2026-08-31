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

// `STILZIEL` gibt es nicht mehr: Das Stilziel ist dieselbe Liste wie die
// Richtung (`RICHTUNGSZIEL`). Zwei Listen fuer dieselbe Sache waren zwei
// Pflegestellen – und im Prompt zwei Angaben, die sich widersprechen
// konnten. Die alten Namen fuehrt `RICHTUNGSZIEL_ALT` ueber (DECISIONS 72).

/**
 * Wofuer der Stil im Alltag vor allem funktionieren soll.
 *
 * Loest den frueheren `DRESSCODE` ab. "Handwerk / Arbeitskleidung" und
 * "Uniform / Dienstkleidung" sind ersatzlos weg: Wer Arbeitskleidung
 * gestellt bekommt, hat daran nichts zu entscheiden.
 */
export const ALLTAGSZWECK: Beschriftungen = {
  uniSchule: { de: 'Uni / Schule / Ausbildung', en: 'uni / school / training' },
  ausgehenDates: { de: 'Ausgehen & Dates', en: 'going out & dates' },
  arbeitNebenjob: { de: 'Arbeit / Nebenjob', en: 'work / part-time job' },
  gymSport: { de: 'Gym & Sport', en: 'gym & sport' },
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
  // Und die Werte des frueheren, eigenen Stilziels (DECISIONS 72). Zwei
  // davon landen auf demselben neuen Wert – eine Menge nimmt das hin.
  klassisch: 'smartHochwertig',
  smartCasual: 'smartHochwertig',
  minimalistisch: 'cleanGepflegt',
  sportlich: 'sportlichFunktional',
  kreativ: 'kreativAuffaellig',
  rockig: 'markantMaskulin',
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

// --- Ausprobieren ------------------------------------------------------

/**
 * Eine Technik aus „Das will ich ausprobieren" (DECISIONS 79).
 *
 * Drei Textfelder, alle zweisprachig, und jedes hat einen anderen Grund:
 *
 * - `label` ist der Name, den der Report traegt. Er steht in der
 *   Zielsprache, weil das Modell woertlich abschreibt, was der Prompt
 *   woertlich nennt (DECISIONS 36) — und weil die App genau diesen Namen
 *   im Feld "neu" wiedererkennen muss.
 * - `takt` ist die fachlich richtige Haeufigkeit. Sie steht hier und nicht
 *   im Ermessen des Modells: Gua Sha jeden Tag als Pflicht ist keine
 *   Empfehlung mehr, sondern eine Belastung, und ein Peeling dreimal die
 *   Woche schadet.
 * - `hinweis` ist der Satz zur Vertraeglichkeit. Er ist kein
 *   Kleingedrucktes, sondern Teil der Anleitung: Gua Sha auf trockener
 *   Haut zieht, ein Peeling ohne Sonnenschutz danach ist ein Schaden.
 */
export interface Technik {
  modul: Modul;
  /** Fuer wen es die Technik gibt. Fehlt das Feld, gilt sie fuer alle. */
  nur?: Ausrichtung;
  label: Zweisprachig;
  takt: Zweisprachig;
  hinweis: Zweisprachig;
}

/**
 * Der Katalog. Spiegelt das Enum `Technik` in
 * `lib/features/ausprobieren/models/technik.dart` — dieselbe Reihenfolge,
 * dieselben Namen.
 *
 * Er steht hier ein zweites Mal, aus demselben Grund wie [moduleFuer]: Der
 * Client ist nicht vertrauenswuerdig. Eine alte oder veraenderte App darf
 * keine Technik bestellen koennen, die es in ihrem Modus nicht gibt — und
 * schon gar keine, die es gar nicht gibt.
 */
export const TECHNIK = {
  kopfhautmassage: {
    modul: 'basis',
    label: { de: 'Kopfhautmassage', en: 'Scalp massage' },
    takt: { de: 'täglich, 2 Minuten', en: 'daily, 2 minutes' },
    hinweis: {
      de: 'mit den Fingerkuppen, nicht mit den Nägeln',
      en: 'with the fingertips, not the nails',
    },
  },
  rosmarinoel: {
    modul: 'basis',
    label: {
      de: 'Rosmarinöl für die Kopfhaut',
      en: 'Rosemary oil for the scalp',
    },
    takt: { de: '2-3× pro Woche', en: '2-3 times a week' },
    hinweis: {
      de: 'immer verdünnt in einem Trägeröl, nie pur; bei gereizter '
        + 'Kopfhaut weglassen',
      en: 'always diluted in a carrier oil, never neat; skip it on an '
        + 'irritated scalp',
    },
  },
  foehnRundbuerste: {
    modul: 'basis',
    label: {
      de: 'Föhnen mit der Rundbürste',
      en: 'Blow-drying with a round brush',
    },
    takt: { de: 'nach jeder Haarwäsche', en: 'after every wash' },
    hinweis: {
      de: 'mittlere Hitze, Abstand halten, kalt abschließen',
      en: 'medium heat, keep some distance, finish on cold',
    },
  },
  haaroelkur: {
    modul: 'basis',
    label: {
      de: 'Haar-Ölkur über Nacht',
      en: 'Overnight hair oil treatment',
    },
    takt: { de: '1× pro Woche, über Nacht', en: 'once a week, overnight' },
    hinweis: {
      de: 'nur in die Längen, nicht auf den Ansatz',
      en: 'lengths only, not the roots',
    },
  },
  seidenkissen: {
    modul: 'basis',
    label: { de: 'Seidenkissenbezug', en: 'Silk pillowcase' },
    takt: { de: 'jede Nacht', en: 'every night' },
    hinweis: {
      de: 'nichts aufzutragen, nur ein Wechsel des Bezugs; regelmäßig '
        + 'waschen',
      en: 'nothing to apply, just a change of pillowcase; wash it '
        + 'regularly',
    },
  },
  bartoelRoutine: {
    modul: 'basis',
    nur: 'maennlich',
    label: { de: 'Bartöl & Balsam', en: 'Beard oil & balm' },
    takt: { de: 'täglich nach dem Waschen', en: 'daily after washing' },
    hinweis: {
      de: 'wenige Tropfen, in die Haut darunter einarbeiten',
      en: 'a few drops, worked into the skin underneath',
    },
  },
  bartbuerste: {
    modul: 'basis',
    nur: 'maennlich',
    label: { de: 'Bartbürste', en: 'Beard brush' },
    takt: { de: 'täglich', en: 'daily' },
    hinweis: {
      de: 'weiche Borste, in Wuchsrichtung, ohne Druck',
      en: 'soft bristle, in the direction of growth, without pressure',
    },
  },
  guaSha: {
    modul: 'hautFarbtyp',
    label: { de: 'Gua Sha', en: 'Gua sha' },
    takt: {
      de: '2-3× pro Woche, je 5 Minuten',
      en: '2-3 times a week, 5 minutes each',
    },
    hinweis: {
      de: 'nie auf trockener Haut – immer mit Öl oder Serum; sanfter '
        + 'Druck, von der Mitte nach außen; entzündete Stellen aussparen',
      en: 'never on dry skin – always with oil or serum; light pressure, '
        + 'from the centre outwards; avoid inflamed areas',
    },
  },
  gesichtsyoga: {
    modul: 'hautFarbtyp',
    label: { de: 'Gesichtsyoga', en: 'Face yoga' },
    takt: { de: 'täglich, 5 Minuten', en: 'daily, 5 minutes' },
    hinweis: {
      de: 'ohne an der Haut zu ziehen; bei Kieferbeschwerden nur sanft',
      en: 'without pulling at the skin; go gently if the jaw is sensitive',
    },
  },
  iceRolling: {
    modul: 'hautFarbtyp',
    label: { de: 'Ice Rolling am Morgen', en: 'Ice rolling in the morning' },
    takt: {
      de: 'täglich am Morgen, 1-2 Minuten',
      en: 'daily in the morning, 1-2 minutes',
    },
    hinweis: {
      de: 'nicht zu lange auf einer Stelle; bei sichtbar erweiterten '
        + 'Äderchen weglassen',
      en: 'never too long on one spot; skip it with visibly broken '
        + 'capillaries',
    },
  },
  lymphmassage: {
    modul: 'hautFarbtyp',
    label: { de: 'Lymph-Gesichtsmassage', en: 'Facial lymphatic massage' },
    takt: { de: '3-4× pro Woche', en: '3-4 times a week' },
    hinweis: {
      de: 'sehr leichter Druck; bei geschwollenen Lymphknoten oder einem '
        + 'Infekt aussetzen',
      en: 'very light pressure; skip it with swollen lymph nodes or an '
        + 'infection',
    },
  },
  sanftesPeeling: {
    modul: 'hautFarbtyp',
    label: {
      de: 'Sanftes chemisches Peeling',
      en: 'Gentle chemical exfoliant',
    },
    takt: { de: 'höchstens 1-2× pro Woche', en: 'at most 1-2 times a week' },
    hinweis: {
      de: 'langsam einschleichen – erst alle zehn Tage, dann steigern; am '
        + 'nächsten Tag Sonnenschutz; nicht mit anderen Säuren '
        + 'kombinieren',
      en: 'ease in slowly – every ten days at first, then increase; '
        + 'sunscreen the next day; do not combine it with other acids',
    },
  },
  sheetMaske: {
    modul: 'hautFarbtyp',
    label: { de: 'Sheet-Masken-Ritual', en: 'Sheet mask ritual' },
    takt: { de: '1× pro Woche', en: 'once a week' },
    hinweis: {
      de: 'höchstens 20 Minuten, danach nicht abspülen',
      en: '20 minutes at most, do not rinse afterwards',
    },
  },
  lippenpeeling: {
    modul: 'hautFarbtyp',
    nur: 'weiblich',
    label: { de: 'Lippen-Peeling', en: 'Lip scrub' },
    takt: { de: '1-2× pro Woche', en: '1-2 times a week' },
    hinweis: {
      de: 'sehr sanft, danach Balsam; nicht auf rissigen Lippen',
      en: 'very gently, balm afterwards; not on cracked lips',
    },
  },
  nagelpflege: {
    modul: 'hautFarbtyp',
    nur: 'weiblich',
    label: { de: 'Nagelpflege-Routine', en: 'Nail care routine' },
    takt: { de: '1× pro Woche', en: 'once a week' },
    hinweis: {
      de: 'Nagelhaut nur zurückschieben, nicht schneiden',
      en: 'push the cuticles back, do not cut them',
    },
  },
  augenbrauenWimpern: {
    modul: 'makeupAusstrahlung',
    label: { de: 'Augenbrauen- & Wimpernpflege', en: 'Brow & lash care' },
    takt: { de: 'täglich', en: 'daily' },
    hinweis: {
      de: 'bürsten und pflegen; kein Wirkstoff-Serum ohne ärztlichen Rat',
      en: 'brushing and care only; no active serum without medical advice',
    },
  },
  pinselhygiene: {
    modul: 'makeupAusstrahlung',
    label: { de: 'Pinsel sauber halten', en: 'Keeping the brushes clean' },
    takt: { de: 'alle 2 Wochen', en: 'every two weeks' },
    hinweis: {
      de: 'milde Seife, flach liegend trocknen lassen',
      en: 'mild soap, dried lying flat',
    },
  },
  lidschattenbasis: {
    modul: 'makeupAusstrahlung',
    label: { de: 'Grundierung für die Lider', en: 'Eyeshadow primer' },
    takt: { de: 'an jedem Tag mit Make-up', en: 'on every day with make-up' },
    hinweis: {
      de: 'dünn auftragen und kurz antrocknen lassen',
      en: 'applied thinly and left to set for a moment',
    },
  },
  rougePlatzierung: {
    modul: 'makeupAusstrahlung',
    label: {
      de: 'Rouge bewusst platzieren',
      en: 'Placing blush deliberately',
    },
    takt: { de: 'an jedem Tag mit Make-up', en: 'on every day with make-up' },
    hinweis: {
      de: 'wenig auftragen und die Kanten auslaufen lassen',
      en: 'use little and blend the edges out',
    },
  },
  oelziehen: {
    modul: 'zaehneLaecheln',
    label: { de: 'Ölziehen', en: 'Oil pulling' },
    takt: {
      de: 'täglich am Morgen, 5-10 Minuten',
      en: 'daily in the morning, 5-10 minutes',
    },
    hinweis: {
      de: 'ins Papier ausspucken, nicht ins Waschbecken; ersetzt kein '
        + 'Zähneputzen',
      en: 'spit into a tissue, not the sink; it does not replace brushing',
    },
  },
  zungenschaber: {
    modul: 'zaehneLaecheln',
    label: { de: 'Zungenschaber', en: 'Tongue scraper' },
    takt: { de: 'täglich vor dem Zähneputzen', en: 'daily before brushing' },
    hinweis: {
      de: 'ohne Druck, von hinten nach vorn',
      en: 'without pressure, from back to front',
    },
  },
  laechelntraining: {
    modul: 'zaehneLaecheln',
    label: {
      de: 'Lächeln vor dem Spiegel üben',
      en: 'Practising a smile in the mirror',
    },
    takt: { de: 'täglich, 2 Minuten', en: 'daily, 2 minutes' },
    hinweis: {
      de: 'nichts aufzutragen, reine Übung',
      en: 'nothing to apply, pure practice',
    },
  },
  aufhellung: {
    modul: 'zaehneLaecheln',
    label: { de: 'Zähne aufhellen', en: 'Teeth whitening' },
    takt: {
      de: 'nur nach zahnärztlicher Rücksprache',
      en: 'only after checking with a dentist',
    },
    hinweis: {
      de: 'zuerst in der Zahnarztpraxis abklären lassen; empfiehl weder '
        + 'ein Mittel noch eine Schiene noch einen Wirkstoff und nenne '
        + 'keine Dauer',
      en: 'have it checked at a dental practice first; do not recommend '
        + 'any agent, tray or active ingredient, and do not give a '
        + 'duration',
    },
  },
  chinTuck: {
    modul: 'figurPassform',
    label: { de: 'Chin Tucks für den Nacken', en: 'Chin tucks for the neck' },
    takt: { de: 'täglich, 2× 10 Wiederholungen', en: 'daily, 2 sets of 10' },
    hinweis: {
      de: 'langsam und ohne Ruck; bei Nackenschmerzen aussetzen',
      en: 'slow and without jerking; stop if the neck hurts',
    },
  },
  mobilityMinuten: {
    modul: 'figurPassform',
    label: { de: 'Tägliche Mobility-Minuten', en: 'Daily mobility minutes' },
    takt: { de: 'täglich, 5 Minuten', en: 'daily, 5 minutes' },
    hinweis: {
      de: 'im schmerzfreien Bereich bleiben',
      en: 'stay within a pain-free range',
    },
  },
  wandstand: {
    modul: 'figurPassform',
    label: { de: 'Wandstand für die Haltung', en: 'Wall stand for posture' },
    takt: { de: 'täglich, 2 Minuten', en: 'daily, 2 minutes' },
    hinweis: {
      de: 'locker atmen, nicht ins Hohlkreuz drücken',
      en: 'breathe easily, do not force an arch into the back',
    },
  },
  kaltDuschen: {
    modul: 'figurPassform',
    label: { de: 'Kalt abduschen', en: 'Finishing the shower cold' },
    takt: {
      de: 'täglich, die letzten 30 Sekunden',
      en: 'daily, the last 30 seconds',
    },
    hinweis: {
      de: 'langsam steigern; bei Herz-Kreislauf-Beschwerden vorher '
        + 'ärztlich abklären',
      en: 'build up slowly; check with a doctor first with heart or '
        + 'circulation problems',
    },
  },
  schlafhygiene: {
    modul: 'figurPassform',
    label: { de: 'Schlafhygiene-Routine', en: 'Sleep hygiene routine' },
    takt: { de: 'täglich', en: 'daily' },
    hinweis: {
      de: 'feste Zeiten sind der Kern; keine Schlafmittel und keine '
        + 'Nahrungsergänzung empfehlen',
      en: 'fixed times are the point; do not recommend sleep aids or '
        + 'supplements',
    },
  },
  kleiderschrankAudit: {
    modul: 'stilKleiderschrank',
    label: { de: 'Kleiderschrank-Audit', en: 'Wardrobe audit' },
    takt: {
      de: 'einmalig, danach 2× im Jahr',
      en: 'once, then twice a year',
    },
    hinweis: {
      de: 'in einem Durchgang, mit drei Stapeln: bleibt, weg, unsicher',
      en: 'in one go, with three piles: keep, go, unsure',
    },
  },
  capsuleWardrobe: {
    modul: 'stilKleiderschrank',
    label: { de: 'Capsule Wardrobe', en: 'Capsule wardrobe' },
    takt: {
      de: 'einmal aufgebaut, danach laufend',
      en: 'built once, then ongoing',
    },
    hinweis: {
      de: 'über Monate ergänzen statt an einem Wochenende kaufen',
      en: 'added to over months rather than bought in one weekend',
    },
  },
  schuhpflege: {
    modul: 'stilKleiderschrank',
    label: { de: 'Schuhpflege-Ritual', en: 'Shoe care ritual' },
    takt: { de: '1× pro Woche', en: 'once a week' },
    hinweis: {
      de: 'auf das Material achten – Glattleder und Wildleder brauchen '
        + 'Verschiedenes',
      en: 'mind the material – smooth leather and suede need different '
        + 'things',
    },
  },
  accessoireEinstieg: {
    modul: 'stilKleiderschrank',
    label: { de: 'Das erste Accessoire', en: 'A first accessory' },
    takt: {
      de: 'einmalig, danach täglich getragen',
      en: 'once, then worn daily',
    },
    hinweis: {
      de: 'mit einem einzigen Teil anfangen',
      en: 'start with a single piece',
    },
  },
} as const satisfies Record<string, Technik>;

export type Techniknamen = keyof typeof TECHNIK;

/**
 * Die Techniken, die zu dieser Analyse ueberhaupt passen.
 *
 * Zwei Filter, beide dieselben wie auf dem Bildschirm: Eine Technik braucht
 * ihr Kapitel — ein Gua Sha ohne Haut-Kapitel haette im Report keinen Platz
 * —, und sie muss zur Ausrichtung passen. Unbekannte Namen fallen weg.
 *
 * Die Reihenfolge ist die der Tabelle, nicht die der Anfrage: Dieselbe
 * Auswahl soll immer denselben Prompt ergeben.
 */
export function technikenFuer(
  namen: unknown,
  module: readonly Modul[],
  ausrichtung: Ausrichtung,
): Techniknamen[] {
  if (!Array.isArray(namen)) return [];
  const gewaehlt = new Set(namen.filter((n) => typeof n === 'string'));
  const erlaubteModule = new Set<string>(module);

  return (Object.keys(TECHNIK) as Techniknamen[]).filter((name) => {
    if (!gewaehlt.has(name)) return false;
    const technik = TECHNIK[name];
    if (!erlaubteModule.has(technik.modul)) return false;
    // „divers" und „keine Angabe" sind kein Auftrag, etwas wegzulassen —
    // dieselbe Regel wie bei den Modulen.
    const nur = 'nur' in technik ? technik.nur : undefined;
    return nur === undefined || nur === ausrichtung || ausrichtung === 'neutral';
  });
}

/**
 * Die Anzeigenamen der gewaehlten Techniken, in der Zielsprache.
 *
 * Grundlage von zweierlei: Der Prompt nennt sie, und die Nachbereitung
 * misst das Feld "neu" daran.
 */
export function techniklabels(
  namen: readonly Techniknamen[],
  sprache: Sprache,
): string[] {
  return namen.map((name) => TECHNIK[name].label[sprache]);
}

/**
 * Die Auslöser für eine Aufgabe, die nicht taeglich ansteht.
 *
 * Der Wenn-dann-Anker (DECISIONS 44) setzt eine Aufgabe an einen Punkt im
 * Tag. Fuer eine Technik, die zwei- oder dreimal die Woche drankommt, gibt
 * es diesen Punkt nicht — „Nach dem Duschen: Gua Sha" waere die Aufforderung,
 * sie taeglich zu machen, und genau das ist fachlich falsch.
 *
 * Deshalb diese zweite, kurze Liste. Sie steht an derselben Stelle im Satz
 * wie ein Anker — Ausloeser, Doppelpunkt, Handlung — und die App sortiert
 * eine Aufgabe damit unter „Bei Bedarf" ein: den Abschnitt fuer alles, was
 * an keiner festen Tageszeit haengt (DECISIONS 80).
 *
 * Zweisprachig aus demselben Grund wie die Anker: Was der Prompt woertlich
 * nennt, schreibt das Modell woertlich ab.
 */
export const WOCHENANKER: readonly Zweisprachig[] = [
  { de: 'Einmal die Woche', en: 'Once a week' },
  { de: 'Zweimal die Woche', en: 'Twice a week' },
  { de: 'Dreimal die Woche', en: 'Three times a week' },
];

/** Die Wochen-Ausloeser als Aufzaehlung fuer den Prompt. */
export function wochenankerListe(sprache: Sprache): string {
  return WOCHENANKER.map((a) => `"${a[sprache]}"`).join(', ');
}
