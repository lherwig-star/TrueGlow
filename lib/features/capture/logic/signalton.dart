import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Die Toene des Auto-Ausloesers.
///
/// Warum es sie ueberhaupt gibt: Der Countdown laeuft, waehrend der Nutzer
/// mehrere Meter vom Handy entfernt steht. Er sieht den Bildschirm dort nicht
/// gut genug, um mitzuzaehlen – ohne Ton wuesste er nicht, wann er stillhalten
/// muss und wann das Foto entstanden ist.
abstract interface class Signalton {
  /// Ein Zaehl-Ton, einer je verbleibender Sekunde.
  Future<void> zaehlen();

  /// Der Ausloese-Ton in dem Moment, in dem das Foto entsteht.
  Future<void> ausloesen();

  Future<void> entsorgen();
}

/// Spielt die generierten WAVs aus `assets/toene/`.
class EchterSignalton implements Signalton {
  EchterSignalton() {
    _spieler.setAudioContext(kontext());
    _spieler.setReleaseMode(ReleaseMode.stop);
  }

  /// Wie die Toene ausgegeben werden.
  ///
  /// Ueber den Benachrichtigungs-Kanal statt ueber Medien: Damit gilt fuer den
  /// Ton dieselbe Regel wie fuer eine Nachricht – im Lautlos-Modus schweigt er,
  /// ohne dass die App den Klingelzustand abfragen muss. Eine eigene Abfrage
  /// braeuchte ein weiteres Plugin und waere auf jedem Hersteller-Android
  /// wieder anders falsch.
  ///
  /// Auf iOS `ambient`: Diese Kategorie mischt sich von sich aus unter
  /// laufende Wiedergabe und folgt dem Klingelschalter – genau das, was drei
  /// kurze Toene brauchen. Hier stand zuvor zusaetzlich `mixWithOthers`, und
  /// **das war der Fehler hinter dem toten Auto-Ausloeser**: Die Option ist
  /// nur zu `playback`, `playAndRecord` und `multiRoute` erlaubt, sonst
  /// bricht `AudioContextIOS` mit einer Zusicherung ab. Der Ausloese-Ton
  /// laeuft eine Zeile vor der Aufnahme – die Ausnahme riss die Kette genau
  /// dort auseinander. Zu `ambient` gehoert das Mischen ohnehin dazu, die
  /// Option war also nicht nur unerlaubt, sondern auch ueberfluessig.
  ///
  /// Eine eigene Funktion, damit sich genau das ohne Audio-Ausgabe pruefen
  /// laesst – die Zusicherung schlaegt schon beim Bauen des Kontexts zu.
  @visibleForTesting
  static AudioContext kontext() => AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      );

  final AudioPlayer _spieler = AudioPlayer();

  @override
  Future<void> zaehlen() => _spiele('toene/countdown.wav');

  @override
  Future<void> ausloesen() => _spiele('toene/ausloesen.wav');

  Future<void> _spiele(String pfad) async {
    try {
      // Vor jedem Ton anhalten: Bei einem Ton pro Sekunde ueberholt sonst der
      // naechste den vorigen und es klingt nach Stottern.
      await _spieler.stop();
      await _spieler.play(AssetSource(pfad));
    } catch (e) {
      // Ein fehlender Ton ist kein Grund, die Aufnahme scheitern zu lassen –
      // der Countdown laeuft sichtbar weiter.
      debugPrint('Signalton nicht abspielbar: $e');
    }
  }

  @override
  Future<void> entsorgen() => _spieler.dispose();
}

/// Tut nichts – fuer Widget-Tests und fuer den Fall, dass der Nutzer den Ton
/// nicht bekommen soll (Lautlos wird zwar vom System geregelt, aber in Tests
/// gibt es keinen Audio-Kanal).
class StummerSignalton implements Signalton {
  const StummerSignalton();

  @override
  Future<void> zaehlen() async {}

  @override
  Future<void> ausloesen() async {}

  @override
  Future<void> entsorgen() async {}
}

final signaltonProvider = Provider<Signalton>((ref) {
  final ton = EchterSignalton();
  ref.onDispose(ton.entsorgen);
  return ton;
});
