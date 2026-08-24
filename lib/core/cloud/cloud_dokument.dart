import 'package:flutter/foundation.dart';

/// Ein einzelnes Dokument im Nutzerbaum `users/{uid}/…`.
///
/// [pfad] ist immer relativ zum Konto (`daten/profil`, `analysen/17…`,
/// `fortschritt/2026-08-24`). Damit taucht die uid nirgends im Modell auf –
/// wer sie braucht, ist ausschliesslich der [CloudSpeicher].
@immutable
class CloudDokument {
  const CloudDokument({
    required this.pfad,
    required this.daten,
    required this.aktualisiertAm,
  });

  /// Pfad relativ zu `users/{uid}`, immer mit gerader Segmentzahl
  /// (Sammlung/Dokument).
  final String pfad;

  /// Die Nutzdaten ohne Metafelder.
  final Map<String, dynamic> daten;

  /// Zeitstempel der letzten Aenderung, in UTC.
  ///
  /// Er ist die gesamte Konfliktlogik: Beim Zusammenfuehren gewinnt der
  /// juengere Stand, bei Gleichstand die Cloud (siehe DECISIONS.md, 9).
  final DateTime aktualisiertAm;

  /// Feldname des Zeitstempels im Firestore-Dokument.
  static const String feldAktualisiertAm = 'aktualisiertAm';

  /// Die Sammlung, in der das Dokument liegt (erstes Pfadsegment).
  String get sammlung => pfad.split('/').first;

  /// Die Dokument-ID (letztes Pfadsegment).
  String get id => pfad.split('/').last;

  CloudDokument mitDaten(Map<String, dynamic> neu) => CloudDokument(
        pfad: pfad,
        daten: neu,
        aktualisiertAm: aktualisiertAm,
      );

  /// Wie das Dokument in Firestore aussieht: Nutzdaten plus Zeitstempel.
  Map<String, dynamic> zurAblage() => {
        ...daten,
        feldAktualisiertAm: aktualisiertAm.toUtc().toIso8601String(),
      };

  /// Liest ein Dokument aus der Ablage zurueck.
  ///
  /// Ein fehlender oder kaputter Zeitstempel wird als "uralt" gewertet: So
  /// gewinnt im Zweifel der lokale Stand, statt dass ein defektes
  /// Cloud-Dokument gute Daten ueberschreibt.
  factory CloudDokument.ausAblage(String pfad, Map<String, dynamic> roh) {
    final daten = Map<String, dynamic>.from(roh)..remove(feldAktualisiertAm);
    return CloudDokument(
      pfad: pfad,
      daten: daten,
      aktualisiertAm: _zeitstempel(roh[feldAktualisiertAm]),
    );
  }

  static DateTime _zeitstempel(Object? wert) {
    if (wert is String) {
      final gelesen = DateTime.tryParse(wert);
      if (gelesen != null) return gelesen.toUtc();
    }
    return DateTime.utc(1970);
  }

  @override
  bool operator ==(Object other) =>
      other is CloudDokument &&
      other.pfad == pfad &&
      other.aktualisiertAm == aktualisiertAm &&
      mapEquals(other.daten, daten);

  @override
  int get hashCode => Object.hash(pfad, aktualisiertAm);

  @override
  String toString() => 'CloudDokument($pfad, $aktualisiertAm)';
}
