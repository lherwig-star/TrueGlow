import '../models/checkin.dart';

/// Ein Schritt im Check-in. Wie im Aufnahme-Flow eine versiegelte Familie,
/// damit die Fortschrittsanzeige ("2 von 6") immer zum tatsaechlichen Ablauf
/// passt und kein Fall vergessen werden kann.
sealed class CheckinSchritt {
  const CheckinSchritt();
}

/// Begruessung mit dem Zweck dieses Check-ins.
class IntroSchritt extends CheckinSchritt {
  const IntroSchritt();
}

/// Das 3-Tap-Rating der Alltagstauglichkeit.
class HabitsSchritt extends CheckinSchritt {
  const HabitsSchritt(this.habits);

  final List<String> habits;
}

/// Die weichen bzw. Ergebnis-Fragen.
class WirkungSchritt extends CheckinSchritt {
  const WirkungSchritt(this.fragen);

  final List<WirkungsFrage> fragen;
}

/// Erwartungsmanagement: was jetzt noch nicht sichtbar sein kann.
class ErwartungSchritt extends CheckinSchritt {
  const ErwartungSchritt(this.text);

  final String text;
}

/// Optionales Fortschrittsfoto.
class FotoSchritt extends CheckinSchritt {
  const FotoSchritt();
}

/// Erstfoto und neues Foto nebeneinander.
class VergleichSchritt extends CheckinSchritt {
  const VergleichSchritt();
}

/// Auswertung durch die KI plus Bestaetigung der Aenderungen.
class AbschlussSchritt extends CheckinSchritt {
  const AbschlussSchritt();
}

/// Baut den Ablauf dieses Check-ins.
///
/// [habits] sind die tatsaechlich abzufragenden Aufgaben – beim Zwischencheck
/// nur die Wackelkandidaten. Ist die Liste leer, entfaellt der Schritt: Eine
/// Seite ohne Inhalt kostet nur Zeit.
List<CheckinSchritt> baueCheckinFlow({
  required Checkin checkin,
  required List<String> habits,
  required List<WirkungsFrage> fragen,
  required String erwartung,
  required bool fotoMoeglich,
}) {
  return [
    const IntroSchritt(),
    if (habits.isNotEmpty) HabitsSchritt(habits),
    if (fragen.isNotEmpty) WirkungSchritt(fragen),
    // Der Hinweis steht nach den Wirkungsfragen: erst antworten, dann
    // einordnen – umgekehrt waere es eine Vorgabe der Antwort.
    if (checkin.typ == CheckinTyp.zwischen && erwartung.isNotEmpty)
      ErwartungSchritt(erwartung),
    if (fotoMoeglich) const FotoSchritt(),
    if (fotoMoeglich && checkin.fortschrittsfoto != null)
      const VergleichSchritt(),
    const AbschlussSchritt(),
  ];
}

/// Ob der Schritt beantwortet ist und "Weiter" freigibt.
bool schrittErfuellt(CheckinSchritt schritt, Checkin checkin) {
  return switch (schritt) {
    IntroSchritt() => true,
    HabitsSchritt(:final habits) => checkin.habitsVollstaendig(habits),
    WirkungSchritt(:final fragen) =>
      fragen.every((f) => checkin.antwortZu(f.id) != null),
    ErwartungSchritt() => true,
    // Das Foto ist ausdruecklich optional.
    FotoSchritt() => true,
    VergleichSchritt() => true,
    AbschlussSchritt() => true,
  };
}
