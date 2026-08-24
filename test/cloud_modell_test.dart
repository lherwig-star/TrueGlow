import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/cloud/cloud_dokument.dart';
import 'package:trueglow/core/cloud/cloud_modell.dart';
import 'package:trueglow/core/cloud/cloud_speicher.dart';
import 'package:trueglow/core/storage/hive_service.dart';

void main() {
  group('CloudModell', () {
    test('bildet jeden synchronisierten Schluessel auf ein Dokument ab', () {
      const faelle = {
        (HiveService.boxEinstellungen, CloudModell.keyOnboarding):
            CloudZiel(CloudModell.dokProfil, 'wert'),
        (HiveService.boxEinstellungen, CloudModell.keyRichtung):
            CloudZiel(CloudModell.dokRichtung, 'wert'),
        (HiveService.boxEinstellungen, CloudModell.keyModule):
            CloudZiel(CloudModell.dokModule, 'module'),
        (HiveService.boxEinstellungen, CloudModell.keyModulEingaben):
            CloudZiel(CloudModell.dokModule, 'eingaben'),
        (HiveService.boxEinstellungen, CloudModell.keyAktuelleAnalyse):
            CloudZiel(CloudModell.dokVerweise, 'analyseId'),
        (HiveService.boxFortschritt, CloudModell.keyStreakRekord):
            CloudZiel(CloudModell.dokStreak, 'rekord'),
        (HiveService.boxFortschritt, CloudModell.keyAbzeichen):
            CloudZiel(CloudModell.dokStreak, 'gefeiert'),
        (HiveService.boxCheckins, CloudModell.keyPlanStart):
            CloudZiel(CloudModell.dokCheckinPlan, 'planStart'),
        (HiveService.boxCheckins, CloudModell.keyNaechsterIndex):
            CloudZiel(CloudModell.dokCheckinPlan, 'naechsterIndex'),
        (HiveService.boxCheckins, CloudModell.keyNaechsterTermin):
            CloudZiel(CloudModell.dokCheckinPlan, 'naechsterTermin'),
        (HiveService.boxCheckins, CloudModell.keyNeueHabits):
            CloudZiel(CloudModell.dokCheckinPlan, 'neueHabits'),
      };

      for (final eintrag in faelle.entries) {
        final (box, schluessel) = eintrag.key;
        expect(
          CloudModell.ziel(box, schluessel),
          eintrag.value,
          reason: '$box/$schluessel',
        );
      }
    });

    test('Analysen und Tage bekommen ein eigenes Dokument', () {
      expect(
        CloudModell.ziel(HiveService.boxAnalysen, '1755000000000'),
        const CloudZiel('analysen/1755000000000', 'wert'),
      );
      expect(
        CloudModell.ziel(HiveService.boxFortschritt, '2026-08-24'),
        const CloudZiel('fortschritt/2026-08-24', 'erledigt'),
      );
    });

    test('Geraetezustand und abgeleitete Werte bleiben lokal', () {
      const lokalBleibt = [
        (HiveService.boxEinstellungen, CloudModell.keyErscheinungsbild),
        (HiveService.boxCheckins, CloudModell.keyEntwurf),
        (HiveService.boxFortschritt, CloudModell.keyStreakAktuell),
        (HiveService.boxFortschritt, CloudModell.keyStreakLetzterTag),
      ];

      for (final (box, schluessel) in lokalBleibt) {
        expect(
          CloudModell.wirdSynchronisiert(box, schluessel),
          isFalse,
          reason: '$box/$schluessel',
        );
      }
    });

    test('der Aufnahmen-Index wandert mit, die Bilder nicht', () {
      // Er enthaelt Verweise auf lokale Dateien. Auf einem neuen Geraet
      // fehlen sie – dafuer gibt es den Platzhalter in der UI.
      expect(
        CloudModell.ziel(
          HiveService.boxEinstellungen,
          CloudModell.keyAufnahmen,
        ),
        const CloudZiel(CloudModell.dokAufnahmen, 'wert'),
      );
    });

    test('die Historie gilt als synchronisiert, aber ohne Feldabbildung', () {
      // Sie wird zu je einem Dokument pro Check-in aufgefaechert.
      expect(
        CloudModell.ziel(HiveService.boxCheckins, CloudModell.keyHistorie),
        isNull,
      );
      expect(
        CloudModell.wirdSynchronisiert(
          HiveService.boxCheckins,
          CloudModell.keyHistorie,
        ),
        isTrue,
      );
    });

    test('die Rueckrichtung trifft wieder denselben Schluessel', () {
      const paare = [
        (HiveService.boxEinstellungen, CloudModell.keyOnboarding),
        (HiveService.boxEinstellungen, CloudModell.keyModulEingaben),
        (HiveService.boxFortschritt, CloudModell.keyAbzeichen),
        (HiveService.boxCheckins, CloudModell.keyNaechsterTermin),
        (HiveService.boxAnalysen, '1755000000000'),
        (HiveService.boxFortschritt, '2026-08-24'),
      ];

      for (final (box, schluessel) in paare) {
        final ziel = CloudModell.ziel(box, schluessel)!;
        expect(
          CloudModell.lokal(ziel.pfad, ziel.feld),
          LokalesZiel(box, schluessel),
          reason: '$box/$schluessel',
        );
      }
    });

    test('Dokumente ohne lokale Entsprechung liefern null', () {
      expect(CloudModell.lokal(CloudModell.dokMigration, 'version'), isNull);
      expect(CloudModell.lokal('kontingent/analyse', 'tagZaehler'), isNull);
      expect(CloudModell.lokal('checkins/0', 'wert'), isNull);
    });
  });

  group('CloudDokument', () {
    test('schreibt den Zeitstempel als UTC und liest ihn zurueck', () {
      final dokument = CloudDokument(
        pfad: CloudModell.dokProfil,
        daten: const {'wert': '{"alter":"a25bis34"}'},
        aktualisiertAm: DateTime.utc(2026, 8, 24, 10, 30),
      );

      final ablage = dokument.zurAblage();
      expect(ablage['aktualisiertAm'], '2026-08-24T10:30:00.000Z');

      final gelesen = CloudDokument.ausAblage(CloudModell.dokProfil, ablage);
      expect(gelesen, dokument);
      expect(gelesen.daten.containsKey('aktualisiertAm'), isFalse);
    });

    test('ein fehlender Zeitstempel gilt als uralt', () {
      final gelesen = CloudDokument.ausAblage(
        CloudModell.dokProfil,
        const {'wert': 'x'},
      );

      expect(gelesen.aktualisiertAm, DateTime.utc(1970));
    });

    test('kennt Sammlung und ID', () {
      final dokument = CloudDokument(
        pfad: 'analysen/17',
        daten: const {},
        aktualisiertAm: DateTime.utc(1970),
      );

      expect(dokument.sammlung, 'analysen');
      expect(dokument.id, '17');
    });
  });

  group('SpeicherAttrappe', () {
    test('fuehrt Felder desselben Dokuments zusammen', () async {
      final speicher = SpeicherAttrappe();

      await speicher.schreiben([
        CloudDokument(
          pfad: CloudModell.dokModule,
          daten: const {'module': ['basis']},
          aktualisiertAm: DateTime.utc(2026, 8, 1),
        ),
      ]);
      await speicher.schreiben([
        CloudDokument(
          pfad: CloudModell.dokModule,
          daten: const {'eingaben': '{}'},
          aktualisiertAm: DateTime.utc(2026, 8, 2),
        ),
      ]);

      final gelesen = await speicher.lesen(CloudModell.dokModule);
      expect(gelesen!.daten, {
        'module': ['basis'],
        'eingaben': '{}',
      });
      expect(gelesen.aktualisiertAm, DateTime.utc(2026, 8, 2));
    });

    test('loescht alles', () async {
      final speicher = SpeicherAttrappe([
        CloudDokument(
          pfad: CloudModell.dokProfil,
          daten: const {'wert': 'x'},
          aktualisiertAm: DateTime.utc(2026),
        ),
      ]);

      await speicher.allesLoeschen();
      expect(await speicher.alleLesen(), isEmpty);
    });
  });
}
