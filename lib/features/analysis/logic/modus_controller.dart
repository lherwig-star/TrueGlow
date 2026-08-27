import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../models/analyse_modus.dart';

/// Hält den gewählten [AnalyseModus] des laufenden Durchlaufs.
///
/// **Warum überhaupt gespeichert**, wo die Wahl doch pro Analyse gilt: Der
/// Weg von der Moduswahl bis zum Startknopf ist lang – Module, Richtung,
/// bis zu elf Aufnahmen. Ein Absturz oder ein Anruf dazwischen darf die
/// Entscheidung nicht kosten. Aus demselben Grund liegt die Modulauswahl im
/// Speicher (siehe `module_controller.dart`).
///
/// **Warum trotzdem kein Konto-Setting:** Jeder neue Durchlauf beginnt mit
/// [zuruecksetzen] und stellt die Frage erneut. Was hier liegt, ist der
/// Zustand *eines* Flows, nicht eine Vorliebe der Person. Deshalb landet der
/// Modus auch am fertigen Report und nicht im Profil.
class ModusController extends StateNotifier<AnalyseModus> {
  ModusController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const _schluessel = 'analyseModus';

  static AnalyseModus _lade(KeyValueStore box) =>
      AnalyseModus.ausName(box.get(_schluessel));

  void waehlen(AnalyseModus modus) {
    if (modus == state) return;
    state = modus;
    _box.put(_schluessel, modus.name);
  }

  /// Zurück auf den Standard – aufgerufen, wenn ein neuer Durchlauf beginnt.
  void zuruecksetzen() {
    state = AnalyseModus.standard;
    _box.delete(_schluessel);
  }

  void neuLaden() => state = _lade(_box);
}

final modusControllerProvider =
    StateNotifierProvider<ModusController, AnalyseModus>(
  (ref) => ModusController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
