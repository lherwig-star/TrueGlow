import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../capture/logic/capture_controller.dart';
import '../../capture/logic/image_quality_service.dart';
import '../../capture/models/aufnahme_typ.dart';
import '../../capture/models/photo_check_result.dart';
import '../models/checkin.dart';
import 'checkin_zeitplan.dart';

/// Zeitplan, laufender Entwurf und Historie der Check-ins.
class CheckinZustand {
  const CheckinZustand({
    this.planStart,
    this.naechsterIndex = 0,
    this.naechsterTermin,
    this.entwurf,
    this.historie = const [],
    this.neueHabits = const {},
    this.fotoProblem,
    this.fotoLaeuft = false,
  });

  /// Startdatum des laufenden Plans. Ohne Plan gibt es keine Check-ins.
  final DateTime? planStart;

  /// Laufende Nummer des naechsten Check-ins (0 = Tag 7).
  final int naechsterIndex;

  final DateTime? naechsterTermin;

  /// Angefangener, noch nicht abgeschlossener Check-in.
  final Checkin? entwurf;

  /// Abgeschlossene Check-ins, aelteste zuerst.
  final List<Checkin> historie;

  /// Habits, die ein Check-in neu in den Plan gebracht hat, mit dem Tag der
  /// Aenderung – Grundlage der "Neu ab heute"-Markierung.
  final Map<String, DateTime> neueHabits;

  /// Warum das Fortschrittsfoto abgelehnt wurde. Nicht gespeichert – der
  /// Hinweis gilt nur fuer den laufenden Versuch.
  final PhotoProblem? fotoProblem;

  /// Waehrend der Qualitaetscheck des Fortschrittsfotos laeuft.
  final bool fotoLaeuft;

  CheckinTyp get naechsterTyp => CheckinZeitplan.typFuer(naechsterIndex);

  /// Ob gerade ein Check-in ansteht.
  bool faellig({DateTime? jetzt}) =>
      naechsterTermin != null &&
      CheckinZeitplan.istFaellig(naechsterTermin!, jetzt: jetzt);

  /// Tage bis zum naechsten Check-in; null ohne Plan.
  int? get tageBis => naechsterTermin == null
      ? null
      : CheckinZeitplan.tageBis(naechsterTermin!);

  /// Ob der faellige Check-in schon angefangen wurde.
  bool get begonnen => entwurf != null;

  /// Der letzte abgeschlossene Check-in.
  Checkin? get letzter => historie.isEmpty ? null : historie.last;

  CheckinZustand copyWith({
    DateTime? planStart,
    int? naechsterIndex,
    DateTime? naechsterTermin,
    Checkin? entwurf,
    bool entwurfLoeschen = false,
    List<Checkin>? historie,
    Map<String, DateTime>? neueHabits,
    PhotoProblem? fotoProblem,
    bool fotoProblemLoeschen = false,
    bool? fotoLaeuft,
  }) {
    return CheckinZustand(
      planStart: planStart ?? this.planStart,
      naechsterIndex: naechsterIndex ?? this.naechsterIndex,
      naechsterTermin: naechsterTermin ?? this.naechsterTermin,
      entwurf: entwurfLoeschen ? null : (entwurf ?? this.entwurf),
      historie: historie ?? this.historie,
      neueHabits: neueHabits ?? this.neueHabits,
      fotoProblem:
          fotoProblemLoeschen ? null : (fotoProblem ?? this.fotoProblem),
      fotoLaeuft: fotoLaeuft ?? this.fotoLaeuft,
    );
  }

  static const leer = CheckinZustand();
}

/// Haelt den Check-in-Zyklus und schreibt jede Aenderung sofort weg.
///
/// Ein Check-in verfaellt nie: Solange er offen ist, bleibt sein Termin
/// stehen. Der naechste Termin haengt am Abschluss des vorherigen und nicht
/// starr am Planstart – sonst wuerden sich nach einer Pause mehrere Check-ins
/// stapeln.
class CheckinController extends StateNotifier<CheckinZustand> {
  CheckinController(this._box, this._bildpruefung) : super(_lade(_box));

  final KeyValueStore _box;
  final ImageQualityService _bildpruefung;

  /// Aufnahme, die als Fortschrittsfoto dient – dieselbe Perspektive wie das
  /// Erstfoto der Analyse.
  static const fortschrittsTyp = AufnahmeTyp.basisFrontal;

