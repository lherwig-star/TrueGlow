import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../history/logic/analysis_repository.dart';
import 'plan_progress_repository.dart';
import 'wochen_rueckblick.dart';

/// Die Sorten von Wochen-Challenges.
///
/// Bewusst wenige: Aus sechs Sorten und verschiedenen Zielzahlen entstehen
/// zehn Vorlagen, und jede Sorte braucht nur einen Satz Text statt zehn.
enum Challengeart {
  /// An [ziel] Tagen mindestens einen Punkt abhaken.
  aktiveTage,

  /// [ziel] Tage in Folge mindestens einen Punkt.
  serie,

  /// An [ziel] Tagen die komplette Checkliste.
  volleTage,

  /// [ziel] Aufgaben ueber die Woche verteilt.
  aufgaben,

  /// Montag bis Mittwoch je ein Haken.
  frueheWoche,

  /// Samstag und Sonntag je ein Haken.
  wochenende,
}

/// Eine Vorlage aus dem Vorrat.
class Challengevorlage {
  const Challengevorlage(this.art, this.ziel, {required this.icon});

  final Challengeart art;

  /// Wie viel zu schaffen ist. Bei [Challengeart.frueheWoche] und
  /// [Challengeart.wochenende] steht die Zahl fest.
  final int ziel;

  final IconData icon;
}

/// Der Vorrat, aus dem wöchentlich rotiert wird.
///
/// Zehn Stück: genug, dass sich in einem Vierteljahr nichts wiederholt, und
/// wenig genug, dass jede einzelne einen Sinn ergibt. Die Reihenfolge ist die
/// Rotation – sie wechselt zwischen leicht und schwer, damit nicht zwei
/// harte Wochen aufeinandertreffen.
const vorrat = <Challengevorlage>[
  Challengevorlage(Challengeart.aktiveTage, 3, icon: Icons.event_available_outlined),
  Challengevorlage(Challengeart.volleTage, 2, icon: Icons.checklist_rtl),
  Challengevorlage(Challengeart.serie, 4, icon: Icons.local_fire_department_outlined),
  Challengevorlage(Challengeart.aufgaben, 15, icon: Icons.done_all),
  Challengevorlage(Challengeart.frueheWoche, 3, icon: Icons.rocket_launch_outlined),
  Challengevorlage(Challengeart.aktiveTage, 5, icon: Icons.event_available_outlined),
  Challengevorlage(Challengeart.wochenende, 2, icon: Icons.weekend_outlined),
  Challengevorlage(Challengeart.volleTage, 3, icon: Icons.checklist_rtl),
  Challengevorlage(Challengeart.aufgaben, 25, icon: Icons.done_all),
  Challengevorlage(Challengeart.serie, 6, icon: Icons.local_fire_department_outlined),
];

/// Der Montag, ab dem gezaehlt wird. Ein fester Punkt, damit die Rotation auf
/// jedem Geraet dieselbe ist – Montag, 5. Januar 2026.
final challengeEpoche = DateTime(2026, 1, 5);

/// Welche Vorlage in der Woche ab [montag] dran ist.
Challengevorlage vorlageFuer(DateTime montag) {
  final wochen = montag.difference(challengeEpoche).inDays ~/ 7;
  // Auch fuer Wochen vor der Epoche ein gueltiger Index.
  final index = ((wochen % vorrat.length) + vorrat.length) % vorrat.length;
  return vorrat[index];
}

/// Die Challenge dieser Woche samt Fortschritt.
class Wochenchallenge {
  const Wochenchallenge({
    required this.vorlage,
    required this.montag,
    required this.stand,
    required this.geschafft,
  });

  final Challengevorlage vorlage;
  final DateTime montag;

  /// Wie weit die Person ist – dieselbe Einheit wie [Challengevorlage.ziel].
  final int stand;

  /// Ob sie in dieser Woche erreicht wurde. Einmal geschafft, bleibt
  /// geschafft, auch wenn ein Haken danach wieder entfernt wird.
  final bool geschafft;

  int get ziel => vorlage.ziel;

  double get anteil => ziel == 0 ? 0 : (stand / ziel).clamp(0, 1).toDouble();

  /// In wie viele Segmente der Balken zerfaellt.
  ///
  /// Ein Segment je Zieleinheit – „4 Tage" ergibt vier Punkte, und man sieht
  /// auf einen Blick, wie viele noch fehlen. Bei „25 Aufgaben" waeren
  /// fuenfundzwanzig Striche nebeneinander aber unlesbar; ab elf wird
  /// deshalb gebuendelt, moeglichst auf einen Teiler, damit jedes Segment
  /// gleich viel wert ist.
  int get segmente => segmenteFuer(ziel);

  /// Wie viele davon gefuellt sind.
  int get gefuellteSegmente => (anteil * segmente).floor().clamp(0, segmente);
}

