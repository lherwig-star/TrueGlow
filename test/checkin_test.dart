import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/logic/analysis_service.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/capture/logic/image_quality_service.dart';
import 'package:trueglow/features/checkin/logic/checkin_controller.dart';
import 'package:trueglow/features/checkin/logic/checkin_flow.dart';
import 'package:trueglow/features/checkin/logic/checkin_anfrage.dart';
import 'package:trueglow/features/checkin/logic/checkin_service.dart';
import 'package:trueglow/features/checkin/logic/checkin_zeitplan.dart';
import 'package:trueglow/features/checkin/logic/plan_anpassung.dart';
import 'package:trueglow/features/checkin/logic/wirkungsfragen.dart';
import 'package:trueglow/features/checkin/models/checkin.dart';
import 'package:trueglow/features/checkin/models/checkin_auswertung.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/streak/logic/streak_repository.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// Ein Report mit zwei Tagesaufgaben – genug, um Ratings und Anpassungen zu
/// pruefen, wenig genug fuer ein Testfenster.
AnalysisResult _analyse({
  List<String> basisHabits = const ['Haare stylen', 'Bart ölen'],
  List<String> hautHabits = const ['Sonnenschutz auftragen'],
  Set<AnalyseModul> module = const {AnalyseModul.basis},
}) {
  return AnalysisResult(
    id: 'plan1',
    erstelltAm: DateTime(2026, 8, 1),
    kapitel: [
      if (module.contains(AnalyseModul.basis))
        Kapitel(
          modul: AnalyseModul.basis,
          einleitung: 'Ovale Grundform.',
          sektionen: const [],
          habits: basisHabits,
        ),
      if (module.contains(AnalyseModul.hautFarbtyp))
        Kapitel(
          modul: AnalyseModul.hautFarbtyp,
          einleitung: 'Mischhaut.',
          sektionen: const [],
          habits: hautHabits,
        ),
    ],
    plan: const Plan(
      sofort: ['a'],
      dreissigTage: [],
      langfristig: [],
      taeglicheHabits: [],
    ),
  );
}

Checkin _checkin({
  CheckinTyp typ = CheckinTyp.alltag,
  int id = 0,
  DateTime? faellig,
}) =>
    Checkin(id: id, typ: typ, faelligAm: faellig ?? DateTime(2026, 8, 8));

/// Die erste gespeicherte Analyse schaltet ein Abzeichen frei – der Jubel
/// liegt dann ueber dem Dashboard und muss erst weg.
Future<void> _jubelWegtippen(WidgetTester tester) async {
  final weiter = find.text('Weiter so');
  if (weiter.evaluate().isEmpty) return;
  await tester.tap(weiter);
  await tester.pumpAndSettle();
}

