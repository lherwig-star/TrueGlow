import 'dart:async';

import 'package:flutter/foundation.dart';

/// Ein Abbruchwunsch des Nutzers.
///
/// Was hier abgebrochen wird, ist das **Warten und Wiederholen**, nicht der
/// laufende Aufruf: Eine bereits abgeschickte Anfrage an die Cloud Function
/// laesst sich nicht zurueckholen. Das ist ehrlicher, als eine Abbrechbarkeit
/// zu behaupten, die es nicht gibt — und es reicht: Der Nutzer wartet nicht
/// weiter, und ein zweiter Versuch auf seine Kosten unterbleibt.
class Abbruch {
  bool _ausgeloest = false;

  bool get istAusgeloest => _ausgeloest;

  void ausloesen() => _ausgeloest = true;
}

/// Wird geworfen, wenn der Nutzer abgebrochen hat.
class AbbruchException implements Exception {
  const AbbruchException();

  @override
  String toString() => 'AbbruchException';
}

/// Wiederholt einen Aufruf mit exponentiell wachsender Pause.
///
/// **Warum die Grenzen so eng sind:** Jeder Versuch gegen die Analyse-Function
/// kann serverseitig Kontingent buchen und Gemini-Tokens kosten. Eine
/// Wiederholung ist deshalb nur dort erlaubt, wo der Aufruf den Server
/// nachweislich **nicht erreicht** hat — das entscheidet [wiederholbar].
/// Alles andere fliegt sofort durch.
///
/// Drei Versuche, zwei Pausen (1 s, 2 s). Mehr waere die Kostenschleife, vor
/// der die Roadmap warnt.
Future<T> mitWiederholung<T>(
  Future<T> Function() aufruf, {
  required bool Function(Object fehler) wiederholbar,
  Abbruch? abbruch,
  int maxVersuche = 3,
  Duration grundpause = const Duration(seconds: 1),
}) async {
  for (var versuch = 1;; versuch++) {
    if (abbruch?.istAusgeloest ?? false) throw const AbbruchException();

    try {
      return await aufruf();
    } catch (fehler) {
      final letzter = versuch >= maxVersuche;
      if (letzter || !wiederholbar(fehler)) rethrow;

      final pause = grundpause * (1 << (versuch - 1));
      debugPrint(
        'Versuch $versuch von $maxVersuche fehlgeschlagen, '
        'neuer Versuch in ${pause.inMilliseconds} ms ($fehler)',
      );

      await _warte(pause, abbruch);
    }
  }
}

/// Wartet, prueft dabei aber regelmaessig auf einen Abbruch.
///
/// Ohne das kaeme ein Abbruch waehrend der Pause erst nach Ablauf an — bei
/// zwei Sekunden faellt das auf.
Future<void> _warte(Duration pause, Abbruch? abbruch) async {
  const takt = Duration(milliseconds: 100);
  var verstrichen = Duration.zero;

  while (verstrichen < pause) {
    if (abbruch?.istAusgeloest ?? false) throw const AbbruchException();
    final schritt = pause - verstrichen < takt ? pause - verstrichen : takt;
    await Future<void>.delayed(schritt);
    verstrichen += schritt;
  }

  if (abbruch?.istAusgeloest ?? false) throw const AbbruchException();
}
