import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/widgets/section_card.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/auth/logic/auth_repository.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/start/ui/splash_screen.dart';

import 'hilfen.dart';

/// Der Weg beim allerersten Start: Startanimation, Anmeldung, Onboarding,
/// Dashboard – in genau dieser Reihenfolge.
void main() {
  testWidgets('der erste Bildschirm ist die Startanimation', (tester) async {
    await tester.pumpWidget(
      appUnterTest(anmeldung: FakeAuthRepository()),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Schon das erste Bild ist der Endzustand – Zeichen und Name zusammen.
    // Es gibt hier nichts mehr, das anlaeuft: Die eine Ueberblendung macht
    // Android ueber diesem fertigen Bild (DECISIONS 55).
    expect(find.text(texte.appName), findsOneWidget);

    // Sie geht von selbst weiter – ohne Knopf, wie ein Startbildschirm es
    // soll.
    await tester.pump(SplashScreen.dauer);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('nach der Startanimation kommt die Anmeldung', (tester) async {
    // Und nicht das Onboarding: Die Erklärseiten gehören zu einem Konto,
    // nicht zu einem Gerät.
    handyGroesse(tester, hoehe: 1400);
    await appStarten(tester, overrides: testOverrides(anmeldung: FakeAuthRepository()));

    expect(find.text(texte.loginGast), findsOneWidget);
    expect(find.text(texte.onbWillkommenTitel), findsNothing);
  });

  testWidgets('der Sprachumschalter steht schon auf der Anmeldung',
      (tester) async {
    // Der erste Text, den jemand liest, ist der auf diesem Bildschirm. Wer
    // die App auf Deutsch bekommt und Englisch erwartet, soll es hier
    // umstellen können – und nicht erst in den Einstellungen, die er ohne
    // Konto gar nicht erreicht.
    handyGroesse(tester, hoehe: 1400);
    await appStarten(tester, overrides: testOverrides(anmeldung: FakeAuthRepository()));

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text(englischeTexte.loginGast), findsOneWidget);
    expect(find.text(texte.loginGast), findsNothing);
  });

  testWidgets('Anmeldung, Onboarding und Zustimmung fuehren zum Dashboard',
      (tester) async {
    // Die Einwilligungsseite traegt inzwischen Disclaimer, Verweise auf die
    // Rechtstexte und die Haekchen – im Standardfenster faellt das Ende
    // heraus.
    handyGroesse(tester, hoehe: 1400);
    await appStarten(tester, overrides: testOverrides(anmeldung: FakeAuthRepository()));

    // Anmeldung: „Erst mal umschauen" legt ein anonymes Konto an.
    await tester.tap(find.text(texte.loginGast));
    await tester.pumpAndSettle();

    // Seite 1: Willkommen
    await tester.tap(find.text(texte.weiter));
    await tester.pumpAndSettle();

    // Seite 2: Geschlecht, Alter, Budget
    await tester.tap(find.text(Geschlecht.maennlich.label(texte)));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text(texte.lichtStarten));
    await tester.pumpAndSettle();

    expect(find.text(texte.homeLeerTitel), findsOneWidget);
    expect(find.text(texte.homeAnalyseStarten), findsOneWidget);
  });
}
