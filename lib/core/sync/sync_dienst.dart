import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../cloud/cloud_dokument.dart';
import '../cloud/cloud_modell.dart';
import '../cloud/cloud_speicher.dart';
import '../cloud/cloud_uebersetzung.dart';
import '../storage/hive_service.dart';
import 'sync_store.dart';

/// Fuehrt lokalen Bestand und Cloud zusammen.
///
/// Die Regel steht in der Roadmap und ist bewusst einfach gehalten: **letzter
/// Schreiber gewinnt, Zeitstempel pro Dokument.** Bei Gleichstand gewinnt die
/// Cloud – sie ist die Quelle der Wahrheit.
///
/// Zwei Ausnahmen, beide aus gutem Grund:
///
/// - **Tagesfortschritt** wird vereinigt statt ersetzt. Ein Haken ist ein
///   additives Ereignis; „letzter Schreiber gewinnt" wuerde drei offline
///   gesetzte Haken verlieren, weil ein anderes Geraet spaeter einen einzigen
///   gesetzt hat.
/// - **Check-ins** werden je Nummer zusammengefuehrt. Ein abgeschlossener
///   Check-in aendert sich nicht mehr; verloren gehen darf trotzdem keiner.
class SyncDienst {
  SyncDienst({required this.stores});

  /// Die Sync-Stores der vier Datenboxen, nach Boxnamen.
  final Map<String, SyncStore> stores;

  /// Setzt das Cloud-Ziel aller Stores. `null` schaltet auf reinen
  /// Offline-Betrieb (nicht angemeldet oder Demo-Modus).
  void cloudSetzen(CloudSpeicher? cloud) {
    for (final store in stores.values) {
      store.cloudSetzen(cloud);
    }
  }

  /// Holt den Cloud-Stand, fuehrt ihn mit dem lokalen zusammen und schiebt
  /// zurueck, was lokal neuer ist.
  ///
  /// Gibt zurueck, ob sich lokal etwas geaendert hat – dann muessen die
  /// Controller neu laden.
  Future<bool> abgleichen(CloudSpeicher? cloud) async {
    if (cloud == null) return false;

    final List<CloudDokument> dokumente;
    try {
      dokumente = await cloud.alleLesen();
    } catch (e) {
      // Ohne Netz und ohne Cache gibt es nichts abzugleichen. Die App laeuft
      // mit dem lokalen Bestand weiter – genau dafuer ist er da.
      debugPrint('Sync: Cloud nicht lesbar ($e)');
      return false;
    }

    var geaendert = false;
    final hochzuladen = <CloudDokument>[];
    final ausCloudGesehen = <String>{};

    final checkinDokumente = <CloudDokument>[];

    for (final dokument in dokumente) {
      if (dokument.sammlung == CloudModell.sammlungCheckins) {
        checkinDokumente.add(dokument);
        continue;
      }

      for (final feld in dokument.daten.entries) {
        final ziel = CloudModell.lokal(dokument.pfad, feld.key);
        if (ziel == null) continue;

        final store = stores[ziel.box];
        if (store == null) continue;

        ausCloudGesehen.add('${ziel.box}/${ziel.schluessel}');

        final lokalerStand = store.standVon(ziel.schluessel);
        final cloudWert = CloudUebersetzung.lokalerWert(feld.value);

        if (_istTagesfortschritt(ziel.box, ziel.schluessel)) {
          final vereinigt = _vereinige(store.get(ziel.schluessel), cloudWert);
          if (!_gleich(store.get(ziel.schluessel), vereinigt)) {
            await store.ausCloud(
              ziel.schluessel,
              vereinigt,
              _juengerer(lokalerStand, dokument.aktualisiertAm),
            );
            geaendert = true;
          }
          // Die Vereinigung muss auch die Cloud erreichen, sonst faengt der
          // naechste Abgleich von vorn an.
          hochzuladen.addAll(
            CloudUebersetzung.dokumenteFuer(
              box: ziel.box,
              schluessel: ziel.schluessel,
              wert: vereinigt,
              stand: _juengerer(lokalerStand, dokument.aktualisiertAm),
            ),
          );
          continue;
        }

        // Kein lokaler Zeitstempel heisst: Der Wert war nie durch den Sync
        // gegangen. Dann gewinnt die Cloud.
        if (lokalerStand == null ||
            !lokalerStand.isAfter(dokument.aktualisiertAm)) {
          if (!_gleich(store.get(ziel.schluessel), cloudWert)) {
            await store.ausCloud(
              ziel.schluessel,
              cloudWert,
              dokument.aktualisiertAm,
            );
            geaendert = true;
          }
        } else {
          hochzuladen.addAll(
            CloudUebersetzung.dokumenteFuer(
              box: ziel.box,
              schluessel: ziel.schluessel,
              wert: store.get(ziel.schluessel),
              stand: lokalerStand,
            ),
          );
        }
      }
    }

    if (await _checkinsZusammenfuehren(checkinDokumente, hochzuladen)) {
      geaendert = true;
    }

    // Alles, was lokal liegt und in der Cloud noch fehlt.
    for (final eintrag in stores.entries) {
      final store = eintrag.value;
      for (final schluessel in store.keys) {
        if (ausCloudGesehen.contains('${eintrag.key}/$schluessel')) continue;
        if (eintrag.key == HiveService.boxCheckins &&
            schluessel == CloudModell.keyHistorie) {
          // Die Historie ist oben schon behandelt worden.
          continue;
        }

        hochzuladen.addAll(
          CloudUebersetzung.dokumenteFuer(
            box: eintrag.key,
            schluessel: schluessel,
            wert: store.get(schluessel),
            stand: store.standVon(schluessel) ?? DateTime.now().toUtc(),
          ),
        );
      }
    }

    if (hochzuladen.isNotEmpty) {
      SyncStore.unawaited(cloud.schreiben(hochzuladen), 'Nachtragen');
    }

    return geaendert;
  }

