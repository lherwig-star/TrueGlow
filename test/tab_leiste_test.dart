import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/checkin/ui/widgets/checkin_karte.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/home/logic/home_tab.dart';
import 'package:trueglow/features/home/ui/tabs/analyse_tab.dart';
import 'package:trueglow/features/home/ui/tabs/fortschritt_tab.dart';
import 'package:trueglow/features/home/ui/tabs/heute_tab.dart';
import 'package:trueglow/features/home/ui/tabs/plan_tab.dart';
import 'package:trueglow/features/home/ui/widgets/phase_karte.dart';
import 'package:trueglow/features/home/ui/widgets/tab_leiste.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/plan/ui/widgets/challenge_karte.dart';
import 'package:trueglow/features/plan/ui/widgets/tagesliste_karte.dart';
import 'package:trueglow/features/streak/ui/widgets/abzeichen_sektion.dart';
import 'package:trueglow/features/streak/ui/widgets/streak_karte.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// Die untere Tab-Leiste – DECISIONS 65.
///
/// Die Startseite war eine einzige sehr lange Liste; die Kernfunktion stand
/// an ihrem Ende. Geprüft werden die vier Zusagen aus dem Paket: Jeder Tab
/// hat seinen Inhalt, **kein Inhalt existiert doppelt**, die Scroll-Position
/// übersteht den Wechsel, und die Zurück-Taste führt erst nach „Heute".
///
/// **Zur Bauweise dieser Tests:** Die vier Tabs liegen in einem
/// `IndexedStack` — alle vier sind gebaut, nur einer ist sichtbar. `find.text`
/// findet deshalb auch, was gerade hinter einem anderen Tab liegt. Wo es um
/// „steht auf welchem Tab" geht, wird deshalb über [find.descendant] gesucht,
/// und wo es um „existiert genau einmal" geht, über den Widget-Typ im ganzen
/// Baum. Das ist strenger als ein Blick auf den Bildschirm: Ein doppelter
/// Eintrag fällt auch dann auf, wenn er gerade unsichtbar ist.
Future<ProviderContainer> _app(
  WidgetTester tester, {
  bool mitAnalyse = true,
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
  onboarding.setZustimmung(true);
  onboarding.abschliessen();
  einwilligungErteilen(container);

  if (mitAnalyse) {
    await container.read(analysenProvider.notifier).speichern(_analyse());
  }

  container.read(routerProvider).go(Routes.home);
  await tester.pumpAndSettle();
  // Die erste Analyse schaltet ein Abzeichen frei – der Jubel liegt dann
  // ueber der Leiste und faengt jeden Tipp ab.
  final weiter = find.text('Weiter so');
  if (weiter.evaluate().isNotEmpty) {
    await tester.tap(weiter);
    await tester.pumpAndSettle();
  }

  return container;
}

AnalysisResult _analyse() => AnalysisResult(
      id: 'a1',
      erstelltAm: DateTime.now(),
      kapitel: const [
        Kapitel(
          modul: AnalyseModul.basis,
          einleitung: 'Ovale Grundform mit klarer Kieferlinie.',
          sektionen: [],
          habits: ['Nach dem Duschen: Paste einarbeiten'],
        ),
      ],
      plan: const Plan(
        sofort: ['Heute den Termin machen'],
        dreissigTage: [],
        langfristig: [],
        taeglicheHabits: [],
      ),
    );

/// Tippt in der Leiste, nicht irgendwo im Baum.
Future<void> _tippe(WidgetTester tester, HomeTab tab) async {
  await tester.tap(
    find.descendant(
      of: find.byType(TabLeiste),
      matching: find.text(tab.label(texte)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Die Leiste steht da', () {
    testWidgets('mit allen vier Tabs, beschriftet', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      await _app(tester);

      expect(find.byType(TabLeiste), findsOneWidget);
      for (final tab in HomeTab.values) {
        expect(
          find.descendant(
            of: find.byType(TabLeiste),
            matching: find.text(tab.label(texte)),
          ),
          findsOneWidget,
          reason: tab.name,
        );
      }
    });

    testWidgets('und „Heute" ist offen, wenn die App startet', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      expect(container.read(homeTabProvider), HomeTab.heute);
    });
  });

  group('Kein Inhalt existiert doppelt', () {
    testWidgets('jede Karte steht auf genau einem Tab', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      await _app(tester);

      // Der `IndexedStack` baut einen Tab erst, wenn er gewaehlt wird, und
      // seine Liste raeumt hinter sich auf, sobald er wieder inaktiv ist.
      // Gezaehlt wird deshalb tabweise: Jeder Tab wird geoeffnet und dabei
      // notiert, welche Karten er traegt.
      final gefunden = <Type, List<HomeTab>>{
        for (final typ in <Type>[
          StreakKarte,
          ChallengeKarte,
          AbschnittKarte,
          CheckinKarte,
          PhaseKarte,
          AbzeichenSektion,
        ])
          typ: <HomeTab>[],
      };

      for (final tab in HomeTab.values) {
        await _tippe(tester, tab);
        for (final typ in gefunden.keys) {
          if (find.byType(typ).evaluate().isNotEmpty) gefunden[typ]!.add(tab);
        }
      }

      for (final eintrag in gefunden.entries) {
        expect(
          eintrag.value,
          hasLength(1),
          reason: '${eintrag.key} steht auf ${eintrag.value}',
        );
      }

      // Und die Verteilung ist die aus DECISIONS 65.
      expect(gefunden[StreakKarte], [HomeTab.heute]);
      expect(gefunden[ChallengeKarte], [HomeTab.heute]);
      expect(gefunden[AbschnittKarte], [HomeTab.heute]);
      expect(gefunden[CheckinKarte], [HomeTab.plan]);
      expect(gefunden[PhaseKarte], [HomeTab.plan]);
      expect(gefunden[AbzeichenSektion], [HomeTab.fortschritt]);
    });
  });

  group('Jeder Tab hat seinen Inhalt', () {
    testWidgets('Heute: Serie, Challenge, Tagesliste', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      await _app(tester);

      for (final typ in <Type>[StreakKarte, ChallengeKarte, AbschnittKarte]) {
        expect(
          find.descendant(of: find.byType(HeuteTab), matching: find.byType(typ)),
          findsOneWidget,
          reason: '$typ',
        );
      }
    });

    testWidgets('Plan: Zusammenfassung, Check-in, Phasen', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      await _tippe(tester, HomeTab.plan);
      expect(container.read(homeTabProvider), HomeTab.plan);

      final imPlan = find.byType(PlanTab);
      expect(
        find.descendant(of: imPlan, matching: find.text(texte.homeDeinPlan)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: imPlan, matching: find.byType(CheckinKarte)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: imPlan, matching: find.byType(PhaseKarte)),
        findsOneWidget,
      );
    });

    testWidgets('Analyse: Kontingent, Start und Verlauf', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      await _tippe(tester, HomeTab.analyse);
      expect(container.read(homeTabProvider), HomeTab.analyse);

      final imTab = find.byType(AnalyseTab);
      expect(
        find.descendant(of: imTab, matching: find.text(texte.homeNeueAnalyse)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: imTab, matching: find.text(texte.verlaufTitel)),
        findsOneWidget,
      );
      // Der gespeicherte Report steht als Eintrag drin.
      expect(
        find.descendant(of: imTab, matching: find.byType(VerlaufKarte)),
        findsOneWidget,
      );
    });

    testWidgets('Fortschritt: Abzeichen, Rekord, Album', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      await _tippe(tester, HomeTab.fortschritt);
      expect(container.read(homeTabProvider), HomeTab.fortschritt);

      final imTab = find.byType(FortschrittTab);
      expect(
        find.descendant(of: imTab, matching: find.byType(AbzeichenSektion)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: imTab,
          matching: find.text(texte.fortschrittSerieTitel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: imTab,
          matching: find.text(texte.fortschrittSerieRekord),
        ),
        findsOneWidget,
      );
    });

    testWidgets('die Serien-Karte steht auf Heute, nicht auf Fortschritt',
        (tester) async {
      // Sie fordert zum Abhaken auf und gehoert deshalb dorthin, wo
      // abgehakt wird. Im Fortschritt-Tab steht stattdessen die Bilanz.
      handyGroesse(tester, hoehe: 2200);
      await _app(tester);

      expect(
        find.descendant(
          of: find.byType(HeuteTab),
          matching: find.byType(StreakKarte),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FortschrittTab),
          matching: find.byType(StreakKarte),
        ),
        findsNothing,
      );
    });
  });

  group('Der Punkt am Heute-Tab', () {
    TabLeiste leiste(WidgetTester tester) =>
        tester.widget<TabLeiste>(find.byType(TabLeiste));

    testWidgets('ist da, solange nichts abgehakt ist – und dann weg',
        (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      expect(leiste(tester).punktAmHeute, isTrue);
      // Und er wird auch wirklich gezeichnet: Erst stand er ausserhalb der
      // Stack-Grenzen und war am Geraet abgeschnitten – im Widget-Baum aber
      // vorhanden. Deshalb wird hier die gezeichnete Flaeche geprueft.
      final punkt = find.byKey(const Key('punkt-heute'));
      expect(punkt, findsOneWidget);
      final flaeche = tester.getRect(punkt);
      expect(flaeche.width, greaterThan(0));
      expect(
        tester.getRect(find.byType(TabLeiste)).contains(flaeche.center),
        isTrue,
        reason: 'Der Punkt liegt ausserhalb der Leiste: $flaeche',
      );

      await container
          .read(planFortschrittProvider.notifier)
          .umschalten('Nach dem Duschen: Paste einarbeiten');
      await tester.pumpAndSettle();

      expect(leiste(tester).punktAmHeute, isFalse);
      expect(find.byKey(const Key('punkt-heute')), findsNothing);
    });

    testWidgets('und ohne Analyse gibt es ihn gar nicht', (tester) async {
      // Ohne Plan gibt es nichts abzuhaken – ein Punkt waere dann eine
      // Aufforderung ins Leere.
      handyGroesse(tester, hoehe: 2200);
      await _app(tester, mitAnalyse: false);

      expect(leiste(tester).punktAmHeute, isFalse);
    });
  });

  group('Wege von aussen fuehren auf den richtigen Tab', () {
    testWidgets('/plan oeffnet den Plan-Tab', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      container.read(routerProvider).go(Routes.plan);
      await tester.pumpAndSettle();

      expect(container.read(homeTabProvider), HomeTab.plan);
    });

    testWidgets('/history oeffnet den Analyse-Tab', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      container.read(routerProvider).go(Routes.history);
      await tester.pumpAndSettle();

      expect(container.read(homeTabProvider), HomeTab.analyse);
    });

    testWidgets('und das Verlaufs-Symbol oben rechts auch', (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(container.read(homeTabProvider), HomeTab.analyse);
    });
  });

  group('Die Zurueck-Taste', () {
    testWidgets('fuehrt aus einem anderen Tab erst nach Heute',
        (tester) async {
      handyGroesse(tester, hoehe: 2200);
      final container = await _app(tester);

      await _tippe(tester, HomeTab.fortschritt);
      expect(container.read(homeTabProvider), HomeTab.fortschritt);

      // Die System-Zurueck-Geste laeuft ueber `maybePop`.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(container.read(homeTabProvider), HomeTab.heute);
      // Und die App laeuft noch.
      expect(find.byType(TabLeiste), findsOneWidget);
    });
  });

  group('Die Scroll-Position uebersteht den Wechsel', () {
    testWidgets('jeder Tab behaelt seine eigene', (tester) async {
      handyGroesse(tester, hoehe: 700);
      await _app(tester);

      final heute = find.descendant(
        of: find.byType(HeuteTab),
        matching: find.byType(Scrollable),
      );

      await tester.drag(heute.first, const Offset(0, -160));
      await tester.pumpAndSettle();

      final vorher = tester.state<ScrollableState>(heute.first).position.pixels;
      expect(vorher, greaterThan(0));

      await _tippe(tester, HomeTab.plan);
      await _tippe(tester, HomeTab.heute);

      expect(
        tester.state<ScrollableState>(heute.first).position.pixels,
        closeTo(vorher, 1),
      );
    });
  });
}
