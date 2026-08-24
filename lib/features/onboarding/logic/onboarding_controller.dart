import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../models/onboarding_profile.dart';

/// Haelt die Onboarding-Antworten und schreibt jede Aenderung sofort nach
/// Hive – so ueberlebt der Stand auch einen Absturz mitten im Flow.
class OnboardingController extends StateNotifier<OnboardingProfile> {
  OnboardingController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const _schluessel = 'onboarding';

  static OnboardingProfile _lade(KeyValueStore box) {
    final wert = box.get(_schluessel);
    if (wert is! String || wert.isEmpty) return const OnboardingProfile();
    try {
      final json = jsonDecode(wert);
      if (json is! Map) return const OnboardingProfile();
      return OnboardingProfile.fromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      return const OnboardingProfile();
    }
  }

  void _setze(OnboardingProfile neu) {
    state = neu;
    _box.put(_schluessel, jsonEncode(neu.toJson()));
  }

  void setAlter(Altersbereich wert) => _setze(state.copyWith(alter: wert));
  void setBudget(Budget wert) => _setze(state.copyWith(budget: wert));
  void setZeit(Zeitbudget wert) => _setze(state.copyWith(zeit: wert));
  void setZustimmung(bool wert) => _setze(state.copyWith(zugestimmt: wert));

  void toggleFokus(Fokusbereich wert) {
    final neu = Set<Fokusbereich>.from(state.fokus);
    neu.contains(wert) ? neu.remove(wert) : neu.add(wert);
    _setze(state.copyWith(fokus: neu));
  }

  void abschliessen() => _setze(state.copyWith(abgeschlossen: true));

  /// Setzt die Antworten zurueck, damit das Onboarding erneut durchlaufen wird.
  void zuruecksetzen() => _setze(const OnboardingProfile());

  /// Liest den Stand neu ein – gebraucht, nachdem der Sync am Controller
  /// vorbei in den Speicher geschrieben hat.
  void neuLaden() => state = _lade(_box);
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingProfile>(
  (ref) => OnboardingController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
