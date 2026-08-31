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
        kapitel: [
          for (final modul in AnalyseModul.values)
            Kapitel(
              modul: modul,
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
        testWidgets(
            'zwei je Zeile, gleich hoch – ${sprache.languageCode}, '
            '${fall.key}', (tester) async {
          tester.view.physicalSize = Size(fall.value, 3000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final container = await speichern(vollerReport());

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.dark,
                locale: sprache,
                localizationsDelegates: L.localizationsDelegates,
                supportedLocales: L.supportedLocales,
                home: const Scaffold(body: SizedBox.shrink()),
              ),
            ),
          );

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
                    child: KapitelRaster(ergebnis: vollerReport()),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final kacheln = tester
              .widgetList<KapitelKachel>(find.byType(KapitelKachel))
              .toList();
          expect(kacheln.length, AnalyseModul.values.length);

          final rechtecke = [
            for (final kachel in kacheln)
              tester.getRect(find.byWidget(kachel)),
          ];

          // Alle gleich breit – zwei Spalten, keine Ausreißer.
          final breiten = rechtecke.map((r) => r.width.round()).toSet();
          expect(breiten.length, 1, reason: 'Breiten: $breiten');

          // Und je Zeile gleich hoch.
          for (var i = 0; i + 1 < rechtecke.length; i += 2) {
            expect(
              rechtecke[i].height,
              closeTo(rechtecke[i + 1].height, 0.5),
              reason: 'Zeile ${i ~/ 2}',
            );
          }

          // Nichts läuft über den Rand hinaus.
          for (final rechteck in rechtecke) {
            expect(rechteck.left, greaterThanOrEqualTo(-0.5));
            expect(rechteck.right, lessThanOrEqualTo(fall.value + 0.5));
          }
        });
      }
    }

    testWidgets('bei ungerader Anzahl bleibt der Platz frei', (tester) async {
      handyGroesse(tester, hoehe: 2000);

      final ergebnis = vollerReport();
      final ungerade = AnalysisResult(
        id: '1',
        erstelltAm: ergebnis.erstelltAm,
        kapitel: ergebnis.kapitel.take(3).toList(),
        plan: ergebnis.plan,
      );
      final container = await speichern(ungerade);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            Scaffold(
              body: SingleChildScrollView(
                child: KapitelRaster(ergebnis: ungerade),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final breiten = tester
          .widgetList<KapitelKachel>(find.byType(KapitelKachel))
          .map((k) => tester.getSize(find.byWidget(k)).width.round())
          .toSet();
      // Die letzte Kachel wird nicht doppelt so breit.
      expect(breiten.length, 1);
    });
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

      expect(find.textContaining('Einleitung zu basis'), findsOneWidget);
      expect(
        find.text(texte.ergebnisKachelEmpfehlungen(2)),
        findsNWidgets(AnalyseModul.values.length),
      );
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
