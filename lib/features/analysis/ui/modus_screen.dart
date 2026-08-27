import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/modus_controller.dart';
import '../models/analyse_modus.dart';

/// Der erste Schritt jeder Analyse: Welche Frage soll sie beantworten?
///
/// Zwei Karten, eine Entscheidung, kein Überspringen. Die Frage ist zu
/// grundlegend, um sie im Vorbeigehen zu setzen: Sie entscheidet, ob der
/// Report den vorhandenen Look verbessert oder einen neuen entwirft. Ein
/// stiller Standard hätte für die Hälfte der Nutzer den falschen Report
/// erzeugt – und die Hälfte wäre die gewesen, die Veränderung sucht.
///
/// Beide Karten sind gleich groß und gleich betont. Keiner der Modi ist der
/// bessere; „verfeinern" steht nur zuerst, weil es das Bekannte ist.
class ModusScreen extends ConsumerWidget {
  const ModusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final gewaehlt = ref.watch(modusControllerProvider);

    return AppPage(
      title: texte.modusTitel,
      bottomFade: true,
      bottomBar: FilledButton(
        onPressed: () => context.push(Routes.module),
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
        child: Text(texte.modusWeiter),
      ),
      children: [
        Text(
          texte.modusEyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: farben.akzentZwei,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        Text(
          texte.modusUeberschrift,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(texte.modusEinleitung),
        const SizedBox(height: AppTheme.gapM),
        for (final modus in AnalyseModus.values) ...[
          _ModusKarte(
            modus: modus,
            ausgewaehlt: modus == gewaehlt,
            onTap: () =>
                ref.read(modusControllerProvider.notifier).waehlen(modus),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
        const SizedBox(height: AppTheme.gapXs),
        // Die zwei Sätze, die jede Rückfrage vorwegnehmen: Kostet das
        // doppelt? Muss ich andere Fotos machen?
        MutedText(texte.modusHinweis),
      ],
    );
  }
}

/// Eine der beiden Karten.
///
/// Bewusst kein [ModulKarte]-Nachbau mit Checkbox: Hier wird nicht
/// zusammengestellt, sondern entschieden. Deshalb ein Radio-Punkt – er sagt
/// „eines von beiden" schon durch seine Form.
class _ModusKarte extends StatelessWidget {
  const _ModusKarte({
    required this.modus,
    required this.ausgewaehlt,
    required this.onTap,
  });

  final AnalyseModus modus;
  final bool ausgewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final karte = Theme.of(context).cardTheme.color ?? farben.flaeche;

    return Semantics(
      selected: ausgewaehlt,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: AnimatedContainer(
            duration:
                AppTheme.animation(context, const Duration(milliseconds: 180)),
            padding: const EdgeInsets.all(AppTheme.gapM),
            decoration: BoxDecoration(
              color: ausgewaehlt
                  ? Color.alphaBlend(
                      farben.erreicht.withValues(alpha: 0.10),
                      karte,
                    )
                  : karte,
              border: Border.all(
                color: ausgewaehlt ? farben.erreicht : farben.kartenrand,
                width: ausgewaehlt ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: farben.akzent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(modus.icon, size: 24, color: farben.akzent),
                ),
                const SizedBox(width: AppTheme.gapS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modus.titel(texte),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modus.beschreibung(texte),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: farben.textSekundaer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.gapXs),
                _Punkt(aktiv: ausgewaehlt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Der Radio-Punkt. Rund, damit er sich vom eckigen Haken der Modulauswahl
/// unterscheidet – dort darf man mehreres, hier genau eines.
class _Punkt extends StatelessWidget {
  const _Punkt({required this.aktiv});

  final bool aktiv;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AnimatedContainer(
      duration: AppTheme.animation(context, const Duration(milliseconds: 180)),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: aktiv ? farben.erreicht : farben.textSekundaer,
          width: aktiv ? 7 : 1.6,
        ),
      ),
    );
  }
}
