import 'package:flutter/material.dart';

import '../../../core/l10n/texte.dart';

/// Die waehlbaren Bausteine einer Analyse.
///
/// [basis] ist immer dabei und laesst sich nicht abwaehlen – alles andere
/// entscheidet der Nutzer vor der Aufnahme und kann es spaeter ueber
/// "Analyse erweitern" nachholen.
enum AnalyseModul {
  basis(icon: Icons.face_retouching_natural),
  hautFarbtyp(icon: Icons.spa_outlined),
  zaehneLaecheln(icon: Icons.sentiment_satisfied_alt_outlined),
  figurPassform(icon: Icons.accessibility_new_outlined),
  stilKleiderschrank(icon: Icons.checkroom_outlined);

  const AnalyseModul({required this.icon});

  final IconData icon;

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

/// Titel, Beschreibung und Ueberschriften eines Moduls.
///
/// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
/// [kapitel] ist die Ueberschrift im Report und stimmt bewusst mit [titel]
/// ueberein; getrennt gehalten, weil beide Stellen unabhaengig voneinander
/// umformuliert werden koennen.
extension AnalyseModulText on AnalyseModul {
  String titel(L texte) => switch (this) {
        AnalyseModul.basis => texte.modulBasisTitel,
        AnalyseModul.hautFarbtyp => texte.modulHautTitel,
        AnalyseModul.zaehneLaecheln => texte.modulZaehneTitel,
        AnalyseModul.figurPassform => texte.modulFigurTitel,
        AnalyseModul.stilKleiderschrank => texte.modulStilTitel,
      };

  String beschreibung(L texte) => switch (this) {
        AnalyseModul.basis => texte.modulBasisText,
        AnalyseModul.hautFarbtyp => texte.modulHautText,
        AnalyseModul.zaehneLaecheln => texte.modulZaehneText,
        AnalyseModul.figurPassform => texte.modulFigurText,
        AnalyseModul.stilKleiderschrank => texte.modulStilText,
      };

  /// Ueberschrift des zugehoerigen Report-Kapitels.
  String kapitel(L texte) => titel(texte);

  /// Kurze Ueberschrift der Tages-Checkliste dieses Kapitels.
  String checkliste(L texte) => switch (this) {
        AnalyseModul.basis => texte.modulBasisCheckliste,
        AnalyseModul.hautFarbtyp => texte.modulHautCheckliste,
        AnalyseModul.zaehneLaecheln => texte.modulZaehneCheckliste,
        AnalyseModul.figurPassform => texte.modulFigurCheckliste,
        AnalyseModul.stilKleiderschrank => texte.modulStilCheckliste,
      };
}
