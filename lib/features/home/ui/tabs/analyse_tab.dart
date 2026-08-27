import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/datum.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../analysis/logic/kontingent.dart';
import '../../../analysis/models/analyse_modus.dart';
import '../../../analysis/models/analysis_result.dart';
import '../../../history/logic/analysis_repository.dart';
import '../../logic/home_tab.dart';
import '../widgets/tab_leiste.dart';

/// Tab „Analyse" – die Antwort auf „neu vermessen".
///
/// Die Kernfunktion der App stand bis DECISIONS 65 als Knopf ganz unten auf
/// einer sehr langen Startseite. Jetzt hat sie einen eigenen Tab, und der
/// Stand des Tageskontingents steht darüber statt versteckt in der
/// Modulauswahl.
class AnalyseTab extends ConsumerWidget {
  const AnalyseTab({super.key, required this.onNeueAnalyse});

  final VoidCallback onNeueAnalyse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final analysen = ref.watch(analysenProvider);

    // `null` heisst „unbekannt" (Demo, offline, nicht angemeldet) und darf
    // niemanden aufhalten – massgeblich bleibt die Cloud Function.
    final kontingent = ref.watch(kontingentProvider).valueOrNull;

    return TabInhalt(
      tab: HomeTab.analyse,
      children: [
        _Kontingent(stand: kontingent),
        const SizedBox(height: AppTheme.gapM),
        FilledButton.icon(
          onPressed: (kontingent?.erschoepft ?? false) ? null : onNeueAnalyse,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(texte.homeNeueAnalyse),
        ),
        const SizedBox(height: AppTheme.gapL),
        Text(
          texte.verlaufTitel,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        if (analysen.isEmpty)
          MutedText(texte.verlaufLeer)
        else
          for (final analyse in analysen) ...[
            VerlaufKarte(
              analyse: analyse,
              onOeffnen: () => context.push('${Routes.result}/${analyse.id}'),
              onLoeschen: () => loescheAnalyse(context, ref, analyse),
            ),
            const SizedBox(height: AppTheme.gapS),
          ],
      ],
    );
  }
}

/// Der Stand des Tageskontingents – die Zahl, die vor jedem Start zählt.
class _Kontingent extends StatelessWidget {
  const _Kontingent({required this.stand});

  final KontingentStand? stand;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final s = stand;

    if (s == null) {
      // Ohne Konto oder ohne Netz gibt es keine Zahl. Dann steht hier nichts
      // Falsches, sondern gar nichts.
      return SectionCard(
        icon: Icons.auto_awesome_outlined,
        title: texte.analyseTabTitel,
        child: MutedText(texte.analyseTabEinleitung),
      );
    }

    if (s.erschoepft) {
      return SectionCard(
        icon: Icons.hourglass_empty,
        title: s.monatsgrenzeErreicht
            ? texte.kontingentMonatsgrenze
            : texte.kontingentTagesgrenze,
        child: MutedText(
          s.monatsgrenzeErreicht
              ? texte.kontingentMonatsgrenzeText
              : texte.kontingentTagesgrenzeText,
        ),
      );
    }

    return SectionCard(
      icon: Icons.auto_awesome_outlined,
      title: texte.analyseTabTitel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texte.kontingentUebrig(s.tagUebrig, KontingentStand.proTag),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: farben.akzent,
            ),
          ),
          const SizedBox(height: 2),
          MutedText(texte.kontingentMonatUebrig(s.monatUebrig)),
        ],
      ),
    );
  }
}

/// Ein Eintrag im Analyse-Verlauf.
///
/// Wortgleich aus `history_screen.dart` übernommen und nur nicht mehr privat
/// (DECISIONS 65) – der Verlauf lebt jetzt in diesem Tab.
class VerlaufKarte extends StatelessWidget {
  const VerlaufKarte({
    super.key,
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
class _ModusEtikett extends StatelessWidget {
  const _ModusEtikett({required this.modus});

  final AnalyseModus modus;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final ton = modus.istEntdecken ? farben.erreicht : farben.textSekundaer;
    final flaeche =
        modus.istEntdecken ? farben.erreichtFlaeche : farben.textSekundaer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: flaeche.withValues(alpha: 0.14),
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

/// Fragt nach und löscht dann. Aus `history_screen.dart` übernommen.
Future<void> loescheAnalyse(
  BuildContext context,
  WidgetRef ref,
  AnalysisResult analyse,
) async {
  final texte = context.texte;
  final bestaetigt = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(texte.verlaufLoeschenTitel),
      content: Text(
        texte.verlaufLoeschenText(
          Datum.kurz(analyse.erstelltAm, texte.localeName),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(texte.abbrechen),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: context.farben.warnung,
          ),
          child: Text(texte.loeschen),
        ),
      ],
    ),
  );

  if (bestaetigt != true) return;
  await ref.read(analysenProvider.notifier).loeschen(analyse.id);
}
