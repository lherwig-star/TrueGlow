import 'package:camera/camera.dart';

/// Welche der vorhandenen Kameras eine Aufnahme benutzt – DECISIONS 71.
///
/// Der Anlass kam vom Geraet: Bei den Ganzkoerper- und Outfit-Aufnahmen
/// startete die Vorderkamera, obwohl `AufnahmeTyp.rueckkamera` dort seit
/// jeher `true` steht. Man stellt das Handy ab, tritt drei Meter zurueck –
/// und sieht sich selbst nicht, weil die Kamera in die falsche Richtung
/// schaut.
///
/// Vorher stand die Auswahl als `firstWhere(..., orElse: () => erste)` im
/// Kamerabildschirm. Diese Zeile hat einen stillen Ausgang: Findet sie die
/// gewuenschte Richtung nicht, nimmt sie die **erste** Kamera der Liste –
/// und die ist auf vielen Geraeten die Selfie-Kamera. Ein Geraet, das seine
/// Rueckkamera nicht als `back` meldet (es gibt sie als `external`), landet
/// damit genau im beobachteten Fehler.
///
/// Deshalb steht die Wahl jetzt hier, als gewoehnliche Funktion mit Tests:
/// Am Geraet laesst sie sich nur mit dem Geraet pruefen, hier mit jeder
/// denkbaren Kameraliste.
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
