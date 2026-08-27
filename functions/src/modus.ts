import { type Sprache, type Zweisprachig } from './sprache';

/**
 * Mit welchem Auftrag die Analyse läuft.
 *
 * Spiegelt das Dart-Enum `AnalyseModus` in
 * `lib/features/analysis/models/analyse_modus.dart`. Der Client schickt den
 * Namen mit; alles andere fällt hier heraus.
 *
 * Der Rückfall ist `verfeinern` – aus demselben Grund wie beim Rückfall auf
 * Deutsch: Ein alter Client, der das Feld noch nicht kennt, bekommt genau
 * das, was er bisher bekommen hat. Der Prompt ist dann Wort für Wort
 * derselbe wie vor DECISIONS 57.
 */
export const MODI = ['verfeinern', 'entdecken'] as const;

export type Modus = (typeof MODI)[number];

export function leseModus(roh: unknown): Modus {
  return typeof roh === 'string' && (MODI as readonly string[]).includes(roh)
    ? (roh as Modus)
    : 'verfeinern';
}

/**
 * Der Auftrag – die eine Zeile, die den ganzen Report dreht.
 *
 * Sie steht dort, wo vorher der feste Satz „Deine Aufgabe: eine
 * konstruktive, motivierende Einschätzung …" stand.
 */
export function auftrag(modus: Modus): string {
  if (modus === 'verfeinern') {
    return `Deine Aufgabe: eine konstruktive, motivierende Einschätzung mit konkret
umsetzbaren Empfehlungen – gegliedert in genau die unten genannten Kapitel.`;
  }

  return `Deine Aufgabe: Entwirf dieser Person einen NEUEN Look – eine neue, in sich
stimmige Richtung, begründet an dem, was du auf den Fotos siehst. Nicht den
Ist-Zustand optimieren: eine Richtung vorschlagen, die sichtbar anders ist
und trotzdem zu diesem Gesicht, diesem Haartyp und diesem Alltag passt.
Gegliedert in genau die unten genannten Kapitel.

Diese Person hat sich ausdrücklich für Veränderung entschieden. Sie will
keine Kritik an ihrem jetzigen Aussehen und keine Bestätigung des
Bestehenden – sie will einen Vorschlag, den sie umsetzen kann.`;
}

/**
 * Die Regeln, die nur im entdeckenden Modus gelten.
 *
 * Vier Forderungen, jede prüfbar an einer einzelnen Zeile des Reports:
 * Name, Begründung, Unterschied, Machbarkeit. Sie stehen so konkret da,
 * weil ein Modell auf „schlag etwas Neues vor" mit „probier doch mal einen
 * frischeren Schnitt" antwortet – und das ist nichts.
 *
 * Wie bei den Ankern (DECISIONS 44) sind die Beispiele **beschrieben** und
 * nicht als fertiger Satz zitiert: Was der Prompt wörtlich nennt, schreibt
 * das Modell wörtlich ab (DECISIONS 36). Namen von Frisuren sind davon
 * ausgenommen – „Textured Crop" heißt auf Deutsch auch „Textured Crop".
 */
