import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/theme/marke.dart';

/// Das Zeichen entsteht an zwei Stellen und muss beide Male gleich aussehen.
///
/// `tool/marke_erzeugen.dart` rechnet die PNG-Dateien für Icon und nativen
/// Splash, `MarkenLogo` zeichnet dasselbe Motiv zur Laufzeit. Laufen die
/// beiden auseinander, zeigt der Homescreen ein anderes Zeichen als die App —
/// und zwar so ähnlich, dass es niemandem auffällt.
///
/// Seit DECISIONS 54 gehört die Glut dazu. Ihre Kurve steht deshalb in
/// [Marke] und nicht zweimal.
void main() {
  group('Die Glut', () {
    test('ist in der Mitte am dichtesten und am Rand nicht mehr da', () {
      expect(Marke.glutDeckung(0), 1.0);
      expect(Marke.glutDeckung(1), 0.0);

      // Streng fallend – jede Delle wäre als Ring zu sehen.
      var vorher = 2.0;
      for (var i = 0; i <= 100; i += 1) {
        final wert = Marke.glutDeckung(i / 100);
        expect(wert, lessThanOrEqualTo(vorher + 1e-9), reason: 'bei $i %');
        vorher = wert;
      }
    });

    test('läuft weich aus, statt eine Kante zu ziehen', () {
      // Am äußeren Rand darf kein Sprung stehen: Der letzte sichtbare Wert
      // muss nahe null sein, sonst sieht man den Kreis, statt den Schein zu
      // spüren.
      expect(Marke.glutDeckung(0.95), lessThan(0.05));

      // Und dazwischen darf sie nicht auf einmal abreißen.
      for (var i = 1; i <= 100; i += 1) {
        final sprung =
            (Marke.glutDeckung((i - 1) / 100) - Marke.glutDeckung(i / 100))
                .abs();
        expect(sprung, lessThan(0.06), reason: 'Sprung bei $i %');
      }
    });

    test('ist innen weiß und außen gold', () {
      expect(Marke.glutWeiss(0), 1.0);
      expect(Marke.glutWeiss(0.5), 0.0);
      expect(Marke.glutWeiss(1), 0.0);
    });

    test('sitzt in der Brustmitte, auf der Oberkante des Schulterbogens', () {
      expect(Marke.glutX, Marke.schulterX);

      final oberkante = Marke.schulterY - Marke.schulterRy;
      expect(Marke.glutY, closeTo(oberkante, 0.01));
    });

    test('bleibt im adaptiven Icon in der Schutzzone', () {
      // Android lässt bei einem adaptiven Icon nur die inneren zwei Drittel
      // stehen. `flutter_launcher_icons` setzt zusätzlich 16 % Einzug.
      const einzug = 0.68;
      const motiv = 0.72;

      // Das Motiv selbst – die Schultern sind das Breiteste daran.
      final breite = (Marke.schulterRx * 2 + Marke.strich) * motiv * einzug;
      expect(breite, lessThan(2 / 3));

      // Der dichte Kern der Glut. Weiter außen ist sie fast durchsichtig,
      // dort schadet ein Schnitt nicht.
      final kern = Marke.glutKern * 2 * motiv * einzug;
      expect(kern, lessThan(2 / 3));
    });
  });

  group('Generator und Laufzeit teilen sich die Zahlen', () {
    final generator = File('tool/marke_erzeugen.dart').readAsStringSync();
    final logo = File('lib/core/widgets/marken_logo.dart').readAsStringSync();

    test('beide rechnen mit derselben Kurve', () {
      for (final quelle in {'Generator': generator, 'MarkenLogo': logo}.entries) {
        expect(
          quelle.value,
          contains('Marke.glutDeckung'),
          reason: quelle.key,
        );
        expect(quelle.value, contains('Marke.glutWeiss'), reason: quelle.key);
      }
    });

    test('keiner von beiden führt eigene Geometrie', () {
      // Ein `0.43` oder `0.8` mitten im Zeichencode wäre der Anfang von zwei
      // Zeichen.
      for (final quelle in {'Generator': generator, 'MarkenLogo': logo}.entries) {
        expect(
          quelle.value,
          contains('Marke.glutRadius'),
          reason: quelle.key,
        );
      }
    });

    test('die Vorschau wird mitgeneriert', () {
      // Sie ist zum Danebenhalten da und darf nicht von Hand entstehen –
      // sonst zeigt sie irgendwann ein Zeichen, das es nicht mehr gibt.
      expect(generator, contains('icon_vorschau.png'));
      expect(File('assets/branding/icon_vorschau.png').existsSync(), isTrue);
    });
  });

  group('Alle Fassungen liegen vor', () {
    test('Icon, adaptive Ebenen, Splash und Vorschau', () {
      const dateien = [
        'app_icon.png',
        'app_icon_vordergrund.png',
        'app_icon_hintergrund.png',
        'store_icon_512.png',
        'splash_dunkel.png',
        'splash_hell.png',
        'splash_android12_dunkel.png',
        'splash_android12_hell.png',
        'icon_vorschau.png',
      ];

      for (final name in dateien) {
        expect(
          File('assets/branding/$name').existsSync(),
          isTrue,
          reason: name,
        );
      }
    });

    test('der Kachel-Hintergrund ist ein Bild, keine Farbe', () {
      // Ein Verlauf lässt sich nicht als `#RRGGBB` angeben.
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('adaptive_icon_background: assets/branding/app_icon_hintergrund.png'),
      );
    });
  });
}
