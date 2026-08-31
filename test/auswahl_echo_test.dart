import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/analysis/models/analyse_modus.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/direction/models/richtung.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/result/ui/result_screen.dart';

import 'hilfen.dart';

/// Das Auswahl-Echo im Report-Kopf – DECISIONS 87.
///
/// Der Befund: Die gewählte Richtung floss in den Prompt ein und prägte den
/// Report – nur sah man das dem Report nicht an. Eine Auswahl, deren Folgen
/// unsichtbar bleiben, fühlt sich folgenlos an.
///
/// Geprüft wird beides: dass die eigenen Eingaben oben stehen **und** dass
/// dort nichts steht, was niemand gewählt hat.
void main() {
  hiveImTest();

  AnalysisResult analyse({
    Richtung richtung = Richtung.leer,
    AnalyseModus modus = AnalyseModus.verfeinern,
    List<String> neu = const [],
  }) =>
      AnalysisResult(
        id: '1',
        erstelltAm: DateTime(2026, 8, 31),
        richtung: richtung,
        modus: modus,
        kapitel: [
          Kapitel(
            modul: AnalyseModul.hautFarbtyp,
            einleitung: 'Warmer Unterton.',
            sektionen: [
              Sektion(
                titel: 'Haut',
                einschaetzung: 'Ruhiges Hautbild.',
                empfehlungen: const ['Morgens waschen.'],
                produkte: const [],
                neu: neu,
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

  Future<void> zeige(WidgetTester tester, AnalysisResult ergebnis) async {
    handyGroesse(tester, hoehe: 2400);

    final container = ProviderContainer(overrides: speicherOverrides());
    addTearDown(container.dispose);
    await container.read(analysenProvider.notifier).speichern(ergebnis);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testHuelle(const ResultScreen(analyseId: '1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Was der Nutzer gewählt hat, steht im Report', () {
    testWidgets('Richtungen, Techniken und Modus stehen oben', (tester) async {
      await zeige(
        tester,
        analyse(
          richtung: const Richtung(
            ziele: {
              Richtungsziel.streetwearLaessig,
              Richtungsziel.markantMaskulin,
            },
          ),
          modus: AnalyseModus.entdecken,
          neu: const ['Gua Sha'],
        ),
      );

      expect(find.text('${texte.ergebnisAuswahl}:'), findsOneWidget);
      expect(find.text(texte.richtungszielStreetwear), findsOneWidget);
      expect(find.text(texte.richtungszielMarkant), findsOneWidget);
      expect(find.text('Gua Sha'), findsWidgets);
      // Der Modus steht seit DECISIONS 90 in der Kopfzeile und ist keine
      // Pille mehr.
      expect(find.textContaining(texte.modusEntdeckenEtikett), findsOneWidget);
    });

    testWidgets('und zwar genau einmal, nicht zweimal auf demselben Schirm',
        (tester) async {
      // Die Richtungskarte zeigte dieselben Pillen ein zweites Mal. Seit
      // DECISIONS 90 gibt es die Karte nicht mehr – nach einer gelaufenen
      // Analyse liess sich dort ohnehin nichts mehr ändern.
      await zeige(
        tester,
        analyse(
          richtung: const Richtung(ziele: {Richtungsziel.cleanGepflegt}),
        ),
      );

      expect(find.text(texte.richtungszielClean), findsOneWidget);
      expect(find.text(texte.richtungTitel), findsNothing);
    });

    testWidgets('ohne Auswahl wird nichts erfunden', (tester) async {
      // „Ohne Auswahl kein Fake": Wer den Schritt übersprungen hat, findet
      // hier keine Richtung – nur den Modus, und der ist in jedem Durchlauf
      // eine echte Entscheidung.
      await zeige(tester, analyse());

      for (final ziel in Richtungsziel.values) {
        expect(find.text(ziel.label(texte)), findsNothing, reason: ziel.name);
      }
      expect(
        find.textContaining(texte.modusVerfeinernEtikett),
        findsOneWidget,
      );
      // Ohne Auswahl entfällt die Zeile ganz – kein leeres Label.
      expect(find.text('${texte.ergebnisAuswahl}:'), findsNothing);
    });

    testWidgets('eine nicht untergebrachte Technik wird nicht behauptet',
        (tester) async {
      // Quelle sind die Marken im Report, nicht die angetippte Liste: Was
      // das Modell nicht untergebracht hat, steht hier auch nicht.
      await zeige(tester, analyse(neu: const []));

      expect(find.text('Gua Sha'), findsNothing);
    });
  });
}