  /// Fuehrt die Check-in-Historie zusammen: je laufender Nummer der juengere
  /// Stand, nie ein Verlust.
  Future<bool> _checkinsZusammenfuehren(
    List<CloudDokument> ausCloud,
    List<CloudDokument> hochzuladen,
  ) async {
    final store = stores[HiveService.boxCheckins];
    if (store == null) return false;

    final lokal = CloudUebersetzung.historieLesen(
      store.get(CloudModell.keyHistorie),
    );
    final lokalerStand =
        store.standVon(CloudModell.keyHistorie) ?? DateTime.utc(1970);

    final nachId = <String, Map<String, dynamic>>{
      for (final eintrag in lokal) '${eintrag['id']}': eintrag,
    };
    final staende = <String, DateTime>{
      for (final eintrag in lokal) '${eintrag['id']}': lokalerStand,
    };

    for (final dokument in ausCloud) {
      final gelesen = CloudUebersetzung.checkinLesen(dokument);
      if (gelesen == null) continue;

      final id = dokument.id;
      final vorhanden = staende[id];
      if (vorhanden == null || !vorhanden.isAfter(dokument.aktualisiertAm)) {
        nachId[id] = gelesen;
        staende[id] = dokument.aktualisiertAm;
      }
    }

    if (nachId.isEmpty) return false;

    // Nach laufender Nummer sortieren – die Historie ist chronologisch.
    final ids = nachId.keys.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    final zusammengefuehrt = [for (final id in ids) nachId[id]!];

    // Was die Cloud noch nicht kennt, geht mit hoch.
    final inCloud = ausCloud.map((d) => d.id).toSet();
    for (final id in ids) {
      if (inCloud.contains(id)) continue;
      hochzuladen.add(
        CloudDokument(
          pfad: CloudModell.checkinPfad(id),
          daten: {'wert': jsonEncode(nachId[id])},
          aktualisiertAm: staende[id] ?? DateTime.now().toUtc(),
        ),
      );
    }

    final neu = jsonEncode(zusammengefuehrt);
    if (neu == store.get(CloudModell.keyHistorie)) return false;

    await store.ausCloud(
      CloudModell.keyHistorie,
      neu,
      staende.values.fold<DateTime>(
        lokalerStand,
        (a, b) => b.isAfter(a) ? b : a,
      ),
    );
    return true;
  }

  static bool _istTagesfortschritt(String box, String schluessel) =>
      box == HiveService.boxFortschritt &&
      CloudModell.istTagesschluessel(schluessel);

  /// Vereinigt zwei Listen abgehakter Aufgaben, ohne Reihenfolge zu
  /// versprechen.
  static List<String> _vereinige(Object? lokal, Object? cloud) {
    final zusammen = <String>{
      if (lokal is List) ...lokal.map((e) => '$e'),
      if (cloud is List) ...cloud.map((e) => '$e'),
    };
    return zusammen.toList()..sort();
  }

  static DateTime _juengerer(DateTime? a, DateTime b) =>
      a != null && a.isAfter(b) ? a : b;

  static bool _gleich(Object? a, Object? b) {
    if (a is List && b is List) {
      return a.length == b.length &&
          const IterableEquality<Object?>().equals(a, b);
    }
    return a == b;
  }
}

/// Kleiner Ersatz fuer `package:collection`, damit die Abhaengigkeit nicht
/// nur fuer einen Vergleich dazukommt.
class IterableEquality<T> {
  const IterableEquality();

  bool equals(Iterable<T> a, Iterable<T> b) {
    final links = a.iterator;
    final rechts = b.iterator;
    while (true) {
      final linksWeiter = links.moveNext();
      final rechtsWeiter = rechts.moveNext();
      if (!linksWeiter || !rechtsWeiter) return linksWeiter == rechtsWeiter;
      if (links.current != rechts.current) return false;
    }
  }
}
