import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trueglow/core/storage/hive_service.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/streak/logic/streak_repository.dart';
import 'package:trueglow/features/streak/models/abzeichen.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hilfen.dart';

AnalysisResult _analyse(String id, DateTime datum) => AnalysisResult(
      id: id,
      erstelltAm: datum,
      kapitel: const [
        Kapitel(
          modul: AnalyseModul.basis,
          einleitung: 'oval',
          sektionen: [
            Sektion(
              titel: 'Haut',
              einschaetzung: 'Mischhaut',
              empfehlungen: ['reinigen', 'eincremen'],
              produkte: [
                Produkt(
                  name: 'Reinigungsgel',
                  kategorie: 'Reinigung',
                  beschreibung: 'morgens und abends',
                ),
              ],
            ),
          ],
        ),
      ],
      plan: const Plan(
        sofort: ['heute anfangen'],
        dreissigTage: ['dranbleiben'],
        langfristig: ['durchhalten'],
        taeglicheHabits: ['Wasser trinken', 'Sonnenschutz'],
      ),
    );

void main() {
  hiveImTest();

  group('AnalysisRepository', () {
    AnalysisRepository repo() => AnalysisRepository(
          HiveStore(Hive.box<dynamic>(HiveService.boxAnalysen)),
          HiveStore(Hive.box<dynamic>(HiveService.boxEinstellungen)),
        );

    test('speichert und liest eine Analyse verlustfrei', () async {
      final original = _analyse('a1', DateTime(2026, 8, 20, 10));
      await repo().speichern(original);

      final geladen = repo().laden('a1');
      expect(geladen, isNotNull);
      expect(geladen!.gesichtsform, 'oval');
      expect(geladen.sektionen.single.produkte.single.name, 'Reinigungsgel');
      expect(geladen.plan.taeglicheHabits, ['Wasser trinken', 'Sonnenschutz']);
    });

    test('liefert die Liste neueste zuerst', () async {
      await repo().speichern(_analyse('alt', DateTime(2026, 8, 1)));
      await repo().speichern(_analyse('neu', DateTime(2026, 8, 20)));

      expect(repo().alle().map((a) => a.id), ['neu', 'alt']);
    });

    test('aktuelle() zeigt auf die zuletzt gespeicherte Analyse', () async {
      await repo().speichern(_analyse('a1', DateTime(2026, 8, 1)));
      await repo().speichern(_analyse('a2', DateTime(2026, 8, 20)));

      expect(repo().aktuelle()?.id, 'a2');
    });

    test('nach dem Loeschen der aktuellen rueckt die naechste nach', () async {
      await repo().speichern(_analyse('a1', DateTime(2026, 8, 1)));
      await repo().speichern(_analyse('a2', DateTime(2026, 8, 20)));

      await repo().loeschen('a2');

      expect(repo().laden('a2'), isNull);
      expect(repo().aktuelle()?.id, 'a1');
    });

    test('unlesbare Eintraege werden uebersprungen', () async {
      await repo().speichern(_analyse('gut', DateTime(2026, 8, 20)));
      await Hive.box<dynamic>(HiveService.boxAnalysen)
          .put('kaputt', 'kein JSON');

      expect(repo().alle().map((a) => a.id), ['gut']);
    });
  });

  group('PlanProgressRepository', () {
    PlanProgressRepository repo() => PlanProgressRepository(
          HiveStore(Hive.box<dynamic>(HiveService.boxFortschritt)),
        );

    test('hakt Habits ab und wieder los', () async {
      final r = repo();
      expect(r.erledigteHeute, isEmpty);

      await r.umschalten('Wasser trinken');
      expect(r.erledigteHeute, {'Wasser trinken'});

      await r.umschalten('Wasser trinken');
      expect(r.erledigteHeute, isEmpty);
    });

    test('Fortschritt ueberlebt einen neuen Repository-Zugriff', () async {
      await repo().umschalten('Sonnenschutz');
      expect(repo().erledigteHeute, {'Sonnenschutz'});
    });

    test('Fortschritt eines Tages ist unabhaengig vom naechsten', () async {
      final box = Hive.box<dynamic>(HiveService.boxFortschritt);
      final gestern = DateTime.now().subtract(const Duration(days: 1));
      await box.put(PlanProgressRepository.schluessel(gestern), ['Habit']);

      expect(repo().erledigteAm(gestern), {'Habit'});
      expect(repo().erledigteHeute, isEmpty);
    });
  });

  group('StreakRepository', () {
    StreakRepository streakRepo() => StreakRepository(
          HiveStore(Hive.box<dynamic>(HiveService.boxFortschritt)),
          PlanProgressRepository(
            HiveStore(Hive.box<dynamic>(HiveService.boxFortschritt)),
          ),
        );

    Future<void> hakeAb(int vorTagen) async {
      final box = Hive.box<dynamic>(HiveService.boxFortschritt);
      final tag = DateTime.now().subtract(Duration(days: vorTagen));
      await box.put(PlanProgressRepository.schluessel(tag), ['Habit']);
    }

    test('zaehlt aufeinanderfolgende Tage', () async {
      for (var i = 0; i < 3; i++) {
        await hakeAb(i);
      }
      expect(streakRepo().berechneAktuell(const []), 3);
    });

    test('ein leerer heutiger Tag reisst die Serie nicht ab', () async {
      await hakeAb(1);
      await hakeAb(2);
      expect(streakRepo().berechneAktuell(const []), 2);
    });

    test('eine Luecke ueberbruecken die Joker', () async {
      // Zwei verpasste Tage faengt das Monatskontingent ab – gezaehlt
      // werden weiterhin nur die beiden Tage mit echtem Haken.
      //
      // Dieser Fall darf mit `heute` rechnen: Zwei verpasste Tage werden
      // überbrückt, egal ob sie in einen Monat fallen oder in zwei. Wo das
      // Datum das Ergebnis ändert, stehen unten feste Tage.
      await hakeAb(0);
      await hakeAb(3);
      expect(streakRepo().berechneAktuell(const []), 2);
    });

    test('ein verbrauchter Joker springt nicht zweimal ein', () {
      // **Mit festem Datum, nicht mit `heute`.** Vorher rechnete dieser Test
      // von `DateTime.now()` rückwärts – und fiel damit an jedem Ersten eines
      // Monats um: Die überbrückten Tage lagen dann im Vormonat und
      // verbrauchten dessen Kontingent, während die Zusicherung den laufenden
      // Monat ansah. Die App rechnete richtig, der Test nicht (DECISIONS 92).
      //
      // Geprüft wird die Regel selbst: `serieRechnen` bekommt Start, Tage und
      // Kontingent von außen und kennt kein Heute.
      const geschafft = {'2026-05-15', '2026-05-12'};
      bool erledigt(DateTime tag) =>
          geschafft.contains(PlanProgressRepository.schluessel(tag));

      // Erster Lauf: Die Lücke am 13. und 14. wird überbrückt.
      final erst = serieRechnen(
        start: DateTime(2026, 5, 15),
        geschafft: erledigt,
        jokerTage: const {},
        jokerProMonat: StreakRepository.jokerProMonat,
      );
      expect(erst.laenge, 2);
      expect(erst.neueJoker..sort(), ['2026-05-13', '2026-05-14']);

      // Zweiter Lauf mit denselben Tagen: Sie sind schon gerettet und werden
      // nicht erneut abgerechnet – aber es kommt auch nichts dazu.
      final zweit = serieRechnen(
        start: DateTime(2026, 5, 15),
        geschafft: erledigt,
        jokerTage: const {'2026-05-13', '2026-05-14'},
        jokerProMonat: StreakRepository.jokerProMonat,
      );
      expect(zweit.laenge, 2);
      expect(zweit.neueJoker, isEmpty);

      // Und das Kontingent des Monats ist damit aufgebraucht: Eine zweite
      // Lücke im selben Mai wird nicht mehr überbrückt.
      const mitLuecke = {'2026-05-15', '2026-05-12', '2026-05-10'};
      final dritt = serieRechnen(
        start: DateTime(2026, 5, 15),
        geschafft: (tag) =>
            mitLuecke.contains(PlanProgressRepository.schluessel(tag)),
        jokerTage: const {'2026-05-13', '2026-05-14'},
        jokerProMonat: StreakRepository.jokerProMonat,
      );
      expect(dritt.laenge, 2);
      expect(dritt.neueJoker, isEmpty);
    });

    test('das Kontingent gilt je Kalendermonat, nicht je Lücke', () {
      // Der Fall, der den alten Test umgeworfen hat, jetzt ausdrücklich:
      // eine Lücke über den Monatswechsel. Vier verpasste Tage werden
      // überbrückt, weil zwei davon dem Mai gehören und zwei dem Juni.
      const geschafft = {'2026-06-03', '2026-05-29'};
      final stand = serieRechnen(
        start: DateTime(2026, 6, 3),
        geschafft: (tag) =>
            geschafft.contains(PlanProgressRepository.schluessel(tag)),
        jokerTage: const {},
        jokerProMonat: StreakRepository.jokerProMonat,
      );

      expect(stand.laenge, 2);
      expect(
        stand.neueJoker..sort(),
        ['2026-05-30', '2026-05-31', '2026-06-01', '2026-06-02'],
      );
    });

    test('innerhalb eines Monats ist nach zwei Jokern Schluss', () {
      // Dieselbe Lücke, aber ganz im Juni: Nach zwei geretteten Tagen reißt
      // die Kette.
      const geschafft = {'2026-06-10', '2026-06-05'};
      final stand = serieRechnen(
        start: DateTime(2026, 6, 10),
        geschafft: (tag) =>
            geschafft.contains(PlanProgressRepository.schluessel(tag)),
        jokerTage: const {},
        jokerProMonat: StreakRepository.jokerProMonat,
      );

      expect(stand.laenge, 1);
    });

    test('die Regel hält an jedem Tag des Jahres', () {
      // Der eigentliche Auftrag: Der Test soll nicht davon abhängen, wann er
      // läuft. Statt es zu behaupten, wird es durchgerechnet – 365 Starttage,
      // jedes Mal dieselbe Lücke von zwei Tagen, jedes Mal dasselbe Ergebnis.
      for (var i = 0; i < 365; i += 1) {
        final start = DateTime(2026, 1, 1).add(Duration(days: i));
        final vorher = start.subtract(const Duration(days: 3));
        final geschafft = {
          PlanProgressRepository.schluessel(start),
          PlanProgressRepository.schluessel(vorher),
        };

        final stand = serieRechnen(
          start: start,
          geschafft: (tag) =>
              geschafft.contains(PlanProgressRepository.schluessel(tag)),
          jokerTage: const {},
          jokerProMonat: StreakRepository.jokerProMonat,
        );

        expect(stand.laenge, 2, reason: '$start');
        expect(stand.neueJoker.length, 2, reason: '$start');
      }
    });

    test('am Letzten aufgebraucht, am Ersten wieder zwei', () async {
      // Die Zusage aus DECISIONS 42 in einem Satz – und der Grund, warum der
      // Zähler ein Datum entgegennimmt statt `heute` zu lesen.
      final box = Hive.box<dynamic>(HiveService.boxFortschritt);
      await box.put('streakJokerTage', ['2026-05-30', '2026-05-31']);

      final repo = streakRepo();
      expect(repo.jokerUebrigAm(DateTime(2026, 5, 31)), 0);
      expect(repo.jokerUebrigAm(DateTime(2026, 6, 1)), 2);

      // Und ein einzelner verbrauchter Joker lässt genau einen übrig.
      await box.put('streakJokerTage', ['2026-06-04']);
      expect(streakRepo().jokerUebrigAm(DateTime(2026, 6, 30)), 1);
    });

    test('ohne jeden Haken ist die Serie null', () {
      expect(streakRepo().berechneAktuell(const []), 0);
    });

    test('laden liefert Serie, Rekord und ob heute gesichert ist', () async {
      await hakeAb(0);
      await hakeAb(1);

      final stand = streakRepo().laden(const []);
      expect(stand.aktuell, 2);
      expect(stand.rekord, 2);
      expect(stand.heuteGesichert, isTrue);
      expect(stand.letzterTag, StreakRepository.heute());
    });

    test('heuteGesichert bleibt falsch, solange nichts abgehakt ist',
        () async {
      await hakeAb(1);
      final stand = streakRepo().laden(const []);
      expect(stand.aktuell, 1);
      expect(stand.heuteGesichert, isFalse);
    });

    test('der Rekord ueberlebt das Zuruecksetzen der Serie', () async {
      // Erst eine Serie aufbauen und den Rekord festschreiben.
      for (var i = 1; i <= 4; i++) {
        await hakeAb(i);
      }
      expect(streakRepo().laden(const []).rekord, 4);

      // Danach die Tagesdaten loeschen: die Serie faellt, der Rekord bleibt.
      final box = Hive.box<dynamic>(HiveService.boxFortschritt);
      for (var i = 1; i <= 4; i++) {
        final tag = DateTime.now().subtract(Duration(days: i));
        await box.delete(PlanProgressRepository.schluessel(tag));
      }

      final stand = streakRepo().laden(const []);
      expect(stand.aktuell, 0);
      expect(stand.rekord, 4);
    });

    test('gefeierte Abzeichen werden gemerkt', () async {
      final repo = streakRepo();
      expect(repo.laden(const []).gefeiert, isEmpty);

      await repo.alsGefeiertMerken(Abzeichen.dreiTage);
      expect(repo.laden(const []).gefeiert, {Abzeichen.dreiTage});
    });
  });

  group('OnboardingController', () {
    test('schreibt Antworten sofort in die Box', () {
      final box = HiveStore(Hive.box<dynamic>(HiveService.boxEinstellungen));
      final ctrl = OnboardingController(box);

      ctrl.setAlter(Altersbereich.a25bis34);
      ctrl.setBudget(Budget.mittel);
      ctrl.toggleFokus(Fokusbereich.haut);
      ctrl.abschliessen();

      // Ein frischer Controller liest denselben Stand wieder ein.
      final neu = OnboardingController(box);
      expect(neu.state.alter, Altersbereich.a25bis34);
      expect(neu.state.budget, Budget.mittel);
      expect(neu.state.fokus, {Fokusbereich.haut});
      expect(neu.state.abgeschlossen, isTrue);
    });

    test('zuruecksetzen loescht die Antworten', () {
      final box = HiveStore(Hive.box<dynamic>(HiveService.boxEinstellungen));
      final ctrl = OnboardingController(box);

      ctrl.setZeit(Zeitbudget.lang);
      ctrl.abschliessen();
      ctrl.zuruecksetzen();

      expect(OnboardingController(box).state.abgeschlossen, isFalse);
      expect(OnboardingController(box).state.zeit, isNull);
    });
  });

  group('Alle Daten loeschen', () {
    test('raeumt jede Box leer', () async {
      for (final name in HiveService.alleBoxen) {
        await Hive.box<dynamic>(name).put('x', 'wert');
      }

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(alleDatenLoeschenProvider)();

      for (final name in HiveService.alleBoxen) {
        expect(Hive.box<dynamic>(name).isEmpty, isTrue, reason: name);
      }
    });
  });
}