export function entdeckenRegeln(): string {
  return `Regeln für den neuen Look – daran wird dieser Report gemessen:
- NAME: Jeder Vorschlag hat einen Namen, den man einem Friseur, Barbier oder
  Verkäufer sagen kann. Bei der Frisur ein gängiger Schnittname (Textured
  Crop, Modern Mullet, Curtains, Buzz Cut, Fade, Slick Back, Shag, Bob,
  Long Layers – oder ein anderer, der wirklich existiert), beim Bart ein
  konkreter Stil oder ausdrücklich glatt rasiert, beim Stil eine benennbare
  Richtung. "Etwas Kürzeres", "moderner", "frischer" sind keine Vorschläge.
- BEGRÜNDUNG AM GESICHT: Zu jedem Vorschlag ein Satz, warum genau er zu
  DIESER Person passt, und darin ein Merkmal, das du auf den Fotos gesehen
  hast – Gesichtsform, Kieferlinie, Stirnhöhe, Haaransatz, Haarstruktur,
  Wuchsrichtung, Schulterbreite. Ohne dieses Merkmal ist der Vorschlag ein
  Trendtipp und gehört gestrichen.
- MACHBAR: Nichts, was der Haartyp nicht hergibt. Feines Haar trägt keine
  Frisur, die Fülle voraussetzt; glattes Haar wird nicht über Nacht lockig;
  ein Bartstil braucht den Bartwuchs, den du siehst. Wenn der gewünschte
  Effekt so nicht geht, sag das offen und schlag das vor, was dem am
  nächsten kommt. Auch der Aufwand muss zum angegebenen Zeit- und
  Geldbudget passen – ein Look, der täglich zwanzig Minuten Föhnen
  braucht, ist bei "wenig Zeit" kein Vorschlag.
- BEIM FRISEUR SAGEN: Zu jedem Frisur- und Bartvorschlag ein Satz in
  direkter Rede, den die Person im Salon vorlesen kann – Länge oben, Länge
  an den Seiten, Übergang, Kontur.
- SICHTBAR ANDERS: Der Vorschlag muss sich vom aktuellen Look erkennbar
  unterscheiden. Das ist der Sinn dieses Reports. Gleichzeitig bleibt er
  alltagstauglich und mit normalem Budget umsetzbar – kein Laufsteg, keine
  Verwandlung, die eine Behandlung oder einen Eingriff voraussetzt.
- WAS BLEIBT: Benenne ehrlich, was am jetzigen Look schon stark ist und
  bleiben sollte. Neu heißt nicht alles anders, und eine Stärke zu behalten
  ist ein Teil des Vorschlags, keine Ausrede.
- TON: Anerkennend und motivierend, nie abwertend über das jetzige
  Aussehen. Kein Satz beginnt damit, was bisher nicht funktioniert hat.
  Sprich über den neuen Look, nicht gegen den alten.
- STANDARD-VORSCHLÄGE SIND VERBOTEN: Wenn dein Vorschlag genauso für eine
  andere Person mit anderem Gesicht richtig wäre, ist er falsch. Streich
  ihn und schreib einen, der nur zu dieser Person passt.`;
}

/**
 * Was zusätzlich im Kapitel stehen soll.
 *
 * Wird an jede Kapitelvorgabe angehängt. Der Vorschlag bekommt eine eigene
 * Sektion **an erster Stelle**, damit er nicht zwischen Pflegetipps
 * untergeht – und weil der Report von oben nach unten gelesen wird.
 */
export function kapitelZusatz(sektionsname: string): string {
  return (
    ' ZUSÄTZLICH zu den genannten Sektionen steht an ERSTER Stelle eine ' +
    `Sektion, deren "titel" GENAU "${sektionsname}" lautet. Ihre ` +
    '"einschaetzung" nennt den Vorschlag für dieses Kapitel beim Namen und ' +
    'begründet ihn an einem Merkmal, das du auf den Fotos siehst; ihre ' +
    '"empfehlungen" sagen, was zu tun ist, um dorthin zu kommen – der erste ' +
    'Schritt zuerst. Die übrigen Sektionen behandeln wie gewohnt ihr Thema, ' +
    'aber bezogen auf den NEUEN Look, nicht auf den alten.'
  );
}

/**
 * Die Regeln für Plan und Tagesaufgaben im entdeckenden Modus.
 *
 * Ohne sie kommt ein Plan zurück, der den alten Look pflegt: Der Vorschlag
 * steht oben, und darunter steht „Bart abends in Form bringen" für einen
 * Bart, der abrasiert werden soll.
 */
export function planRegeln(): string {
  return `- Plan und Tagesaufgaben gehören zum NEUEN Look, nicht zum alten. Die
  Aufgaben sind die Styling- und Pflegeroutine, die der neue Schnitt, der
  neue Bartstil und die neue Kleidungsrichtung brauchen.
- "sofort" enthält die Schritte, die den Wechsel in Gang bringen – der
  Termin, der Einkauf, das Gespräch im Salon. "dreissigTage" ist die Zeit,
  in der der neue Look sich einspielt. "langfristig" ist, was danach hält.
- Ist zwischen heute und dem neuen Look eine Übergangszeit nötig
  (Herauswachsen, Herausfärben), sag das offen und gib für diese Zeit
  konkrete Aufgaben. Eine verschwiegene Übergangszeit ist der häufigste
  Grund, warum jemand nach zwei Wochen aufgibt.`;
}

