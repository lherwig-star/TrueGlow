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
  });

  /// Seitenhintergrund.
  final Color hintergrund;

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

  /// Dunkel – "Deep Teal & Sand" (Standard).
  ///
  /// Vorgegeben sind Hintergrund, Karte, Akzent, Sekundaerton und Text; die
  /// uebrigen Rollen sind daraus abgeleitet und so gewaehlt, dass jeder Text
  /// auf seiner Flaeche mindestens 4,5:1 erreicht.
  static const dunkel = AppColors(
    // Deep Teal / Petrol
    hintergrund: Color(0xFF173C3B),
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
  );

  /// Hell – "Mocha Light".
  static const hell = AppColors(
    hintergrund: Color(0xFFF7F2E9),
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
  );

  @override
  AppColors copyWith({
    Color? hintergrund,
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
  }) {
    return AppColors(
      hintergrund: hintergrund ?? this.hintergrund,
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
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      hintergrund: Color.lerp(hintergrund, other.hintergrund, t)!,
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
    );
  }
}

/// Kurzzugriff auf die Farbrollen des aktiven Themes.
extension AppColorsX on BuildContext {
  AppColors get farben => Theme.of(this).extension<AppColors>()!;
}