  /// Eigener Namensraum auf der Platte: Das Erstfoto muss erhalten bleiben,
  /// sonst gibt es nichts zu vergleichen.
  static String _namensraum(int checkinId) => 'fortschritt${checkinId}_'
      '${fortschrittsTyp.name}';

  static const _kPlanStart = 'planStart';
  static const _kIndex = 'naechsterIndex';
  static const _kTermin = 'naechsterTermin';
  static const _kEntwurf = 'entwurf';
  static const _kHistorie = 'historie';
  static const _kNeueHabits = 'neueHabits';

  static CheckinZustand _lade(KeyValueStore box) {
    DateTime? datum(String schluessel) {
      final roh = box.get(schluessel);
      return roh is String ? DateTime.tryParse(roh) : null;
    }

    return CheckinZustand(
      planStart: datum(_kPlanStart),
      naechsterIndex: switch (box.get(_kIndex)) {
        final int i => i,
        _ => 0,
      },
      naechsterTermin: datum(_kTermin),
      entwurf: _lesenEinzeln(box.get(_kEntwurf)),
      historie: _lesenListe(box.get(_kHistorie)),
      neueHabits: _lesenNeueHabits(box.get(_kNeueHabits)),
    );
  }

  static Checkin? _lesenEinzeln(Object? roh) {
    if (roh is! String || roh.isEmpty) return null;
    try {
      final json = jsonDecode(roh);
      return json is Map
          ? Checkin.fromJson(Map<String, dynamic>.from(json))
          : null;
    } on FormatException {
      return null;
    }
  }

  static List<Checkin> _lesenListe(Object? roh) {
    if (roh is! String || roh.isEmpty) return const [];
    try {
      final json = jsonDecode(roh);
      if (json is! List) return const [];
      return [
        for (final e in json.whereType<Map>())
          ?Checkin.fromJson(Map<String, dynamic>.from(e)),
      ];
    } on FormatException {
      return const [];
    }
  }

  static Map<String, DateTime> _lesenNeueHabits(Object? roh) {
    if (roh is! String || roh.isEmpty) return const {};
    try {
      final json = jsonDecode(roh);
      if (json is! Map) return const {};
      final gelesen = <String, DateTime>{};
      for (final eintrag in json.entries) {
        final tag = DateTime.tryParse('${eintrag.value}');
        if (tag != null) gelesen['${eintrag.key}'] = tag;
      }
      return gelesen;
    } on FormatException {
      return const {};
    }
  }

  /// Startet den Zyklus, sobald ein Plan existiert. Mehrfaches Aufrufen ist
  /// unschaedlich – ein laufender Zyklus wird nicht angefasst.
  void planSicherstellen(DateTime planStart) {
    if (state.planStart != null) return;
    _neuStarten(planStart);
  }

  /// Beginnt den Zyklus von vorn – der Weg ueber "Neue Analyse".
  void neuBeginnen(DateTime planStart) => _neuStarten(planStart);

  void _neuStarten(DateTime planStart) {
    final termin = CheckinZeitplan.termin(index: 0, planStart: planStart);
    state = CheckinZustand(
      planStart: planStart,
      naechsterIndex: 0,
      naechsterTermin: termin,
      historie: state.historie,
      neueHabits: state.neueHabits,
    );
    _box.put(_kPlanStart, planStart.toIso8601String());
    _box.put(_kIndex, 0);
    _box.put(_kTermin, termin.toIso8601String());
    _box.delete(_kEntwurf);
  }

  /// Der Check-in, der gerade ansteht – der angefangene Entwurf oder ein
  /// frischer. Null, wenn nichts faellig ist.
  Checkin? faelligerCheckin({DateTime? jetzt}) {
    if (!state.faellig(jetzt: jetzt)) return null;
    return state.entwurf ??
        Checkin(
          id: state.naechsterIndex,
          typ: state.naechsterTyp,
          faelligAm: state.naechsterTermin!,
        );
  }

  /// Zwischenstand sichern – der Check-in ist jederzeit abbrechbar.
  void entwurfSichern(Checkin checkin) {
    state = state.copyWith(entwurf: checkin);
    _box.put(_kEntwurf, jsonEncode(checkin.toJson()));
  }

