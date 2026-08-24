import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_dokument.dart';
import 'cloud_modell.dart';

/// Lesen und Schreiben im Nutzerbaum.
///
/// Bewusst als Schnittstelle: Migration und Sync sind die heikelsten Teile
/// dieser Phase und muessen ohne Firestore-Emulator testbar bleiben. Die
/// Attrappe [SpeicherAttrappe] ist genau dafuer da.
abstract interface class CloudSpeicher {
  /// Alle Dokumente des Kontos, ueber alle Sammlungen hinweg.
  Future<List<CloudDokument>> alleLesen();

  /// Ein einzelnes Dokument oder `null`, wenn es nicht existiert.
  Future<CloudDokument?> lesen(String pfad);

  /// Schreibt mehrere Dokumente. Bestehende Felder bleiben erhalten, damit
  /// zwei Schluessel, die sich ein Dokument teilen, sich nicht gegenseitig
  /// ausloeschen (etwa `module` und `eingaben` in `daten/module`).
  Future<void> schreiben(Iterable<CloudDokument> dokumente);

  Future<void> loeschen(Iterable<String> pfade);

  /// Loescht saemtliche Daten des Kontos – die Cloud-Haelfte von
  /// „Alle Daten löschen".
  Future<void> allesLoeschen();
}

/// Firestore-Fassung. Alle Pfade haengen unter `users/{uid}`.
class FirestoreSpeicher implements CloudSpeicher {
  FirestoreSpeicher({required this.uid, FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  /// Firestore nimmt hoechstens 500 Schreibvorgaenge je Stapel.
  static const int _stapelgroesse = 400;

  DocumentReference<Map<String, dynamic>> _referenz(String pfad) =>
      _db.collection('users').doc(uid).collection(pfad.split('/').first).doc(
            pfad.split('/').last,
          );

  @override
  Future<List<CloudDokument>> alleLesen() async {
    final dokumente = <CloudDokument>[];

    for (final sammlung in CloudModell.alleSammlungen) {
      final treffer = await _db
          .collection('users')
          .doc(uid)
          .collection(sammlung)
          .get();

      for (final doc in treffer.docs) {
        dokumente.add(
          CloudDokument.ausAblage('$sammlung/${doc.id}', doc.data()),
        );
      }
    }

    return dokumente;
  }

  @override
  Future<CloudDokument?> lesen(String pfad) async {
    final doc = await _referenz(pfad).get();
    final daten = doc.data();
    if (!doc.exists || daten == null) return null;
    return CloudDokument.ausAblage(pfad, daten);
  }

  @override
  Future<void> schreiben(Iterable<CloudDokument> dokumente) async {
    for (final teil in _stapel(dokumente.toList())) {
      final stapel = _db.batch();
      for (final dokument in teil) {
        stapel.set(
          _referenz(dokument.pfad),
          dokument.zurAblage(),
          SetOptions(merge: true),
        );
      }
      await stapel.commit();
    }
  }

  @override
  Future<void> loeschen(Iterable<String> pfade) async {
    for (final teil in _stapel(pfade.toList())) {
      final stapel = _db.batch();
      for (final pfad in teil) {
        stapel.delete(_referenz(pfad));
      }
      await stapel.commit();
    }
  }

  @override
  Future<void> allesLoeschen() async {
    for (final sammlung in CloudModell.alleSammlungen) {
      final treffer = await _db
          .collection('users')
          .doc(uid)
          .collection(sammlung)
          .get();

      await loeschen(treffer.docs.map((d) => '$sammlung/${d.id}'));
    }
    // Das Kontodokument selbst bleibt stehen: Es traegt keine Nutzdaten, und
    // ein Konto ohne Dokument waere nach dem Loeschen nicht mehr von einem
    // frischen zu unterscheiden. Das Konto selbst zu entfernen ist Phase 2.3.
  }

  static Iterable<List<T>> _stapel<T>(List<T> alle) sync* {
    for (var i = 0; i < alle.length; i += _stapelgroesse) {
      yield alle.sublist(
        i,
        i + _stapelgroesse > alle.length ? alle.length : i + _stapelgroesse,
      );
    }
  }
}

/// Speicher im Arbeitsspeicher – fuer Tests von Migration und Sync.
class SpeicherAttrappe implements CloudSpeicher {
  SpeicherAttrappe([Iterable<CloudDokument> start = const []]) {
    for (final dokument in start) {
      _daten[dokument.pfad] = dokument;
    }
  }

  final Map<String, CloudDokument> _daten = {};

  /// Zaehlt die Schreibvorgaenge – so laesst sich pruefen, dass eine zweite
  /// Migration wirklich nichts mehr tut.
  int schreibzugriffe = 0;

  @override
  Future<List<CloudDokument>> alleLesen() async => _daten.values.toList();

  @override
  Future<CloudDokument?> lesen(String pfad) async => _daten[pfad];

  @override
  Future<void> schreiben(Iterable<CloudDokument> dokumente) async {
    for (final dokument in dokumente) {
      schreibzugriffe++;
      final vorhanden = _daten[dokument.pfad];
      // Wie SetOptions(merge: true) in Firestore.
      _daten[dokument.pfad] = CloudDokument(
        pfad: dokument.pfad,
        daten: {...?vorhanden?.daten, ...dokument.daten},
        aktualisiertAm: dokument.aktualisiertAm,
      );
    }
  }

  @override
  Future<void> loeschen(Iterable<String> pfade) async {
    for (final pfad in pfade) {
      _daten.remove(pfad);
    }
  }

  @override
  Future<void> allesLoeschen() async => _daten.clear();
}
