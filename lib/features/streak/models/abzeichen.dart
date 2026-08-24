import 'package:flutter/material.dart';

/// Meilensteine, die sich freischalten lassen.
///
/// Die Reihenfolge der Werte ist zugleich die Anzeigereihenfolge in der
/// Abzeichen-Sektion.
enum Abzeichen {
  ersteAnalyse(
    titel: 'Erste Analyse geschafft',
    beschreibung: 'Du hast deine erste Analyse abgeschlossen.',
    icon: Icons.auto_awesome,
  ),
  dreiTage(
    titel: 'Dranbleiben angefangen',
    beschreibung: 'Drei Tage am Stück etwas abgehakt.',
    icon: Icons.bolt_outlined,
    tage: 3,
  ),
  siebenTage(
    titel: 'Erste Woche durchgezogen',
    beschreibung: 'Sieben Tage am Stück – die erste Woche steht.',
    icon: Icons.local_fire_department_outlined,
    tage: 7,
  ),
  vierzehnTage(
    titel: 'Zwei Wochen stark',
    beschreibung: 'Vierzehn Tage am Stück. Das ist schon Routine.',
    icon: Icons.whatshot_outlined,
    tage: 14,
  ),
  dreissigTage(
    titel: 'Ein Monat dran',
    beschreibung: 'Dreißig Tage am Stück. Beeindruckend.',
    icon: Icons.calendar_month_outlined,
    tage: 30,
  ),
  sechzigTage(
    titel: 'Zwei Monate durchgehalten',
    beschreibung: 'Sechzig Tage am Stück – das schaffen wenige.',
    icon: Icons.military_tech_outlined,
    tage: 60,
  ),
  neunzigTage(
    titel: 'Ein Vierteljahr Disziplin',
    beschreibung: 'Neunzig Tage am Stück. Das ist jetzt dein Alltag.',
    icon: Icons.workspace_premium_outlined,
    tage: 90,
  ),
  alleModule(
    titel: 'Alles freigeschaltet',
    beschreibung: 'Deine Analyse deckt alle Module ab.',
    icon: Icons.grid_view_rounded,
  );

  const Abzeichen({
    required this.titel,
    required this.beschreibung,
    required this.icon,
    this.tage,
  });

  final String titel;
  final String beschreibung;
  final IconData icon;

  /// Ab welchem Streak das Abzeichen faellt. Null bei Abzeichen, die nicht am
  /// Streak haengen.
  final int? tage;

  bool get istStreakZiel => tage != null;

  /// Text fuer den Jubel-Moment.
  String get jubel => switch (tage) {
        final int t => '$t Tage durchgezogen!',
        _ => titel,
      };

  static List<Abzeichen> get streakZiele =>
      values.where((a) => a.istStreakZiel).toList();
}

/// Ein Abzeichen zusammen mit seinem aktuellen Stand.
class AbzeichenStand {
  const AbzeichenStand({
    required this.abzeichen,
    required this.erreicht,
    required this.fortschrittstext,
  });

  final Abzeichen abzeichen;
  final bool erreicht;

  /// Was noch fehlt, z. B. "noch 3 Tage". Leer, wenn erreicht.
  final String fortschrittstext;
}
