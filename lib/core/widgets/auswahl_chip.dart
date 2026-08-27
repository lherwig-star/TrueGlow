import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Auswahl-Element im Kartenstil der App: im Ruhezustand eine Fläche mit
/// Rahmen, ausgewählt in der Farbe für Erreichtes hinterlegt.
///
/// Bewusst zentral: Der Stil-Fragebogen, der Check-in und „Deine Richtung"
/// nutzen dieselbe Optik, und ein zweiter Nachbau wäre beim nächsten
/// Feinschliff sofort auseinandergelaufen.
///
/// **Zwei Formen** (DECISIONS 61):
///
/// - **Pille** (Voreinstellung): rund, so breit wie ihr Text, mehrere neben-
///   einander in einem `Wrap`. Richtig für kurze Einwort-Antworten.
/// - **Volle Breite** ([vollBreite]`: true`): eine Zeile pro Eintrag,
///   untereinander, mit Untertext und Haken rechts — wie die Modul-Karten.
///   Richtig, sobald ein Untertext dazukommt.
///
/// Warum nicht beides in einem Wrap: Acht Pillen mit unterschiedlich langen
/// Beschriftungen ergeben ein ausgefranstes Bild — zwei in der ersten Zeile,
/// eine in der zweiten, eine einzelne rechts außen. Am Gerät sah das aus wie
/// ein Fehler, und in der englischen Fassung wurde es schlimmer, weil die
/// Texte dort länger sind. Volle Breite kann per Konstruktion nicht
/// ausfransen: Jede Zeile ist gleich breit, und kein Text kann die Spalte
/// verlassen.
class AuswahlChip extends StatelessWidget {
  const AuswahlChip({
    super.key,
    required this.label,
    required this.aktiv,
    required this.onTap,
    this.untertext,
    this.vollBreite = false,
  });

  final String label;
  final bool aktiv;
  final VoidCallback onTap;

  /// Drei bis sechs Wörter unter der Beschriftung.
  ///
  /// Ohne ihn ist „Smart & hochwertig" für jemanden ohne Modewissen eine
  /// leere Hülle. Mit „Polo, Strick, klare Silhouetten" weiß man, worauf man
  /// tippt. Nur in der Form [vollBreite] sichtbar — in einer Pille hätte er
  /// keinen Platz.
  final String? untertext;

  /// Eine Zeile über die ganze Breite statt einer Pille.
  final bool vollBreite;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final dauer = AppTheme.animation(context, const Duration(milliseconds: 180));
    final radius = BorderRadius.circular(
      vollBreite ? AppTheme.radiusCard : 999,
    );

    final flaeche = AnimatedContainer(
      duration: dauer,
      width: vollBreite ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: vollBreite ? AppTheme.gapM : 18,
        vertical: vollBreite ? 12 : 12,
      ),
      decoration: BoxDecoration(
        color: aktiv ? farben.erreicht.withValues(alpha: 0.14) : farben.flaeche,
        border: Border.all(
          color: aktiv ? farben.erreicht : farben.kartenrand,
          width: aktiv ? 1.6 : 1,
        ),
        borderRadius: radius,
      ),
      child: vollBreite ? _zeile(farben) : _text(farben),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: flaeche),
    );
  }

  Widget _text(AppColors farben) => Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: aktiv ? farben.erreicht : farben.textPrimaer,
        ),
      );

  Widget _zeile(AppColors farben) {
    final unter = untertext;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _text(farben),
              if (unter != null && unter.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  unter,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    // Nicht die Akzentfarbe: Kleinschrift in Akzentfarbe
                    // käme auf dieser Fläche nicht auf die nötigen 4,5:1.
                    color: farben.textSekundaer,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppTheme.gapS),
        _Haken(aktiv: aktiv),
      ],
    );
  }
}

/// Derselbe Haken wie auf den Modul-Karten – eckig, weil hier mehreres
/// gleichzeitig gehen darf. Der runde Punkt bleibt der Moduswahl vorbehalten,
/// wo genau eines gilt.
class _Haken extends StatelessWidget {
  const _Haken({required this.aktiv});

  final bool aktiv;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AnimatedContainer(
      duration: AppTheme.animation(context, const Duration(milliseconds: 180)),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: aktiv ? farben.erreicht : Colors.transparent,
        border: Border.all(
          color: aktiv ? farben.erreicht : farben.textSekundaer,
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: aktiv
          ? Icon(Icons.check, size: 16, color: farben.aufAkzent)
          : null,
    );
  }
}
