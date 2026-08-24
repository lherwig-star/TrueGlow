import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../analysis/logic/analysis_service.dart';
import '../../../analysis/models/analysis_result.dart';
import '../../../capture/logic/capture_controller.dart';
import '../../../history/logic/analysis_repository.dart';
import '../../../plan/logic/plan_progress_repository.dart';
import '../../logic/checkin_benachrichtigung.dart';
import '../../logic/checkin_controller.dart';
import '../../logic/checkin_service.dart';
import '../../logic/plan_anpassung.dart';
import '../../models/checkin.dart';
import '../../models/checkin_auswertung.dart';

/// Letzter Schritt: Die KI liest die Antworten, schlaegt Aenderungen vor, und
/// der Nutzer bestaetigt sie.
///
/// Die Bestaetigung ist Absicht – der Plan aendert sich nie hinter dem Ruecken
/// des Nutzers. Schlaegt die Auswertung fehl, laesst sich der Check-in
/// trotzdem abschliessen: Die Antworten sind dann in der Historie, der Plan
/// bleibt unveraendert.
class CheckinAbschluss extends ConsumerStatefulWidget {
  const CheckinAbschluss({
    super.key,
    required this.checkin,
    required this.analyse,
  });

  final Checkin checkin;
  final AnalysisResult analyse;

  @override
  ConsumerState<CheckinAbschluss> createState() => _CheckinAbschlussState();
}

class _CheckinAbschlussState extends ConsumerState<CheckinAbschluss> {
  CheckinAuswertung? _auswertung;
  AnalysisFehler? _fehler;
  bool _laeuft = true;
  bool _speichert = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _auswerten());
  }

  Future<void> _auswerten() async {
    setState(() {
      _laeuft = true;
      _fehler = null;
    });

    final erstfoto = ref
        .read(captureControllerProvider)
        .foto(CheckinController.fortschrittsTyp);
    final neu = widget.checkin.fortschrittsfoto;

    try {
      final auswertung =
          await ref.read(checkinServiceProvider).auswerten(
                checkin: widget.checkin,
                analyse: widget.analyse,
                historie: ref.read(checkinControllerProvider).historie,
                erstfoto: erstfoto == null ? null : File(erstfoto.pfad),
                fortschrittsfoto: neu == null ? null : File(neu),
              );

      if (!mounted) return;
      setState(() {
        _auswertung = auswertung;
        _laeuft = false;
      });
    } on AnalysisException catch (e) {
      debugPrint('Check-in-Auswertung fehlgeschlagen: $e');
      if (!mounted) return;
      setState(() {
        _fehler = e.fehler;
        _laeuft = false;
      });
    } catch (e, s) {
      debugPrint('Check-in-Auswertung unerwartet fehlgeschlagen: $e\n$s');
      if (!mounted) return;
      setState(() {
        _fehler = AnalysisFehler.apiFehler;
        _laeuft = false;
      });
    }
  }

  /// Uebernimmt die Aenderungen und schliesst den Check-in ab.
  Future<void> _abschliessen({required bool mitAnpassung}) async {
    if (_speichert) return;
    setState(() => _speichert = true);

    final auswertung = _auswertung ?? CheckinAuswertung.leer;
    final ctrl = ref.read(checkinControllerProvider.notifier);

    if (mitAnpassung && auswertung.aendertPlan) {
      final angepasst = planAnwenden(widget.analyse, auswertung.anpassungen);
      await ref.read(analysenProvider.notifier).speichern(angepasst.ergebnis);
      await ctrl.habitsAlsNeuMerken(angepasst.neueHabits);
    }

    await ctrl.abschliessen(
      widget.checkin.copyWith(
        erledigtAm: DateTime.now(),
        fazit: auswertung.fazit,
        zusammenfassung: mitAnpassung ? auswertung.zusammenfassung : '',
      ),
    );

    // Der Check-in zaehlt als erledigte Aufgabe des Tages.
    await ref.read(planFortschrittProvider.notifier).checkinGezaehlt();

    // Erinnerung fuer den neuen Termin setzen.
    await ref.read(checkinBenachrichtigungProvider).planen(
          ref.read(checkinControllerProvider).naechsterTermin,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(S.checkinDankeText)),
    );
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    if (_laeuft) return const _Laden();
    if (_fehler case final fehler?) {
      return _Fehler(
        fehler: fehler,
        onErneut: _auswerten,
        onTrotzdem: () => _abschliessen(mitAnpassung: false),
        blockiert: _speichert,
      );
    }

    final auswertung = _auswertung ?? CheckinAuswertung.leer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          S.checkinDankeTitel,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapM),

        if (auswertung.fazit.isNotEmpty) ...[
          SectionCard(
            title: S.checkinFazitTitel,
            icon: Icons.insights_outlined,
            child: Text(auswertung.fazit, style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],

        SectionCard(
          title: S.checkinAenderungenTitel,
          icon: Icons.tune,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (auswertung.zusammenfassung.isNotEmpty)
                Text(
                  auswertung.zusammenfassung,
                  style: const TextStyle(height: 1.5),
                ),
              if (!auswertung.aendertPlan)
                const MutedText(S.checkinKeineAenderung)
              else ...[
                const SizedBox(height: AppTheme.gapS),
                for (final anpassung in auswertung.anpassungen)
                  _AnpassungZeile(anpassung: anpassung),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTheme.gapM),

        FilledButton(
          onPressed:
              _speichert ? null : () => _abschliessen(mitAnpassung: true),
          style: FilledButton.styleFrom(shape: const StadiumBorder()),
          child: Text(
            auswertung.aendertPlan
                ? S.checkinBestaetigen
                : S.checkinAbschliessen,
          ),
        ),
        if (auswertung.aendertPlan) ...[
          const SizedBox(height: AppTheme.gapS),
          OutlinedButton(
            onPressed:
                _speichert ? null : () => _abschliessen(mitAnpassung: false),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            child: const Text('Plan unverändert lassen'),
          ),
        ],
      ],
    );
  }
}

