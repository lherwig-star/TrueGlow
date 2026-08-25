import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_service.dart';
import '../storage/key_value_store.dart';
import '../l10n/texte.dart';

/// Auswahl im Einstellungspunkt "Erscheinungsbild".
enum Erscheinungsbild {
  hell(Icons.light_mode_outlined, ThemeMode.light),
  dunkel(Icons.dark_mode_outlined, ThemeMode.dark),
  system(Icons.brightness_auto_outlined, ThemeMode.system);

  const Erscheinungsbild(this.icon, this.modus);

  final IconData icon;
  final ThemeMode modus;
}

// Anzeigetexte als Erweiterung – Begruendung in
// `features/onboarding/models/onboarding_profile.dart`.
extension ErscheinungsbildText on Erscheinungsbild {
  String label(L texte) => switch (this) {
        Erscheinungsbild.hell => texte.erscheinungHell,
        Erscheinungsbild.dunkel => texte.erscheinungDunkel,
        Erscheinungsbild.system => texte.erscheinungSystem,
      };
}

/// Haelt die Theme-Auswahl und schreibt sie in denselben Speicher wie die
/// uebrigen Einstellungen, damit sie einen Neustart ueberlebt.
class ThemeController extends StateNotifier<Erscheinungsbild> {
  ThemeController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const _schluessel = 'erscheinungsbild';

  /// Standard ist das dunkle Schema.
  static const standard = Erscheinungsbild.dunkel;

  static Erscheinungsbild _lade(KeyValueStore box) {
    final wert = box.get(_schluessel);
    if (wert is! String) return standard;
    return Erscheinungsbild.values
        .where((e) => e.name == wert)
        .firstOrNull ??
        standard;
  }

  void setzen(Erscheinungsbild wahl) {
    if (wahl == state) return;
    state = wahl;
    _box.put(_schluessel, wahl.name);
  }

  /// Nach dem Loeschen aller Daten steht nichts mehr im Speicher – dann faellt
  /// die App auf den Standard zurueck.
  void neuLaden() => state = _lade(_box);
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, Erscheinungsbild>(
  (ref) => ThemeController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
