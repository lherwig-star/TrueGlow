import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auswahl_chip.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../modules/logic/module_controller.dart';
import '../../../modules/models/modul_eingaben.dart';

/// Kurzer Fragebogen fuer "Stil & Kleiderschrank".
class StilFragebogen extends ConsumerWidget {
  const StilFragebogen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        // --- Stilziel: Mehrfachauswahl als Chips ---
        _Frage(titel: texte.stilZiel, untertitel: texte.stilZielText),
        Wrap(
          spacing: AppTheme.gapS,
          runSpacing: AppTheme.gapS,
          children: [
            for (final ziel in Stilziel.values)
              AuswahlChip(
                label: ziel.label(texte),
                aktiv: stil.ziele.contains(ziel),
                onTap: () {
                  final neu = Set<Stilziel>.from(stil.ziele);
                  neu.contains(ziel) ? neu.remove(ziel) : neu.add(ziel);
                  ctrl.setzeStil(stil.copyWith(ziele: neu));
                },
              ),
          ],
        ),
        const SizedBox(height: AppTheme.gapL),

        // --- Dresscode ---
        _Frage(titel: texte.stilDresscode),
        for (final code in Dresscode.values)
          _Zeile(
            label: code.label(texte),
            aktiv: stil.dresscode == code,
            onTap: () => ctrl.setzeStil(stil.copyWith(dresscode: code)),
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
            border: Border.all(color: aktiv ? farben.akzent : farben.rand),
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
                color: aktiv ? farben.akzent : farben.textSekundaer,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
