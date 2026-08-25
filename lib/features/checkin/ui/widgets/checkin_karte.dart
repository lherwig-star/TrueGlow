import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/checkin_controller.dart';
import '../../models/checkin.dart';

/// Die Einladung zum Check-in auf der Startseite.
///
/// Steht bewusst ganz oben und faellt farblich auf: Der Check-in ist der
/// einzige Weg, den Plan an den echten Alltag anzupassen – eine Zeile im
/// Fliesstext wuerde dafuer untergehen. Steht keiner an, zeigt die Karte
/// nichts an, sondern verschwindet ganz.
class CheckinKarte extends ConsumerWidget {
  const CheckinKarte({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final zustand = ref.watch(checkinControllerProvider);
    if (!zustand.faellig()) return const SizedBox.shrink();

    final farben = context.farben;
    final typ = zustand.entwurf?.typ ?? zustand.naechsterTyp;
    final begonnen = zustand.begonnen;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: farben.akzent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.rate_review_outlined,
                    size: 18,
                    color: farben.akzent,
                  ),
                ),
                const SizedBox(width: AppTheme.gapS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texte.checkinKarteTitel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        typ.titel(texte),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: farben.akzent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.gapS),
            MutedText(
              begonnen ? texte.checkinKarteFortsetzen : texte.checkinKarteText,
            ),
            const SizedBox(height: AppTheme.gapM),
            FilledButton(
              onPressed: () => context.push(Routes.checkin),
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              child: Text(
                begonnen ? texte.checkinFortsetzen : texte.checkinStarten,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dezenter Hinweis auf den naechsten Termin – nur, wenn gerade keiner offen
/// ist. Ohne diese Zeile wirkt der Zyklus wie ein Zufallsereignis.
class CheckinVorschau extends ConsumerWidget {
  const CheckinVorschau({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final zustand = ref.watch(checkinControllerProvider);
    final tage = zustand.tageBis;
    if (zustand.faellig() || tage == null || tage <= 0) {
      return const SizedBox.shrink();
    }

    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.gapS),
      child: Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 16,
            color: farben.textSekundaer,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MutedText(texte.checkinNaechsterIn(tage)),
          ),
        ],
      ),
    );
  }
}
