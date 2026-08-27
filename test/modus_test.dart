import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/logic/analyse_anfrage.dart';
import 'package:trueglow/features/analysis/logic/modus_controller.dart';
import 'package:trueglow/features/analysis/models/analyse_modus.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// Die Moduswahl – der erste Schritt jeder Analyse.
///
/// Der Anlass steht in DECISIONS 56: Die App konnte nur eine Frage
/// beantworten („wie hole ich aus dem, was da ist, das Beste heraus?"), und
/// wer Veränderung wollte, bekam darauf eine Antwort, die ihn festhielt.
///
/// Was hier getestet wird, ist genau die Zusage aus dem Paket: Die Wahl gilt
/// **pro Analyse**, sie fährt bis zum Server mit, und sie bleibt am fertigen
/// Report ablesbar.
Future<ProviderContainer> _appMitDashboard(WidgetTester tester) async {
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

  container.read(routerProvider).go(Routes.home);
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('Der Modus als Wert', () {
    test('unbekanntes faellt auf das bisherige Verhalten zurueck', () {
      // Ein alter Report, ein alter Client, eine kaputte Zeile: Wer den
      // Modus nicht kennt, bekommt genau das, was er bisher bekommen hat.
      expect(AnalyseModus.standard, AnalyseModus.verfeinern);
      expect(AnalyseModus.ausName(null), AnalyseModus.verfeinern);
      expect(AnalyseModus.ausName('gibtsNicht'), AnalyseModus.verfeinern);
      expect(AnalyseModus.ausName('entdecken'), AnalyseModus.entdecken);
    });

    test('jeder Modus hat Titel, Text und Etikett – in beiden Sprachen', () {
      final englisch = lookupL(const Locale('en'));

      for (final modus in AnalyseModus.values) {
        for (final l in [texte, englisch]) {
          expect(modus.titel(l), isNotEmpty, reason: modus.name);
          expect(modus.beschreibung(l), isNotEmpty, reason: modus.name);
          expect(modus.etikett(l), isNotEmpty, reason: modus.name);
        }
        // Das Etikett steht neben einem Datum – es darf die Zeile nicht
        // sprengen.
        expect(modus.etikett(texte).length, lessThanOrEqualTo(14));
        expect(modus.etikett(englisch).length, lessThanOrEqualTo(14));
      }
    });
  });

  group('Die Wahl gilt pro Analyse', () {
    test('sie ueberlebt eine Unterbrechung des Flows', () {
      // Zwischen Moduswahl und Startknopf liegen Module, Richtung und bis zu
      // elf Aufnahmen. Ein Anruf dazwischen darf die Entscheidung nicht
      // kosten – deshalb liegt sie im Speicher und nicht nur im Zustand.
      final speicher = MemoryStore();

      ModusController(speicher).waehlen(AnalyseModus.entdecken);
      expect(ModusController(speicher).state, AnalyseModus.entdecken);
    });

    test('aber ein neuer Durchlauf fragt neu', () {
      // Sonst waere es ein Konto-Setting: Wer einmal einen neuen Look wollte,
      // bekaeme ihn stillschweigend fuer immer.
      final speicher = MemoryStore();
      final ctrl = ModusController(speicher)..waehlen(AnalyseModus.entdecken);

      ctrl.zuruecksetzen();

      expect(ctrl.state, AnalyseModus.verfeinern);
      expect(ModusController(speicher).state, AnalyseModus.verfeinern);
    });
  });

  group('Der Modus faehrt mit', () {
    test('bis in die Nutzlast der Cloud Function', () {
      final nutzlast = AnalyseAnfrage.bauen(
        bilder: const {AufnahmeTyp.basisFrontal: 'abc'},
        module: {AnalyseModul.basis},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
        sprache: Sprache.deutsch,
        modus: AnalyseModus.entdecken,
      );

      expect(nutzlast['modus'], 'entdecken');
    });

    test('ohne Angabe steht das bisherige Verhalten drin', () {
      final nutzlast = AnalyseAnfrage.bauen(
        bilder: const {AufnahmeTyp.basisFrontal: 'abc'},
        module: {AnalyseModul.basis},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
        sprache: Sprache.deutsch,
      );

      expect(nutzlast['modus'], 'verfeinern');
    });

    test('und bleibt am gespeicherten Report haengen', () {
      final original = AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 27),
        kapitel: const [],
        plan: Plan.leer,
        modus: AnalyseModus.entdecken,
      );

      final zurueck = AnalysisResult.fromJson(original.toJson());

      expect(zurueck.modus, AnalyseModus.entdecken);
    });

    test('ein Report von frueher ist der verfeinernde', () {
      // Analysen aus der Zeit vor dem Feature haben kein Feld. Sie sind per
      // Definition „verfeinert" – etwas anderes gab es damals nicht.
      final alt = AnalysisResult.fromJson({
        'id': '1',
        'erstelltAm': '2026-08-01T10:00:00.000',
        'kapitel': const [],
        'plan': const {},
      });

      expect(alt.modus, AnalyseModus.verfeinern);
    });
  });

  group('Der Flow', () {
    testWidgets('eine neue Analyse beginnt mit der Moduswahl', (tester) async {
      handyGroesse(tester, hoehe: 2000);
      final container = await _appMitDashboard(tester);

      container.read(routerProvider).push(Routes.modus);
      await tester.pumpAndSettle();

      expect(find.text(texte.modusUeberschrift), findsOneWidget);
      // Beide Karten stehen da, und es gibt kein Ueberspringen: Die Frage
      // ist zu grundlegend, um sie im Vorbeigehen zu setzen.
      expect(find.text(texte.modusVerfeinernTitel), findsOneWidget);
      expect(find.text(texte.modusEntdeckenTitel), findsOneWidget);
      expect(find.text(texte.flowUeberspringen), findsNothing);
    });

    testWidgets('ein Tipp auf die Karte setzt den Modus', (tester) async {
      handyGroesse(tester, hoehe: 2000);
      final container = await _appMitDashboard(tester);

      container.read(routerProvider).push(Routes.modus);
      await tester.pumpAndSettle();

      expect(container.read(modusControllerProvider), AnalyseModus.verfeinern);

      await tester.tap(find.text(texte.modusEntdeckenTitel));
      await tester.pumpAndSettle();

      expect(container.read(modusControllerProvider), AnalyseModus.entdecken);
    });

    testWidgets('und der Weiter-Knopf fuehrt in die Modulauswahl',
        (tester) async {
      handyGroesse(tester, hoehe: 2000);
      final container = await _appMitDashboard(tester);

      container.read(routerProvider).push(Routes.modus);
      await tester.pumpAndSettle();

      await tester.tap(find.text(texte.modusWeiter));
      await tester.pumpAndSettle();

      expect(find.text(texte.moduleUeberschrift), findsOneWidget);
    });
  });

  group('Der Verlauf zeigt, welche Frage beantwortet wurde', () {
    testWidgets('an jedem Eintrag steht ein Etikett', (tester) async {
      handyGroesse(tester, hoehe: 2000);
      final container = await _appMitDashboard(tester);

      final repo = container.read(analysenProvider.notifier);
      await repo.speichern(_report('a', AnalyseModus.entdecken));
      await repo.speichern(_report('b', AnalyseModus.verfeinern));

      container.read(routerProvider).push(Routes.history);
      await tester.pumpAndSettle();

      // Beide, nicht nur der neue: Nur eines der beiden zu kennzeichnen
      // hiesse, das andere zur Norm zu erklaeren.
      expect(find.text(AnalyseModus.entdecken.etikett(texte)), findsOneWidget);
      expect(find.text(AnalyseModus.verfeinern.etikett(texte)), findsOneWidget);
    });
  });
}

AnalysisResult _report(String id, AnalyseModus modus) => AnalysisResult(
      id: id,
      erstelltAm: DateTime(2026, 8, 27),
      kapitel: const [
        Kapitel(
          modul: AnalyseModul.basis,
          einleitung: 'Ovale Grundform.',
          sektionen: [],
          habits: [],
        ),
      ],
      plan: const Plan(
        sofort: ['Heute'],
        dreissigTage: [],
        langfristig: [],
        taeglicheHabits: [],
      ),
      modus: modus,
    );
