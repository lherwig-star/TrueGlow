import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analyse_modus.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';

/// Beispielbilder unter den Vorschlaegen – DECISIONS 69.
///
/// Der Suchbegriff ist das einzige Stueck, das vom Modell kommt. Er wird nie
/// angezeigt, entscheidet aber darueber, welche Fotos unter dem Vorschlag
/// stehen. Hier steht, was die App daraus liest.
void main() {
  AnalysisResult lies(String antwort) => AnalysisResult.vonApi(
        JsonExtractor.extrahiere(antwort)!,
        id: 'test',
        erstelltAm: DateTime(2026, 8, 27),
      );

  Sektion sektion({Object? begriff = _fehlt}) => Sektion.fromJson({
        'titel': 'Frisur',
        'einschaetzung': 'Text.',
        'empfehlungen': <String>[],
        'produkte': <Object>[],
        if (!identical(begriff, _fehlt)) 'bildSuchbegriff': begriff,
      });

  group('Die Sektion liest den Suchbegriff', () {
    test('wenn einer da ist', () {
      final s = sektion(begriff: 'textured crop haircut men');

      expect(s.bildSuchbegriff, 'textured crop haircut men');
      expect(s.zeigtBilder, isTrue);
    });

    test('und raeumt Leerraum weg', () {
      expect(sektion(begriff: '  short beard men  ').bildSuchbegriff,
          'short beard men');
    });

    test('null heisst: hier hilft kein Foto', () {
      // Eine Pflegeroutine laesst sich nicht abbilden. Das ist die
      // vorgesehene Antwort des Modells und kein Fehler.
      final s = sektion(begriff: null);

      expect(s.bildSuchbegriff, isNull);
      expect(s.zeigtBilder, isFalse);
    });

    test('ein alter Report hat das Feld gar nicht', () {
      // Reports von vor DECISIONS 69 zeigen einfach keine Bilder – es gibt
      // keine Wanderung und keinen Fehler.
      final s = sektion();

      expect(s.bildSuchbegriff, isNull);
      expect(s.zeigtBilder, isFalse);
    });

    test('Unsinn faellt heraus, statt den Report zu zerlegen', () {
      for (final unsinn in <Object>[42, '', '   ', <String>['a']]) {
        expect(sektion(begriff: unsinn).bildSuchbegriff, isNull,
            reason: '$unsinn');
      }
    });
  });

  group('Der Begriff ueberlebt das Speichern', () {
    test('und fehlt im gespeicherten Report, wenn es keinen gibt', () {
      // Kein `"bildSuchbegriff": null` in jedem Dokument: Das Feld steht nur
      // da, wo es etwas bedeutet.
      expect(sektion().toJson().containsKey('bildSuchbegriff'), isFalse);
      expect(
        sektion(begriff: null).toJson().containsKey('bildSuchbegriff'),
        isFalse,
      );
    });

    test('und steht wieder da, wenn es einen gab', () {
      final vorher = sektion(begriff: 'smart casual outfit men');
      final nachher = Sektion.fromJson(vorher.toJson());

      expect(nachher.bildSuchbegriff, 'smart casual outfit men');
    });
  });

  group('Der Demo-Modus zeigt beide Faelle', () {
    for (final modus in AnalyseModus.values) {
      test('${modus.name}: Vorschlaege mit und ohne Bilderreihe', () {
        final report = lies(
          MockAnalysisService.antwortFuer(
            AnalyseModul.bestellbar.toSet(),
            modus: modus,
          ),
        );
        final alle = [for (final k in report.kapitel) ...k.sektionen];

        // Beides muss vorkommen, sonst laesst sich im Demo-Modus nur die
        // Haelfte pruefen: eine Frisur mit Bildern, eine Pflegeroutine ohne.
        expect(alle.where((s) => s.zeigtBilder), isNotEmpty);
        expect(alle.where((s) => !s.zeigtBilder), isNotEmpty);
      });

      test('${modus.name}: die Demo-Begriffe halten die Prompt-Regel ein', () {
        final report = lies(
          MockAnalysisService.antwortFuer(
            AnalyseModul.bestellbar.toSet(),
            modus: modus,
          ),
        );

        for (final kapitel in report.kapitel) {
          for (final s in kapitel.sektionen) {
            final begriff = s.bildSuchbegriff;
            if (begriff == null) continue;

            // Dieselben Schranken, die der Server durchsetzt: englisch
            // (also ohne Umlaute), klein, zwei bis sechs Woerter.
            expect(begriff, matches(RegExp(r"^[a-z0-9][a-z0-9 '&-]*$")),
                reason: begriff);
            expect(begriff.split(' ').length, inInclusiveRange(2, 6),
                reason: begriff);
          }
        }
      });
    }
  });
}

/// Steht fuer „das Feld fehlt ganz" – zu unterscheiden von `null`.
const Object _fehlt = Object();
