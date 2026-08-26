import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../capture/logic/capture_controller.dart';
import '../../history/logic/analysis_repository.dart';
import 'checkin_controller.dart';

/// Ein Foto im Fortschritts-Tagebuch.
///
/// Die Fotos liegen ausschliesslich im privaten Verzeichnis der App. Sie
/// gehen nicht in die Galerie, nicht an die Analyse-API und nicht nach
/// Firebase – siehe DECISIONS 48.
@immutable
class Fotoeintrag {
  const Fotoeintrag({
    required this.datum,
    required this.pfad,
    this.checkinId,
  });

  final DateTime datum;
  final String pfad;

  /// Der Check-in, zu dem das Foto gehoert. `null` beim Startfoto aus der
  /// Analyse – das gehoert dem Report und wird hier nicht geloescht.
  final int? checkinId;

  bool get istStart => checkinId == null;

  /// Ob die Datei auf diesem Geraet liegt. Nach einem Geraetewechsel steht
  /// der Eintrag noch da (der Check-in kommt aus der Cloud), das Bild nicht.
  bool get vorhanden => File(pfad).existsSync();

  @override
  bool operator ==(Object other) =>
      other is Fotoeintrag &&
      other.pfad == pfad &&
      other.datum == datum &&
      other.checkinId == checkinId;

  @override
  int get hashCode => Object.hash(pfad, datum, checkinId);
}

/// Das Tagebuch in zeitlicher Reihenfolge, aeltestes zuerst.
///
/// Zusammengesetzt aus dem Frontalfoto der Analyse (der Startpunkt) und den
/// Fotos der abgeschlossenen Check-ins. Ein eigener Speicher waere ein
/// zweiter Ort fuer dieselben Daten – die Check-ins halten ihre Fotos
/// ohnehin schon fest.
final fortschrittsAlbumProvider = Provider<List<Fotoeintrag>>((ref) {
  final eintraege = <Fotoeintrag>[];

  final analyse = ref.watch(aktuelleAnalyseProvider);
  final start =
      ref.watch(captureControllerProvider).foto(CheckinController.fortschrittsTyp);
  if (analyse != null && start != null) {
    eintraege.add(
      Fotoeintrag(datum: analyse.erstelltAm, pfad: start.pfad),
    );
  }

  for (final checkin in ref.watch(checkinControllerProvider).historie) {
    final pfad = checkin.fortschrittsfoto;
    if (pfad == null || pfad.isEmpty) continue;
    eintraege.add(
      Fotoeintrag(
        datum: checkin.erledigtAm ?? checkin.faelligAm,
        pfad: pfad,
        checkinId: checkin.id,
      ),
    );
  }

  eintraege.sort((a, b) => a.datum.compareTo(b.datum));
  return eintraege;
});

/// Nur die Eintraege, deren Bild wirklich auf diesem Geraet liegt.
final vorhandeneFotosProvider = Provider<List<Fotoeintrag>>(
  (ref) => ref.watch(fortschrittsAlbumProvider).where((e) => e.vorhanden).toList(),
);

/// Loescht ein einzelnes Foto: erst die Datei, dann den Verweis im Check-in.
///
/// Reihenfolge mit Absicht: Bliebe der Verweis stehen, waehrend die Datei
/// weg ist, zeigte das Album einen Platzhalter, den niemand mehr wegbekommt.
Future<void> fotoLoeschen(WidgetRef ref, Fotoeintrag eintrag) async {
  if (eintrag.istStart) return;

  try {
    final datei = File(eintrag.pfad);
    if (datei.existsSync()) await datei.delete();
  } catch (e) {
    debugPrint('Fortschrittsfoto nicht loeschbar: $e');
  }

  await ref
      .read(checkinControllerProvider.notifier)
      .fortschrittsfotoEntfernen(eintrag.checkinId!);
}
