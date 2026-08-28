import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/capture/logic/kamerawahl.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';

/// Welche Kamera eine Aufnahme startet – DECISIONS 71.
///
/// Der Anlass kam vom Geraet: Bei den Ganzkoerper- und Outfit-Aufnahmen kam
/// die Selfie-Kamera hoch, obwohl `rueckkamera` dort seit jeher `true` steht.
/// Man stellt das Handy ab, tritt drei Meter zurueck – und die Kamera schaut
/// in die falsche Richtung.
CameraDescription _kamera(CameraLensDirection richtung, [String name = '']) =>
    CameraDescription(
      name: name.isEmpty ? richtung.name : name,
      lensDirection: richtung,
      sensorOrientation: 90,
    );

final _vorn = _kamera(CameraLensDirection.front);
final _hinten = _kamera(CameraLensDirection.back);
final _fremd = _kamera(CameraLensDirection.external);

void main() {
  group('waehleKamera', () {
    test('nimmt die gewuenschte Richtung, egal an welcher Stelle', () {
      // Die Reihenfolge von `availableCameras()` haengt am Geraet. Auf
      // manchen steht vorn zuerst.
      for (final liste in [
        [_hinten, _vorn],
        [_vorn, _hinten],
        [_vorn, _fremd, _hinten],
      ]) {
        expect(
          waehleKamera(liste, CameraLensDirection.back)?.lensDirection,
          CameraLensDirection.back,
          reason: liste.map((k) => k.lensDirection.name).join(','),
        );
      }
    });

    test('und ebenso fuer vorn', () {
      expect(
        waehleKamera([_hinten, _vorn], CameraLensDirection.front)
            ?.lensDirection,
        CameraLensDirection.front,
      );
    });

    test('faellt NIE in die Selfie-Kamera, wenn hinten gefragt war', () {
      // Genau hier lag der Fehler: Die alte Zeile nahm bei fehlendem
      // Treffer die erste Kamera der Liste – und die ist oft die vordere.
      // Ein Geraet, das seine Rueckkamera als "external" meldet, landete
      // damit in der Selfie-Kamera.
      final gewaehlt = waehleKamera(
        [_vorn, _fremd],
        CameraLensDirection.back,
      );

      expect(gewaehlt?.lensDirection, CameraLensDirection.external);
    });

    test('nimmt lieber das Gegenteil als gar nichts', () {
      // Ein Geraet ohne Rueckkamera gibt es – ein Tablet etwa. Dann ist eine
      // Kamera besser als keine; der Wechsel-Knopf steht daneben.
      expect(
        waehleKamera([_vorn], CameraLensDirection.back)?.lensDirection,
        CameraLensDirection.front,
      );
    });

    test('ohne Kamera gibt es keine Wahl', () {
      expect(waehleKamera(const [], CameraLensDirection.back), isNull);
    });
  });

  group('Alle Aufnahmen starten auf der Bildschirm-Seite', () {
    test('keine Aufnahme bringt mehr eine eigene Richtung mit', () {
      // Es gibt kein `rueckkamera` mehr (DECISIONS 75): Jede Aufnahme
      // startet vorn, auch die Ganzkoerper- und Outfit-Fotos. Man stellt das
      // Handy auf, stellt sich davor und sieht sich selbst.
      //
      // Geprueft am Quelltext, weil die Startrichtung im Kamerabildschirm
      // privat ist – und weil genau dieses Feld zweimal fuer eine falsche
      // Voreinstellung gesorgt hat.
      final quellen = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final datei in quellen) {
        expect(
          datei.readAsStringSync(),
          isNot(contains('rueckkamera')),
          reason: datei.path,
        );
      }
    });

    test('und der Sucher startet mit der vorderen Linse', () {
      final quelle = File('lib/features/capture/ui/camera_screen.dart')
          .readAsStringSync();

      expect(
        quelle,
        contains('CameraLensDirection _richtung = CameraLensDirection.front'),
      );
    });

    test('und die Wahl liefert dafuer die vordere Linse', () {
      expect(
        waehleKamera(
          [_hinten, _vorn, _fremd],
          CameraLensDirection.front,
        )?.lensDirection,
        CameraLensDirection.front,
      );
    });
  });
}
