import 'package:flutter/material.dart';
import '../../../core/l10n/texte.dart';

/// Meilensteine, die sich freischalten lassen.
///
/// Die Reihenfolge der Werte ist zugleich die Anzeigereihenfolge in der
/// Abzeichen-Sektion.
enum Abzeichen {
  ersteAnalyse(icon: Icons.auto_awesome),
  dreiTage(icon: Icons.bolt_outlined, tage: 3),
  siebenTage(icon: Icons.local_fire_department_outlined, tage: 7),
  vierzehnTage(icon: Icons.whatshot_outlined, tage: 14),
  dreissigTage(icon: Icons.calendar_month_outlined, tage: 30),
  sechzigTage(icon: Icons.military_tech_outlined, tage: 60),
  neunzigTage(icon: Icons.workspace_premium_outlined, tage: 90),
  alleModule(icon: Icons.grid_view_rounded),

  /// Vier geschaffte Wochen-Challenges. Haengt nicht am Streak, sondern an
  /// der Zahl der Wochen, in denen das Wochenziel gefallen ist.
  challenges(icon: Icons.emoji_events_outlined);

  /// So viele Challenges braucht [Abzeichen.challenges].
  static const challengeZiel = 4;

  const Abzeichen({required this.icon, this.tage});

  final IconData icon;

  /// Ab welchem Streak das Abzeichen faellt. Null bei Abzeichen, die nicht am
  /// Streak haengen.
  final int? tage;

  bool get istStreakZiel => tage != null;

  /// Text fuer den Jubel-Moment.
  String jubel(L texte) => switch (tage) {
        final int t => texte.abzeichenJubelTage(t),
        _ => titel(texte),
      };

  static List<Abzeichen> get streakZiele =>
      values.where((a) => a.istStreakZiel).toList();
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension AbzeichenText on Abzeichen {
  String titel(L texte) => switch (this) {
        Abzeichen.ersteAnalyse => texte.abzeichenErsteAnalyseTitel,
        Abzeichen.dreiTage => texte.abzeichenDreiTitel,
        Abzeichen.siebenTage => texte.abzeichenSiebenTitel,
        Abzeichen.vierzehnTage => texte.abzeichenVierzehnTitel,
        Abzeichen.dreissigTage => texte.abzeichenDreissigTitel,
        Abzeichen.sechzigTage => texte.abzeichenSechzigTitel,
        Abzeichen.neunzigTage => texte.abzeichenNeunzigTitel,
        Abzeichen.alleModule => texte.abzeichenAlleModuleTitel,
        Abzeichen.challenges => texte.abzeichenChallengesTitel,
      };

  String beschreibung(L texte) => switch (this) {
        Abzeichen.ersteAnalyse => texte.abzeichenErsteAnalyseText,
        Abzeichen.dreiTage => texte.abzeichenDreiText,
        Abzeichen.siebenTage => texte.abzeichenSiebenText,
        Abzeichen.vierzehnTage => texte.abzeichenVierzehnText,
        Abzeichen.dreissigTage => texte.abzeichenDreissigText,
        Abzeichen.sechzigTage => texte.abzeichenSechzigText,
        Abzeichen.neunzigTage => texte.abzeichenNeunzigText,
        Abzeichen.alleModule => texte.abzeichenAlleModuleText,
        Abzeichen.challenges => texte.abzeichenChallengesText,
      };
}

/// Ein Abzeichen zusammen mit seinem aktuellen Stand.
class AbzeichenStand {
  const AbzeichenStand({
    required this.abzeichen,
    required this.erreicht,
    required this.fehlend,
  });

  final Abzeichen abzeichen;
  final bool erreicht;

  /// Wie viel noch fehlt – Tage oder Module, je nach Abzeichen. 0, wenn
  /// erreicht.
  ///
  /// Absichtlich eine Zahl und kein fertiger Satz: „noch 3 Tage" heisst im
  /// Englischen „3 days to go" und im Singular wieder anders. Die Sprache
  /// gehoert in die Oberflaeche, nicht ins Repository.
  final int fehlend;
}
