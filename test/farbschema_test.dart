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
/// Alle Farbrollen eines Schemas, benannt – fuer Tests, die den ganzen
/// Satz durchgehen statt einzelner Werte.
Map<String, Color> _rollen(AppColors f) => {
      'hintergrund': f.hintergrund,
      'hintergrundTief': f.hintergrundTief,
      'flaeche': f.flaeche,
      'flaecheHoch': f.flaecheHoch,
      'rand': f.rand,
      'akzent': f.akzent,
      'aufAkzent': f.aufAkzent,
      'akzentZwei': f.akzentZwei,
      'textPrimaer': f.textPrimaer,
      'textSekundaer': f.textSekundaer,
      'warnung': f.warnung,
      'erfolg': f.erfolg,
      'erreicht': f.erreicht,
      'erreichtFlaeche': f.erreichtFlaeche,
      'aufErreicht': f.aufErreicht,
      'erreichtLeer': f.erreichtLeer,
      'erreichtChip': f.erreichtChip,
      'kartenrand': f.kartenrand,
    };

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

    test('Light Mode ist "Creme, Teal & Amber"', () {
      // Vorgabe aus dem Referenzbild (DECISIONS 63).
      expect(AppColors.hell.hintergrund, const Color(0xFFFDF5EE));
      expect(AppColors.hell.flaeche, const Color(0xFFFEFAF7));
      expect(AppColors.hell.akzent, const Color(0xFF025D70));
      expect(AppColors.hell.aufAkzent, AppColors.hell.flaeche);
      expect(AppColors.hell.textPrimaer, const Color(0xFF12383F));
      expect(AppColors.hell.erreichtFlaeche, const Color(0xFFE59305));
      expect(AppColors.hell.erreichtLeer, const Color(0xFFFDE9D2));
      expect(AppColors.hell.erreichtChip, const Color(0xFFF5DEB9));
    });

    test('kein Kaffeebraun und kein kuehles Grau-Gruen mehr', () {
      // Zwei abgelegte Fassungen: „Mocha Light" (bis DECISIONS 62) und
      // „Petrol Light" (bis DECISIONS 63). Beide sollen restlos weg sein —
      // ein einzelner ueberlebender Wert waere eine Stelle, die nicht an
      // den Rollen haengt.
      const abgelegt = <int>{
        // Mocha Light
        0xFFF7F2E9, 0xFFEDE3D2, 0xFFEFE7D8, 0xFFE5DAC7, 0xFFDDD2BE,
        0xFF6B4F3A, 0xFFA8794F, 0xFF2B241C, 0xFF6E6353, 0xFFB85C3A,
        0xFF7A5200, 0x122B241C,
        // Petrol Light
        0xFFF7F9F8, 0xFFE0E9E7, 0xFFFCFEFD, 0xFFEDF3F2, 0xFFB7CBC8,
        0xFF143C4A, 0xFFF5F8F7, 0xFF2E6E85, 0xFF10262E, 0xFF43606A,
        0xFF865F1B, 0xFFB27F26, 0x1A143C4A,
      };

      for (final farbe in _rollen(AppColors.hell).entries) {
        expect(
          abgelegt.contains(farbe.value.toARGB32()),
          isFalse,
          reason: '${farbe.key} traegt noch einen abgelegten Wert',
        );
      }
    });

    test('und der helle Modus ist durchgehend warm', () {
      // Kein kuehler oder grauer Stich in den Flaechen: Bei jeder von ihnen
      // liegt Rot ueber Blau.
      for (final flaeche in {
        'hintergrund': AppColors.hell.hintergrund,
        'hintergrundTief': AppColors.hell.hintergrundTief,
        'flaeche': AppColors.hell.flaeche,
        'flaecheHoch': AppColors.hell.flaecheHoch,
        'erreichtLeer': AppColors.hell.erreichtLeer,
        'erreichtChip': AppColors.hell.erreichtChip,
      }.entries) {
        expect(
          (flaeche.value.r * 255).round(),
          greaterThan((flaeche.value.b * 255).round()),
          reason: '${flaeche.key} ist kuehl statt warm',
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

    test('die Flaeche hebt sich von ihrer leeren Gegenseite ab', () {
      // Ein gefuelltes Segment traegt keinen Text – dort zaehlt, dass es
      // vom ungefuellten daneben zu unterscheiden ist.
      //
      // Ehrlich gemessen: Das Amber aus dem Referenzbild kommt gegen die
      // helle Karte nur auf 2,4:1 und gegen den Creme-Amber daneben auf
      // 2,1:1 – die 3:1 der WCAG fuer grafische Elemente erreicht es nicht.
      // Getragen wird der Zustand deshalb nie von der Flaeche allein: Im
      // Haken steht ein Haken, am Zaehler eine Zahl, an der Challenge die
      // Angabe „1 von 4". Das steht hier, damit es niemand fuer ein
      // Versehen haelt (DECISIONS 63).
      for (final schema in {'dunkel': AppColors.dunkel, 'hell': AppColors.hell}.entries) {
        final farben = schema.value;
        // Dunkel ist die leere Seite durchscheinend – gemessen wird, was
        // auf der Karte ankommt.
        final leer = Color.alphaBlend(farben.erreichtLeer, farben.flaeche);
        expect(
          _kontrast(farben.erreichtFlaeche, leer),
          greaterThanOrEqualTo(1.9),
          reason: 'gefuellt gegen leer (${schema.key})',
        );
      }
    });

    test('der Zaehler-Chip traegt seinen Text', () {
      // Er ist 12 Punkt – also die volle Textschwelle. Geprueft wird der
      // helle Modus: Dort ist der Chip eine deckende Flaeche und neu
      // gewaehlt (DECISIONS 63). Dunkel bleibt er die durchscheinende
      // Toenung, die er immer war – dort haelt ihn der Einfrier-Test, und
      // sein Verhaeltnis von 3,7:1 ist unveraendert seit DECISIONS 50.
      final grund = Color.alphaBlend(
        AppColors.hell.erreichtChip,
        AppColors.hell.flaeche,
      );

      expect(
        _kontrast(grund, AppColors.hell.erreicht),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('was darauf liegt, ist im Dunkelmodus klar zu sehen', () {
      expect(
        _kontrast(
          AppColors.dunkel.erreichtFlaeche,
          AppColors.dunkel.aufErreicht,
        ),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('hell ist der Haken eine ausdrueckliche Ausnahme', () {
      // Das Karten-Weiss auf dem Amber kommt auf rund 2,5:1 und erreicht
      // damit keine Schwelle – weder die 4,5:1 fuer Text noch die 3:1 fuer
      // grafische Elemente.
      //
      // Das ist bewusst so entschieden (DECISIONS 64): Der Haken ist
      // Zierrat. Was er anzeigt, steht immer auch woanders — die erledigte
      // Aufgabe ist durchgestrichen, der Zaehler nennt „2/5", die Challenge
      // „1 von 4". Die Alternative war die dunkle Tinte, und die ergab
      // Braun auf Orange – genau der Look, der weg sollte.
      //
      // Der Test haelt die Zahl fest, damit sie niemand fuer ein Versehen
      // haelt und niemand sie unbemerkt verschlechtert.
      final wert = _kontrast(
        AppColors.hell.erreichtFlaeche,
        AppColors.hell.aufErreicht,
      );

      expect(wert, greaterThan(2.3));
      expect(wert, lessThan(2.8));
      // Und es ist wirklich das Karten-Weiss, keine dritte Farbe.
      expect(AppColors.hell.aufErreicht, AppColors.hell.flaeche);
    });

    test('im Dunkelmodus sind Text- und Flaechen-Gold derselbe Ton', () {
      // Auf dunklem Grund braucht es die Trennung nicht – und genau
      // deshalb aendert sie am Dunkelmodus nichts.
      expect(AppColors.dunkel.erreichtFlaeche, AppColors.dunkel.erreicht);
      expect(AppColors.dunkel.aufErreicht, AppColors.dunkel.aufAkzent);
    });

    test('im hellen Modus sind sie verschieden – und beide Amber', () {
      expect(AppColors.hell.erreichtFlaeche, isNot(AppColors.hell.erreicht));
      // Beide warm: Rot deutlich ueber Blau.
      for (final ton in [AppColors.hell.erreicht, AppColors.hell.erreichtFlaeche]) {
        expect((ton.r * 255).round(), greaterThan((ton.b * 255).round() + 60));
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
