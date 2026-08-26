import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Runder Auswahl-Chip im Kartenstil der App: im Ruhezustand eine Karte mit
/// Rahmen, ausgewaehlt in der Akzentfarbe hinterlegt.
///
/// Bewusst zentral: Der Stil-Fragebogen und "Deine Richtung" nutzen dieselbe
/// Optik, und ein zweiter Nachbau waere beim naechsten Feinschliff sofort
/// auseinandergelaufen.
class AuswahlChip extends StatelessWidget {
  const AuswahlChip({
    super.key,
    required this.label,
    required this.aktiv,
    required this.onTap,
  });

  final String label;
  final bool aktiv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppTheme.animation(context, const Duration(milliseconds: 180)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: aktiv
              ? farben.erreicht.withValues(alpha: 0.14)
              : farben.flaeche,
          border: Border.all(
            color: aktiv ? farben.erreicht : farben.kartenrand,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: aktiv ? farben.erreicht : farben.textPrimaer,
          ),
        ),
      ),
    );
  }
}
