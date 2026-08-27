import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analyse_modus.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/result/logic/bilder_dienst.dart';
import 'package:trueglow/features/result/models/beispielbild.dart';
import 'package:trueglow/features/result/ui/widgets/beispielbilder.dart';
import 'package:trueglow/main.dart';

import 'hilfen.dart';

/// Beispielbilder unter den Vorschlaegen – DECISIONS 69.
///
/// Der Suchbegriff ist das einzige Stueck, das vom Modell kommt. Er wird nie
/// angezeigt, entscheidet aber darueber, welche Fotos unter dem Vorschlag
/// stehen. Hier steht, was die App daraus liest.
void main() {
  AnalysisResult lies(String antwort) => AnalysisResult.vonApi(
        JsonExtractor.extrahiere(antwort)!,
        id: 'test',
        erstelltAm: DateTime(2026, 8, 27),
      );

  Sektion sektion({Object? begriff = _fehlt}) => Sektion.fromJson({
        'titel': 'Frisur',
        'einschaetzung': 'Text.',
        'empfehlungen': <String>[],
        'produkte': <Object>[],
        if (!identical(begriff, _fehlt)) 'bildSuchbegriff': begriff,
      });

  group('Die Sektion liest den Suchbegriff', () {
    test('wenn einer da ist', () {
      final s = sektion(begriff: 'textured crop haircut men');

      expect(s.bildSuchbegriff, 'textured crop haircut men');
      expect(s.zeigtBilder, isTrue);
    });

    test('und raeumt Leerraum weg', () {
      expect(sektion(begriff: '  short beard men  ').bildSuchbegriff,
          'short beard men');
    });

    test('null heisst: hier hilft kein Foto', () {
      // Eine Pflegeroutine laesst sich nicht abbilden. Das ist die
      // vorgesehene Antwort des Modells und kein Fehler.
      final s = sektion(begriff: null);

      expect(s.bildSuchbegriff, isNull);
      expect(s.zeigtBilder, isFalse);
    });

    test('ein alter Report hat das Feld gar nicht', () {
      // Reports von vor DECISIONS 69 zeigen einfach keine Bilder – es gibt
      // keine Wanderung und keinen Fehler.
      final s = sektion();

      expect(s.bildSuchbegriff, isNull);
      expect(s.zeigtBilder, isFalse);
    });

    test('Unsinn faellt heraus, statt den Report zu zerlegen', () {
      for (final unsinn in <Object>[42, '', '   ', <String>['a']]) {
        expect(sektion(begriff: unsinn).bildSuchbegriff, isNull,
            reason: '$unsinn');
      }
    });
  });

  group('Der Begriff ueberlebt das Speichern', () {
    test('und fehlt im gespeicherten Report, wenn es keinen gibt', () {
      // Kein `"bildSuchbegriff": null` in jedem Dokument: Das Feld steht nur
      // da, wo es etwas bedeutet.
      expect(sektion().toJson().containsKey('bildSuchbegriff'), isFalse);
      expect(
        sektion(begriff: null).toJson().containsKey('bildSuchbegriff'),
        isFalse,
      );
    });

    test('und steht wieder da, wenn es einen gab', () {
      final vorher = sektion(begriff: 'smart casual outfit men');
      final nachher = Sektion.fromJson(vorher.toJson());

      expect(nachher.bildSuchbegriff, 'smart casual outfit men');
    });
  });

  group('Der Demo-Modus zeigt beide Faelle', () {
    for (final modus in AnalyseModus.values) {
      test('${modus.name}: Vorschlaege mit und ohne Bilderreihe', () {
        final report = lies(
          MockAnalysisService.antwortFuer(
            AnalyseModul.bestellbar.toSet(),
            modus: modus,
          ),
        );
        final alle = [for (final k in report.kapitel) ...k.sektionen];

        // Beides muss vorkommen, sonst laesst sich im Demo-Modus nur die
        // Haelfte pruefen: eine Frisur mit Bildern, eine Pflegeroutine ohne.
        expect(alle.where((s) => s.zeigtBilder), isNotEmpty);
        expect(alle.where((s) => !s.zeigtBilder), isNotEmpty);
      });

      test('${modus.name}: die Demo-Begriffe halten die Prompt-Regel ein', () {
        final report = lies(
          MockAnalysisService.antwortFuer(
            AnalyseModul.bestellbar.toSet(),
            modus: modus,
          ),
        );

        for (final kapitel in report.kapitel) {
          for (final s in kapitel.sektionen) {
            final begriff = s.bildSuchbegriff;
            if (begriff == null) continue;

            // Dieselben Schranken, die der Server durchsetzt: englisch
            // (also ohne Umlaute), klein, zwei bis sechs Woerter.
            expect(begriff, matches(RegExp(r"^[a-z0-9][a-z0-9 '&-]*$")),
                reason: begriff);
            expect(begriff.split(' ').length, inInclusiveRange(2, 6),
                reason: begriff);
          }
        }
      });
    }
  });

  _bilderTests();
}

