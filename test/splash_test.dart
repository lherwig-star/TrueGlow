import 'dart:io';

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

  /// Der Ton, den der Seitenverlauf auf halber Höhe trägt – dort steht das
  /// Zeichen. Der native Splash kann keinen Verlauf, nur eine Farbe.
  String mitteDesVerlaufs() {
    final oben = AppColors.dunkel.hintergrund;
    final unten = AppColors.dunkel.hintergrundTief;
    int misch(double a, double b) => (((a + b) / 2) * 255).round();
    return '#'
        '${misch(oben.r, unten.r).toRadixString(16).padLeft(2, '0')}'
        '${misch(oben.g, unten.g).toRadixString(16).padLeft(2, '0')}'
        '${misch(oben.b, unten.b).toRadixString(16).padLeft(2, '0')}';
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
    final farbe = mitteDesVerlaufs();

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
