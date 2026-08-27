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

    test('Light Mode ist "Petrol Light" – dieselbe Familie, helle Werte', () {
      // Vorgabe aus dem Vergleichsbild (DECISIONS 62).
      expect(AppColors.hell.hintergrund, const Color(0xFFF7F9F8));
      expect(AppColors.hell.hintergrundTief, const Color(0xFFE0E9E7));
      expect(AppColors.hell.flaeche, const Color(0xFFFCFEFD));
      expect(AppColors.hell.akzent, const Color(0xFF143C4A));
      expect(AppColors.hell.aufAkzent, const Color(0xFFF5F8F7));
      expect(AppColors.hell.textPrimaer, const Color(0xFF10262E));
      expect(AppColors.hell.erreichtFlaeche, const Color(0xFFB27F26));
    });

    test('kein Braun ist uebrig geblieben', () {
      // Der alte helle Modus war Kaffeebraun. „Kein Beige mehr, kein
      // Mocha" heisst: In keiner Rolle steht mehr ein Ton, in dem Rot
      // deutlich ueber Blau liegt – ausser bei Warnung und Gold, die
      // warm sein muessen.
      const warmErlaubt = {'warnung', 'erreicht', 'erreichtFlaeche'};
      final rollen = <String, Color>{
        'hintergrund': AppColors.hell.hintergrund,
        'hintergrundTief': AppColors.hell.hintergrundTief,
        'flaeche': AppColors.hell.flaeche,
        'flaecheHoch': AppColors.hell.flaecheHoch,
        'rand': AppColors.hell.rand,
        'akzent': AppColors.hell.akzent,
        'aufAkzent': AppColors.hell.aufAkzent,
        'akzentZwei': AppColors.hell.akzentZwei,
        'textPrimaer': AppColors.hell.textPrimaer,
        'textSekundaer': AppColors.hell.textSekundaer,
        'erfolg': AppColors.hell.erfolg,
        'aufErreicht': AppColors.hell.aufErreicht,
      };

      for (final rolle in rollen.entries) {
        if (warmErlaubt.contains(rolle.key)) continue;
        final rot = (rolle.value.r * 255).round();
        final blau = (rolle.value.b * 255).round();
        expect(
          rot,
          lessThanOrEqualTo(blau),
          reason: '${rolle.key} ist waermer als kalt – Braun-Rest?',
        );
      }
    });
  });

  group('Der Goldton fuer Erreichtes', () {
    // Er traegt kleine Schrift – die Zeile „Geschafft!" auf der
    // Challenge-Karte ist 12 Punkt. Damit gilt fuer ihn dieselbe Schwelle
    // wie fuer jeden anderen Text: 4,5:1 (DECISIONS 50).
    test('bleibt in beiden Schemata auf jeder Flaeche lesbar', () {
      for (final schema in {'dunkel': AppColors.dunkel, 'hell': AppColors.hell}.entries) {
        final farben = schema.value;
        final flaechen = {
          'Hintergrund': farben.hintergrund,
          'Verlaufsende': farben.hintergrundTief,
          'Karte': farben.flaeche,
          'Vertiefung': farben.flaecheHoch,
        };

        for (final flaeche in flaechen.entries) {
          expect(
            _kontrast(flaeche.value, farben.erreicht),
            greaterThanOrEqualTo(4.5),
            reason: 'erreicht auf ${flaeche.key} (${schema.key})',
          );
        }
      }
    });

    test('als Flaeche gilt die Flaechen-Schwelle: 3:1', () {
      // Ein gefuellter Haken oder ein Fortschrittssegment traegt keinen
      // Text – dort reicht die Schwelle fuer grafische Elemente. Deshalb
      // darf [erreichtFlaeche] leuchtender sein als [erreicht]
      // (DECISIONS 62).
      for (final schema in {'dunkel': AppColors.dunkel, 'hell': AppColors.hell}.entries) {
        final farben = schema.value;
        for (final flaeche in {
          'Karte': farben.flaeche,
          'Vertiefung': farben.flaecheHoch,
        }.entries) {
          expect(
            _kontrast(flaeche.value, farben.erreichtFlaeche),
            greaterThanOrEqualTo(3.0),
            reason: 'erreichtFlaeche auf ${flaeche.key} (${schema.key})',
          );
        }
      }
    });

    test('und was darauf liegt, ist darauf zu sehen', () {
      for (final schema in {'dunkel': AppColors.dunkel, 'hell': AppColors.hell}.entries) {
        expect(
          _kontrast(schema.value.erreichtFlaeche, schema.value.aufErreicht),
          greaterThanOrEqualTo(3.0),
          reason: 'aufErreicht auf erreichtFlaeche (${schema.key})',
        );
      }
    });

    test('im Dunkelmodus sind Text- und Flaechen-Gold derselbe Ton', () {
      // Auf dunklem Grund braucht es die Trennung nicht – und genau
      // deshalb aendert sie am Dunkelmodus nichts.
      expect(AppColors.dunkel.erreichtFlaeche, AppColors.dunkel.erreicht);
      expect(AppColors.dunkel.aufErreicht, AppColors.dunkel.aufAkzent);
    });

    test('im hellen Modus sind sie verschieden – und beide Gold', () {
      expect(AppColors.hell.erreichtFlaeche, isNot(AppColors.hell.erreicht));
      // Beide warm: Rot deutlich ueber Blau.
      for (final gold in [AppColors.hell.erreicht, AppColors.hell.erreichtFlaeche]) {
        expect((gold.r * 255).round(), greaterThan((gold.b * 255).round() + 60));
      }
    });

    test('unterscheidet sich deutlich vom Sand-Akzent', () {
      // Sonst waere die ganze Idee dahin: Erreichtes soll auffallen, nicht
      // aussehen wie jeder andere Button.
      for (final farben in [AppColors.dunkel, AppColors.hell]) {
        final gold = farben.erreicht;
        final sand = farben.akzent;
        final abstand = (gold.r - sand.r).abs() +
            (gold.g - sand.g).abs() +
            (gold.b - sand.b).abs();
        expect(abstand, greaterThan(0.25));
      }
    });
  });

  group('Der Seitenverlauf', () {
    test('endet dunkler, als er anfaengt', () {
      // Von Petrol oben nach fast schwarzem Blau unten – im hellen Schema
      // entsprechend eine Spur tiefer.
      for (final farben in [AppColors.dunkel, AppColors.hell]) {
        expect(
          farben.hintergrundTief.computeLuminance(),
          lessThan(farben.hintergrund.computeLuminance()),
        );
      }
    });

    test('bleibt dezent genug, dass die Karte ueberall abhebt', () {
      // Die Karte liegt auf beiden Enden des Verlaufs. Faellt der Grund zu
      // tief, wirkt sie oben flach und unten wie ein Fremdkoerper.
      for (final farben in [AppColors.dunkel, AppColors.hell]) {
        expect(
          _kontrast(farben.hintergrund, farben.hintergrundTief),
          lessThan(2.2),
        );
      }
    });

    test('traegt Fliesstext auch am tiefsten Punkt', () {
      for (final farben in [AppColors.dunkel, AppColors.hell]) {
        expect(
          _kontrast(farben.hintergrundTief, farben.textPrimaer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _kontrast(farben.hintergrundTief, farben.textSekundaer),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });
}
