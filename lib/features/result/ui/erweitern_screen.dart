import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/logic/module_controller.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/ui/widgets/modul_karte.dart';
import '../../onboarding/logic/onboarding_controller.dart';

/// Die noch nicht analysierten Bereiche, mit den ausführlichen Modul-Karten.
///
/// **Warum eine eigene Seite (DECISIONS 90).** Diese Karten standen unter dem
/// Report. Drei große Karten mit Erklärtext waren dort zusammen höher als
/// alle Inhalts-Kacheln darüber — die Seite endete mit dem, was noch fehlt,
/// statt mit dem, was da ist. Im Report steht jetzt eine einzige, ruhige
/// Karte, und wer wirklich erweitern will, findet hier alles Nötige.
class ErweiternScreen extends ConsumerWidget {
  const ErweiternScreen({super.key, required this.analyseId});

  final String analyseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ref.watch(ausrichtungProvider);

    ref.watch(analysenProvider);
    final ergebnis = ref.watch(analysisRepositoryProvider).laden(analyseId);
    final offene = ergebnis == null
        ? const <AnalyseModul>[]
        : AnalyseModul.waehlbareFuer(ausrichtung)
            .where((m) => !ergebnis.module.contains(m))
            .toList();

    return AppPage(
      title: texte.moduleErweitern,
      children: [
        MutedText(texte.moduleErweiternText),
        const SizedBox(height: AppTheme.gapM),
        if (offene.isEmpty)
          MutedText(texte.ergebnisAlleBereiche)
        else
          for (final modul in offene) ...[
            ModulKarte(
              modul: modul,
              mitCheckbox: false,
              aktion: Icon(Icons.arrow_forward, color: farben.akzent, size: 20),
              onTap: () {
                // Auswahl merken, damit das Modul danach als Teil der Analyse
                // gilt und nicht erneut angeboten wird.
                ref.read(moduleControllerProvider.notifier).ergaenzen(modul);
                context.push(Routes.aufnahmeFuer(modul));
              },
            ),
            const SizedBox(height: AppTheme.gapS),
          ],
        const SizedBox(height: AppTheme.gapM),
      ],
    );
  }
}
