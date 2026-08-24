import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/app_strings.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/features/capture/logic/aufnahme_flow.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/logic/image_quality_service.dart';
import 'package:trueglow/features/capture/logic/live_face_guide.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/capture/models/photo_check_result.dart';
import 'package:trueglow/features/capture/ui/capture_flow_screen.dart';
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

    test('Haut bringt keine eigene Aufnahme mehr mit', () {
      // Die Hautton-Nahaufnahme ist entfallen; ausgewertet wird das
      // Frontalfoto der Basis (DECISIONS.md, "Hautton ohne eigenes Foto").
      final flow = baueAufnahmeFlow(
        {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );

      final fotos = flow.whereType<FotoSchritt>().map((s) => s.typ).toSet();
      expect(fotos, equals(AnalyseModul.basis.aufnahmen.toSet()));
    });

    test('Haut behaelt seine Hinweisseite, sonst fehlt das Modul im Flow', () {
      // Ohne diese Seite waere ein gewaehltes Modul im Aufnahme-Flow gar nicht
      // sichtbar – und der Nutzer wuerde sich fragen, ob die Auswahl griff.
      final flow = baueAufnahmeFlow(
        {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );

      expect(
        flow.whereType<ModulHinweisSchritt>().map((s) => s.modul),
        contains(AnalyseModul.hautFarbtyp),
      );
    });

    test('Haut allein ergibt einen Flow ohne Fotos und ohne Lichtcheck', () {
      // Der Weg ueber "Analyse erweitern": Die Basis-Fotos liegen vor, fuer
      // Haut kommt nichts Neues dazu. Der Flow darf trotzdem nicht leer sein,
      // sonst zeigt der Screen seine Ausweichseite statt weiterzufuehren.
      final flow = baueAufnahmeFlow(
        AnalyseModul.values.toSet(),
        nur: AnalyseModul.hautFarbtyp,
      );

      expect(flow, isNotEmpty);
      expect(flow.whereType<FotoSchritt>(), isEmpty);
      // Kein Foto, also auch keine Lichtcheckliste.
      expect(flow.whereType<LichtCheckSchritt>(), isEmpty);
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
      expect(AufnahmeTyp.zaehneLaecheln.pruefung.gesichtPflicht, isTrue);
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

    test('nur die Ganzkoerperfotos loesen selbst aus', () {
      // Bei allen anderen haelt man das Geraet in der Hand – ein Automatismus
      // waere dort nur ein Foto zum falschen Zeitpunkt.
      final automatisch =
          AufnahmeTyp.values.where((t) => t.autoAusloeser).toSet();

      expect(
        automatisch,
        {
          AufnahmeTyp.figurGanzkoerperFrontal,
          AufnahmeTyp.figurGanzkoerperSeitlich,
        },
      );
    });

    test('ein Bildstrom laeuft nur, wo etwas erkannt wird', () {
      // Outfit-Fotos brauchen weder Gesicht noch Pose. Liefe der Strom dort
      // trotzdem, kostete er auf schwachen Geraeten Speicher und Waerme fuer
      // nichts.
      for (final typ in AufnahmeTyp.values) {
        expect(
          typ.mitBildstrom,
          typ.mitLiveHilfe || typ.autoAusloeser,
          reason: typ.name,
        );
      }
      expect(AufnahmeTyp.stilOutfitEins.mitBildstrom, isFalse);
      expect(AufnahmeTyp.figurGanzkoerperFrontal.mitBildstrom, isTrue);
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

  testWidgets('die Foto-Leiste zeigt jede Aufnahme und springt hin',
      (tester) async {
    // Bei bis zu zehn Aufnahmen ist die Leiste der einzige Ort, an dem
    // sichtbar wird, was schon im Kasten ist – und der schnellste Weg zu
    // einem misslungenen Foto zurueck.
    handyGroesse(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const CaptureFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Nur die Basis: Lichtcheck plus vier Fotos.
    final fotos = AnalyseModul.basis.aufnahmen.length;
    expect(find.text('Schritt 1 von ${fotos + 1}'), findsOneWidget);

    // Je ein Platzhalter mit laufender Nummer, noch kein Foto vorhanden.
    for (var i = 1; i <= fotos; i++) {
      expect(find.text('$i'), findsOneWidget);
    }

    // Antippen des dritten Feldes fuehrt zum dritten Foto-Schritt – das ist
    // nach dem Lichtcheck der vierte Schritt insgesamt.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    expect(find.text('Schritt 4 von ${fotos + 1}'), findsOneWidget);
    expect(
      find.text(AnalyseModul.basis.aufnahmen[2].label),
      findsWidgets,
    );
  });

  group('Live-Hinweis Helligkeit', () {
    const guide = LiveFaceGuide();
    const bild = Size(1000, 1000);
    // Ein mittig sitzendes Gesicht mit rund 36 % Flaechenanteil – waere ohne
    // Lichtproblem „perfekt".
    final gutesGesicht = [
      Rect.fromCenter(center: const Offset(500, 500), width: 600, height: 600),
    ];

    test('ohne Helligkeitsangabe bleibt alles wie bisher', () {
      // Auf iOS oder bei unlesbarem Puffer kommt kein Wert – dann darf die
      // Bewertung nicht plötzlich anders ausfallen.
      expect(
        guide.bewerte(gesichter: gutesGesicht, bildGroesse: bild),
        LiveHinweis.perfekt,
      );
    });

    test('zu dunkel schlaegt selbst bei perfekter Haltung durch', () {
      expect(
        guide.bewerte(
          gesichter: gutesGesicht,
          bildGroesse: bild,
          helligkeit: 20,
        ),
        LiveHinweis.zuDunkel,
      );
    });

    test('zu dunkel geht vor „kein Gesicht"', () {
      // Bei Dunkelheit findet ML Kit oft gar nichts. „Niemand im Bild" waere
      // dann irrefuehrend – das Licht ist die Ursache.
      expect(
        guide.bewerte(gesichter: const [], bildGroesse: bild, helligkeit: 20),
        LiveHinweis.zuDunkel,
      );
    });

    test('warnt frueher als der finale Check ablehnt', () {
      // Der Sinn des Hinweises: nachbessern koennen, statt ein Foto zu
      // machen, das der Check anschliessend verwirft.
      expect(
        LiveFaceGuide.minHelligkeit,
        greaterThan(ImageQualityService.minHelligkeit),
      );

      // Genau im Puffer dazwischen: Der Check wuerde es durchlassen, die
      // Vorschau mahnt trotzdem.
      const knapp = ImageQualityService.minHelligkeit + 1;
      expect(
        guide.bewerte(
          gesichter: gutesGesicht,
          bildGroesse: bild,
          helligkeit: knapp,
        ),
        LiveHinweis.zuDunkel,
      );
    });

    test('genug Licht laesst die Haltungshinweise durch', () {
      expect(
        guide.bewerte(
          gesichter: gutesGesicht,
          bildGroesse: bild,
          helligkeit: 200,
        ),
        LiveHinweis.perfekt,
      );
      expect(
        guide.bewerte(
          gesichter: const [],
          bildGroesse: bild,
          helligkeit: 200,
        ),
        LiveHinweis.keinGesicht,
      );
    });

    test('kein Hinweis ohne Text, und nur „perfekt" gibt frei', () {
      for (final hinweis in LiveHinweis.values) {
        expect(hinweis.text, isNotEmpty, reason: '${hinweis.name} ohne Text');
      }
      expect(LiveHinweis.zuDunkel.bereit, isFalse);
    });
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

    test('die beiden Ganzkoerper-Aufnahmen haben eigene Umrisse', () {
      // Frueher teilten sie sich einen Overlaytyp – das seitliche Foto zeigte
      // also eine frontale Figur. Wer sich danach ausrichtet, steht falsch.
      expect(
        AufnahmeTyp.figurGanzkoerperFrontal.overlay,
        Overlaytyp.ganzkoerperFrontal,
      );
      expect(
        AufnahmeTyp.figurGanzkoerperSeitlich.overlay,
        Overlaytyp.ganzkoerperSeitlich,
      );
      expect(
        AufnahmeTyp.figurGanzkoerperFrontal.overlay,
        isNot(AufnahmeTyp.figurGanzkoerperSeitlich.overlay),
      );
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

  group('Hinweis am Frontalfoto', () {
    test('mit Haut-Modul kommt der Lichthinweis dazu', () {
      // Der Zusatz ist das, was vom gestrichenen Hautton-Screen uebrig blieb.
      // Ohne ihn faellt die Anforderung an das Licht ersatzlos weg.
      final text = AufnahmeTyp.basisFrontal.hinweisFuer(
        {AnalyseModul.basis, AnalyseModul.hautFarbtyp},
      );

      expect(text, startsWith(AufnahmeTyp.basisFrontal.hinweis));
      expect(text, contains(AufnahmeTyp.hautLichtZusatz));
    });

    test('ohne Haut-Modul bleibt der Hinweis unveraendert', () {
      // Wer das Modul nicht gebucht hat, soll keine Anforderung lesen, die
      // fuer seine Analyse nichts aendert.
      expect(
        AufnahmeTyp.basisFrontal.hinweisFuer({AnalyseModul.basis}),
        AufnahmeTyp.basisFrontal.hinweis,
      );
    });

    test('andere Aufnahmen bleiben vom Haut-Modul unberuehrt', () {
      for (final typ in AufnahmeTyp.values) {
        if (typ == AufnahmeTyp.basisFrontal) continue;
        expect(
          typ.hinweisFuer({AnalyseModul.basis, AnalyseModul.hautFarbtyp}),
          typ.hinweis,
          reason: '${typ.name} darf den Hautton-Zusatz nicht tragen',
        );
      }
    });
  });
}