/// Steht fuer „das Feld fehlt ganz" – zu unterscheiden von `null`.
const Object _fehlt = Object();

/// Ein Dienst, der liefert, was der Test vorgibt – und mitschreibt, wonach
/// gefragt wurde.
class _TestDienst implements BilderDienst {
  _TestDienst(this.antwort);

  final Map<String, List<Beispielbild>> antwort;
  final List<List<String>> gefragt = [];

  @override
  Future<Map<String, List<Beispielbild>>> suche(List<String> begriffe) async {
    gefragt.add(begriffe);
    return antwort;
  }
}

const _einBild = Beispielbild(
  vorschau: 'https://images.pexels.com/1-medium.jpg',
  gross: 'https://images.pexels.com/1-large.jpg',
  fotograf: 'Alex Beispiel',
  quelle: 'https://www.pexels.com/photo/1/',
  beschreibung: 'Mann mit kurzem Haarschnitt',
);

void _bilderTests() {
  group('Beispielbild.ausJson', () {
    Map<String, Object?> roh({
      Object? fotograf = 'Alex Beispiel',
      Object? quelle = 'https://www.pexels.com/photo/1/',
      Object? vorschau = 'https://images.pexels.com/1-medium.jpg',
      Object? gross = 'https://images.pexels.com/1-large.jpg',
    }) =>
        {
          'vorschau': vorschau,
          'gross': gross,
          'fotograf': fotograf,
          'quelle': quelle,
          'beschreibung': 'Mann mit kurzem Haarschnitt',
        };

    test('liest einen vollstaendigen Eintrag', () {
      expect(Beispielbild.ausJson(roh())?.fotograf, 'Alex Beispiel');
      expect(Beispielbild.ausJson(roh())?.hatDatei, isTrue);
    });

    test('lehnt ein Bild ohne Fotograf oder Quelle ab', () {
      // Beides verlangt die Pexels-Lizenz. Ein Bild, das sich nicht nennen
      // laesst, darf gar nicht erst angezeigt werden.
      expect(Beispielbild.ausJson(roh(fotograf: '')), isNull);
      expect(Beispielbild.ausJson(roh(fotograf: null)), isNull);
      expect(Beispielbild.ausJson(roh(quelle: '')), isNull);
      expect(Beispielbild.ausJson(roh(quelle: 42)), isNull);
    });

    test('lehnt ein Bild ohne Vorschau ab', () {
      expect(Beispielbild.ausJson(roh(vorschau: '')), isNull);
    });

    test('faellt auf die Vorschau zurueck, wenn die grosse fehlt', () {
      expect(Beispielbild.ausJson(roh(gross: ''))?.gross,
          'https://images.pexels.com/1-medium.jpg');
    });

    test('uebersteht Unsinn', () {
      for (final unsinn in <Object?>[null, 42, 'text', <String>[]]) {
        expect(Beispielbild.ausJson(unsinn), isNull, reason: '$unsinn');
      }
      expect(Beispielbild.listeAus('nein'), isEmpty);
      expect(Beispielbild.tabelleAus('nein'), isEmpty);
    });

    test('liest die Tabelle der Function', () {
      final tabelle = Beispielbild.tabelleAus({
        'french crop haircut men': [roh(), roh(fotograf: '')],
        'kaputt': 'nein',
      });

      expect(tabelle['french crop haircut men'], hasLength(1));
      expect(tabelle['kaputt'], isEmpty);
    });
  });

  group('Der Demo-Dienst', () {
    test('liefert zu jedem Begriff eine Reihe ohne Bilddateien', () async {
      // Im Demo-Modus laeuft kein Firebase. Statt die Reihe wegzulassen,
      // steht sie mit gezeichneten Platzhaltern da – Antippen, Wischen und
      // die Nennung lassen sich so trotzdem pruefen.
      final treffer = await const DemoBilderDienst().suche(
        ['french crop haircut men', 'short beard men'],
      );

      expect(treffer.keys, ['french crop haircut men', 'short beard men']);
      for (final reihe in treffer.values) {
        expect(reihe, isNotEmpty);
        for (final bild in reihe) {
          expect(bild.hatDatei, isFalse);
          // Nennung und Quelle stehen trotzdem – sie sind der Teil, den der
          // Demo-Modus pruefen soll.
          expect(bild.fotograf, isNotEmpty);
          expect(bild.quelle, isNotEmpty);
        }
      }
    });
  });

  group('Der Kapitel-Provider', () {
    test('fragt genau die Begriffe des Kapitels, in einem Aufruf', () async {
      final dienst = _TestDienst({});
      final container = ProviderContainer(
        overrides: [bilderDienstProvider.overrideWithValue(dienst)],
      );
      addTearDown(container.dispose);

      final schluessel = bilderSchluessel(['aaa bbb', 'ccc ddd']);
      await container.read(kapitelBilderProvider(schluessel).future);

      expect(dienst.gefragt, [
        ['aaa bbb', 'ccc ddd'],
      ]);
    });

    test('und fragt kein zweites Mal', () async {
      // Wer im Report scrollt, baut die Kapitel immer wieder neu. Ohne den
      // Cache im Provider liefe bei jedem Bauen eine Anfrage.
      final dienst = _TestDienst({});
      final container = ProviderContainer(
        overrides: [bilderDienstProvider.overrideWithValue(dienst)],
      );
      addTearDown(container.dispose);

      final schluessel = bilderSchluessel(['aaa bbb']);
      await container.read(kapitelBilderProvider(schluessel).future);
      await container.read(kapitelBilderProvider(schluessel).future);

      expect(dienst.gefragt, hasLength(1));
    });
  });

  group('Die Bilderreihe', () {
    Future<void> zeige(WidgetTester tester, AsyncValue<List<Beispielbild>> z) =>
        tester.pumpWidget(
          testHuelle(
            Scaffold(body: Beispielbilder(bilder: z)),
          ),
        );

    testWidgets('zeigt Platzhalter, waehrend geladen wird', (tester) async {
      // Nicht nichts: Sonst springt die Karte, sobald die Bilder da sind.
      await zeige(tester, const AsyncValue.loading());

      expect(find.text(texte.beispielbilderTitel), findsOneWidget);
    });

    testWidgets('verschwindet ohne Treffer rueckstandslos', (tester) async {
      await zeige(tester, const AsyncValue.data(<Beispielbild>[]));

      expect(find.text(texte.beispielbilderTitel), findsNothing);
      expect(find.text(texte.beispielbilderHinweis), findsNothing);
    });

    testWidgets('und ebenso bei einem Fehler', (tester) async {
      // Kein Netz, kein Konto, ein Serverfehler: Der Report ist ohne Bilder
      // vollstaendig. Eine Fehlermeldung waere hier Laerm.
      await zeige(
        tester,
        AsyncValue<List<Beispielbild>>.error('kaputt', StackTrace.empty),
      );

      expect(find.text(texte.beispielbilderTitel), findsNothing);
    });

    testWidgets('nennt die Quelle schon unter der Reihe', (tester) async {
      await zeige(tester, const AsyncValue.data([_einBild]));

      expect(find.text(texte.beispielbilderTitel), findsOneWidget);
      expect(find.text(texte.beispielbilderHinweis), findsOneWidget);
    });

    testWidgets('oeffnet im Vollbild den Fotografen und den Rueckweg',
        (tester) async {
      // Die Pexels-Lizenz verlangt Namen und Link zurueck zur Quelle.
      await zeige(tester, const AsyncValue.data([_einBild]));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byType(BeispielbildBetrachter), findsOneWidget);
      expect(
        find.text(texte.beispielbildFotograf('Alex Beispiel')),
        findsOneWidget,
      );
      expect(find.text(texte.beispielbildQuelle), findsOneWidget);
    });
  });

  group('Im Report', () {
    testWidgets('steht die Reihe unter dem Vorschlag', (tester) async {
      handyGroesse(tester, hoehe: 3000);

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

      final report = AnalysisResult.vonApi(
        JsonExtractor.extrahiere(
          MockAnalysisService.antwortFuer({AnalyseModul.basis}),
        )!,
        id: 'bilder',
        erstelltAm: DateTime(2026, 8, 27),
      );
      await container.read(analysenProvider.notifier).speichern(report);

      container.read(routerProvider).push('${Routes.result}/bilder');
      await tester.pumpAndSettle();

      // Das Basis-Kapitel hat eine Sektion mit Suchbegriff (Frisur) und eine
      // ohne – die Reihe steht also genau einmal je Begriff.
      expect(find.text(texte.beispielbilderTitel), findsWidgets);
    });
  });
}
