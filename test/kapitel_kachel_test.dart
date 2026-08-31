import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/core/theme/app_colors.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/direction/models/richtung.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/result/ui/kapitel_screen.dart';
import 'package:trueglow/features/result/ui/result_screen.dart';
import 'package:trueglow/features/result/ui/widgets/kapitel_kachel.dart';

import 'hilfen.dart';

/// Der Report als Kachel-Übersicht – DECISIONS 89.
///
/// Zwei Zusicherungen, und die zweite ist die wichtigere:
///
///  1. Das Raster schert nicht aus – auf keiner Breite und in keiner der
///     beiden Sprachen, wie beim Stilrichtungs-Raster (DECISIONS 61).
///  2. **Es geht nichts verloren.** Alles, was vorher im langen Scroll
///     stand, ist danach genauso erreichbar.
void main() {
  hiveImTest();

  /// Ein Report, der alle Bereiche füllt.
  AnalysisResult vollerReport() => AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
        gesamtbild: 'Ein ruhiges Gesamtbild mit klarer Richtung.',
        richtung: const Richtung(
          ziele: {Richtungsziel.cleanGepflegt},
          freitext: 'Ich will gepflegter wirken, ohne viel Aufwand.',
        ),
        kapitel: [
          for (final modul in AnalyseModul.values)
            Kapitel(
              modul: modul,
              kurzfazit: 'Kurzfazit zu ${modul.name}',
              einleitung:
                  'Einleitung zu ${modul.name} – zwei Zeilen, die den '
                  'Bereich in eigenen Worten zusammenfassen und dabei '
                  'lang genug sind, um gekürzt zu werden.',
              sektionen: [
                Sektion(
                  titel: 'Abschnitt ${modul.name}',
                  einschaetzung: 'Einschätzung zu ${modul.name}.',
                  empfehlungen: const ['Erste Empfehlung', 'Zweite'],
                  produkte: const [],
                ),
              ],
            ),
        ],
        plan: const Plan(
          sofort: ['Heute anfangen'],
          dreissigTage: [],
          langfristig: [],
          taeglicheHabits: [],
        ),
      );

  /// Derselbe Report mit einer bestimmten Zahl von Kapiteln.
  AnalysisResult mitKapiteln(int anzahl) {
    final voll = vollerReport();
    return AnalysisResult(
      id: voll.id,
      erstelltAm: voll.erstelltAm,
      gesamtbild: voll.gesamtbild,
      richtung: voll.richtung,
      kapitel: voll.kapitel.take(anzahl).toList(),
      plan: voll.plan,
    );
  }

  Future<ProviderContainer> speichern(AnalysisResult ergebnis) async {
    final container = ProviderContainer(overrides: speicherOverrides());
    addTearDown(container.dispose);
    await container.read(analysenProvider.notifier).speichern(ergebnis);
    return container;
  }

  group('Das Raster schert nicht aus', () {
    for (final sprache in [const Locale('de'), const Locale('en')]) {
      for (final fall in {'schmal': 320.0, 'normal': 400.0, 'breit': 480.0}
          .entries) {
        for (final anzahl in [6, 7]) {
          testWidgets(
              '$anzahl Bereiche \u2013 ${sprache.languageCode}, ${fall.key}',
              (tester) async {
            tester.view.physicalSize = Size(fall.value, 3000);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            final ergebnis = mitKapiteln(anzahl);
            final container = await speichern(ergebnis);

            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: AppTheme.dark,
                  locale: sprache,
                  localizationsDelegates: L.localizationsDelegates,
                  supportedLocales: L.supportedLocales,
                  home: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.gapM),
                      child: KapitelRaster(ergebnis: ergebnis),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final rechtecke = tester
                .widgetList<KapitelKachel>(find.byType(KapitelKachel))
                .map((k) => tester.getRect(find.byWidget(k)))
                .toList();
            expect(rechtecke.length, anzahl);

            // Die Paare: alle gleich breit, je Zeile gleich hoch.
            final paare = anzahl.isOdd
                ? rechtecke.sublist(0, anzahl - 1)
                : rechtecke;
            final breiten = paare.map((r) => r.width.round()).toSet();
            expect(breiten.length, 1, reason: 'Breiten: $breiten');

            for (var i = 0; i + 1 < paare.length; i += 2) {
              expect(
                paare[i].height,
                closeTo(paare[i + 1].height, 0.5),
                reason: 'Zeile ${i ~/ 2}',
              );
            }

            // Bei ungerader Anzahl liegt die letzte quer \u00fcber die volle
            // Breite \u2013 kein Loch daneben (DECISIONS 90).
            if (anzahl.isOdd) {
              final letzte = rechtecke.last;
              expect(letzte.width, greaterThan(paare.first.width * 1.8));
              expect(letzte.height, lessThan(paare.first.height));
            }

            // Nichts l\u00e4uft \u00fcber den Rand hinaus.
            for (final rechteck in rechtecke) {
              expect(rechteck.left, greaterThanOrEqualTo(-0.5));
              expect(rechteck.right, lessThanOrEqualTo(fall.value + 0.5));
            }
          });
        }
      }
    }
  });

  group('Auf der Kachel steht, was dahinter wartet', () {
    testWidgets('Name, Zusammenfassung und Anzahl', (tester) async {
      handyGroesse(tester, hoehe: 3000);

      final ergebnis = vollerReport();
      final container = await speichern(ergebnis);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            Scaffold(
              body: SingleChildScrollView(
                child: KapitelRaster(ergebnis: ergebnis),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Eine ganze Aussage statt eines angerissenen Satzes (DECISIONS 90).
      expect(find.text('Kurzfazit zu basis'), findsOneWidget);
      expect(find.textContaining('Einleitung zu'), findsNothing);
      expect(
        find.text(texte.ergebnisKachelEmpfehlungen(2)),
        findsNWidgets(AnalyseModul.values.length),
      );
    });

    testWidgets('ohne kurzfazit springt die erste Empfehlung ein',
        (tester) async {
      // Aeltere Reports kennen das Feld nicht. Die erste Empfehlung ist von
      // sich aus ein ganzer Satz – die bessere Rueckfallebene als ein
      // abgeschnittener Absatz (DECISIONS 90).
      handyGroesse(tester, hoehe: 1200);

      final alt = AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
        kapitel: const [
          Kapitel(
            modul: AnalyseModul.basis,
            einleitung: 'Ein langer Einleitungstext, der mitten im Wort ab',
            sektionen: [
              Sektion(
                titel: 'Frisur',
                einschaetzung: 'x',
                empfehlungen: ['Seiten kuerzer halten als oben.'],
                produkte: [],
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
      final container = await speichern(alt);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(Scaffold(body: KapitelRaster(ergebnis: alt))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Seiten kuerzer halten als oben.'), findsOneWidget);
      expect(find.textContaining('Ein langer Einleitungstext'), findsNothing);
    });

    testWidgets('ein leeres Kapitel bekommt keine Kachel', (tester) async {
      handyGroesse(tester);

      final leer = AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
        kapitel: const [
          Kapitel(modul: AnalyseModul.basis, einleitung: '', sektionen: []),
        ],
        plan: const Plan(
          sofort: [],
          dreissigTage: [],
          langfristig: [],
          taeglicheHabits: [],
        ),
      );
      final container = await speichern(leer);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            Scaffold(body: KapitelRaster(ergebnis: leer)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KapitelKachel), findsNothing);
    });
  });

  group('Es geht nichts verloren', () {
    testWidgets('der Kopfbereich steht weiter über dem Raster',
        (tester) async {
      handyGroesse(tester, hoehe: 3000);

      final ergebnis = vollerReport();
      final container = await speichern(ergebnis);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(const ResultScreen(analyseId: '1')),
        ),
      );
      await tester.pumpAndSettle();

      // Gesamtbild, Auswahl-Echo und der Weg zum Plan.
      expect(find.text(ergebnis.gesamtbild), findsOneWidget);
      expect(find.text('${texte.ergebnisAuswahl}:'), findsOneWidget);
      expect(find.text(texte.ergebnisPlanErstellen), findsOneWidget);
      expect(find.text(texte.disclaimerMedizin), findsWidgets);
      expect(find.byType(KapitelKachel), findsWidgets);
    });

    testWidgets('und ein Tipp öffnet den vollständigen Bereich',
        (tester) async {
      handyGroesse(tester, hoehe: 3000);

      final ergebnis = vollerReport();
      final container = await speichern(ergebnis);

      final router = GoRouter(
        initialLocation: '/result/1',
        routes: [
          GoRoute(
            path: '/result/:id',
            builder: (context, state) =>
                ResultScreen(analyseId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'kapitel/:modul',
                builder: (context, state) => KapitelScreen(
                  analyseId: state.pathParameters['id']!,
                  modulName: state.pathParameters['modul']!,
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: L.localizationsDelegates,
            supportedLocales: L.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In der Übersicht steht die Empfehlung noch nicht.
      expect(find.text('Erste Empfehlung'), findsNothing);

      await tester.tap(find.byType(KapitelKachel).first);
      await tester.pumpAndSettle();

      // Dahinter der vollständige Kapitelinhalt.
      expect(find.text('Abschnitt basis'), findsOneWidget);
      expect(find.text('Erste Empfehlung'), findsOneWidget);
      expect(find.text('Zweite'), findsOneWidget);
      expect(find.textContaining('Einleitung zu basis'), findsOneWidget);
    });
  });

  group('Der Freitext wohnt im Zielkapitel', () {
    // DECISIONS 90: Er stand in einer eigenen Karte, die dasselbe sagte wie
    // das Kapitel darunter. Jetzt steht er dort, wo das Kapitel steht, das
    // aus ihm geworden ist.
    testWidgets('auf der Kachel als Untertitel', (tester) async {
      handyGroesse(tester, hoehe: 3000);

      final ergebnis = vollerReport();
      final container = await speichern(ergebnis);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            Scaffold(
              body: SingleChildScrollView(
                child: KapitelRaster(ergebnis: ergebnis),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Ich will gepflegter wirken, ohne viel Aufwand.'),
        findsOneWidget,
      );
      // Und nicht die Einleitung des Zielkapitels.
      expect(
        find.textContaining('Einleitung zu persoenlicheZiele'),
        findsNothing,
      );
    });

    testWidgets('und dahinter vollständig als Zitat', (tester) async {
      handyGroesse(tester, hoehe: 3000);

      final container = await speichern(vollerReport());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(const KapitelScreen(
            analyseId: '1',
            modulName: 'persoenlicheZiele',
          )),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(texte.ergebnisDeinWunsch), findsOneWidget);
      expect(
        find.text('Ich will gepflegter wirken, ohne viel Aufwand.'),
        findsOneWidget,
      );
      // Der Rest des Kapitels steht wie bisher darunter.
      expect(find.text('Abschnitt persoenlicheZiele'), findsOneWidget);
      expect(find.text('Erste Empfehlung'), findsOneWidget);
    });

    testWidgets('in einem anderen Bereich steht kein Zitat', (tester) async {
      handyGroesse(tester, hoehe: 3000);

      final container = await speichern(vollerReport());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(const KapitelScreen(
            analyseId: '1',
            modulName: 'basis',
          )),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(texte.ergebnisDeinWunsch), findsNothing);
    });
  });

  group('Der Demo-Report füllt alle Bereiche', () {
    // Sonst liesse sich der siebte Bereich – und die Kachel-Zeile mit
    // ungerader Anzahl – nur mit echtem Kontingent ansehen.
    int kapitelZahl(String antwort) =>
        (JsonExtractor.extrahiere(antwort)!['kapitel'] as List).length;

    test('sechs Bereiche ohne Freitext', () {
      expect(
        kapitelZahl(MockAnalysisService.antwortFuer(
          AnalyseModul.bestellbar.toSet(),
        )),
        AnalyseModul.bestellbar.length,
      );
    });

    test('und sieben mit', () {
      final antwort = MockAnalysisService.antwortFuer(
        AnalyseModul.bestellbar.toSet(),
        mitZielen: true,
      );

      expect(kapitelZahl(antwort), AnalyseModul.values.length);
      expect(antwort, contains('"modul": "persoenlicheZiele"'));
    });
  });

  group('Die Töne kommen aus der Palette', () {
    test('für jeden Bereich gibt es einen', () {
      // Ein Bereich ohne Ton bekäme die Farbe eines anderen – dann wäre die
      // Unterscheidung keine.
      expect(
        AppColors.dunkel.kachelToene.length,
        greaterThanOrEqualTo(AnalyseModul.values.length),
      );
      expect(
        AppColors.hell.kachelToene.length,
        AppColors.dunkel.kachelToene.length,
      );
    });

    test('und keiner davon ist das Gold für Erreichtes', () {
      // Gold ist seit DECISIONS 50 für Erreichtes reserviert. Als Dekoration
      // an einer Kachel wäre es genau das nicht mehr.
      for (final schema in [AppColors.dunkel, AppColors.hell]) {
        for (final ton in schema.kachelToene) {
          expect(ton, isNot(schema.erreicht));
          expect(ton, isNot(schema.erreichtFlaeche));
        }
      }
    });

    test('sie unterscheiden sich voneinander', () {
      for (final schema in [AppColors.dunkel, AppColors.hell]) {
        expect(schema.kachelToene.toSet().length, schema.kachelToene.length);
      }
    });
  });
}
