import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../analysis/models/analysis_result.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/models/analyse_modul.dart';
import '../../plan/logic/plan_progress_repository.dart';
import '../models/abzeichen.dart';

/// Wann ein Tag als geschafft gilt.
enum Tagesziel {
  /// Mindestens eine Aufgabe abgehakt.
  eineAufgabe,

  /// Alle Tagesaufgaben abgehakt.
  alleAufgaben,
}

/// Aktueller Stand der Serie.
class StreakStand {
  const StreakStand({
    required this.aktuell,
    required this.rekord,
    required this.letzterTag,
    required this.heuteGesichert,
    required this.gefeiert,
  });

  /// Tage am Stueck.
  final int aktuell;

  /// Laengste je erreichte Serie. Bleibt beim Zuruecksetzen stehen.
  final int rekord;

  /// Letzter Tag, an dem das Tagesziel erreicht wurde.
  final DateTime? letzterTag;

  /// Ob der heutige Tag schon gesichert ist – steuert die gedimmte Flamme.
  final bool heuteGesichert;

  /// Abzeichen, deren Jubel-Moment bereits gezeigt wurde.
  final Set<Abzeichen> gefeiert;

  static const leer = StreakStand(
    aktuell: 0,
    rekord: 0,
    letzterTag: null,
    heuteGesichert: false,
    gefeiert: {},
  );
}

/// Rechnet die Serie aus den abgehakten Tagen und haelt Rekord sowie die
/// bereits gefeierten Abzeichen fest.
///
/// Die Serie selbst wird bewusst immer neu aus den Tagesdaten abgeleitet statt
/// nur fortgeschrieben: damit stimmt sie auch dann, wenn die App tagelang
/// nicht offen war – der Reset passiert schon beim Laden und nicht erst beim
/// naechsten Abhaken.
class StreakRepository {
  StreakRepository(this._box, this._fortschritt);

  final KeyValueStore _box;
  final PlanProgressRepository _fortschritt;

  /// Umschalter fuer die Bedingung eines geschafften Tages.
  static const Tagesziel tagesziel = Tagesziel.eineAufgabe;

  /// Sicherheitsnetz gegen kaputte Daten beim Rueckwaertslaufen.
  static const _maxTage = 3650;

  static const _kAktuell = 'streakAktuell';
  static const _kRekord = 'streakRekord';
  static const _kLetzterTag = 'streakLetzterTag';
  static const _kGefeiert = 'abzeichenGefeiert';

  static DateTime heute() {
    final jetzt = DateTime.now();
    return DateTime(jetzt.year, jetzt.month, jetzt.day);
  }

  /// Ob an [tag] das Tagesziel erreicht wurde.
  ///
  /// Im Modus [Tagesziel.alleAufgaben] wird die heutige Aufgabenliste auch auf
  /// vergangene Tage angewandt – die damalige Liste ist nicht gespeichert.
  bool geschafftAm(DateTime tag, List<String> habits) {
    final erledigt = _fortschritt.erledigteAm(tag);
    return switch (tagesziel) {
      Tagesziel.eineAufgabe => erledigt.isNotEmpty,
      Tagesziel.alleAufgaben =>
        habits.isNotEmpty && habits.every(erledigt.contains),
    };
  }

  /// Zaehlt aufeinanderfolgende geschaffte Tage.
  ///
  /// Der heutige Tag zaehlt nur mit, wenn schon etwas erledigt ist – ein noch
  /// leerer Vormittag soll die Serie aber nicht abreissen lassen.
  int berechneAktuell(List<String> habits) {
    final start = heute();
    var tag = geschafftAm(start, habits)
        ? start
        : start.subtract(const Duration(days: 1));

    var zaehler = 0;
    while (geschafftAm(tag, habits)) {
      zaehler++;
      tag = tag.subtract(const Duration(days: 1));
      if (zaehler >= _maxTage) break;
    }
    return zaehler;
  }

  /// Letzter geschaffter Tag – heute oder gestern, sonst der gespeicherte.
  DateTime? _letzterTag(List<String> habits) {
    final start = heute();
    if (geschafftAm(start, habits)) return start;

    final gestern = start.subtract(const Duration(days: 1));
    if (geschafftAm(gestern, habits)) return gestern;

    final gespeichert = _box.get(_kLetzterTag);
    return gespeichert is String ? DateTime.tryParse(gespeichert) : null;
  }

