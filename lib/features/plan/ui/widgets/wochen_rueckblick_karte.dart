import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/datum.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../modules/models/analyse_modul.dart';
import '../../../onboarding/logic/onboarding_controller.dart';
import '../../logic/wochen_rueckblick.dart';

/// Der Wochen-Rueckblick auf der Startseite.
///
/// Steht Sonntagabend bis Montagabend und verschwindet danach von selbst.
/// Alles darin kommt aus den Haken, die ohnehin gespeichert sind – kein
/// Modellaufruf, keine Kosten.
///
/// Der Ton ist bei jeder Bilanz anerkennend. Eine Woche ohne einen einzigen
/// Haken bekommt keine Kritik, sondern eine Einladung; wer nach einer
/// schlechten Woche eine Rechnung praesentiert bekommt, macht die App nicht
/// wieder auf.
class WochenRueckblickKarte extends ConsumerWidget {
  const WochenRueckblickKarte({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bilanz = ref.watch(wochenRueckblickProvider);
    if (bilanz == null) return const SizedBox.shrink();

    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ref.watch(ausrichtungProvider);
    final sprache = texte.localeName;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: SectionCard(
        title: texte.rueckblickTitel,
        icon: Icons.insights_outlined,
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: texte.rueckblickSchliessen,
          visualDensity: VisualDensity.compact,
          color: farben.textSekundaer,
          onPressed: () =>
              ref.read(wochenRueckblickProvider.notifier).weggeklickt(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MutedText(
              texte.rueckblickZeitraum(
                Datum.nurTag(bilanz.montag, sprache),
                Datum.nurTag(bilanz.sonntag, sprache),
              ),
            ),
            const SizedBox(height: AppTheme.gapS),
            _Zeile(
              icon: Icons.event_available_outlined,
              text: texte.rueckblickAktiveTage(bilanz.aktiveTage),
              stark: true,
            ),
            _Zeile(
              icon: Icons.check_circle_outline,
              text: texte.rueckblickAufgaben(bilanz.aufgaben),
            ),
            // Ohne einen einzigen Haken gibt es keinen staerksten Bereich.
            // Eine Zeile "Dein staerkster Bereich: –" waere Hohn.
            if (bilanz.staerksterBereich case final modul?)
              _Zeile(
                icon: modul.icon,
                text: texte.rueckblickStaerkster(
                  modul.checkliste(texte, ausrichtung),
                ),
              ),
            const SizedBox(height: AppTheme.gapS),
            Text(
              switch (tonFuer(bilanz.aktiveTage)) {
                Wochenton.stark => texte.rueckblickTonStark,
                Wochenton.solide => texte.rueckblickTonSolide,
                Wochenton.klein => texte.rueckblickTonKlein,
                Wochenton.leer => texte.rueckblickTonLeer,
              },
              style: TextStyle(
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: farben.akzent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({required this.icon, required this.text, this.stark = false});

  final IconData icon;
  final String text;
  final bool stark;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: farben.textSekundaer),
          const SizedBox(width: AppTheme.gapS),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.4,
                fontWeight: stark ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
