import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analyse_modus.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/plan/logic/tagesabschnitt.dart';
import 'package:trueglow/features/plan/ui/widgets/tagesliste_karte.dart';

import 'hilfen.dart';

/// Die Tagesliste nach Tagesabschnitten – DECISIONS 70.
///
/// Der Anlass kam vom Geraet: Innerhalb eines Kapitels sprang die Liste vom
/// Zubettgehen zurueck zum Fruehstueck. Was hier geprueft wird, ist genau die
/// Zusage aus dem Paket: durchgetaktet von morgens bis abends, jede Aufgabe
/// genau einmal, und nichts geht verloren.

/// Die sieben Anker aus `functions/src/labels.ts`, in beiden Sprachen.
///
/// Absichtlich hier abgeschrieben und nicht aus dem Code gezogen: Der Test
/// soll fehlschlagen, wenn dort einer dazukommt, ohne dass ihn jemand
/// einsortiert hat.
const _ankerDe = [
  'Nach dem Aufstehen',
  'Nach dem Zähneputzen',
  'Beim Duschen',
  'Nach dem Duschen',
  'Nach dem Frühstück',
  'Nach dem Abendessen',
  'Vor dem Schlafengehen',
];

const _ankerEn = [
  'After getting up',
  'After brushing your teeth',
  'In the shower',
  'After your shower',
  'After breakfast',
  'After dinner',
  'Before bed',
];

Kapitel _kapitel(AnalyseModul modul, List<String> habits) => Kapitel(
      modul: modul,
      einleitung: 'Text.',
      sektionen: const [],
      habits: habits,
    );