/// Siehe [Wochenchallenge.segmente].
int segmenteFuer(int ziel) {
  if (ziel <= 10) return ziel < 1 ? 1 : ziel;
  for (final teiler in [5, 4, 6, 3]) {
    if (ziel % teiler == 0) return teiler;
  }
  return 5;
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension ChallengeartText on Challengeart {
  String text(L texte, int ziel) => switch (this) {
        Challengeart.aktiveTage => texte.challengeAktiveTage(ziel),
        Challengeart.serie => texte.challengeSerie(ziel),
        Challengeart.volleTage => texte.challengeVolleTage(ziel),
        Challengeart.aufgaben => texte.challengeAufgaben(ziel),
        Challengeart.frueheWoche => texte.challengeFrueheWoche,
        Challengeart.wochenende => texte.challengeWochenende,
      };
}

/// Rechnet den Stand einer Challenge aus den Haken der Woche.
///
/// [habits] sind die Aufgaben des aktuellen Plans – gebraucht nur, um einen
/// „vollen" Tag zu erkennen. Ohne Plan gibt es keine vollen Tage; das ist
/// richtig so, denn eine leere Checkliste ist nicht abgehakt, sondern leer.
int challengeStand({
  required Challengevorlage vorlage,
  required DateTime montag,
  required Set<String> Function(DateTime tag) erledigteAm,
  required List<String> habits,
}) {
  bool aktiv(int index) => erledigteAm(montag.add(Duration(days: index)))
      .isNotEmpty;

  bool voll(int index) {
    if (habits.isEmpty) return false;
    final erledigt = erledigteAm(montag.add(Duration(days: index)));
    return habits.every(erledigt.contains);
  }

  switch (vorlage.art) {
    case Challengeart.aktiveTage:
      return [for (var i = 0; i < 7; i += 1) i].where(aktiv).length;

    case Challengeart.volleTage:
      return [for (var i = 0; i < 7; i += 1) i].where(voll).length;

    case Challengeart.aufgaben:
      var summe = 0;
      for (var i = 0; i < 7; i += 1) {
        for (final eintrag in erledigteAm(montag.add(Duration(days: i)))) {
          if (eintrag == PlanProgressRepository.checkinMarker) continue;
          summe += 1;
        }
      }
      return summe;

    case Challengeart.serie:
      var beste = 0;
      var laufend = 0;
      for (var i = 0; i < 7; i += 1) {
        laufend = aktiv(i) ? laufend + 1 : 0;
        if (laufend > beste) beste = laufend;
      }
      return beste;

    case Challengeart.frueheWoche:
      return [0, 1, 2].where(aktiv).length;

    case Challengeart.wochenende:
      return [5, 6].where(aktiv).length;
  }
}

/// Speichert, welche Wochen geschafft wurden.
///
/// Nur die Wochenschluessel, keine Ergebnisse: Was zaehlt, ist die Zahl der
/// geschafften Challenges fuer das Abzeichen. Eine verpasste Woche wird
/// ausdruecklich **nicht** vermerkt – sie verfaellt kommentarlos.
class ChallengeSpeicher {
  ChallengeSpeicher(this._box);

  final KeyValueStore _box;

  static const _kGeschafft = 'challengesGeschafft';

  Set<String> get geschaffteWochen {
    final roh = _box.get(_kGeschafft);
    return roh is List ? roh.whereType<String>().toSet() : <String>{};
  }

  int get anzahl => geschaffteWochen.length;

  bool istGeschafft(DateTime montag) =>
      geschaffteWochen.contains(wochenschluessel(montag));

  Future<void> merken(DateTime montag) async {
    final neu = {...geschaffteWochen, wochenschluessel(montag)};
    await _box.put(_kGeschafft, neu.toList());
  }
}

final challengeSpeicherProvider = Provider<ChallengeSpeicher>(
  (ref) => ChallengeSpeicher(
    ref.watch(storeProvider(HiveService.boxFortschritt)),
  ),
);

class ChallengeNotifier extends StateNotifier<Wochenchallenge?> {
  ChallengeNotifier(this._ref) : super(null) {
    aktualisieren();
  }

  final Ref _ref;

  void aktualisieren({DateTime? jetzt}) {
    final montag = montagVon(jetzt ?? DateTime.now());
    final vorlage = vorlageFuer(montag);
    final speicher = _ref.read(challengeSpeicherProvider);

    final stand = challengeStand(
      vorlage: vorlage,
      montag: montag,
      erledigteAm: _ref.read(planProgressRepositoryProvider).erledigteAm,
      habits: _ref.read(aktuelleAnalyseProvider)?.alleHabits ?? const [],
    );

    // Einmal geschafft, bleibt geschafft: Wer einen Haken wieder entfernt,
    // soll nicht sehen, wie ihm eine erreichte Challenge abhandenkommt.
    final schonVermerkt = speicher.istGeschafft(montag);
    if (!schonVermerkt && stand >= vorlage.ziel) {
      speicher.merken(montag);
    }

    state = Wochenchallenge(
      vorlage: vorlage,
      montag: montag,
      stand: stand,
      geschafft: schonVermerkt || stand >= vorlage.ziel,
    );
  }
}

final wochenChallengeProvider =
    StateNotifierProvider<ChallengeNotifier, Wochenchallenge?>((ref) {
  final notifier = ChallengeNotifier(ref);
  ref.listen(planFortschrittProvider, (_, _) => notifier.aktualisieren());
  ref.listen(analysenProvider, (_, _) => notifier.aktualisieren());
  return notifier;
});

/// Wie viele Challenges bisher geschafft wurden – Grundlage des Abzeichens.
final geschaffteChallengesProvider = Provider<int>((ref) {
  // Haengt am Fortschritt, damit die Zahl mitwaechst, sobald eine Challenge
  // in dieser Woche faellt.
  ref.watch(wochenChallengeProvider);
  return ref.watch(challengeSpeicherProvider).anzahl;
});
