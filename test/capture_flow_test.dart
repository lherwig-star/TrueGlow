import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/app_strings.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/features/capture/logic/aufnahme_flow.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/capture/models/photo_check_result.dart';
import 'package:trueglow/features/capture/ui/schritte/foto_schritt_ansicht.dart';
import 'package:trueglow/features/capture/ui/widgets/silhouette_overlay.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';

import 'hilfen.dart';

CapturedPhoto _foto(AufnahmeTyp typ) => CapturedPhoto(
      typ: typ,
      pfad: '/tmp/${typ.name}.jpg',
      breite: 768,
      hoehe: 1024,
      groesseInBytes: 120000,
    );

CaptureState _mit(List<AufnahmeTyp> typen) =>
    CaptureState(fotos: {for (final t in typen) t: _foto(t)});

void main() {
  group('CaptureState', () {
    test('merkt sich Aufnahmen je Typ', () {
      const leer = CaptureState();
      expect(leer.hat(AufnahmeTyp.basisFrontal), isFalse);

      final mitFrontal = _mit([AufnahmeTyp.basisFrontal]);
      expect(mitFrontal.hat(AufnahmeTyp.basisFrontal), isTrue);
      expect(mitFrontal.hat(AufnahmeTyp.basisProfilLinks), isFalse);
      expect(mitFrontal.foto(AufnahmeTyp.basisFrontal)?.breite, 768);
    });

    test('vollstaendig erst, wenn alle Pflichtaufnahmen stehen', () {
      final pflicht = pflichtAufnahmen({AnalyseModul.basis});
      expect(_mit([AufnahmeTyp.basisFrontal]).vollstaendig(pflicht), isFalse);
      expect(_mit(pflicht.toList()).vollstaendig(pflicht), isTrue);
    });

    test('zaehlt vorhandene Aufnahmen einer Auswahl', () {
      final zustand = _mit([
        AufnahmeTyp.basisFrontal,
        AufnahmeTyp.basisProfilLinks,
      ]);
      expect(zustand.anzahlVon(AnalyseModul.basis.aufnahmen.toSet()), 2);
    });
  });

  group('Aufnahme-Flow', () {
    test('Basis allein: Lichtcheck plus vier Aufnahmen', () {
      final flow = baueAufnahmeFlow({AnalyseModul.basis});

      expect(flow.first, isA<LichtCheckSchritt>());
      expect(flow.whereType<FotoSchritt>().length, 4);
      expect(flow.length, 5);
    });

    test('Figur ergaenzt zwei Aufnahmen und das Formular', () {
      final flow = baueAufnahmeFlow(
        {AnalyseModul.basis, AnalyseModul.figurPassform},
      );

      expect(flow.whereType<FotoSchritt>().length, 6);
      expect(flow.whereType<FigurFormularSchritt>().length, 1);
      // Das Formular kommt nach den Ganzkoerper-Fotos.
      expect(flow.last, isA<FigurFormularSchritt>());
    });

    test('Haut bekommt eine Hinweisseite vor der Aufnahme', () {
      final flow = baueAufnahmeFlow(
        {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );

      final hinweisIndex = flow.indexWhere((s) => s is ModulHinweisSchritt);
      final fotoIndex = flow.indexWhere(
        (s) => s is FotoSchritt && s.typ == AufnahmeTyp.hautNahaufnahme,
      );

      expect(hinweisIndex, greaterThan(-1));
      expect(hinweisIndex, lessThan(fotoIndex));
    });

    test('Stil endet mit dem Fragebogen', () {
      final flow = baueAufnahmeFlow(
        {AnalyseModul.basis, AnalyseModul.stilKleiderschrank},
      );
      expect(flow.last, isA<StilFragebogenSchritt>());
    });

    test('nur-Modus laesst die Basis weg', () {
      final flow = baueAufnahmeFlow(
        {AnalyseModul.basis, AnalyseModul.zaehneLaecheln},
        nur: AnalyseModul.zaehneLaecheln,
      );

      final fotos = flow.whereType<FotoSchritt>().map((s) => s.typ).toList();
      expect(fotos, [AufnahmeTyp.zaehneLaecheln]);
      // Der Lichtcheck bleibt, es wird ja wieder fotografiert.
      expect(flow.first, isA<LichtCheckSchritt>());
    });

    test('optionale Aufnahmen zaehlen nicht als Pflicht', () {
      final alle = benoetigteAufnahmen({AnalyseModul.stilKleiderschrank});
      final pflicht = pflichtAufnahmen({AnalyseModul.stilKleiderschrank});

      expect(alle, contains(AufnahmeTyp.stilOutfitDrei));
      expect(pflicht, isNot(contains(AufnahmeTyp.stilOutfitDrei)));
      expect(pflicht.length, alle.length - 1);
    });

    test('Fortschritt zaehlt nur die Schritte der gewaehlten Module', () {
      final klein = baueAufnahmeFlow({AnalyseModul.basis});
      final gross = baueAufnahmeFlow(AnalyseModul.values.toSet());
      expect(gross.length, greaterThan(klein.length));
    });
  });

  group('Pruefprofile', () {
    test('Portraits verlangen ein Gesicht, Ganzkoerper und Outfit nicht', () {
      expect(AufnahmeTyp.basisFrontal.pruefung.gesichtPflicht, isTrue);
      expect(AufnahmeTyp.hautNahaufnahme.pruefung.gesichtPflicht, isTrue);
      expect(
        AufnahmeTyp.figurGanzkoerperFrontal.pruefung.gesichtPflicht,
        isFalse,
      );
      expect(AufnahmeTyp.stilOutfitEins.pruefung.gesichtPflicht, isFalse);
    });

    test('ohne Gesichtsbezug laeuft auch keine Live-Hilfe', () {
      expect(AufnahmeTyp.basisFrontal.mitLiveHilfe, isTrue);
      expect(AufnahmeTyp.figurGanzkoerperFrontal.mitLiveHilfe, isFalse);
      expect(AufnahmeTyp.stilOutfitEins.mitLiveHilfe, isFalse);
    });

    test('jede Aufnahme gehoert zu genau einem Modul', () {
      for (final modul in AnalyseModul.values) {
        for (final typ in modul.aufnahmen) {
          expect(typ.modul, modul);
        }
      }
      final summe = AnalyseModul.values
          .fold(0, (n, m) => n + m.aufnahmen.length);
      expect(summe, AufnahmeTyp.values.length);
    });
  });

  group('PhotoProblem', () {
    test('jeder Fehlerfall hat Titel und konkreten Tipp', () {
      for (final problem in PhotoProblem.values) {
        expect(problem.titel, isNotEmpty);
        expect(problem.tipp, isNotEmpty);
      }
    });
  });

  testWidgets('Foto-Schritt zeigt Label, Hinweis und beide Quellen',
      (tester) async {
    handyGroesse(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: MaterialApp(
          // Die Widgets lesen ihre Farben aus der AppColors-Extension, die
          // nur an den App-Themes haengt.
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: FotoSchrittAnsicht(typ: AufnahmeTyp.basisFrontal),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AufnahmeTyp.basisFrontal.label), findsOneWidget);
    expect(find.text(AufnahmeTyp.basisFrontal.hinweis), findsOneWidget);
    expect(find.text(S.fotoKamera), findsOneWidget);
    expect(find.text(S.fotoGalerie), findsOneWidget);
  });

  testWidgets('Fehlermeldung erscheint mit Titel und Tipp', (tester) async {
    handyGroesse(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: FotoSchrittAnsicht(typ: AufnahmeTyp.basisFrontal),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FotoSchrittAnsicht)),
    );
    // Zustand direkt setzen – der echte Check braucht Kamera und ML Kit.
    container.read(captureControllerProvider.notifier).setzeZustand(
          const CaptureState(problem: PhotoProblem.zuKlein),
        );
    await tester.pumpAndSettle();

    expect(find.text(PhotoProblem.zuKlein.titel), findsOneWidget);
    expect(find.text(PhotoProblem.zuKlein.tipp), findsOneWidget);
  });

  group('Silhouetten', () {
    for (final overlay in Overlaytyp.values) {
      testWidgets('$overlay zeichnet ohne Fehler', (tester) async {
        handyGroesse(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SilhouetteOverlay(overlay: overlay),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    test('jedes Profil hat eine eindeutige Blickrichtung', () {
      // Linkes Profil heisst: linke Gesichtshaelfte zur Kamera. In der
      // gespiegelten Frontkamera-Vorschau zeigt die Nase dann nach rechts.
      expect(
        AufnahmeTyp.basisProfilLinks.overlay,
        Overlaytyp.profilNaseRechts,
      );
      expect(
        AufnahmeTyp.basisProfilRechts.overlay,
        Overlaytyp.profilNaseLinks,
      );
      expect(AufnahmeTyp.basisWinkel45.overlay, Overlaytyp.winkel45);
    });

    test('die Profil-Hinweise nennen Drehrichtung und Gesichtshaelfte', () {
      expect(
        AufnahmeTyp.basisProfilLinks.hinweis,
        allOf(contains('nach rechts'), contains('linke Gesichtshälfte')),
      );
      expect(
        AufnahmeTyp.basisProfilRechts.hinweis,
        allOf(contains('nach links'), contains('rechte Gesichtshälfte')),
      );
    });
  });
}
