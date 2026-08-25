import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../modules/logic/module_controller.dart';
import '../../logic/capture_controller.dart';
import '../../models/aufnahme_typ.dart';
import '../../models/captured_photo.dart';
import '../../models/photo_check_result.dart';
import '../widgets/silhouette_overlay.dart';

/// Ein Aufnahme-Schritt: Sucher mit Hilfslinien oder das bereits gepruefte
/// Foto, dazu Kamera- und Galerie-Zugang und der Hinweis zur Haltung.
class FotoSchrittAnsicht extends ConsumerWidget {
  const FotoSchrittAnsicht({super.key, required this.typ});

  final AufnahmeTyp typ;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final zustand = ref.watch(captureControllerProvider);
    final foto = zustand.foto(typ);
    final module = ref.watch(moduleControllerProvider).module;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          typ.label,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (typ.optional) ...[
          const SizedBox(height: AppTheme.gapXs),
          const MutedText('Optional – du kannst diesen Schritt überspringen.'),
        ],
        const SizedBox(height: AppTheme.gapM),
        _Sucher(typ: typ, foto: foto, laeuft: zustand.laeuft),
        const SizedBox(height: AppTheme.gapS),
        _Quellen(
          hatFoto: foto != null,
          laeuft: zustand.laeuft,
          onKamera: () => context.push(Routes.kameraFuer(typ)),
          onGalerie: () =>
              ref.read(captureControllerProvider.notifier).ausGalerie(typ),
          onNeu: () =>
              ref.read(captureControllerProvider.notifier).verwerfen(typ),
        ),
        const SizedBox(height: AppTheme.gapS),
        if (zustand.problem case final problem?) ...[
          _Problemkarte(
            problem: problem,
            onSchliessen: () => ref
                .read(captureControllerProvider.notifier)
                .problemVerwerfen(),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
        SectionCard(
          title: 'So klappt das Foto',
          icon: Icons.tips_and_updates_outlined,
          child: MutedText(typ.hinweisFuer(module)),
        ),
        if (typ.autoAusloeser) ...[
          const SizedBox(height: AppTheme.gapS),
          SectionCard(
            title: 'Die App löst selbst aus',
            icon: Icons.timer_outlined,
            child: MutedText(texte.koerperAutoHinweis),
          ),
        ],
      ],
    );
  }
}

/// Sucher-Bereich: entweder die Hilfslinien oder das gepruefte Foto.
class _Sucher extends StatelessWidget {
  const _Sucher({
    required this.typ,
    required this.foto,
    required this.laeuft,
  });

  final AufnahmeTyp typ;
  final CapturedPhoto? foto;
  final bool laeuft;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: farben.flaeche,
                border: Border.all(color: farben.rand),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
            ),
            if (foto != null)
              Image.file(
                File(foto!.pfad),
                fit: BoxFit.cover,
                // Der Dateiname bleibt pro Typ gleich – ohne eigenen Key
                // zeigt Flutter sonst das alte Bild aus dem Cache.
                key: ValueKey('${foto!.pfad}-${foto!.groesseInBytes}'),
              )
            else if (typ.overlay == Overlaytyp.keins)
              Center(
                child: Icon(
                  Icons.add_a_photo_outlined,
                  size: 40,
                  color: farben.textSekundaer,
                ),
              )
            else
              SilhouetteOverlay(overlay: typ.overlay),
            if (foto != null)
              const Positioned(
                top: AppTheme.gapS,
                right: AppTheme.gapS,
                child: _GeprueftBadge(),
              ),
            if (laeuft) const _PruefUeberlagerung(),
          ],
        ),
      ),
    );
  }
}

class _Quellen extends StatelessWidget {
  const _Quellen({
    required this.hatFoto,
    required this.laeuft,
    required this.onKamera,
    required this.onGalerie,
    required this.onNeu,
  });

  final bool hatFoto;
  final bool laeuft;
  final VoidCallback onKamera;
  final VoidCallback onGalerie;
  final VoidCallback onNeu;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    if (hatFoto) {
      return OutlinedButton.icon(
        onPressed: laeuft ? null : onNeu,
        icon: const Icon(Icons.refresh),
        label: Text(texte.fotoNeuAufnehmen),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: laeuft ? null : onKamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(texte.fotoKamera),
          ),
        ),
        const SizedBox(width: AppTheme.gapS),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: laeuft ? null : onGalerie,
            icon: const Icon(Icons.image_outlined),
            label: Text(texte.fotoGalerie),
          ),
        ),
      ],
    );
  }
}

class _GeprueftBadge extends StatelessWidget {
  const _GeprueftBadge();

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: farben.hintergrund.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: farben.erfolg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: farben.erfolg),
          const SizedBox(width: 6),
          Text(
            'Geprüft',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: farben.erfolg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PruefUeberlagerung extends StatelessWidget {
  const _PruefUeberlagerung();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.farben.hintergrund.withValues(alpha: 0.7),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: AppTheme.gapS),
          Text(
            'Foto wird geprüft...',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Verstaendliche Rueckmeldung, wenn der Qualitaetscheck fehlschlaegt.
class _Problemkarte extends StatelessWidget {
  const _Problemkarte({required this.problem, required this.onSchliessen});

  final PhotoProblem problem;
  final VoidCallback onSchliessen;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
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
            child: Icon(Icons.error_outline, color: farben.warnung, size: 20),
          ),
          const SizedBox(width: AppTheme.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  problem.titel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: farben.warnung,
                  ),
                ),
                const SizedBox(height: 4),
                MutedText(problem.tipp),
              ],
            ),
          ),
          IconButton(
            onPressed: onSchliessen,
            icon: const Icon(Icons.close, size: 18),
            color: farben.textSekundaer,
            visualDensity: VisualDensity.compact,
            tooltip: 'Hinweis schließen',
          ),
        ],
      ),
    );
  }
}
