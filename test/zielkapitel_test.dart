import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/features/analysis/logic/analyse_anfrage.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/capture/logic/aufnahme_flow.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/checkin/logic/plan_anpassung.dart';
import 'package:trueglow/features/checkin/models/checkin_auswertung.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

/// Das Kapitel „Persönliche Ziele".
///
/// Der Anlass steht in DECISIONS 39: Am Geraet landeten die Aufgaben aus dem
/// Freitext („Bei Rauchverlangen ein Glas kaltes Wasser trinken") unter
/// „Haare & Bart" – das Modell suchte das inhaltlich passendste Kapitel, und
/// fuer Rauchen gibt es keins.
///
/// Seitdem ist es ein eigenes Kapitel. Es verhaelt sich wie jedes andere,
/// mit einem Unterschied: Waehlen kann es niemand.
void main() {
  /// Eine Antwort, wie der Server sie liefert, wenn ein Freitext vorlag.
  Map<String, dynamic> antwortMitZielen() => {
        'kapitel': [
          {
            'modul': 'basis',
            'einleitung': 'Ovale Grundform.',
            'habits': ['Scheitel morgens nach links föhnen'],
            'sektionen': [
              {
                'titel': 'Frisur',
                'einschaetzung': 'Text',
                'empfehlungen': ['Schritt'],
                'produkte': <Map<String, dynamic>>[],
              },
            ],
          },
          {
            'modul': 'persoenlicheZiele',
            'einleitung': 'Du willst aufhören zu rauchen.',
            'habits': [
              'Bei Verlangen ein Glas kaltes Wasser trinken',
              'Nach dem Essen zwei Minuten vor die Tür',
            ],
            'sektionen': [
              {
                'titel': 'Dein Ziel',
                'einschaetzung': 'Text',
                'empfehlungen': ['Beim Kaffee die Hände beschäftigen'],
                'produkte': <Map<String, dynamic>>[],
              },
            ],
          },
        ],
        'plan': {
          'sofort': ['Heute Abend anfangen'],
          'dreissigTage': <String>[],
          'langfristig': <String>[],
        },
      };

  AnalysisResult gelesen() => AnalysisResult.vonApi(
        antwortMitZielen(),
        id: 'x',
        erstelltAm: DateTime(2026, 8, 26),
      );

  group('Der Freitext bekommt ein eigenes Kapitel', () {
    test('es wird als Kapitel gelesen', () {
      final ergebnis = gelesen();

      expect(ergebnis.module, {
        AnalyseModul.basis,
        AnalyseModul.persoenlicheZiele,
      });
      expect(ergebnis.kapitel.last.modul, AnalyseModul.persoenlicheZiele);
      expect(ergebnis.kapitel.last.einleitung, isNotEmpty);
    });

    test('es bringt eine eigene Karte in der Tagesliste mit', () {
      final ergebnis = gelesen();

      expect(ergebnis.checklisten.length, 2);
      final ziele = ergebnis.checklisten.last;
      expect(ziele.modul, AnalyseModul.persoenlicheZiele);
      expect(ziele.habits, hasLength(2));
    });

    test('die Look-Kapitel bleiben bei ihrem Thema', () {
      // Der eigentliche Fund: Unter „Haare & Bart" stand eine
      // Rauchfrei-Aufgabe. Aus der Basis kommt jetzt nur noch Basis.
      final basis = gelesen().kapitel.first;

      expect(basis.modul, AnalyseModul.basis);
      expect(basis.habits, ['Scheitel morgens nach links föhnen']);
    });

    test('es steht hinter den Look-Kapiteln', () {
      // Die Sortierung folgt der Reihenfolge im Enum – auch beim
      // nachtraeglichen Ergaenzen eines Moduls.
      final ergaenzt = gelesen().mitKapitel(
        const Kapitel(
          modul: AnalyseModul.zaehneLaecheln,
          einleitung: 'Text',
          sektionen: [],
          habits: ['Abends Zahnseide zwischen den Frontzähnen'],
        ),
      );

      expect(ergaenzt.kapitel.map((k) => k.modul).toList(), [
        AnalyseModul.basis,
        AnalyseModul.zaehneLaecheln,
        AnalyseModul.persoenlicheZiele,
      ]);
    });

    test('der Check-in kann seine Aufgaben anpassen', () {
      // Es ist ein Kapitel wie jedes andere – auch fuer den Check-in.
      final angepasst = planAnwenden(gelesen(), [
        const HabitAnpassung(
          modul: AnalyseModul.persoenlicheZiele,
          alt: 'Bei Verlangen ein Glas kaltes Wasser trinken',
          neu: 'Bei Verlangen drei Minuten an die frische Luft',
        ),
      ]);

      final ziele = angepasst.ergebnis.kapitel.last;
      expect(ziele.habits.first, 'Bei Verlangen drei Minuten an die frische Luft');
      expect(angepasst.neueHabits, hasLength(1));
    });
  });

  group('Waehlen kann es niemand', () {
    test('es steht in keiner Auswahlliste', () {
      expect(AnalyseModul.waehlbare, isNot(contains(AnalyseModul.persoenlicheZiele)));
      expect(AnalyseModul.bestellbar, isNot(contains(AnalyseModul.persoenlicheZiele)));

      for (final ausrichtung in Ausrichtung.values) {
        expect(
          AnalyseModul.waehlbareFuer(ausrichtung),
          isNot(contains(AnalyseModul.persoenlicheZiele)),
          reason: ausrichtung.name,
        );
      }
    });

    test('eine gespeicherte Auswahl nimmt es nicht auf', () {
      final module = AnalyseModul.ausNamen(['persoenlicheZiele', 'hautFarbtyp']);

      expect(module, {AnalyseModul.basis, AnalyseModul.hautFarbtyp});
    });

    test('es geht nicht als bestelltes Modul an den Server', () {
      final nutzlast = AnalyseAnfrage.bauen(
        bilder: const {AufnahmeTyp.basisFrontal: 'abc'},
        module: {AnalyseModul.basis, AnalyseModul.persoenlicheZiele},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
        sprache: Sprache.deutsch,
      );

      expect(nutzlast['module'], ['basis']);
    });

    test('es bringt keinen Schritt in den Foto-Flow', () {
      final schritte = baueAufnahmeFlow({
        AnalyseModul.basis,
        AnalyseModul.persoenlicheZiele,
      });
      final nurBasis = baueAufnahmeFlow({AnalyseModul.basis});

      expect(schritte.length, nurBasis.length);
    });
  });

  group('Ohne Freitext aendert sich nichts', () {
    test('ein Report ohne Zielkapitel sieht aus wie vorher', () {
      final ohne = AnalysisResult.vonApi(
        {
          'kapitel': [
            {
              'modul': 'basis',
              'einleitung': 'Ovale Grundform.',
              'habits': ['Scheitel morgens nach links föhnen'],
              'sektionen': <Map<String, dynamic>>[],
            },
          ],
          'plan': {'sofort': <String>[], 'dreissigTage': <String>[], 'langfristig': <String>[]},
        },
        id: 'x',
        erstelltAm: DateTime(2026, 8, 26),
      );

      expect(ohne.module, {AnalyseModul.basis});
      expect(ohne.checklisten, hasLength(1));
    });
  });
}
