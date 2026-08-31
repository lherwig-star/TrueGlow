import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/ui/widgets/modul_karte.dart';
import 'package:trueglow/features/result/logic/plan_erzeugt.dart';
import 'package:trueglow/features/result/ui/erweitern_screen.dart';
import 'package:trueglow/features/result/ui/result_screen.dart';

import 'hilfen.dart';

/// Der aufgeräumte Fuß der Report-Seite – DECISIONS 90.
///
/// Zwei Dinge standen dort zu groß: drei ausführliche Modul-Karten für
/// Bereiche, die es noch gar nicht gibt, und zwei Knöpfe, von denen einer
/// nichts tat, was die Zurück-Taste nicht auch tut.
void main() {
  hiveImTest();

  AnalysisResult report({List<AnalyseModul> module = const []}) =>
      AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
        kapitel: [
          for (final modul in module)
            Kapitel(
              modul: modul,
              kurzfazit: 'Kurzfazit zu ${modul.name}',
              einleitung: 'Einleitung.',
              sektionen: [
                Sektion(
                  titel: 'Abschnitt ${modul.name}',
                  einschaetzung: 'x',
                  empfehlungen: const ['Eine Empfehlung'],
                  produkte: const [],
                ),
              ],
            ),
        ],
        plan: const Plan(
          sofort: [],
          dreissigTage: [],
          langfristig: [],
          taeglicheHabits: [],
        ),
      );

  Future<ProviderContainer> zeige(
    WidgetTester tester,
    AnalysisResult ergebnis, {
    GoRouter? router,
  }) async {
    handyGroesse(tester, hoehe: 2400);

    final container = ProviderContainer(overrides: speicherOverrides());
    addTearDown(container.dispose);
    await container.read(analysenProvider.notifier).speichern(ergebnis);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: router == null
            ? testHuelle(const ResultScreen(analyseId: '1'))
            : MaterialApp.router(
                theme: AppTheme.dark,
                locale: const Locale('de'),
                localizationsDelegates: L.localizationsDelegates,
                supportedLocales: L.supportedLocales,
                routerConfig: router,
              ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('Erweitern ist eine Zeile, keine drei Karten', () {
    testWidgets('die Karte nennt die offenen Bereiche', (tester) async {
      await zeige(tester, report(module: [AnalyseModul.basis]));

      expect(find.text(texte.moduleErweitern), findsOneWidget);
      expect(
        find.textContaining('Bereiche noch nicht analysiert'),
        findsOneWidget,
      );
      // Die ausführlichen Modul-Karten stehen nicht mehr im Report.
      expect(find.byType(ModulKarte), findsNothing);
    });

    testWidgets('sind alle Bereiche analysiert, erscheint sie nicht',
        (tester) async {
      await zeige(
        tester,
        report(module: AnalyseModul.bestellbar),
      );

      expect(find.text(texte.moduleErweitern), findsNothing);
    });

    testWidgets('und dahinter stehen die ausführlichen Karten',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/result/1',
        routes: [
          GoRoute(
            path: '/result/:id',
            builder: (context, state) =>
                ResultScreen(analyseId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'erweitern',
                builder: (context, state) => ErweiternScreen(
                  analyseId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await zeige(
        tester,
        report(module: [AnalyseModul.basis]),
        router: router,
      );

      await tester.tap(find.textContaining('Bereiche noch nicht analysiert'));
      await tester.pumpAndSettle();

      expect(find.byType(ErweiternScreen), findsOneWidget);
      expect(find.byType(ModulKarte), findsWidgets);
    });
  });

  group('Unten steht genau ein Knopf', () {
    testWidgets('„Zur Startseite" ist weg', (tester) async {
      await zeige(tester, report(module: [AnalyseModul.basis]));

      expect(find.text(texte.zurStartseite), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('erst „Plan erstellen", danach „Zum Plan"', (tester) async {
      // Ohne diese Notiz hieße der Knopf für immer „Plan erstellen" – auch
      // beim zehnten Besuch desselben Reports.
      final router = GoRouter(
        initialLocation: '/result/1',
        routes: [
          GoRoute(
            path: '/result/:id',
            builder: (context, state) =>
                ResultScreen(analyseId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/plan',
            builder: (context, state) =>
                const Scaffold(body: Text('Plan-Tab')),
          ),
        ],
      );
      addTearDown(router.dispose);

      final container = await zeige(
        tester,
        report(module: [AnalyseModul.basis]),
        router: router,
      );

      expect(find.text(texte.ergebnisPlanErstellen), findsOneWidget);
      expect(find.text(texte.ergebnisZumPlan), findsNothing);

      await tester.tap(find.text(texte.ergebnisPlanErstellen));
      await tester.pumpAndSettle();

      // Der Knopf führt in den Plan – und merkt sich, dass es ihn gibt.
      expect(find.text('Plan-Tab'), findsOneWidget);
      expect(container.read(planErzeugtProvider).contains('1'), isTrue);

      // Zurück auf den Report: Jetzt heißt der Knopf anders.
      router.go('/result/1');
      await tester.pumpAndSettle();

      expect(find.text(texte.ergebnisZumPlan), findsOneWidget);
      expect(find.text(texte.ergebnisPlanErstellen), findsNothing);
    });

    testWidgets('der medizinische Hinweis bleibt darüber', (tester) async {
      await zeige(tester, report(module: [AnalyseModul.basis]));

      expect(find.text(texte.disclaimerMedizin), findsOneWidget);
    });
  });
}
