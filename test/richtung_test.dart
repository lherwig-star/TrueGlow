import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/logic/analyse_anfrage.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/direction/logic/direction_controller.dart';
import 'package:trueglow/features/direction/models/richtung.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// Bringt die App an den Punkt nach dem Onboarding und liefert den Container.
Future<ProviderContainer> _appMitDashboard(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(overrides: testOverrides(), child: const TrueGlowApp()),
  );
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(TrueGlowApp)),
  );

  final onboarding = container.read(onboardingControllerProvider.notifier);
  onboarding.setAlter(Altersbereich.a25bis34);
  onboarding.setBudget(Budget.mittel);
  onboarding.setZeit(Zeitbudget.mittel);
  onboarding.setZustimmung(true);
  onboarding.abschliessen();
  einwilligungErteilen(container);

  container.read(routerProvider).go(Routes.home);
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('Richtung (Modell)', () {
    test('ueberlebt den Weg durch JSON', () {
      const original = Richtung(
        ziele: {Richtungsziel.markanter, Richtungsziel.serioeser},
        freitext: 'Ich will im Bewerbungsgespräch souverän wirken.',
      );

      final zurueck = Richtung.fromJson(original.toJson());

      expect(zurueck, original);
      expect(zurueck.sortierteZiele, [
        Richtungsziel.markanter,
        Richtungsziel.serioeser,
      ]);
    });

    test('unbekannte Ziele aus alten Daten fallen weg', () {
      final gelesen = Richtung.fromJson({
        'ziele': ['markanter', 'gibtsNichtMehr'],
        'freitext': 'x',
      });

      expect(gelesen.ziele, {Richtungsziel.markanter});
    });

    test('zu langer Freitext wird auf das Limit geschnitten', () {
      final gelesen = Richtung.fromJson({
        'ziele': const <String>[],
        'freitext': 'a' * (Richtung.maxZeichen + 500),
      });

      expect(gelesen.freitext.length, Richtung.maxZeichen);
    });

    test('leer heisst: keine Chips und kein Text', () {
      expect(Richtung.leer.istLeer, isTrue);
      expect(const Richtung(freitext: '   ').istLeer, isTrue);
      expect(const Richtung(freitext: 'was').istLeer, isFalse);
      expect(const Richtung(ziele: {Richtungsziel.reifer}).istLeer, isFalse);
    });

    test('die Kurzfassung kuerzt lange Texte fuer die Report-Karte', () {
      final lang = Richtung(freitext: 'Wort ' * 100);

      expect(lang.kurzfassung.length, lessThanOrEqualTo(140));
      expect(lang.kurzfassung, endsWith('…'));
      expect(
        const Richtung(freitext: 'Kurz und knapp').kurzfassung,
        'Kurz und knapp',
      );
    });
  });

  group('DirectionController', () {
    test('schreibt jede Aenderung sofort weg und liest sie wieder ein', () {
      final store = MemoryStore();
      final ctrl = DirectionController(store);

      ctrl.umschalten(Richtungsziel.maskuliner);
      ctrl.umschalten(Richtungsziel.sportlicher);
      ctrl.umschalten(Richtungsziel.maskuliner); // wieder abwaehlen
      ctrl.setzeFreitext('Mehr Struktur im Alltag.');

      expect(ctrl.state.ziele, {Richtungsziel.sportlicher});

      // Frischer Controller auf demselben Speicher: gleicher Stand.
      expect(DirectionController(store).state, ctrl.state);
    });

    test('zuruecksetzen loescht die Richtung', () {
      final store = MemoryStore();
      final ctrl = DirectionController(store);

      ctrl.setzeFreitext('weg damit');
      ctrl.zuruecksetzen();

      expect(ctrl.state.istLeer, isTrue);
      expect(DirectionController(store).state.istLeer, isTrue);
    });
  });

  // Der Prompt selbst wird seit dem Proxy-Umbau serverseitig gebaut
  // (functions/src/analyse_prompt.ts, geprueft in functions/test/prompt.test.ts).
  // Hier steht die Client-Haelfte: Was von der Richtung ueberhaupt das Geraet
  // verlaesst.
  group('Anfrage an die Function', () {
    Map<String, dynamic> anfrageMit(Richtung richtung) => AnalyseAnfrage.bauen(
          bilder: const {AufnahmeTyp.basisFrontal: 'AAAA'},
          module: {AnalyseModul.basis},
          onboarding: const OnboardingProfile(),
          eingaben: const ModulEingaben(),
          richtung: richtung,
        );

    test('ohne Richtung geht nichts Zusaetzliches mit', () {
      final richtung = anfrageMit(Richtung.leer)['richtung'] as Map;

      expect(richtung['ziele'], isEmpty);
      expect(richtung['freitext'], isEmpty);
    });

    test('Chips und Freitext landen in der Nutzlast', () {
      final richtung = anfrageMit(
        const Richtung(
          ziele: {Richtungsziel.markanter, Richtungsziel.gepflegter},
          freitext: 'Weniger Bart, mehr Kante.',
        ),
      )['richtung'] as Map;

      // Stabile Enum-Namen, keine fertigen Prompt-Texte: Die Function setzt
      // die Beschriftungen selbst ein und ignoriert alles Unbekannte.
      expect(richtung['ziele'], ['markanter', 'gepflegter']);
      expect(richtung['freitext'], 'Weniger Bart, mehr Kante.');
    });

    test('Ziele gehen in Deklarationsreihenfolge raus', () {
      final richtung = anfrageMit(
        const Richtung(
          ziele: {Richtungsziel.sportlicher, Richtungsziel.maskuliner},
        ),
      )['richtung'] as Map;

      expect(richtung['ziele'], ['maskuliner', 'sportlicher']);
    });

    test('die Nutzlast enthaelt weder Pfade noch den Zustimmungsstatus', () {
      final anfrage = anfrageMit(Richtung.leer);

      expect(anfrage['bilder'], [
        {'typ': 'basisFrontal', 'daten': 'AAAA'},
      ]);
      expect((anfrage['profil'] as Map).keys, ['alter', 'budget', 'zeit', 'fokus']);
    });
  });

  group('Richtung am Ergebnis', () {
    const richtung = Richtung(
      ziele: {Richtungsziel.natuerlicher},
      freitext: 'Nichts Auffälliges.',
    );

    AnalysisResult ergebnis({Richtung mit = Richtung.leer}) => AnalysisResult(
          id: 'a1',
          erstelltAm: DateTime(2026, 8, 22),
          kapitel: const [
            Kapitel(
              modul: AnalyseModul.basis,
              einleitung: 'Text',
              sektionen: [],
              habits: ['x'],
            ),
          ],
          plan: const Plan(
            sofort: ['a'],
            dreissigTage: [],
            langfristig: [],
            taeglicheHabits: [],
          ),
          richtung: mit,
        );

    test('wird mitgespeichert und wieder gelesen', () {
      final zurueck = AnalysisResult.fromJson(ergebnis(mit: richtung).toJson());

      expect(zurueck.richtung, richtung);
    });

    test('alte Analysen ohne Feld laufen ohne Richtung weiter', () {
      final json = ergebnis(mit: richtung).toJson()..remove('richtung');

      expect(AnalysisResult.fromJson(json).richtung.istLeer, isTrue);
    });

    test('ein nachtraeglich ergaenztes Kapitel bringt die neue Richtung mit',
        () {
      final erweitert = ergebnis().mitKapitel(
        const Kapitel(
          modul: AnalyseModul.hautFarbtyp,
          einleitung: 'Haut',
          sektionen: [],
        ),
        richtung: richtung,
      );

      expect(erweitert.richtung, richtung);
      expect(erweitert.kapitel, hasLength(2));
    });
  });

  group('Flow und Report', () {
    testWidgets('die Modul-Auswahl fuehrt in den Richtungs-Schritt',
        (tester) async {
      handyGroesse(tester, hoehe: 2000);
      final container = await _appMitDashboard(tester);

      container.read(routerProvider).push(Routes.module);
      await tester.pumpAndSettle();

      await tester.tap(find.text(texte.moduleStartBasis));
      await tester.pumpAndSettle();

      expect(find.text(texte.richtungUeberschrift), findsOneWidget);
      expect(find.text(texte.flowUeberspringen), findsOneWidget);
    });

    testWidgets('Chips und Freitext landen im Controller', (tester) async {
      handyGroesse(tester, hoehe: 2400);
      final container = await _appMitDashboard(tester);

      container.read(routerProvider).push(Routes.richtung);
      await tester.pumpAndSettle();

      await tester.tap(find.text(Richtungsziel.markanter.label));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Ich will seriöser wirken.',
      );
      await tester.pumpAndSettle();

      final richtung = container.read(directionControllerProvider);
      expect(richtung.ziele, {Richtungsziel.markanter});
      expect(richtung.freitext, 'Ich will seriöser wirken.');
      // Der Zaehler zeigt den Stand an.
      expect(
        find.text('${richtung.freitext.length} / ${Richtung.maxZeichen}'),
        findsOneWidget,
      );
    });

    testWidgets('der Report bietet nach einer Aenderung die Neuberechnung an',
        (tester) async {
      handyGroesse(tester, hoehe: 3000);
      final container = await _appMitDashboard(tester);

      final gespeichert = AnalysisResult(
        id: 'report1',
        erstelltAm: DateTime(2026, 8, 22),
        kapitel: const [
          Kapitel(
            modul: AnalyseModul.basis,
            einleitung: 'Ovale Grundform.',
            sektionen: [],
            habits: ['x'],
          ),
        ],
        plan: const Plan(
          sofort: ['a'],
          dreissigTage: [],
          langfristig: [],
          taeglicheHabits: [],
        ),
        richtung: const Richtung(ziele: {Richtungsziel.gepflegter}),
      );
      await container.read(analysenProvider.notifier).speichern(gespeichert);

      // Gleicher Stand wie im Report: kein Angebot zum Neuberechnen.
      container
          .read(directionControllerProvider.notifier)
          .umschalten(Richtungsziel.gepflegter);
      container.read(routerProvider).push('${Routes.result}/report1');
      await tester.pumpAndSettle();

      expect(find.text(texte.richtungTitel), findsOneWidget);
      expect(find.text(Richtungsziel.gepflegter.label), findsOneWidget);
      expect(find.text(texte.richtungAktualisieren), findsNothing);

      // Richtung aendern -> der Report bietet die Neuberechnung an.
      container
          .read(directionControllerProvider.notifier)
          .umschalten(Richtungsziel.sportlicher);
      await tester.pumpAndSettle();

      expect(find.text(texte.richtungAktualisieren), findsOneWidget);
    });
  });
}
