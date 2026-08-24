import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowup/core/l10n/app_strings.dart';
import 'package:glowup/main.dart';

import 'hilfen.dart';

void main() {
  testWidgets('Start zeigt das Onboarding', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: speicherOverrides(), child: const GlowUpApp()));
    await tester.pumpAndSettle();

    expect(find.text(S.onbWillkommenTitel), findsOneWidget);
  });

  testWidgets('Onboarding fuehrt nach Zustimmung zum Dashboard', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: speicherOverrides(), child: const GlowUpApp()));
    await tester.pumpAndSettle();

    // Seite 1: Willkommen
    await tester.tap(find.text(S.weiter));
    await tester.pumpAndSettle();

    // Seite 2: Alter + Budget
    await tester.tap(find.text('25–34'));
    await tester.tap(find.text('Mittel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.weiter));
    await tester.pumpAndSettle();

    // Seite 3: Zeitbudget
    await tester.tap(find.text('15 Minuten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.weiter));
    await tester.pumpAndSettle();

    // Seite 4: Fokusbereiche
    await tester.tap(find.text('Haut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.weiter));
    await tester.pumpAndSettle();

    // Seite 5: Datenschutz-Zustimmung
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Los geht es'));
    await tester.pumpAndSettle();

    expect(find.text(S.homeLeerTitel), findsOneWidget);
    expect(find.text(S.homeAnalyseStarten), findsOneWidget);
  });
}
