import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/theme/app_colors.dart';

/// Kontrastverhaeltnis nach WCAG 2.1 zwischen zwei deckenden Farben.
double _kontrast(Color a, Color b) {
  final hell = a.computeLuminance();
  final dunkel = b.computeLuminance();
  final oben = hell > dunkel ? hell : dunkel;
  final unten = hell > dunkel ? dunkel : hell;
  return (oben + 0.05) / (unten + 0.05);
}

/// Die Farbwelten sind Vorgabe, kein Zufallsfund – und die Lesbarkeit auf
/// ihnen ist eine Anforderung. Beides wird hier festgehalten, damit ein
/// spaeterer Feinschliff an einer Farbe nicht unbemerkt Text unlesbar macht.
void main() {
  group('Dark Mode – "Deep Teal & Sand"', () {
    const farben = AppColors.dunkel;

    test('traegt genau die vorgegebenen Farben', () {
      expect(farben.hintergrund, const Color(0xFF173C3B)); // Deep Teal
      expect(farben.flaeche, const Color(0xFF295654)); // Muted Teal
      expect(farben.akzent, const Color(0xFFD8C6AA)); // Warm Sand
      expect(farben.akzentZwei, const Color(0xFFC7B18C)); // Soft Sand
      expect(farben.textPrimaer, const Color(0xFFF2EEE6)); // Off-White
    });

    test('jede Textfarbe erreicht auf jeder Flaeche mindestens 4,5:1', () {
      final flaechen = {
        'Hintergrund': farben.hintergrund,
        'Karte': farben.flaeche,
        'Vertiefung': farben.flaecheHoch,
      };
      final texte = {
        'textPrimaer': farben.textPrimaer,
        'textSekundaer': farben.textSekundaer,
        'akzent': farben.akzent,
        'warnung': farben.warnung,
      };

      for (final flaeche in flaechen.entries) {
        for (final text in texte.entries) {
          expect(
            _kontrast(flaeche.value, text.value),
            greaterThanOrEqualTo(4.5),
            reason: '${text.key} auf ${flaeche.key}',
          );
        }
      }
    });

    test('Beschriftung auf Akzentflaechen bleibt lesbar', () {
      expect(
        _kontrast(farben.akzent, farben.aufAkzent),
        greaterThanOrEqualTo(4.5),
      );
      // Deaktivierte Buttons liegen auf der Vertiefung.
      expect(
        _kontrast(farben.flaecheHoch, farben.textSekundaer),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('der Sekundaerton traegt Icons, aber keine Kleinschrift auf Karten',
        () {
      // Auf dem Seitenhintergrund reicht er auch fuer Text ...
      expect(
        _kontrast(farben.hintergrund, farben.akzentZwei),
        greaterThanOrEqualTo(4.5),
      );
      // ... auf der Karte nur noch fuer Flaechen und Symbole (3:1). Genau
      // deshalb steht dort Text im Primaer-Akzent.
      expect(
        _kontrast(farben.flaeche, farben.akzentZwei),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _kontrast(farben.flaeche, farben.erfolg),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('Karten und Raender heben sich vom Hintergrund ab', () {
      expect(farben.flaeche, isNot(farben.hintergrund));
      expect(
        _kontrast(farben.hintergrund, farben.rand),
        greaterThanOrEqualTo(1.5),
      );
    });
  });

  group('Beide Schemata', () {
    test('Fliesstext und Primaer-Akzent bleiben ueberall lesbar', () {
      for (final farben in [AppColors.dunkel, AppColors.hell]) {
        for (final flaeche in [
          farben.hintergrund,
          farben.flaeche,
          farben.flaecheHoch,
        ]) {
          expect(
            _kontrast(flaeche, farben.textPrimaer),
            greaterThanOrEqualTo(4.5),
          );
          expect(_kontrast(flaeche, farben.akzent), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('Light Mode bleibt "Mocha Light"', () {
      expect(AppColors.hell.hintergrund, const Color(0xFFF7F2E9));
      expect(AppColors.hell.flaeche, const Color(0xFFEFE7D8));
      expect(AppColors.hell.akzent, const Color(0xFF6B4F3A));
      expect(AppColors.hell.textPrimaer, const Color(0xFF2B241C));
    });
  });
}
