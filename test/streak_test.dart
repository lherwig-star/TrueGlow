import 'package:flutter_test/flutter_test.dart';
import 'package:glowup/features/analysis/logic/json_extractor.dart';
import 'package:glowup/features/analysis/logic/mock_analysis_service.dart';
import 'package:glowup/features/analysis/models/analysis_result.dart';
import 'package:glowup/features/modules/models/analyse_modul.dart';
import 'package:glowup/features/streak/logic/streak_repository.dart';
import 'package:glowup/features/streak/models/abzeichen.dart';

AnalysisResult _analyse(Set<AnalyseModul> module) => AnalysisResult.vonApi(
      JsonExtractor.extrahiere(MockAnalysisService.antwortFuer(module))!,
      id: 'a1',
      erstelltAm: DateTime(2026, 8, 22),
    );

StreakStand _streak(int aktuell, {int? rekord}) => StreakStand(
      aktuell: aktuell,
      rekord: rekord ?? aktuell,
      letzterTag: DateTime(2026, 8, 22),
      heuteGesichert: true,
      gefeiert: const {},
    );

AbzeichenStand _stand(List<AbzeichenStand> alle, Abzeichen gesucht) =>
    alle.firstWhere((s) => s.abzeichen == gesucht);

void main() {
  group('Abzeichen', () {
    test('die Streak-Meilensteine decken die geforderten Stufen ab', () {
      expect(
        Abzeichen.streakZiele.map((a) => a.tage).toList(),
        [3, 7, 14, 30, 60, 90],
      );
    });

    test('zwei Abzeichen haengen nicht am Streak', () {
      final ohneStreak =
          Abzeichen.values.where((a) => !a.istStreakZiel).toList();
      expect(ohneStreak, [Abzeichen.ersteAnalyse, Abzeichen.alleModule]);
    });

    test('jedes Abzeichen hat Titel, Beschreibung und Jubeltext', () {
      for (final abzeichen in Abzeichen.values) {
        expect(abzeichen.titel, isNotEmpty);
        expect(abzeichen.beschreibung, isNotEmpty);
        expect(abzeichen.jubel, isNotEmpty);
      }
    });

    test('der Jubeltext nennt bei Streak-Zielen die Tageszahl', () {
      expect(Abzeichen.siebenTage.jubel, '7 Tage durchgezogen!');
      expect(Abzeichen.dreissigTage.jubel, '30 Tage durchgezogen!');
      // Ohne Tageszahl bleibt es beim Titel.
      expect(Abzeichen.ersteAnalyse.jubel, Abzeichen.ersteAnalyse.titel);
    });
  });

  group('abzeichenStaende', () {
    test('ohne Analyse und ohne Serie ist nichts erreicht', () {
      final staende = abzeichenStaende(streak: StreakStand.leer, analyse: null);

      expect(staende.every((s) => !s.erreicht), isTrue);
      expect(
        _stand(staende, Abzeichen.ersteAnalyse).fortschrittstext,
        'Starte deine erste Analyse',
      );
    });

    test('die erste Analyse schaltet ihr Abzeichen frei', () {
      final staende = abzeichenStaende(
        streak: StreakStand.leer,
        analyse: _analyse({AnalyseModul.basis}),
      );

      expect(_stand(staende, Abzeichen.ersteAnalyse).erreicht, isTrue);
      expect(_stand(staende, Abzeichen.ersteAnalyse).fortschrittstext, isEmpty);
    });

    test('Streak-Abzeichen fallen genau ab ihrer Tageszahl', () {
      final beiSechs = abzeichenStaende(streak: _streak(6), analyse: null);
      expect(_stand(beiSechs, Abzeichen.dreiTage).erreicht, isTrue);
      expect(_stand(beiSechs, Abzeichen.siebenTage).erreicht, isFalse);
      expect(_stand(beiSechs, Abzeichen.siebenTage).fortschrittstext,
          'noch 1 Tag');

      final beiSieben = abzeichenStaende(streak: _streak(7), analyse: null);
      expect(_stand(beiSieben, Abzeichen.siebenTage).erreicht, isTrue);
      expect(
        _stand(beiSieben, Abzeichen.vierzehnTage).fortschrittstext,
        'noch 7 Tage',
      );
    });

    test('alle Module freigeschaltet erst bei vollstaendigem Report', () {
      final teilweise = abzeichenStaende(
        streak: StreakStand.leer,
        analyse: _analyse({AnalyseModul.basis, AnalyseModul.hautFarbtyp}),
      );
      expect(_stand(teilweise, Abzeichen.alleModule).erreicht, isFalse);
      expect(
        _stand(teilweise, Abzeichen.alleModule).fortschrittstext,
        'noch 3 Module',
      );

      final vollstaendig = abzeichenStaende(
        streak: StreakStand.leer,
        analyse: _analyse(AnalyseModul.values.toSet()),
      );
      expect(_stand(vollstaendig, Abzeichen.alleModule).erreicht, isTrue);
    });

    test('der Fortschrittstext steht nur bei offenen Abzeichen', () {
      final staende = abzeichenStaende(
        streak: _streak(90),
        analyse: _analyse(AnalyseModul.values.toSet()),
      );

      expect(staende.every((s) => s.erreicht), isTrue);
      expect(staende.every((s) => s.fortschrittstext.isEmpty), isTrue);
    });

    test('die Reihenfolge folgt der Deklaration', () {
      final staende = abzeichenStaende(streak: StreakStand.leer, analyse: null);
      expect(
        staende.map((s) => s.abzeichen).toList(),
        Abzeichen.values,
      );
    });
  });

  group('Tagesziel', () {
    test('Standard ist "mindestens eine Aufgabe"', () {
      expect(StreakRepository.tagesziel, Tagesziel.eineAufgabe);
    });
  });
}
