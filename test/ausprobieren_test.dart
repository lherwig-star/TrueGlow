import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/cloud/cloud_modell.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/hive_service.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/core/widgets/auswahl_chip.dart';
import 'package:trueglow/features/analysis/logic/analyse_anfrage.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/ausprobieren/logic/ausprobieren_controller.dart';
import 'package:trueglow/features/ausprobieren/models/technik.dart';
import 'package:trueglow/features/ausprobieren/ui/ausprobieren_screen.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/logic/module_controller.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/plan/logic/tagesabschnitt.dart';
import 'package:trueglow/features/result/ui/kapitel_screen.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// „Das will ich ausprobieren" – DECISIONS 79.
///
/// Geprueft wird, was der Schritt zusagt: Er zeigt nur, was zu dieser
/// Analyse passt, er laesst sich ueberspringen, er merkt sich die Wahl, und
/// was er nicht mehr anbietet, verschwindet auch aus der Auswahl.

/// Der Bildschirm allein, mit gesetzter Ausrichtung und Modulauswahl.
Future<ProviderContainer> _schirm(
  WidgetTester tester, {
  required Geschlecht geschlecht,
  required Set<AnalyseModul> module,
  Set<Technik> vorbelegt = const {},
}) async {
  final container = ProviderContainer(overrides: speicherOverrides());
  addTearDown(container.dispose);

  container.read(onboardingControllerProvider.notifier)
      .setGeschlecht(geschlecht);
  for (final modul in module) {
    container.read(moduleControllerProvider.notifier).ergaenzen(modul);
  }
  for (final technik in vorbelegt) {
    container.read(ausprobierenControllerProvider.notifier)
        .umschalten(technik);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: testHuelle(const AusprobierenScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Die Beschriftungen aller Chips auf dem Schirm.
List<String> _chips(WidgetTester tester) => tester
    .widgetList<AuswahlChip>(find.byType(AuswahlChip))
    .map((c) => c.label)
    .toList();

void main() {
  group('Was angeboten wird', () {
    test('nur Techniken zu den gewaehlten Modulen', () {
      final angebot = Technik.angebot(
        {AnalyseModul.basis, AnalyseModul.zaehneLaecheln},
        Ausrichtung.maennlich,
      );

      expect(angebot, contains(Technik.oelziehen));
      expect(angebot, contains(Technik.kopfhautmassage));
      // Gua Sha gehoert ins Haut-Kapitel, und das wurde nicht bestellt.
      expect(angebot, isNot(contains(Technik.guaSha)));
      expect(
        angebot.every((t) => t.modul != AnalyseModul.hautFarbtyp),
        isTrue,
      );
    });

    test('die Ausrichtung entscheidet mit', () {
      final maennlich =
          Technik.angebot(AnalyseModul.values.toSet(), Ausrichtung.maennlich);
      final weiblich =
          Technik.angebot(AnalyseModul.values.toSet(), Ausrichtung.weiblich);
      final neutral =
          Technik.angebot(AnalyseModul.values.toSet(), Ausrichtung.neutral);

      expect(maennlich, contains(Technik.bartbuerste));
      expect(maennlich, isNot(contains(Technik.nagelpflege)));

      expect(weiblich, contains(Technik.nagelpflege));
      expect(weiblich, isNot(contains(Technik.bartbuerste)));

      // „Divers" und „keine Angabe" sind kein Auftrag, etwas wegzulassen –
      // dieselbe Regel wie bei den Modulen.
      expect(neutral, containsAll([Technik.bartbuerste, Technik.nagelpflege]));
    });

    test('jedes waehlbare Modul bringt mindestens vier Techniken mit', () {
      for (final modul in AnalyseModul.bestellbar) {
        final eigene = Technik.values.where((t) => t.modul == modul);
        expect(
          eigene.length,
          greaterThanOrEqualTo(4),
          reason: '${modul.name} hat nur ${eigene.length}',
        );
      }
    });

    test('die Sicherheitsgrenze steht', () {
      // Nichts Invasives, nichts Medizinisches, kein Looksmaxxing mit
      // Verletzungsrisiko (DECISIONS 79). Der Test faengt den Fall ab, dass
      // jemand spaeter „nur schnell" einen Eintrag ergaenzt.
      const verboten = [
        'dermaroller',
        'microneedling',
        'needling',
        'mewing',
        'mastic',
        'kaugummi',
        'kautraining',
        'fasten',
        'diaet',
        'diät',
        'tretinoin',
        'retinol',
        'botox',
        'filler',
      ];

      for (final technik in Technik.values) {
        final name = technik.name.toLowerCase();
        for (final wort in verboten) {
          expect(name.contains(wort), isFalse, reason: technik.name);
        }
      }
    });
  });

  group('Der Bildschirm', () {
    testWidgets('zeigt nur die Techniken der gewaehlten Module',
        (tester) async {
      handyGroesse(tester, hoehe: 3000);
      await _schirm(
        tester,
        geschlecht: Geschlecht.maennlich,
        module: {AnalyseModul.basis, AnalyseModul.zaehneLaecheln},
      );

      final beschriftungen = _chips(tester);

      expect(beschriftungen, contains(texte.technikOelziehen));
      expect(beschriftungen, contains(texte.technikBartbuerste));
      expect(beschriftungen, isNot(contains(texte.technikGuaSha)));
      expect(
        beschriftungen,
        hasLength(
          Technik.angebot(
            {AnalyseModul.basis, AnalyseModul.zaehneLaecheln},
            Ausrichtung.maennlich,
          ).length,
        ),
      );
    });

    testWidgets('alle Chips stehen im selben Raster', (tester) async {
      // Dieselbe Zusage wie bei den Stilrichtungen (DECISIONS 61): eine
      // Form, volle Breite, keiner schert aus.
      handyGroesse(tester, hoehe: 3000);
      await _schirm(
        tester,
        geschlecht: Geschlecht.maennlich,
        module: {AnalyseModul.basis},
      );

      final breiten = tester
          .widgetList<AuswahlChip>(find.byType(AuswahlChip))
          .map((c) => tester.getSize(find.byWidget(c)).width)
          .toSet();

      expect(breiten, hasLength(1));
      expect(breiten.first, closeTo(400 - 2 * AppTheme.gapM, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ein Tipp waehlt aus und schreibt es weg', (tester) async {
      handyGroesse(tester, hoehe: 3000);
      final container = await _schirm(
        tester,
        geschlecht: Geschlecht.maennlich,
        module: {AnalyseModul.basis},
      );

      await tester.tap(find.text(texte.technikKopfhautmassage));
      await tester.pumpAndSettle();

      expect(
        container.read(ausprobierenControllerProvider),
        {Technik.kopfhautmassage},
      );
      // Und der naechste Start faengt nicht wieder bei null an.
      final box = container.read(
        storeProvider(HiveService.boxEinstellungen),
      );
      expect(box.get(CloudModell.keyTechniken), ['kopfhautmassage']);
    });

    testWidgets('zeigt, wie viele gewaehlt sind', (tester) async {
      handyGroesse(tester, hoehe: 3000);
      await _schirm(
        tester,
        geschlecht: Geschlecht.maennlich,
        module: {AnalyseModul.basis},
        vorbelegt: {Technik.kopfhautmassage, Technik.seidenkissen},
      );

      expect(find.text(texte.ausprobierenGewaehlt(2)), findsOneWidget);
    });
  });

  group('Die gemerkte Auswahl', () {
    testWidgets('verliert, was diese Analyse nicht anbietet', (tester) async {
      // Vorbelegt aus einem frueheren Lauf mit Haut-Kapitel; diesmal steht
      // nur die Basis auf der Liste.
      handyGroesse(tester, hoehe: 3000);
      final container = await _schirm(
        tester,
        geschlecht: Geschlecht.maennlich,
        module: {AnalyseModul.basis},
        vorbelegt: {Technik.kopfhautmassage, Technik.guaSha},
      );
      await tester.pumpAndSettle();

      expect(
        container.read(ausprobierenControllerProvider),
        {Technik.kopfhautmassage},
      );
    });

    test('unbekannte Namen aus der Speicherung fallen weg', () {
      expect(
        Technik.ausNamen(['guaSha', 'mewing', 42, null, 'oelziehen']),
        {Technik.guaSha, Technik.oelziehen},
      );
    });
  });

  group('Die Nutzlast', () {
    test('traegt die Namen in Deklarationsreihenfolge', () {
      final anfrage = AnalyseAnfrage.bauen(
        bilder: const {AufnahmeTyp.basisFrontal: 'AAAA'},
        module: {AnalyseModul.basis},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
        sprache: Sprache.deutsch,
        // Absichtlich in der falschen Reihenfolge angeliefert.
        techniken: {Technik.guaSha, Technik.kopfhautmassage},
      );

      expect(anfrage['techniken'], ['kopfhautmassage', 'guaSha']);
    });

    test('ohne Auswahl steht eine leere Liste drin', () {
      final anfrage = AnalyseAnfrage.bauen(
        bilder: const {AufnahmeTyp.basisFrontal: 'AAAA'},
        module: {AnalyseModul.basis},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
        sprache: Sprache.deutsch,
      );

      expect(anfrage['techniken'], isEmpty);
    });
  });

  group('Die Wirkung im Report', () {
    test('eine gewaehlte Technik wird zu Empfehlung, Marke und Aufgabe', () {
      final json = JsonExtractor.extrahiere(
        MockAnalysisService.antwortFuer({AnalyseModul.basis}),
      )!;

      final mit = MockAnalysisService.mitTechniken(
        json,
        {Technik.kopfhautmassage},
      );
      final ergebnis = AnalysisResult.vonApi(
        mit,
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
      );

      final name = texte.technikKopfhautmassage;
      final sektion = ergebnis.kapitel.first.sektionen.first;

      expect(sektion.neu, [name]);
      expect(sektion.zeigtNeu, isTrue);
      expect(sektion.empfehlungen.any((e) => e.contains(name)), isTrue);
      expect(ergebnis.alleHabits.any((h) => h.contains(name)), isTrue);
    });

    test('ohne Auswahl bleibt die Antwort unveraendert', () {
      final json = JsonExtractor.extrahiere(
        MockAnalysisService.antwortFuer({AnalyseModul.basis}),
      )!;

      expect(MockAnalysisService.mitTechniken(json, const {}), same(json));

      final ergebnis = AnalysisResult.vonApi(
        json,
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
      );
      expect(ergebnis.sektionen.every((s) => s.neu.isEmpty), isTrue);
    });

    test('die Marke ueberlebt den Weg durch die Speicherung', () {
      const sektion = Sektion(
        titel: 'Haut',
        einschaetzung: 'Text.',
        empfehlungen: ['Schritt'],
        produkte: [],
        neu: ['Gua Sha'],
      );

      expect(Sektion.fromJson(sektion.toJson()).neu, ['Gua Sha']);

      // Ohne Marke steht das Feld gar nicht erst im Dokument.
      const ohne = Sektion(
        titel: 'Haut',
        einschaetzung: '',
        empfehlungen: [],
        produkte: [],
      );
      expect(ohne.toJson().containsKey('neu'), isFalse);
      expect(Sektion.fromJson(ohne.toJson()).neu, isEmpty);
    });

    testWidgets('der Report zeigt die Marke an der Sektion', (tester) async {
      handyGroesse(tester, hoehe: 2200);

      final analyse = AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
        kapitel: const [
          Kapitel(
            modul: AnalyseModul.hautFarbtyp,
            einleitung: 'Warmer Unterton.',
            sektionen: [
              Sektion(
                titel: 'Haut',
                einschaetzung: 'Ruhiges Hautbild, an den Wangen etwas trocken.',
                empfehlungen: ['Gua Sha: mit Öl, immer nach außen.'],
                produkte: [],
                neu: ['Gua Sha'],
              ),
            ],
          ),
        ],
        plan: const Plan(
          sofort: ['Heute anfangen'],
          dreissigTage: [],
          langfristig: [],
          taeglicheHabits: [],
        ),
      );

      final container = ProviderContainer(overrides: speicherOverrides());
      addTearDown(container.dispose);
      await container.read(analysenProvider.notifier).speichern(analyse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          // Seit DECISIONS 89 steht der Kapitelinhalt hinter einer
          // Kachel; die Marke gehört zur Sektion und damit hierher.
          child: testHuelle(const KapitelScreen(
            analyseId: '1',
            modulName: 'hautFarbtyp',
          )),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('${texte.ergebnisNeuFuerDich} \u00b7 Gua Sha'),
        findsOneWidget,
      );
    });
  });

  group('Eine Wochenaufgabe in der Tagesliste', () {
    const ausloeser = [
      ('Einmal die Woche', 'Once a week'),
      ('Zweimal die Woche', 'Twice a week'),
      ('Dreimal die Woche', 'Three times a week'),
    ];

    test('landet unter Bei Bedarf, nicht mitten im Tag', () {
      for (final (de, en) in ausloeser) {
        for (final wort in [de, en]) {
          expect(
            einordnen('$wort: Gua Sha einbauen').abschnitt,
            Tagesabschnitt.beiBedarf,
            reason: wort,
          );
        }
      }
    });

    test('deutsche und englische Fassung landen gleich', () {
      // Wer die App nach der Analyse umstellt, behaelt seine Aufgaben in der
      // alten Sprache. Sie muessen trotzdem an derselben Stelle stehen.
      for (final (de, en) in ausloeser) {
        final links = einordnen('$de: X');
        final rechts = einordnen('$en: X');

        expect(rechts.abschnitt, links.abschnitt, reason: de);
        expect(rechts.rang, links.rang, reason: de);
      }
    });

    test('und stehen in fester Reihenfolge beieinander', () {
      // Ein unbekannter Ausloeser bekommt Rang 0; die drei Wochen-Ausloeser
      // haben feste Raenge und stehen deshalb immer beieinander und immer in
      // derselben Reihenfolge.
      final situativ = einordnen('Wenn das Verlangen kommt: X');
      final einmal = einordnen('Einmal die Woche: X');
      final dreimal = einordnen('Dreimal die Woche: X');

      expect(situativ.rang, lessThan(einmal.rang));
      expect(einmal.rang, lessThan(dreimal.rang));
    });

    test('die Tagesliste zeigt sie in einem eigenen Abschnitt', () {
      final gruppen = tagesliste(const [
        Kapitel(
          modul: AnalyseModul.hautFarbtyp,
          einleitung: '',
          sektionen: [],
          habits: [
            'Nach dem Aufstehen: Gesicht mit lauwarmem Wasser waschen',
            'Zweimal die Woche: Gua Sha einbauen',
          ],
        ),
      ]);

      expect(gruppen.map((g) => g.abschnitt), [
        Tagesabschnitt.morgens,
        Tagesabschnitt.beiBedarf,
      ]);
      expect(gruppen.last.aufgaben.single.text, contains('Gua Sha'));
    });
  });

  group('Der Platz im Flow', () {
    testWidgets('liegt zwischen der Richtung und der Aufnahme',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: testOverrides(), child: const TrueGlowApp()),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TrueGlowApp)),
      );
      final onboarding = container.read(onboardingControllerProvider.notifier);
      onboarding.setAlter(Altersbereich.a25bis34);
      onboarding.setZustimmung(true);
      onboarding.abschliessen();
      // Schliesst die Altersbestaetigung ein – ohne sie fuehrt der Router
      // vor jedem Schritt des Analyse-Flows auf den Hinweis.
      einwilligungErteilen(container);

      container.read(routerProvider).go(Routes.richtung);
      await tester.pumpAndSettle();

      // „Weiter" auf der Richtung fuehrt hierher und nicht in die Aufnahme.
      await tester.tap(find.text(texte.richtungWeiter));
      await tester.pumpAndSettle();

      expect(find.byType(AusprobierenScreen), findsOneWidget);
      expect(find.text(texte.ausprobierenUeberschrift), findsOneWidget);

      // Und von hier geht es weiter in die Aufnahme – auch beim
      // Ueberspringen.
      await tester.tap(find.text(texte.flowUeberspringen));
      await tester.pumpAndSettle();

      expect(find.byType(AusprobierenScreen), findsNothing);
    });
  });
}
