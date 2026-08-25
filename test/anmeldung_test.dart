import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/auth/logic/auth_repository.dart';
import 'package:trueglow/features/auth/models/trueglow_nutzer.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

import 'hilfen.dart';

/// Startet die App mit einer bestimmten Anmeldung und abgeschlossenem
/// Onboarding – der Zustand, in dem der Login-Screen greift.
///
/// Das Onboarding wird hier vorweg abgehakt, obwohl es seit dem Umbau erst
/// nach der Anmeldung kommt: Diese Tests pruefen die Anmeldung, nicht den Weg
/// dorthin.
Future<(ProviderContainer, FakeAuthRepository)> _start(
  WidgetTester tester, {
  TrueGlowNutzer? nutzer,
}) async {
  final anmeldung = FakeAuthRepository(nutzer: nutzer);

  final container = await appStarten(
    tester,
    overrides: testOverrides(anmeldung: anmeldung),
  );

  final onboarding = container.read(onboardingControllerProvider.notifier);
  onboarding.setAlter(Altersbereich.a25bis34);
  onboarding.setBudget(Budget.mittel);
  onboarding.setZeit(Zeitbudget.mittel);
  onboarding.toggleFokus(Fokusbereich.haut);
  onboarding.setZustimmung(true);
  onboarding.abschliessen();
  einwilligungErteilen(container);

  container.read(routerProvider).go(Routes.home);
  await tester.pumpAndSettle();

  return (container, anmeldung);
}

void main() {
  testWidgets('die Anmeldung ist der erste Bildschirm', (tester) async {
    handyGroesse(tester, hoehe: 1400);
    await _start(tester);

    expect(find.text(texte.loginGast), findsOneWidget);
    expect(find.text(texte.loginMitAnbieter(texte.anbieterGoogle)), findsOneWidget);
  });

  testWidgets('"Erst ausprobieren" fuehrt anonym ins Dashboard',
      (tester) async {
    handyGroesse(tester, hoehe: 1400);
    final (container, anmeldung) = await _start(tester);

    await tester.tap(find.text(texte.loginGast));
    await tester.pumpAndSettle();

    expect(anmeldung.zuletztGenutzt, AuthAnbieter.anonym);
    expect(container.read(authRepositoryProvider).aktuell?.anonym, isTrue);
    expect(find.text(texte.loginGast), findsNothing);
  });

  testWidgets('ein Fehler bleibt auf dem Screen stehen', (tester) async {
    handyGroesse(tester, hoehe: 1400);
    final (_, anmeldung) = await _start(tester);

    anmeldung.naechsterFehler = AuthFehler.keinInternet;
    await tester.tap(find.text(texte.loginMitAnbieter(texte.anbieterGoogle)));
    await tester.pumpAndSettle();

    expect(find.text(AuthFehler.keinInternet.titel(texte)), findsOneWidget);
    expect(find.text(AuthFehler.keinInternet.tipp(texte)), findsOneWidget);
    // Der Screen bleibt bedienbar, statt in einen Ladezustand zu kippen.
    expect(find.text(texte.loginGast), findsOneWidget);
  });

  testWidgets('angemeldet startet die App direkt im Dashboard',
      (tester) async {
    handyGroesse(tester, hoehe: 1400);
    await _start(
      tester,
      nutzer: const TrueGlowNutzer(uid: 'u1', anonym: true),
    );

    expect(find.text(texte.loginGast), findsNothing);
  });

  testWidgets('Abmelden in den Einstellungen fuehrt zurueck zur Anmeldung',
      (tester) async {
    handyGroesse(tester, hoehe: 2400);
    final (container, anmeldung) = await _start(
      tester,
      nutzer: const TrueGlowNutzer(
        uid: 'u1',
        anonym: false,
        email: 'jemand@example.com',
        anzeigename: 'Jemand',
      ),
    );

    container.read(routerProvider).go(Routes.settings);
    await tester.pumpAndSettle();

    expect(find.text('Jemand'), findsOneWidget);

    await tester.tap(find.text(texte.settingsAbmelden));
    await tester.pumpAndSettle();

    // Der Dialog erklaert die Folge, bevor er sie ausloest.
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, texte.settingsAbmelden),
      ),
    );
    await tester.pumpAndSettle();

    expect(anmeldung.aktuell, isNull);
    expect(find.text(texte.loginGast), findsOneWidget);
  });

  group('AuthAnbieter', () {
    test('Apple erscheint nur auf Apple-Geraeten', () {
      expect(AuthAnbieter.apple.verfuegbarAuf(TargetPlatform.iOS), isTrue);
      expect(AuthAnbieter.apple.verfuegbarAuf(TargetPlatform.android), isFalse);
      expect(AuthAnbieter.google.verfuegbarAuf(TargetPlatform.android), isTrue);
      expect(AuthAnbieter.anonym.verfuegbarAuf(TargetPlatform.iOS), isTrue);
    });
  });

  group('FakeAuthRepository', () {
    test('behaelt beim Verknuepfen die uid', () async {
      final repo = FakeAuthRepository();
      final anonym = await repo.anmelden(AuthAnbieter.anonym);

      final verknuepft = await repo.verknuepfen(AuthAnbieter.google);

      expect(verknuepft.uid, anonym.uid);
      expect(verknuepft.anonym, isFalse);
    });

    test('beschriftet das Konto verstaendlich', () {
      const anonym = TrueGlowNutzer(uid: 'a', anonym: true);
      const mitName = TrueGlowNutzer(
        uid: 'b',
        anonym: false,
        anzeigename: 'Jemand',
        email: 'jemand@example.com',
      );
      const nurMail = TrueGlowNutzer(
        uid: 'c',
        anonym: false,
        email: 'jemand@example.com',
      );

      expect(anonym.beschriftung(texte), 'Ohne Konto angemeldet');
      expect(mitName.beschriftung(texte), 'Jemand');
      expect(nurMail.beschriftung(texte), 'jemand@example.com');
    });
  });
}
