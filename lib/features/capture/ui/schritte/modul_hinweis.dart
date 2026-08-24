import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../modules/models/analyse_modul.dart';
import '../../models/aufnahme_typ.dart';

/// Vorbereitungsseite eines Moduls – steht vor dessen Aufnahmen, wenn die
/// Bedingungen ueber den normalen Sucher-Hinweis hinausgehen.
class ModulHinweis extends StatelessWidget {
  const ModulHinweis({super.key, required this.modul});

  final AnalyseModul modul;

  /// Was fuer dieses Modul besonders zaehlt.
  ///
  /// Seit dem Wegfall der Hautton-Nahaufnahme steht diese Seite **hinter** den
  /// Basis-Fotos – die Reihenfolge folgt der Deklaration in [AnalyseModul].
  /// Ratschlaege zur Aufnahme waeren hier also zu spaet. Deshalb erklaert sie
  /// jetzt, warum kein Foto kommt, und zeigt den Rueckweg, falls das
  /// Frontalfoto nichts taugt.
  List<(IconData, String, String)> get _punkte => switch (modul) {
        AnalyseModul.hautFarbtyp => const [
            (
              Icons.photo_camera_back_outlined,
              'Kein eigenes Foto nötig',
              'Unterton und Farbpalette lesen wir aus deinem Frontalfoto der '
                  'Basis mit. Eine zusätzliche Nahaufnahme brauchst du nicht.',
            ),
            (
              Icons.wb_twilight,
              'Licht zählt hier doppelt',
              'War dein Frontalfoto zu dunkel oder farbstichig, geh einen '
                  'Schritt zurück und nimm es bei indirektem Tageslicht neu '
                  'auf – warmes Kunstlicht verfälscht den Unterton.',
            ),
          ],
        _ => const [],
      };

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: farben.akzent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(modul.icon, color: farben.akzent, size: 22),
            ),
            const SizedBox(width: AppTheme.gapS),
            Expanded(
              child: Text(
                modul.titel,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(modul.benoetigt),
        const SizedBox(height: AppTheme.gapM),
        for (final (icon, titel, text) in _punkte) ...[
          SectionCard(
            title: titel,
            icon: icon,
            child: MutedText(text),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
      ],
    );
  }
}