  /// Liest den Stand, rechnet ihn neu und schreibt ihn zurueck.
  StreakStand laden(List<String> habits) {
    final aktuell = berechneAktuell(habits);
    final gespeicherterRekord = switch (_box.get(_kRekord)) {
      final int i => i,
      _ => 0,
    };
    final rekord = math.max(aktuell, gespeicherterRekord);
    final letzter = _letzterTag(habits);

    _box.put(_kAktuell, aktuell);
    _box.put(_kRekord, rekord);
    if (letzter != null) {
      _box.put(_kLetzterTag, letzter.toIso8601String());
    }

    return StreakStand(
      aktuell: aktuell,
      rekord: rekord,
      letzterTag: letzter,
      heuteGesichert: geschafftAm(heute(), habits),
      gefeiert: _gefeierte(),
    );
  }

  Set<Abzeichen> _gefeierte() {
    final roh = _box.get(_kGefeiert);
    if (roh is! List) return {};
    return {
      for (final name in roh.whereType<String>())
        ...Abzeichen.values.where((a) => a.name == name),
    };
  }

  Future<void> alsGefeiertMerken(Abzeichen abzeichen) async {
    final neu = {..._gefeierte(), abzeichen};
    await _box.put(_kGefeiert, neu.map((a) => a.name).toList());
  }
}

/// Ermittelt, welche Abzeichen erreicht sind und was den offenen noch fehlt.
List<AbzeichenStand> abzeichenStaende({
  required StreakStand streak,
  required AnalysisResult? analyse,
}) {
  final module = analyse?.module ?? const <AnalyseModul>{};
  final alleModule = module.length == AnalyseModul.values.length;

  return [
    for (final abzeichen in Abzeichen.values)
      switch (abzeichen) {
        Abzeichen.ersteAnalyse => AbzeichenStand(
            abzeichen: abzeichen,
            erreicht: analyse != null,
            fehlend: analyse != null ? 0 : 1,
          ),
        Abzeichen.alleModule => AbzeichenStand(
            abzeichen: abzeichen,
            erreicht: alleModule,
            fehlend: AnalyseModul.values.length - module.length,
          ),
        _ => AbzeichenStand(
            abzeichen: abzeichen,
            erreicht: streak.aktuell >= abzeichen.tage!,
            fehlend: (abzeichen.tage! - streak.aktuell).clamp(0, abzeichen.tage!),
          ),
      },
  ];
}

class StreakNotifier extends StateNotifier<StreakStand> {
  StreakNotifier(this._repo, this._habits) : super(StreakStand.leer) {
    aktualisieren();
  }

  final StreakRepository _repo;
  final List<String> Function() _habits;

  void aktualisieren() => state = _repo.laden(_habits());

  Future<void> gefeiert(Abzeichen abzeichen) async {
    await _repo.alsGefeiertMerken(abzeichen);
    aktualisieren();
  }
}

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepository(
    ref.watch(storeProvider(HiveService.boxFortschritt)),
    ref.watch(planProgressRepositoryProvider),
  );
});

final streakProvider = StateNotifierProvider<StreakNotifier, StreakStand>(
  (ref) {
    final notifier = StreakNotifier(
      ref.watch(streakRepositoryProvider),
      () => ref.read(aktuelleAnalyseProvider)?.alleHabits ?? const [],
    );
    // Jeder Haken und jede neue Analyse kann die Serie veraendern.
    ref.listen(planFortschrittProvider, (_, _) => notifier.aktualisieren());
    ref.listen(analysenProvider, (_, _) => notifier.aktualisieren());
    return notifier;
  },
);

/// Abzeichen mit ihrem aktuellen Stand, in Anzeigereihenfolge.
final abzeichenProvider = Provider<List<AbzeichenStand>>((ref) {
  return abzeichenStaende(
    streak: ref.watch(streakProvider),
    analyse: ref.watch(aktuelleAnalyseProvider),
  );
});

/// Das naechste Abzeichen, dessen Jubel-Moment noch aussteht.
final offenerJubelProvider = Provider<Abzeichen?>((ref) {
  final gefeiert = ref.watch(streakProvider).gefeiert;
  return ref
      .watch(abzeichenProvider)
      .where((s) => s.erreicht && !gefeiert.contains(s.abzeichen))
      .map((s) => s.abzeichen)
      .firstOrNull;
});
