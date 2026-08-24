import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../models/richtung.dart';

/// Haelt die persoenliche Richtung und schreibt jede Aenderung sofort weg.
///
/// Die Richtung ueberlebt bewusst auch eine neue Analyse: Sie beschreibt den
/// Nutzer, nicht einen einzelnen Durchlauf, und wird beim naechsten Mal
/// vorbefuellt angeboten. Geloescht wird sie nur ueber "Alle Daten loeschen".
class DirectionController extends StateNotifier<Richtung> {
  DirectionController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const _schluessel = 'richtung';

  static Richtung _lade(KeyValueStore box) {
    final roh = box.get(_schluessel);
    if (roh is! String || roh.isEmpty) return Richtung.leer;
    try {
      final json = jsonDecode(roh);
      if (json is Map) {
        return Richtung.fromJson(Map<String, dynamic>.from(json));
      }
    } on FormatException {
      // Kaputter Eintrag: lieber ohne Richtung starten als abstuerzen.
    }
    return Richtung.leer;
  }

  void umschalten(Richtungsziel ziel) {
    final neu = Set<Richtungsziel>.from(state.ziele);
    neu.contains(ziel) ? neu.remove(ziel) : neu.add(ziel);
    _setze(state.copyWith(ziele: neu));
  }

  /// Uebernimmt den Freitext. Laenger als [Richtung.maxZeichen] kommt hier
  /// nichts an – das Eingabefeld begrenzt bereits –, der Schnitt ist die
  /// zweite Sicherung.
  void setzeFreitext(String text) {
    final gekuerzt = text.length <= Richtung.maxZeichen
        ? text
        : text.substring(0, Richtung.maxZeichen);
    if (gekuerzt == state.freitext) return;
    _setze(state.copyWith(freitext: gekuerzt));
  }

  void zuruecksetzen() {
    state = Richtung.leer;
    _box.delete(_schluessel);
  }

  void neuLaden() => state = _lade(_box);

  void _setze(Richtung richtung) {
    state = richtung;
    _box.put(_schluessel, jsonEncode(richtung.toJson()));
  }
}

final directionControllerProvider =
    StateNotifierProvider<DirectionController, Richtung>(
  (ref) => DirectionController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
