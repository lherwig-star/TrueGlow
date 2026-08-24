import 'dart:io';

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
import '../models/aufnahme_typ.dart';
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
          if (schritte.whereType<FotoSchritt>().isNotEmpty) ...[
            const SizedBox(height: AppTheme.gapS),
            _FotoLeiste(
              fotoSchritte: schritte.whereType<FotoSchritt>().toList(),
              aufnahmen: aufnahmen,
              aktueller: schritt is FotoSchritt ? schritt.typ : null,
              onSpringe: (typ) => setState(
                () => _index = schritte.indexWhere(
                  (s) => s is FotoSchritt && s.typ == typ,
                ),
              ),
            ),
          ],
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

/// Miniaturen aller Fotos des Flows – gemacht wie ausstehend.
///
/// Der Balken darueber zaehlt Schritte, diese Leiste zeigt Inhalt: was
/// tatsaechlich schon im Kasten ist. Bei bis zu zehn Aufnahmen verliert man
/// sonst den Ueberblick, und ein misslungenes Foto faellt erst am Ende auf.
///
/// Ein Antippen springt zu dem Schritt. Neu aufgenommen wird dort mit dem
/// vorhandenen „Neu aufnehmen" – ein zweiter Weg zur selben Sache waere eine
/// Fehlerquelle mehr.
class _FotoLeiste extends StatelessWidget {
  const _FotoLeiste({
    required this.fotoSchritte,
    required this.aufnahmen,
    required this.aktueller,
    required this.onSpringe,
  });

  final List<FotoSchritt> fotoSchritte;
  final CaptureState aufnahmen;
  final AufnahmeTyp? aktueller;
  final void Function(AufnahmeTyp) onSpringe;

  static const double _kante = 46;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return SizedBox(
      height: _kante,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotoSchritte.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.gapXs),
        itemBuilder: (context, i) {
          final typ = fotoSchritte[i].typ;
          final foto = aufnahmen.foto(typ);
          final istAktuell = typ == aktueller;

          return Semantics(
            button: true,
            selected: istAktuell,
            label: '${typ.label}, '
                '${foto != null ? 'aufgenommen' : 'noch offen'}',
            child: GestureDetector(
              onTap: () => onSpringe(typ),
              child: Container(
                width: _kante,
                height: _kante,
                decoration: BoxDecoration(
                  color: farben.flaeche,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: istAktuell
                        ? farben.akzent
                        : foto != null
                            ? farben.erfolg.withValues(alpha: 0.6)
                            : farben.rand,
                    width: istAktuell ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: foto != null
                    ? Image.file(
                        File(foto.pfad),
                        fit: BoxFit.cover,
                        // Die Miniatur braucht keine 1024 Pixel Kantenlaenge –
                        // zehn Vollbilder im Speicher waeren auf schwachen
                        // Geraeten der schnellste Weg in den Absturz.
                        cacheWidth: 140,
                        key: ValueKey('${foto.pfad}-${foto.groesseInBytes}'),
                      )
                    : Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: farben.textSekundaer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
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
