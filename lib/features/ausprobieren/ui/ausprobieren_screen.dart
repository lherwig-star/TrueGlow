import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/auswahl_chip.dart';
import '../../../core/widgets/section_card.dart';
import '../../modules/logic/module_controller.dart';
import '../../modules/models/analyse_modul.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../logic/ausprobieren_controller.dart';
import '../models/technik.dart';

/// Der optionale Schritt zwischen „Deine Richtung" und der Aufnahme.
///
/// Angeboten wird nur, was zu dieser Analyse passt: Techniken der gewaehlten
/// Module, gefiltert nach der Ausrichtung. Ein Gua Sha ohne Haut-Kapitel
/// haette im Report keinen Platz, und eine Bartbuerste im weiblichen Modus
/// waere derselbe Fehler, den die Nachbereitung fuer den Bart-Abschnitt
/// abfaengt.
///
/// Ueberspringbar, und zwar wirklich: Ohne Auswahl geht die Analyse
/// unveraendert los. Was die Tiefe der Empfehlungen angeht, haengt sie
/// ohnehin nicht an diesem Schritt – die Regel dafuer steht im Prompt und
/// gilt auch ohne einen einzigen Haken (DECISIONS 79).
class AusprobierenScreen extends ConsumerWidget {
  const AusprobierenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ref.watch(ausrichtungProvider);
    final module = ref.watch(moduleControllerProvider).module;
    final gewaehlt = ref.watch(ausprobierenControllerProvider);
    final ctrl = ref.read(ausprobierenControllerProvider.notifier);

    final angebot = Technik.angebot(module, ausrichtung);
    // Was nicht mehr angeboten wird, faellt aus der gemerkten Auswahl. Der
    // Aufruf steht bewusst nach dem Bauen der Liste und nicht im Controller:
    // Erst hier ist bekannt, was diese Analyse ueberhaupt umfasst.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ctrl.aufAngebotKuerzen(angebot),
    );

    final anzahl = gewaehlt.where(angebot.contains).length;

    return AppPage(
      title: texte.ausprobierenTitel,
      bottomFade: true,
      actions: [
        TextButton(
          onPressed: () => context.push(Routes.aufnahme),
          child: Text(texte.flowUeberspringen),
        ),
      ],
      bottomBar: FilledButton(
        onPressed: () => context.push(Routes.aufnahme),
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
        child: Text(texte.ausprobierenWeiter),
      ),
      children: [
        Text(
          texte.ausprobierenEyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: farben.akzent,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        Text(
          texte.ausprobierenUeberschrift,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(texte.ausprobierenEinleitung),
        const SizedBox(height: AppTheme.gapXs),
        MutedText(
          anzahl == 0
              ? texte.ausprobierenChipsText
              : texte.ausprobierenGewaehlt(anzahl),
        ),
        const SizedBox(height: AppTheme.gapL),

        if (angebot.isEmpty)
          MutedText(texte.ausprobierenNichts)
        else
          // Nach Kapiteln gegliedert, in Modul-Reihenfolge: Zwanzig Zeilen
          // am Stueck sind eine Wand, und die Ueberschrift sagt zugleich,
          // wo die Technik spaeter im Report landet.
          for (final modul in AnalyseModul.bestellbar)
            if (angebot.where((t) => t.modul == modul).toList()
                case final techniken when techniken.isNotEmpty) ...[
              Text(
                modul.titel(texte, ausrichtung),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppTheme.gapS),
              // Volle Breite, eine Form – dasselbe Raster wie bei den
              // Stilrichtungen (DECISIONS 61). Als Pillen fransten
              // unterschiedlich lange Namen wie „Rosmarinöl für die
              // Kopfhaut" und „Gua Sha" sofort aus.
              for (final technik in techniken) ...[
                AuswahlChip(
                  label: technik.label(texte),
                  untertext: technik.untertext(texte),
                  vollBreite: true,
                  aktiv: gewaehlt.contains(technik),
                  onTap: () => ctrl.umschalten(technik),
                ),
                const SizedBox(height: AppTheme.gapS),
              ],
              const SizedBox(height: AppTheme.gapM),
            ],
      ],
    );
  }
}
