// Texteingaben und Auswahlantworten, die einzelne Module zusaetzlich zu den
// Fotos brauchen. Fliessen wie das Onboarding-Profil in den Prompt ein.

import '../../../core/l10n/texte.dart';
import '../../direction/models/richtung.dart';

// Das Stilziel ist kein eigenes Enum mehr: Es ist dieselbe Liste wie bei
// „Deine Richtung" ([Richtungsziel]). Die alte Auswahl (klassisch,
// minimalistisch, sportlich, smart casual, kreativ, rockig) beschrieb
// dieselbe Sache ein zweites Mal und driftete davon ab – zwei Listen, zwei
// Pflegestellen, und im Report zwei Angaben, die sich widersprechen konnten
// (DECISIONS 72). Alte gespeicherte Werte fuehrt [_altesStilziel] ueber.

/// Wofuer der Stil im Alltag vor allem funktionieren soll.
///
/// Loest den frueheren `Dresscode` ab. „Handwerk / Arbeitskleidung" und
/// „Uniform / Dienstkleidung" sind ersatzlos weg: Wer Arbeitskleidung
/// gestellt bekommt, hat daran nichts zu entscheiden, und die App richtet
/// sich an 16- bis 25-Jaehrige.
///
/// Mehrfachauswahl und ueberspringbar – anders als der Dresscode, der genau
/// eine Antwort verlangte.
enum Alltagszweck {
  uniSchule,
  ausgehenDates,
  arbeitNebenjob,
  gymSport,
}

/// Preisrahmen speziell fuer Kleidung – bewusst getrennt vom Pflegebudget
/// aus dem Onboarding.
enum Kleidungsbudget { klein, mittel, gross }

/// Wie viel Aufwand beim Pflegen und Kombinieren akzeptabel ist.
enum Pflegeaufwand { minimal, mittel, hoch }

// Anzeigetexte als Erweiterungen – Begruendung in `onboarding_profile.dart`.

extension AlltagszweckText on Alltagszweck {
  String label(L texte) => switch (this) {
        Alltagszweck.uniSchule => texte.zweckUniSchule,
        Alltagszweck.ausgehenDates => texte.zweckAusgehenDates,
        Alltagszweck.arbeitNebenjob => texte.zweckArbeitNebenjob,
        Alltagszweck.gymSport => texte.zweckGymSport,
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
    this.zwecke = const {},
    this.budget,
    this.pflegeaufwand,
  });

  /// Die Stilrichtung – dieselbe Liste wie bei „Deine Richtung".
  ///
  /// Ist dort schon etwas gewaehlt, kommt der Fragebogen damit vorbelegt.
  /// Aendern kann man es hier trotzdem: Die Richtung gilt fuer den ganzen
  /// Look, hier geht es nur um die Kleidung.
  final Set<Richtungsziel> ziele;

  /// Wofuer der Stil vor allem funktionieren soll. Mehrfachauswahl und
  /// ausdruecklich ueberspringbar.
  final Set<Alltagszweck> zwecke;

  final Kleidungsbudget? budget;
  final Pflegeaufwand? pflegeaufwand;

  /// [zwecke] zaehlt bewusst nicht mit: Die Frage darf uebersprungen werden.
  bool get istVollstaendig =>
      ziele.isNotEmpty && budget != null && pflegeaufwand != null;

  StilAngaben copyWith({
    Set<Richtungsziel>? ziele,
    Set<Alltagszweck>? zwecke,
    Kleidungsbudget? budget,
    Pflegeaufwand? pflegeaufwand,
  }) {
    return StilAngaben(
      ziele: ziele ?? this.ziele,
      zwecke: zwecke ?? this.zwecke,
      budget: budget ?? this.budget,
      pflegeaufwand: pflegeaufwand ?? this.pflegeaufwand,
    );
  }

  Map<String, dynamic> toJson() => {
        'ziele': ziele.map((z) => z.name).toList(),
        'zwecke': zwecke.map((z) => z.name).toList(),
        'budget': budget?.name,
        'pflegeaufwand': pflegeaufwand?.name,
      };

  factory StilAngaben.fromJson(Map<String, dynamic> json) => StilAngaben(
        ziele: {
          for (final n in (json['ziele'] as List? ?? const []))
            ?_stilziel(n),
        },
        zwecke: {
          for (final n in (json['zwecke'] as List? ?? const []))
            ?_ausName(Alltagszweck.values, n),
          // Der frueher einzeln gespeicherte Dresscode. Buero und Business
          // Casual werden zu „Arbeit / Nebenjob"; Handwerk, Uniform,
          // Homeoffice und „keine Vorgaben" haben keine naechstliegende
          // Entsprechung und bleiben leer (DECISIONS 72).
          if (json['dresscode'] == 'buero' ||
              json['dresscode'] == 'businessCasual')
            Alltagszweck.arbeitNebenjob,
        },
        budget: _ausName(Kleidungsbudget.values, json['budget']),
        pflegeaufwand: _ausName(Pflegeaufwand.values, json['pflegeaufwand']),
      );
}

/// Was aus den Werten der alten Stilziel-Liste geworden ist.
///
/// Derselbe Grundsatz wie bei [Richtungsziel]: der naechste vorhandene
/// Nachbar, nie ein Wegfall. Zwei alte Werte landen auf demselben neuen –
/// eine Menge nimmt das ohne Dublette hin.
const _altesStilziel = <String, Richtungsziel>{
  'klassisch': Richtungsziel.smartHochwertig,
  'smartCasual': Richtungsziel.smartHochwertig,
  'minimalistisch': Richtungsziel.cleanGepflegt,
  'sportlich': Richtungsziel.sportlichFunktional,
  'kreativ': Richtungsziel.kreativAuffaellig,
  'rockig': Richtungsziel.markantMaskulin,
};

/// Liest ein gespeichertes Stilziel – neu, alt oder aus der ganz alten
/// Richtungsliste. Unbekanntes faellt weg.
Richtungsziel? _stilziel(dynamic name) =>
    Richtungsziel.ausName(name) ?? _altesStilziel[name];

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
