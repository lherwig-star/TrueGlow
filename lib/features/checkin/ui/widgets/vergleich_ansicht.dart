import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/datum.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../capture/logic/capture_controller.dart';
import '../../../history/logic/analysis_repository.dart';
import '../../logic/checkin_controller.dart';
import '../../models/checkin.dart';

/// Erstfoto und Fortschrittsfoto nebeneinander, jeweils mit Datum.
///
/// Bewusst ohne Schieberegler oder Ueberblendung: Zwei Bilder nebeneinander
/// zeigen den Unterschied ehrlicher als eine Animation, die Bewegung
/// suggeriert, wo keine ist.
class VergleichAnsicht extends ConsumerWidget {
  const VergleichAnsicht({super.key, required this.checkin});

  final Checkin checkin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final erstfoto = ref
        .watch(captureControllerProvider)
        .foto(CheckinController.fortschrittsTyp);
    final analyse = ref.watch(aktuelleAnalyseProvider);
    final neu = checkin.fortschrittsfoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texte.checkinVergleichTitel,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(texte.vergleichHinweis),
        const SizedBox(height: AppTheme.gapM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Seite(
                titel: texte.checkinVergleichVorher,
                datum: analyse?.erstelltAm,
                pfad: erstfoto?.pfad,
              ),
            ),
            const SizedBox(width: AppTheme.gapS),
            Expanded(
              child: _Seite(
                titel: texte.checkinVergleichNachher,
                datum: DateTime.now(),
                pfad: neu,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.gapM),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.fortschritt),
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(texte.fotosAlleAnsehen),
        ),
        const SizedBox(height: AppTheme.gapM),
        SectionCard(
          title: texte.vergleichNurFuerDichTitel,
          icon: Icons.lock_outline,
          child: MutedText(texte.vergleichNurFuerDichText),
        ),
      ],
    );
  }
}

class _Seite extends StatelessWidget {
  const _Seite({required this.titel, required this.datum, required this.pfad});

  final String titel;
  final DateTime? datum;
  final String? pfad;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final datei = pfad == null ? null : File(pfad!);
    final vorhanden = datei != null && datei.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titel.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: farben.akzent,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: vorhanden
                ? Image.file(datei, fit: BoxFit.cover)
                // Fotos bleiben auf dem Geraet. Nach einem Geraetewechsel ist
                // die Datei deshalb weg, obwohl der Check-in in der Cloud
                // steht – das gehoert erklaert, nicht als Fehler gezeigt.
                : ColoredBox(
                    color: farben.flaecheHoch,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.gapS),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: farben.textSekundaer,
                          ),
                          const SizedBox(height: AppTheme.gapXs),
                          Text(
                            texte.fotoNichtAufDiesemGeraet,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: farben.textSekundaer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        MutedText(
          datum == null
              ? context.texte.vergleichOhneDatum
              : Datum.nurTag(datum!, context.texte.localeName),
        ),
      ],
    );
  }
}
