import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/features/analysis/logic/analyse_anfrage.dart';
import 'package:trueglow/features/analysis/models/analyse_modus.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/direction/models/richtung.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

/// Die Form der Anfrage, die wirklich an die Cloud Function geht.
///
/// **Warum es diese Datei gibt.** Am 27.08.2026 fiel die Analyse aus, und der
/// erste Verdacht war ein Versatz zwischen App und Server: Die App hatte am
/// selben Tag zwei neue Felder bekommen (Modus, neue Stilrichtungen). Es war
/// am Ende etwas anderes (DECISIONS 59) — aber die Frage liess sich nicht
/// schnell beantworten, weil **kein Test die beiden Seiten aneinanderhaelt**.
/// Die Dart-Tests prueften die App, die TypeScript-Tests prueften den Server,
/// und dazwischen war nichts.
///
/// Diese Datei schliesst die Luecke von der Dart-Seite: Sie schreibt die
/// echte Nutzlast in eine Datei, die der Server-Test
/// (`functions/test/anfrage_form.test.ts`) einliest und durch `leseAnalyse`
/// schickt. Faellt dort ein Feld heraus oder heisst es anders, schlaegt der
/// Server-Test fehl — im Testlauf, nicht am Geraet.
///
/// Die Datei ist eingecheckt. Aendert sich die Nutzlast, aendert sich die
/// Datei mit, und der Unterschied steht im Commit.
void main() {
  const ordner = 'functions/test/fixtures';

  /// Ein Fall, den die App wirklich so verschickt.
  Map<String, dynamic> nutzlast({
    required AnalyseModus modus,
    required Sprache sprache,
  }) {
    return AnalyseAnfrage.bauen(
      // Die Bilddaten sind hier Platzhalter: Was geprueft wird, ist die
      // Form der Nutzlast, nicht der Inhalt eines JPEGs.
      bilder: const {
        AufnahmeTyp.basisFrontal: 'AAAA',
        AufnahmeTyp.basisProfilLinks: 'BBBB',
        AufnahmeTyp.figurGanzkoerperFrontal: 'CCCC',
      },
      module: const {
        AnalyseModul.basis,
        AnalyseModul.hautFarbtyp,
        AnalyseModul.figurPassform,
        AnalyseModul.stilKleiderschrank,
      },
      onboarding: const OnboardingProfile(
        alter: Altersbereich.a25bis34,
        budget: Budget.mittel,
        zeit: Zeitbudget.mittel,
        fokus: {Fokusbereich.haut, Fokusbereich.haare},
        geschlecht: Geschlecht.maennlich,
      ),
      eingaben: const ModulEingaben(
        figur: FigurAngaben(groesseCm: 182, gewichtKg: 78),
        stil: StilAngaben(
          ziele: {Stilziel.smartCasual},
          dresscode: Dresscode.businessCasual,
          budget: Kleidungsbudget.mittel,
          pflegeaufwand: Pflegeaufwand.mittel,
        ),
      ),
      sprache: sprache,
      richtung: const Richtung(
        ziele: {
          Richtungsziel.streetwearLaessig,
          Richtungsziel.smartHochwertig,
        },
        freitext: 'Ich will im Bewerbungsgespräch souverän wirken.',
      ),
      modus: modus,
    );
  }

  final faelle = <String, Map<String, dynamic>>{
    'entdecken_de': nutzlast(
      modus: AnalyseModus.entdecken,
      sprache: Sprache.deutsch,
    ),
    'verfeinern_en': nutzlast(
      modus: AnalyseModus.verfeinern,
      sprache: Sprache.englisch,
    ),
  };

  group('Die Nutzlast an die Function', () {
    test('ist eingecheckt und aktuell', () {
      // Der Server-Test liest genau diese Dateien. Waeren sie veraltet,
      // pruefte er eine Anfrage, die es nicht mehr gibt.
      Directory(ordner).createSync(recursive: true);
      const kodierer = JsonEncoder.withIndent('  ');

      final abweichend = <String>[];
      for (final fall in faelle.entries) {
        final datei = File('$ordner/anfrage_${fall.key}.json');
        final soll = '${kodierer.convert(fall.value)}\n';
        if (!datei.existsSync() || datei.readAsStringSync() != soll) {
          datei.writeAsStringSync(soll);
          abweichend.add(datei.path);
        }
      }

      expect(
        abweichend,
        isEmpty,
        reason: 'Die Nutzlast hat sich geaendert. Die Dateien wurden neu '
            'geschrieben – bitte pruefen, ob der Server sie noch versteht '
            '(functions: npm test), und mit einchecken.',
      );
    });

    test('enthaelt genau die Felder, die der Server erwartet', () {
      // Ein Feld mehr ist harmlos (der Server ignoriert Unbekanntes), ein
      // Feld weniger oder ein anderer Name ist der Ausfall.
      for (final fall in faelle.entries) {
        expect(
          fall.value.keys.toSet(),
          {
            'sprache',
            'modus',
            'ausrichtung',
            'module',
            'profil',
            'eingaben',
            'richtung',
            'bilder',
          },
          reason: fall.key,
        );
      }
    });

    test('schickt Enum-Namen, keine Anzeigetexte', () {
      // Der Server schlaegt Namen in seinen Tabellen nach. Ein uebersetzter
      // Text faende dort nichts und fiele stillschweigend heraus.
      final daten = faelle['entdecken_de']!;

      expect(daten['sprache'], 'de');
      expect(daten['modus'], 'entdecken');
      expect(daten['ausrichtung'], 'maennlich');
      expect(daten['module'], [
        'basis',
        'hautFarbtyp',
        'figurPassform',
        'stilKleiderschrank',
      ]);
      expect(
        (daten['richtung'] as Map)['ziele'],
        ['streetwearLaessig', 'smartHochwertig'],
      );
      expect((daten['profil'] as Map)['alter'], 'a25bis34');
    });

    test('nichts Persoenliches faehrt mit, was der Prompt nicht braucht', () {
      // Dieselbe Zusage wie in `analyse_anfrage.dart`: keine Pfade, keine
      // Geraetekennung, kein Zustimmungsstatus.
      final roh = jsonEncode(faelle['entdecken_de']);

      for (final verboten in ['pfad', 'path', 'geraet', 'device', 'zustimm']) {
        expect(
          roh.toLowerCase(),
          isNot(contains(verboten)),
          reason: verboten,
        );
      }
    });
  });
}
