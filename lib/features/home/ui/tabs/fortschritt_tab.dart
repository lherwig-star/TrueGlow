import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../checkin/ui/widgets/fortschritt_karte.dart';
import '../../../plan/ui/widgets/wochen_rueckblick_karte.dart';
import '../../../streak/logic/streak_repository.dart';
import '../../../streak/ui/widgets/abzeichen_sektion.dart';
import '../../logic/home_tab.dart';
import '../widgets/tab_leiste.dart';

/// Tab „Fortschritt" – die Antwort auf „Was habe ich geschafft?".
///
/// Das Abzeichen-Regal, die Rekordserie, der Wochen-Rückblick und das
/// Foto-Album mit dem Vorher-nachher-Vergleich. Alles, was zurückblickt, an
/// einer Stelle — bis DECISIONS 65 lag es über drei Bildschirme verteilt.
class FortschrittTab extends ConsumerWidget {
  const FortschrittTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final streak = ref.watch(streakProvider);

    return TabInhalt(
      tab: HomeTab.fortschritt,
      children: [
        // Sonntagabend bis Montagabend, danach von selbst wieder weg.
        const WochenRueckblickKarte(),
        _Rekord(aktuell: streak.aktuell, rekord: streak.rekord),
        const SizedBox(height: AppTheme.gapS),
        const AbzeichenSektion(),
        const SizedBox(height: AppTheme.gapS),
        // Nur da, wenn es ueberhaupt ein Foto auf diesem Geraet gibt.
        const FortschrittKarte(),
        const SizedBox(height: AppTheme.gapS),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
          child: MutedText(texte.fortschrittTabHinweis),
        ),
      ],
    );
  }
}

/// Laufende Serie und Rekord nebeneinander.
///
/// Die Streak-Karte selbst steht auf „Heute" – dort gehört sie hin, weil sie
/// zum Abhaken auffordert. Hier steht die Bilanz: zwei Zahlen, kein Appell.
class _Rekord extends StatelessWidget {
  const _Rekord({required this.aktuell, required this.rekord});

  final int aktuell;
  final int rekord;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;

    return SectionCard(
      title: texte.fortschrittSerieTitel,
      icon: Icons.local_fire_department_outlined,
      child: Row(
        children: [
          Expanded(
            child: _Zahl(wert: aktuell, label: texte.fortschrittSerieAktuell),
          ),
          Expanded(
            child: _Zahl(wert: rekord, label: texte.fortschrittSerieRekord),
          ),
        ],
      ),
    );
  }
}

class _Zahl extends StatelessWidget {
  const _Zahl({required this.wert, required this.label});

  final int wert;
  final String label;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$wert',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
            // Die Zahl ist Schrift – also der Schrift-Ton (DECISIONS 64).
            color: wert > 0 ? farben.erreicht : farben.textSekundaer,
          ),
        ),
        const SizedBox(height: 2),
        MutedText(label),
      ],
    );
  }
}
