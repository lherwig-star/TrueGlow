import 'package:flutter/foundation.dart';

/// Phase des Auto-Ausloesers.
enum AutoPhase {
  /// Wartet auf eine brauchbare Haltung.
  warten,

  /// Countdown laeuft.
  zaehlt,

  /// Ausgeloest – bis zum Zuruecksetzen passiert nichts mehr.
  ausgeloest,
}

/// Was der Sucher gerade anzeigen soll.
@immutable
class AutoZustand {
  const AutoZustand(this.phase, [this.verbleibend = 0]);

  final AutoPhase phase;

  /// Verbleibende volle Sekunden, nur in [AutoPhase.zaehlt] von Bedeutung.
  final int verbleibend;

  @override
  bool operator ==(Object other) =>
      other is AutoZustand &&
      other.phase == phase &&
      other.verbleibend == verbleibend;

  @override
  int get hashCode => Object.hash(phase, verbleibend);

  @override
  String toString() => 'AutoZustand(${phase.name}, $verbleibend)';
}

/// Countdown fuer die Ganzkoerper-Aufnahme.
///
/// Warum es diese Klasse gibt: Wer sein Handy aufstellt und drei Meter
/// zuruecktritt, kann nicht ausloesen. Die App muss selbst erkennen, wann er
/// steht, und ihm vorher sagen, wie lange er noch stillhalten muss.
///
/// Bewusst ohne Timer und ohne Kamera: Die Uhrzeit kommt von aussen herein.
/// So laeuft die gesamte Ablauflogik in gewoehnlichen Tests, in denen die Zeit
/// einfach weitergesetzt wird – ein Auto-Ausloeser, der zur falschen Zeit
/// schiesst, faellt sonst erst am Geraet auf, und dort steht man drei Meter
/// entfernt und sieht nichts.
class AutoAusloeser {
  AutoAusloeser({
    this.sekunden = 3,
    this.nachsicht = const Duration(milliseconds: 700),
  }) : assert(sekunden > 0, 'Ein Countdown ohne Sekunden ist kein Countdown');

  /// Dauer des Countdowns.
  final int sekunden;

  /// Wie lange eine verlorene Haltung toleriert wird, bevor abgebrochen wird.
  ///
  /// Ohne diese Nachsicht bricht der Countdown staendig ab: Die Posenerkennung
  /// flackert, ein einzelner Frame ohne sichere Knoechel genuegt. Wer ruhig
  /// steht, soll nicht dafuer bestraft werden, dass das Modell kurz zweifelt.
  final Duration nachsicht;

  AutoPhase _phase = AutoPhase.warten;
  DateTime? _begonnen;
  DateTime? _schlechtSeit;

  AutoPhase get phase => _phase;

  /// Meldet das Ergebnis eines Frames und liefert den neuen Zustand.
  ///
  /// [bereit] ist die Haltungsbewertung, [jetzt] der Zeitpunkt des Frames.
  AutoZustand melde({required bool bereit, required DateTime jetzt}) {
    if (_phase == AutoPhase.ausgeloest) {
      return const AutoZustand(AutoPhase.ausgeloest);
    }

    if (!bereit) return _haltungVerloren(jetzt);

    _schlechtSeit = null;

    _begonnen ??= jetzt;
    if (_phase == AutoPhase.warten) _phase = AutoPhase.zaehlt;

    return _abgelaufen(jetzt) ?? AutoZustand(AutoPhase.zaehlt, _verbleibend(jetzt));
  }

  /// Verbleibende volle Sekunden seit dem Start des Countdowns.
  ///
  /// Aufrunden: Von 0 bis 999 ms nach dem Start sollen noch „3" stehen.
  /// Abgerundet spraenge die Anzeige sofort auf 2 und der Countdown fuehlte
  /// sich um eine Sekunde zu kurz an.
  int _verbleibend(DateTime jetzt) {
    final vergangen = jetzt.difference(_begonnen!);
    return sekunden - (vergangen.inMilliseconds / 1000).floor();
  }

  /// Loest aus, wenn die Zeit um ist – sonst `null`.
  ///
  /// Ein gemeinsamer Weg fuer beide Zweige: Ob die Haltung im letzten Frame
  /// sass oder gerade flackerte, darf ueber das Ausloesen nicht entscheiden.
  AutoZustand? _abgelaufen(DateTime jetzt) {
    if (_verbleibend(jetzt) > 0) return null;
    _phase = AutoPhase.ausgeloest;
    return const AutoZustand(AutoPhase.ausgeloest);
  }

  AutoZustand _haltungVerloren(DateTime jetzt) {
    if (_phase != AutoPhase.zaehlt) {
      _begonnen = null;
      return const AutoZustand(AutoPhase.warten);
    }

    final seit = _schlechtSeit ??= jetzt;
    if (jetzt.difference(seit) < nachsicht) {
      // Noch in der Nachsicht: Countdown laeuft weiter, damit das Flackern der
      // Erkennung nicht als Zappeln beim Nutzer ankommt.
      //
      // Und er laeuft wirklich weiter – bis zum Ausloesen. Hier stand zuvor
      // ein `clamp(1, sekunden)`: Lief die Zeit waehrend eines Flackerns ab,
      // blieb die Anzeige auf „1" stehen und es wurde nie ausgeloest. Nach
      // 700 ms fiel alles auf „warten" zurueck und der Countdown begann von
      // vorn. Am Geraet sah das aus wie „zaehlt 3-2-1 und macht dann nichts".
      //
      // Der Widerspruch war die Nachsicht selbst: Wer dem Nutzer zutraut,
      // dass er trotz eines Aussetzers noch steht, muss ihm auch zutrauen,
      // dass er im Bild steht, wenn die Zeit um ist. Ein leicht unsauberes
      // Foto ist danach ueber „Nochmal" in zwei Sekunden erledigt – ein nie
      // ausgeloestes kostet den Weg zurueck ans Handy.
      return _abgelaufen(jetzt) ??
          AutoZustand(AutoPhase.zaehlt, _verbleibend(jetzt));
    }

    _phase = AutoPhase.warten;
    _begonnen = null;
    _schlechtSeit = null;
    return const AutoZustand(AutoPhase.warten);
  }

  /// Nach dem Ausloesen oder beim Verlassen des Suchers.
  void zuruecksetzen() {
    _phase = AutoPhase.warten;
    _begonnen = null;
    _schlechtSeit = null;
  }
}
