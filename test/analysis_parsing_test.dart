import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

void main() {
  group('JsonExtractor', () {
    test('liest reines JSON', () {
      final json = JsonExtractor.extrahiere('{"a": 1}');
      expect(json, {'a': 1});
    });

    test('entfernt Markdown-Codefences', () {
      final json = JsonExtractor.extrahiere('```json\n{"a": 1}\n```');
      expect(json, {'a': 1});
    });

    test('entfernt Codefences ohne Sprachangabe', () {
      final json = JsonExtractor.extrahiere('```\n{"a": 1}\n```');
      expect(json, {'a': 1});
    });

    test('schneidet Fliesstext vor und nach dem Objekt weg', () {
      final json = JsonExtractor.extrahiere(
        'Klar, hier ist deine Analyse:\n{"a": 1}\nViel Erfolg!',
      );
      expect(json, {'a': 1});
    });

    test('kommt mit geschweiften Klammern in Strings klar', () {
      final json = JsonExtractor.extrahiere(
        'Antwort: {"text": "eine } Klammer", "b": 2} Ende',
      );
      expect(json?['text'], 'eine } Klammer');
      expect(json?['b'], 2);
    });

    test('gibt null zurueck, wenn gar kein JSON drin ist', () {
      expect(JsonExtractor.extrahiere('Tut mir leid, das geht nicht.'), isNull);
      expect(JsonExtractor.extrahiere(''), isNull);
    });

    test('gibt null bei kaputtem JSON zurueck', () {
      expect(JsonExtractor.extrahiere('{"a": }'), isNull);
    });
  });

  group('AnalysisResult', () {
    test('liest das vollstaendige Schema', () {
      final json = JsonExtractor.extrahiere(
        MockAnalysisService.beispielAntwort,
      );
      expect(json, isNotNull);

      final ergebnis = AnalysisResult.vonApi(
        json!,
        id: 'test',
        erstelltAm: DateTime(2026, 8, 22),
      );

      expect(ergebnis.gesichtsform, isNotEmpty);
      expect(ergebnis.sektionen.length, greaterThanOrEqualTo(3));
      expect(ergebnis.alleHabits, isNotEmpty);
      expect(ergebnis.istVollstaendig, isTrue);

      // Ein Kapitel pro Modul, in Modul-Reihenfolge.
      expect(ergebnis.module, AnalyseModul.values.toSet());
      expect(ergebnis.kapitel.first.modul, AnalyseModul.basis);

      final frisur = ergebnis.kapitel.first.sektionen.first;
      expect(frisur.titel, 'Frisur');
      expect(frisur.empfehlungen, isNotEmpty);
      expect(frisur.produkte.first.affiliateUrl, isNull);
    });

    test('ueberlebt fehlende und falsch getypte Felder', () {
      final ergebnis = AnalysisResult.vonApi(
        {
          'kapitel': 'kein Array',
          'sektionen': 'auch kein Array',
          'plan': null,
        },
        id: 'test',
        erstelltAm: DateTime(2026, 8, 22),
      );

      expect(ergebnis.kapitel, isEmpty);
      expect(ergebnis.gesichtsform, '');
      expect(ergebnis.sektionen, isEmpty);
      expect(ergebnis.plan.istLeer, isTrue);
      expect(ergebnis.istVollstaendig, isFalse);
    });

    test('liest Analysen aus der Zeit vor den Modulen als Basis-Kapitel', () {
      final ergebnis = AnalysisResult.vonApi(
        {
          'gesichtsform': 'oval',
          'sektionen': [
            {'titel': 'Haut', 'einschaetzung': 'ok', 'empfehlungen': ['x']},
          ],
          'plan': {'taeglicheHabits': ['trinken']},
        },
        id: 'alt',
        erstelltAm: DateTime(2026, 8, 22),
      );

      expect(ergebnis.kapitel.single.modul, AnalyseModul.basis);
      expect(ergebnis.gesichtsform, 'oval');
      expect(ergebnis.sektionen.single.titel, 'Haut');
    });

    test('haengt ein Kapitel an, ohne bestehende zu veraendern', () {
      final basis = AnalysisResult.vonApi(
        JsonExtractor.extrahiere(
          MockAnalysisService.antwortFuer({AnalyseModul.basis}),
        )!,
        id: 'a1',
        erstelltAm: DateTime(2026, 8, 22),
      );
      expect(basis.module, {AnalyseModul.basis});

      final zusatz = AnalysisResult.vonApi(
        JsonExtractor.extrahiere(
          MockAnalysisService.antwortFuer({AnalyseModul.zaehneLaecheln}),
        )!,
        id: 'a2',
        erstelltAm: DateTime(2026, 8, 23),
      );

      final erweitert = basis.mitKapitel(
        zusatz.kapitel.single,
        planErgaenzung: zusatz.plan,
      );

      expect(erweitert.id, 'a1');
      expect(erweitert.module, {AnalyseModul.basis, AnalyseModul.zaehneLaecheln});
      // Das Basis-Kapitel ist unveraendert geblieben.
      expect(erweitert.kapitel.first.einleitung, basis.kapitel.first.einleitung);
      expect(
        erweitert.kapitel.first.sektionen.length,
        basis.kapitel.first.sektionen.length,
      );
    });

    test('filtert leere Eintraege aus Listen', () {
      final sektion = Sektion.fromJson({
        'titel': 'Haut',
        'einschaetzung': 'ok',
        'empfehlungen': ['echt', '', '   ', null, 'auch echt'],
        'produkte': ['kein Objekt'],
      });

      expect(sektion.empfehlungen, ['echt', 'auch echt']);
      expect(sektion.produkte, isEmpty);
    });

    test('ueberlebt eine Speicher-Runde verlustfrei', () {
      final json = JsonExtractor.extrahiere(
        MockAnalysisService.beispielAntwort,
      )!;
      final original = AnalysisResult.vonApi(
        json,
        id: 'abc',
        erstelltAm: DateTime(2026, 8, 22, 14, 30),
      );

      final zurueck = AnalysisResult.fromJson(original.toJson());

      expect(zurueck.id, 'abc');
      expect(zurueck.erstelltAm, DateTime(2026, 8, 22, 14, 30));
      expect(zurueck.gesichtsform, original.gesichtsform);
      expect(zurueck.sektionen.length, original.sektionen.length);
      expect(zurueck.anzahlEmpfehlungen, original.anzahlEmpfehlungen);
      expect(zurueck.alleHabits, original.alleHabits);
    });
  });

  group('MockAnalysisService', () {
    test('liefert nach kurzer Wartezeit ein vollstaendiges Ergebnis', () async {
      const service = MockAnalysisService();

      final ergebnis = await service.analysiere(
        // Der Mock liest die Dateien nicht – Pfade reichen.
        fotos: {AufnahmeTyp.basisFrontal: File('frontal.jpg')},
        module: {AnalyseModul.basis},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
      );

      expect(ergebnis.istVollstaendig, isTrue);
      expect(ergebnis.id, isNotEmpty);
      expect(ergebnis.plan.sofort, isNotEmpty);
    });
  });

  group('Checklisten pro Kapitel', () {
    AnalysisResult fuer(Set<AnalyseModul> module) => AnalysisResult.vonApi(
          JsonExtractor.extrahiere(MockAnalysisService.antwortFuer(module))!,
          id: 'x',
          erstelltAm: DateTime(2026, 8, 22),
        );

    test('jedes Kapitel bringt seine eigene Checkliste mit', () {
      final ergebnis = fuer(AnalyseModul.values.toSet());

      expect(ergebnis.checklisten.length, AnalyseModul.values.length);
      for (final kapitel in ergebnis.checklisten) {
        expect(kapitel.habits.length, greaterThanOrEqualTo(4));
        expect(kapitel.habits.length, lessThanOrEqualTo(7));
      }
    });

    test('kein Punkt stammt aus einem nicht gewaehlten Modul', () {
      // Genau der gemeldete Fall: Basis + Haut + Zaehne, aber die
      // Haltungsuebung aus "Figur & Passform" tauchte trotzdem auf.
      final auswahl = {
        AnalyseModul.basis,
        AnalyseModul.hautFarbtyp,
        AnalyseModul.zaehneLaecheln,
      };
      final ergebnis = fuer(auswahl);

      expect(ergebnis.module, auswahl);

      // Alle Punkte der nicht gewaehlten Module duerfen nirgends auftauchen.
      final verboten = fuer({AnalyseModul.figurPassform, AnalyseModul.stilKleiderschrank})
          .alleHabits
          .toSet();
      expect(verboten, isNotEmpty);
      for (final habit in ergebnis.alleHabits) {
        expect(verboten, isNot(contains(habit)));
      }
      expect(
        ergebnis.alleHabits,
        isNot(contains('30 Sekunden Brustöffner im Türrahmen')),
      );
    });

    test('mehr Module ergeben mehr Punkte, nie weniger', () {
      final nurBasis = fuer({AnalyseModul.basis}).alleHabits.length;
      final mitZwei = fuer({
        AnalyseModul.basis,
        AnalyseModul.hautFarbtyp,
        AnalyseModul.zaehneLaecheln,
      }).alleHabits.length;
      final alle = fuer(AnalyseModul.values.toSet()).alleHabits.length;

      expect(mitZwei, greaterThan(nurBasis));
      expect(alle, greaterThan(mitZwei));
    });

    test('nachtraeglich ergaenztes Modul bringt seine Checkliste mit', () {
      final basis = fuer({AnalyseModul.basis});
      final zusatz = fuer({AnalyseModul.zaehneLaecheln});

      final erweitert = basis.mitKapitel(zusatz.kapitel.single);

      expect(erweitert.checklisten.length, 2);
      expect(
        erweitert.alleHabits.length,
        basis.alleHabits.length + zusatz.alleHabits.length,
      );
    });

    test('Altbestand ohne Kapitel behaelt seine Tagesaufgaben', () {
      final ergebnis = AnalysisResult.vonApi(
        {
          'gesichtsform': 'oval',
          'sektionen': [
            {'titel': 'Haut', 'einschaetzung': 'ok', 'empfehlungen': ['x']},
          ],
          'plan': {'taeglicheHabits': ['Wasser trinken', 'Sonnenschutz']},
        },
        id: 'alt',
        erstelltAm: DateTime(2026, 8, 22),
      );

      expect(ergebnis.checklisten.single.modul, AnalyseModul.basis);
      expect(ergebnis.alleHabits, ['Wasser trinken', 'Sonnenschutz']);
    });
  });
}
