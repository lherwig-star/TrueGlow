import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/cloud/cloud_modell.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/hive_service.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/core/widgets/section_card.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/analysis_service.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/consent/logic/einwilligung_controller.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/legal/logic/rechtstexte.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

EinwilligungController _controller([KeyValueStore? store]) =>
    EinwilligungController(store ?? MemoryStore());

void main() {
  group('Nachweis', () {
    test('haelt Zeitpunkt, Textversion und Kanal fest', () {
      final ctrl = _controller();

      ctrl.setzen(
        Einwilligungsart.fotoKi,
        erteilt: true,
        kanal: Einwilligungskanal.onboarding,
        zeitpunkt: DateTime.utc(2026, 8, 24, 9, 30),
      );

      final eintrag = ctrl.state.eintrag(Einwilligungsart.fotoKi)!;
      expect(eintrag.erteilt, isTrue);
      expect(eintrag.zeitpunkt, DateTime.utc(2026, 8, 24, 9, 30));
      expect(eintrag.textversion, Rechtstexte.version);
      expect(eintrag.kanal, Einwilligungskanal.onboarding);
    });

    test('ueberlebt einen Neustart', () {
      final store = MemoryStore();
      _controller(store).setzen(
        Einwilligungsart.nutzung,
        erteilt: true,
        kanal: Einwilligungskanal.onboarding,
        zeitpunkt: DateTime.utc(2026, 8, 1),
      );

      final frisch = _controller(store);
      expect(
        frisch.state.eintrag(Einwilligungsart.nutzung)?.zeitpunkt,
        DateTime.utc(2026, 8, 1),
      );
    });

    test('ein Widerruf bleibt als Eintrag stehen', () {
      // "Nie gefragt" und "ausdruecklich widerrufen" sind zwei verschiedene
      // Zustaende – nur der zweite ist ein Nachweis.
      final ctrl = _controller();
      ctrl.setzen(
        Einwilligungsart.fotoKi,
        erteilt: true,
        kanal: Einwilligungskanal.onboarding,
      );

      ctrl.widerrufen(Einwilligungsart.fotoKi);

      expect(ctrl.state.wurdeGefragt(Einwilligungsart.fotoKi), isTrue);
      expect(ctrl.state.gilt(Einwilligungsart.fotoKi, Rechtstexte.version),
          isFalse);
      expect(
        ctrl.state.eintrag(Einwilligungsart.fotoKi)!.kanal,
        Einwilligungskanal.einstellungen,
      );
    });

    test('eine Zustimmung zu einer alten Textfassung gilt nicht mehr', () {
      final ctrl = _controller();
      ctrl.setzen(
        Einwilligungsart.nutzung,
        erteilt: true,
        kanal: Einwilligungskanal.onboarding,
      );

      expect(ctrl.state.gilt(Einwilligungsart.nutzung, Rechtstexte.version),
          isTrue);
      expect(ctrl.state.gilt(Einwilligungsart.nutzung, '99'), isFalse);
    });

    test('ein kaputter Eintrag gilt nicht als Zustimmung', () {
      final store = MemoryStore()
        ..put(CloudModell.keyEinwilligungen, '{kaputt');

      expect(_controller(store).state.eintraege, isEmpty);
    });

    test('liest und schreibt sich verlustfrei', () {
      final original = Einwilligungsstand.leer.mit(
        Einwilligung(
          art: Einwilligungsart.fotoKi,
          erteilt: false,
          zeitpunkt: DateTime.utc(2026, 8, 24),
          textversion: '3',
          kanal: Einwilligungskanal.einstellungen,
        ),
      );

      final gelesen = Einwilligungsstand.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(gelesen.eintrag(Einwilligungsart.fotoKi),
          original.eintrag(Einwilligungsart.fotoKi));
    });
  });

  group('Ablage', () {
    test('landet im Profil-Dokument der Cloud', () {
      // Die Roadmap verlangt den Nachweis lokal *und* im profil-Dokument.
      expect(
        CloudModell.ziel(
          HiveService.boxEinstellungen,
          CloudModell.keyEinwilligungen,
        ),
        const CloudZiel(CloudModell.dokProfil, 'einwilligungen'),
      );
      expect(
        CloudModell.lokal(CloudModell.dokProfil, 'einwilligungen'),
        const LokalesZiel(
          HiveService.boxEinstellungen,
          CloudModell.keyEinwilligungen,
        ),
      );
    });
  });

  group('Analyse-Gate', () {
    /// Alle Basis-Aufnahmen als bereits geprueft.
    CaptureState basisFotos() => CaptureState(
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

    testWidgets('ohne Foto-Einwilligung startet keine Analyse', (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final container = await appMitDashboard(tester);
      einwilligungErteilen(container, fotoKi: false);

      container
          .read(captureControllerProvider.notifier)
          .setzeZustand(basisFotos());
      await container.read(analysisControllerProvider.notifier).starten();

      final zustand = container.read(analysisControllerProvider);
      expect(zustand, isA<AnalyseFehlgeschlagen>());
      expect(
        (zustand as AnalyseFehlgeschlagen).fehler,
        AnalysisFehler.einwilligungFehlt,
      );
      // Nichts gespeichert – der Aufruf ist gar nicht erst losgelaufen.
      expect(container.read(analysenProvider), isEmpty);
    });

    testWidgets('mit Einwilligung laeuft sie durch', (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final container = await appMitDashboard(tester);

      container
          .read(captureControllerProvider.notifier)
          .setzeZustand(basisFotos());
      final laeuft =
          container.read(analysisControllerProvider.notifier).starten();
      await tester.pump(AnalysisConfig.mockDauer);
      await laeuft;

      expect(container.read(analysisControllerProvider), isA<AnalyseFertig>());
    });
  });

  group('Migration der alten Sammel-Checkbox', () {
    testWidgets('fuehrt Bestandsnutzer einmalig durch die neue Einwilligung',
        (tester) async {
      handyGroesse(tester, hoehe: 2000);

      await tester.pumpWidget(
        ProviderScope(overrides: testOverrides(), child: const TrueGlowApp()),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TrueGlowApp)),
      );

      // Der Zustand eines Nutzers aus der Zeit vor Phase 2.2: Onboarding
      // abgeschlossen, alter Sammel-Haken gesetzt, kein Nachweis.
      final onboarding = container.read(onboardingControllerProvider.notifier);
      onboarding.setAlter(Altersbereich.a25bis34);
      onboarding.setBudget(Budget.mittel);
      onboarding.setZeit(Zeitbudget.mittel);
      onboarding.toggleFokus(Fokusbereich.haut);
      onboarding.setZustimmung(true);
      onboarding.abschliessen();

      expect(container.read(ausAlterZustimmungProvider), isTrue);

      container.read(routerProvider).go(Routes.home);
      await tester.pumpAndSettle();

      // Statt aufs Dashboard geht es auf den Nachtrags-Screen.
      expect(find.text('Wir haben nachgeschärft'), findsOneWidget);
      expect(find.text(Einwilligungsart.fotoKi.titel(texte)), findsOneWidget);

      // Pflicht ankreuzen, dann ist der Weg frei.
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
      await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
      await tester.pumpAndSettle();

      expect(find.text('Wir haben nachgeschärft'), findsNothing);
      expect(container.read(ausAlterZustimmungProvider), isFalse);
    });
  });
}
