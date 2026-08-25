import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/logic/analyse_anfrage.dart';
import 'package:trueglow/features/analysis/logic/json_extractor.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/analysis/models/analysis_result.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/checkin/logic/checkin_anfrage.dart';
import 'package:trueglow/features/checkin/logic/checkin_service.dart';
import 'package:trueglow/features/checkin/models/checkin.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

import 'hilfen.dart';

/// Die englischen Texte – als Gegenprobe zu [texte] aus `hilfen.dart`.
final englisch = lookupL(const Locale('en'));

void main() {
  group('Sprachwahl', () {
    test('ohne Wahl folgt die App dem Gerät', () {
      // Nicht Deutsch heißt Englisch. Für Französisch gibt es keine
      // Übersetzung, und ein französisches Gerät auf Deutsch zu stellen wäre
      // die schlechtere Vermutung.
      expect(Sprache.fuerGeraet(const Locale('de')), Sprache.deutsch);
      expect(Sprache.fuerGeraet(const Locale('de', 'AT')), Sprache.deutsch);
      expect(Sprache.fuerGeraet(const Locale('en')), Sprache.englisch);
      expect(Sprache.fuerGeraet(const Locale('fr')), Sprache.englisch);
      expect(Sprache.fuerGeraet(const Locale('tr')), Sprache.englisch);
    });

    test('die Wahl übersteht einen Neustart', () {
      // Derselbe Speicher, zwei Controller – genau das passiert beim
      // Neustart der App.
      final speicher = MemoryStore();

      SprachController(speicher).setzen(Sprache.englisch);

      expect(SprachController(speicher).state, Sprache.englisch);
    });

    test('„noch nichts gewählt" ist etwas anderes als Deutsch', () {
      // Wer nie gewählt hat, soll dem Gerät weiter folgen – auch wenn er es
      // später umstellt. Stünde hier nach dem ersten Start „de" im Speicher,
      // wäre die Sprache ungefragt eingefroren.
      final speicher = MemoryStore();

      expect(SprachController(speicher).state, isNull);
      expect(speicher.get('sprache'), isNull);
    });

    test('nach dem Löschen aller Daten folgt die App wieder dem Gerät', () {
      final speicher = MemoryStore();
      final controller = SprachController(speicher)..setzen(Sprache.englisch);

      speicher.clear();
      controller.neuLaden();

      expect(controller.state, isNull);
    });

    test('jede Sprache hat einen Code, einen Namen und ein Kürzel', () {
      for (final sprache in Sprache.values) {
        expect(sprache.code.length, 2, reason: sprache.name);
        expect(sprache.name, isNotEmpty);
        expect(sprache.kuerzel.length, 2, reason: sprache.name);
      }
    });
  });

  group('Sprachwechsel in der App', () {
    testWidgets('der Umschalter in den Einstellungen ändert die Oberfläche',
        (tester) async {
      handyGroesse(tester, hoehe: 3000);
      final container = await appMitDashboard(tester);

      container.read(routerProvider).go(Routes.settings);
      await tester.pumpAndSettle();

      expect(find.text(texte.einstellungenTitel), findsWidgets);

      await tester.tap(find.text(Sprache.englisch.name));
      await tester.pumpAndSettle();

      // Derselbe Screen, andere Sprache – und die deutsche Fassung ist weg.
      expect(find.text(englisch.einstellungenTitel), findsWidgets);
      expect(find.text(texte.einstellungenDatenLoeschen), findsNothing);
      expect(find.text(englisch.einstellungenDatenLoeschen), findsOneWidget);
    });

    testWidgets('der Wechsel wirkt auch auf Screens, die schon standen',
        (tester) async {
      // Der eigentliche Grund für den Zugriff über den Kontext statt über
      // eine globale Variable: Ein Sprachwechsel muss den ganzen Baum neu
      // bauen, nicht nur den Screen, auf dem der Schalter sitzt.
      handyGroesse(tester, hoehe: 3000);
      final container = await appMitDashboard(tester);

      // appMitDashboard setzt die Zustaende ueber die Provider. Der Router
      // wertet seine Weichen erst beim naechsten Navigieren neu aus – ohne
      // diesen Schritt stuende noch das Onboarding auf dem Schirm.
      container.read(routerProvider).go(Routes.home);
      await tester.pumpAndSettle();

      expect(find.text(texte.homeLeerTitel), findsOneWidget);

      container.read(sprachControllerProvider.notifier).setzen(Sprache.englisch);
      await tester.pumpAndSettle();

      expect(find.text(englisch.homeLeerTitel), findsOneWidget);
      expect(find.text(texte.homeLeerTitel), findsNothing);
    });
  });

  group('Sprache des Reports', () {
    test('die Analyse-Anfrage nimmt die Zielsprache mit', () {
      // Der Prompt liegt auf dem Server. Vom Gerät geht deshalb nur der
      // Sprachcode mit – der Server entscheidet daraus, in welcher Sprache
      // Gemini antworten soll.
      final deutsch = AnalyseAnfrage.bauen(
        bilder: const {AufnahmeTyp.basisFrontal: 'AAAA'},
        module: {AnalyseModul.basis},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
        sprache: Sprache.deutsch,
      );
      final englisch = AnalyseAnfrage.bauen(
        bilder: const {AufnahmeTyp.basisFrontal: 'AAAA'},
        module: {AnalyseModul.basis},
        onboarding: const OnboardingProfile(),
        eingaben: const ModulEingaben(),
        sprache: Sprache.englisch,
      );

      expect(deutsch['sprache'], 'de');
      expect(englisch['sprache'], 'en');
    });

    test('die Check-in-Anfrage ebenso', () {
      final anfrage = CheckinAnfrage.bauen(
        checkin: Checkin(
          id: 0,
          typ: CheckinTyp.alltag,
          faelligAm: DateTime(2026, 9, 1),
        ),
        analyse: AnalysisResult.vonApi(
          JsonExtractor.extrahiere(
            MockAnalysisService.antwortFuer({AnalyseModul.basis}),
          )!,
          id: 'a1',
          erstelltAm: DateTime(2026, 8, 22),
        ),
        historie: const [],
        sprache: Sprache.englisch,
        ausrichtung: Ausrichtung.maennlich,
      );

      expect(anfrage['sprache'], 'en');
    });

    test('die Attrappe antwortet in der gewählten Sprache', () async {
      // Im Demo-Modus schreibt die Attrappe den Text selbst. Sie muss
      // derselben Sprachwahl folgen wie der echte Dienst – sonst sähe ein
      // Screenshot-Durchlauf auf Englisch plötzlich deutsch aus.
      final analyse = AnalysisResult.vonApi(
        JsonExtractor.extrahiere(
          MockAnalysisService.antwortFuer({AnalyseModul.basis}),
        )!,
        id: 'a1',
        erstelltAm: DateTime(2026, 8, 22),
      );
      final habit = analyse.kapitel.first.habits.first;
      final checkin = Checkin(
        id: 0,
        typ: CheckinTyp.alltag,
        faelligAm: DateTime(2026, 9, 1),
      )
          .mitBewertung(habit, HabitBewertung.passtNicht)
          .mitGrund(habit, PasstNichtGrund.zeit);

      final auf = await const MockCheckinService().auswerten(
        checkin: checkin,
        analyse: analyse,
        historie: const [],
        sprache: Sprache.englisch,
        ausrichtung: Ausrichtung.maennlich,
      );

      expect(auf.zusammenfassung, contains("didn't fit your day"));
      expect(auf.anpassungen.single.neu, contains('30 seconds'));
    });
  });

  group('Vollständigkeit', () {
    test('beide Sprachen liefern zu jedem Text etwas', () {
      // Stichprobe über die Texte, die auf dem ersten Bildschirm stehen.
      // Die harte Vollständigkeitsprüfung macht `gen-l10n` selbst: In
      // l10n.yaml steht `untranslated-messages-file`, eine fehlende
      // Übersetzung landet dort und fällt beim Bauen auf.
      final proben = <String Function(L)>[
        (l) => l.appName,
        (l) => l.weiter,
        (l) => l.homeLeerTitel,
        (l) => l.koerperNichtGanz,
        (l) => l.aufnahmeFehlgeschlagen,
        (l) => l.einstellungenSprache,
        (l) => l.disclaimerMedizin,
      ];

      for (final probe in proben) {
        expect(probe(texte), isNotEmpty);
        expect(probe(englisch), isNotEmpty);
      }
    });

    test('Deutsch und Englisch sind wirklich verschieden', () {
      // Fängt das versehentliche Kopieren der deutschen Datei nach
      // app_en.arb ab – das würde jede andere Prüfung bestehen.
      expect(englisch.homeLeerTitel, isNot(texte.homeLeerTitel));
      expect(englisch.koerperNichtGanz, isNot(texte.koerperNichtGanz));
      expect(englisch.einstellungenDatenLoeschen,
          isNot(texte.einstellungenDatenLoeschen));
    });

    test('Zahlen und Datum folgen der Sprache', () {
      // Der Plural steckt in der ARB-Datei, nicht im Dart-Code – im
      // Englischen ist „1 of 3" ohne „Noch" die richtige Form.
      expect(texte.kontingentUebrig(1, 3), contains('1 von 3'));
      expect(texte.kontingentUebrig(2, 3), contains('2 von 3'));
      expect(englisch.kontingentUebrig(1, 3), contains('1 of 3'));
      expect(englisch.kontingentUebrig(2, 3), contains('2 of 3'));
    });

    test('die Oberflaeche enthaelt kein fest verdrahtetes Deutsch', () {
      // Zwei deutsche Zeilen sind erst am Gerät aufgefallen, nachdem die App
      // auf Englisch stand: „Heute alles erledigt. Stark." in der
      // Streak-Karte und „Nächster Check-in in 7 Tagen", bei dem der
      // Zeitraum im Dart-Code zusammengesetzt wurde. Beides sah im Quelltext
      // unauffällig aus – genau deshalb liest diese Prüfung alle Dateien
      // unter lib/ und meldet jede Zeichenkette, die nach deutschem
      // Anzeigetext aussieht.
      //
      // Die Prüfung ist eine Heuristik und kann nicht jeden Fall erkennen.
      // Sie ist trotzdem sinnvoll: Sie kostet nichts und fängt die Fälle,
      // die man beim Übersetzen übersieht, weil der Satz kurz ist.

      // Wörter, die im Englischen nicht vorkommen oder dort etwas anderes
      // heißen. Zwei davon in einer Zeichenkette gelten als Deutsch.
      const woerter = [
        'aber', 'alle', 'alles', 'auch', 'auf', 'aus', 'beim', 'bereits',
        'bitte', 'Bitte', 'brauchst', 'dann', 'das', 'dass', 'dein', 'deine',
        'deinen', 'deiner', 'dem', 'den', 'der', 'des', 'dich', 'die', 'dir',
        'doch', 'dort', 'du', 'durch', 'ein', 'eine', 'einen', 'einer',
        'eines', 'erledigt', 'erst', 'etwas', 'für', 'fuer', 'gegen',
        'gemacht', 'genug', 'gerade', 'gleich', 'hast', 'hat', 'heute',
        'Heute', 'hier', 'ihr', 'immer', 'ist', 'jetzt', 'kann', 'kannst',
        'kein', 'keine', 'keinen', 'lässt', 'legst', 'mehr', 'mit', 'nach',
        'nicht', 'noch', 'nur', 'oder', 'ohne', 'schon', 'sein', 'seine',
        'sich', 'sie', 'sind', 'so', 'später', 'über', 'und', 'uns', 'vom',
        'von', 'vor', 'wähle', 'wählst', 'warum', 'was', 'weil', 'weiter',
        'welche', 'wenn', 'wer', 'wie', 'wieder', 'wir', 'wird', 'wirst',
        'zum', 'zur', 'zwei',
      ];

      // Wörter, die schon allein reichen – auch ohne Satz drumherum. Damit
      // fällt der Bausatz aus dem Check-in auf: `tage == 1 ? 'Tag' : 'Tagen'`.
      const alleinReichend = [
        'Tag', 'Tage', 'Tagen', 'Woche', 'Wochen', 'Monat', 'Monate',
        'Monaten', 'Stunde', 'Stunden', 'Minute', 'Minuten', 'Jahr', 'Jahre',
        'Jahren', 'Heute', 'Gestern', 'Morgen', 'Abbrechen', 'Weiter',
        'Zurück', 'Fertig', 'Speichern', 'Löschen', 'Schließen',
      ];

      // Bewusst deutsch. Der Einrichtungshinweis läuft außerhalb der
      // `MaterialApp` und damit ohne Lokalisierung; die Mock-Analyse steht
      // für eine Modellantwort, nicht für Oberfläche; und der Fehlerbericht
      // aus `rechtstexte.dart` erscheint nur, solange die Rechtstexte
      // Entwurf sind, nennt einen Dateipfad und ist an uns gerichtet.
      const ausnahmen = [
        'lib/firebase_options.dart',
        'lib/core/firebase/einrichtung_hinweis.dart',
        'lib/features/analysis/logic/mock_analysis_service.dart',
        'lib/features/legal/logic/rechtstexte.dart',
      ];

      final umlaut = RegExp('[äöüÄÖÜß]');
      final wort = RegExp(r'(?<![A-Za-zÄÖÜäöüß])(' + woerter.join('|') +
          r')(?![A-Za-zÄÖÜäöüß])');
      final allein = RegExp('^(${alleinReichend.join('|')})\$');
      // Zeilen, die nie an die Oberfläche gehen.
      final egal = RegExp(r'debugPrint|assert\(|^\s*//|^\s*\*|^\s*import ');
      final wurf = RegExp(r'throw |Error\(|Exception\(');
      final literale = RegExp('\'([^\'\n]{2,})\'|"([^"\n]{2,})"');

      final funde = <String>[];
      for (final eintrag in Directory('lib').listSync(recursive: true)) {
        if (eintrag is! File || !eintrag.path.endsWith('.dart')) continue;
        final pfad = eintrag.path.replaceAll(r'\', '/');
        // lib/l10n/ ist die Übersetzung selbst.
        if (pfad.contains('/l10n/')) continue;
        if (ausnahmen.contains(pfad)) continue;

        final zeilen = eintrag.readAsLinesSync();
        // Ein `throw` reicht oft über mehrere Zeilen; sein Text steht dann
        // nicht auf der Zeile mit dem Schlüsselwort.
        var imWurf = false;
        for (var i = 0; i < zeilen.length; i++) {
          final zeile = zeilen[i];
          if (imWurf) {
            if (zeile.contains(';')) imWurf = false;
            continue;
          }
          if (wurf.hasMatch(zeile)) {
            if (!zeile.contains(';')) imWurf = true;
            continue;
          }
          if (egal.hasMatch(zeile)) continue;

          for (final treffer in literale.allMatches(zeile)) {
            final text = treffer.group(1) ?? treffer.group(2)!;
            final verdacht = allein.hasMatch(text) ||
                (text.contains(' ') &&
                    (umlaut.hasMatch(text) ||
                        wort.allMatches(text).length >= 2));
            if (verdacht) funde.add('$pfad:${i + 1}  $text');
          }
        }
      }

      expect(
        funde,
        isEmpty,
        reason: 'Diese Texte gehören in lib/l10n/app_de.arb und app_en.arb:\n'
            '${funde.join('\n')}',
      );
    });
  });
}
