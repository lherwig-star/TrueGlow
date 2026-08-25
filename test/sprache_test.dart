import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/key_value_store.dart';

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
  });
}
