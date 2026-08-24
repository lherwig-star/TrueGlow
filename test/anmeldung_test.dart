import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowup/core/router/app_router.dart';
import 'package:glowup/features/auth/logic/auth_repository.dart';
import 'package:glowup/features/auth/models/glowup_nutzer.dart';
import 'package:glowup/features/onboarding/logic/onboarding_controller.dart';
import 'package:glowup/features/onboarding/models/onboarding_profile.dart';
import 'package:glowup/main.dart';

import 'hilfen.dart';

/// Startet die App mit einer bestimmten Anmeldung und abgeschlossenem
/// Onboarding – der Zustand, in dem der Login-Screen greift.
Future<(ProviderContainer, FakeAuthRepository)> _start(
  WidgetTester tester, {
  GlowUpNutzer? nutzer,
}) async {
  final anmeldung = FakeAuthRepository(nutzer: nutzer);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...speicherOverrides(),
        ...dienstOverrides(),
        authRepositoryProvider.overrideWithValue(anmeldung),
      ],
      child: const GlowUpApp(),
    ),
  );
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(GlowUpApp)),
  );

  final onboarding = container.read(onboardingControllerProvider.notifier);
  onboarding.setAlter(Altersbereich.a25bis34);
  onboarding.setBudget(Budget.mittel);
  onboarding.setZeit(Zeitbudget.mittel);
  onboarding.toggleFokus(Fokusbereich.haut);
  onboarding.setZustimmung(true);
  onboarding.abschliessen();

  container.read(routerProvider).go(Routes.home);
  await tester.pumpAndSettle();

  return (container, anmeldung);
}

void main() {
  testWidgets('nach dem Onboarding fuehrt der Weg zur Anmeldung',
      (tester) async {
    handyGroesse(tester, hoehe: 1400);
    await _start(tester);

    expect(find.text('Erst ausprobieren'), findsOneWidget);
    expect(find.text('Mit Google anmelden'), findsOneWidget);
  });

  testWidgets('"Erst ausprobieren" fuehrt anonym ins Dashboard',
      (tester) async {
    handyGroesse(tester, hoehe: 1400);
    final (container, anmeldung) = await _start(tester);

    await tester.tap(find.text('Erst ausprobieren'));
    await tester.pumpAndSettle();

    expect(anmeldung.zuletztGenutzt, AuthAnbieter.anonym);
    expect(container.read(authRepositoryProvider).aktuell?.anonym, isTrue);
    expect(find.text('Erst ausprobieren'), findsNothing);
  });

  testWidgets('ein Fehler bleibt auf dem Screen stehen', (tester) async {
    handyGroesse(tester, hoehe: 1400);
    final (_, anmeldung) = await _start(tester);

    anmeldung.naechsterFehler = AuthFehler.keinInternet;
    await tester.tap(find.text('Mit Google anmelden'));
    await tester.pumpAndSettle();

    expect(find.text(AuthFehler.keinInternet.titel), findsOneWidget);
    expect(find.text(AuthFehler.keinInternet.tipp), findsOneWidget);
    // Der Screen bleibt bedienbar, statt in einen Ladezustand zu kippen.
    expect(find.text('Erst ausprobieren'), findsOneWidget);
  });

  testWidgets('angemeldet startet die App direkt im Dashboard',
      (tester) async {
    handyGroesse(tester, hoehe: 1400);
    await _start(
      tester,
      nutzer: const GlowUpNutzer(uid: 'u1', anonym: true),
    );

    expect(find.text('Erst ausprobieren'), findsNothing);
  });

  testWidgets('Abmelden in den Einstellungen fuehrt zurueck zur Anmeldung',
      (tester) async {
    handyGroesse(tester, hoehe: 2400);
    final (container, anmeldung) = await _start(
      tester,
      nutzer: const GlowUpNutzer(
        uid: 'u1',
        anonym: false,
        email: 'jemand@example.com',
        anzeigename: 'Jemand',
      ),
    );

    container.read(routerProvider).go(Routes.settings);
    await tester.pumpAndSettle();

    expect(find.text('Jemand'), findsOneWidget);

    await tester.tap(find.text('Abmelden'));
    await tester.pumpAndSettle();

    // Der Dialog erklaert die Folge, bevor er sie ausloest.
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Abmelden'),
      ),
    );
    await tester.pumpAndSettle();

    expect(anmeldung.aktuell, isNull);
    expect(find.text('Erst ausprobieren'), findsOneWidget);
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
      const anonym = GlowUpNutzer(uid: 'a', anonym: true);
      const mitName = GlowUpNutzer(
        uid: 'b',
        anonym: false,
        anzeigename: 'Jemand',
        email: 'jemand@example.com',
      );
      const nurMail = GlowUpNutzer(
        uid: 'c',
        anonym: false,
        email: 'jemand@example.com',
      );

      expect(anonym.beschriftung, 'Ohne Konto angemeldet');
      expect(mitName.beschriftung, 'Jemand');
      expect(nurMail.beschriftung, 'jemand@example.com');
    });
  });
}
