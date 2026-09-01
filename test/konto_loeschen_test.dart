import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/account/logic/konto_dienst.dart';
import 'package:trueglow/features/account/logic/loeschablauf.dart';
import 'package:trueglow/features/auth/logic/auth_repository.dart';
import 'package:trueglow/features/auth/models/trueglow_nutzer.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

import 'hilfen.dart';

/// Loeschdienst ohne Netz: merkt sich die Aufrufe und kann gezielt scheitern.
class _DienstAttrappe implements KontoDienst {
  _DienstAttrappe({
    this.fehlerBisNeuAnmeldung = 0,
    this.dauerhafterFehler,
    this.details,
  });

  /// So oft wird „bitte neu anmelden" verlangt, bevor es klappt.
  int fehlerBisNeuAnmeldung;

  /// Scheitert immer mit diesem Fehler.
  final KontoFehler? dauerhafterFehler;

  /// Der technische Hinweis, den die Meldung mitzeigen soll.
  final String? details;

  final List<Loeschmodus> aufrufe = [];

  @override
  Future<void> loeschen(Loeschmodus modus) async {
    aufrufe.add(modus);

    if (dauerhafterFehler != null) {
      throw KontoException(dauerhafterFehler!, details);
    }
    if (fehlerBisNeuAnmeldung > 0) {
      fehlerBisNeuAnmeldung--;
      throw const KontoException(KontoFehler.neuAnmelden);
    }
  }
}

/// Startet die App in den Einstellungen, mit einem echten Konto.
Future<(ProviderContainer, _DienstAttrappe, FakeAuthRepository)> _einstellungen(
  WidgetTester tester, {
  _DienstAttrappe? dienst,
  bool alsGast = false,
}) async {
  final attrappe = dienst ?? _DienstAttrappe();
  // Beide Anmeldearten laufen durch denselben Ablauf – und genau das war
  // die Frage beim Gerätetest (DECISIONS 93).
  final anmeldung = FakeAuthRepository(
    nutzer: alsGast
        ? const TrueGlowNutzer(uid: 'gast1', anonym: true)
        : const TrueGlowNutzer(
            uid: 'u1',
            anonym: false,
            email: 'jemand@example.com',
            anzeigename: 'Jemand',
          ),
  );

  final container = await appMitDashboard(
    tester,
    anmeldung: anmeldung,
    zusatz: [kontoDienstProvider.overrideWithValue(attrappe)],
  );

  container.read(routerProvider).go(Routes.settings);
  await tester.pumpAndSettle();

  return (container, attrappe, anmeldung);
}

