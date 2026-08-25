// Texteingaben und Auswahlantworten, die einzelne Module zusaetzlich zu den
// Fotos brauchen. Fliessen wie das Onboarding-Profil in den Prompt ein.

import '../../../core/l10n/texte.dart';

/// Stilziel im Modul "Stil & Kleiderschrank".
enum Stilziel {
  klassisch,
  minimalistisch,
  sportlich,
  smartCasual,
  kreativ,
  rockig,
}

/// Was der Alltag an Kleidung verlangt.
enum Dresscode {
  buero,
  businessCasual,
  handwerk,
  homeoffice,
  uniform,
  frei,
}

/// Preisrahmen speziell fuer Kleidung – bewusst getrennt vom Pflegebudget
/// aus dem Onboarding.
enum Kleidungsbudget { klein, mittel, gross }

/// Wie viel Aufwand beim Pflegen und Kombinieren akzeptabel ist.
enum Pflegeaufwand { minimal, mittel, hoch }

// Anzeigetexte als Erweiterungen – Begruendung in `onboarding_profile.dart`.

extension StilzielText on Stilziel {
  String label(L texte) => switch (this) {
        Stilziel.klassisch => texte.stilzielKlassisch,
        Stilziel.minimalistisch => texte.stilzielMinimalistisch,
        Stilziel.sportlich => texte.stilzielSportlich,
        Stilziel.smartCasual => texte.stilzielSmartCasual,
        Stilziel.kreativ => texte.stilzielKreativ,
        Stilziel.rockig => texte.stilzielRockig,
      };
}

extension DresscodeText on Dresscode {
  String label(L texte) => switch (this) {
        Dresscode.buero => texte.dresscodeBuero,
        Dresscode.businessCasual => texte.dresscodeBusinessCasual,
        Dresscode.handwerk => texte.dresscodeHandwerk,
        Dresscode.homeoffice => texte.dresscodeHomeoffice,
        Dresscode.uniform => texte.dresscodeUniform,
        Dresscode.frei => texte.dresscodeFrei,
      };
}

extension KleidungsbudgetText on Kleidungsbudget {
  String label(L texte) => switch (this) {
        Kleidungsbudget.klein => texte.kleidungsbudgetKlein,
        Kleidungsbudget.mittel => texte.kleidungsbudgetMittel,
        Kleidungsbudget.gross => texte.kleidungsbudgetGross,
      };
}

extension PflegeaufwandText on Pflegeaufwand {
  String label(L texte) => switch (this) {
        Pflegeaufwand.minimal => texte.pflegeaufwandMinimal,
        Pflegeaufwand.mittel => texte.pflegeaufwandMittel,
        Pflegeaufwand.hoch => texte.pflegeaufwandHoch,
      };
}

/// Koerpermasse fuer das Modul "Figur & Passform".
class FigurAngaben {
  const FigurAngaben({this.groesseCm, this.gewichtKg});

  final int? groesseCm;
  final int? gewichtKg;

  bool get istVollstaendig => groesseCm != null && gewichtKg != null;

  FigurAngaben copyWith({int? groesseCm, int? gewichtKg}) => FigurAngaben(
        groesseCm: groesseCm ?? this.groesseCm,
        gewichtKg: gewichtKg ?? this.gewichtKg,
      );

  Map<String, dynamic> toJson() => {
        'groesseCm': groesseCm,
        'gewichtKg': gewichtKg,
      };

  factory FigurAngaben.fromJson(Map<String, dynamic> json) => FigurAngaben(
        groesseCm: _ganzzahl(json['groesseCm']),
        gewichtKg: _ganzzahl(json['gewichtKg']),
      );
}

/// Antworten des Stil-Fragebogens.
class StilAngaben {
  const StilAngaben({
    this.ziele = const {},
    this.dresscode,
    this.budget,
    this.pflegeaufwand,
  });

  /// Mehrfachauswahl – die Chips im Fragebogen.
  final Set<Stilziel> ziele;
  final Dresscode? dresscode;
  final Kleidungsbudget? budget;
  final Pflegeaufwand? pflegeaufwand;

  bool get istVollstaendig =>
      ziele.isNotEmpty &&
      dresscode != null &&
      budget != null &&
      pflegeaufwand != null;

  StilAngaben copyWith({
    Set<Stilziel>? ziele,
    Dresscode? dresscode,
    Kleidungsbudget? budget,
    Pflegeaufwand? pflegeaufwand,
  }) {
    return StilAngaben(
      ziele: ziele ?? this.ziele,
      dresscode: dresscode ?? this.dresscode,
      budget: budget ?? this.budget,
      pflegeaufwand: pflegeaufwand ?? this.pflegeaufwand,
    );
  }

  Map<String, dynamic> toJson() => {
        'ziele': ziele.map((z) => z.name).toList(),
        'dresscode': dresscode?.name,
        'budget': budget?.name,
        'pflegeaufwand': pflegeaufwand?.name,
      };

  factory StilAngaben.fromJson(Map<String, dynamic> json) => StilAngaben(
        ziele: {
          for (final n in (json['ziele'] as List? ?? const []))
            ?_ausName(Stilziel.values, n),
        },
        dresscode: _ausName(Dresscode.values, json['dresscode']),
        budget: _ausName(Kleidungsbudget.values, json['budget']),
        pflegeaufwand: _ausName(Pflegeaufwand.values, json['pflegeaufwand']),
      );
}

/// Sammelt alle Zusatzangaben der Module.
class ModulEingaben {
  const ModulEingaben({
    this.figur = const FigurAngaben(),
    this.stil = const StilAngaben(),
  });

  final FigurAngaben figur;
  final StilAngaben stil;

  ModulEingaben copyWith({FigurAngaben? figur, StilAngaben? stil}) =>
      ModulEingaben(figur: figur ?? this.figur, stil: stil ?? this.stil);

  Map<String, dynamic> toJson() => {
        'figur': figur.toJson(),
        'stil': stil.toJson(),
      };

  factory ModulEingaben.fromJson(Map<String, dynamic> json) => ModulEingaben(
        figur: json['figur'] is Map
            ? FigurAngaben.fromJson(
                Map<String, dynamic>.from(json['figur'] as Map))
            : const FigurAngaben(),
        stil: json['stil'] is Map
            ? StilAngaben.fromJson(
                Map<String, dynamic>.from(json['stil'] as Map))
            : const StilAngaben(),
      );
}

T? _ausName<T extends Enum>(List<T> werte, dynamic name) {
  if (name == null) return null;
  for (final wert in werte) {
    if (wert.name == name) return wert;
  }
  return null;
}

int? _ganzzahl(dynamic wert) => switch (wert) {
      final int i => i,
      final num n => n.round(),
      final String s => int.tryParse(s.trim()),
      _ => null,
    };
