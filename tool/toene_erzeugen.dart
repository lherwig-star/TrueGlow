// Erzeugt die Signaltoene des Auto-Ausloesers als WAV.
//
//   dart run tool/toene_erzeugen.dart
//
// Wie beim Markenauftritt (`tool/marke_erzeugen.dart`) sind die Assets
// generiert und nicht von Hand gebaut: Die Werte stehen hier, nicht in einer
// Binaerdatei, die niemand mehr aendern kann. Wer die Toene anpassen will,
// dreht an den Konstanten und laesst das Skript neu laufen.
//
// Warum ueberhaupt eigene Toene: Der Countdown laeuft, waehrend der Nutzer
// mehrere Meter vom Handy entfernt steht. Ein Systemklick ist dort nicht zu
// hoeren, und die Tonhoehe soll die letzte Sekunde von den ersten
// unterscheiden, ohne dass man hinsehen muss.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// 44,1 kHz, 16 Bit, Mono – mehr braucht ein Sinuston nicht.
const int _abtastrate = 44100;

void main() {
  final ordner = Directory('assets/toene')..createSync(recursive: true);

  // Die drei Zaehl-Toene: kurz und mittelhoch, gut hoerbar ohne aufdringlich
  // zu sein.
  _schreibe(
    File('${ordner.path}/countdown.wav'),
    _sinus(frequenz: 880, dauer: const Duration(milliseconds: 120)),
  );

  // Der Ausloese-Ton: hoeher und laenger, damit unverwechselbar ist, wann das
  // Foto entstanden ist. Aus drei Metern ist das die einzige Rueckmeldung.
  _schreibe(
    File('${ordner.path}/ausloesen.wav'),
    _sinus(frequenz: 1320, dauer: const Duration(milliseconds: 220)),
  );

  stdout.writeln('✓ assets/toene/countdown.wav');
  stdout.writeln('✓ assets/toene/ausloesen.wav');
}

/// Ein Sinuston mit weichen Flanken.
///
/// Die Ein- und Ausblendung ueber je fuenf Millisekunden ist nicht Kosmetik:
/// Ein hart abgeschnittener Sinus knackt hoerbar, und bei drei Toenen
/// hintereinander klingt das nach kaputtem Lautsprecher.
Int16List _sinus({required double frequenz, required Duration dauer}) {
  final anzahl = (_abtastrate * dauer.inMilliseconds / 1000).round();
  final flanke = (_abtastrate * 0.005).round();
  final daten = Int16List(anzahl);

  for (var i = 0; i < anzahl; i++) {
    final wert = math.sin(2 * math.pi * frequenz * i / _abtastrate);

    // Dreiecksfoermige Huellkurve an den Raendern.
    var lautstaerke = 1.0;
    if (i < flanke) {
      lautstaerke = i / flanke;
    } else if (i > anzahl - flanke) {
      lautstaerke = (anzahl - i) / flanke;
    }

    // 0.6 statt Vollaussteuerung: laut genug fuer drei Meter, ohne zu
    // uebersteuern, wenn das Geraet ohnehin auf Anschlag steht.
    daten[i] = (wert * lautstaerke * 0.6 * 32767).round();
  }

  return daten;
}

/// Schreibt die Rohdaten als WAV (PCM, 16 Bit, Mono).
void _schreibe(File datei, Int16List daten) {
  final nutzdaten = daten.buffer.asUint8List();
  final kopf = BytesBuilder();

  void text(String s) => kopf.add(s.codeUnits);
  void wort32(int wert) => kopf.add(
        Uint8List(4)..buffer.asByteData().setUint32(0, wert, Endian.little),
      );
  void wort16(int wert) => kopf.add(
        Uint8List(2)..buffer.asByteData().setUint16(0, wert, Endian.little),
      );

  text('RIFF');
  wort32(36 + nutzdaten.length);
  text('WAVE');
  text('fmt ');
  wort32(16); // Laenge des fmt-Blocks
  wort16(1); // PCM, unkomprimiert
  wort16(1); // Mono
  wort32(_abtastrate);
  wort32(_abtastrate * 2); // Bytes pro Sekunde
  wort16(2); // Blockausrichtung
  wort16(16); // Bit je Abtastwert
  text('data');
  wort32(nutzdaten.length);

  datei.writeAsBytesSync([...kopf.takeBytes(), ...nutzdaten]);
}
