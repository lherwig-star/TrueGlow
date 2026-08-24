import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/module_controller.dart';
import '../models/analyse_modul.dart';
import 'widgets/modul_karte.dart';

/// Auswahl der Analyse-Bausteine vor der Aufnahme.
///
/// Die Basis ist gesetzt; alles Weitere entscheidet der Nutzer hier und kann
/// es spaeter ueber "Analyse erweitern" nachholen.
class ModuleSelectionScreen extends ConsumerWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zustand = ref.watch(moduleControllerProvider);
    final farben = context.farben;
    final anzahl = zustand.anzahlZusatzModule;

    return AppPage(
      title: S.moduleTitel,
      bottomFade: true,
      bottomBar: FilledButton(
        // Naechster Schritt ist "Deine Richtung"; von dort geht es – mit oder
        // ohne Eingabe – weiter in die Aufnahme.
        onPressed: () => context.push(Routes.richtung),
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
        child: Text(
          anzahl == 0
              ? S.moduleStartBasis
              : '${S.moduleStartBasis} + $anzahl ${anzahl == 1 ? 'Modul' : 'Module'}',
        ),
      ),
      children: [
        Text(
          S.moduleEyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: farben.akzentZwei,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        const Text(
          S.moduleUeberschrift,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        const MutedText(S.moduleEinleitung),
        const SizedBox(height: AppTheme.gapM),
        ModulKarte(
          modul: AnalyseModul.basis,
          ausgewaehlt: true,
          mitCheckbox: false,
          badge: S.moduleBasisBadge,
          onTap: null,
        ),
        const SizedBox(height: AppTheme.gapS),
        for (final modul in AnalyseModul.waehlbare) ...[
          ModulKarte(
            modul: modul,
            ausgewaehlt: zustand.enthaelt(modul),
            onTap: () =>
                ref.read(moduleControllerProvider.notifier).umschalten(modul),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
      ],
    );
  }
}
