import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../analysis/models/analysis_result.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/models/analyse_modul.dart';
import 'plan_progress_repository.dart';

/// Was in der vergangenen Woche zusammengekommen ist.
///
/// Vollstaendig aus den Haken gerechnet, die ohnehin schon lokal und in
/// Firestore liegen – kein Modellaufruf, keine Kosten.
class Wochenbilanz {
  const Wochenbilanz({
    required this.montag,
    required this.aktiveTage,
    required this.aufgaben,
    required this.staerksterBereich,
  });

  /// Der Montag der betrachteten Woche. Der Zeitraum ist Montag bis Sonntag.
  final DateTime montag;

  DateTime get sonntag => montag.add(const Duration(days: 6));

  /// Tage, an denen mindestens ein Haken gesetzt wurde. 0 bis 7.
  final int aktiveTage;

  /// Wie viele Aufgaben insgesamt abgehakt wurden.
  final int aufgaben;

  /// Das Kapitel mit den meisten Haken – oder `null`, wenn sich keines
  /// zuordnen laesst (etwa weil die Aufgaben aus einer aelteren Analyse
  /// stammen).
  final AnalyseModul? staerksterBereich;

  /// Eine Woche ohne einen einzigen Haken bekommt keinen Rueckblick, sondern
  /// eine Einladung.
  bool get istLeer => aufgaben == 0;
}

/// Die Stufen des Lobs. Der Ton ist bei jeder anerkennend – auch bei null.
enum Wochenton { stark, solide, klein, leer }

Wochenton tonFuer(int aktiveTage) => switch (aktiveTage) {
      >= 5 => Wochenton.stark,
      >= 3 => Wochenton.solide,
      2 => Wochenton.klein,
      _ => Wochenton.leer,
    };

/// Der Montag der Woche, in der [tag] liegt.
DateTime montagVon(DateTime tag) {
  final rein = DateTime(tag.year, tag.month, tag.day);
  return rein.subtract(Duration(days: rein.weekday - DateTime.monday));
}

/// Schluessel einer Woche – der Montag als `jjjj-mm-tt`.
String wochenschluessel(DateTime montag) =>
    PlanProgressRepository.schluessel(montag);

/// Ab wann am Sonntag der Rueckblick erscheint.
const rueckblickAbStunde = 18;

/// Welche Woche gerade zurueckgeblickt werden soll – oder `null`.
///
/// Das Fenster laeuft von Sonntagabend bis Montag um Mitternacht. Betrachtet
/// wird immer die Woche, die an diesem Sonntag endet.
///
/// **Warum ein Fenster und nicht ein Zeitpunkt.** „Sonntagabend" trifft nur,
/// wer die App am Sonntagabend oeffnet. Der Montag haengt mit dran, damit der
/// Rueckblick nicht an genau den Nutzern vorbeilaeuft, die ihn am ehesten
/// brauchen – an denen, die das Wochenende ueber nicht hineingesehen haben.
DateTime? rueckblickWoche(DateTime jetzt) {
  if (jetzt.weekday == DateTime.sunday && jetzt.hour >= rueckblickAbStunde) {
    return montagVon(jetzt);
  }
  if (jetzt.weekday == DateTime.monday) {
    return montagVon(jetzt).subtract(const Duration(days: 7));
  }
  return null;
}

