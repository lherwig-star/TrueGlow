import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/streak/logic/streak_repository.dart';
import 'package:trueglow/features/streak/ui/widgets/streak_karte.dart';

import 'hilfen.dart';

/// Die Serien-Karte: Joker-Vorrat, Rekord und der Moment nach dem ersten
/// Haken des Tages.
///
/// Der gefeierte Moment (DECISIONS 45) ist bewusst kein Dialog. Genau das
/// macht ihn testbar wie jedes andere Widget — und genau das muss geprüft
/// werden: dass er kommt, dass er wieder geht, und dass er nicht bei jedem
/// weiteren Haken erneut auftaucht.
void main() {
  final analyse = AnalysisResult.vonApi(
    JsonExtractor.extrahiere(
      MockAnalysisService.antwortFuer({AnalyseModul.basis}),
    )!,
    id: 'a1',
    erstelltAm: DateTime(2026, 8, 26),
  );

  Future<ProviderContainer> karteZeigen(WidgetTester tester) async {
    handyGroesse(tester, hoehe: 800);
    final container = ProviderContainer(overrides: speicherOverrides());
    addTearDown(container.dispose);

    await container.read(analysisRepositoryProvider).speichern(analyse);
    container.read(analysenProvider.notifier).neuLaden();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testHuelle(const Scaffold(body: StreakKarte())),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('zeigt den Joker-Vorrat des Monats', (tester) async {
    await karteZeigen(tester);

    expect(find.text('2/${StreakRepository.jokerProMonat}'), findsOneWidget);
  });

  testWidgets('der erste Haken des Tages wird gefeiert', (tester) async {
    final container = await karteZeigen(tester);

    expect(find.text(texte.streakTagGesichert), findsNothing);

    await container
        .read(planFortschrittProvider.notifier)
        .umschalten(analyse.alleHabits.first);
    await tester.pump();
    await tester.pump();

    expect(find.text(texte.streakTagGesichert), findsOneWidget);
    expect(find.text(texte.streakTagGesichertText(1)), findsOneWidget);
  });

  testWidgets('der Moment verschwindet von selbst', (tester) async {
    // Kein Knopf, kein Wegklicken: Was jeden Tag kommt, muss von allein
    // wieder gehen.
    final container = await karteZeigen(tester);

    await container
        .read(planFortschrittProvider.notifier)
        .umschalten(analyse.alleHabits.first);
    await tester.pump();
    await tester.pump();
    expect(find.text(texte.streakTagGesichert), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text(texte.streakTagGesichert), findsNothing);
  });

  testWidgets('der zweite Haken am selben Tag feiert nicht erneut',
      (tester) async {
    final container = await karteZeigen(tester);
    final habits = analyse.alleHabits;

    await container.read(planFortschrittProvider.notifier).umschalten(habits[0]);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await container.read(planFortschrittProvider.notifier).umschalten(habits[1]);
    await tester.pump();
    await tester.pump();

    expect(find.text(texte.streakTagGesichert), findsNothing);
  });

  testWidgets('ohne Serie und ohne Rekord steht kein Neustart-Text da',
      (tester) async {
    // Der Ton beim allerersten Mal ist ein anderer als nach einem Abriss.
    await karteZeigen(tester);

    expect(find.text(texte.streakNeustart), findsNothing);
    expect(find.text(texte.streakNichtsAbgehakt), findsOneWidget);
  });
}
