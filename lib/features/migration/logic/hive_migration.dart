import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_dokument.dart';
import '../../../core/cloud/cloud_modell.dart';
import '../../../core/cloud/cloud_provider.dart';
import '../../../core/cloud/cloud_speicher.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';

/// Uebernimmt den lokalen Hive-Bestand einmalig in die Cloud.
///
/// Der Anlass ist der erste echte Login: Wer die App vorher ohne Konto
/// benutzt hat, soll Streak, Plan und Historie nicht verlieren – das sind
/// genau die Daten, die emotional am meisten wiegen.
///
/// **Idempotenz** ist die zentrale Zusicherung, und sie ruht auf zwei
/// Saeulen:
///
/// 1. Ein Marker in `daten/migration`. Ist er gesetzt, tut ein zweiter Lauf
///    nichts.
/// 2. Alle Schreibvorgaenge benutzen feste Dokument-IDs (Analyse-ID, Check-in-
///    ID, Tagesdatum). Selbst ein Abbruch mitten im Lauf kann deshalb beim
///    Wiederholen nichts verdoppeln – es wird hoechstens dasselbe Dokument
///    noch einmal geschrieben.
class HiveMigration {
  HiveMigration({required this.speicher, required this.boxen});

  final CloudSpeicher speicher;

  /// Die vier Hive-Boxen, nach Namen.
  final Map<String, KeyValueStore> boxen;

  /// Schema-Version der Uebernahme. Aendert sich die Abbildung grundlegend,
  /// erkennt ein spaeterer Lauf am Marker, was er vor sich hat.
  static const int version = 1;

  /// Ob es ueberhaupt etwas zu uebernehmen gibt.
  ///
  /// Nur wahr, wenn lokal Daten liegen **und** der Marker fehlt. Beides ist
  /// noetig: Ein leerer Bestand braucht keinen Dialog, und ein gesetzter
  /// Marker heisst, dass die Frage schon beantwortet wurde.
  Future<bool> istNoetig() async {
    if (!hatLokaleDaten()) return false;
    return await speicher.lesen(CloudModell.dokMigration) == null;
  }

