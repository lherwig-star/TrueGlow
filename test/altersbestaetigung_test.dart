import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/widgets/section_card.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/analysis_service.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/consent/logic/einwilligung_controller.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

import 'hilfen.dart';

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
  group('Onboarding fragt nicht mehr nach unter 18', () {
    test('der Altersbereich beginnt bei 18', () {
      expect(
        Altersbereich.values.map((a) => a.name),
        ['a18bis24', 'a25bis34', 'a35bis44', 'ab45'],
      );
      expect(Altersbereich.values.first.label, '18–24');
    });

    test('ein gespeicherter Altwert faellt heraus statt durchzurutschen', () {
      // Bestandsdaten aus der Zeit vor der 18+-Entscheidung.
      final profil = OnboardingProfile.fromJson(const {
        'alter': 'unter18',
        'abgeschlossen': true,
      });

      expect(profil.alter, isNull);
      expect(profil.abgeschlossen, isTrue);
    });
  });

  group('Nachweis', () {
    test('die Altersbestaetigung wird wie eine Einwilligung protokolliert', () {
      final ctrl = EinwilligungController(speicherAttrappe());

      ctrl.setzen(
        Einwilligungsart.mindestalter,
        erteilt: true,
        kanal: Einwilligungskanal.onboarding,
        zeitpunkt: DateTime.utc(2026, 8, 24, 12),
      );

      final eintrag = ctrl.state.eintrag(Einwilligungsart.mindestalter)!;
      expect(eintrag.zeitpunkt, DateTime.utc(2026, 8, 24, 12));
      expect(eintrag.textversion, isNotEmpty);
      expect(eintrag.kanal, Einwilligungskanal.onboarding);
    });

    test('offene Punkte werden als gefragt und abgelehnt vermerkt', () {
      // Sonst schickt der Router dieselbe Person bei jedem Start erneut auf
      // den Nachtrags-Screen.
      final ctrl = EinwilligungController(speicherAttrappe());
      ctrl.setzen(
        Einwilligungsart.nutzung,
        erteilt: true,
        kanal: Einwilligungskanal.onboarding,
      );

      ctrl.offeneAlsGefragtVermerken();

      for (final art in Einwilligungsart.values) {
        expect(ctrl.state.wurdeGefragt(art), isTrue, reason: art.name);
      }
      expect(
        ctrl.state.eintrag(Einwilligungsart.mindestalter)!.erteilt,
        isFalse,
      );
    });

    test('ein bereits erteilter Punkt wird nicht ueberschrieben', () {
      final ctrl = EinwilligungController(speicherAttrappe());
      ctrl.setzen(
        Einwilligungsart.mindestalter,
        erteilt: true,
        kanal: Einwilligungskanal.onboarding,
      );

      ctrl.offeneAlsGefragtVermerken();

      expect(
        ctrl.state.eintrag(Einwilligungsart.mindestalter)!.erteilt,
        isTrue,
      );
    });
  });

  group('Analyse-Gate', () {
    testWidgets('ohne Altersbestaetigung startet keine Analyse',
        (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final container = await appMitDashboard(tester);
      einwilligungErteilen(container, mindestalter: false);

      container
          .read(captureControllerProvider.notifier)
          .setzeZustand(_basisFotos());
      await container.read(analysisControllerProvider.notifier).starten();

      final zustand = container.read(analysisControllerProvider);
      expect(zustand, isA<AnalyseFehlgeschlagen>());
      expect(
        (zustand as AnalyseFehlgeschlagen).fehler,
        AnalysisFehler.einwilligungFehlt,
      );
      expect(container.read(analysenProvider), isEmpty);
    });

    testWidgets('der Analyse-Flow fuehrt auf den Hinweis statt in die Wand',
        (tester) async {
      handyGroesse(tester, hoehe: 2000);
      final container = await appMitDashboard(tester);
      einwilligungErteilen(container, mindestalter: false);

      container.read(routerProvider).go(Routes.module);
      await tester.pumpAndSettle();

      expect(find.text('Nur für Erwachsene'), findsOneWidget);
      expect(find.text('Zurück zum Dashboard'), findsOneWidget);
      // Der Weiter-Knopf bleibt gesperrt, solange nichts bestaetigt ist.
      final weiter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Weiter zur Analyse'),
      );
      expect(weiter.onPressed, isNull);
    });

    testWidgets('nach der Bestaetigung geht es zum urspruenglichen Ziel',
        (tester) async {
      handyGroesse(tester, hoehe: 2000);
      final container = await appMitDashboard(tester);
      einwilligungErteilen(container, mindestalter: false);

      container.read(routerProvider).go(Routes.module);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text(Einwilligungsart.mindestalter.titel),
            matching: find.byType(SectionCard),
          ),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Weiter zur Analyse'));
      await tester.pumpAndSettle();

      expect(find.text('Nur für Erwachsene'), findsNothing);
      expect(container.read(volljaehrigBestaetigtProvider), isTrue);
    });

    testWidgets('der uebrige Teil der App bleibt offen', (tester) async {
      // Kein Analyse-Flow heisst nicht: keine App. Plan, Checkliste und
      // Einstellungen muessen weiter erreichbar sein.
      handyGroesse(tester, hoehe: 2000);
      final container = await appMitDashboard(tester);
      einwilligungErteilen(container, mindestalter: false);

      container.read(routerProvider).go(Routes.plan);
      await tester.pumpAndSettle();
      expect(find.text('Nur für Erwachsene'), findsNothing);

      container.read(routerProvider).go(Routes.settings);
      await tester.pumpAndSettle();
      expect(find.text('Nur für Erwachsene'), findsNothing);
    });
  });

  group('Bestandsnutzer', () {
    testWidgets('werden einmalig nach dem Alter gefragt', (tester) async {
      handyGroesse(tester, hoehe: 2400);
      final container = await appMitDashboard(tester);

      // Zustand aus der Zeit vor der 18+-Entscheidung: Einwilligungen da,
      // Altersfrage nie gestellt.
      final ctrl = container.read(einwilligungControllerProvider.notifier)
        ..zuruecksetzen();
      for (final art in [Einwilligungsart.nutzung, Einwilligungsart.fotoKi]) {
        ctrl.setzen(art, erteilt: true, kanal: Einwilligungskanal.onboarding);
      }

      expect(container.read(nachtragNoetigProvider), isTrue);

      container.read(routerProvider).go(Routes.home);
      await tester.pumpAndSettle();

      expect(find.text(Einwilligungsart.mindestalter.titel), findsOneWidget);

      // Wer nicht bestaetigt, kommt trotzdem weiter – und wird nicht wieder
      // hierhin geschickt.
      await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
      await tester.pumpAndSettle();

      expect(container.read(nachtragNoetigProvider), isFalse);
      expect(container.read(volljaehrigBestaetigtProvider), isFalse);
      expect(find.text(Einwilligungsart.mindestalter.titel), findsNothing);
    });
  });
}
