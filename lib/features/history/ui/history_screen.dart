import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/datum.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../analysis/models/analyse_modus.dart';
import '../../analysis/models/analysis_result.dart';
import '../logic/analysis_repository.dart';

/// Liste vergangener Analysen, neueste zuerst.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final analysen = ref.watch(analysenProvider);

    return AppPage(
      title: texte.verlaufTitel,
      children: [
        if (analysen.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.gapXl),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: context.farben.textSekundaer,
                ),
                const SizedBox(height: AppTheme.gapS),
                MutedText(texte.verlaufLeer, align: TextAlign.center),
              ],
            ),
          )
        else
          for (final analyse in analysen)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.gapS),
              child: _VerlaufKarte(
                analyse: analyse,
                onOeffnen: () =>
                    context.push('${Routes.result}/${analyse.id}'),
                onLoeschen: () => _loeschen(context, ref, analyse),
              ),
            ),
      ],
    );
  }

  Future<void> _loeschen(
    BuildContext context,
    WidgetRef ref,
    AnalysisResult analyse,
  ) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.texte.verlaufLoeschenTitel),
        content: Text(
          context.texte.verlaufLoeschenText(
            Datum.kurz(analyse.erstelltAm, context.texte.localeName),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.texte.abbrechen),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.farben.warnung,
            ),
            child: Text(context.texte.loeschen),
          ),
        ],
      ),
    );

    if (bestaetigt != true) return;
    await ref.read(analysenProvider.notifier).loeschen(analyse.id);
  }
}

class _VerlaufKarte extends StatelessWidget {
  const _VerlaufKarte({
    required this.analyse,
    required this.onOeffnen,
    required this.onLoeschen,
  });

  final AnalysisResult analyse;
  final VoidCallback onOeffnen;
  final VoidCallback onLoeschen;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return SectionCard(
      onTap: onOeffnen,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: farben.akzent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 20,
              color: farben.akzent,
            ),
          ),
          const SizedBox(width: AppTheme.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        Datum.kurz(analyse.erstelltAm, texte.localeName),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ModusEtikett(modus: analyse.modus),
                  ],
                ),
                const SizedBox(height: 2),
                MutedText(
                  texte.verlaufZeile(
                    analyse.sektionen.length,
                    analyse.anzahlEmpfehlungen,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLoeschen,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: farben.textSekundaer,
            tooltip: texte.verlaufLoeschenTooltip,
          ),
        ],
      ),
    );
  }
}

/// Das kleine Etikett am Verlaufseintrag: verfeinert oder neu entdeckt.
///
/// Steht an jedem Eintrag, auch am verfeinernden. Nur den einen zu
/// kennzeichnen hiesse, den anderen zur Norm zu erklaeren – und dann waere
/// ein Report ohne Etikett zweideutig: alter Report oder verfeinert?
///
/// Der entdeckende Modus traegt die Farbe fuer Erreichtes, der verfeinernde
/// den ruhigen Sekundaerton. Das ist keine Wertung, sondern Wiedererkennung:
/// Dieselbe Farbe markiert im Report den Abschnitt "Dein neuer Look".
class _ModusEtikett extends StatelessWidget {
  const _ModusEtikett({required this.modus});

  final AnalyseModus modus;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final ton = modus.istEntdecken ? farben.erreicht : farben.textSekundaer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ton.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        modus.etikett(context.texte),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: ton,
        ),
      ),
    );
  }
}
