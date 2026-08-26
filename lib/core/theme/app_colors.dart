import 'package:flutter/material.dart';

/// Semantische Farbrollen der App.
///
/// Bewusst als [ThemeExtension] und nicht als statische Konstanten: nur so
/// liefert derselbe Aufruf im hellen und im dunklen Theme unterschiedliche
/// Werte. Widgets greifen ueber `context.farben` zu und kennen keine
/// konkreten Farbwerte.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.hintergrund,
    required this.hintergrundTief,
    required this.flaeche,
    required this.flaecheHoch,
    required this.rand,
    required this.akzent,
    required this.aufAkzent,
    required this.akzentZwei,
    required this.textPrimaer,
    required this.textSekundaer,
    required this.warnung,
    required this.erfolg,
    required this.erreicht,
    required this.kartenrand,
  });

  /// Seitenhintergrund – der obere Ton des Seitenverlaufs.
  final Color hintergrund;

  /// Der untere Ton desselben Verlaufs.
  ///
  /// Der Hintergrund ist seit DECISIONS 50 kein Flaechenton mehr, sondern
  /// ein sehr sanfter Verlauf von oben nach unten. Er soll auffallen, ohne
  /// aufzufallen: Man spuert Tiefe, sieht aber keinen Farbwechsel.
  final Color hintergrundTief;

  /// Karten und abgesetzte Flaechen.
  final Color flaeche;

  /// Eine Stufe von [flaeche] abgesetzt – Produktzeilen und Zaehler-Badges.
  /// Im hellen Schema dunkler, im dunklen Schema tiefer als die Karte: In
  /// beiden Faellen eine Vertiefung, auf der die Sand-Toene ihren Kontrast
  /// behalten.
  final Color flaecheHoch;

  /// Dezente Rahmen und Trennlinien.
  final Color rand;

  /// Primaer-Akzent: Buttons, aktive Zustaende, Fortschrittsbalken.
  final Color akzent;

  /// Textfarbe auf [akzent]-Flaechen.
  final Color aufAkzent;

  /// Sekundaer-Akzent: Icons, Highlights.
  final Color akzentZwei;

  final Color textPrimaer;
  final Color textSekundaer;

  /// Fehler und Warnungen – gedecktes Terrakotta statt grellem Rot.
  final Color warnung;

  /// Erfolgs-Zustaende (Haekchen, "Geprueft"-Badge, Streak). Teilt sich den
  /// Ton mit [akzentZwei]; als eigene Rolle gefuehrt, damit ein spaeterer
  /// Wechsel nicht alle Icons mitzieht.
  final Color erfolg;

  /// **Erreichtes und Ausgewaehltes** – und ausschliesslich das.
  ///
  /// Ein warmes, gedaempftes Gold. Es steht an der Streak-Flamme und ihrer
  /// Zahl, an gesetzten Haken, an gefuellten Fortschrittssegmenten, an
  /// freigeschalteten Abzeichen, an den Joker-Schilden – und seit DECISIONS
  /// 51 an jedem Zustand, den der Nutzer selbst eingeschaltet hat: gewaehlte
  /// Module, angeklickte Chips, gesetzte Checkboxen, das gewaehlte Foto in
  /// der Zeitleiste.
  ///
  /// Das ist die ganze Idee dahinter (DECISIONS 50): Wenn Gold ueberall
  /// auftaucht, heisst es nichts mehr. Wer es sieht, soll wissen, dass hier
  /// etwas an ist, ohne den Text zu lesen. Buttons, Titel und Icons bleiben
  /// deshalb im Sand-Ton von [akzent].
  final Color erreicht;

  /// Die hauchduenne helle Kontur einer Karte.
  ///
  /// Seit DECISIONS 50 setzt sich eine Karte darueber ab und nicht mehr ueber
  /// einen Schlagschatten. Bewusst eine eigene Rolle und nicht `rand`: Der
  /// ist kraeftiger und zieht eine sichtbare Linie – richtig fuer
  /// Trennstriche und Eingabefelder, zu laut fuer eine Karte.
  ///
  /// Sie steht hier, damit es genau **eine** Stelle gibt. Vorher rechnete
  /// das Theme sie sich selbst aus, und jede handgebaute Karte nahm `rand` –
  /// das war der Grund, warum das neue Design auf den Unterseiten nur halb
  /// ankam (DECISIONS 51).
  final Color kartenrand;

  /// Dunkel – "Deep Teal & Sand" (Standard).
  ///
  /// Vorgegeben sind Hintergrund, Karte, Akzent, Sekundaerton und Text; die
  /// uebrigen Rollen sind daraus abgeleitet und so gewaehlt, dass jeder Text
  /// auf seiner Flaeche mindestens 4,5:1 erreicht.
  static const dunkel = AppColors(
    // Deep Teal / Petrol
    hintergrund: Color(0xFF173C3B),
    // Fast schwarzes Blau – das untere Ende des Seitenverlaufs.
    hintergrundTief: Color(0xFF0C1C26),
    // Muted Teal
    flaeche: Color(0xFF295654),
    // Nicht in der Vorgabe: eine Vertiefung innerhalb der Karte. Bewusst
    // dunkler als die Karte – nur so bleiben Sand-Toene darauf lesbar.
    flaecheHoch: Color(0xFF1E4746),
    rand: Color(0xFF3C6F6C),
    // Warm Sand
    akzent: Color(0xFFD8C6AA),
    aufAkzent: Color(0xFF173C3B),
    // Soft Sand
    akzentZwei: Color(0xFFC7B18C),
    // Off-White
    textPrimaer: Color(0xFFF2EEE6),
    textSekundaer: Color(0xFFBCCCC8),
    // Gedecktes Apricot – auf Petrol lesbar, ohne grell zu wirken.
    warnung: Color(0xFFEFB79E),
    erfolg: Color(0xFFC7B18C),
    // Gedaempftes Gold. Hell genug fuer 4,7:1 auf der Karte – der kleinste
    // Text in dieser Farbe ist die 12-Punkt-Zeile "Geschafft!".
    erreicht: Color(0xFFE8BE6E),
    // Off-White bei 10 % – Licht, kein Rahmen.
    kartenrand: Color(0x1AF2EEE6),
  );

  /// Hell – "Mocha Light".
  static const hell = AppColors(
    hintergrund: Color(0xFFF7F2E9),
    hintergrundTief: Color(0xFFEDE3D2),
    flaeche: Color(0xFFEFE7D8),
    flaecheHoch: Color(0xFFE5DAC7),
    rand: Color(0xFFDDD2BE),
    akzent: Color(0xFF6B4F3A),
    aufAkzent: Color(0xFFF7F2E9),
    akzentZwei: Color(0xFFA8794F),
    textPrimaer: Color(0xFF2B241C),
    textSekundaer: Color(0xFF6E6353),
    warnung: Color(0xFFB85C3A),
    erfolg: Color(0xFFA8794F),
    // Dasselbe Gold, dunkel genug fuer den hellen Grund (5,4:1) und ohne
    // jeden Blauanteil – sonst waere es vom Mocha-Akzent kaum zu
    // unterscheiden, und genau das darf es nicht sein.
    erreicht: Color(0xFF7A5200),
    // Auf hellem Grund traegt weniger: 7 % der Textfarbe.
    kartenrand: Color(0x122B241C),
  );

  /// Die flache Fläche, mit der der Start beginnt.
  ///
  /// Genau die Mitte des Seitenverlaufs – und genau der Ton, den der native
  /// Splash trägt. Der kann nämlich keinen Verlauf: `windowSplashScreenBack-
  /// ground` nimmt ab Android 12 nur eine einzelne Farbe.
  ///
  /// Damit ist das erste Bild der eigenen Startanimation vom letzten Bild
  /// des nativen Splash nicht zu unterscheiden, und die Übergabe ist nichts,
  /// was man sehen könnte (DECISIONS 53).
  Color get startFlaeche =>
      Color.lerp(hintergrund, hintergrundTief, 0.5)!;

  @override
  AppColors copyWith({
    Color? hintergrund,
    Color? hintergrundTief,
    Color? flaeche,
    Color? flaecheHoch,
    Color? rand,
    Color? akzent,
    Color? aufAkzent,
    Color? akzentZwei,
    Color? textPrimaer,
    Color? textSekundaer,
    Color? warnung,
    Color? erfolg,
    Color? erreicht,
    Color? kartenrand,
  }) {
    return AppColors(
      hintergrund: hintergrund ?? this.hintergrund,
      hintergrundTief: hintergrundTief ?? this.hintergrundTief,
      flaeche: flaeche ?? this.flaeche,
      flaecheHoch: flaecheHoch ?? this.flaecheHoch,
      rand: rand ?? this.rand,
      akzent: akzent ?? this.akzent,
      aufAkzent: aufAkzent ?? this.aufAkzent,
      akzentZwei: akzentZwei ?? this.akzentZwei,
      textPrimaer: textPrimaer ?? this.textPrimaer,
      textSekundaer: textSekundaer ?? this.textSekundaer,
      warnung: warnung ?? this.warnung,
      erfolg: erfolg ?? this.erfolg,
      erreicht: erreicht ?? this.erreicht,
      kartenrand: kartenrand ?? this.kartenrand,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      hintergrund: Color.lerp(hintergrund, other.hintergrund, t)!,
      hintergrundTief:
          Color.lerp(hintergrundTief, other.hintergrundTief, t)!,
      flaeche: Color.lerp(flaeche, other.flaeche, t)!,
      flaecheHoch: Color.lerp(flaecheHoch, other.flaecheHoch, t)!,
      rand: Color.lerp(rand, other.rand, t)!,
      akzent: Color.lerp(akzent, other.akzent, t)!,
      aufAkzent: Color.lerp(aufAkzent, other.aufAkzent, t)!,
      akzentZwei: Color.lerp(akzentZwei, other.akzentZwei, t)!,
      textPrimaer: Color.lerp(textPrimaer, other.textPrimaer, t)!,
      textSekundaer: Color.lerp(textSekundaer, other.textSekundaer, t)!,
      warnung: Color.lerp(warnung, other.warnung, t)!,
      erfolg: Color.lerp(erfolg, other.erfolg, t)!,
      erreicht: Color.lerp(erreicht, other.erreicht, t)!,
      kartenrand: Color.lerp(kartenrand, other.kartenrand, t)!,
    );
  }
}

/// Kurzzugriff auf die Farbrollen des aktiven Themes.
extension AppColorsX on BuildContext {
  AppColors get farben => Theme.of(this).extension<AppColors>()!;
}
