import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/fortschritts_album.dart';

/// Einstieg ins Fortschritts-Tagebuch – zeigt das neueste Bild als Miniatur.
///
/// Steht nur da, wenn es ueberhaupt ein Foto auf diesem Geraet gibt. Eine
/// leere Karte, die auf einen leeren Bildschirm fuehrt, ist ein Versprechen,
/// das nichts dahinter hat.
class FortschrittKarte extends ConsumerWidget {
  const FortschrittKarte({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fotos = ref.watch(vorhandeneFotosProvider);
    if (fotos.isEmpty) return const SizedBox.shrink();

    final texte = context.texte;
    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: SectionCard(
        title: texte.fotosTitel,
        icon: Icons.photo_library_outlined,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          onTap: () => context.push(Routes.fortschritt),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(fotos.last.pfad),
                  width: 56,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppTheme.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texte.fotosZeitleiste(fotos.length),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    MutedText(texte.fotosOeffnen),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: farben.textSekundaer),
            ],
          ),
        ),
      ),
    );
  }
}
