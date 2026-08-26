import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/plan/logic/wochen_rueckblick.dart';

/// Der Wochen-Rückblick.
///
/// Rechnet ausschließlich aus den Haken, die ohnehin gespeichert sind — kein
/// Modellaufruf, keine Kosten. Geprüft wird hier die Rechnung und das
/// Zeitfenster; das Aussehen der Karte steht im Testplan.
void main() {
  // Montag, 24. August 2026. Der Sonntag dieser Woche ist der 30.
  final montag = DateTime(2026, 8, 24);

  Set<String> Function(DateTime) haken(Map<int, List<String>> jeTag) =>
      (tag) {
        final index = tag.difference(montag).inDays;
        return (jeTag[index] ?? const <String>[]).toSet();
      };

  group('Die Rechnung', () {
    test('zählt aktive Tage und Aufgaben', () {
      final bilanz = wochenbilanz(
        montag: montag,
        erledigteAm: haken({
          0: ['a', 'b'],
          2: ['a'],
          6: ['a', 'b', 'c'],
        }),
        habitsJeKapitel: const {},
      );

      expect(bilanz.aktiveTage, 3);
      expect(bilanz.aufgaben, 6);
    });

    test('der Check-in-Marker sichert den Tag, ist aber keine Aufgabe', () {
      // Er liegt im selben Topf wie die Haken, damit der Streak ihn ohne
      // Sonderweg mitzählt. In der Aufgabenzahl hätte er nichts zu suchen.
      final bilanz = wochenbilanz(
        montag: montag,
        erledigteAm: haken({
          1: [PlanProgressRepository.checkinMarker],
          3: ['a', PlanProgressRepository.checkinMarker],
        }),
        habitsJeKapitel: const {},
      );

      expect(bilanz.aktiveTage, 2);
      expect(bilanz.aufgaben, 1);
    });

    test('findet den stärksten Bereich', () {
      final bilanz = wochenbilanz(
        montag: montag,
        erledigteAm: haken({
          0: ['haar', 'zahn'],
          1: ['haar'],
          2: ['haar', 'zahn'],
        }),
        habitsJeKapitel: const {
          'haar': AnalyseModul.basis,
          'zahn': AnalyseModul.zaehneLaecheln,
        },
      );

      expect(bilanz.staerksterBereich, AnalyseModul.basis);
    });

    test('bei Gleichstand entscheidet die Reihenfolge der Module', () {
      // Sonst zeigte dieselbe Woche bei jedem Aufruf einen anderen Sieger.
      final bilanz = wochenbilanz(
        montag: montag,
        erledigteAm: haken({
          0: ['haar', 'zahn'],
        }),
        habitsJeKapitel: const {
          'haar': AnalyseModul.basis,
          'zahn': AnalyseModul.zaehneLaecheln,
        },
      );

      expect(bilanz.staerksterBereich, AnalyseModul.basis);
    });

    test('unbekannte Aufgaben zählen mit, aber auf keinen Bereich', () {
      // Nach einer neuen Analyse steht in den alten Tagen Text, den es im
      // aktuellen Report nicht mehr gibt.
      final bilanz = wochenbilanz(
        montag: montag,
        erledigteAm: haken({
          0: ['aus einer alten Analyse'],
        }),
        habitsJeKapitel: const {'haar': AnalyseModul.basis},
      );

      expect(bilanz.aufgaben, 1);
      expect(bilanz.staerksterBereich, isNull);
    });

    test('eine leere Woche ist leer, aber nicht kaputt', () {
      final bilanz = wochenbilanz(
        montag: montag,
        erledigteAm: haken(const {}),
        habitsJeKapitel: const {},
      );

      expect(bilanz.aktiveTage, 0);
      expect(bilanz.aufgaben, 0);
      expect(bilanz.staerksterBereich, isNull);
      expect(bilanz.istLeer, isTrue);
    });

    test('nur die sieben Tage der Woche zählen', () {
      // Der Montag danach gehört zur nächsten Woche.
      final bilanz = wochenbilanz(
        montag: montag,
        erledigteAm: haken({7: ['a', 'b']}),
        habitsJeKapitel: const {},
      );

      expect(bilanz.aktiveTage, 0);
      expect(bilanz.sonntag, DateTime(2026, 8, 30));
    });
  });

  group('Der Ton', () {
    test('lobt ab fünf aktiven Tagen', () {
      expect(tonFuer(7), Wochenton.stark);
      expect(tonFuer(5), Wochenton.stark);
    });

    test('nennt drei und vier Tage solide', () {
      expect(tonFuer(4), Wochenton.solide);
      expect(tonFuer(3), Wochenton.solide);
    });

    test('wird auch bei null und eins nicht vorwurfsvoll', () {
      // Der Ton ist die halbe Funktion: Wer nach einer schlechten Woche eine
      // Rechnung präsentiert bekommt, macht die App nicht wieder auf.
      expect(tonFuer(2), Wochenton.klein);
      expect(tonFuer(1), Wochenton.leer);
      expect(tonFuer(0), Wochenton.leer);
    });
  });

  group('Das Zeitfenster', () {
    test('vor Sonntagabend gibt es keinen Rückblick', () {
      expect(rueckblickWoche(DateTime(2026, 8, 26, 20)), isNull);
      expect(rueckblickWoche(DateTime(2026, 8, 30, 17, 59)), isNull);
    });

    test('am Sonntag ab 18 Uhr kommt die laufende Woche', () {
      expect(rueckblickWoche(DateTime(2026, 8, 30, 18)), montag);
      expect(rueckblickWoche(DateTime(2026, 8, 30, 23, 59)), montag);
    });

    test('der Montag zeigt noch die Woche davor', () {
      // Damit der Rückblick nicht an denen vorbeiläuft, die ihn am ehesten
      // brauchen — an denen, die das Wochenende über nicht hineingesehen
      // haben.
      expect(rueckblickWoche(DateTime(2026, 8, 31, 7)), montag);
      expect(rueckblickWoche(DateTime(2026, 8, 31, 23, 30)), montag);
    });

    test('ab Dienstag ist er wieder weg', () {
      expect(rueckblickWoche(DateTime(2026, 9, 1, 0, 1)), isNull);
    });

    test('montagVon findet den Wochenanfang', () {
      for (var i = 0; i < 7; i += 1) {
        expect(montagVon(montag.add(Duration(days: i))), montag);
      }
    });
  });
}
