import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/plan/logic/wochen_challenge.dart';
import 'package:trueglow/features/streak/logic/streak_repository.dart';
import 'package:trueglow/features/streak/models/abzeichen.dart';

import 'hilfen.dart';

/// Die Wochen-Challenge.
///
/// Rotiert aus einem festen Vorrat und rechnet ausschließlich aus den Haken,
/// die ohnehin gespeichert sind — kein Modellaufruf, keine Kosten.
void main() {
  // Montag, 24. August 2026.
  final montag = DateTime(2026, 8, 24);

  Set<String> Function(DateTime) haken(Map<int, List<String>> jeTag) => (tag) {
        final index = tag.difference(montag).inDays;
        return (jeTag[index] ?? const <String>[]).toSet();
      };

  int stand(
    Challengevorlage vorlage,
    Map<int, List<String>> jeTag, {
    List<String> plan = const ['a', 'b', 'c'],
  }) =>
      challengeStand(
        vorlage: vorlage,
        montag: montag,
        erledigteAm: haken(jeTag),
        habits: plan,
      );

  group('Der Vorrat', () {
    test('hat zehn Vorlagen', () {
      // Genug, dass sich in einem Vierteljahr nichts wiederholt.
      expect(vorrat, hasLength(10));
    });

    test('deckt jede Sorte ab', () {
      expect(
        vorrat.map((v) => v.art).toSet(),
        Challengeart.values.toSet(),
      );
    });

    test('jede Vorlage hat einen Text in beiden Sprachen', () {
      for (final vorlage in vorrat) {
        final de = vorlage.art.text(texte, vorlage.ziel);
        final en = vorlage.art.text(englischeTexte, vorlage.ziel);
        expect(de, isNotEmpty);
        expect(en, isNotEmpty);
        expect(de, isNot(en), reason: 'unübersetzt: ${vorlage.art.name}');
      }
    });

    test('jede Vorlage hat ein erreichbares Ziel', () {
      for (final vorlage in vorrat) {
        expect(vorlage.ziel, greaterThan(0));
        if (vorlage.art == Challengeart.aktiveTage ||
            vorlage.art == Challengeart.serie ||
            vorlage.art == Challengeart.volleTage) {
          expect(vorlage.ziel, lessThanOrEqualTo(7));
        }
      }
    });
  });

  group('Die Rotation', () {
    test('läuft der Reihe nach durch den Vorrat', () {
      for (var woche = 0; woche < vorrat.length; woche += 1) {
        final tag = challengeEpoche.add(Duration(days: 7 * woche));
        expect(vorlageFuer(tag), vorrat[woche]);
      }
    });

    test('fängt nach dem Vorrat wieder von vorn an', () {
      final nachEinerRunde =
          challengeEpoche.add(Duration(days: 7 * vorrat.length));
      expect(vorlageFuer(nachEinerRunde), vorrat.first);
    });

    test('kommt auch mit Wochen vor der Epoche klar', () {
      // Ein Gerät mit falsch gestelltem Datum darf nicht abstürzen.
      final davor = challengeEpoche.subtract(const Duration(days: 7));
      expect(() => vorlageFuer(davor), returnsNormally);
      expect(vorrat, contains(vorlageFuer(davor)));
    });

    test('zwei aufeinanderfolgende Wochen sind verschieden', () {
      for (var woche = 0; woche < vorrat.length; woche += 1) {
        final a = vorlageFuer(challengeEpoche.add(Duration(days: 7 * woche)));
        final b =
            vorlageFuer(challengeEpoche.add(Duration(days: 7 * (woche + 1))));
        expect(a, isNot(b));
      }
    });
  });

  group('Der Fortschritt', () {
    test('aktive Tage zählt Tage mit mindestens einem Haken', () {
      const vorlage = Challengevorlage(Challengeart.aktiveTage, 3,
          icon: _icon);
      expect(stand(vorlage, {0: ['a'], 2: ['a', 'b'], 5: ['c']}), 3);
    });

    test('die Serie nimmt die längste Kette der Woche', () {
      const vorlage =
          Challengevorlage(Challengeart.serie, 4, icon: _icon);
      // Mo, Di frei, dann Mi–Sa: die längste Kette ist 4.
      expect(stand(vorlage, {0: ['a'], 2: ['a'], 3: ['a'], 4: ['a'], 5: ['a']}), 4);
    });

    test('volle Tage brauchen die komplette Liste', () {
      const vorlage =
          Challengevorlage(Challengeart.volleTage, 2, icon: _icon);
      expect(
        stand(vorlage, {
          0: ['a', 'b', 'c'],
          1: ['a', 'b'],
          2: ['c', 'b', 'a'],
        }),
        2,
      );
    });

    test('ohne Plan gibt es keine vollen Tage', () {
      // Eine leere Checkliste ist nicht abgehakt, sondern leer.
      const vorlage =
          Challengevorlage(Challengeart.volleTage, 1, icon: _icon);
      expect(stand(vorlage, {0: ['a']}, plan: const []), 0);
    });

    test('die Aufgabensumme lässt den Check-in-Marker aus', () {
      const vorlage =
          Challengevorlage(Challengeart.aufgaben, 15, icon: _icon);
      expect(
        stand(vorlage, {
          0: ['a', 'b', PlanProgressRepository.checkinMarker],
          1: ['a'],
        }),
        3,
      );
    });

    test('die frühe Woche zählt nur Montag bis Mittwoch', () {
      const vorlage = Challengevorlage(Challengeart.frueheWoche, 3,
          icon: _icon);
      expect(stand(vorlage, {0: ['a'], 1: ['a'], 2: ['a'], 4: ['a']}), 3);
      expect(stand(vorlage, {3: ['a'], 4: ['a'], 5: ['a']}), 0);
    });

    test('das Wochenende zählt nur Samstag und Sonntag', () {
      const vorlage = Challengevorlage(Challengeart.wochenende, 2,
          icon: _icon);
      expect(stand(vorlage, {5: ['a'], 6: ['a']}), 2);
      expect(stand(vorlage, {0: ['a'], 1: ['a'], 2: ['a'], 3: ['a'], 4: ['a']}), 0);
    });
  });

  group('Das Abzeichen', () {
    test('fällt nach vier geschafften Challenges', () {
      final vorher = abzeichenStaende(
        streak: StreakStand.leer,
        analyse: null,
        challenges: 3,
      ).firstWhere((s) => s.abzeichen == Abzeichen.challenges);
      expect(vorher.erreicht, isFalse);
      expect(vorher.fehlend, 1);

      final nachher = abzeichenStaende(
        streak: StreakStand.leer,
        analyse: null,
        challenges: Abzeichen.challengeZiel,
      ).firstWhere((s) => s.abzeichen == Abzeichen.challenges);
      expect(nachher.erreicht, isTrue);
      expect(nachher.fehlend, 0);
    });

    test('ohne geschaffte Challenge fehlen alle vier', () {
      final stand = abzeichenStaende(streak: StreakStand.leer, analyse: null)
          .firstWhere((s) => s.abzeichen == Abzeichen.challenges);

      expect(stand.fehlend, Abzeichen.challengeZiel);
    });
  });
}

/// Welches Icon eine Testvorlage traegt, spielt fuer die Rechnung keine
/// Rolle – gebraucht wird nur irgendeines.
const _icon = Icons.check;
