import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../modules/models/analyse_modul.dart';
import '../logic/analysis_controller.dart';
import '../logic/analysis_service.dart';

/// Ladezustand waehrend des API-Calls, mit rotierenden Statustexten.
/// Startet die Analyse selbst und wechselt bei Erfolg zum Ergebnis.
class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  const AnalysisLoadingScreen({super.key, this.nurModul, this.module});

  /// Beim Erweitern wird nur dieses Kapitel erzeugt.
  final AnalyseModul? nurModul;

  /// Umfang der Neuberechnung. Ohne Angabe gilt die aktuelle Modulauswahl.
  final Set<AnalyseModul>? module;

  @override
  ConsumerState<AnalysisLoadingScreen> createState() =>
      _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends ConsumerState<AnalysisLoadingScreen> {
  static const _statusTexte = [
    'Analysiere Gesichtsform...',
    'Prüfe Hautbild...',
    'Vergleiche Frisur-Optionen...',
    'Stelle Empfehlungen zusammen...',
    'Erstelle deinen Plan...',
  ];

  Timer? _rotation;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _rotation = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _statusTexte.length);
    });
    // Nach dem ersten Frame starten, damit der Screen schon steht.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analysisControllerProvider.notifier).starten(
            nurModul: widget.nurModul,
            module: widget.module,
          );
    });
  }

  @override
  void dispose() {
    _rotation?.cancel();
    super.dispose();
  }

  /// Bricht ab und geht zurueck.
  ///
  /// Ohne diesen Ausweg haengt die Analyse am Netz: Bei schlechter Verbindung
  /// laeuft der Wiederholungszyklus bis zu drei Versuche durch, und der
  /// einzige Weg heraus waere, die App zu schliessen.
  void _abbrechen() {
    ref.read(analysisControllerProvider.notifier).abbrechen();
    if (context.canPop()) context.pop();
  }

  void _erneutVersuchen() {
    setState(() => _index = 0);
    ref.read(analysisControllerProvider.notifier).starten(
          nurModul: widget.nurModul,
          module: widget.module,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Bei Erfolg direkt zum Ergebnis wechseln, beim Abbruch zurueck.
    ref.listen<AnalyseZustand>(analysisControllerProvider, (_, neu) {
      if (neu is AnalyseFertig) {
        context.pushReplacement('${Routes.result}/${neu.ergebnis.id}');
      } else if (neu is AnalyseAbgebrochen && context.canPop()) {
        context.pop();
      }
    });

    final zustand = ref.watch(analysisControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gapM),
          child: switch (zustand) {
            AnalyseFehlgeschlagen(:final fehler) => _Fehler(
                fehler: fehler,
                onErneut: _erneutVersuchen,
                onZurueck: () => context.pop(),
              ),
            _ => _Laden(
                text: _statusTexte[_index],
                index: _index,
                onAbbrechen: _abbrechen,
              ),
          },
        ),
      ),
    );
  }
}

class _Laden extends StatelessWidget {
  const _Laden({
    required this.text,
    required this.index,
    required this.onAbbrechen,
  });

  final String text;
  final int index;
  final VoidCallback onAbbrechen;

  @override
  Widget build(BuildContext context) {
    // Scrollbar, damit der Inhalt auf kleinen Geraeten und bei grosser
    // Systemschrift nicht ueberlaeuft.
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppTheme.gapL),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              text,
              key: ValueKey(index),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppTheme.gapS),
          Text(
            S.analyseHinweis,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.farben.textSekundaer, fontSize: 14),
          ),
          const SizedBox(height: AppTheme.gapXl),
          const _SkeletonBlock(),
          const SizedBox(height: AppTheme.gapS),
          TextButton(onPressed: onAbbrechen, child: const Text(S.abbrechen)),
        ],
      ),
    );
  }
}

/// Angedeutete Ergebnis-Karten, damit die Wartezeit weniger leer wirkt.
class _SkeletonBlock extends StatefulWidget {
  const _SkeletonBlock();

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: List.generate(3, (i) {
            // Leicht versetztes Pulsieren pro Karte.
            final phase = (_controller.value + i * 0.18) % 1.0;
            final staerke = 0.04 + 0.05 * (1 - (phase - 0.5).abs() * 2);
            return Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: AppTheme.gapS),
              decoration: BoxDecoration(
                color: farben.akzent.withValues(alpha: staerke),
                border: Border.all(color: farben.rand),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Freundliche Fehlermeldung mit Retry.
class _Fehler extends StatelessWidget {
  const _Fehler({
    required this.fehler,
    required this.onErneut,
    required this.onZurueck,
  });

  final AnalysisFehler fehler;
  final VoidCallback onErneut;
  final VoidCallback onZurueck;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: farben.warnung.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_off_outlined,
            size: 32,
            color: farben.warnung,
          ),
        ),
        const SizedBox(height: AppTheme.gapM),
        Text(
          fehler.titel,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        Text(
          fehler.tipp,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: farben.textSekundaer,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.gapL),
        FilledButton.icon(
          onPressed: onErneut,
          icon: const Icon(Icons.refresh),
          label: const Text(S.erneutVersuchen),
        ),
        const SizedBox(height: AppTheme.gapS),
        OutlinedButton(
          onPressed: onZurueck,
          child: const Text(S.zurueck),
        ),
      ],
    );
  }
}