  /// Prueft ein frisch aufgenommenes Fortschrittsfoto und haengt es an den
  /// Entwurf. Laeuft durch denselben Qualitaetscheck wie die Analyse-Fotos.
  Future<bool> fortschrittsfotoUebernehmen(File datei) async {
    final entwurf = state.entwurf;
    if (entwurf == null || state.fotoLaeuft) return false;

    state = state.copyWith(fotoLaeuft: true, fotoProblemLoeschen: true);

    final ergebnis = await _bildpruefung.pruefeUndVerarbeite(
      datei: datei,
      typ: fortschrittsTyp,
      namensraum: _namensraum(entwurf.id),
    );

    switch (ergebnis) {
      case PhotoCheckOk(:final foto):
        state = state.copyWith(fotoLaeuft: false);
        entwurfSichern(entwurf.copyWith(fortschrittsfoto: foto.pfad));
        return true;
      case PhotoCheckFehler(:final problem):
        state = state.copyWith(fotoLaeuft: false, fotoProblem: problem);
        return false;
    }
  }

  void fotoProblemVerwerfen() =>
      state = state.copyWith(fotoProblemLoeschen: true);

  void entwurfVerwerfen() {
    state = state.copyWith(entwurfLoeschen: true);
    _box.delete(_kEntwurf);
  }

  /// Schliesst den Check-in ab, legt ihn in die Historie und plant den
  /// naechsten – gerechnet ab heute, damit sich nichts staut.
  Future<void> abschliessen(Checkin checkin) async {
    final erledigt = checkin.erledigtAm ?? DateTime.now();
    final fertig = checkin.copyWith(erledigtAm: erledigt);

    final index = state.naechsterIndex + 1;
    final termin = CheckinZeitplan.termin(
      index: index,
      planStart: state.planStart ?? erledigt,
      zuletztErledigt: erledigt,
    );

    final historie = [...state.historie, fertig];

    state = state.copyWith(
      naechsterIndex: index,
      naechsterTermin: termin,
      historie: historie,
      entwurfLoeschen: true,
    );

    await _box.put(_kIndex, index);
    await _box.put(_kTermin, termin.toIso8601String());
    await _box.put(
      _kHistorie,
      jsonEncode(historie.map((c) => c.toJson()).toList()),
    );
    await _box.delete(_kEntwurf);
  }

  /// Merkt sich frisch angepasste Habits fuer die Markierung in der
  /// Checkliste.
  Future<void> habitsAlsNeuMerken(Set<String> habits) async {
    if (habits.isEmpty) return;

    final heute = DateTime.now();
    final neu = {
      ...state.neueHabits,
      for (final habit in habits) habit: heute,
    };

    state = state.copyWith(neueHabits: neu);
    await _box.put(
      _kNeueHabits,
      jsonEncode({
        for (final e in neu.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  void zuruecksetzen() {
    state = CheckinZustand.leer;
    for (final schluessel in [
      _kPlanStart,
      _kIndex,
      _kTermin,
      _kEntwurf,
      _kHistorie,
      _kNeueHabits,
    ]) {
      _box.delete(schluessel);
    }
  }

  void neuLaden() => state = _lade(_box);
}

final checkinControllerProvider =
    StateNotifierProvider<CheckinController, CheckinZustand>(
  (ref) => CheckinController(
    ref.watch(storeProvider(HiveService.boxCheckins)),
    ref.watch(imageQualityServiceProvider),
  ),
);

/// Wie lange eine Aenderung als "neu" markiert bleibt.
const _neuMarkierungTage = 7;

/// Habits, die ein Check-in kuerzlich neu in den Plan gebracht hat, mit dem
/// Hinweistext fuer die Checkliste.
final neueHabitsProvider = Provider<Map<String, String>>((ref) {
  final neu = ref.watch(checkinControllerProvider).neueHabits;
  final heute = DateTime.now();

  String? hinweis(DateTime seit) {
    final tage = DateTime(heute.year, heute.month, heute.day)
        .difference(DateTime(seit.year, seit.month, seit.day))
        .inDays;
    if (tage < 0 || tage > _neuMarkierungTage) return null;
    return tage == 0 ? 'Neu ab heute' : 'Neu';
  }

  final markierungen = <String, String>{};
  for (final eintrag in neu.entries) {
    final text = hinweis(eintrag.value);
    if (text != null) markierungen[eintrag.key] = text;
  }
  return markierungen;
});
