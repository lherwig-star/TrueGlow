import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../modules/models/analyse_modul.dart';
import '../../models/aufnahme_typ.dart';
import '../../../../core/l10n/texte.dart';

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
  List<(IconData, String, String)> _punkte(L texte) => switch (modul) {
        AnalyseModul.hautFarbtyp => [
            (
              Icons.photo_camera_back_outlined,
              texte.modulHautKeinFotoTitel,
              texte.modulHautKeinFotoText,
            ),
            (
              Icons.wb_twilight,
              texte.modulHautLichtTitel,
              texte.modulHautLichtText,
            ),
          ],
        _ => const [],
      };

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
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
                modul.titel(texte),
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
        MutedText(modul.benoetigt(texte)),
        const SizedBox(height: AppTheme.gapM),
        for (final (icon, titel, text) in _punkte(texte)) ...[
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
