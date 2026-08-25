import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/account/logic/konto_dienst.dart';
import 'package:trueglow/features/auth/logic/auth_repository.dart';
import 'package:trueglow/features/auth/models/trueglow_nutzer.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';

import 'hilfen.dart';

/// Loeschdienst ohne Netz: merkt sich die Aufrufe und kann gezielt scheitern.
class _DienstAttrappe implements KontoDienst {
  _DienstAttrappe({this.fehlerBisNeuAnmeldung = 0, this.dauerhafterFehler});

  /// So oft wird „bitte neu anmelden" verlangt, bevor es klappt.
  int fehlerBisNeuAnmeldung;

  /// Scheitert immer mit diesem Fehler.
  final KontoFehler? dauerhafterFehler;

  final List<Loeschmodus> aufrufe = [];

  @override
  Future<void> loeschen(Loeschmodus modus) async {
    aufrufe.add(modus);

    if (dauerhafterFehler != null) {
      throw KontoException(dauerhafterFehler!);
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
}) async {
  final attrappe = dienst ?? _DienstAttrappe();
  final anmeldung = FakeAuthRepository(
    nutzer: const TrueGlowNutzer(
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
