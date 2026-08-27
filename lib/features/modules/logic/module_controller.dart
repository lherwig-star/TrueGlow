import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../models/analyse_modul.dart';
import '../models/modul_eingaben.dart';

/// Getroffene Modulauswahl plus die Zusatzangaben der Module.
class ModulZustand {
  const ModulZustand({required this.module, required this.eingaben});

  /// Enthaelt immer [AnalyseModul.basis].
  final Set<AnalyseModul> module;
  final ModulEingaben eingaben;

  /// Module, die noch nicht Teil der Analyse sind – die Grundlage fuer
  /// "Analyse erweitern" auf dem Ergebnis-Screen.
  List<AnalyseModul> get offene =>
      AnalyseModul.waehlbare.where((m) => !module.contains(m)).toList();

  /// Zaehler fuer die Beschriftung des Startbuttons.
  int get anzahlZusatzModule => module.where((m) => !m.istBasis).length;

  bool enthaelt(AnalyseModul modul) => module.contains(modul);

  ModulZustand copyWith({
    Set<AnalyseModul>? module,
    ModulEingaben? eingaben,
  }) =>
      ModulZustand(
        module: module ?? this.module,
        eingaben: eingaben ?? this.eingaben,
      );

  static const leer = ModulZustand(
    module: {AnalyseModul.basis},
    eingaben: ModulEingaben(),
  );
}

/// Haelt die Modulauswahl und schreibt jede Aenderung sofort weg – der Flow
/// dahinter kann lang sein, ein Absturz soll die Auswahl nicht kosten.
class ModuleController extends StateNotifier<ModulZustand> {
  ModuleController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const _schluesselModule = 'analyseModule';
  static const _schluesselEingaben = 'modulEingaben';

  static ModulZustand _lade(KeyValueStore box) {
    final rohModule = box.get(_schluesselModule);
    final module = rohModule is List
        ? AnalyseModul.ausNamen(rohModule)
        : {AnalyseModul.basis};

    var eingaben = const ModulEingaben();
    final rohEingaben = box.get(_schluesselEingaben);
    if (rohEingaben is String && rohEingaben.isNotEmpty) {
      try {
        final json = jsonDecode(rohEingaben);
        if (json is Map) {
          eingaben = ModulEingaben.fromJson(Map<String, dynamic>.from(json));
        }
      } on FormatException {
        // Kaputter Eintrag: lieber leere Angaben als ein Absturz beim Start.
      }
    }

    return ModulZustand(module: module, eingaben: eingaben);
  }

  void umschalten(AnalyseModul modul) {
    // Die Basis ist nicht abwaehlbar.
    if (modul.istBasis) return;

    final neu = Set<AnalyseModul>.from(state.module);
    neu.contains(modul) ? neu.remove(modul) : neu.add(modul);
    _setzeModule(neu);
  }

  /// Nimmt ein Modul nachtraeglich dazu (Weg ueber "Analyse erweitern").
  void ergaenzen(AnalyseModul modul) {
    if (state.module.contains(modul)) return;
    _setzeModule({...state.module, modul});
  }

  void setzeFigur(FigurAngaben angaben) =>
      _setzeEingaben(state.eingaben.copyWith(figur: angaben));

  void setzeStil(StilAngaben angaben) =>
      _setzeEingaben(state.eingaben.copyWith(stil: angaben));

  /// Zuruecksetzen auf die reine Basis-Auswahl.
  void zuruecksetzen() => vorbereiten(const {});

  /// Setzt zurueck und waehlt [vorauswahl] gleich mit an.
  ///
  /// Das ist der Weg, auf dem die Schwerpunkte aus dem Onboarding wirken
  /// (DECISIONS 60): Wer dort „Haut" angekreuzt hat, findet „Haut & Farbtyp"
  /// beim naechsten Zusammenstellen bereits ausgewaehlt vor – und kann es
  /// mit einem Tipp wieder abwaehlen. Das Onboarding spart damit
  /// Tipparbeit, statt dieselbe Frage ein zweites Mal zu stellen.
  ///
  /// Die Zusatzangaben (Figur, Stil) werden trotzdem geleert: Sie gehoeren
  /// zum vorigen Durchlauf, nicht zur Vorauswahl.
  void vorbereiten(Set<AnalyseModul> vorauswahl) {
    _box.delete(_schluesselEingaben);
    state = ModulZustand.leer;
    if (vorauswahl.isEmpty) {
      _box.delete(_schluesselModule);
      return;
    }
    _setzeModule(vorauswahl);
  }

  void neuLaden() => state = _lade(_box);

  void _setzeModule(Set<AnalyseModul> module) {
    state = state.copyWith(module: {AnalyseModul.basis, ...module});
    _box.put(
      _schluesselModule,
      state.module.map((m) => m.name).toList(),
    );
  }

  void _setzeEingaben(ModulEingaben eingaben) {
    state = state.copyWith(eingaben: eingaben);
    _box.put(_schluesselEingaben, jsonEncode(eingaben.toJson()));
  }
}

final moduleControllerProvider =
    StateNotifierProvider<ModuleController, ModulZustand>(
  (ref) => ModuleController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
