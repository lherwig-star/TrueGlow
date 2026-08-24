// Benannte Parameter duerfen in Dart nicht mit Unterstrich beginnen –
// prefer_initializing_formals laesst sich hier deshalb nicht befolgen.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../cloud/cloud_dokument.dart';
import '../cloud/cloud_speicher.dart';
import '../cloud/cloud_uebersetzung.dart';
import '../storage/key_value_store.dart';

/// Ein [KeyValueStore], der lokal schreibt und die Cloud nachzieht.
///
/// Das ist der Angelpunkt der Sync-Strategie: Die zwoelf Controller der App
/// schreiben seit jeher durch [KeyValueStore]. Wird diese eine Stelle
/// erweitert, laufen Plan, Checklisten, Streak und Historie ohne jede weitere
/// Aenderung durch die Cloud.
///
/// **Lesen** geht immer lokal – sofort und ohne Netz. Hive ist der
/// Offline-Cache; die Cloud ist die Quelle der Wahrheit, aber nur beim
/// Abgleich (siehe [SyncDienst]).
///
/// **Schreiben** geht zuerst lokal und dann in die Cloud, ohne darauf zu
/// warten. Firestore nimmt Schreibvorgaenge auch offline entgegen und
/// schickt sie nach, sobald wieder Netz da ist – genau das verlangt die
/// Roadmap („Sync läuft nach, sobald Netz da ist"), und es kostet kein
/// weiteres Paket.
class SyncStore implements KeyValueStore {
  SyncStore({
    required this.box,
    required KeyValueStore lokal,
    required KeyValueStore zeitstempel,
  })  : _lokal = lokal,
        _zeitstempel = zeitstempel;

  /// Name der Hive-Box, fuer die dieser Store steht.
  final String box;

  final KeyValueStore _lokal;

  /// Wann welcher Schluessel zuletzt geschrieben wurde. Liegt in einer
  /// eigenen Box, damit die Zeitstempel nicht in `values` oder `keys` der
  /// Nutzdaten auftauchen – der Analyse-Verlauf liest die Box naemlich
  /// vollstaendig aus.
  final KeyValueStore _zeitstempel;

  CloudSpeicher? _cloud;

  /// Setzt das Ziel in der Cloud. `null` heisst: nur lokal arbeiten
  /// (nicht angemeldet oder Demo-Modus).
  void cloudSetzen(CloudSpeicher? cloud) => _cloud = cloud;

  bool get hatCloud => _cloud != null;

  // --- Lesen (immer lokal) ---------------------------------------------

  @override
  Object? get(String schluessel) => _lokal.get(schluessel);

  @override
  Iterable<Object?> get values => _lokal.values;

  @override
  Iterable<String> get keys => _lokal.keys;

  @override
  bool get isEmpty => _lokal.isEmpty;

  // --- Schreiben --------------------------------------------------------

  @override
  Future<void> put(String schluessel, Object? wert) async {
    final jetzt = DateTime.now().toUtc();
    await _lokal.put(schluessel, wert);
    await _standSetzen(schluessel, jetzt);
    hochladen(schluessel, wert, jetzt);
  }

  @override
  Future<void> delete(String schluessel) async {
    await _lokal.delete(schluessel);
    // Der Zeitstempel bleibt bewusst stehen und wird nur fortgeschrieben:
    // Sonst wuerde ein geloeschter Schluessel beim naechsten Abgleich als
    // „hat die Cloud, kennt das Geraet nicht" wieder auftauchen.
    await _standSetzen(schluessel, DateTime.now().toUtc());

    final cloud = _cloud;
    if (cloud == null) return;

    final pfade = CloudUebersetzung.dokumenteFuer(
      box: box,
      schluessel: schluessel,
      // Fuer den Pfad reicht ein Platzhalterwert; der Inhalt wird geloescht.
      wert: '',
      stand: DateTime.now().toUtc(),
    ).map((d) => d.pfad);

    unawaited(
      cloud.loeschen(pfade),
      'Loeschen von $box/$schluessel',
    );
  }

  @override
  Future<void> clear() async {
    await _lokal.clear();
    // Die Zeitstempel dieser Box gehen mit – ohne Daten sagen sie nichts
    // mehr aus. Die Cloud raeumt der Aufrufer selbst
    // (Einstellungen → „Alle Daten löschen"), damit ein lokales Leeren nie
    // versehentlich das Konto leert.
    for (final schluessel in _zeitstempel.keys.toList()) {
      if (schluessel.startsWith('$box/')) {
        await _zeitstempel.delete(schluessel);
      }
    }
  }

  // --- Sync-Schnittstelle ----------------------------------------------

  /// Schreibt einen Wert, der gerade aus der Cloud kam.
  ///
  /// Bewusst ohne Rueckweg in die Cloud: Sonst schriebe jeder Abgleich das
  /// gerade Gelesene sofort wieder zurueck.
  Future<void> ausCloud(String schluessel, Object? wert, DateTime stand) async {
    if (wert == null) {
      await _lokal.delete(schluessel);
    } else {
      await _lokal.put(schluessel, wert);
    }
    await _standSetzen(schluessel, stand);
  }

  /// Wann dieser Schluessel lokal zuletzt geschrieben wurde.
  ///
  /// `null` heisst „unbekannt" – dann gewinnt beim Abgleich die Cloud, weil
  /// ein lokaler Wert ohne Zeitstempel aelter ist als jede bekannte Angabe.
  DateTime? standVon(String schluessel) {
    final roh = _zeitstempel.get('$box/$schluessel');
    return roh is String ? DateTime.tryParse(roh)?.toUtc() : null;
  }

  /// Schiebt einen lokalen Wert in die Cloud, ohne auf die Bestaetigung zu
  /// warten.
  void hochladen(String schluessel, Object? wert, DateTime stand) {
    final cloud = _cloud;
    if (cloud == null) return;

    final dokumente = CloudUebersetzung.dokumenteFuer(
      box: box,
      schluessel: schluessel,
      wert: wert,
      stand: stand,
    );
    if (dokumente.isEmpty) return;

    unawaited(cloud.schreiben(dokumente), 'Schreiben von $box/$schluessel');
  }

  /// Alle Dokumente, die der aktuelle lokale Bestand ergibt.
  List<CloudDokument> alleDokumente() {
    final dokumente = <CloudDokument>[];
    for (final schluessel in keys) {
      dokumente.addAll(
        CloudUebersetzung.dokumenteFuer(
          box: box,
          schluessel: schluessel,
          wert: get(schluessel),
          stand: standVon(schluessel) ?? DateTime.now().toUtc(),
        ),
      );
    }
    return dokumente;
  }

  Future<void> _standSetzen(String schluessel, DateTime stand) =>
      _zeitstempel.put('$box/$schluessel', stand.toIso8601String());

  /// Feuert einen Cloud-Vorgang ab und protokolliert nur, wenn er scheitert.
  ///
  /// Absichtlich ohne `await` in den Schreibpfaden: Firestore nimmt den
  /// Vorgang offline entgegen und liefert das Future erst, wenn der Server
  /// bestaetigt hat. Wuerde die UI darauf warten, haengte jeder Haken in der
  /// Checkliste am Netz.
  static void unawaited(Future<void> vorgang, String was) {
    vorgang.catchError((Object e) {
      debugPrint('Sync: $was fehlgeschlagen ($e)');
    });
  }
}
