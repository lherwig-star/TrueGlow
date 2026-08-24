import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../analysis/models/analysis_result.dart';
import '../../history/logic/analysis_repository.dart';
import '../logic/plan_progress_repository.dart';
import '../../streak/ui/widgets/streak_karte.dart';
import 'widgets/checkliste_karte.dart';

/// Step-by-Step-Plan plus taegliche Checkliste. Der Fortschritt liegt lokal
/// in Hive und ueberlebt einen Neustart.
///
/// Der Plan ist der Endpunkt des Foto-Flows: von hier fuehren sowohl der
/// Button als auch die System-Zurueck-Geste direkt aufs Dashboard, statt den
/// Nutzer rueckwaerts durch Analyse und Fotos zu schicken.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyse = ref.watch(aktuelleAnalyseProvider);
    final fortschritt = ref.watch(planFortschrittProvider);
    final farben = context.farben;

    // canPop: false faengt Wischgeste und AppBar-Zurueck gleichermassen ab –
    // beide laufen ueber Navigator.maybePop.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: AppPage(
        title: S.planTitel,
        bottomBar: FilledButton.icon(
          onPressed: () => context.go(Routes.home),
          icon: const Icon(Icons.home_outlined),
          label: const Text(S.planFertigZurStartseite),
        ),
        children: analyse == null
            ? [
                const SizedBox(height: AppTheme.gapXl),
                Icon(
                  Icons.flag_outlined,
                  size: 48,
                  color: farben.textSekundaer,
                ),
                const SizedBox(height: AppTheme.gapS),
                const MutedText(
                  'Noch kein Plan vorhanden. Starte zuerst eine Analyse.',
                  align: TextAlign.center,
                ),
              ]
            : _inhalt(context, ref, analyse, fortschritt),
      ),
    );
  }

  List<Widget> _inhalt(
    BuildContext context,
    WidgetRef ref,
    AnalysisResult analyse,
    PlanFortschritt fortschritt,
  ) {
    final plan = analyse.plan;

    return [
      const StreakKarte(),
      const SizedBox(height: AppTheme.gapS),
      // Eine Checkliste pro Kapitel, in Kapitel-Reihenfolge.
      for (final kapitel in analyse.checklisten) ...[
        ChecklisteKarte(kapitel: kapitel),
        const SizedBox(height: AppTheme.gapS),
      ],
      if (plan.sofort.isNotEmpty) ...[
        _PhaseKarte(
          titel: S.planSofort,
          icon: Icons.bolt_outlined,
          schritte: plan.sofort,
        ),
        const SizedBox(height: AppTheme.gapS),
      ],
      if (plan.dreissigTage.isNotEmpty) ...[
        _PhaseKarte(
          titel: S.planDreissigTage,
          icon: Icons.calendar_month_outlined,
          schritte: plan.dreissigTage,
        ),
        const SizedBox(height: AppTheme.gapS),
      ],
      if (plan.langfristig.isNotEmpty)
        _PhaseKarte(
          titel: S.planLangfristig,
          icon: Icons.trending_up,
          schritte: plan.langfristig,
        ),
    ];
  }
}

class _PhaseKarte extends StatelessWidget {
  const _PhaseKarte({
    required this.titel,
    required this.icon,
    required this.schritte,
  });

  final String titel;
  final IconData icon;
  final List<String> schritte;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return SectionCard(
      title: titel,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < schritte.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.gapXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 1, right: 10),
                    decoration: BoxDecoration(
                      color: farben.flaecheHoch,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: farben.akzent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      schritte[i],
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
