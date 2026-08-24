import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/hive_service.dart';
import 'cloud_dokument.dart';
import 'cloud_modell.dart';

/// Macht aus einem lokalen Schluessel-Wert-Paar die passenden
/// Cloud-Dokumente – und aus einem Cloud-Wert wieder einen lokalen.
///
/// Migration (Phase 1.5) und Sync (Phase 1.6) benutzen dieselbe Uebersetzung.
/// Zwei Fassungen davon waeren die klassische Stelle, an der Datenmodelle
/// auseinanderlaufen.
class CloudUebersetzung {
  CloudUebersetzung._();

  /// Die Dokumente, die ein einzelner lokaler Schluessel erzeugt.
  ///
  /// In aller Regel genau eines. Die Ausnahme ist die Check-in-Historie: Sie
  /// liegt lokal als eine JSON-Liste und in der Cloud als je ein Dokument mit
  /// der laufenden Nummer als ID – nur so kann ein wiederholter Lauf nichts
  /// verdoppeln.
  static List<CloudDokument> dokumenteFuer({
    required String box,
    required String schluessel,
    required Object? wert,
    required DateTime stand,
  }) {
    if (box == HiveService.boxCheckins &&
        schluessel == CloudModell.keyHistorie) {
      return _historie(wert, stand: stand);
    }

    final ziel = CloudModell.ziel(box, schluessel);
    if (ziel == null) return const [];

    final cloudWert = _cloudWert(wert);
    if (cloudWert == null) return const [];

    return [
      CloudDokument(
        pfad: ziel.pfad,
        daten: {ziel.feld: cloudWert},
        aktualisiertAm: stand,
      ),
    ];
  }

  static List<CloudDokument> _historie(Object? roh, {required DateTime stand}) {
    final liste = historieLesen(roh);
    return [
      for (final eintrag in liste)
        if (eintrag['id'] != null)
          CloudDokument(
            pfad: CloudModell.checkinPfad(eintrag['id']),
            daten: {'wert': jsonEncode(eintrag)},
            aktualisiertAm: stand,
          ),
    ];
  }

  /// Liest die lokal gespeicherte Check-in-Historie.
  ///
  /// Kaputte Eintraege liefern eine leere Liste statt einer Ausnahme: Der
  /// Sync soll an einem beschaedigten Speicher nicht haengenbleiben.
  static List<Map<String, dynamic>> historieLesen(Object? roh) {
    if (roh is! String || roh.isEmpty) return const [];
    try {
      final gelesen = jsonDecode(roh);
      if (gelesen is! List) return const [];
      return [
        for (final eintrag in gelesen.whereType<Map>())
          Map<String, dynamic>.from(eintrag),
      ];
    } on FormatException catch (e) {
      debugPrint('Historie nicht lesbar ($e)');
      return const [];
    }
  }

  /// Der Inhalt eines Check-in-Dokuments als Map.
  static Map<String, dynamic>? checkinLesen(CloudDokument dokument) {
    final roh = dokument.daten['wert'];
    if (roh is! String || roh.isEmpty) return null;
    try {
      final gelesen = jsonDecode(roh);
      return gelesen is Map ? Map<String, dynamic>.from(gelesen) : null;
    } on FormatException {
      return null;
    }
  }

  /// Bringt einen Hive-Wert in eine Form, die Firestore annimmt.
  ///
  /// Hive liefert Listen als `List<dynamic>`; Firestore braucht sie
  /// typisiert. Unbekannte Typen fallen heraus statt den Lauf zu sprengen –
  /// der lokale Bestand bleibt ja erhalten.
  static Object? _cloudWert(Object? wert) => switch (wert) {
        null => null,
        final List<dynamic> liste => liste.map((e) => '$e').toList(),
        final String s => s,
        final int i => i,
        final bool b => b,
        final double d => d,
        _ => null,
      };

  /// Der lokale Wert zu einem Cloud-Feld.
  ///
  /// Firestore liefert Listen als `List<dynamic>` zurueck; Hive und die
  /// Controller erwarten `List<String>`.
  static Object? lokalerWert(Object? wert) => switch (wert) {
        final List<dynamic> liste => liste.map((e) => '$e').toList(),
        _ => wert,
      };
}
