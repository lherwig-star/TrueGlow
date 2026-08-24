import 'package:flutter/material.dart';

/// Die waehlbaren Bausteine einer Analyse.
///
/// [basis] ist immer dabei und laesst sich nicht abwaehlen – alles andere
/// entscheidet der Nutzer vor der Aufnahme und kann es spaeter ueber
/// "Analyse erweitern" nachholen.
enum AnalyseModul {
  basis(
    titel: 'Gesicht, Haare & Bart',
    beschreibung: 'Gesichtsform, Frisur- und Bart-Empfehlungen.',
    icon: Icons.face_retouching_natural,
    kapitel: 'Gesicht, Haare & Bart',
    checkliste: 'Haare & Bart',
  ),
  hautFarbtyp(
    titel: 'Haut & Farbtyp',
    beschreibung: 'Hautbild, Unterton, Farbpalette für Kleidung.',
    icon: Icons.spa_outlined,
    kapitel: 'Haut & Farbtyp',
    checkliste: 'Haut',
  ),
  zaehneLaecheln(
    titel: 'Zähne & Lächeln',
    beschreibung: 'Zahnfarbe, Zahnstellung, Mimik beim Lächeln.',
    icon: Icons.sentiment_satisfied_alt_outlined,
    kapitel: 'Zähne & Lächeln',
    checkliste: 'Zähne',
  ),
  figurPassform(
    titel: 'Figur & Passform',
    beschreibung: 'Silhouette, Proportionen, Schnitt-Empfehlungen.',
    icon: Icons.accessibility_new_outlined,
    kapitel: 'Figur & Passform',
    checkliste: 'Haltung & Figur',
  ),
  stilKleiderschrank(
    titel: 'Stil & Kleiderschrank',
    beschreibung: 'Aktuelle Outfits, Stilziel, konkrete Look-Vorschläge.',
    icon: Icons.checkroom_outlined,
    kapitel: 'Stil & Kleiderschrank',
    checkliste: 'Stil',
  );

  const AnalyseModul({
    required this.titel,
    required this.beschreibung,
    required this.icon,
    required this.kapitel,
    required this.checkliste,
  });

  final String titel;
  final String beschreibung;
  final IconData icon;

  /// Ueberschrift des zugehoerigen Report-Kapitels.
  final String kapitel;

  /// Kurze Ueberschrift der Tages-Checkliste dieses Kapitels.
  final String checkliste;

  bool get istBasis => this == AnalyseModul.basis;

  /// Alle Module ausser der Basis – das ist genau die Auswahl, die der Nutzer
  /// treffen kann.
  static List<AnalyseModul> get waehlbare =>
      values.where((m) => !m.istBasis).toList();

  /// Stabile Namen fuer die lokale Speicherung.
  static Set<AnalyseModul> ausNamen(Iterable<Object?> namen) {
    final gefunden = <AnalyseModul>{};
    for (final name in namen) {
      for (final modul in values) {
        if (modul.name == name) gefunden.add(modul);
      }
    }
    // Die Basis ist nicht verhandelbar.
    return {AnalyseModul.basis, ...gefunden};
  }
}