/// Rechnet die Bilanz einer Woche aus den Haken.
///
/// [habitsJeKapitel] bildet den Wortlaut einer Aufgabe auf ihr Kapitel ab.
/// Aufgaben, die dort nicht vorkommen, zaehlen in die Summe, aber nicht auf
/// einen Bereich – sonst wuerde eine geaenderte Analyse den staerksten
/// Bereich stillschweigend verschieben.
Wochenbilanz wochenbilanz({
  required DateTime montag,
  required Set<String> Function(DateTime tag) erledigteAm,
  required Map<String, AnalyseModul> habitsJeKapitel,
}) {
  var aktiveTage = 0;
  var aufgaben = 0;
  final jeKapitel = <AnalyseModul, int>{};

  for (var i = 0; i < 7; i += 1) {
    final tag = montag.add(Duration(days: i));
    final erledigt = erledigteAm(tag);
    if (erledigt.isEmpty) continue;

    aktiveTage += 1;
    for (final eintrag in erledigt) {
      // Der Check-in-Marker sichert den Tag, ist aber keine Tagesaufgabe.
      if (eintrag == PlanProgressRepository.checkinMarker) continue;
      aufgaben += 1;

      final modul = habitsJeKapitel[eintrag];
      if (modul != null) jeKapitel[modul] = (jeKapitel[modul] ?? 0) + 1;
    }
  }

  AnalyseModul? staerkster;
  var beste = 0;
  // Reihenfolge der Deklaration entscheidet bei Gleichstand – damit dieselbe
  // Woche nicht bei jedem Aufruf einen anderen Sieger hat.
  for (final modul in AnalyseModul.values) {
    final anzahl = jeKapitel[modul] ?? 0;
    if (anzahl > beste) {
      beste = anzahl;
      staerkster = modul;
    }
  }

  return Wochenbilanz(
    montag: montag,
    aktiveTage: aktiveTage,
    aufgaben: aufgaben,
    staerksterBereich: staerkster,
  );
}

/// Haelt fest, welcher Rueckblick schon weggeklickt wurde.
class RueckblickSpeicher {
  RueckblickSpeicher(this._box);

  final KeyValueStore _box;

  static const _kGesehen = 'wochenrueckblickGesehen';

  String? get gesehen {
    final wert = _box.get(_kGesehen);
    return wert is String ? wert : null;
  }

  Future<void> merken(DateTime montag) =>
      _box.put(_kGesehen, wochenschluessel(montag));
}

final rueckblickSpeicherProvider = Provider<RueckblickSpeicher>(
  (ref) => RueckblickSpeicher(
    ref.watch(storeProvider(HiveService.boxFortschritt)),
  ),
);

/// Der aktuell faellige Rueckblick – oder `null`, wenn gerade keiner ansteht.
class RueckblickNotifier extends StateNotifier<Wochenbilanz?> {
  RueckblickNotifier(this._ref) : super(null) {
    aktualisieren();
  }

  final Ref _ref;

  void aktualisieren({DateTime? jetzt}) {
    final montag = rueckblickWoche(jetzt ?? DateTime.now());
    if (montag == null) {
      state = null;
      return;
    }

    final speicher = _ref.read(rueckblickSpeicherProvider);
    if (speicher.gesehen == wochenschluessel(montag)) {
      state = null;
      return;
    }

    final fortschritt = _ref.read(planProgressRepositoryProvider);
    final analyse = _ref.read(aktuelleAnalyseProvider);

    state = wochenbilanz(
      montag: montag,
      erledigteAm: fortschritt.erledigteAm,
      habitsJeKapitel: _zuordnung(analyse),
    );
  }

  Future<void> weggeklickt() async {
    final bilanz = state;
    if (bilanz == null) return;
    await _ref.read(rueckblickSpeicherProvider).merken(bilanz.montag);
    state = null;
  }

  static Map<String, AnalyseModul> _zuordnung(AnalysisResult? analyse) => {
        for (final kapitel in analyse?.kapitel ?? const <Kapitel>[])
          for (final habit in kapitel.habits) habit: kapitel.modul,
      };
}

final wochenRueckblickProvider =
    StateNotifierProvider<RueckblickNotifier, Wochenbilanz?>((ref) {
  final notifier = RueckblickNotifier(ref);
  // Ein Haken kann die Bilanz aendern, eine neue Analyse die Zuordnung.
  ref.listen(planFortschrittProvider, (_, _) => notifier.aktualisieren());
  ref.listen(analysenProvider, (_, _) => notifier.aktualisieren());
  return notifier;
});