/// Eine vorgeschlagene Aenderung: was rausfliegt, was nachkommt, warum.
class _AnpassungZeile extends StatelessWidget {
  const _AnpassungZeile({required this.anpassung});

  final HabitAnpassung anpassung;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.gapXs),
      padding: const EdgeInsets.all(AppTheme.gapS),
      decoration: BoxDecoration(
        color: farben.flaecheHoch,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (anpassung.alt.isNotEmpty)
            Text(
              anpassung.alt,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: farben.textSekundaer,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          if (anpassung.neu.isNotEmpty) ...[
            if (anpassung.alt.isNotEmpty) const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: farben.akzent,
                  ),
                ),
                Expanded(
                  child: Text(
                    anpassung.neu,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (anpassung.grund.isNotEmpty) ...[
            const SizedBox(height: 4),
            MutedText(anpassung.grund),
          ],
        ],
      ),
    );
  }
}

class _Laden extends StatelessWidget {
  const _Laden();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.gapXl),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: AppTheme.gapM),
          Text(
            S.checkinAuswertungLaeuft,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Fehler extends StatelessWidget {
  const _Fehler({
    required this.fehler,
    required this.onErneut,
    required this.onTrotzdem,
    required this.blockiert,
  });

  final AnalysisFehler fehler;
  final VoidCallback onErneut;
  final VoidCallback onTrotzdem;
  final bool blockiert;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_outlined, color: farben.warnung),
            const SizedBox(width: AppTheme.gapS),
            Expanded(
              child: Text(
                fehler.titel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(fehler.tipp),
        const SizedBox(height: AppTheme.gapM),
        FilledButton.icon(
          onPressed: blockiert ? null : onErneut,
          style: FilledButton.styleFrom(shape: const StadiumBorder()),
          icon: const Icon(Icons.refresh),
          label: const Text(S.erneutVersuchen),
        ),
        const SizedBox(height: AppTheme.gapS),
        // Der Check-in darf nicht am Netz haengen bleiben: Die Antworten sind
        // gesammelt, der Plan bleibt eben unveraendert.
        OutlinedButton(
          onPressed: blockiert ? null : onTrotzdem,
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          child: const Text('Ohne Anpassung abschließen'),
        ),
      ],
    );
  }
}
