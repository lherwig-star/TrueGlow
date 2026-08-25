import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/einwilligung_controller.dart';
import '../models/einwilligung.dart';
import 'einwilligungs_auswahl.dart';
import '../../../core/l10n/texte.dart';

/// Erklärt, warum der Analyse-Bereich ohne Altersbestätigung zubleibt.
///
/// Der Weg dorthin ist eine Umleitung im Router: Wer den Analyse-Flow
/// aufruft, ohne bestätigt zu haben, landet hier statt vor einer stummen
/// Wand. Wer bestätigt, kommt sofort weiter; wer nicht will, geht mit einem
/// Knopf zurück ins Dashboard und kann den Rest der App normal benutzen.
class AltersHinweisScreen extends ConsumerWidget {
  const AltersHinweisScreen({super.key, this.ziel});

  /// Wohin es nach der Bestätigung weitergeht — die ursprünglich gewünschte
  /// Route. Ohne Angabe zurück aufs Dashboard.
  final String? ziel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final bestaetigt = ref.watch(volljaehrigBestaetigtProvider);

    return AppPage(
      title: texte.altersTitel,
      showBackButton: false,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: bestaetigt
                ? () => context.go(ziel ?? Routes.home)
                : null,
            child: Text(texte.altersWeiter),
          ),
          const SizedBox(height: AppTheme.gapXs),
          TextButton(
            onPressed: () => context.go(Routes.home),
            child: Text(texte.altersZurueck),
          ),
        ],
      ),
      children: [
        SectionCard(
          title: texte.altersWarumTitel,
          icon: Icons.info_outline,
          child: MutedText(texte.altersWarumText),
        ),
        const SizedBox(height: AppTheme.gapM),
        const EinwilligungsHaken(
          art: Einwilligungsart.mindestalter,
          kanal: Einwilligungskanal.nachtrag,
        ),
        const SizedBox(height: AppTheme.gapM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
          child: MutedText(texte.altersOhneText),
        ),
      ],
    );
  }
}
