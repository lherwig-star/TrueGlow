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

  group('Wer mit der Rueckkamera startet', () {
    test('sind genau die Aufnahmen, fuer die man zuruecktritt', () {
      // Ganzkoerper und Outfit: Dort steht das Handy und der Nutzer mehrere
      // Meter davor. Bei den Portraits haelt man es in der Hand und schaut
      // hinein – dort ist die vordere richtig.
      final hinten =
          AufnahmeTyp.values.where((t) => t.rueckkamera).toSet();

      expect(hinten, {
        AufnahmeTyp.figurGanzkoerperFrontal,
        AufnahmeTyp.figurGanzkoerperSeitlich,
        AufnahmeTyp.stilOutfitEins,
        AufnahmeTyp.stilOutfitZwei,
        AufnahmeTyp.stilOutfitDrei,
      });
    });

    test('und das ist dieselbe Gruppe, die selbst ausloest', () {
      // Kein Zufall, sondern derselbe Grund: Wer drei Meter entfernt steht,
      // erreicht weder den Ausloeser noch die richtige Linse.
      for (final typ in AufnahmeTyp.values) {
        expect(typ.rueckkamera, typ.autoAusloeser, reason: typ.name);
      }
    });
  });
}
