import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/datum.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../checkin/ui/widgets/checkin_karte.dart';

import '../../../history/logic/analysis_repository.dart';
import '../../logic/home_tab.dart';
import '../widgets/tab_leiste.dart';
import '../widgets/phase_karte.dart';

/// Tab „Plan" – die Antwort auf „Was steht drin?".
///
/// Die Zusammenfassung der Analyse, der nächste Check-in und der
/// Step-by-Step-Plan in drei Zeithorizonten. Die Tagesliste steht nicht hier,
/// sondern auf „Heute": Wer nachlesen will, liest; wer abhaken will, hakt ab
/// (DECISIONS 65).
class PlanTab extends ConsumerWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final analyse = ref.watch(aktuelleAnalyseProvider);

    if (analyse == null) {
      return TabInhalt(
        tab: HomeTab.plan,
        children: [
          const SizedBox(height: AppTheme.gapXl),
          Icon(Icons.flag_outlined, size: 48, color: farben.textSekundaer),
          const SizedBox(height: AppTheme.gapS),
          MutedText(texte.planLeer, align: TextAlign.center),
        ],
      );
    }

    final plan = analyse.plan;

    return TabInhalt(
      tab: HomeTab.plan,
      children: [
        SectionCard(
          title: texte.homeDeinPlan,
          icon: Icons.flag_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MutedText(
                texte.homePlanZeile(
                  Datum.relativ(
                    analyse.erstelltAm,
                    texte.localeName,
                    heute: texte.datumHeute,
                    gestern: texte.datumGestern,
                  ),
                  analyse.anzahlEmpfehlungen,
                ),
              ),
              if (analyse.gesichtsform.isNotEmpty) ...[
                const SizedBox(height: AppTheme.gapS),
                Text(
                  analyse.gesichtsform,
                  style: const TextStyle(height: 1.5),
                ),
              ],
              // Wann der naechste Check-in ansteht – die Gegenseite zur
              // Karte darunter, die erst auftaucht, wenn er faellig ist.
              const CheckinVorschau(),
              const SizedBox(height: AppTheme.gapM),
              // Der ganze Report ist ein eigener Bildschirm – hier steht nur
              // der Weg dorthin.
              OutlinedButton.icon(
                onPressed: () => context.push('${Routes.result}/${analyse.id}'),
                icon: const Icon(Icons.article_outlined),
                label: Text(texte.planReportOeffnen),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        // Der naechste Check-in mit der Moeglichkeit, ihn zu starten.
        const CheckinKarte(),
        if (plan.sofort.isNotEmpty) ...[
          PhaseKarte(
            titel: texte.planSofort,
            icon: Icons.bolt_outlined,
            schritte: plan.sofort,
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
        if (plan.dreissigTage.isNotEmpty) ...[
          PhaseKarte(
            titel: texte.planDreissigTage,
            icon: Icons.calendar_month_outlined,
            schritte: plan.dreissigTage,
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
        if (plan.langfristig.isNotEmpty)
          PhaseKarte(
            titel: texte.planLangfristig,
            icon: Icons.trending_up,
            schritte: plan.langfristig,
          ),
      ],
    );
  }
}
