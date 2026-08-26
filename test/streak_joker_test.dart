import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/streak/logic/streak_repository.dart';

/// Der Streak-Joker.
///
/// Zwei pro Kalendermonat fangen einen verpassten Tag ab, ohne dass der
/// Nutzer etwas tun muss. Die Regel steckt vollständig in [serieRechnen] —
/// ohne Hive, ohne Riverpod, damit sie sich durchspielen lässt.
///
/// Die beiden Fälle, an denen so etwas erfahrungsgemäß scheitert, stehen
/// unten als eigene Tests: der Joker am losen Ende (ein neuer Nutzer bekäme
/// sonst eine Serie geschenkt) und der Joker, der bei jedem Laden erneut
/// einspringt (dann wäre das Monatskontingent wertlos).
void main() {
  final heute = DateTime(2026, 8, 26);

  String tag(int vorTagen) => PlanProgressRepository.schluessel(
        heute.subtract(Duration(days: vorTagen)),
      );

  /// [geschafft] als Menge von „vor wie vielen Tagen".
  Serienstand rechnen(
    Set<int> geschafft, {
    Set<String> joker = const {},
    int proMonat = StreakRepository.jokerProMonat,
    int startVor = 0,
  }) =>
      serieRechnen(
        start: heute.subtract(Duration(days: startVor)),
        geschafft: (t) =>
            geschafft.contains(heute.difference(t).inDays),
        jokerTage: joker,
        jokerProMonat: proMonat,
      );

  group('Ohne Lücke bleibt alles wie bisher', () {
    test('drei Tage am Stück sind drei Tage', () {
      final serie = rechnen({0, 1, 2});

      expect(serie.laenge, 3);
      expect(serie.neueJoker, isEmpty);
    });

    test('ohne einen einzigen geschafften Tag ist die Serie leer', () {
      final serie = rechnen(const {});

      expect(serie.laenge, 0);
      expect(serie.neueJoker, isEmpty);
    });
  });

  group('Der Joker überbrückt eine Lücke', () {
    test('ein verpasster Tag reißt die Serie nicht mehr ab', () {
      // Heute und vorgestern abgehakt, gestern vergessen.
      final serie = rechnen({0, 2, 3});

      expect(serie.laenge, 3);
      expect(serie.neueJoker, [tag(1)]);
    });

    test('der gerettete Tag zählt nicht mit', () {
      // Vier Kalendertage, drei davon wirklich abgehakt.
      final serie = rechnen({0, 2, 3});

      expect(serie.laenge, 3, reason: 'nicht 4 – der Joker erfindet keinen Tag');
    });

    test('zwei Lücken gehen, drei nicht', () {
      final zwei = rechnen({0, 2, 4, 5});
      expect(zwei.laenge, 4);
      expect(zwei.neueJoker, [tag(1), tag(3)]);

      final drei = rechnen({0, 2, 4, 6, 7});
      expect(drei.laenge, 3, reason: 'nach zwei Jokern ist Schluss');
      expect(drei.neueJoker, [tag(1), tag(3)]);
    });

    test('zwei verpasste Tage hintereinander gehen auch', () {
      final serie = rechnen({0, 3, 4});

      expect(serie.laenge, 3);
      expect(serie.neueJoker, [tag(1), tag(2)]);
    });
  });

  group('Am losen Ende wird kein Joker verbrannt', () {
    test('wer noch nie etwas abgehakt hat, bekommt keine Serie geschenkt', () {
      // Der gefährliche Fall: Beim ersten Start ist jeder Tag rückwärts
      // leer. Ohne Sperre stünde hier eine Serie von 2 aus dem Nichts.
      final serie = rechnen(const {}, startVor: 1);

      expect(serie.laenge, 0);
      expect(serie.neueJoker, isEmpty);
    });

    test('hinter der letzten Lücke muss ein echter Tag stehen', () {
      // Heute abgehakt, davor drei leere Tage und dann nichts mehr: Die
      // beiden Joker werden angesetzt, aber nie bestätigt.
      final serie = rechnen({0});

      expect(serie.laenge, 1);
      expect(serie.neueJoker, isEmpty);
    });

    test('ein noch leerer Vormittag kostet keinen Joker', () {
      // Heute noch nichts, gestern schon: Gerechnet wird ab gestern, für
      // heute springt nie ein Joker ein.
      final serie = rechnen({1, 2}, startVor: 1);

      expect(serie.laenge, 2);
      expect(serie.neueJoker, isEmpty);
    });
  });

  group('Ein verbrauchter Joker bleibt verbraucht', () {
    test('ein bereits geretteter Tag wird nicht erneut bezahlt', () {
      final serie = rechnen({0, 2, 3}, joker: {tag(1)});

      expect(serie.laenge, 3);
      expect(serie.neueJoker, isEmpty, reason: 'der Tag war schon gerettet');
    });

    test('er zählt aber gegen das Kontingent des Monats', () {
      // Ein Joker ist schon weg, also bleibt genau einer – die zweite Lücke
      // beendet die Serie.
      final serie = rechnen({0, 2, 4, 5}, joker: {tag(20)});

      expect(serie.laenge, 2);
      expect(serie.neueJoker, [tag(1)]);
    });

    test('ein Joker aus dem Vormonat belastet den laufenden nicht', () {
      final serie = rechnen({0, 2, 4, 5}, joker: {'2026-07-15'});

      expect(serie.laenge, 4);
      expect(serie.neueJoker, [tag(1), tag(3)]);
    });
  });

  group('Das Kontingent hängt am Kalendermonat des geretteten Tages', () {
    test('eine Lücke über den Monatswechsel zahlen beide Monate', () {
      // Abgehakt am 2. September und am 30. August. Dazwischen liegen zwei
      // leere Tage — der 1. September geht auf das September-Kontingent,
      // der 31. August auf das des August. Ohne diese Trennung wäre einer
      // der beiden Tage zu teuer gewesen.
      final geschafft = {DateTime(2026, 9, 2), DateTime(2026, 8, 30)};

      final serie = serieRechnen(
        start: DateTime(2026, 9, 2),
        geschafft: geschafft.contains,
        jokerTage: const {},
        jokerProMonat: 2,
      );

      expect(serie.laenge, 2);
      expect(serie.neueJoker, ['2026-09-01', '2026-08-31']);
    });

    test('der August hat danach noch einen Joker übrig', () {
      // Fortsetzung des Falls oben: Nach dem 30.08. folgt eine weitere
      // Lücke. Sie ist bezahlbar (zweiter August-Joker), die übernächste
      // nicht mehr.
      final geschafft = {
        DateTime(2026, 9, 2),
        DateTime(2026, 8, 30),
        DateTime(2026, 8, 28),
      };

      final serie = serieRechnen(
        start: DateTime(2026, 9, 2),
        geschafft: geschafft.contains,
        jokerTage: const {},
        jokerProMonat: 2,
      );

      expect(serie.laenge, 3);
      expect(serie.neueJoker, ['2026-09-01', '2026-08-31', '2026-08-29']);
    });
  });
}
