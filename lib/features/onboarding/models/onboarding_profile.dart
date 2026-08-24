/// Antworten aus dem Onboarding. Fliessen spaeter in den Analyse-Prompt ein.
/// Die Altersbereiche, nach denen das Onboarding fragt.
///
/// „unter 18" gibt es bewusst nicht mehr: TrueGlow richtet sich ausschliesslich
/// an Erwachsene. Das Alter wird hier nur erfragt, um Empfehlungen
/// einzuordnen; die verbindliche Aussage ist die Altersbestaetigung
/// (`Einwilligungsart.mindestalter`).
///
/// Ein gespeicherter Altwert `unter18` faellt beim Lesen heraus und laesst das
/// Feld leer – das Onboarding fragt dann neu.
enum Altersbereich {
  a18bis24('18–24'),
  a25bis34('25–34'),
  a35bis44('35–44'),
  ab45('45+');

  const Altersbereich(this.label);
  final String label;
}

enum Budget {
  niedrig('Niedrig', 'Drogerie, unter 30 € im Monat'),
  mittel('Mittel', '30–80 € im Monat'),
  hoch('Hoch', 'über 80 € im Monat');

  const Budget(this.label, this.beschreibung);
  final String label;
  final String beschreibung;
}

enum Zeitbudget {
  kurz('5 Minuten', 'Nur das Nötigste'),
  mittel('15 Minuten', 'Solide Routine'),
  lang('30+ Minuten', 'Volles Programm');

  const Zeitbudget(this.label, this.beschreibung);
  final String label;
  final String beschreibung;
}

enum Fokusbereich {
  haut('Haut'),
  haare('Haare'),
  bart('Bart'),
  style('Style'),
  fitness('Fitness-Habits');

  const Fokusbereich(this.label);
  final String label;
}

class OnboardingProfile {
  const OnboardingProfile({
    this.alter,
    this.budget,
    this.zeit,
    this.fokus = const {},
    this.zugestimmt = false,
    this.abgeschlossen = false,
  });

  final Altersbereich? alter;
  final Budget? budget;
  final Zeitbudget? zeit;
  final Set<Fokusbereich> fokus;
  final bool zugestimmt;
  final bool abgeschlossen;

  OnboardingProfile copyWith({
    Altersbereich? alter,
    Budget? budget,
    Zeitbudget? zeit,
    Set<Fokusbereich>? fokus,
    bool? zugestimmt,
    bool? abgeschlossen,
  }) {
    return OnboardingProfile(
      alter: alter ?? this.alter,
      budget: budget ?? this.budget,
      zeit: zeit ?? this.zeit,
      fokus: fokus ?? this.fokus,
      zugestimmt: zugestimmt ?? this.zugestimmt,
      abgeschlossen: abgeschlossen ?? this.abgeschlossen,
    );
  }

  Map<String, dynamic> toJson() => {
        'alter': alter?.name,
        'budget': budget?.name,
        'zeit': zeit?.name,
        'fokus': fokus.map((f) => f.name).toList(),
        'zugestimmt': zugestimmt,
        'abgeschlossen': abgeschlossen,
      };

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    T? byName<T extends Enum>(List<T> values, dynamic name) {
      if (name == null) return null;
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    return OnboardingProfile(
      alter: byName(Altersbereich.values, json['alter']),
      budget: byName(Budget.values, json['budget']),
      zeit: byName(Zeitbudget.values, json['zeit']),
      fokus: {
        for (final n in (json['fokus'] as List? ?? const []))
          ?byName(Fokusbereich.values, n),
      },
      zugestimmt: json['zugestimmt'] as bool? ?? false,
      abgeschlossen: json['abgeschlossen'] as bool? ?? false,
    );
  }
}
