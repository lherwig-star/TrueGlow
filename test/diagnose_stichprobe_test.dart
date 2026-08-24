import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';

import '../tool/diagnose_pruefung.dart';

/// Die Stichprobe aus Roadmap 2.4, als Testfall statt als Handarbeit.
///
/// Geprüft wird gegen die Beispielantworten des Mock-Dienstes — je eine pro
/// Modul, also fünf Antworten. Die Live-Antworten laufen über dasselbe
/// Regelwerk, aber über `tool/diagnose_stichprobe.dart`, weil sie ein
/// Firebase-Projekt brauchen.
void main() {
  group('Regelwerk', () {
    test('erkennt ein Diagnosewort', () {
      final befunde = verstoesse('Das ist ein klarer Befund einer Erkrankung.');

      expect(befunde, isNotEmpty);
      expect(befunde.first.regel.name, 'Diagnosewort');
    });

    test('erkennt benannte Krankheitsbilder', () {
      expect(verstoesse('Hier liegt eine Rosazea vor.'), isNotEmpty);
      expect(verstoesse('Deine Zähne zeigen Karies.'), isNotEmpty);
    });

    test('erkennt Behandlungsempfehlungen', () {
      expect(verstoesse('Trag abends eine Kortisonsalbe auf.'), isNotEmpty);
      expect(verstoesse('Dafür braucht es ein Rezept.'), isNotEmpty);
    });

    test('erkennt Bewertungszahlen und Attraktivitätsurteile', () {
      expect(verstoesse('Deine Haut ist eine 7 von 10.'), isNotEmpty);
      expect(verstoesse('Das wirkt überdurchschnittlich attraktiv.'),
          isNotEmpty);
    });

    test('erkennt Gewichtsurteile', () {
      expect(verstoesse('Du bist leicht übergewichtig.'), isNotEmpty);
      expect(verstoesse('Am besten machst du eine Diät.'), isNotEmpty);
    });

    test('laesst normale Empfehlungen in Ruhe', () {
      // Das ist der eigentliche Zweck: Der Waechter darf nicht bei jedem
      // Pflegehinweis anschlagen, sonst benutzt ihn niemand.
      const harmlos = 'Trag morgens eine leichte Feuchtigkeitscreme auf und '
          'nutze täglich Sonnenschutz mit LSF 30. Die Seiten kürzer halten '
          'als das Deckhaar.';

      expect(pruefe(harmlos), isEmpty);
    });

    test('meldet den Zusammenhang mit', () {
      final befund = verstoesse('Ich sehe hier eine Neurodermitis.').single;

      expect(befund.umgebung, contains('Neurodermitis'));
      expect(befund.regel.warum, isNotEmpty);
    });
  });

  group('Stichprobe über die Beispielantworten', () {
    test('jedes Modul einzeln bleibt sauber', () {
      for (final modul in AnalyseModul.values) {
        final antwort = MockAnalysisService.antwortFuer({
          AnalyseModul.basis,
          modul,
        });

        expect(
          verstoesse(antwort),
          isEmpty,
          reason: 'Modul ${modul.name}: ${verstoesse(antwort)}',
        );
      }
    });

    test('die vollstaendige Antwort ueber alle Module bleibt sauber', () {
      final befunde = pruefe(MockAnalysisService.beispielAntwort);

      expect(befunde, isEmpty, reason: '$befunde');
    });
  });
}
