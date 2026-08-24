import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../modules/logic/module_controller.dart';
import '../../modules/models/analyse_modul.dart';
import '../logic/aufnahme_flow.dart';
import '../logic/capture_controller.dart';
import 'schritte/figur_formular.dart';
import 'schritte/foto_schritt_ansicht.dart';
import 'schritte/licht_checkliste.dart';
import 'schritte/modul_hinweis.dart';
import 'schritte/stil_fragebogen.dart';

/// Gefuehrter Aufnahme-Flow. Welche Schritte erscheinen, ergibt sich aus den
/// gewaehlten Modulen – mit [nurModul] laeuft nur ein einzelnes Modul, das ist
/// der Weg ueber "Analyse erweitern".
class CaptureFlowScreen extends ConsumerStatefulWidget {
  const CaptureFlowScreen({super.key, this.nurModul});

  final AnalyseModul? nurModul;

  @override
  ConsumerState<CaptureFlowScreen> createState() => _CaptureFlowScreenState();
}

class _CaptureFlowScreenState extends ConsumerState<CaptureFlowScreen> {
  int _index = 0;

  void _weiter(List<FlowSchritt> schritte) {
    if (_index < schritte.length - 1) {
      setState(() => _index++);
      return;
    }
    // Letzter Schritt: ab in die Analyse. Der Umfang wandert als Parameter
    // mit, damit beim Erweitern nur das neue Kapitel erzeugt wird.
    context.push(Routes.analyseFuer(widget.nurModul));
  }

  void _zurueck() {
    if (_index > 0) {
      setState(() => _index--);
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final zustand = ref.watch(moduleControllerProvider);
    final aufnahmen = ref.watch(captureControllerProvider);

    final schritte = baueAufnahmeFlow(zustand.module, nur: widget.nurModul);
    if (schritte.isEmpty) {
      return const AppPage(
        title: 'Aufnahme',
        children: [
          SizedBox(height: AppTheme.gapXl),
          MutedText(
            'Für diese Auswahl gibt es nichts aufzunehmen.',
            align: TextAlign.center,
          ),
        ],
      );
    }

    // Nach einer Aenderung der Auswahl kann der Index ins Leere zeigen.
    final index = _index.clamp(0, schritte.length - 1);
    final schritt = schritte[index];

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = index - 1);
      },
      child: AppPage(
        title: 'Schritt ${index + 1} von ${schritte.length}',
        bottomFade: true,
        bottomBar: _Aktionen(
          schritt: schritt,
          erfuellt: _erfuellt(schritt, aufnahmen, zustand),
          letzter: index == schritte.length - 1,
          ersterSchritt: index == 0,
          onWeiter: () => _weiter(schritte),
          onZurueck: _zurueck,
        ),
        children: [
          _Fortschritt(aktuell: index, gesamt: schritte.length),
          const SizedBox(height: AppTheme.gapM),
          switch (schritt) {
            LichtCheckSchritt() => const LichtCheckliste(),
            ModulHinweisSchritt(:final modul) => ModulHinweis(modul: modul),
            FotoSchritt(:final typ) => FotoSchrittAnsicht(typ: typ),
            FigurFormularSchritt() => const FigurFormular(),
            StilFragebogenSchritt() => const StilFragebogen(),
          },
        ],
      ),
    );
  }

  /// Ob der aktuelle Schritt abgeschlossen ist und "Weiter" freigibt.
  bool _erfuellt(
    FlowSchritt schritt,
    CaptureState aufnahmen,
    ModulZustand module,
  ) {
    return switch (schritt) {
      LichtCheckSchritt() => true,
      ModulHinweisSchritt() => true,
      FotoSchritt(:final typ) => aufnahmen.hat(typ) || typ.optional,
      FigurFormularSchritt() => module.eingaben.figur.istVollstaendig,
      StilFragebogenSchritt() => module.eingaben.stil.istVollstaendig,
    };
  }
}

/// Balkenanzeige ueber dem Inhalt.
class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.aktuell, required this.gesamt});

  final int aktuell;
  final int gesamt;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Row(
      children: [
        for (var i = 0; i < gesamt; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              margin: EdgeInsets.only(right: i == gesamt - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: i <= aktuell ? farben.akzent : farben.rand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _Aktionen extends StatelessWidget {
  const _Aktionen({
    required this.schritt,
    required this.erfuellt,
    required this.letzter,
    required this.ersterSchritt,
    required this.onWeiter,
    required this.onZurueck,
  });

  final FlowSchritt schritt;
  final bool erfuellt;
  final bool letzter;
  final bool ersterSchritt;
  final VoidCallback onWeiter;
  final VoidCallback onZurueck;

  @override
  Widget build(BuildContext context) {
    // Ein optionales Foto darf uebersprungen werden – das muss auch
    // beschriftet sein, sonst wirkt der Weiter-Button wie ein Fehler.
    final ueberspringbar = schritt is FotoSchritt &&
        (schritt as FotoSchritt).typ.optional &&
        !erfuellt;

    final beschriftung = switch (schritt) {
      LichtCheckSchritt() => S.lichtStarten,
      _ when ueberspringbar => S.flowUeberspringen,
      _ when letzter => S.fotoAnalyseStarten,
      _ => S.weiter,
    };

    return Row(
      children: [
        if (!ersterSchritt) ...[
          // Feste Breite: die Theme-Buttons fordern in einer Row sonst
          // unendliche Breite an.
          SizedBox(
            width: 120,
            child: OutlinedButton(
              onPressed: onZurueck,
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              child: const Text(S.zurueck),
            ),
          ),
          const SizedBox(width: AppTheme.gapS),
        ],
        Expanded(
          child: FilledButton(
            onPressed: erfuellt || ueberspringbar ? onWeiter : null,
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            child: Text(beschriftung),
          ),
        ),
      ],
    );
  }
}
