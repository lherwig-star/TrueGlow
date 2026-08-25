import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../analysis/logic/kontingent.dart';
import '../logic/module_controller.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../../onboarding/models/onboarding_profile.dart';
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
    final texte = context.texte;
    final ausrichtung = ref.watch(ausrichtungProvider);
    final zustand = ref.watch(moduleControllerProvider);
    final farben = context.farben;
    final anzahl = zustand.anzahlZusatzModule;

    // Der Kontingentstand ist ein Hinweis, keine Sperre – massgeblich bleibt
    // die Cloud Function. `null` heisst „unbekannt" (Demo, offline, nicht
    // angemeldet) und darf niemanden aufhalten.
    final kontingent = ref.watch(kontingentProvider).valueOrNull;
    final gesperrt = kontingent?.erschoepft ?? false;

    return AppPage(
      title: texte.moduleTitel,
      bottomFade: true,
      bottomBar: FilledButton(
        // Naechster Schritt ist "Deine Richtung"; von dort geht es – mit oder
        // ohne Eingabe – weiter in die Aufnahme.
        onPressed: gesperrt ? null : () => context.push(Routes.richtung),
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
        child: Text(
          anzahl == 0
              ? texte.moduleStartBasis
              : '${texte.moduleStartBasis} + $anzahl ${anzahl == 1 ? 'Modul' : 'Module'}',
        ),
      ),
      children: [
        Text(
          texte.moduleEyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: farben.akzentZwei,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        Text(
          texte.moduleUeberschrift,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        // „Bart" steht in der Einleitung nur, wenn er auch im Report steht.
        MutedText(
          ausrichtung == Ausrichtung.weiblich
              ? texte.moduleEinleitungOhneBart
              : texte.moduleEinleitung,
        ),
        if (kontingent != null) ...[
          const SizedBox(height: AppTheme.gapM),
          if (kontingent.erschoepft)
            SectionCard(
              icon: Icons.hourglass_empty,
              title: kontingent.monatsgrenzeErreicht
                  ? texte.kontingentMonatsgrenze
                  : texte.kontingentTagesgrenze,
              child: MutedText(
                kontingent.monatsgrenzeErreicht
                    ? texte.kontingentMonatsgrenzeText
                    : texte.kontingentTagesgrenzeText,
              ),
            )
          else
            MutedText(
              texte.kontingentUebrig(
                kontingent.tagUebrig,
                KontingentStand.proTag,
              ),
            ),
        ],
        const SizedBox(height: AppTheme.gapM),
        ModulKarte(
          modul: AnalyseModul.basis,
          ausgewaehlt: true,
          mitCheckbox: false,
          badge: texte.moduleBasisBadge,
          onTap: null,
        ),
        const SizedBox(height: AppTheme.gapS),
        for (final modul in AnalyseModul.waehlbareFuer(ausrichtung)) ...[
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
