import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../analysis/models/analysis_result.dart';
import '../../../modules/models/analyse_modul.dart';
import '../../../onboarding/logic/onboarding_controller.dart';

/// Die Kapitel des Reports als Übersicht statt als langer Scroll
/// (DECISIONS 89).
///
/// Zwei Kacheln je Zeile, gleich hoch. Die gleiche Höhe kommt aus
/// [IntrinsicHeight] und nicht aus einem festen Seitenverhältnis: Ein festes
/// Verhältnis müsste für den längsten Text in beiden Sprachen passen und
/// wäre für alle anderen zu hoch. So bestimmt die längere der beiden Kacheln
/// die Zeile, und weil jeder Text auf zwei Zeilen gekürzt wird, kann das
/// nicht davonlaufen.
class KapitelRaster extends ConsumerWidget {
  const KapitelRaster({super.key, required this.ergebnis});

  final AnalysisResult ergebnis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kapitel ohne Inhalt erscheinen nicht – eine Kachel, hinter der nichts
    // steht, ist ein leeres Versprechen.
    final kapitel = ergebnis.kapitel.where((k) => !k.istLeer).toList();
    if (kapitel.isEmpty) return const SizedBox.shrink();

    final zeilen = <List<Kapitel>>[
      for (var i = 0; i < kapitel.length; i += 2)
        kapitel.sublist(i, i + 2 > kapitel.length ? kapitel.length : i + 2),
    ];

    return Column(
      children: [
        for (final zeile in zeilen) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (nummer, eintrag) in zeile.indexed) ...[
                  if (nummer > 0) const SizedBox(width: AppTheme.gapS),
                  Expanded(
                    child: KapitelKachel(
                      analyseId: ergebnis.id,
                      kapitel: eintrag,
                    ),
                  ),
                ],
                // Bei ungerader Anzahl bleibt der Platz frei, statt dass die
                // letzte Kachel doppelt so breit wird.
                if (zeile.length == 1) ...[
                  const SizedBox(width: AppTheme.gapS),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
      ],
    );
  }
}

/// Eine einzelne Bereichs-Kachel.
class KapitelKachel extends ConsumerWidget {
  const KapitelKachel({
    super.key,
    required this.analyseId,
    required this.kapitel,
  });

  final String analyseId;
  final Kapitel kapitel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ref.watch(ausrichtungProvider);
    final titel = kapitel.titel(texte, ausrichtung);

    return Material(
      color: farben.flaeche,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        onTap: () => context.push(
          Routes.kapitelFuer(analyseId, kapitel.modul),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: farben.kartenrand),
          ),
          padding: const EdgeInsets.all(AppTheme.gapS),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  // Der Ton des Bereichs – der einzige Ort, an dem sich die
                  // Kacheln farblich unterscheiden.
                  color: farben.kachelton(
                    AnalyseModul.values.indexOf(kapitel.modul),
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  kapitel.modul.icon,
                  size: 21,
                  color: farben.textPrimaer,
                ),
              ),
              const SizedBox(height: AppTheme.gapS),
              Text(
                titel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (kapitel.einleitung.isNotEmpty) ...[
                const SizedBox(height: 4),
                // Nichts Erfundenes: Das ist die Einleitung des Kapitels,
                // gekürzt – kein neuer Text und kein zweites Feld.
                Text(
                  kapitel.einleitung,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: farben.textSekundaer,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.gapS),
              // Nach unten geschoben, damit die Fußzeile in beiden Kacheln
              // einer Zeile auf derselben Höhe steht.
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      texte.ergebnisKachelEmpfehlungen(
                        kapitel.anzahlEmpfehlungen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: farben.textSekundaer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: farben.textSekundaer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
