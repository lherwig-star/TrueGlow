import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';

/// Merkt sich, aus welchen Reports schon ein Plan geworden ist
/// (DECISIONS 90).
///
/// **Warum es das überhaupt braucht.** Unter dem Report steht seit dem
/// Aufräumen genau ein Knopf, und der soll sagen, was er tut: „Plan
/// erstellen", solange aus diesem Report noch keiner geworden ist, danach
/// „Zum Plan". Ohne diese Notiz gäbe es die Unterscheidung nicht — der Knopf
/// hieße für immer „Plan erstellen", auch beim zehnten Besuch.
///
/// **Warum keine Ableitung aus den vorhandenen Daten.** Naheliegend wäre
/// gewesen: „ist dies die aktuelle Analyse?" Nur ist sie das ab der Sekunde,
/// in der sie fertig ist — der Knopf hieße dann nie „Plan erstellen". Und
/// „hat jemand eine Aufgabe abgehakt?" beantwortet eine andere Frage.
///
/// **Warum es lokal bleibt.** Es ist keine Information über den Nutzer,
/// sondern über seinen Weg durch die App: eine Bedienhilfe. Sie gehört
/// deshalb nicht in die Cloud-Sicherung, und wenn sie beim Löschen der
/// lokalen Daten verschwindet, steht dort wieder „Plan erstellen" — das ist
/// nach einem Datenlöschen sogar die richtigere Antwort.
class PlanErzeugtController extends StateNotifier<Set<String>> {
  PlanErzeugtController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const schluessel = 'planErzeugt';

  /// So viele Kennungen werden behalten. Mehr braucht niemand: Der Knopf
  /// interessiert sich nur für die Reports, die jemand tatsächlich wieder
  /// aufmacht, und eine Liste, die ewig wächst, ist eine Liste, die niemand
  /// aufräumt.
  static const _hoechstens = 50;

  static Set<String> _lade(KeyValueStore box) {
    final roh = box.get(schluessel);
    return roh is List
        ? {
            for (final eintrag in roh)
              if (eintrag is String && eintrag.isNotEmpty) eintrag,
          }
        : <String>{};
  }

  bool istErzeugt(String analyseId) => state.contains(analyseId);

  /// Hält fest, dass aus diesem Report ein Plan geworden ist.
  void merken(String analyseId) {
    if (analyseId.isEmpty || state.contains(analyseId)) return;

    final neu = [...state, analyseId];
    final gekuerzt = neu.length <= _hoechstens
        ? neu
        : neu.sublist(neu.length - _hoechstens);

    state = gekuerzt.toSet();
    _box.put(schluessel, gekuerzt);
  }

  /// Nach dem Löschen aller Daten steht nichts mehr im Speicher.
  void neuLaden() => state = _lade(_box);
}

final planErzeugtProvider =
    StateNotifierProvider<PlanErzeugtController, Set<String>>(
  (ref) => PlanErzeugtController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
