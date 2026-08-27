import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/texte.dart';

/// Die vier Tabs der Startseite.
///
/// **Jeder Tab beantwortet eine Frage** (DECISIONS 65):
///
/// | Tab | Frage |
/// |---|---|
/// | Heute | Was mache ich jetzt? |
/// | Plan | Was steht drin? |
/// | Analyse | Neu vermessen |
/// | Fortschritt | Was habe ich geschafft? |
///
/// Daraus folgt die Regel, an der sich jede künftige Karte messen lassen
/// muss: **Kein Inhalt existiert doppelt.** Wer eine Karte auf zwei Tabs
/// stellt, hat die Frage nicht beantwortet, sondern verdoppelt.
enum HomeTab {
  heute(Icons.check_circle_outline, Icons.check_circle),
  plan(Icons.flag_outlined, Icons.flag),
  analyse(Icons.auto_awesome_outlined, Icons.auto_awesome),
  fortschritt(Icons.emoji_events_outlined, Icons.emoji_events);

  const HomeTab(this.icon, this.iconAktiv);

  /// Umriss im Ruhezustand, gefüllt im aktiven – der übliche Unterschied,
  /// den man auch ohne Farbe sieht.
  final IconData icon;
  final IconData iconAktiv;
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension HomeTabText on HomeTab {
  String label(L texte) => switch (this) {
        HomeTab.heute => texte.tabHeute,
        HomeTab.plan => texte.tabPlan,
        HomeTab.analyse => texte.tabAnalyse,
        HomeTab.fortschritt => texte.tabFortschritt,
      };
}

/// Welcher Tab gerade offen ist.
///
/// Bewusst ein Provider und kein Zustand in der Hülle: Der Router setzt ihn,
/// wenn jemand über einen alten Weg hereinkommt – aus einer Erinnerung, aus
/// dem Check-in, über `/plan`. So gibt es weiterhin genau **eine** Hülle,
/// und die behält ihre vier Scroll-Positionen.
final homeTabProvider = StateProvider<HomeTab>((_) => HomeTab.heute);
