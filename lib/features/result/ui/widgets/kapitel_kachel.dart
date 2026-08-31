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
import '../../../onboarding/models/onboarding_profile.dart';

/// Die Kapitel des Reports als Übersicht statt als langer Scroll
/// (DECISIONS 89, geschärft in DECISIONS 90).
///
/// Zwei Kacheln je Zeile, gleich hoch. Die gleiche Höhe kommt aus
/// [IntrinsicHeight] und nicht aus einem festen Seitenverhältnis: Ein festes
/// Verhältnis müsste für den längsten Text in beiden Sprachen passen und
/// wäre für alle anderen zu hoch. So bestimmt die längere der beiden Kacheln
/// die Zeile, und weil jeder Text gekürzt wird, kann das nicht davonlaufen.
///
/// **Kein Loch am Ende:** Bleibt bei ungerader Anzahl ein Platz frei, nimmt
/// die letzte Kachel die volle Breite und legt sich quer – Symbol links,
/// Text rechts. Eine halbe Zeile Leere sah aus, als fehlte dort etwas.
class KapitelRaster extends ConsumerWidget {
  const KapitelRaster({super.key, required this.ergebnis});

  final AnalysisResult ergebnis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kapitel ohne Inhalt erscheinen nicht – eine Kachel, hinter der nichts
    // steht, ist ein leeres Versprechen.
    final kapitel = ergebnis.kapitel.where((k) => !k.istLeer).toList();
    if (kapitel.isEmpty) return const SizedBox.shrink();

    final ungerade = kapitel.length.isOdd;
    final paare = ungerade
        ? kapitel.sublist(0, kapitel.length - 1)
        : kapitel;

    Widget kachel(Kapitel eintrag, {bool quer = false}) => KapitelKachel(
          analyseId: ergebnis.id,
          kapitel: eintrag,
          freitext: ergebnis.richtung.freitext,
          quer: quer,
        );

    return Column(
      children: [
        for (var i = 0; i < paare.length; i += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: kachel(paare[i])),
                const SizedBox(width: AppTheme.gapS),
                Expanded(child: kachel(paare[i + 1])),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
        if (ungerade) ...[
          kachel(kapitel.last, quer: true),
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
    this.freitext = '',
    this.quer = false,
  });

  final String analyseId;
  final Kapitel kapitel;

  /// Der Wunsch in eigenen Worten – nur auf der Kachel des Zielkapitels.
  ///
  /// Er stand bis DECISIONS 90 in einer eigenen Karte weiter oben. Dort war
  /// er doppelt: Das Zielkapitel entsteht aus genau diesem Text. Jetzt steht
  /// er da, wo das Kapitel steht, das aus ihm geworden ist.
  final String freitext;

  /// Querformat über die volle Breite – die letzte Kachel einer ungeraden
  /// Reihe. Symbol links, Text rechts.
  final bool quer;

  /// Was unter dem Bereichsnamen steht.
  ///
  /// Beim Zielkapitel der eigene Wunsch, sonst das [Kapitel.fazit] – eine
  /// ganze Aussage und nie ein angerissener Satz (DECISIONS 90).
  String _untertitel() {
    if (kapitel.modul == AnalyseModul.persoenlicheZiele) {
      final wunsch = freitext.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (wunsch.isNotEmpty) return wunsch;
    }
    return kapitel.fazit;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ref.watch(ausrichtungProvider);

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
          padding: const EdgeInsets.all(AppTheme.gapM),
          child: quer
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Symbol(modul: kapitel.modul),
                    const SizedBox(width: AppTheme.gapM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _text(texte, farben, ausrichtung),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: farben.textSekundaer,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Symbol(modul: kapitel.modul),
                    const SizedBox(height: AppTheme.gapS),
                    ..._text(texte, farben, ausrichtung),
                    const SizedBox(height: AppTheme.gapS),
                    // Nach unten geschoben, damit die Fußzeile in beiden
                    // Kacheln einer Zeile auf derselben Höhe steht.
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(child: _Zaehler(kapitel: kapitel)),
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

  /// Name, Untertitel und – im Querformat – der Zähler. Beide Formen zeigen
  /// dasselbe; sie ordnen es nur anders an.
  List<Widget> _text(L texte, AppColors farben, Ausrichtung ausrichtung) => [
        Text(
          kapitel.titel(texte, ausrichtung),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        if (_untertitel().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            _untertitel(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: farben.textSekundaer,
            ),
          ),
        ],
        if (quer) ...[
          const SizedBox(height: 5),
          _Zaehler(kapitel: kapitel),
        ],
      ];
}

/// Das Bereichs-Symbol auf seinem Ton.
class _Symbol extends StatelessWidget {
  const _Symbol({required this.modul});

  final AnalyseModul modul;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        // Der Ton des Bereichs – der einzige Ort, an dem sich die Kacheln
        // farblich unterscheiden.
        color: context.farben.kachelton(AnalyseModul.values.indexOf(modul)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(modul.icon, size: 23, color: context.farben.textPrimaer),
    );
  }
}

/// Wie viele Empfehlungen hinter der Kachel warten.
class _Zaehler extends StatelessWidget {
  const _Zaehler({required this.kapitel});

  final Kapitel kapitel;

  @override
  Widget build(BuildContext context) => Text(
        context.texte.ergebnisKachelEmpfehlungen(kapitel.anzahlEmpfehlungen),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.farben.textSekundaer,
        ),
      );
}
