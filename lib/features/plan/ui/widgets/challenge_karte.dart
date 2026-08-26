import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/wochen_challenge.dart';

/// Die Challenge der laufenden Woche.
///
/// Eine kleine Extra-Aufgabe über die Tagesliste hinaus, aus einem festen
/// Vorrat von zehn Vorlagen rotiert. Alles daran wird aus den vorhandenen
/// Haken gerechnet – kein Modellaufruf, keine Kosten.
///
/// Eine nicht geschaffte Challenge verschwindet am Montag kommentarlos. Es
/// gibt kein „leider verpasst": Die naechste steht schon da, und das ist die
/// einzige Nachricht, die hier hilft.
class ChallengeKarte extends ConsumerWidget {
  const ChallengeKarte({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(wochenChallengeProvider);
    if (challenge == null) return const SizedBox.shrink();

    final texte = context.texte;
    final farben = context.farben;
    final geschafft = challenge.geschafft;
    final farbe = geschafft ? farben.erfolg : farben.akzent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: SectionCard(
        title: texte.challengeTitel,
        icon: challenge.vorlage.icon,
        trailing: geschafft
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 18, color: farben.erfolg),
                  const SizedBox(width: 4),
                  Text(
                    texte.challengeGeschafft,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: farben.erfolg,
                    ),
                  ),
                ],
              )
            : Text(
                texte.challengeStand(challenge.stand, challenge.ziel),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: farben.akzent,
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.vorlage.art.text(texte, challenge.ziel),
              style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.gapS),
            Semantics(
              label: texte.challengeStand(challenge.stand, challenge.ziel),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: challenge.anteil,
                  minHeight: 8,
                  backgroundColor: farbe.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(farbe),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
