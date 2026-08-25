import 'package:flutter/material.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';

/// Einmalige Vorbereitung vor dem ersten Foto. Diese drei Punkte kosten
/// nichts und retten die meisten unbrauchbaren Aufnahmen.
class LichtCheckliste extends StatelessWidget {
  const LichtCheckliste({super.key});

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texte.lichtTitel,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(texte.lichtText),
        const SizedBox(height: AppTheme.gapM),
        _Punkt(
          icon: Icons.wb_sunny_outlined,
          titel: texte.lichtTageslicht,
          text: texte.lichtTageslichtText,
        ),
        const SizedBox(height: AppTheme.gapS),
        _Punkt(
          icon: Icons.auto_fix_off_outlined,
          titel: texte.lichtKeinFilter,
          text: texte.lichtKeinFilterText,
        ),
        const SizedBox(height: AppTheme.gapS),
        _Punkt(
          icon: Icons.back_hand_outlined,
          titel: texte.lichtRuhigeHand,
          text: texte.lichtRuhigeHandText,
        ),
      ],
    );
  }
}

class _Punkt extends StatelessWidget {
  const _Punkt({required this.icon, required this.titel, required this.text});

  final IconData icon;
  final String titel;
  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: farben.akzent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: farben.akzent, size: 20),
          ),
          const SizedBox(width: AppTheme.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                MutedText(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