void main() {
  group('Zeitplan', () {
    test('die Reihe ist Tag 7, 14, 30 und dann alle 30 Tage', () {
      expect(CheckinZeitplan.typFuer(0), CheckinTyp.alltag);
      expect(CheckinZeitplan.typFuer(1), CheckinTyp.zwischen);
      expect(CheckinZeitplan.typFuer(2), CheckinTyp.wirkung);
      expect(CheckinZeitplan.typFuer(7), CheckinTyp.wirkung);

      expect(CheckinZeitplan.abstandTage(0), 7);
      expect(CheckinZeitplan.abstandTage(1), 7);
      expect(CheckinZeitplan.abstandTage(2), 16);
      expect(CheckinZeitplan.abstandTage(3), 30);
    });

    test('der erste Termin haengt am Planstart', () {
      final start = DateTime(2026, 8, 1, 18, 30);

      expect(
        CheckinZeitplan.termin(index: 0, planStart: start),
        DateTime(2026, 8, 8),
      );
    });

    test('spaeter erledigt heisst spaeter dran – Check-ins stapeln sich nie',
        () {
      final start = DateTime(2026, 8, 1);

      // Tag 7 wird erst am Tag 20 erledigt.
      final zweiter = CheckinZeitplan.termin(
        index: 1,
        planStart: start,
        zuletztErledigt: DateTime(2026, 8, 20),
      );

      expect(zweiter, DateTime(2026, 8, 27));

      // Und der dritte kommt 16 Tage nach dem zweiten, nicht am Tag 30.
      expect(
        CheckinZeitplan.termin(
          index: 2,
          planStart: start,
          zuletztErledigt: DateTime(2026, 8, 27),
        ),
        DateTime(2026, 9, 12),
      );
    });

    test('faellig ist der ganze Tag, nicht erst die Uhrzeit', () {
      final termin = DateTime(2026, 8, 8, 23, 59);

      expect(
        CheckinZeitplan.istFaellig(termin, jetzt: DateTime(2026, 8, 8, 0, 5)),
        isTrue,
      );
      expect(
        CheckinZeitplan.istFaellig(termin, jetzt: DateTime(2026, 8, 7, 23, 59)),
        isFalse,
      );
      // Ein verpasster Check-in bleibt faellig.
      expect(
        CheckinZeitplan.istFaellig(termin, jetzt: DateTime(2026, 9, 30)),
        isTrue,
      );
    });
  });

  group('Checkin (Modell)', () {
    test('ueberlebt den Weg durch JSON', () {
      final original = _checkin(typ: CheckinTyp.wirkung, id: 2)
          .mitBewertung('Bart ölen', HabitBewertung.passtNicht)
          .mitGrund('Bart ölen', PasstNichtGrund.zeit, notiz: 'morgens hektisch')
          .mitWirkung(
            const WirkungsFrage(id: 'hautErgebnis'),
            WirkungsAntwort.besser,
            texte,
          )
          .copyWith(erledigtAm: DateTime(2026, 9, 1), fazit: 'Läuft.');

      final zurueck = Checkin.fromJson(original.toJson())!;

      expect(zurueck.id, 2);
      expect(zurueck.typ, CheckinTyp.wirkung);
      expect(zurueck.erledigtAm, DateTime(2026, 9, 1));
      expect(zurueck.feedbackZu('Bart ölen')?.grund, PasstNichtGrund.zeit);
      expect(zurueck.feedbackZu('Bart ölen')?.notiz, 'morgens hektisch');
      expect(zurueck.antwortZu('hautErgebnis'), WirkungsAntwort.besser);
      expect(zurueck.fazit, 'Läuft.');
    });

    test('ein Grund verfaellt, sobald die Bewertung wieder passt', () {
      final mitGrund = _checkin()
          .mitBewertung('Haare stylen', HabitBewertung.passtNicht)
          .mitGrund('Haare stylen', PasstNichtGrund.teuer);

      expect(mitGrund.feedbackZu('Haare stylen')?.grund, PasstNichtGrund.teuer);

      final umbewertet =
          mitGrund.mitBewertung('Haare stylen', HabitBewertung.laeuftGut);

      expect(umbewertet.feedbackZu('Haare stylen')?.grund, isNull);
    });

    test('nachzufragen sind die Wackelkandidaten', () {
      final checkin = _checkin()
          .mitBewertung('Haare stylen', HabitBewertung.laeuftGut)
          .mitBewertung('Bart ölen', HabitBewertung.gehtSo)
          .mitBewertung('Sonnenschutz auftragen', HabitBewertung.passtNicht);

      expect(checkin.nachzufragen, {'Bart ölen', 'Sonnenschutz auftragen'});
    });

    test('vollstaendig ist der Check-in erst mit jeder Bewertung', () {
      const habits = ['Haare stylen', 'Bart ölen'];
      final halb = _checkin().mitBewertung('Haare stylen', HabitBewertung.gehtSo);

      expect(halb.habitsVollstaendig(habits), isFalse);
      expect(
        halb
            .mitBewertung('Bart ölen', HabitBewertung.laeuftGut)
            .habitsVollstaendig(habits),
        isTrue,
      );
    });
  });

  group('Wirkungsfragen', () {
    test('Tag 7 fragt nicht nach Ergebnissen', () {
      expect(
        Wirkungsfragen.fuer(CheckinTyp.alltag, {AnalyseModul.hautFarbtyp}),
        isEmpty,
      );
    });

    test('Tag 14 stellt nur weiche Fragen zu Schnell-Effekten', () {
      final fragen = Wirkungsfragen.fuer(
        CheckinTyp.zwischen,
        {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );

      expect(fragen, isNotEmpty);
      expect(fragen.length, lessThanOrEqualTo(Wirkungsfragen.maxFragen));
      // Keine Ergebnisfrage – die kommen erst beim Wirkungs-Check.
      expect(fragen.map((f) => f.id), isNot(contains('hautErgebnis')));
      expect(fragen.map((f) => f.id), contains('hautGefuehl'));
    });

    test('Tag 30 fragt pro gewaehltem Modul nach dem Ergebnis', () {
      final fragen = Wirkungsfragen.fuer(
        CheckinTyp.wirkung,
        {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );

      expect(fragen.map((f) => f.id), containsAll(['basisErgebnis', 'hautErgebnis']));
      // Nichts zu Modulen, die gar nicht analysiert wurden.
      expect(fragen.map((f) => f.id), isNot(contains('stilErgebnis')));
    });

    test('der Erwartungstext richtet sich nach den Modulen', () {
      expect(
        Wirkungsfragen.erwartung({AnalyseModul.hautFarbtyp}, texte),
        contains('Woche 4–6'),
      );
      expect(
        Wirkungsfragen.erwartung({AnalyseModul.basis}, texte),
        contains('Zentimeter'),
      );
    });
  });

  group('Ablauf', () {
    List<CheckinSchritt> flow(
      CheckinTyp typ, {
      List<String> habits = const ['a'],
      bool mitFoto = false,
      Checkin? checkin,
    }) =>
        baueCheckinFlow(
          checkin: checkin ?? _checkin(typ: typ),
          habits: habits,
          fragen: Wirkungsfragen.fuer(typ, {AnalyseModul.basis}),
          erwartung: Wirkungsfragen.erwartung({AnalyseModul.basis}, texte),
          fotoMoeglich: mitFoto,
        );

    test('Tag 7: Intro, Ratings, Abschluss – sonst nichts', () {
      final schritte = flow(CheckinTyp.alltag);

      expect(schritte.map((s) => s.runtimeType), [
        IntroSchritt,
        HabitsSchritt,
        AbschlussSchritt,
      ]);
    });

    test('Tag 14 bringt Wirkungsfragen und den Erwartungshinweis mit', () {
      final schritte = flow(CheckinTyp.zwischen);

      expect(schritte.whereType<WirkungSchritt>(), hasLength(1));
      expect(schritte.whereType<ErwartungSchritt>(), hasLength(1));
      // Der Hinweis steht nach den Fragen.
      expect(
        schritte.indexWhere((s) => s is ErwartungSchritt),
        greaterThan(schritte.indexWhere((s) => s is WirkungSchritt)),
      );
    });

    test('der Vergleich erscheint erst mit Foto', () {
      final ohne = flow(CheckinTyp.wirkung, mitFoto: true);
      expect(ohne.whereType<VergleichSchritt>(), isEmpty);

      final mit = flow(
        CheckinTyp.wirkung,
        mitFoto: true,
        checkin: _checkin(typ: CheckinTyp.wirkung)
            .copyWith(fortschrittsfoto: '/tmp/neu.jpg'),
      );
      expect(mit.whereType<VergleichSchritt>(), hasLength(1));
    });

    test('ein leerer Rating-Schritt entfaellt', () {
      expect(
        flow(CheckinTyp.zwischen, habits: const []).whereType<HabitsSchritt>(),
        isEmpty,
      );
    });

    test('weiter geht es erst, wenn der Schritt beantwortet ist', () {
      const schritt = HabitsSchritt(['Haare stylen']);
      final leer = _checkin();

      expect(schrittErfuellt(schritt, leer), isFalse);
      expect(
        schrittErfuellt(
          schritt,
          leer.mitBewertung('Haare stylen', HabitBewertung.gehtSo),
        ),
        isTrue,
      );
      // Das Foto ist ausdruecklich optional.
      expect(schrittErfuellt(const FotoSchritt(), leer), isTrue);
    });
  });

  group('CheckinController', () {
    CheckinController bauen(KeyValueStore store) =>
        CheckinController(store, ImageQualityService());

    test('der Zyklus startet einmal und nicht bei jedem Aufruf', () {
      final store = MemoryStore();
      final ctrl = bauen(store);

      ctrl.planSicherstellen(DateTime(2026, 8, 1));
      final termin = ctrl.state.naechsterTermin;

      ctrl.planSicherstellen(DateTime(2026, 9, 1));

      expect(ctrl.state.planStart, DateTime(2026, 8, 1));
      expect(ctrl.state.naechsterTermin, termin);
    });

    test('der Zwischenstand ueberlebt einen Neustart', () {
      final store = MemoryStore();
      final ctrl = bauen(store);

      ctrl.planSicherstellen(DateTime(2026, 8, 1));
      ctrl.entwurfSichern(
        _checkin().mitBewertung('Bart ölen', HabitBewertung.gehtSo),
      );

      final frisch = bauen(store);

      expect(frisch.state.entwurf, isNotNull);
      expect(
        frisch.state.entwurf!.feedbackZu('Bart ölen')?.bewertung,
        HabitBewertung.gehtSo,
      );
    });

    test('abschliessen legt in die Historie und plant den naechsten Termin',
        () {
      final store = MemoryStore();
      final ctrl = bauen(store);

      ctrl.planSicherstellen(DateTime(2026, 8, 1));
      ctrl.entwurfSichern(_checkin());
      ctrl.abschliessen(
        _checkin().copyWith(erledigtAm: DateTime(2026, 8, 10)),
      );

      expect(ctrl.state.historie, hasLength(1));
      expect(ctrl.state.entwurf, isNull);
      expect(ctrl.state.naechsterIndex, 1);
      expect(ctrl.state.naechsterTyp, CheckinTyp.zwischen);
      // 7 Tage nach dem Abschluss, nicht 14 Tage nach dem Start.
      expect(ctrl.state.naechsterTermin, DateTime(2026, 8, 17));
    });

    test('faellig ist erst ab dem Termin', () {
      final store = MemoryStore();
      final ctrl = bauen(store);

      ctrl.planSicherstellen(DateTime.now().subtract(const Duration(days: 3)));
      expect(ctrl.state.faellig(), isFalse);
      expect(ctrl.faelligerCheckin(), isNull);

      ctrl.neuBeginnen(DateTime.now().subtract(const Duration(days: 8)));
      expect(ctrl.state.faellig(), isTrue);
      expect(ctrl.faelligerCheckin()?.typ, CheckinTyp.alltag);
    });
  });

  group('Plan-Anpassung', () {
    test('ersetzt nur den genannten Habit und laesst den Rest stehen', () {
      final angepasst = planAnwenden(_analyse(), const [
        HabitAnpassung(
          modul: AnalyseModul.basis,
          alt: 'Bart ölen',
          neu: 'Bart ölen – 30 Sekunden',
        ),
      ]);

      expect(angepasst.ergebnis.kapitel.single.habits, [
        'Haare stylen',
        'Bart ölen – 30 Sekunden',
      ]);
      expect(angepasst.neueHabits, {'Bart ölen – 30 Sekunden'});
    });

    test('ein erfundener Wortlaut aendert nichts', () {
      final angepasst = planAnwenden(_analyse(), const [
        HabitAnpassung(
          modul: AnalyseModul.basis,
          alt: 'Gibt es gar nicht',
          neu: 'Neuer Habit',
        ),
      ]);

      expect(angepasst.ergebnis.kapitel.single.habits, [
        'Haare stylen',
        'Bart ölen',
      ]);
      expect(angepasst.neueHabits, isEmpty);
    });

    test('Neuzugang und Streichung funktionieren', () {
      final angepasst = planAnwenden(_analyse(), const [
        HabitAnpassung(
          modul: AnalyseModul.basis,
          alt: '',
          neu: 'Abends Kopfhaut massieren',
        ),
        HabitAnpassung(
          modul: AnalyseModul.basis,
          alt: 'Haare stylen',
          neu: '',
        ),
      ]);

      expect(angepasst.ergebnis.kapitel.single.habits, [
        'Bart ölen',
        'Abends Kopfhaut massieren',
      ]);
    });

    test('andere Kapitel bleiben unberuehrt', () {
      final vorher = _analyse(
        module: {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );

      final angepasst = planAnwenden(vorher, const [
        HabitAnpassung(
          modul: AnalyseModul.basis,
          alt: 'Bart ölen',
          neu: 'Bart kämmen',
        ),
      ]);

      final haut = angepasst.ergebnis.kapitel
          .firstWhere((k) => k.modul == AnalyseModul.hautFarbtyp);
      expect(haut.habits, ['Sonnenschutz auftragen']);
      expect(angepasst.ergebnis.id, vorher.id);
      expect(angepasst.ergebnis.plan.sofort, vorher.plan.sofort);
    });
  });

  group('Auswertung', () {
    test('der Mock passt nur an, was bemaengelt wurde', () async {
      final checkin = _checkin()
          .mitBewertung('Haare stylen', HabitBewertung.laeuftGut)
          .mitBewertung('Bart ölen', HabitBewertung.passtNicht)
          .mitGrund('Bart ölen', PasstNichtGrund.zeit);

      final auswertung = await const MockCheckinService().auswerten(
        checkin: checkin,
        analyse: _analyse(),
        historie: const [],
        sprache: Sprache.deutsch,
      );

      expect(auswertung.anpassungen, hasLength(1));
      expect(auswertung.anpassungen.single.alt, 'Bart ölen');
      expect(auswertung.anpassungen.single.neu, contains('30 Sekunden'));
      // Kein Fazit ohne Wirkungs-Check.
      expect(auswertung.fazit, isEmpty);
    });

    test('laeuft alles rund, bleibt der Plan stehen', () async {
      final checkin = _checkin()
          .mitBewertung('Haare stylen', HabitBewertung.laeuftGut)
          .mitBewertung('Bart ölen', HabitBewertung.gehtSo);

      final auswertung = await const MockCheckinService().auswerten(
        checkin: checkin,
        analyse: _analyse(),
        historie: const [],
        sprache: Sprache.deutsch,
      );

      expect(auswertung.aendertPlan, isFalse);
      expect(auswertung.zusammenfassung, isNotEmpty);
    });

    test('die Antwort der KI wird defensiv gelesen', () {
      final auswertung = CheckinAuswertung.fromJson({
        'zusammenfassung': 'Wir kürzen zwei Aufgaben.',
        'anpassungen': [
          {'modul': 'basis', 'alt': 'a', 'neu': 'b'},
          {'modul': 'gibtsNicht', 'alt': 'x', 'neu': 'y'},
          {'modul': 'basis', 'alt': '', 'neu': ''},
        ],
      });

      expect(auswertung.anpassungen, hasLength(1));
      expect(auswertung.anpassungen.single.modul, AnalyseModul.basis);
    });
  });

  // Der Prompt entsteht seit dem Proxy-Umbau in der Cloud Function
  // (functions/src/checkin_prompt.ts, geprueft in functions/test/prompt.test.ts).
  // Hier bleibt die Frage, was der Client ueberhaupt hochlaedt.
  group('Anfrage an die Function', () {
    test('enthaelt Plan, Antworten und Gruende', () {
      final checkin = _checkin()
          .mitBewertung('Bart ölen', HabitBewertung.passtNicht)
          .mitGrund('Bart ölen', PasstNichtGrund.vergessen);

      final anfrage = CheckinAnfrage.bauen(
        checkin: checkin,
        analyse: _analyse(),
        historie: const [],
        sprache: Sprache.deutsch,
      );

      expect(anfrage['plan'], [
        {
          'modul': 'basis',
          'habits': ['Haare stylen', 'Bart ölen'],
        },
      ]);
      expect((anfrage['checkin'] as Map)['typ'], 'alltag');
      expect((anfrage['checkin'] as Map)['habits'], [
        {
          'habit': 'Bart ölen',
          'bewertung': 'passtNicht',
          'grund': 'vergessen',
          'notiz': '',
        },
      ]);
    });

    test('frueher Bemaengeltes geht als Historie mit', () {
      final alt = _checkin()
          .mitBewertung('Bart ölen', HabitBewertung.passtNicht)
          .mitGrund('Bart ölen', PasstNichtGrund.teuer)
          .copyWith(erledigtAm: DateTime(2026, 8, 8));

      final anfrage = CheckinAnfrage.bauen(
        checkin: _checkin(typ: CheckinTyp.zwischen, id: 1),
        analyse: _analyse(),
        historie: [alt],
        sprache: Sprache.deutsch,
      );

      expect(anfrage['historie'], [
        {
          'datum': DateTime(2026, 8, 8).toIso8601String(),
          'typ': 'alltag',
          'probleme': [
            {'habit': 'Bart ölen', 'grund': 'teuer'},
          ],
        },
      ]);
    });

    test('der Pfad des Fortschrittsfotos bleibt auf dem Geraet', () {
      final checkin = _checkin(typ: CheckinTyp.wirkung)
          .copyWith(fortschrittsfoto: '/daten/glowup_fotos/fortschritt0.jpg');

      final anfrage = CheckinAnfrage.bauen(
        checkin: checkin,
        analyse: _analyse(),
        historie: const [],
        sprache: Sprache.deutsch,
        bilder: const ['AAAA', 'BBBB'],
      );

      // Das Bild geht als base64 mit, sein Speicherort nicht.
      expect(jsonEncode(anfrage), isNot(contains('glowup_fotos')));
      expect(anfrage['bilder'], ['AAAA', 'BBBB']);
    });
  });

  group('Im Zusammenspiel', () {
    testWidgets('faelliger Check-in fuehrt vom Dashboard bis zum neuen Plan',
        (tester) async {
      handyGroesse(tester, hoehe: 3200);

      await tester.pumpWidget(
        ProviderScope(overrides: testOverrides(), child: const TrueGlowApp()),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TrueGlowApp)),
      );

      final onboarding = container.read(onboardingControllerProvider.notifier);
      onboarding.setAlter(Altersbereich.a25bis34);
      onboarding.setBudget(Budget.mittel);
      onboarding.setZeit(Zeitbudget.mittel);
      onboarding.setZustimmung(true);
      onboarding.abschliessen();
      einwilligungErteilen(container);

      await container.read(analysenProvider.notifier).speichern(_analyse());

      // Plan laeuft seit acht Tagen: Tag 7 ist faellig.
      container
          .read(checkinControllerProvider.notifier)
          .neuBeginnen(DateTime.now().subtract(const Duration(days: 8)));

      container.read(routerProvider).go(Routes.home);
      await tester.pumpAndSettle();
      await _jubelWegtippen(tester);

      // Die Karte steht auf der Startseite.
      expect(find.text(texte.checkinKarteTitel), findsOneWidget);
      await tester.tap(find.text(texte.checkinStarten));
      await tester.pumpAndSettle();

      // Intro -> Ratings.
      await tester.tap(find.text('Los geht es'));
      await tester.pumpAndSettle();

      expect(find.text(texte.checkinHabitsTitel), findsOneWidget);
      // Ohne Bewertung bleibt "Weiter" gesperrt.
      final weiter = find.widgetWithText(FilledButton, texte.weiter);
      expect(tester.widget<FilledButton>(weiter).onPressed, isNull);

      await tester.tap(find.text(HabitBewertung.laeuftGut.label(texte)).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(HabitBewertung.passtNicht.label(texte)).last);
      await tester.pumpAndSettle();

      // Die Nachfrage klappt direkt unter dem Habit auf.
      expect(find.text(PasstNichtGrund.zeit.label(texte)), findsOneWidget);
      await tester.tap(find.text(PasstNichtGrund.zeit.label(texte)));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, texte.weiter));
      await tester.pumpAndSettle();

      // pumpAndSettle spult die Wartezeit des Mock-Service mit vor.
      await tester.pumpAndSettle(AnalysisConfig.mockDauer);

      expect(find.text(texte.checkinDankeTitel), findsOneWidget);
      expect(find.textContaining('30 Sekunden'), findsWidgets);

      await tester.tap(find.text(texte.checkinBestaetigen));
      await tester.pumpAndSettle();

      // Der Plan traegt die Anpassung, der Rest ist unveraendert.
      final habits = container.read(aktuelleAnalyseProvider)!.alleHabits;
      expect(habits, contains('Haare stylen'));
      expect(habits.any((h) => h.contains('30 Sekunden')), isTrue);
      expect(habits, isNot(contains('Bart ölen')));

      // Historie, Folgetermin, Streak.
      final zustand = container.read(checkinControllerProvider);
      expect(zustand.historie, hasLength(1));
      expect(zustand.entwurf, isNull);
      expect(zustand.naechsterTyp, CheckinTyp.zwischen);
      expect(zustand.faellig(), isFalse);

      expect(
        container.read(planFortschrittProvider).erledigt,
        contains(PlanProgressRepository.checkinMarker),
      );
      expect(container.read(streakProvider).aktuell, 1);

      // Angepasste Aufgaben sind in der Checkliste markiert.
      expect(find.text('Neu ab heute'), findsWidgets);
    });

    testWidgets('ohne faelligen Check-in zeigt das Dashboard den Termin an',
        (tester) async {
      handyGroesse(tester, hoehe: 2600);

      await tester.pumpWidget(
        ProviderScope(overrides: testOverrides(), child: const TrueGlowApp()),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TrueGlowApp)),
      );

      final onboarding = container.read(onboardingControllerProvider.notifier);
      onboarding.setAlter(Altersbereich.a25bis34);
      onboarding.setBudget(Budget.mittel);
      onboarding.setZeit(Zeitbudget.mittel);
      onboarding.setZustimmung(true);
      onboarding.abschliessen();
      einwilligungErteilen(container);

      await container.read(analysenProvider.notifier).speichern(_analyse());
      container
          .read(checkinControllerProvider.notifier)
          .neuBeginnen(DateTime.now().subtract(const Duration(days: 2)));

      container.read(routerProvider).go(Routes.home);
      await tester.pumpAndSettle();
      await _jubelWegtippen(tester);

      expect(find.text(texte.checkinKarteTitel), findsNothing);
      expect(find.textContaining(texte.checkinNaechster), findsOneWidget);
      expect(find.textContaining('in 5 Tagen'), findsOneWidget);
    });
  });
}
