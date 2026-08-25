import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/checkin_controller.dart';
import '../../../capture/models/photo_check_result.dart';
import '../../models/checkin.dart';

/// Optionales Fortschrittsfoto beim Wirkungs-Check.
///
/// Aufgenommen wird mit derselben Kamera-Ansicht und demselben Overlay wie
/// beim Erstfoto – nur so sind die beiden Bilder ueberhaupt vergleichbar.
/// Deshalb stehen hier auch wieder die Hinweise von damals.
class FortschrittsfotoSchritt extends ConsumerWidget {
  const FortschrittsfotoSchritt({super.key, required this.checkin});

  final Checkin checkin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final zustand = ref.watch(checkinControllerProvider);
    final farben = context.farben;
    final pfad = checkin.fortschrittsfoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texte.checkinFotoTitel,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(texte.checkinFotoText),
        const SizedBox(height: AppTheme.gapM),

        if (zustand.fotoProblem case final problem?) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.gapM),
            decoration: BoxDecoration(
              color: farben.warnung.withValues(alpha: 0.08),
              border: Border.all(color: farben.warnung.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.error_outline,
                    color: farben.warnung,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.gapS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        problem.titel(texte),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: farben.warnung,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MutedText(problem.tipp(texte)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(checkinControllerProvider.notifier)
                      .fotoProblemVerwerfen(),
                  icon: const Icon(Icons.close, size: 18),
                  color: farben.textSekundaer,
                  visualDensity: VisualDensity.compact,
                  tooltip: texte.hinweisSchliessen,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],

        if (pfad != null && File(pfad).existsSync()) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Image.file(
              File(pfad),
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppTheme.gapS),
          OutlinedButton.icon(
            onPressed: () => _aufnehmen(context),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(texte.checkinFotoNeu),
          ),
        ] else ...[
          SectionCard(
            title: 'Wie beim ersten Mal',
            icon: Icons.wb_sunny_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MutedText(texte.lichtTageslichtText),
                SizedBox(height: AppTheme.gapS),
                MutedText(texte.lichtKeinFilterText),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.gapS),
          FilledButton.icon(
            onPressed: zustand.fotoLaeuft ? null : () => _aufnehmen(context),
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(texte.checkinFotoAufnehmen),
          ),
          const SizedBox(height: AppTheme.gapS),
          Center(child: MutedText(texte.checkinFotoOhne)),
        ],
      ],
    );
  }

  void _aufnehmen(BuildContext context) => context.push(
        Routes.kameraFortschritt(CheckinController.fortschrittsTyp),
      );
}
