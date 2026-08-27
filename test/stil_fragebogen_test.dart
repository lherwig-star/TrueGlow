import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/capture/ui/schritte/stil_fragebogen.dart';
import 'package:trueglow/features/direction/logic/direction_controller.dart';
import 'package:trueglow/features/direction/models/richtung.dart';
import 'package:trueglow/features/modules/logic/module_controller.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';

import 'hilfen.dart';

/// Der Stil-Fragebogen nach DECISIONS 72.
///
/// Zwei Dinge haben sich geaendert: Die Stilrichtung ist dieselbe Liste wie
/// bei „Deine Richtung", und aus dem Dresscode ist die Frage geworden, wofuer
/// der Stil funktionieren soll. Was hier geprueft wird, ist vor allem das
/// Dritte: dass niemandes gespeicherte Antwort dabei verloren geht.
void main() {
  hiveImTest();

  StilAngaben lies(Map<String, dynamic> json) => StilAngaben.fromJson(json);

  group('Alte Antworten werden überführt', () {
    test('jedes alte Stilziel hat einen Nachfolger', () {
      // Der Grundsatz wie bei DECISIONS 58: der naechste vorhandene Nachbar,
      // nie ein Wegfall. Wer „Rockig" gewaehlt hatte, findet seine Auswahl
      // wieder und raetselt nicht, warum sie leer ist.
      const erwartet = {
        'klassisch': Richtungsziel.smartHochwertig,
        'minimalistisch': Richtungsziel.cleanGepflegt,
        'sportlich': Richtungsziel.sportlichFunktional,
        'smartCasual': Richtungsziel.smartHochwertig,
        'kreativ': Richtungsziel.kreativAuffaellig,
        'rockig': Richtungsziel.markantMaskulin,
      };

      for (final eintrag in erwartet.entries) {
        expect(
          lies({'ziele': [eintrag.key]}).ziele,
          {eintrag.value},
          reason: eintrag.key,
        );
      }
    });

    test('zwei alte Werte auf einem neuen geben keine Dublette', () {
      expect(
        lies({'ziele': ['klassisch', 'smartCasual']}).ziele,
        {Richtungsziel.smartHochwertig},
      );
    });

    test('neue Namen werden unverändert gelesen', () {
      expect(
        lies({'ziele': ['streetwearLaessig']}).ziele,
        {Richtungsziel.streetwearLaessig},
      );
    });

    test('Büro und Business Casual werden zu „Arbeit / Nebenjob"', () {
      for (final alt in ['buero', 'businessCasual']) {
        expect(
          lies({'dresscode': alt}).zwecke,
          {Alltagszweck.arbeitNebenjob},
          reason: alt,
        );
      }
    });

    test('der Rest bleibt leer, statt etwas zu erfinden', () {
      // Handwerk und Uniform sind ersatzlos weg; Homeoffice und „keine
      // Vorgaben" haben keine naechstliegende Entsprechung. Leer ist
      // ehrlicher als geraten – die Frage ist ohnehin überspringbar.
      for (final alt in ['handwerk', 'uniform', 'homeoffice', 'frei']) {
        expect(lies({'dresscode': alt}).zwecke, isEmpty, reason: alt);
      }
    });

    test('Unbekanntes fällt weg, ohne etwas zu zerlegen', () {
      final angaben = lies({
        'ziele': ['gibtsNicht', 42, null, 'kreativ'],
        'dresscode': 'quatsch',
        'zwecke': ['gymSport', 'auchNicht'],
        'budget': 'mittel',
      });

      expect(angaben.ziele, {Richtungsziel.kreativAuffaellig});
      expect(angaben.zwecke, {Alltagszweck.gymSport});
      expect(angaben.budget, Kleidungsbudget.mittel);
    });

    test('Budget und Pflegeaufwand sind unberührt', () {
      final angaben = lies({'budget': 'gross', 'pflegeaufwand': 'minimal'});

      expect(angaben.budget, Kleidungsbudget.gross);
      expect(angaben.pflegeaufwand, Pflegeaufwand.minimal);
    });

    test('und was neu gespeichert wird, kommt unverändert zurück', () {
      const vorher = StilAngaben(
        ziele: {Richtungsziel.streetwearLaessig},
        zwecke: {Alltagszweck.ausgehenDates},
        budget: Kleidungsbudget.klein,
        pflegeaufwand: Pflegeaufwand.mittel,
      );

      final nachher = StilAngaben.fromJson(vorher.toJson());

      expect(nachher.ziele, vorher.ziele);
      expect(nachher.zwecke, vorher.zwecke);
      expect(nachher.budget, vorher.budget);
      expect(nachher.pflegeaufwand, vorher.pflegeaufwand);
    });
  });

  group('Die Frage nach dem Zweck darf offen bleiben', () {
    test('ohne Zweck gilt der Fragebogen trotzdem als beantwortet', () {
      const ohne = StilAngaben(
        ziele: {Richtungsziel.cleanGepflegt},
        budget: Kleidungsbudget.mittel,
        pflegeaufwand: Pflegeaufwand.mittel,
      );

      expect(ohne.istVollstaendig, isTrue);
    });

    test('ohne Stilrichtung dagegen nicht', () {
      const ohne = StilAngaben(
        zwecke: {Alltagszweck.gymSport},
        budget: Kleidungsbudget.mittel,
        pflegeaufwand: Pflegeaufwand.mittel,
      );

      expect(ohne.istVollstaendig, isFalse);
    });
  });

  group('Der Fragebogen selbst', () {
    Future<ProviderContainer> zeige(
      WidgetTester tester, {
      Richtung richtung = Richtung.leer,
    }) async {
      handyGroesse(tester, hoehe: 2400);

      final container = ProviderContainer(overrides: speicherOverrides());
      addTearDown(container.dispose);

      for (final ziel in richtung.ziele) {
        container.read(directionControllerProvider.notifier).umschalten(ziel);
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            const Scaffold(
              body: SingleChildScrollView(child: StilFragebogen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return container;
    }

    testWidgets('bietet dieselben acht Stilrichtungen wie „Deine Richtung"',
        (tester) async {
      await zeige(tester);

      for (final ziel in Richtungsziel.values) {
        expect(find.text(ziel.label(texte)), findsOneWidget,
            reason: ziel.name);
      }
    });

    testWidgets('und die alte Liste kommt nirgends mehr vor', (tester) async {
      await zeige(tester);

      for (final alt in [
        'Klassisch',
        'Minimalistisch',
        'Smart Casual',
        'Rockig',
        'Handwerk / Arbeitskleidung',
        'Uniform / Dienstkleidung',
        'Büro / formell',
      ]) {
        expect(find.text(alt), findsNothing, reason: alt);
      }
    });

    testWidgets('fragt stattdessen, wofür der Style funktionieren soll',
        (tester) async {
      await zeige(tester);

      expect(find.text(texte.stilZweck), findsOneWidget);
      for (final zweck in Alltagszweck.values) {
        expect(find.text(zweck.label(texte)), findsOneWidget,
            reason: zweck.name);
      }
    });

    testWidgets('ist aus „Deine Richtung" vorbelegt', (tester) async {
      // Vorbelegt und nicht nur angezeigt: Sonst waere der erste Tipp auf
      // einen markierten Chip ein Abwaehlen von etwas, das nie gespeichert
      // war.
      final container = await zeige(
        tester,
        richtung: const Richtung(
          ziele: {Richtungsziel.streetwearLaessig},
          freitext: '',
        ),
      );

      expect(
        container.read(moduleControllerProvider).eingaben.stil.ziele,
        {Richtungsziel.streetwearLaessig},
      );
    });

    testWidgets('und trotzdem änderbar', (tester) async {
      final container = await zeige(
        tester,
        richtung: const Richtung(
          ziele: {Richtungsziel.streetwearLaessig},
          freitext: '',
        ),
      );

      await tester.tap(
        find.text(Richtungsziel.streetwearLaessig.label(texte)),
      );
      await tester.pumpAndSettle();

      // Die Richtung selbst bleibt, wie sie war – hier geht es nur um die
      // Kleidung.
      expect(
        container.read(moduleControllerProvider).eingaben.stil.ziele,
        isEmpty,
      );
      expect(
        container.read(directionControllerProvider).ziele,
        {Richtungsziel.streetwearLaessig},
      );
    });

    testWidgets('ohne gewählte Richtung bleibt nichts vorbelegt',
        (tester) async {
      final container = await zeige(tester);

      expect(
        container.read(moduleControllerProvider).eingaben.stil.ziele,
        isEmpty,
      );
    });
  });
}
