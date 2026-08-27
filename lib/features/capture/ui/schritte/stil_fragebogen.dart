import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auswahl_chip.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../direction/logic/direction_controller.dart';
import '../../../direction/models/richtung.dart';
import '../../../modules/logic/module_controller.dart';
import '../../../modules/models/modul_eingaben.dart';

/// Kurzer Fragebogen fuer "Stil & Kleiderschrank".
///
/// Ueberarbeitet in DECISIONS 72: Die Stilrichtung ist dieselbe Liste wie bei
/// „Deine Richtung", und aus dem Dresscode ist die Frage geworden, wofuer der
/// Stil funktionieren soll.
class StilFragebogen extends ConsumerStatefulWidget {
  const StilFragebogen({super.key});

  @override
  ConsumerState<StilFragebogen> createState() => _StilFragebogenState();
}

class _StilFragebogenState extends ConsumerState<StilFragebogen> {
  @override
  void initState() {
    super.initState();
    // Vorbelegen aus „Deine Richtung" – aber erst nach dem ersten Bild:
    // Waehrend `build` laeuft, darf kein Provider beschrieben werden.
    //
    // Vorbelegen und nicht nur anzeigen: Sonst waere der erste Tipp auf einen
    // schon markierten Chip ein Abwaehlen von etwas, das nie gespeichert war.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final stil = ref.read(moduleControllerProvider).eingaben.stil;
      if (stil.ziele.isNotEmpty) return;

      final gewaehlt = ref.read(directionControllerProvider).ziele;
      if (gewaehlt.isEmpty) return;

      ref
          .read(moduleControllerProvider.notifier)
          .setzeStil(stil.copyWith(ziele: gewaehlt));
    });
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final stil = ref.watch(moduleControllerProvider).eingaben.stil;
    final ctrl = ref.read(moduleControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texte.stilFragebogenTitel,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(texte.stilFragebogenText),
        const SizedBox(height: AppTheme.gapM),

        // --- Stilrichtung: dieselbe Liste wie bei „Deine Richtung" ---
        _Frage(titel: texte.stilZiel, untertitel: texte.stilZielText),
        Wrap(
          spacing: AppTheme.gapS,
          runSpacing: AppTheme.gapS,
          children: [
            for (final ziel in Richtungsziel.values)
              AuswahlChip(
                label: ziel.label(texte),
                aktiv: stil.ziele.contains(ziel),
                onTap: () {
                  final neu = Set<Richtungsziel>.from(stil.ziele);
                  neu.contains(ziel) ? neu.remove(ziel) : neu.add(ziel);
                  ctrl.setzeStil(stil.copyWith(ziele: neu));
                },
              ),
          ],
        ),
        const SizedBox(height: AppTheme.gapL),

        // --- Wofuer der Stil funktionieren soll (ueberspringbar) ---
        _Frage(titel: texte.stilZweck, untertitel: texte.stilZweckText),
        Wrap(
          spacing: AppTheme.gapS,
          runSpacing: AppTheme.gapS,
          children: [
            for (final zweck in Alltagszweck.values)
              AuswahlChip(
                label: zweck.label(texte),
                aktiv: stil.zwecke.contains(zweck),
                onTap: () {
                  final neu = Set<Alltagszweck>.from(stil.zwecke);
                  neu.contains(zweck) ? neu.remove(zweck) : neu.add(zweck);
                  ctrl.setzeStil(stil.copyWith(zwecke: neu));
                },
              ),
          ],
        ),
        const SizedBox(height: AppTheme.gapL),

        // --- Budget ---
        _Frage(titel: texte.stilBudget),
        for (final budget in Kleidungsbudget.values)
          _Zeile(
            label: budget.label(texte),
            aktiv: stil.budget == budget,
            onTap: () => ctrl.setzeStil(stil.copyWith(budget: budget)),
          ),
        const SizedBox(height: AppTheme.gapL),

        // --- Pflegeaufwand ---
        _Frage(titel: texte.stilPflege),
        for (final aufwand in Pflegeaufwand.values)
          _Zeile(
            label: aufwand.label(texte),
            aktiv: stil.pflegeaufwand == aufwand,
            onTap: () => ctrl.setzeStil(stil.copyWith(pflegeaufwand: aufwand)),
          ),
      ],
    );
  }
}

class _Frage extends StatelessWidget {
  const _Frage({required this.titel, this.untertitel});

  final String titel;
  final String? untertitel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (untertitel != null) ...[
            const SizedBox(height: 2),
            MutedText(untertitel!),
          ],
        ],
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.label,
    required this.aktiv,
    required this.onTap,
  });

  final String label;
  final bool aktiv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.gapM,
            vertical: AppTheme.gapS + 2,
          ),
          decoration: BoxDecoration(
            color: aktiv
                ? farben.akzent.withValues(alpha: 0.10)
                : farben.flaeche,
            border: Border.all(
              color: aktiv ? farben.erreichtFlaeche : farben.kartenrand,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                aktiv
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: aktiv
                    ? farben.erreichtFlaeche
                    : farben.textSekundaer,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
