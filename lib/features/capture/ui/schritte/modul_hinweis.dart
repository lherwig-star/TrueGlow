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
  List<(IconData, String, String)> get _punkte => switch (modul) {
        AnalyseModul.hautFarbtyp => const [
            (
              Icons.wb_twilight,
              'Indirektes Tageslicht',
              'Stell dich seitlich ans Fenster. Direkte Sonne und warmes '
                  'Kunstlicht verfälschen den Unterton.',
            ),
            (
              Icons.no_photography_outlined,
              'Kein Filter, keine Beauty-Funktion',
              'Auch die automatische Hautglättung deines Handys ausschalten – '
                  'sonst ist genau das weg, was wir einschätzen sollen.',
            ),
            (
              Icons.straighten,
              'Auf Armlänge',
              'Frontkamera etwa eine Armlänge vor dem Gesicht, Kopf füllt den '
                  'Rahmen.',
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