Future<void> _bestaetigen(WidgetTester tester, String knopf) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, knopf),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  hiveImTest();

  testWidgets('die Einstellungen bieten beide Loeschwege getrennt an',
      (tester) async {
    handyGroesse(tester, hoehe: 3000);
    await _einstellungen(tester);

    expect(find.text(texte.einstellungenDatenLoeschen), findsOneWidget);
    expect(find.text(texte.einstellungenKontoLoeschen), findsOneWidget);
  });

  testWidgets('"Daten löschen" raeumt die Cloud und behaelt das Konto',
      (tester) async {
    handyGroesse(tester, hoehe: 3000);
    final (_, dienst, anmeldung) = await _einstellungen(tester);

    await tester.tap(find.text(texte.einstellungenDatenLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Löschen');

    expect(dienst.aufrufe, [Loeschmodus.nurDaten]);
    expect(anmeldung.aktuell, isNotNull, reason: 'Konto bleibt bestehen');
  });

  testWidgets('"Konto löschen" meldet danach ab', (tester) async {
    handyGroesse(tester, hoehe: 3000);
    final (_, dienst, anmeldung) = await _einstellungen(tester);

    await tester.tap(find.text(texte.einstellungenKontoLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Konto löschen');

    expect(dienst.aufrufe, [Loeschmodus.kontoKomplett]);
    expect(anmeldung.aktuell, isNull);
  });

  testWidgets('verlangt die Function eine frische Anmeldung, wird genau '
      'einmal nachgefasst', (tester) async {
    handyGroesse(tester, hoehe: 3000);
    final (_, dienst, anmeldung) = await _einstellungen(
      tester,
      dienst: _DienstAttrappe(fehlerBisNeuAnmeldung: 1),
    );

    await tester.tap(find.text(texte.einstellungenKontoLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Konto löschen');

    expect(anmeldung.erneutBestaetigt, isTrue);
    expect(dienst.aufrufe, [
      Loeschmodus.kontoKomplett,
      Loeschmodus.kontoKomplett,
    ]);
    expect(anmeldung.aktuell, isNull);
  });

  testWidgets('scheitert die Cloud, bleibt lokal alles stehen', (tester) async {
    // Ein halbes Loeschen waere schlimmer als keins: Der Nutzer glaubt, es
    // sei erledigt, und seine Daten liegen weiter in der Cloud.
    handyGroesse(tester, hoehe: 3000);
    final (container, dienst, _) = await _einstellungen(
      tester,
      dienst: _DienstAttrappe(dauerhafterFehler: KontoFehler.keinInternet),
    );

    await tester.tap(find.text(texte.einstellungenDatenLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Löschen');

    expect(dienst.aufrufe, [Loeschmodus.nurDaten]);
    expect(
      container.read(onboardingControllerProvider).abgeschlossen,
      isTrue,
      reason: 'lokaler Bestand unangetastet',
    );
    expect(find.textContaining(KontoFehler.keinInternet.titel(texte)), findsOneWidget);
  });

  testWidgets('ohne Backend laeuft die lokale Loeschung trotzdem',
      (tester) async {
    // Der Demo-Modus hat keinen Loeschdienst – die Aktion darf trotzdem nicht
    // ins Leere laufen.
    handyGroesse(tester, hoehe: 3000);
    final container = await appMitDashboard(
      tester,
      zusatz: [kontoDienstProvider.overrideWithValue(null)],
    );
    container.read(routerProvider).go(Routes.settings);
    await tester.pumpAndSettle();

    await tester.tap(find.text(texte.einstellungenDatenLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Löschen');

    expect(
      container.read(onboardingControllerProvider).abgeschlossen,
      isFalse,
      reason: 'lokal geleert',
    );
  });

  testWidgets('als Gast angemeldet loescht das Konto genauso',
      (tester) async {
    // Die Vermutung beim Gerätetest war, das anonyme Konto sei die Ursache.
    // War es nicht – aber geprüft gehört es trotzdem (DECISIONS 93).
    handyGroesse(tester, hoehe: 3000);
    final (container, dienst, anmeldung) =
        await _einstellungen(tester, alsGast: true);

    await tester.tap(find.text(texte.einstellungenKontoLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Konto löschen');

    expect(dienst.aufrufe, [Loeschmodus.kontoKomplett]);
    expect(anmeldung.aktuell, isNull);
    expect(container.read(routerProvider).state.uri.path, Routes.login);
  });

  testWidgets('und landet auch mit echtem Konto bei der Anmeldung',
      (tester) async {
    handyGroesse(tester, hoehe: 3000);
    final (container, _, _) = await _einstellungen(tester);

    await tester.tap(find.text(texte.einstellungenKontoLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Konto löschen');

    expect(container.read(routerProvider).state.uri.path, Routes.login);
  });

  testWidgets('das Aufraeumen braucht gar keinen Bildschirm', (tester) async {
    // Der eigentliche Befund vom 01.09.2026: Das Aufräumen hing am
    // Einstellungs-Bildschirm. Verschwand der mittendrin, brach es mit
    // „Cannot use ref after the widget was disposed" ab – und das Abmelden,
    // das ganz am Ende stand, fand nie statt.
    //
    // Deshalb hier ohne jedes Widget: Läuft es am nackten Container durch,
    // kann kein Bildschirm es mehr abwürgen.
    final anmeldung = FakeAuthRepository(
      nutzer: const TrueGlowNutzer(uid: 'u1', anonym: false),
    );
    final container = ProviderContainer(
      overrides: testOverrides(anmeldung: anmeldung),
    );
    addTearDown(container.dispose);

    container.read(onboardingControllerProvider.notifier)
      ..setAlter(Altersbereich.a25bis34)
      ..abschliessen();
    expect(container.read(onboardingControllerProvider).abgeschlossen, isTrue);

    await container.read(aufraeumenNachLoeschenProvider)(kontoWeg: true);

    expect(anmeldung.aktuell, isNull, reason: 'abgemeldet');
    expect(container.read(onboardingControllerProvider).abgeschlossen, isFalse);
  });

  testWidgets('ein unerwarteter Fehler nennt seinen Namen', (tester) async {
    // „Etwas ist schiefgelaufen" war die Meldung, mit der die kaputte
    // Kontolöschung tagelang unentdeckt blieb.
    handyGroesse(tester, hoehe: 3000);
    await _einstellungen(
      tester,
      dienst: _DienstAttrappe(
        dauerhafterFehler: KontoFehler.fehlgeschlagen,
        details: 'internal: null',
      ),
    );

    await tester.tap(find.text(texte.einstellungenKontoLoeschen));
    await tester.pumpAndSettle();
    await _bestaetigen(tester, 'Konto löschen');

    expect(
      find.textContaining(texte.kontoFehlgeschlagenTitel),
      findsOneWidget,
    );
    expect(find.textContaining('internal'), findsOneWidget);
  });

  group('Fehlerabbildung', () {
    test('jeder Fall hat Titel und Tipp', () {
      for (final fehler in KontoFehler.values) {
        expect(fehler.titel(texte), isNotEmpty);
        expect(fehler.tipp(texte), isNotEmpty);
      }
    });

    test('die Modi heissen so, wie die Function sie erwartet', () {
      expect(Loeschmodus.nurDaten.wert, 'daten');
      expect(Loeschmodus.kontoKomplett.wert, 'konto');
    });
  });
}
