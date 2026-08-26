/// Die Geometrie des TrueGlow-Zeichens – ein hochkant stehendes Oval mit
/// angedeuteten Schultern darunter, dasselbe Motiv wie das Gesichts-Oval im
/// Kamera-Sucher.
///
/// Bewusst ohne Flutter-Abhängigkeit und bewusst als eigene Datei: Dieselben
/// Zahlen brauchen zwei Stellen, die nicht dieselbe Laufzeit haben.
///
/// * `tool/marke_erzeugen.dart` läuft als reines Dart-Skript und rechnet die
///   PNG-Dateien für Icon und nativen Splash daraus aus.
/// * [MarkenLogo] in `core/widgets/marken_logo.dart` zeichnet dasselbe Motiv
///   zur Laufzeit – in den Farben des aktiven Schemas und in jeder Größe
///   scharf.
///
/// Zwei Kopien derselben Geometrie wären zwei Kopien, die auseinanderlaufen:
/// Das App-Icon und die Startanimation zeigten dann verschiedene Zeichen, und
/// zwar so ähnlich, dass es niemandem auffällt.
///
/// Alle Werte sind auf eine quadratische Fläche 0..1 normiert.
class Marke {
  Marke._();

  /// Das Gesichts-Oval.
  static const ovalX = 0.500;
  static const ovalY = 0.430;
  static const ovalRx = 0.215;
  static const ovalRy = 0.285;

  /// Die angedeuteten Schultern: ein weiter Bogen, von dem nur die Oberkante
  /// im Bild liegt.
  static const schulterX = 0.500;
  static const schulterY = 1.145;
  static const schulterRx = 0.425;
  static const schulterRy = 0.345;

  /// Strichstärke beider Ringe.
  static const strich = 0.050;

  /// Unterhalb dieser Höhe wird der Schulterbogen abgeschnitten – sonst wirkt
  /// er wie ein abgeschnittener Kreis statt wie Schultern.
  static const schulterUnterkante = 0.895;

  // --- Der native Splash -------------------------------------------------
  //
  // Diese beiden Zahlen entscheiden, wie groß das Zeichen beim Start
  // erscheint – und zwar zweimal: einmal im PNG, das Android zeichnet, und
  // einmal im eigenen Startbildschirm, der nahtlos daran anschließt. Standen
  // sie an zwei Stellen, sprang das Zeichen beim Übergang. Genau das ist
  // passiert (DECISIONS 52).

  /// Die Fläche, in die Android ab Version 12 das Startsymbol zeichnet.
  ///
  /// 288 dp – der dokumentierte Wert für ein Symbol ohne eigenen
  /// Hintergrund. Am Gerät nachgemessen: Das Motiv erschien 116 dp hoch,
  /// was bei [splashMotivAnteil] genau auf diese Fläche führt.
  static const splashFlaecheDp = 288.0;

  /// Wie viel dieser Fläche das Motiv einnimmt.
  ///
  /// Die äußeren Ränder bleiben frei: Android beschneidet ein Startsymbol
  /// auf die inneren zwei Drittel, was dort liegt, kann weg sein.
  static const splashMotivAnteil = 0.52;

  /// Kantenlänge des Zeichens im eigenen Startbildschirm, in dp.
  ///
  /// Rechnung statt Schätzung: genau die Größe, in der Android das Motiv
  /// zeichnet. Damit steht es beim Übergang still.
  static const splashZeichenDp = splashFlaecheDp * splashMotivAnteil;

  /// Anteil der Fläche, den die sichtbare Zeichnung senkrecht einnimmt.
  ///
  /// Vom oberen Rand des Ovals bis zur Schulter-Unterkante. Gebraucht, um
  /// die gemessene Höhe am Gerät gegen die Vorgabe halten zu können.
  static const tinteHoehe = schulterUnterkante - (ovalY - ovalRy - strich / 2);
}
