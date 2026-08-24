import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Zentrale Design-Definition der App.
///
/// Zwei gleichwertige Schemata – "Deep Teal & Sand" (dunkel, Standard) und
/// "Mocha Light" (hell). Beide bauen auf denselben Formen, Radien und
/// Abstaenden auf und beziehen saemtliche Farben aus [AppColors]; in Widgets
/// steht kein einziger Farbwert.
class AppTheme {
  AppTheme._();

  // --- Abstaende & Radien (schema-unabhaengig) ---
  static const double radiusCard = 20;
  static const double radiusButton = 14;
  static const double gapXs = 6;
  static const double gapS = 12;
  static const double gapM = 20;
  static const double gapL = 32;
  static const double gapXl = 48;

  /// Animationsdauer, die die System-Einstellung "Animationen reduzieren"
  /// respektiert: Ist sie aktiv, wird ohne Uebergang umgeschaltet.
  static Duration animation(BuildContext context, Duration dauer) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : dauer;

  static ThemeData get dark => _bauen(AppColors.dunkel, Brightness.dark);

  static ThemeData get light => _bauen(AppColors.hell, Brightness.light);

  /// Passende Statusbar-/Navigationsleisten-Farben zum Schema: dunkle Icons
  /// auf hellem Grund und umgekehrt.
  static SystemUiOverlayStyle overlayStyle(
    AppColors farben,
    Brightness helligkeit,
  ) {
    final dunkel = helligkeit == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dunkel ? Brightness.light : Brightness.dark,
      statusBarBrightness: dunkel ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: farben.hintergrund,
      systemNavigationBarIconBrightness:
          dunkel ? Brightness.light : Brightness.dark,
    );
  }

  static ThemeData _bauen(AppColors farben, Brightness helligkeit) {
    final scheme = ColorScheme(
      brightness: helligkeit,
      primary: farben.akzent,
      onPrimary: farben.aufAkzent,
      secondary: farben.akzentZwei,
      onSecondary: farben.aufAkzent,
      surface: farben.flaeche,
      onSurface: farben.textPrimaer,
      error: farben.warnung,
      onError: farben.aufAkzent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: helligkeit,
      colorScheme: scheme,
      scaffoldBackgroundColor: farben.hintergrund,
    );

    // Im hellen Schema duerfen Schatten etwas sichtbarer sein – auf dunklem
    // Grund verpufft ein Schatten ohnehin.
    final kartenSchatten = helligkeit == Brightness.light ? 2.0 : 0.0;

    return base.copyWith(
      extensions: [farben],
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: farben.textPrimaer,
        displayColor: farben.textPrimaer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle(farben, helligkeit),
        titleTextStyle: TextStyle(
          color: farben.textPrimaer,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: farben.textPrimaer),
      ),
      cardTheme: CardThemeData(
        color: farben.flaeche,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        elevation: kartenSchatten,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: farben.rand),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: farben.flaeche,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: farben.akzent,
          foregroundColor: farben.aufAkzent,
          // Vertiefung statt Rahmenfarbe: der deaktivierte Button liegt so
          // sichtbar "tiefer" und die Beschriftung bleibt trotzdem lesbar.
          disabledBackgroundColor: farben.flaecheHoch,
          disabledForegroundColor: farben.textSekundaer,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: farben.textPrimaer,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: farben.rand),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: farben.akzent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? farben.akzent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(farben.aufAkzent),
        side: BorderSide(color: farben.textSekundaer, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? farben.akzent
              : farben.textSekundaer,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: farben.akzent,
        textColor: farben.textPrimaer,
      ),
      // Umschalter im Einstellungspunkt "Erscheinungsbild": aktive Auswahl
      // traegt den Primaer-Akzent, die uebrigen bleiben transparent.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? farben.akzent
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? farben.aufAkzent
                : farben.textPrimaer,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? farben.aufAkzent
                : farben.textSekundaer,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: farben.rand)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: farben.rand,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: farben.akzent),
      snackBarTheme: SnackBarThemeData(
        // Wie eine Karte, inklusive Rahmen: Ohne den Rahmen verschwaemme die
        // schwebende Leiste in beiden Schemata mit dem Seitenhintergrund.
        backgroundColor: farben.flaeche,
        contentTextStyle: TextStyle(color: farben.textPrimaer),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          side: BorderSide(color: farben.rand),
        ),
      ),
    );
  }
}
