import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/cloud/cloud_dokument.dart';
import 'package:trueglow/core/cloud/cloud_modell.dart';
import 'package:trueglow/core/cloud/cloud_speicher.dart';
import 'package:trueglow/core/storage/hive_service.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/core/sync/sync_dienst.dart';
import 'package:trueglow/core/sync/sync_store.dart';

/// Ein Satz Sync-Stores auf gemeinsamen Zeitstempeln – so wie in der App.
({Map<String, SyncStore> stores, KeyValueStore zeitstempel}) _aufbau() {
  final zeitstempel = MemoryStore();
  return (
    stores: {
      for (final name in HiveService.alleBoxen)
        name: SyncStore(
          box: name,
          lokal: MemoryStore(),
          zeitstempel: zeitstempel,
        ),
    },
    zeitstempel: zeitstempel,
  );
}

CloudDokument _dokument(
  String pfad,
  Map<String, dynamic> daten,
  DateTime stand,
) =>
    CloudDokument(pfad: pfad, daten: daten, aktualisiertAm: stand);

void main() {
  group('SyncStore', () {
    test('schreibt lokal und merkt sich den Zeitpunkt', () async {
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxEinstellungen]!;

      await store.put(CloudModell.keyRichtung, '{"ziele":[]}');

      expect(store.get(CloudModell.keyRichtung), '{"ziele":[]}');
      expect(store.standVon(CloudModell.keyRichtung), isNotNull);
    });

    test('laeuft ohne Cloud vollstaendig weiter', () async {
      // Der Offline-Fall: kein Konto, kein Netz, trotzdem benutzbar.
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxFortschritt]!;

      expect(store.hatCloud, isFalse);
      await store.put('2026-08-24', ['Haare stylen']);

      expect(store.get('2026-08-24'), ['Haare stylen']);
    });

    test('schiebt geschriebene Werte in die Cloud', () async {
      final aufbau = _aufbau();
      final cloud = SpeicherAttrappe();
      final store = aufbau.stores[HiveService.boxEinstellungen]!
        ..cloudSetzen(cloud);

      await store.put(CloudModell.keyOnboarding, '{"alter":"ab45"}');
      // Der Upload laeuft bewusst ohne await – ein Mikrotask reicht.
      await Future<void>.delayed(Duration.zero);

      final profil = await cloud.lesen(CloudModell.dokProfil);
      expect(profil!.daten['wert'], '{"alter":"ab45"}');
    });

    test('haelt die Zeitstempel aus den Nutzdaten heraus', () async {
      // Der Analyse-Verlauf liest seine Box vollstaendig aus – ein
      // Fremdeintrag darin waere ein Fehler mit Ansage.
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxAnalysen]!;

      await store.put('17', '{"id":"17"}');

      expect(store.keys, ['17']);
      expect(store.values, ['{"id":"17"}']);
      expect(aufbau.zeitstempel.keys, ['analysen/17']);
    });

    test('ausCloud schreibt lokal, ohne wieder hochzuladen', () async {
      final aufbau = _aufbau();
      final cloud = SpeicherAttrappe();
      final store = aufbau.stores[HiveService.boxEinstellungen]!
        ..cloudSetzen(cloud);

      await store.ausCloud(
        CloudModell.keyRichtung,
        '{"ziele":["reifer"]}',
        DateTime.utc(2026, 8, 20),
      );
      await Future<void>.delayed(Duration.zero);

      expect(store.get(CloudModell.keyRichtung), '{"ziele":["reifer"]}');
      expect(store.standVon(CloudModell.keyRichtung), DateTime.utc(2026, 8, 20));
      expect(cloud.schreibzugriffe, 0);
    });
  });

  group('Konfliktregel', () {
    test('der juengere Stand gewinnt – hier die Cloud', () async {
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxEinstellungen]!;
      await store.ausCloud(
        CloudModell.keyRichtung,
        'alt',
        DateTime.utc(2026, 8, 1),
      );

      final cloud = SpeicherAttrappe([
        _dokument(CloudModell.dokRichtung, {'wert': 'neu'}, DateTime.utc(2026, 8, 5)),
      ]);

      final geaendert =
          await SyncDienst(stores: aufbau.stores).abgleichen(cloud);

      expect(geaendert, isTrue);
      expect(store.get(CloudModell.keyRichtung), 'neu');
    });

    test('der juengere Stand gewinnt – hier das Geraet', () async {
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxEinstellungen]!;
      await store.ausCloud(
        CloudModell.keyRichtung,
        'lokal neu',
        DateTime.utc(2026, 8, 10),
      );

      final cloud = SpeicherAttrappe([
        _dokument(CloudModell.dokRichtung, {'wert': 'alt'}, DateTime.utc(2026, 8, 5)),
      ]);

      final geaendert =
          await SyncDienst(stores: aufbau.stores).abgleichen(cloud);
      await Future<void>.delayed(Duration.zero);

      expect(geaendert, isFalse);
      expect(store.get(CloudModell.keyRichtung), 'lokal neu');
      expect(
        (await cloud.lesen(CloudModell.dokRichtung))!.daten['wert'],
        'lokal neu',
      );
    });

    test('bei Gleichstand gewinnt die Cloud', () async {
      final zeitpunkt = DateTime.utc(2026, 8, 5);
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxEinstellungen]!;
      await store.ausCloud(CloudModell.keyRichtung, 'lokal', zeitpunkt);

      final cloud = SpeicherAttrappe([
        _dokument(CloudModell.dokRichtung, {'wert': 'cloud'}, zeitpunkt),
      ]);

      await SyncDienst(stores: aufbau.stores).abgleichen(cloud);

      expect(store.get(CloudModell.keyRichtung), 'cloud');
    });

    test('ein lokaler Wert ohne Zeitstempel verliert gegen die Cloud',
        () async {
      final store = SyncStore(
        box: HiveService.boxEinstellungen,
        lokal: MemoryStore()..put(CloudModell.keyRichtung, 'ungestempelt'),
        zeitstempel: MemoryStore(),
      );

      final cloud = SpeicherAttrappe([
        _dokument(CloudModell.dokRichtung, {'wert': 'cloud'}, DateTime.utc(2026)),
      ]);

      await SyncDienst(stores: {HiveService.boxEinstellungen: store})
          .abgleichen(cloud);

      expect(store.get(CloudModell.keyRichtung), 'cloud');
    });
  });

  group('Tagesfortschritt', () {
    test('wird vereinigt statt ersetzt', () async {
      // Ein Haken ist additiv: Drei offline gesetzte duerfen nicht
      // verschwinden, weil ein anderes Geraet spaeter einen gesetzt hat.
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxFortschritt]!;
      await store.ausCloud(
        '2026-08-24',
        ['Haare stylen', 'Bart ölen'],
        DateTime.utc(2026, 8, 24, 8),
      );

      final cloud = SpeicherAttrappe([
        _dokument(
          'fortschritt/2026-08-24',
          {'erledigt': ['Sonnenschutz auftragen']},
          DateTime.utc(2026, 8, 24, 20),
        ),
      ]);

      await SyncDienst(stores: aufbau.stores).abgleichen(cloud);
      await Future<void>.delayed(Duration.zero);

      expect(store.get('2026-08-24'), [
        'Bart ölen',
        'Haare stylen',
        'Sonnenschutz auftragen',
      ]);
      // Die Vereinigung muss auch die Cloud erreichen.
      expect(
        (await cloud.lesen('fortschritt/2026-08-24'))!.daten['erledigt'],
        ['Bart ölen', 'Haare stylen', 'Sonnenschutz auftragen'],
      );
    });
  });

  group('Check-in-Historie', () {
    test('wird je Nummer zusammengefuehrt, ohne Verlust', () async {
      final aufbau = _aufbau();
      final store = aufbau.stores[HiveService.boxCheckins]!;
      await store.ausCloud(
        CloudModell.keyHistorie,
        jsonEncode([
          {'id': 0, 'typ': 'alltag'},
        ]),
        DateTime.utc(2026, 8, 10),
      );

      final cloud = SpeicherAttrappe([
        _dokument(
          'checkins/1',
          {'wert': jsonEncode({'id': 1, 'typ': 'zwischen'})},
          DateTime.utc(2026, 8, 20),
        ),
      ]);

      final geaendert =
          await SyncDienst(stores: aufbau.stores).abgleichen(cloud);
      await Future<void>.delayed(Duration.zero);

      expect(geaendert, isTrue);
      final historie = jsonDecode(
        store.get(CloudModell.keyHistorie)! as String,
      ) as List;
      expect(historie.map((e) => e['id']), [0, 1]);

      // Der lokale Check-in 0 fehlte in der Cloud und geht mit hoch.
      expect(await cloud.lesen('checkins/0'), isNotNull);
    });

    test('sortiert nach laufender Nummer, nicht nach Fundreihenfolge',
        () async {
      final aufbau = _aufbau();
      final cloud = SpeicherAttrappe([
        for (final id in [2, 0, 1])
          _dokument(
            'checkins/$id',
            {'wert': jsonEncode({'id': id})},
            DateTime.utc(2026, 8, 20),
          ),
      ]);

      await SyncDienst(stores: aufbau.stores).abgleichen(cloud);

      final historie = jsonDecode(
        aufbau.stores[HiveService.boxCheckins]!.get(CloudModell.keyHistorie)!
            as String,
      ) as List;
      expect(historie.map((e) => e['id']), [0, 1, 2]);
    });
  });

  group('Nachtragen', () {
    test('laedt lokale Schluessel hoch, die die Cloud noch nicht kennt',
        () async {
      final aufbau = _aufbau();
      await aufbau.stores[HiveService.boxAnalysen]!
          .ausCloud('17', '{"id":"17"}', DateTime.utc(2026, 8, 1));
      await aufbau.stores[HiveService.boxEinstellungen]!
          .ausCloud(CloudModell.keyModule, ['basis'], DateTime.utc(2026, 8, 1));

      final cloud = SpeicherAttrappe();
      await SyncDienst(stores: aufbau.stores).abgleichen(cloud);
      await Future<void>.delayed(Duration.zero);

      expect(await cloud.lesen('analysen/17'), isNotNull);
      expect(
        (await cloud.lesen(CloudModell.dokModule))!.daten['module'],
        ['basis'],
      );
    });

    test('laesst Geraetezustand aussen vor', () async {
      final aufbau = _aufbau();
      await aufbau.stores[HiveService.boxCheckins]!.ausCloud(
        CloudModell.keyEntwurf,
        '{"id":1}',
        DateTime.utc(2026, 8, 1),
      );

      final cloud = SpeicherAttrappe();
      await SyncDienst(stores: aufbau.stores).abgleichen(cloud);
      await Future<void>.delayed(Duration.zero);

      expect(await cloud.alleLesen(), isEmpty);
    });

    test('eine unerreichbare Cloud ist kein Fehler', () async {
      final aufbau = _aufbau();
      final geaendert =
          await SyncDienst(stores: aufbau.stores).abgleichen(_KaputteCloud());

      expect(geaendert, isFalse);
    });
  });
}

/// Cloud, die bei jedem Lesen scheitert – der Offline-Fall ohne Cache.
class _KaputteCloud implements CloudSpeicher {
  @override
  Future<List<CloudDokument>> alleLesen() async =>
      throw Exception('kein Netz');

  @override
  Future<void> allesLoeschen() async {}

  @override
  Future<CloudDokument?> lesen(String pfad) async => null;

  @override
  Future<void> loeschen(Iterable<String> pfade) async {}

  @override
  Future<void> schreiben(Iterable<CloudDokument> dokumente) async {}
}
