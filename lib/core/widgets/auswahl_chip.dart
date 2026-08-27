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
    this.untertext,
  });

  final String label;
  final bool aktiv;
  final VoidCallback onTap;

  /// Drei bis sechs Woerter unter der Beschriftung.
  ///
  /// Mit Untertext wird aus der Pille eine kleine Karte: Zwei Zeilen in
  /// einer Pille zu stapeln sieht aus wie ein Fehler, und die Rundung frisst
  /// dann die Ecken der zweiten Zeile. Ohne Untertext bleibt alles, wie es
  /// war – der Stil-Fragebogen nutzt weiterhin die runde Form.
  final String? untertext;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final zweizeilig = untertext != null && untertext!.isNotEmpty;
    final radius = BorderRadius.circular(zweizeilig ? AppTheme.radiusCard : 999);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppTheme.animation(context, const Duration(milliseconds: 180)),
        padding: EdgeInsets.symmetric(
          horizontal: zweizeilig ? 14 : 18,
          vertical: zweizeilig ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: aktiv
              ? farben.erreicht.withValues(alpha: 0.14)
              : farben.flaeche,
          border: Border.all(
            color: aktiv ? farben.erreicht : farben.kartenrand,
          ),
          borderRadius: radius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: aktiv ? farben.erreicht : farben.textPrimaer,
              ),
            ),
            if (zweizeilig) ...[
              const SizedBox(height: 2),
              Text(
                untertext!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  // Nicht der Akzentton: Kleinschrift in Akzentfarbe kaeme
                  // auf der Chipflaeche nicht auf die noetigen 4,5:1.
                  color: farben.textSekundaer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
