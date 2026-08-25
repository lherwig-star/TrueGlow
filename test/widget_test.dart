import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/widgets/section_card.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

void main() {
  testWidgets('Start zeigt das Onboarding', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const TrueGlowApp()));
    await tester.pumpAndSettle();

    expect(find.text(texte.onbWillkommenTitel), findsOneWidget);
  });

  testWidgets('Onboarding fuehrt nach Zustimmung zum Dashboard', (tester) async {
    // Die Einwilligungsseite traegt inzwischen Disclaimer, Verweise auf die
    // Rechtstexte und die Haekchen – im Standardfenster faellt das Ende
    // heraus.
    handyGroesse(tester, hoehe: 1400);
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const TrueGlowApp()));
    await tester.pumpAndSettle();

    // Seite 1: Willkommen
    await tester.tap(find.text(texte.weiter));
    await tester.pumpAndSettle();

    // Seite 2: Alter + Budget
    await tester.tap(find.text('25–34'));
    await tester.tap(find.text('Mittel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texte.weiter));
    await tester.pumpAndSettle();

    // Seite 3: Zeitbudget
    await tester.tap(find.text('15 Minuten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texte.weiter));
    await tester.pumpAndSettle();

    // Seite 4: Fokusbereiche
    await tester.tap(find.text('Haut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texte.weiter));
    await tester.pumpAndSettle();

    // Seite 5: zwei getrennte Einwilligungen. Nur die erste ist Pflicht –
    // die Foto-Einwilligung bleibt bewusst ungehakt, um genau das zu pruefen.
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(Einwilligungsart.nutzung.titel(texte)),
          matching: find.byType(SectionCard),
        ),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Los geht es'));
    await tester.pumpAndSettle();

    expect(find.text(texte.homeLeerTitel), findsOneWidget);
    expect(find.text(texte.homeAnalyseStarten), findsOneWidget);
  });
}
