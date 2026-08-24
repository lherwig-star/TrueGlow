import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glowup/core/cloud/cloud_modell.dart';
import 'package:glowup/core/cloud/cloud_speicher.dart';
import 'package:glowup/core/storage/hive_service.dart';
import 'package:glowup/core/storage/key_value_store.dart';
import 'package:glowup/features/migration/logic/hive_migration.dart';

/// Vier leere Boxen, wie sie die App beim Start oeffnet.
Map<String, KeyValueStore> _boxen() => {
      for (final name in HiveService.alleBoxen) name: MemoryStore(),
    };

/// Ein typischer Bestand aus der Zeit ohne Konto.
Map<String, KeyValueStore> _bestand() {
  final boxen = _boxen();

  boxen[HiveService.boxEinstellungen]!
    ..put(CloudModell.keyOnboarding, '{"alter":"a25bis34"}')
    ..put(CloudModell.keyRichtung, '{"ziele":["markanter"],"freitext":""}')
    ..put(CloudModell.keyModule, ['basis', 'hautFarbtyp'])
    ..put(CloudModell.keyModulEingaben, '{"figur":{}}')
    ..put(CloudModell.keyAktuelleAnalyse, '17')
    ..put(CloudModell.keyErscheinungsbild, 'dunkel');

  boxen[HiveService.boxAnalysen]!.put('17', '{"id":"17"}');

  boxen[HiveService.boxFortschritt]!
    ..put('2026-08-23', ['Haare stylen'])
    ..put('2026-08-24', ['Haare stylen', 'Bart ölen'])
    ..put(CloudModell.keyStreakRekord, 9)
    ..put(CloudModell.keyStreakAktuell, 2)
    ..put(CloudModell.keyAbzeichen, ['ersteAnalyse']);

  boxen[HiveService.boxCheckins]!
    ..put(CloudModell.keyPlanStart, '2026-08-01T00:00:00.000')
    ..put(CloudModell.keyNaechsterIndex, 1)
    ..put(CloudModell.keyEntwurf, '{"id":1,"typ":"zwischen"}')
    ..put(
      CloudModell.keyHistorie,
      jsonEncode([
        {'id': 0, 'typ': 'alltag', 'faelligAm': '2026-08-08T00:00:00.000'},
      ]),
    );

  return boxen;
}

