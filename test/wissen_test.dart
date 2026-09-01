import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/ausprobieren/models/technik.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/plan/ui/widgets/tagesliste_karte.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/result/ui/kapitel_screen.dart';
import 'package:trueglow/features/wissen/logic/wissen_bibliothek.dart';
import 'package:trueglow/features/wissen/ui/wissen_screen.dart';
import 'package:trueglow/features/wissen/ui/wissens_blatt.dart';

import 'hilfen.dart';

/// Die Wissens-Bibliothek – DECISIONS 88.
///
/// Der Befund: Eine Aufgabe wie „5 Minuten Gesichtsyoga" setzt Wissen voraus,
/// das viele nicht haben, und die App ließ sie damit allein.
///
/// Geprüft wird dreierlei: dass zu jeder Technik eine Erklärung da ist, dass
/// die Erkennung im Satz trifft, ohne wild um sich zu greifen, und dass man
/// von einer Aufgabe aus dorthin kommt.
void main() {
  hiveImTest();

  // Der Bundle-Cache merkt sich nicht den Text, sondern das Future des
  // Ladevorgangs – und ein Future aus der Async-Zone eines fruehen Tests wird
  // in der Zone eines spaeteren nie fertig. Ohne dieses Leeren stand jeder
  // Bildschirm ab dem zweiten Widget-Test auf „Wird geladen".
  setUp(rootBundle.clear);

  // Die Inhaltspruefungen lesen die Datei direkt und nicht ueber
  // `rootBundle`. Der Bundle-Cache merkt sich das Future eines Ladevorgangs
  // ueber Testgrenzen hinweg – ein Future aus der Async-Zone eines fruehen
  // Tests wird in der Zone eines spaeteren nie fertig, und der Bildschirm
  // stand danach ewig auf „Wird geladen". Dass der Pfad im Bundle
  // ueberhaupt angemeldet ist, pruefen weiter unten die Widget-Tests: Die
  // laden ueber den echten Provider.
  Future<WissenBibliothek> lade(Sprache sprache) async =>
      WissenBibliothek.ausJson(
        await File(wissenAsset(sprache.code)).readAsString(),
      );

  group('Zu jeder Technik gibt es eine Erklärung', () {
    for (final sprache in Sprache.values) {
      test('in ${sprache.name}', () async {
        final bibliothek = await lade(sprache);

        for (final technik in Technik.values) {
          final eintrag = bibliothek.nachId(technik.name);
          expect(eintrag, isNotNull, reason: technik.name);
          expect(eintrag!.schritte.length, greaterThanOrEqualTo(3),
              reason: technik.name);
          expect(eintrag.woraufAchten, isNotEmpty, reason: technik.name);
        }
      });
    }

    test('und die App nennt sie genauso wie die Bibliothek', () async {
      // Sonst zeigt der Chip in „Das will ich ausprobieren" einen Namen, zu
      // dem sich nichts nachschlagen lässt.
      final bibliothek = await lade(Sprache.deutsch);

      for (final technik in Technik.values) {
        final eintrag = bibliothek.nachId(technik.name)!;
        expect(eintrag.namen, contains(technik.label(texte)),
            reason: technik.name);
      }
    });
  });

  group('Die Erkennung trifft, was gemeint ist', () {
    late WissenBibliothek bibliothek;

    setUp(() async => bibliothek = await lade(Sprache.deutsch));

    test('findet die Technik in einer Tagesaufgabe', () {
      final treffer = bibliothek.suche('Nach dem Duschen: Gua Sha, 5 Minuten');
      expect(treffer?.id, 'guaSha');
    });

    test('auch wenn der Name mitten im Satz steht', () {
      expect(
        bibliothek.suche('Abends einmal Ölziehen, dann putzen')?.id,
        'oelziehen',
      );
    });

    test('erkennt eine Schreibvariante', () {
      expect(bibliothek.suche('Gua-Sha am Morgen')?.id, 'guaSha');
    });

    test('greift nicht mitten in ein anderes Wort', () {
      // „Ölziehen" darf nicht in „Ölziehende" gefunden werden – sonst
      // erscheint das Info-Zeichen an Sätzen, in denen es nichts zu holen
      // gibt.
      expect(bibliothek.suche('Ölziehende Bewegungen der Hand'), isNull);
    });

    test('lässt Sätze ohne Technik in Ruhe', () {
      expect(
        bibliothek.suche('Nach dem Zähneputzen: ein Glas Wasser trinken'),
        isNull,
      );
    });

    test('nimmt bei mehreren den, der vorn steht', () {
      final treffer = bibliothek.suche('Gua Sha, danach eine Sheet-Maske');
      expect(treffer?.id, 'guaSha');
    });

    test('kennt auch Begriffe, die keine Technik zur Auswahl sind', () {
      // Der Befund war nicht auf den Katalog beschränkt: Auch „Lagenlook"
      // oder „LSF" stehen in Empfehlungen und wollen erklärt werden.
      for (final (satz, id) in [
        ('Morgens LSF 30 auftragen', 'lichtschutzfaktor'),
        ('Probier den Lagenlook aus', 'lagenlook'),
        ('Abends Doppelreinigung', 'doppelreinigung'),
      ]) {
        expect(bibliothek.suche(satz)?.id, id, reason: satz);
      }
    });

    test('sucht in der Sprache, in der die App läuft', () async {
      final englisch = await lade(Sprache.englisch);
      expect(englisch.suche('Evening: oil pulling for five minutes')?.id,
          'oelziehen');
    });
  });

  group('Von der Empfehlung zur Erklärung', () {
    Future<void> zeigeReport(WidgetTester tester, String empfehlung) async {
      handyGroesse(tester, hoehe: 2400);

      final analyse = AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
        kapitel: [
          Kapitel(
            modul: AnalyseModul.hautFarbtyp,
            einleitung: 'Warmer Unterton.',
            sektionen: [
              Sektion(
                titel: 'Haut',
                einschaetzung: 'Ruhiges Hautbild.',
                empfehlungen: [empfehlung],
                produkte: const [],
              ),
            ],
          ),
        ],
        plan: const Plan(
          sofort: [],
          dreissigTage: [],
          langfristig: [],
          taeglicheHabits: [],
        ),
      );

      final container = ProviderContainer(overrides: speicherOverrides());
      addTearDown(container.dispose);
      await container.read(analysenProvider.notifier).speichern(analyse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          // Der Kapitelinhalt steht seit DECISIONS 89 hinter einer
          // Kachel. Geprüft wird hier der Inhalt, nicht der Weg dorthin –
          // den prüft `kapitel_kachel_test.dart`.
          child: testHuelle(const KapitelScreen(
            analyseId: '1',
            modulName: 'hautFarbtyp',
          )),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('das Info-Zeichen steht dort, wo es etwas zu lesen gibt',
        (tester) async {
      await zeigeReport(tester, 'Gua Sha: mit Öl, immer nach außen.');

      expect(find.byType(WissenLink), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('und nirgends sonst', (tester) async {
      await zeigeReport(tester, 'Morgens das Gesicht mit Wasser waschen.');

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('antippen öffnet die Erklärung', (tester) async {
      await zeigeReport(tester, 'Gua Sha: mit Öl, immer nach außen.');

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.byType(WissensBlatt), findsOneWidget);
      expect(find.text(texte.wissenWasIstDas), findsOneWidget);
      expect(find.text(texte.wissenSoGehts), findsOneWidget);
      expect(find.text(texte.wissenWoraufAchten), findsOneWidget);
      // Die Anleitung selbst, nicht nur der Name.
      expect(find.textContaining('Stein'), findsWidgets);
    });
  });

  group('Aus der Tagesliste nachschlagen', () {
    Future<int> zeigeAufgabe(WidgetTester tester, String aufgabe) async {
      var abgehakt = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: speicherOverrides(),
          child: testHuelle(
            Scaffold(
              body: HabitZeile(
                text: aufgabe,
                erledigt: false,
                onTap: () => abgehakt++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return abgehakt;
    }

    testWidgets('das Info-Zeichen steht an der Aufgabe', (tester) async {
      await zeigeAufgabe(tester, 'Morgens nach dem Waschen: Gua Sha, 3 Minuten');

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('und hakt die Aufgabe dabei nicht ab', (tester) async {
      // Die ganze Zeile ist antippbar. Wer nachschlagen will, darf nicht
      // aus Versehen etwas als erledigt melden, das er nicht getan hat.
      var abgehakt = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: speicherOverrides(),
          child: testHuelle(
            Scaffold(
              body: HabitZeile(
                text: 'Morgens: Gua Sha, 3 Minuten',
                erledigt: false,
                onTap: () => abgehakt++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.byType(WissensBlatt), findsOneWidget);
      expect(abgehakt, 0);
    });

    testWidgets('die Trefferflaeche misst mindestens 48 Punkte',
        (tester) async {
      // DECISIONS 94: Das Zeichen maß 16 Punkte plus zwei Punkte Rand. Wer
      // knapp danebentraf, hakte die Aufgabe ab.
      await zeigeAufgabe(tester, 'Morgens: Gua Sha, 3 Minuten');

      final flaeche = tester.getSize(find.byType(WissenLink));
      expect(flaeche.width, greaterThanOrEqualTo(48));
      expect(flaeche.height, greaterThanOrEqualTo(48));
    });

    // Der eigentliche Beleg: nicht die Mitte, sondern die vier Ecken – je
    // Ecke ein eigener Test, damit kein offenes Blatt aus dem vorigen
    // Durchgang den nächsten Tipp abfängt.
    for (final ecke in ['oben links', 'oben rechts', 'unten links',
      'unten rechts']) {
      testWidgets('$ecke trifft noch das Zeichen', (tester) async {
        var abgehakt = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: speicherOverrides(),
            child: testHuelle(
              Scaffold(
                body: HabitZeile(
                  text: 'Morgens: Gua Sha, 3 Minuten',
                  erledigt: false,
                  onTap: () => abgehakt++,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rechteck = tester.getRect(find.byType(WissenLink));
        // Einen Punkt innerhalb der Kante – näher kommt kein Finger.
        final punkt = switch (ecke) {
          'oben links' => rechteck.topLeft + const Offset(1, 1),
          'oben rechts' => rechteck.topRight + const Offset(-1, 1),
          'unten links' => rechteck.bottomLeft + const Offset(1, -1),
          _ => rechteck.bottomRight + const Offset(-1, -1),
        };

        await tester.tapAt(punkt);
        await tester.pumpAndSettle();

        expect(find.byType(WissensBlatt), findsOneWidget, reason: ecke);
        expect(abgehakt, 0, reason: ecke);
      });
    }

    testWidgets('daneben gehört der Platz weiter der Aufgabe',
        (tester) async {
      // Die Kehrseite: Die Trefferfläche darf sich nicht über die Zeile
      // legen. Ein Tipp links daneben hakt weiterhin ab.
      var abgehakt = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: speicherOverrides(),
          child: testHuelle(
            Scaffold(
              body: HabitZeile(
                text: 'Morgens: Gua Sha, 3 Minuten',
                erledigt: false,
                onTap: () => abgehakt++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rechteck = tester.getRect(find.byType(WissenLink));
      await tester.tapAt(
        Offset(rechteck.left - 4, rechteck.center.dy),
      );
      await tester.pumpAndSettle();

      expect(abgehakt, 1);
      expect(find.byType(WissensBlatt), findsNothing);
    });

    testWidgets('eine Aufgabe ohne Technik bleibt schmucklos', (tester) async {
      await zeigeAufgabe(tester, 'Nach dem Zähneputzen: ein Glas Wasser');

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });
  });

  group('Die Bibliothek lässt sich durchblättern', () {
    Future<void> zeige(WidgetTester tester) async {
      handyGroesse(tester, hoehe: 2400);

      await tester.pumpWidget(
        ProviderScope(
          overrides: speicherOverrides(),
          child: testHuelle(const WissenScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('und zeigt die Einträge', (tester) async {
      await zeige(tester);

      expect(find.text('Gua Sha'), findsOneWidget);
      expect(find.text('Ölziehen'), findsOneWidget);
    });

    testWidgets('die Suche grenzt ein', (tester) async {
      await zeige(tester);

      await tester.enterText(find.byType(TextField), 'Gua');
      await tester.pumpAndSettle();

      expect(find.text('Gua Sha'), findsOneWidget);
      expect(find.text('Ölziehen'), findsNothing);
    });

    testWidgets('und sagt es, wenn nichts passt', (tester) async {
      await zeige(tester);

      await tester.enterText(find.byType(TextField), 'Quantenphysik');
      await tester.pumpAndSettle();

      expect(find.text(texte.wissenLeer), findsOneWidget);
    });
  });
}
