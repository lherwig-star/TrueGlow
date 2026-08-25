import '../../../core/l10n/texte.dart';

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
/// Die Angabe, nach der sich Module, Umrisse und Empfehlungen richten.
///
/// Bewusst vier Werte und nicht zwei. „Divers" und „keine Angabe" sind
/// verschiedene Aussagen – die eine ist eine Identität, die andere ein
/// Nein zur Frage – und führen trotzdem zur selben [Ausrichtung]: Beide
/// heißen für die App „lass mir alles offen".
enum Geschlecht { maennlich, weiblich, divers, keineAngabe }

/// Wonach sich die App tatsächlich richtet.
///
/// Getrennt vom [Geschlecht], weil hier eine Entscheidung steht und dort
/// eine Angabe. Vier Angaben, drei Ausrichtungen – und `null`, also „noch
/// nie gefragt", ist eine fünfte Angabe mit demselben Verhalten wie vorher.
enum Ausrichtung { maennlich, weiblich, neutral }

extension GeschlechtAusrichtung on Geschlecht? {
  /// Die Ausrichtung zu dieser Angabe.
  ///
  /// `null` ergibt [Ausrichtung.maennlich] – nicht als Aussage über
  /// irgendjemanden, sondern weil das genau das Verhalten ist, das die App
  /// vor dieser Frage hatte. Bestandsnutzer sollen von einem Update nichts
  /// merken, und ein erzwungener Zusatzdialog beim ersten Start nach dem
  /// Update wäre die schlechtere Antwort auf eine Frage, die sie nie
  /// gestellt bekommen haben.
  Ausrichtung get ausrichtung => switch (this) {
        null || Geschlecht.maennlich => Ausrichtung.maennlich,
        Geschlecht.weiblich => Ausrichtung.weiblich,
        Geschlecht.divers || Geschlecht.keineAngabe => Ausrichtung.neutral,
      };
}

enum Altersbereich { a18bis24, a25bis34, a35bis44, ab45 }

enum Budget { niedrig, mittel, hoch }

enum Zeitbudget { kurz, mittel, lang }

enum Fokusbereich {
  haut,
  haare,
  bart,
  style,
  fitness;

  /// Was zur Wahl steht.
  ///
  /// Im weiblichen Modus faellt „Bart" heraus – es waere die einzige Frage
  /// auf dem Bildschirm, die im Report keine Entsprechung mehr hat.
  static List<Fokusbereich> fuer(Ausrichtung ausrichtung) =>
      ausrichtung == Ausrichtung.weiblich
          ? values.where((f) => f != Fokusbereich.bart).toList()
          : values;
}

// Die Anzeigetexte stehen bewusst nicht mehr im Enum, sondern in
// Erweiterungen daneben.
//
// Ein Enum-Wert ist konstant, ein übersetzter Text hängt an der gewählten
// Sprache – beides in einem Feld unterzubringen geht nicht. Die Zuordnung
// bleibt trotzdem hier, direkt neben der Liste: So fällt beim Ergänzen eines
// Werts sofort auf, dass auch ein Text dazugehört, und der Compiler besteht
// darauf.

extension GeschlechtText on Geschlecht {
  String label(L texte) => switch (this) {
        Geschlecht.maennlich => texte.geschlechtMaennlich,
        Geschlecht.weiblich => texte.geschlechtWeiblich,
        Geschlecht.divers => texte.geschlechtDivers,
        Geschlecht.keineAngabe => texte.geschlechtKeineAngabe,
      };
}

extension AltersbereichText on Altersbereich {
  String label(L texte) => switch (this) {
        Altersbereich.a18bis24 => texte.alter18bis24,
        Altersbereich.a25bis34 => texte.alter25bis34,
        Altersbereich.a35bis44 => texte.alter35bis44,
        Altersbereich.ab45 => texte.alterAb45,
      };
}

extension BudgetText on Budget {
  String label(L texte) => switch (this) {
        Budget.niedrig => texte.budgetNiedrig,
        Budget.mittel => texte.budgetMittel,
        Budget.hoch => texte.budgetHoch,
      };

  String beschreibung(L texte) => switch (this) {
        Budget.niedrig => texte.budgetNiedrigText,
        Budget.mittel => texte.budgetMittelText,
        Budget.hoch => texte.budgetHochText,
      };
}

extension ZeitbudgetText on Zeitbudget {
  String label(L texte) => switch (this) {
        Zeitbudget.kurz => texte.zeitKurz,
        Zeitbudget.mittel => texte.zeitMittel,
        Zeitbudget.lang => texte.zeitLang,
      };

  String beschreibung(L texte) => switch (this) {
        Zeitbudget.kurz => texte.zeitKurzText,
        Zeitbudget.mittel => texte.zeitMittelText,
        Zeitbudget.lang => texte.zeitLangText,
      };
}

extension FokusbereichText on Fokusbereich {
  String label(L texte) => switch (this) {
        Fokusbereich.haut => texte.fokusHaut,
        Fokusbereich.haare => texte.fokusHaare,
        Fokusbereich.bart => texte.fokusBart,
        Fokusbereich.style => texte.fokusStyle,
        Fokusbereich.fitness => texte.fokusFitness,
      };
}

class OnboardingProfile {
  const OnboardingProfile({
    this.geschlecht,
    this.alter,
    this.budget,
    this.zeit,
    this.fokus = const {},
    this.zugestimmt = false,
    this.abgeschlossen = false,
  });

  /// `null` heißt „nie gefragt" – siehe [GeschlechtAusrichtung.ausrichtung].
  final Geschlecht? geschlecht;

  final Altersbereich? alter;
  final Budget? budget;
  final Zeitbudget? zeit;
  final Set<Fokusbereich> fokus;
  final bool zugestimmt;
  final bool abgeschlossen;

  OnboardingProfile copyWith({
    Geschlecht? geschlecht,
    Altersbereich? alter,
    Budget? budget,
    Zeitbudget? zeit,
    Set<Fokusbereich>? fokus,
    bool? zugestimmt,
    bool? abgeschlossen,
  }) {
    return OnboardingProfile(
      geschlecht: geschlecht ?? this.geschlecht,
      alter: alter ?? this.alter,
      budget: budget ?? this.budget,
      zeit: zeit ?? this.zeit,
      fokus: fokus ?? this.fokus,
      zugestimmt: zugestimmt ?? this.zugestimmt,
      abgeschlossen: abgeschlossen ?? this.abgeschlossen,
    );
  }

  Map<String, dynamic> toJson() => {
        'geschlecht': geschlecht?.name,
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
      geschlecht: byName(Geschlecht.values, json['geschlecht']),
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