void main() {
  group('Jeder bekannte Anker hat seinen Platz', () {
    test('genau ein Abschnitt je Anker, keiner in „Bei Bedarf"', () {
      for (final anker in [..._ankerDe, ..._ankerEn]) {
        final platz = einordnen('$anker: Irgendetwas tun');

        expect(
          platz.abschnitt,
          isNot(Tagesabschnitt.beiBedarf),
          reason: '$anker ist nicht einsortiert',
        );
        expect(
          platz.abschnitt,
          isNot(Tagesabschnitt.tagsueber),
          reason: '$anker gilt als ankerlos',
        );
      }
    });

    test('und deutsche und englische Fassung landen gleich', () {
      // Wer die App nach der Analyse umstellt, behaelt seine Aufgaben in der
      // alten Sprache. Sie muessen trotzdem an derselben Stelle stehen.
      for (var i = 0; i < _ankerDe.length; i++) {
        final de = einordnen('${_ankerDe[i]}: X');
        final en = einordnen('${_ankerEn[i]}: X');

        expect(en.abschnitt, de.abschnitt, reason: _ankerDe[i]);
        expect(en.rang, de.rang, reason: _ankerDe[i]);
      }
    });

    test('die Reihenfolge innerhalb des Morgens ist chronologisch', () {
      int rang(String anker) => einordnen('$anker: X').rang;

      expect(rang('Nach dem Aufstehen'), lessThan(rang('Beim Duschen')));
      expect(rang('Beim Duschen'), lessThan(rang('Nach dem Duschen')));
      expect(rang('Nach dem Duschen'), lessThan(rang('Nach dem Frühstück')));
      expect(
        rang('Nach dem Frühstück'),
        lessThan(rang('Nach dem Zähneputzen')),
      );
    });

    test('und abends ebenso', () {
      expect(
        einordnen('Nach dem Abendessen: X').rang,
        lessThan(einordnen('Vor dem Schlafengehen: X').rang),
      );
    });

    test('Gross- und Kleinschreibung ist egal', () {
      expect(
        einordnen('NACH DEM AUFSTEHEN: X').abschnitt,
        Tagesabschnitt.morgens,
      );
    });
  });

  group('Was nicht in der Tabelle steht', () {
    test('ein situativer Anker landet in „Bei Bedarf"', () {
      // Der Prompt laesst fuer die Aufgaben aus dem Freitext ausdruecklich
      // eine Situation als Ausloeser zu. Die hat keine Tageszeit.
      for (final aufgabe in [
        'Bei Rauchverlangen: drei Minuten an die frische Luft',
        'Wenn der Feierabend-Drang einsetzt: Schuhe anziehen und losgehen',
        'When the craving hits: drink a glass of water',
      ]) {
        expect(
          einordnen(aufgabe).abschnitt,
          Tagesabschnitt.beiBedarf,
          reason: aufgabe,
        );
      }
    });

    test('eine Aufgabe ganz ohne Anker landet „Tagsüber"', () {
      // Reports von vor DECISIONS 44 haben keine Anker. Sie verschwinden
      // nicht, sie stehen in der Mitte des Tages.
      for (final aufgabe in [
        'Bildschirm auf Augenhöhe prüfen',
        'Wasser trinken',
      ]) {
        expect(
          einordnen(aufgabe).abschnitt,
          Tagesabschnitt.tagsueber,
          reason: aufgabe,
        );
      }
    });

    test('ein langer Satz mit Doppelpunkt ist kein Anker', () {
      // Sonst laese „Zähne putzen: zwei Minuten, auch die Innenseiten und
      // die Zunge" als unbekannter Anker und landete bei Bedarf.
      const lang = 'Zähne putzen, und zwar wirklich sehr gründlich und '
          'ohne Eile: zwei Minuten';

      expect(einordnen(lang).abschnitt, Tagesabschnitt.tagsueber);
      expect(ankerVon(lang), isNull);
    });

    test('ein Doppelpunkt am Anfang zählt nicht', () {
      expect(ankerVon(': etwas'), isNull);
    });
  });

  group('Die Liste selbst', () {
    test('ist von morgens bis abends durchsortiert', () {
      final gruppen = tagesliste([
        _kapitel(AnalyseModul.basis, [
          'Vor dem Schlafengehen: Bartöl einarbeiten',
          'Nach dem Aufstehen: Haare richten',
        ]),
        _kapitel(AnalyseModul.zaehneLaecheln, [
          'Nach dem Frühstück: Mit Wasser nachspülen',
          'Nach dem Abendessen: Interdentalbürste',
        ]),
      ]);

      expect(
        [for (final g in gruppen) g.abschnitt],
        [Tagesabschnitt.morgens, Tagesabschnitt.abends],
      );
      expect(
        [for (final a in gruppen.first.aufgaben) a.text],
        [
          'Nach dem Aufstehen: Haare richten',
          'Nach dem Frühstück: Mit Wasser nachspülen',
        ],
      );
      expect(
        [for (final a in gruppen.last.aufgaben) a.text],
        [
          'Nach dem Abendessen: Interdentalbürste',
          'Vor dem Schlafengehen: Bartöl einarbeiten',
        ],
      );
    });

    test('leere Abschnitte entstehen gar nicht', () {
      final gruppen = tagesliste([
        _kapitel(AnalyseModul.basis, ['Nach dem Aufstehen: Haare richten']),
      ]);

      expect(gruppen, hasLength(1));
      expect(gruppen.single.abschnitt, Tagesabschnitt.morgens);
    });

    test('gleichrangige Aufgaben behalten ihre Reihenfolge', () {
      // Dart sortiert nicht stabil. Ohne den Laufindex wechselte die Liste
      // bei jedem Bauen die Reihenfolge – unbenutzbar.
      final habits = [
        for (var i = 0; i < 12; i++) 'Nach dem Aufstehen: Aufgabe $i',
      ];
      final erwartet = tagesliste([_kapitel(AnalyseModul.basis, habits)])
          .single
          .aufgaben
          .map((a) => a.text)
          .toList();

      expect(erwartet, habits);

      for (var lauf = 0; lauf < 5; lauf++) {
        expect(
          tagesliste([_kapitel(AnalyseModul.basis, habits)])
              .single
              .aufgaben
              .map((a) => a.text),
          erwartet,
        );
      }
    });

    test('keine Aufgabe geht verloren und keine kommt doppelt', () {
      final kapitel = [
        _kapitel(AnalyseModul.basis, [
          'Nach dem Aufstehen: A',
          'Ohne Anker B',
        ]),
        _kapitel(AnalyseModul.stilKleiderschrank, [
          'Bei Langeweile: C',
          'Vor dem Schlafengehen: D',
        ]),
      ];

      final alle = [
        for (final g in tagesliste(kapitel))
          for (final a in g.aufgaben) a.text,
      ];

      expect(alle, hasLength(4));
      expect(alle.toSet(), hasLength(4));
      expect(
        alle.toSet(),
        {
          'Nach dem Aufstehen: A',
          'Ohne Anker B',
          'Bei Langeweile: C',
          'Vor dem Schlafengehen: D',
        },
      );
    });

    test('jede Aufgabe weiss, aus welchem Kapitel sie kommt', () {
      // Das Themen-Abzeichen haengt daran.
      final gruppen = tagesliste([
        _kapitel(AnalyseModul.basis, ['Nach dem Aufstehen: A']),
        _kapitel(AnalyseModul.zaehneLaecheln, ['Nach dem Aufstehen: B']),
      ]);

      final module = {
        for (final a in gruppen.single.aufgaben) a.text: a.modul,
      };
      expect(module['Nach dem Aufstehen: A'], AnalyseModul.basis);
      expect(module['Nach dem Aufstehen: B'], AnalyseModul.zaehneLaecheln);
    });

    test('ohne Kapitel gibt es keine Gruppen', () {
      expect(tagesliste(const []), isEmpty);
      expect(tagesliste([_kapitel(AnalyseModul.basis, const [])]), isEmpty);
    });
  });

  group('Der Demo-Modus zeigt alle vier Abschnitte', () {
    for (final modus in AnalyseModus.values) {
      test(modus.name, () {
        final report = AnalysisResult.vonApi(
          JsonExtractor.extrahiere(
            MockAnalysisService.antwortFuer(
              AnalyseModul.bestellbar.toSet(),
              modus: modus,
            ),
          )!,
          id: 'demo',
          erstelltAm: DateTime(2026, 8, 28),
        );

        final gruppen = tagesliste(report.checklisten);

        expect(
          [for (final g in gruppen) g.abschnitt],
          Tagesabschnitt.values,
          reason: 'ohne alle vier laesst sich die Sortierung im Demo-Modus '
              'nicht abnehmen',
        );
      });

      test('${modus.name}: alle sieben Anker kommen vor', () {
        final report = AnalysisResult.vonApi(
          JsonExtractor.extrahiere(
            MockAnalysisService.antwortFuer(
              AnalyseModul.bestellbar.toSet(),
              modus: modus,
            ),
          )!,
          id: 'demo',
          erstelltAm: DateTime(2026, 8, 28),
        );

        final anker = {
          for (final kapitel in report.checklisten)
            for (final habit in kapitel.habits)
              if (ankerVon(habit) case final a?) a.toLowerCase(),
        };

        for (final erwartet in _ankerDe) {
          expect(anker, contains(erwartet.toLowerCase()), reason: erwartet);
        }
      });
    }
  });

  group('Im Heute-Tab', () {
    testWidgets('steht eine Karte je Abschnitt, mit Zähler', (tester) async {
      handyGroesse(tester, hoehe: 2400);

      await tester.pumpWidget(
        testHuelle(
          ProviderScope(
            overrides: speicherOverrides(),
            child: Scaffold(
              body: ListView(
                children: [
                  for (final gruppe in tagesliste([
                    _kapitel(AnalyseModul.basis, [
                      'Nach dem Aufstehen: Haare richten',
                      'Vor dem Schlafengehen: Bartöl einarbeiten',
                    ]),
                  ]))
                    AbschnittKarte(gruppe: gruppe),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(texte.abschnittMorgens), findsOneWidget);
      expect(find.text(texte.abschnittAbends), findsOneWidget);
      // Je Abschnitt ein eigener Zaehler.
      expect(find.text('0/1'), findsNWidgets(2));
    });

    testWidgets('und jede Zeile trägt das Symbol ihres Kapitels',
        (tester) async {
      handyGroesse(tester, hoehe: 2400);

      await tester.pumpWidget(
        testHuelle(
          ProviderScope(
            overrides: speicherOverrides(),
            child: Scaffold(
              body: ListView(
                children: [
                  for (final gruppe in tagesliste([
                    _kapitel(AnalyseModul.basis, ['Nach dem Aufstehen: A']),
                    _kapitel(
                      AnalyseModul.zaehneLaecheln,
                      ['Nach dem Aufstehen: B'],
                    ),
                  ]))
                    AbschnittKarte(gruppe: gruppe),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seit die Ueberschrift die Tageszeit nennt, ist das Abzeichen die
      // einzige Angabe zum Thema.
      expect(find.byIcon(AnalyseModul.basis.icon), findsOneWidget);
      expect(find.byIcon(AnalyseModul.zaehneLaecheln.icon), findsOneWidget);
    });
  });
}
