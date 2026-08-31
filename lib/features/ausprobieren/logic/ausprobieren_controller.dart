import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_modell.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../models/technik.dart';

/// Haelt die Auswahl aus „Das will ich ausprobieren" und schreibt jede
/// Aenderung sofort weg.
///
/// **Die Auswahl gilt pro Analyse und wird trotzdem gespeichert.** Das ist
/// kein Widerspruch: Mitgeschickt wird sie bei genau dem Lauf, bei dem sie
/// auf dem Schirm stand — ein fertiger Report aendert sich nicht mehr, wenn
/// jemand danach etwas anhakt. Gespeichert wird sie, damit der naechste Lauf
/// nicht bei null anfaengt: Wer Gua Sha und Kopfhautmassage ausprobiert,
/// will sie beim naechsten Mal meist wieder dabeihaben und soll nicht jedes
/// Mal dieselben zwei Haken setzen. Dieselbe Ueberlegung wie bei „Deine
/// Richtung" (DECISIONS 79).
class AusprobierenController extends StateNotifier<Set<Technik>> {
  AusprobierenController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static Set<Technik> _lade(KeyValueStore box) {
    final roh = box.get(CloudModell.keyTechniken);
    return roh is List ? Technik.ausNamen(roh) : const <Technik>{};
  }

  void umschalten(Technik technik) {
    final neu = Set<Technik>.from(state);
    neu.contains(technik) ? neu.remove(technik) : neu.add(technik);
    _setze(neu);
  }

  /// Wirft alles weg, was in dieser Analyse gar nicht angeboten wird.
  ///
  /// Gebraucht, wenn jemand nach der letzten Analyse ein Modul abwaehlt oder
  /// die Ausrichtung umstellt: Eine gemerkte Bartbuerste darf im weiblichen
  /// Modus nicht als unsichtbarer Haken weiterlaufen und schon gar nicht in
  /// den Prompt gehen. Der Server siebt dasselbe noch einmal aus – hier
  /// passiert es, damit der Zaehler auf dem Schirm die Wahrheit sagt.
  void aufAngebotKuerzen(List<Technik> angebot) {
    final erlaubt = angebot.toSet();
    final gekuerzt = state.where(erlaubt.contains).toSet();
    if (gekuerzt.length == state.length) return;
    _setze(gekuerzt);
  }

  void zuruecksetzen() {
    state = const {};
    _box.delete(CloudModell.keyTechniken);
  }

  void neuLaden() => state = _lade(_box);

  void _setze(Set<Technik> auswahl) {
    state = auswahl;
    _box.put(
      CloudModell.keyTechniken,
      Technik.sortiert(auswahl).map((t) => t.name).toList(),
    );
  }
}

final ausprobierenControllerProvider =
    StateNotifierProvider<AusprobierenController, Set<Technik>>(
  (ref) => AusprobierenController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
