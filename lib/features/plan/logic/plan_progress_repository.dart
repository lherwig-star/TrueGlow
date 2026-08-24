import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';

/// Fortschritt der taeglichen Checkliste. Pro Tag wird die Liste der
/// abgehakten Habits gespeichert.
class PlanProgressRepository {
  PlanProgressRepository(this._box);

  final KeyValueStore _box;

  /// Datumsschluessel im Format yyyy-mm-tt.
  static String schluessel(DateTime tag) =>
      '${tag.year.toString().padLeft(4, '0')}-'
      '${tag.month.toString().padLeft(2, '0')}-'
      '${tag.day.toString().padLeft(2, '0')}';

  Set<String> erledigteAm(DateTime tag) {
    final wert = _box.get(schluessel(tag));
    if (wert is! List) return {};
    return wert.whereType<String>().toSet();
  }

  Set<String> get erledigteHeute => erledigteAm(DateTime.now());

  /// Marker fuer einen abgeschlossenen Check-in. Er steht im selben Topf wie
  /// die abgehakten Habits, damit der Streak ohne Sonderweg mitzaehlt – in
  /// den Checklisten taucht er nicht auf, weil dort nur die Habits des
  /// Reports gezeichnet werden.
  static const checkinMarker = '__checkin__';

  /// Traegt einen Eintrag fuer heute ein, ohne ihn umzuschalten.
  Future<Set<String>> merken(String eintrag) async {
    final heute = erledigteHeute;
    if (!heute.add(eintrag)) return heute;

    await _box.put(schluessel(DateTime.now()), heute.toList());
    return heute;
  }

  Future<Set<String>> umschalten(String habit) async {
    final heute = erledigteHeute;
    heute.contains(habit) ? heute.remove(habit) : heute.add(habit);

    final key = schluessel(DateTime.now());
    if (heute.isEmpty) {
      await _box.delete(key);
    } else {
      await _box.put(key, heute.toList());
    }
    return heute;
  }
}

/// Abgehakte Aufgaben des heutigen Tages.
///
/// Die Serie steckt bewusst nicht hier, sondern im StreakRepository – sonst
/// gaebe es zwei Rechenwege fuer dieselbe Zahl.
class PlanFortschritt {
  const PlanFortschritt({required this.erledigt});

  final Set<String> erledigt;
}

class PlanProgressNotifier extends StateNotifier<PlanFortschritt> {
  PlanProgressNotifier(this._repo)
      : super(PlanFortschritt(erledigt: _repo.erledigteHeute));

  final PlanProgressRepository _repo;

  Future<void> umschalten(String habit) async {
    state = PlanFortschritt(erledigt: await _repo.umschalten(habit));
  }

  /// Der abgeschlossene Check-in zaehlt als erledigte Aufgabe des Tages.
  Future<void> checkinGezaehlt() async {
    state = PlanFortschritt(
      erledigt: await _repo.merken(PlanProgressRepository.checkinMarker),
    );
  }

  void neuLaden() => state = PlanFortschritt(erledigt: _repo.erledigteHeute);
}

final planProgressRepositoryProvider = Provider<PlanProgressRepository>(
  (ref) => PlanProgressRepository(ref.watch(storeProvider(HiveService.boxFortschritt))),
);

final planFortschrittProvider =
    StateNotifierProvider<PlanProgressNotifier, PlanFortschritt>(
  (ref) => PlanProgressNotifier(ref.watch(planProgressRepositoryProvider)),
);
