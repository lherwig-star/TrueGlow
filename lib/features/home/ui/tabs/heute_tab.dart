import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../analysis/ui/unterbrochen_karte.dart';
import '../../../history/logic/analysis_repository.dart';
import '../../../plan/ui/widgets/challenge_karte.dart';
import '../../../plan/ui/widgets/checkliste_karte.dart';
import '../../../streak/ui/widgets/streak_karte.dart';
import '../../logic/home_tab.dart';
import '../widgets/tab_leiste.dart';

/// Tab „Heute" – die Antwort auf „Was mache ich jetzt?".
///
/// Hier steht alles, was man täglich abhakt, und sonst nichts: die Serie, die
/// Wochen-Challenge und die vollständige Tagesliste über alle Kapitel. Der
/// Plan mit seinen Empfehlungen liegt einen Tab weiter — wer abhaken will,
/// soll nicht daran vorbeiscrollen (DECISIONS 65).
class HeuteTab extends ConsumerWidget {
  const HeuteTab({super.key, required this.onNeueAnalyse});

  /// Der Einstieg in die erste Analyse. Er lebt in der Hülle, weil er
  /// mehrere Zustände zurücksetzt.
  final VoidCallback onNeueAnalyse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final analyse = ref.watch(aktuelleAnalyseProvider);

    if (analyse == null) return _Leer(onStarten: onNeueAnalyse);

    return TabInhalt(
      tab: HomeTab.heute,
      children: [
        // Steht ganz oben und nur, wenn es etwas zu sagen gibt: Ein
        // Programmlauf, der mitten in der Analyse endete, hinterlaesst sonst
        // gar keine Spur.
        const UnterbrochenKarte(),
        const StreakKarte(),
        const SizedBox(height: AppTheme.gapS),
        const ChallengeKarte(),
        const SizedBox(height: AppTheme.gapM),
        // Eine Checkliste pro Kapitel – die Ueberschrift nennt den Bereich.
        // „Deine Ziele" ist eines davon und steht deshalb hier mit drin.
        for (final kapitel in analyse.checklisten) ...[
          ChecklisteKarte(kapitel: kapitel),
          const SizedBox(height: AppTheme.gapS),
        ],
        if (analyse.checklisten.isEmpty)
          SectionCard(
            title: texte.heuteKeineAufgabenTitel,
            icon: Icons.checklist_rtl,
            child: MutedText(texte.heuteKeineAufgabenText),
          ),
      ],
    );
  }
}

/// Der Zustand vor der ersten Analyse.
class _Leer extends StatelessWidget {
  const _Leer({required this.onStarten});

  final VoidCallback onStarten;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return TabInhalt(
      tab: HomeTab.heute,
      children: [
        const UnterbrochenKarte(),
        const SizedBox(height: AppTheme.gapL),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: farben.akzent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 42, color: farben.akzent),
          ),
        ),
        const SizedBox(height: AppTheme.gapM),
        Text(
          texte.homeLeerTitel,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapM),
          child: MutedText(texte.homeLeerText, align: TextAlign.center),
        ),
        const SizedBox(height: AppTheme.gapL),
        Center(
          child: FilledButton.icon(
            onPressed: onStarten,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(texte.homeAnalyseStarten),
          ),
        ),
      ],
    );
  }
}
