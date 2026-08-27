import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';

/// Eine Phase des Plans – „Sofort", „Erste 30 Tage", „Langfristig".
///
/// Wortgleich aus `plan_screen.dart` übernommen, nur nicht mehr privat: Sie
/// wird jetzt vom Plan-Tab gebraucht (DECISIONS 65). Der Umzug ist ein Umzug
/// — an der Karte selbst hat sich nichts geändert.
class PhaseKarte extends StatelessWidget {
  const PhaseKarte({
    super.key,
    required this.titel,
    required this.icon,
    required this.schritte,
  });

  final String titel;
  final IconData icon;
  final List<String> schritte;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return SectionCard(
      title: titel,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < schritte.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.gapXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 1, right: 10),
                    decoration: BoxDecoration(
                      color: farben.flaecheHoch,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: farben.akzent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      schritte[i],
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
