import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/models/analyse_modul.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import 'widgets/kapitel_block.dart';

/// Ein einzelner Bereich des Reports, hinter einer Kachel (DECISIONS 89).
///
/// **Warum eine eigene Seite und kein Blatt von unten.** Ein Kapitel ist
/// lang – Einleitung, mehrere Sektionen, Empfehlungen, Produkte. Ein Blatt
/// müsste den Bildschirm fast ganz einnehmen und trüge dann einen eigenen
/// Scroll innerhalb eines Scrolls; das fühlt sich beim Wischen zäh an. Dazu
/// kommt ein handfestes Argument: Die Wissens-Erklärung ist selbst ein Blatt
/// von unten (DECISIONS 88), und ein Blatt über einem Blatt stapelt sich.
///
/// Eine Seite hat außerdem die Zurück-Taste ohne Zutun auf der richtigen
/// Seite, und die Übersicht darunter bleibt stehen – samt Scroll-Position.
class KapitelScreen extends ConsumerWidget {
  const KapitelScreen({
    super.key,
    required this.analyseId,
    required this.modulName,
  });

  final String analyseId;
  final String modulName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final ausrichtung = ref.watch(ausrichtungProvider);

    ref.watch(analysenProvider);
    final ergebnis = ref.watch(analysisRepositoryProvider).laden(analyseId);
    final modul = AnalyseModul.values
        .where((m) => m.name == modulName)
        .firstOrNull;
    final kapitel = modul == null
        ? null
        : ergebnis?.kapitel.where((k) => k.modul == modul).firstOrNull;

    if (kapitel == null) {
      return AppPage(
        title: texte.ergebnisTitel,
        children: [
          const SizedBox(height: AppTheme.gapXl),
          Icon(Icons.search_off, size: 48, color: context.farben.textSekundaer),
          const SizedBox(height: AppTheme.gapS),
          MutedText(texte.ergebnisNichtVorhanden, align: TextAlign.center),
        ],
      );
    }

    return AppPage(
      title: kapitel.titel(texte, ausrichtung),
      children: [
        // Der Wunsch in eigenen Worten steht über dem, was daraus geworden
        // ist – vollständig und nicht gekürzt (DECISIONS 90).
        if (kapitel.modul == AnalyseModul.persoenlicheZiele &&
            (ergebnis?.richtung.freitext.trim() ?? '').isNotEmpty) ...[
          _WunschZitat(text: ergebnis!.richtung.freitext.trim()),
          const SizedBox(height: AppTheme.gapM),
        ],
        KapitelBlock(kapitel: kapitel),
        const SizedBox(height: AppTheme.gapS),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
          child: MutedText(texte.disclaimerMedizin),
        ),
      ],
    );
  }
}

/// Der Freitext des Nutzers als Zitat über dem Zielkapitel.
///
/// Eigene Optik und keine gewöhnliche Karte: Das hier ist der einzige Text
/// auf der ganzen Seite, der nicht von der Analyse stammt, sondern vom
/// Nutzer selbst. Ein Zitat sieht man das an.
class _WunschZitat extends StatelessWidget {
  const _WunschZitat({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return Container(
      padding: const EdgeInsets.all(AppTheme.gapM),
      decoration: BoxDecoration(
        color: farben.flaecheHoch,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border(left: BorderSide(color: farben.akzent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, size: 18, color: farben.akzent),
              const SizedBox(width: 6),
              Text(
                texte.ergebnisDeinWunsch,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: farben.textSekundaer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapXs),
          Text(
            text,
            style: const TextStyle(
              height: 1.55,
              fontSize: 15.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