/**
 * Die Regel fuer das Gesamtbild – DECISIONS 67.
 *
 * Der Anlass: In beiden Modi zaehlte die Karte ganz oben bereits die
 * konkreten Vorschlaege auf – den Schnittnamen, den Bartstil, die
 * Kleidungsstuecke – und die Kapitel darunter wiederholten dasselbe. Der
 * Report las sich wie zweimal derselbe Text.
 *
 * Jede Information hat jetzt genau **ein** Zuhause: Das Gesamtbild
 * beschreibt die Wirkung, die Kapitel nennen die Namen.
 *
 * Die Beispiele sind ausdruecklich als Muster fuer die **Form** markiert.
 * Ohne diese Markierung schreibt ein Modell sie woertlich ab (DECISIONS 36) –
 * und dann stuende in jedem Report derselbe Satz.
 */
export function gesamtbildRegeln(modus: Modus, sprache: Sprache): string {
  const gut = BEISPIEL[modus].gut[sprache];
  const schlecht = BEISPIEL[modus].schlecht[sprache];

  const was = modus === 'entdecken'
    ? 'die neue Richtung'
    : 'den Weg, den die Verfeinerung nimmt';

  return `Das Gesamtbild – die Regel für "gesamtbild":
- 2 bis 4 Sätze, die ${was} als Bild im Kopf entstehen lassen: wie die Teile
  zusammenwirken und was der Look ausstrahlt.
- KEINE konkreten Einzelvorschläge. Kein Schnittname, keine
  Bart-Bezeichnung, kein Kleidungsstück, kein Produktname, keine Längen-
  oder Millimeterangabe. Diese Begriffe fallen im ganzen Report zum ersten
  Mal im jeweiligen Kapitel.
- Kein Aufzählen der Kapitel, keine Vorrede.
- So sieht es aus (Muster für die FORM, nicht für den Inhalt – übernimm
  keinen dieser Sätze und keines dieser Merkmale):
  RICHTIG: "${gut}"
  FALSCH:  "${schlecht}"
- Und umgekehrt: Die Kapitel steigen direkt mit ihrem Vorschlag ein. Sie
  fassen das Gesamtbild nicht noch einmal zusammen und wiederholen seine
  Sätze nicht.
- "gesamtbild" ist Anzeigetext und steht in der Zielsprache.`;
}

/**
 * Je ein Muster pro Modus und Sprache.
 *
 * Das falsche Beispiel ist absichtlich das, was vorher wirklich
 * herauskam – ein Gesamtbild, das den Schnitt beim Namen nennt.
 */
const BEISPIEL: Record<
  Modus,
  { gut: Zweisprachig; schlecht: Zweisprachig }
> = {
  entdecken: {
    gut: {
      de: 'Die Richtung geht weg vom Unauffälligen hin zu klaren Kanten: '
        + 'oben mehr Kontur, unten mehr Ruhe. Das Ergebnis wirkt wacher und '
        + 'entschiedener, ohne dass du morgens länger brauchst.',
      en: 'The direction moves away from the unobtrusive towards clear '
        + 'edges: more definition up top, more calm below. The result looks '
        + 'more awake and more decided, without costing you extra minutes.',
    },
    schlecht: {
      de: 'Ein Textured Crop mit mittelhohem Fade, dazu ein Vollbart auf '
        + '6 mm und ein Overshirt in Oliv.',
      en: 'A textured crop with a mid fade, plus a full beard at 6 mm and '
        + 'an olive overshirt.',
    },
  },
  verfeinern: {
    gut: {
      de: 'Deine Grundlage trägt bereits – klare Proportionen und ein '
        + 'ruhiger Gesamteindruck. Die Verfeinerung setzt an den Kanten an: '
        + 'sauberer, wo es unentschieden wirkt, und ein wenig mehr Halt '
        + 'dort, wo der Tag ihn wegnimmt.',
      en: 'Your foundation already works – clear proportions and a calm '
        + 'overall impression. The refinement starts at the edges: cleaner '
        + 'where it looks undecided, and a little more hold where the day '
        + 'takes it away.',
    },
    schlecht: {
      de: 'Die Seiten zwei Nummern kürzer, die Wangenlinie mit dem '
        + 'Präzisionstrimmer nachziehen und eine matte Paste benutzen.',
      en: 'Take the sides two grades shorter, redo the cheek line with a '
        + 'precision trimmer and use a matte paste.',
    },
  },
};
