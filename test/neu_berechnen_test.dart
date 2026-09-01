import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/analysis/logic/neuberechnung.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/home/ui/tabs/analyse_tab.dart';
import 'package:trueglow/features/modules/logic/module_controller.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';

import 'hilfen.dart';

/// „Mit vorhandenen Fotos neu berechnen" – DECISIONS 91.
///
/// Der Weg war mit der Richtungskarte aus dem Report verschwunden. Er steht
/// jetzt im Analyse-Tab, als zweite und leisere Aktion.
void main() {
  hiveImTest();

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

  AnalysisResult report() => AnalysisResult(
        id: 'alt',
        erstelltAm: DateTime(2026, 8, 20),
        // `module` ergibt sich aus den Kapiteln – zwei Kapitel, zwei Bereiche.
        kapitel: const [
          Kapitel(
            modul: AnalyseModul.basis,
            einleitung: 'Ovale Grundform.',
            sektionen: [],
            habits: ['x'],
          ),
          Kapitel(
            modul: AnalyseModul.hautFarbtyp,
            einleitung: 'Warmer Unterton.',
            sektionen: [],
            habits: ['y'],
          ),
        ],
        plan: const Plan(
          sofort: ['a'],
          dreissigTage: [],
          langfristig: [],
          taeglicheHabits: [],
        ),
      );

  Future<ProviderContainer> aufsetzen({
    bool mitReport = true,
    bool mitFotos = true,
  }) async {
    // `testOverrides` und nicht nur `speicherOverrides`: Sonst zieht der
    // Capture-Controller den echten Gesichtserkenner mit, und der
    // stolpert im Test über den fehlenden Plattform-Kanal.
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);

    if (mitReport) {
      await container.read(analysenProvider.notifier).speichern(report());
    }
    if (mitFotos) {
      container
          .read(captureControllerProvider.notifier)
          .setzeZustand(basisFotos());
    }
    return container;
  }

  group('Die Aktion zeigt sich nur, wenn sie etwas kann', () {
    Future<void> zeigeTab(
      WidgetTester tester,
      ProviderContainer container, {
      VoidCallback? onNeuBerechnen,
    }) async {
      handyGroesse(tester, hoehe: 1600);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            AnalyseTab(
              onNeueAnalyse: () {},
              onNeuBerechnen: onNeuBerechnen ?? () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('mit Report und Fotos steht sie da', (tester) async {
      await zeigeTab(tester, await aufsetzen());

      expect(find.text(texte.homeNeuBerechnen), findsOneWidget);
      // Der Preis steht dabei: Ein Weg, der aussieht, als wäre er umsonst,
      // weil keine Kamera aufgeht, wäre eine Falle.
      expect(find.textContaining('Analyse-Lauf'), findsOneWidget);
    });

    testWidgets('ohne Fotos nicht', (tester) async {
      // Es gäbe nichts, womit gerechnet werden könnte.
      await zeigeTab(tester, await aufsetzen(mitFotos: false));

      expect(find.text(texte.homeNeuBerechnen), findsNothing);
    });

    testWidgets('ohne früheren Report auch nicht', (tester) async {
      await zeigeTab(tester, await aufsetzen(mitReport: false));

      expect(find.text(texte.homeNeuBerechnen), findsNothing);
    });

    testWidgets('und ein Tipp löst sie aus', (tester) async {
      var getippt = 0;
      await zeigeTab(
        tester,
        await aufsetzen(),
        onNeuBerechnen: () => getippt++,
      );

      await tester.tap(find.text(texte.homeNeuBerechnen));
      await tester.pumpAndSettle();

      expect(getippt, 1);
    });
  });

  group('Vorbereiten heißt: Fotos behalten', () {
    /// Ein Knopf, der nichts tut, als [neuberechnungVorbereiten] aufzurufen.
    /// Die Funktion braucht einen `WidgetRef`; mehr Bildschirm als diesen
    /// Knopf braucht der Test nicht.
    Future<void> vorbereiten(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(const _Ausloeser()),
        ),
      );
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
    }

    testWidgets('die Aufnahmen bleiben stehen', (tester) async {
      // Der Unterschied zu „Neue Analyse": Die wirft sie weg.
      final container = await aufsetzen();

      await vorbereiten(tester, container);

      expect(container.read(captureControllerProvider).fotos, isNotEmpty);
      expect(container.read(neuberechnungProvider), isTrue);
    });

    testWidgets('die Bereiche des letzten Reports sind vorbelegt',
        (tester) async {
      final container = await aufsetzen();

      await vorbereiten(tester, container);

      expect(
        container.read(moduleControllerProvider).module,
        {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );
    });
  });

  group('Am Ende wartet die Berechnung statt der Kamera', () {
    Future<ProviderContainer> imFlow(
      WidgetTester tester, {
      required bool neuberechnung,
    }) async {
      handyGroesse(tester, hoehe: 2400);
      final container = await appMitDashboard(tester);
      container
          .read(captureControllerProvider.notifier)
          .setzeZustand(basisFotos());
      container.read(neuberechnungProvider.notifier).state = neuberechnung;

      container.read(routerProvider).push(Routes.ausprobieren);
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('„Weiter" führt an der Kamera vorbei', (tester) async {
      final container = await imFlow(tester, neuberechnung: true);

      await tester.tap(find.text(texte.ausprobierenWeiter));
      await tester.pumpAndSettle();

      // Die Berechnung läuft im Test sofort durch und landet beim fertigen
      // Report – geprüft wird, dass die Kamera dazwischen nicht vorkam.
      expect(
        container.read(routerProvider).state.uri.path,
        isNot(Routes.aufnahme),
      );
      expect(container.read(analysenProvider), isNotEmpty);
    });

    testWidgets('und „Überspringen" ebenso', (tester) async {
      final container = await imFlow(tester, neuberechnung: true);

      await tester.tap(find.text(texte.flowUeberspringen));
      await tester.pumpAndSettle();

      expect(
        container.read(routerProvider).state.uri.path,
        isNot(Routes.aufnahme),
      );
      expect(container.read(analysenProvider), isNotEmpty);
    });

    testWidgets('ohne Merker geht es zur Kamera', (tester) async {
      // Der Normalfall darf sich nicht ändern.
      final container = await imFlow(tester, neuberechnung: false);

      await tester.tap(find.text(texte.ausprobierenWeiter));
      await tester.pumpAndSettle();

      expect(
        container.read(routerProvider).state.uri.path,
        Routes.aufnahme,
      );
    });

    testWidgets('und die Berechnung räumt den Merker weg', (tester) async {
      // Sonst führte der nächste reguläre Durchgang ebenfalls an der Kamera
      // vorbei – mit den Fotos von vorletztem Mal.
      final container = await imFlow(tester, neuberechnung: true);

      await tester.tap(find.text(texte.ausprobierenWeiter));
      await tester.pumpAndSettle();

      expect(container.read(neuberechnungProvider), isFalse);
    });
  });
}

class _Ausloeser extends ConsumerWidget {
  const _Ausloeser();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: TextButton(
          onPressed: () => neuberechnungVorbereiten(ref),
          child: const Text('los'),
        ),
      );
}
