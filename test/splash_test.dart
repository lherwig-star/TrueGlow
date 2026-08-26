import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/theme/app_colors.dart';
import 'package:trueglow/core/theme/marke.dart';
import 'package:trueglow/features/start/ui/splash_screen.dart';

/// Der Start – die eine Stelle, an der Android und Flutter dasselbe Bild
/// zeigen müssen.
///
/// Der Anlass steht in DECISIONS 52: Am Gerät sprang das Zeichen beim
/// Übergang um ein Fünftel und rutschte um 24 dp nach oben, und die Farbe war
/// noch das alte flache Petrol. Nichts davon fällt beim Programmieren auf —
/// es fällt nur auf, wenn man die App öffnet. Deshalb steht es hier.
///
/// Und deshalb steht hier auch, was `dart run flutter_native_splash:create`
/// überschreiben kann: Der Generator schreibt `styles.xml` neu, und die
/// Handanpassung darin ist genau die Sorte Änderung, die still verloren geht.
void main() {
  String lies(String pfad) => File(pfad).readAsStringSync();

  const stylesDateien = [
    'android/app/src/main/res/values/styles.xml',
    'android/app/src/main/res/values-night/styles.xml',
    'android/app/src/main/res/values-v31/styles.xml',
    'android/app/src/main/res/values-night-v31/styles.xml',
  ];

  /// Der Ton, mit dem der Start beginnt – als Hex, wie ihn Android braucht.
  ///
  /// Er kommt aus [AppColors.startFlaeche], damit hier keine zweite Rechnung
  /// steht: Genau diese Farbe zeichnet auch der eigene Startbildschirm im
  /// ersten Bild.
  String startfarbe() {
    final f = AppColors.dunkel.startFlaeche;
    String teil(double wert) =>
        (wert * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${teil(f.r)}${teil(f.g)}${teil(f.b)}';
  }

  group('Das Zeichen steht beim Übergang still', () {
    test('seine Größe wird gerechnet, nicht geschätzt', () {
      // 288 dp ist die Fläche, in die Android ab Version 12 ein Startsymbol
      // ohne eigenen Hintergrund zeichnet; 0,52 davon füllt unser Motiv.
      expect(Marke.splashFlaecheDp, 288.0);
      expect(Marke.splashMotivAnteil, 0.52);
      expect(SplashScreen.zeichenGroesse, Marke.splashZeichenDp);
      expect(SplashScreen.zeichenGroesse, closeTo(149.8, 0.1));
    });

    test('das passt zur Messung am Gerät', () {
      // Gemessen am Samsung SM A525F (420 dpi, also 2,625 px je dp): Das
      // Motiv im nativen Splash war 304 px hoch. Die Zeichnung nimmt
      // senkrecht `tinteHoehe` der Fläche ein.
      const pxProDp = 420 / 160;
      final erwarteteHoehePx =
          SplashScreen.zeichenGroesse * Marke.tinteHoehe * pxProDp;

      expect(erwarteteHoehePx, closeTo(304, 6));
    });

    test('die Splash-Grafik darf keinen Symbol-Hintergrund bekommen', () {
      // Mit `icon_background_color` zeichnet Android in 240 dp statt 288 –
      // und dann stimmt die Rechnung oben nicht mehr.
      final pubspec = lies('pubspec.yaml');
      expect(pubspec, isNot(contains('icon_background_color:')));

      for (final pfad in stylesDateien) {
        expect(
          lies(pfad),
          isNot(contains('windowSplashScreenIconBackgroundColor')),
          reason: pfad,
        );
      }
    });
  });

  group('Die Farbe ist in beiden Phasen dieselbe', () {
    final farbe = startfarbe();

    test('sie kommt aus dem Seitenverlauf', () {
      // Die Mitte zwischen #173C3B und #0C1C26. Steht hier als Zahl,
      // damit ein versehentlicher Griff an eine der beiden Verlaufsfarben
      // sofort auffaellt statt still den Splash zu verstellen.
      expect(farbe, '#122c31');
    });

    test('der System-Splash trägt sie', () {
      for (final pfad in ['android/app/src/main/res/values-v31/styles.xml',
                          'android/app/src/main/res/values-night-v31/styles.xml']) {
        expect(
          lies(pfad).toLowerCase(),
          contains('<item name="android:windowsplashscreenbackground">$farbe<'),
          reason: pfad,
        );
      }
    });

    test('die Konfiguration trägt sie', () {
      // Sonst schreibt der nächste `flutter_native_splash:create` die alte
      // Farbe zurück in styles.xml.
      expect(lies('pubspec.yaml').toLowerCase(), contains('color: "$farbe"'));
    });

    test('das Fenster dahinter trägt sie auch', () {
      // Diese Farbe steht die ganze Laufzeit hinter der Oberfläche und
      // blitzt zwischen Splash und erstem Flutter-Frame auf.
      expect(
        lies('android/app/src/main/res/values/colors.xml').toLowerCase(),
        contains('<color name="splashhintergrund">$farbe</color>'),
      );
    });
  });

  group('Die Übergabe ist nichts, was man sehen kann', () {
    test('das erste Bild ist flach, nicht der Verlauf', () {
      // Bei t = 0 sind beide Enden des Verlaufs dieselbe Farbe – dieselbe,
      // die der System-Splash trägt. Genau das macht die Übergabe unsichtbar
      // (DECISIONS 53).
      final farben = AppColors.dunkel;
      expect(
        farben.startFlaeche,
        Color.lerp(farben.hintergrund, farben.hintergrundTief, 0.5),
      );
    });

    test('die Blende läuft, bevor der Schirm weitergeht', () {
      // Sonst schnitte der Wechsel auf die Startseite die Blende ab.
      expect(SplashScreen.blende, lessThan(SplashScreen.dauer));

      // Und danach bleibt Zeit, in der der Name ruhig dasteht.
      expect(
        SplashScreen.dauer - SplashScreen.blende,
        greaterThanOrEqualTo(const Duration(milliseconds: 1000)),
      );
    });

    test('sie ist kurz und weich – eine, nicht mehrere', () {
      // Unter einer Fünftelsekunde ist von einem Schnitt kaum zu
      // unterscheiden, über einer halben wirkt sie wie ein zweiter Start.
      // Beides war am Gerät zu sehen (DECISIONS 53 und 55).
      expect(SplashScreen.blende.inMilliseconds, greaterThanOrEqualTo(250));
      expect(SplashScreen.blende.inMilliseconds, lessThanOrEqualTo(350));
    });

    test('der eigene Schirm zeigt sofort den Endzustand', () {
      // Kein Vorlauf, keine Stufen – und ueberhaupt keine Animation. Was
      // hier anliefe, liefe unsichtbar: Bis der Inhalt dieses Schirms auf
      // dem Bildschirm ankommt, waere es vorbei. Am Geraet zweimal
      // gemessen (DECISIONS 55).
      final quelle = lies('lib/features/start/ui/splash_screen.dart');
      expect(quelle, isNot(contains('vorlauf')));
      expect(quelle, isNot(contains('_einsatz')));
      expect(quelle, isNot(contains('AnimationController')));
      expect(quelle, isNot(contains('TickerProvider')));
    });

    test('die Ueberblendung macht Android, nicht Flutter', () {
      // Nur dort ist die Reihenfolge zwingend: Der Inhalt der App liegt
      // fertig darunter, und darueber wird die Flaeche des Systems
      // weggeblendet. Ohne eigenen Exit-Listener nimmt Android sie selbst
      // weg – und zeigt dabei drei Bilder lang gar nichts. Genau das war
      // das Blinken (DECISIONS 55).
      final activity = lies(
        'android/app/src/main/kotlin/com/trueglow/app/MainActivity.kt',
      );
      expect(activity, contains('setOnExitAnimationListener'));

      // Und beide Stellen nennen dieselbe Zahl.
      final treffer =
          RegExp(r'BLENDE_MS\s*=\s*(\d+)').firstMatch(activity);
      expect(treffer, isNotNull, reason: 'keine Dauer in MainActivity.kt');
      expect(
        int.parse(treffer!.group(1)!),
        SplashScreen.blende.inMilliseconds,
      );
    });

    test('nichts haelt den ersten Frame zurueck', () {
      // `FlutterNativeSplash.preserve` haelt das erste gezeichnete Bild
      // zurueck. Es war nicht die Ursache des Blinkens – die lag im System –,
      // aber es verlaengert die Luecke: Android wartet auf dieses Bild, um
      // seinen Start-Bildschirm wegzunehmen. Mit `preserve` waren es drei
      // leere Einzelbilder statt einem (DECISIONS 55).
      final start = lies('lib/main.dart');
      expect(start, isNot(contains('FlutterNativeSplash')));
      expect(start, isNot(contains('deferFirstFrame')));
    });
  });

  group('Was der Generator überschreiben könnte', () {
    // `dart run flutter_native_splash:create` schreibt alle vier Dateien
    // neu. Ohne diese Tests fiele erst am Gerät auf, dass die Handanpassung
    // weg ist – als kurzes weißes Aufblitzen beim Start.
    test('NormalTheme zeigt in jeder Fassung die eigene Farbe', () {
      for (final pfad in stylesDateien) {
        final inhalt = lies(pfad);
        final ab = inhalt.indexOf('name="NormalTheme"');
        expect(ab, greaterThan(0), reason: '$pfad: kein NormalTheme');

        expect(
          inhalt.substring(ab),
          contains(
            '<item name="android:windowBackground">@color/splashHintergrund</item>',
          ),
          reason: pfad,
        );
      }
    });

    test('der Warnhinweis steht noch drin', () {
      // Er ist die einzige Stelle, an der jemand liest, dass der Generator
      // diese Datei anfassen darf.
      expect(
        lies('android/app/src/main/res/values/styles.xml'),
        contains('flutter_native_splash:create'),
      );
    });
  });
}