  /// Ob lokal etwas liegt, das mitwandern wuerde.
  bool hatLokaleDaten() {
    for (final eintrag in boxen.entries) {
      for (final schluessel in eintrag.value.keys) {
        if (CloudModell.wirdSynchronisiert(eintrag.key, schluessel)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Fuehrt die Uebernahme aus und setzt den Marker.
  ///
  /// Gibt zurueck, wie viele Dokumente geschrieben wurden; 0 heisst, dass der
  /// Marker schon stand.
  Future<int> ausfuehren({DateTime? jetzt}) async {
    if (await speicher.lesen(CloudModell.dokMigration) != null) {
      debugPrint('Migration: Marker steht bereits, nichts zu tun.');
      return 0;
    }

    final zeitpunkt = (jetzt ?? DateTime.now()).toUtc();
    final dokumente = sammle(jetzt: zeitpunkt);

    if (dokumente.isNotEmpty) {
      await speicher.schreiben(dokumente);
    }

    // Der Marker kommt zuletzt: Bricht der Lauf vorher ab, laeuft er beim
    // naechsten Login noch einmal – und schreibt dank fester IDs dieselben
    // Dokumente statt neuer.
    await speicher.schreiben([
      CloudDokument(
        pfad: CloudModell.dokMigration,
        daten: {
          'version': version,
          'dokumente': dokumente.length,
        },
        aktualisiertAm: zeitpunkt,
      ),
    ]);

    return dokumente.length;
  }

  /// Merkt sich, dass die Uebernahme abgelehnt wurde.
  ///
  /// Ohne diesen Marker kaeme die Frage bei jeder Anmeldung wieder. Die
  /// lokalen Daten bleiben unangetastet – abgelehnt ist die Uebernahme, nicht
  /// der Bestand.
  Future<void> ablehnen({DateTime? jetzt}) async {
    await speicher.schreiben([
      CloudDokument(
        pfad: CloudModell.dokMigration,
        daten: const {'version': version, 'abgelehnt': true},
        aktualisiertAm: (jetzt ?? DateTime.now()).toUtc(),
      ),
    ]);
  }

  /// Baut aus dem lokalen Bestand die Cloud-Dokumente.
  ///
  /// Oeffentlich, weil sich daran ohne Cloud pruefen laesst, was uebertragen
  /// wuerde – und vor allem, was nicht.
  @visibleForTesting
  List<CloudDokument> sammle({required DateTime jetzt}) {
    // Mehrere lokale Schluessel koennen in dasselbe Dokument fallen
    // (`daten/module` etwa nimmt Auswahl und Eingaben auf), deshalb erst
    // sammeln und dann je Dokument einmal schreiben.
    final felder = <String, Map<String, dynamic>>{};
    final dokumente = <CloudDokument>[];

    for (final eintrag in boxen.entries) {
      final box = eintrag.key;
      final speicher = eintrag.value;

      for (final schluessel in speicher.keys) {
        if (box == HiveService.boxCheckins &&
            schluessel == CloudModell.keyHistorie) {
          dokumente.addAll(
            _historie(speicher.get(schluessel), jetzt: jetzt),
          );
          continue;
        }

        final ziel = CloudModell.ziel(box, schluessel);
        if (ziel == null) continue;

        final wert = _cloudWert(speicher.get(schluessel));
        if (wert == null) continue;

        felder.putIfAbsent(ziel.pfad, () => {})[ziel.feld] = wert;
      }
    }

    for (final eintrag in felder.entries) {
      dokumente.add(
        CloudDokument(
          pfad: eintrag.key,
          daten: eintrag.value,
          aktualisiertAm: jetzt,
        ),
      );
    }

    return dokumente;
  }

  /// Faechert die Check-in-Historie in je ein Dokument auf.
  ///
  /// Lokal liegt sie als eine JSON-Liste; in der Cloud gehoert jeder Check-in
  /// in ein eigenes Dokument mit seiner laufenden Nummer als ID. Genau das
  /// macht einen zweiten Lauf harmlos: Dieselbe Nummer trifft dasselbe
  /// Dokument.
  List<CloudDokument> _historie(Object? roh, {required DateTime jetzt}) {
    if (roh is! String || roh.isEmpty) return const [];

    final List<dynamic> liste;
    try {
      final gelesen = jsonDecode(roh);
      if (gelesen is! List) return const [];
      liste = gelesen;
    } on FormatException catch (e) {
      debugPrint('Migration: Historie nicht lesbar ($e)');
      return const [];
    }

    final dokumente = <CloudDokument>[];
    for (final eintrag in liste.whereType<Map>()) {
      final id = eintrag['id'];
      if (id == null) continue;

      dokumente.add(
        CloudDokument(
          pfad: CloudModell.checkinPfad(id),
          daten: {'wert': jsonEncode(eintrag)},
          aktualisiertAm: jetzt,
        ),
      );
    }
    return dokumente;
  }

  /// Bringt einen Hive-Wert in eine Form, die Firestore annimmt.
  ///
  /// Hive liefert Listen als `List<dynamic>`; Firestore braucht sie
  /// typisiert. Alles andere (String, int, bool) geht unveraendert durch.
  static Object? _cloudWert(Object? wert) => switch (wert) {
        null => null,
        final List<dynamic> liste => liste.map((e) => '$e').toList(),
        final String s => s,
        final int i => i,
        final bool b => b,
        final double d => d,
        // Unbekannte Typen lieber auslassen als die Uebernahme scheitern
        // lassen – der lokale Bestand bleibt ja erhalten.
        _ => null,
      };
}

/// Baut die Migration fuer das angemeldete Konto.
///
/// `null`, solange niemand angemeldet ist oder kein Cloud-Speicher
/// bereitsteht (Demo-Modus).
final hiveMigrationProvider = Provider<HiveMigration?>((ref) {
  final speicher = ref.watch(cloudSpeicherProvider);
  if (speicher == null) return null;

  return HiveMigration(
    speicher: speicher,
    boxen: {
      for (final name in HiveService.alleBoxen)
        name: ref.watch(storeProvider(name)),
    },
  );
});
