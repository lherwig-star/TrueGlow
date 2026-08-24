import '../../modules/models/analyse_modul.dart';

/// Eine einzelne Planaenderung, die die KI nach einem Check-in vorschlaegt.
///
/// Absichtlich kleinteilig: Es wird ein Habit ersetzt, ergaenzt oder
/// gestrichen – nie der ganze Plan neu geschrieben.
class HabitAnpassung {
  const HabitAnpassung({
    required this.modul,
    required this.alt,
    required this.neu,
    this.grund = '',
  });

  final AnalyseModul modul;

  /// Der bisherige Habit im Wortlaut. Leer = es kommt etwas Neues dazu.
  final String alt;

  /// Der neue Habit. Leer = der bisherige faellt ersatzlos weg.
  final String neu;

  /// Warum die Aenderung – wird dem Nutzer in der Zusammenfassung gezeigt.
  final String grund;

  bool get istNeuzugang => alt.isEmpty && neu.isNotEmpty;
  bool get istStreichung => neu.isEmpty && alt.isNotEmpty;
  bool get istErsatz => alt.isNotEmpty && neu.isNotEmpty;

  /// Eine Anpassung ohne beide Seiten leer ist unbrauchbar.
  bool get istGueltig => alt.isNotEmpty || neu.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'modul': modul.name,
        'alt': alt,
        'neu': neu,
        'grund': grund,
      };

  /// Liefert null, wenn das Modul unbekannt ist – etwa weil das Modell einen
  /// Namen erfunden hat.
  static HabitAnpassung? fromJson(Map<String, dynamic> json) {
    final modul =
        AnalyseModul.values.where((m) => m.name == json['modul']).firstOrNull;
    if (modul == null) return null;

    final anpassung = HabitAnpassung(
      modul: modul,
      alt: _text(json['alt']),
      neu: _text(json['neu']),
      grund: _text(json['grund']),
    );
    return anpassung.istGueltig ? anpassung : null;
  }
}

/// Was die KI aus einem Check-in gemacht hat.
class CheckinAuswertung {
  const CheckinAuswertung({
    this.zusammenfassung = '',
    this.fazit = '',
    this.anpassungen = const [],
  });

  /// "Das passen wir an: ..." – ein bis zwei Saetze fuer den Nutzer.
  final String zusammenfassung;

  /// Kurzes Zwischenfazit beim Wirkungs-Check (Fotovergleich + Historie).
  final String fazit;

  final List<HabitAnpassung> anpassungen;

  bool get istLeer =>
      anpassungen.isEmpty && zusammenfassung.isEmpty && fazit.isEmpty;

  /// Ob es etwas zu bestaetigen gibt.
  bool get aendertPlan => anpassungen.isNotEmpty;

  static const leer = CheckinAuswertung();

  Map<String, dynamic> toJson() => {
        'zusammenfassung': zusammenfassung,
        'fazit': fazit,
        'anpassungen': anpassungen.map((a) => a.toJson()).toList(),
      };

  factory CheckinAuswertung.fromJson(Map<String, dynamic> json) =>
      CheckinAuswertung(
        zusammenfassung: _text(json['zusammenfassung']),
        fazit: _text(json['fazit']),
        anpassungen: [
          for (final e
              in (json['anpassungen'] as List? ?? const []).whereType<Map>())
            ?HabitAnpassung.fromJson(Map<String, dynamic>.from(e)),
        ],
      );
}

String _text(dynamic wert) => switch (wert) {
      final String s => s.trim(),
      null => '',
      _ => wert.toString(),
    };
