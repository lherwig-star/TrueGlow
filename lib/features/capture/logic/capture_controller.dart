import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../models/aufnahme_typ.dart';
import '../models/captured_photo.dart';
import '../models/photo_check_result.dart';
import 'image_quality_service.dart';

/// Zustand des Foto-Flows.
///
/// Die Aufnahmen liegen in einer Map statt in festen Feldern, weil der Flow
/// nicht mehr fest zwei Bilder umfasst, sondern sich aus den gewaehlten
/// Modulen ergibt.
class CaptureState {
  const CaptureState({
    this.fotos = const {},
    this.laeuft = false,
    this.problem,
  });

  final Map<AufnahmeTyp, CapturedPhoto> fotos;
  final bool laeuft;
  final PhotoProblem? problem;

  CapturedPhoto? foto(AufnahmeTyp typ) => fotos[typ];

  bool hat(AufnahmeTyp typ) => fotos.containsKey(typ);

  /// Ob alle Pflichtaufnahmen vorliegen.
  bool vollstaendig(Set<AufnahmeTyp> pflicht) => pflicht.every(hat);

  /// Wie viele der angefragten Aufnahmen schon stehen.
  int anzahlVon(Set<AufnahmeTyp> typen) => typen.where(hat).length;

  CaptureState copyWith({
    Map<AufnahmeTyp, CapturedPhoto>? fotos,
    bool? laeuft,
    PhotoProblem? problem,
    bool problemLoeschen = false,
  }) {
    return CaptureState(
      fotos: fotos ?? this.fotos,
      laeuft: laeuft ?? this.laeuft,
      problem: problemLoeschen ? null : (problem ?? this.problem),
    );
  }
}

class CaptureController extends StateNotifier<CaptureState> {
  CaptureController(this._service, this._box) : super(_lade(_box));

  final ImageQualityService _service;
  final KeyValueStore _box;
  final ImagePicker _picker = ImagePicker();

  static const _schluessel = 'aufnahmen';

  /// Bereits gemachte Aufnahmen wiederherstellen. Das ist die Grundlage
  /// dafuer, dass ein nachtraeglich ergaenztes Modul die Basis-Fotos
  /// weiterverwenden kann, statt sie neu zu verlangen.
  static CaptureState _lade(KeyValueStore box) {
    final roh = box.get(_schluessel);
    if (roh is! String || roh.isEmpty) return const CaptureState();

    try {
      final json = jsonDecode(roh);
      if (json is! List) return const CaptureState();

      final fotos = <AufnahmeTyp, CapturedPhoto>{};
      for (final eintrag in json.whereType<Map>()) {
        final foto =
            CapturedPhoto.fromJson(Map<String, dynamic>.from(eintrag));
        // Datei kann zwischenzeitlich geloescht worden sein.
        if (foto != null && File(foto.pfad).existsSync()) {
          fotos[foto.typ] = foto;
        }
      }
      return CaptureState(fotos: fotos);
    } on FormatException {
      return const CaptureState();
    }
  }

  /// Foto aus der Galerie waehlen und direkt pruefen.
  Future<bool> ausGalerie(AufnahmeTyp typ) async {
    if (state.laeuft) return false;

    state = state.copyWith(laeuft: true, problemLoeschen: true);

    try {
      final auswahl = await _picker.pickImage(
        source: ImageSource.gallery,
        // Vorab begrenzen: schont Speicher beim Dekodieren, die
        // Flaechenverhaeltnisse fuer den Check bleiben unveraendert.
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (auswahl == null) {
        state = state.copyWith(laeuft: false);
        return false;
      }

      return await _pruefen(typ, File(auswahl.path));
    } catch (_) {
      state = state.copyWith(
        laeuft: false,
        problem: PhotoProblem.fehlgeschlagen,
      );
      return false;
    }
  }

  /// Aufnahme aus der In-App-Kamera uebernehmen. Durchlaeuft denselben
  /// Qualitaetscheck wie der Galerie-Import.
  Future<bool> uebernehmen(AufnahmeTyp typ, File datei) async {
    if (state.laeuft) return false;

    state = state.copyWith(laeuft: true, problemLoeschen: true);

    try {
      return await _pruefen(typ, datei);
    } catch (_) {
      state = state.copyWith(
        laeuft: false,
        problem: PhotoProblem.fehlgeschlagen,
      );
      return false;
    }
  }

  /// Gemeinsamer Pruefpfad beider Quellen.
  Future<bool> _pruefen(AufnahmeTyp typ, File datei) async {
    final ergebnis = await _service.pruefeUndVerarbeite(datei: datei, typ: typ);

    switch (ergebnis) {
      case PhotoCheckOk(:final foto):
        state = state.copyWith(
          fotos: {...state.fotos, typ: foto},
          laeuft: false,
        );
        _sichern();
        return true;
      case PhotoCheckFehler(:final problem):
        state = state.copyWith(laeuft: false, problem: problem);
        return false;
    }
  }

  /// Einzelne Aufnahme verwerfen, um sie neu zu machen.
  void verwerfen(AufnahmeTyp typ) {
    final fotos = Map<AufnahmeTyp, CapturedPhoto>.from(state.fotos)
      ..remove(typ);
    state = state.copyWith(fotos: fotos, problemLoeschen: true);
    _sichern();
  }

  void problemVerwerfen() => state = state.copyWith(problemLoeschen: true);

  /// Alles zuruecksetzen – etwa vor einer komplett neuen Analyse.
  void alleVerwerfen() {
    state = const CaptureState();
    _box.delete(_schluessel);
  }

  void neuLaden() => state = _lade(_box);

  void _sichern() {
    _box.put(
      _schluessel,
      jsonEncode(state.fotos.values.map((f) => f.toJson()).toList()),
    );
  }

  /// Nur fuer Tests: der echte Weg fuehrt immer ueber Kamera oder Galerie,
  /// die beide ohne Geraet nicht laufen.
  @visibleForTesting
  void setzeZustand(CaptureState zustand) => state = zustand;
}

final imageQualityServiceProvider = Provider<ImageQualityService>((ref) {
  final service = ImageQualityService();
  // Der ML-Kit-Detector haelt native Ressourcen – sauber schliessen.
  ref.onDispose(service.dispose);
  return service;
});

final captureControllerProvider =
    StateNotifierProvider<CaptureController, CaptureState>(
  (ref) => CaptureController(
    ref.watch(imageQualityServiceProvider),
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
