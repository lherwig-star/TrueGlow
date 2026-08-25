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
}
