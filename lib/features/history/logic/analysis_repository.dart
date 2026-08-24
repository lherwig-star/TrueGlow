import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../analysis/models/analysis_result.dart';

/// Lesen und Schreiben der Analysen. Gespeichert wird als JSON-String – damit
/// kommt genau das zurueck, was hineingeschrieben wurde, ohne Typ-Ueberraschungen
/// bei verschachtelten Maps.
class AnalysisRepository {
  AnalysisRepository(this._analysen, this._einstellungen);

  final KeyValueStore _analysen;
  final KeyValueStore _einstellungen;

  static const _schluesselAktuelle = 'aktuelleAnalyseId';

  Future<void> speichern(AnalysisResult ergebnis) async {
    await _analysen.put(ergebnis.id, jsonEncode(ergebnis.toJson()));
    await _einstellungen.put(_schluesselAktuelle, ergebnis.id);
  }

  AnalysisResult? laden(String id) => _lies(_analysen.get(id));

  /// Die zuletzt erstellte Analyse – Grundlage fuer Dashboard und Plan.
  AnalysisResult? aktuelle() {
    final id = _einstellungen.get(_schluesselAktuelle);
    if (id is String) {
      final gespeichert = laden(id);
      if (gespeichert != null) return gespeichert;
    }
    // Falls der Verweis ins Leere zeigt: die neueste Analyse nehmen.
    final alleAnalysen = alle();
    return alleAnalysen.isEmpty ? null : alleAnalysen.first;
  }

  /// Alle Analysen, neueste zuerst.
  List<AnalysisResult> alle() {
    final ergebnisse = _analysen.values
        .map(_lies)
        .whereType<AnalysisResult>()
        .toList();
    ergebnisse.sort((a, b) => b.erstelltAm.compareTo(a.erstelltAm));
    return ergebnisse;
  }

  Future<void> loeschen(String id) async {
    await _analysen.delete(id);
    if (_einstellungen.get(_schluesselAktuelle) == id) {
      await _einstellungen.delete(_schluesselAktuelle);
    }
  }

  AnalysisResult? _lies(dynamic wert) {
    if (wert is! String || wert.isEmpty) return null;
    try {
      final json = jsonDecode(wert);
      if (json is! Map) return null;
      return AnalysisResult.fromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      return null;
    }
  }
}

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepository(
    ref.watch(storeProvider(HiveService.boxAnalysen)),
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  );
});

/// Aktueller Stand der gespeicherten Analysen. Wird nach jeder Analyse und
/// nach dem Loeschen neu gelesen.
class AnalysenNotifier extends StateNotifier<List<AnalysisResult>> {
  AnalysenNotifier(this._repo) : super(_repo.alle());

  final AnalysisRepository _repo;

  AnalysisResult? get aktuelle => _repo.aktuelle();

  Future<void> speichern(AnalysisResult ergebnis) async {
    await _repo.speichern(ergebnis);
    state = _repo.alle();
  }

  Future<void> loeschen(String id) async {
    await _repo.loeschen(id);
    state = _repo.alle();
  }

  void neuLaden() => state = _repo.alle();
}

final analysenProvider =
    StateNotifierProvider<AnalysenNotifier, List<AnalysisResult>>(
  (ref) => AnalysenNotifier(ref.watch(analysisRepositoryProvider)),
);

/// Bequemer Zugriff auf die zuletzt erstellte Analyse.
final aktuelleAnalyseProvider = Provider<AnalysisResult?>((ref) {
  ref.watch(analysenProvider);
  return ref.watch(analysisRepositoryProvider).aktuelle();
});