void main() {
  group('Was uebertragen wird', () {
    test('legt jede Sammlung dort ab, wo das Modell sie erwartet', () async {
      final speicher = SpeicherAttrappe();
      await HiveMigration(speicher: speicher, boxen: _bestand()).ausfuehren();

      final pfade = (await speicher.alleLesen()).map((d) => d.pfad).toSet();

      expect(pfade, containsAll([
        CloudModell.dokProfil,
        CloudModell.dokRichtung,
        CloudModell.dokModule,
        CloudModell.dokVerweise,
        CloudModell.dokStreak,
        CloudModell.dokMigration,
        'analysen/17',
        'fortschritt/2026-08-23',
        'fortschritt/2026-08-24',
        'checkins/0',
        CloudModell.dokCheckinPlan,
      ]));
    });

    test('fuehrt Schluessel, die sich ein Dokument teilen, zusammen', () async {
      final speicher = SpeicherAttrappe();
      await HiveMigration(speicher: speicher, boxen: _bestand()).ausfuehren();

      final module = await speicher.lesen(CloudModell.dokModule);
      expect(module!.daten, {
        'module': ['basis', 'hautFarbtyp'],
        'eingaben': '{"figur":{}}',
      });
    });

    test('faechert die Historie in einzelne Check-ins auf', () async {
      final speicher = SpeicherAttrappe();
      await HiveMigration(speicher: speicher, boxen: _bestand()).ausfuehren();

      final checkin = await speicher.lesen('checkins/0');
      expect(jsonDecode(checkin!.daten['wert'] as String), {
        'id': 0,
        'typ': 'alltag',
        'faelligAm': '2026-08-08T00:00:00.000',
      });
    });

    test('laesst Geraetezustand und Entwurf zurueck', () async {
      final speicher = SpeicherAttrappe();
      await HiveMigration(speicher: speicher, boxen: _bestand()).ausfuehren();

      final alles = jsonEncode([
        for (final dokument in await speicher.alleLesen()) dokument.daten,
      ]);

      expect(alles, isNot(contains('dunkel')));
      expect(alles, isNot(contains('"typ":"zwischen"')));
      // Der abgeleitete Tageszaehler wandert nicht mit, der Rekord schon.
      final streak = await speicher.lesen(CloudModell.dokStreak);
      expect(streak!.daten, {
        'rekord': 9,
        'gefeiert': ['ersteAnalyse'],
      });
    });
  });

  group('Idempotenz', () {
    test('ein zweiter Lauf schreibt nichts mehr', () async {
      final speicher = SpeicherAttrappe();
      final migration = HiveMigration(speicher: speicher, boxen: _bestand());

      final erste = await migration.ausfuehren();
      final nachErster = speicher.schreibzugriffe;

      final zweite = await migration.ausfuehren();

      expect(erste, greaterThan(0));
      expect(zweite, 0);
      expect(speicher.schreibzugriffe, nachErster);
    });

    test('ein Abbruch vor dem Marker fuehrt beim zweiten Lauf nicht zu '
        'Doppelten', () async {
      final speicher = SpeicherAttrappe();
      final boxen = _bestand();

      // Erster Lauf bis kurz vor den Marker: die Dokumente sind da, der
      // Marker fehlt.
      final migration = HiveMigration(speicher: speicher, boxen: boxen);
      await speicher.schreiben(migration.sammle(jetzt: DateTime.utc(2026, 8, 24)));
      final nachAbbruch = (await speicher.alleLesen()).length;

      await migration.ausfuehren();

      // Genau ein Dokument mehr: der Marker.
      expect((await speicher.alleLesen()).length, nachAbbruch + 1);
    });

    test('istNoetig kennt beide Abbruchgruende', () async {
      final leer = HiveMigration(speicher: SpeicherAttrappe(), boxen: _boxen());
      expect(await leer.istNoetig(), isFalse, reason: 'kein lokaler Bestand');

      final speicher = SpeicherAttrappe();
      final migration = HiveMigration(speicher: speicher, boxen: _bestand());
      expect(await migration.istNoetig(), isTrue);

      await migration.ausfuehren();
      expect(await migration.istNoetig(), isFalse, reason: 'Marker steht');
    });

    test('eine Ablehnung wird nicht erneut gefragt', () async {
      final speicher = SpeicherAttrappe();
      final migration = HiveMigration(speicher: speicher, boxen: _bestand());

      await migration.ablehnen();

      expect(await migration.istNoetig(), isFalse);
      // Abgelehnt ist die Uebernahme, nicht der Bestand.
      expect(migration.hatLokaleDaten(), isTrue);
      expect((await speicher.alleLesen()).single.pfad, CloudModell.dokMigration);
    });
  });

  group('Kaputte Daten', () {
    test('eine unlesbare Historie bricht die Uebernahme nicht ab', () async {
      final boxen = _bestand();
      boxen[HiveService.boxCheckins]!.put(CloudModell.keyHistorie, '{kaputt');

      final speicher = SpeicherAttrappe();
      final anzahl =
          await HiveMigration(speicher: speicher, boxen: boxen).ausfuehren();

      expect(anzahl, greaterThan(0));
      expect(await speicher.lesen('checkins/0'), isNull);
      expect(await speicher.lesen(CloudModell.dokProfil), isNotNull);
    });

    test('ein leerer Bestand erzeugt nur den Marker', () async {
      final speicher = SpeicherAttrappe();
      final anzahl =
          await HiveMigration(speicher: speicher, boxen: _boxen()).ausfuehren();

      expect(anzahl, 0);
      expect((await speicher.alleLesen()).single.pfad, CloudModell.dokMigration);
    });
  });
}
