import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/modules/logic/module_controller.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// Die Schwerpunkte aus dem Onboarding – DECISIONS 60.
///
/// Vorher bewirkte die Frage „Worauf willst du dich konzentrieren?" genau
/// eine Sache: eine Zeile im Analyse-Prompt. Auf dem Weg dorthin stellte die
/// Modul-Auswahl dieselbe Frage ein zweites Mal, nur ausführlicher — und der
/// Nutzer musste zweimal antworten.
///
/// Jetzt wählen die Schwerpunkte die passenden Module vor. Was hier geprüft
/// wird, ist beides: dass die Vorauswahl ankommt, und dass sie eine
/// Vorauswahl bleibt und keine Festlegung.
Future<ProviderContainer> _appMitDashboard(
  WidgetTester tester, {
  Set<Fokusbereich> fokus = const {},
}) async {
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
  for (final f in fokus) {
    onboarding.toggleFokus(f);
  }
  onboarding.setZustimmung(true);
  onboarding.abschliessen();
  einwilligungErteilen(container);

  container.read(routerProvider).go(Routes.home);
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('Jeder Schwerpunkt weiss, wohin er gehoert', () {
    test('die Zuordnung ist vollstaendig und eindeutig', () {
      expect(Fokusbereich.haut.modul, AnalyseModul.hautFarbtyp);
      expect(Fokusbereich.style.modul, AnalyseModul.stilKleiderschrank);
      expect(Fokusbereich.fitness.modul, AnalyseModul.figurPassform);

      // Haare und Bart gehen in der Basis auf. Die ist immer dabei, hier
      // gibt es also nichts vorzuwaehlen – die Wirkung liegt allein in der
      // Gewichtung im Prompt.
      expect(Fokusbereich.haare.modul, isNull);
      expect(Fokusbereich.bart.modul, isNull);
    });

    test('kein Schwerpunkt zeigt auf die Basis oder das Zielkapitel', () {
      // Die Basis ist nicht abwaehlbar, das Zielkapitel bestellt niemand.
      // Ein Schwerpunkt, der dorthin zeigt, waere eine Vorauswahl ohne
      // Wirkung.
      for (final f in Fokusbereich.values) {
        expect(f.modul?.istBasis, isNot(true), reason: f.name);
        expect(f.modul, isNot(AnalyseModul.persoenlicheZiele), reason: f.name);
      }
    });

    test('die Ausrichtung entscheidet mit', () {
      // Was im aktuellen Modus gar nicht zur Wahl steht, wird auch nicht
      // vorausgewaehlt.
      final maennlich = Fokusbereich.moduleFuer(
        {Fokusbereich.haut, Fokusbereich.style},
        Ausrichtung.maennlich,
      );
      expect(maennlich, {
        AnalyseModul.hautFarbtyp,
        AnalyseModul.stilKleiderschrank,
      });
    });

    test('Haare und Bart waehlen nichts vor', () {
      expect(
        Fokusbereich.moduleFuer(
          {Fokusbereich.haare, Fokusbereich.bart},
          Ausrichtung.maennlich,
        ),
        isEmpty,
      );
    });
  });

  group('Der Controller nimmt die Vorauswahl an', () {
    test('vorbereiten setzt zurueck und waehlt vor', () {
      final speicher = MemoryStore();
      final ctrl = ModuleController(speicher)
        ..umschalten(AnalyseModul.zaehneLaecheln);

      ctrl.vorbereiten({AnalyseModul.hautFarbtyp});

      // Die Basis ist immer dabei, das Alte ist weg, das Neue ist da.
      expect(ctrl.state.module, {
        AnalyseModul.basis,
        AnalyseModul.hautFarbtyp,
      });
      // Und es ueberlebt den Neustart wie jede andere Auswahl auch.
      expect(ModuleController(speicher).state.module, ctrl.state.module);
    });

    test('ohne Schwerpunkte bleibt es bei der Basis', () {
      final ctrl = ModuleController(MemoryStore())
        ..umschalten(AnalyseModul.zaehneLaecheln);

      ctrl.vorbereiten(const {});

      expect(ctrl.state.module, {AnalyseModul.basis});
    });
  });

  group('Im Flow', () {
    testWidgets('eine neue Analyse startet mit den Schwerpunkten',
        (tester) async {
      handyGroesse(tester, hoehe: 2400);
      final container = await _appMitDashboard(
        tester,
        fokus: {Fokusbereich.haut, Fokusbereich.style},
      );

      final knopf = find.text(texte.homeAnalyseStarten);
      await tester.ensureVisible(knopf);
      await tester.pumpAndSettle();
      await tester.tap(knopf);
      await tester.pumpAndSettle();

      expect(
        container.read(moduleControllerProvider).module,
        {
          AnalyseModul.basis,
          AnalyseModul.hautFarbtyp,
          AnalyseModul.stilKleiderschrank,
        },
      );
    });

    testWidgets('die Modulseite sagt, woher die Haken kommen', (tester) async {
      handyGroesse(tester, hoehe: 2600);
      final container = await _appMitDashboard(
        tester,
        fokus: {Fokusbereich.haut},
      );

      container.read(moduleControllerProvider.notifier).vorbereiten(
        {AnalyseModul.hautFarbtyp},
      );
      container.read(routerProvider).push(Routes.module);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Aus deinen Schwerpunkten'),
        findsOneWidget,
      );
    });

    testWidgets('ohne Schwerpunkte steht der Hinweis nicht da', (tester) async {
      handyGroesse(tester, hoehe: 2600);
      final container = await _appMitDashboard(tester);

      container.read(routerProvider).push(Routes.module);
      await tester.pumpAndSettle();

      expect(find.textContaining('Aus deinen Schwerpunkten'), findsNothing);
    });

    testWidgets('vorausgewaehlt heisst nicht festgelegt', (tester) async {
      // Das ist der ganze Unterschied zu „das Onboarding entscheidet".
      handyGroesse(tester, hoehe: 2600);
      final container = await _appMitDashboard(
        tester,
        fokus: {Fokusbereich.haut},
      );

      container.read(moduleControllerProvider.notifier).vorbereiten(
        {AnalyseModul.hautFarbtyp},
      );
      container.read(routerProvider).push(Routes.module);
      await tester.pumpAndSettle();

      final ausrichtung = container.read(ausrichtungProvider);
      await tester.tap(
        find.text(AnalyseModul.hautFarbtyp.titel(texte, ausrichtung)),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(moduleControllerProvider).module,
        {AnalyseModul.basis},
      );
    });
  });
}
