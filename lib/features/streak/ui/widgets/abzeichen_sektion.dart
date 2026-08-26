import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/streak_repository.dart';
import '../../models/abzeichen.dart';
import '../../../../core/l10n/texte.dart';

/// Uebersicht aller Meilensteine: erreichte farbig, offene ausgegraut mit
/// Hinweis, was noch fehlt.
class AbzeichenSektion extends ConsumerWidget {
  const AbzeichenSektion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staende = ref.watch(abzeichenProvider);
    final rekord = ref.watch(streakProvider).rekord;
    final erreicht = staende.where((s) => s.erreicht).length;

    return SectionCard(
      title: 'Deine Abzeichen',
      icon: Icons.emoji_events_outlined,
      trailing: Text(
        '$erreicht/${staende.length}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: context.farben.akzent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rekord > 0) ...[
            MutedText('Rekord: $rekord ${rekord == 1 ? 'Tag' : 'Tage'}'),
            const SizedBox(height: AppTheme.gapS),
          ],
          for (final stand in staende)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.gapXs),
              child: _AbzeichenZeile(stand: stand),
            ),
        ],
      ),
    );
  }
}

class _AbzeichenZeile extends StatelessWidget {
  const _AbzeichenZeile({required this.stand});

  final AbzeichenStand stand;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final erreicht = stand.erreicht;
    final farbe = erreicht ? farben.akzent : farben.textSekundaer;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: farbe.withValues(alpha: erreicht ? 0.16 : 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: erreicht ? farben.akzent : farben.rand,
            ),
          ),
          child: Icon(stand.abzeichen.icon, size: 20, color: farbe),
        ),
        const SizedBox(width: AppTheme.gapS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stand.abzeichen.titel(texte),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: erreicht ? farben.textPrimaer : farben.textSekundaer,
                ),
              ),
              if (!stand.erreicht) ...[
                const SizedBox(height: 1),
                Text(
                  _fortschritt(stand, texte),
                  style: TextStyle(
                    fontSize: 13,
                    color: farben.textSekundaer,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (erreicht)
          Icon(Icons.check_circle, size: 20, color: farben.erfolg),
      ],
    );
  }
}

/// Was einem noch nicht erreichten Abzeichen fehlt.
///
/// Der Satz haengt am Abzeichen: Bei „Alles freigeschaltet" sind es Module,
/// bei den Streak-Zielen Tage, und die erste Analyse ist gar keine Zahl,
/// sondern eine Aufforderung.
String _fortschritt(AbzeichenStand stand, L texte) => switch (stand.abzeichen) {
      Abzeichen.ersteAnalyse => texte.abzeichenErsteAnalyseOffen,
      Abzeichen.alleModule => texte.abzeichenNochModule(stand.fehlend),
      Abzeichen.challenges => texte.abzeichenNochChallenges(stand.fehlend),
      _ => texte.abzeichenNochTage(stand.fehlend),
    };
