import 'package:camera/camera.dart';

/// Welche der vorhandenen Kameras eine Aufnahme benutzt.
///
/// Alle Aufnahmen starten auf der Bildschirm-Seite (DECISIONS 75); diese
/// Funktion sucht die passende Linse heraus. Sie stammt aus DECISIONS 71 und
/// bleibt aus dem Grund, aus dem sie geschrieben wurde: Vorher stand die
/// Auswahl als `firstWhere(..., orElse: () => erste)` im Kamerabildschirm,
/// und diese Zeile hat einen stillen Ausgang – findet sie die gewuenschte
/// Richtung nicht, nimmt sie die **erste** Kamera der Liste. Auf einem
/// Geraet, das seine Linsen anders meldet, landet man damit garantiert im
/// Gegenteil.
///
/// Als gewoehnliche Funktion laesst sich das mit jeder denkbaren
/// Kameraliste pruefen; am Geraet ginge es nur mit dem Geraet.
CameraDescription? waehleKamera(
  List<CameraDescription> kameras,
  CameraLensDirection wunsch,
) {
  if (kameras.isEmpty) return null;

  // 1. Der Normalfall: Es gibt genau das, was gefragt war.
  for (final kamera in kameras) {
    if (kamera.lensDirection == wunsch) return kamera;
  }

  // 2. Kein Treffer. Entscheidend ist jetzt nur eins: nicht ins Gegenteil
  //    fallen. Wer nach hinten gefragt hat, bekommt lieber eine Kamera
  //    unbekannter Bauart als die Selfie-Kamera – die zeigt garantiert das
  //    Falsche.
  final gegenteil = wunsch == CameraLensDirection.front
      ? CameraLensDirection.back
      : CameraLensDirection.front;

  for (final kamera in kameras) {
    if (kamera.lensDirection != gegenteil) return kamera;
  }

  // 3. Es gibt nur das Gegenteil. Dann ist eine Kamera besser als keine –
  //    aufnehmen laesst sich damit immer noch, und der Wechsel-Knopf steht
  //    daneben.
  return kameras.first;
}
