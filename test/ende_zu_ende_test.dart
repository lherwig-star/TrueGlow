import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/app_strings.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/analysis_service.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/features/streak/logic/streak_repository.dart';
import 'package:trueglow/features/streak/models/abzeichen.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// Alle Basis-Aufnahmen als bereits geprueft. Der Mock-Service liest die
/// Dateien nicht, deshalb reichen Pfade.
CaptureState _basisFotos() => CaptureState(
      fotos: {
        for (final typ in AnalyseModul.basis.aufnahmen)
          typ: CapturedPhoto(
            typ: typ,
            pfad: '${typ.name}.jpg',
            breite: 768,
            hoehe: 1024,
            groesseInBytes: 120000,
          ),
      },
    );

void main() {
  testWidgets('Analyse landet im Dashboard, im Plan und im Verlauf',
      (tester) async {
    handyGroesse(tester, hoehe: 2400);
    final overrides = testOverrides();

    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const TrueGlowApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrueGlowApp)),
    );

    // Onboarding ueberspringen und direkt auf dem Dashboard starten.
    final onboarding = container.read(onboardingControllerProvider.notifier);
    onboarding.setAlter(Altersbereich.a25bis34);
    onboarding.setBudget(Budget.mittel);
    onboarding.setZeit(Zeitbudget.mittel);
    onboarding.toggleFokus(Fokusbereich.haut);
    onboarding.setZustimmung(true);
    onboarding.abschliessen();

    // Der Redirect greift beim naechsten Navigationsvorgang – genau so
    // verlaesst auch der letzte Onboarding-Screen die Seite.
    container.read(routerProvider).go(Routes.home);
    await tester.pumpAndSettle();

    expect(find.text(S.homeLeerTitel), findsOneWidget);

    // Fotos setzen und die Analyse ueber den Controller starten – das ist
    // derselbe Weg, den der Analyse-Screen nimmt.
    final container2 = container;
    container2.read(captureControllerProvider.notifier).setzeZustand(_basisFotos());
    final laufendeAnalyse =
        container2.read(analysisControllerProvider.notifier).starten();
    // Die Testuhr ist gefaked – die Wartezeit des Mocks muss aktiv
    // vorgespult werden, sonst wartet der Test ewig.
    await tester.pump(AnalysisConfig.mockDauer + const Duration(seconds: 1));
    await laufendeAnalyse;
    await tester.pumpAndSettle();

    // Ergebnis ist gespeichert.
    final analysen = container2.read(analysenProvider);
    expect(analysen, hasLength(1));
    expect(analysen.single.istVollstaendig, isTrue);

    // Die erste Analyse schaltet ein Abzeichen frei – der Jubel liegt jetzt
    // ueber dem Dashboard und muss erst weggetippt werden.
    expect(find.text('Weiter so'), findsOneWidget);
    expect(find.text(Abzeichen.ersteAnalyse.jubel), findsWidgets);
    await tester.tap(find.text('Weiter so'));
    await tester.pumpAndSettle();
    expect(
      container2.read(streakProvider).gefeiert,
      contains(Abzeichen.ersteAnalyse),
    );

    // Dashboard zeigt jetzt den Plan statt des leeren Zustands.
    expect(find.text(S.homeLeerTitel), findsNothing);
    expect(find.text('Dein Plan'), findsOneWidget);
    // Eine Checkliste pro Kapitel – bei reiner Basis-Analyse genau eine.
    expect(find.text(AnalyseModul.basis.checkliste), findsOneWidget);

    // Solange nichts abgehakt ist, bleibt die Serie bei null.
    expect(container2.read(streakProvider).aktuell, 0);
    expect(container2.read(streakProvider).heuteGesichert, isFalse);

    // Ein Habit abhaken – der Fortschritt landet in Hive.
    final habit = analysen.single.alleHabits.first;
    await tester.tap(find.text(habit).first);
    await tester.pumpAndSettle();

    expect(container2.read(planFortschrittProvider).erledigt, contains(habit));
    expect(container2.read(streakProvider).aktuell, 1);
    expect(container2.read(streakProvider).heuteGesichert, isTrue);
    expect(container2.read(streakProvider).rekord, 1);

    // Der Jubel kommt pro Abzeichen genau einmal.
    expect(find.text('Weiter so'), findsNothing);
  });

  testWidgets('Ohne Fotos meldet die Analyse einen verstaendlichen Fehler',
      (tester) async {
    handyGroesse(tester, hoehe: 1400);
    final overrides = testOverrides();

    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const TrueGlowApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrueGlowApp)),
    );

    await container.read(analysisControllerProvider.notifier).starten();

    final zustand = container.read(analysisControllerProvider);
    expect(zustand, isA<AnalyseFehlgeschlagen>());
    expect(container.read(analysenProvider), isEmpty);
  });
}
