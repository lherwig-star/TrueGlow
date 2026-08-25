import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/diagnose/diagnose_dienst.dart';
import '../../../../core/l10n/texte.dart';
import '../../../../core/netz/wiederholung.dart';
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
import '../../../consent/logic/einwilligung_controller.dart';
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

  /// Abbruchwunsch der laufenden Auswertung.
  Abbruch? _abbruch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _auswerten());
  }

  /// Bricht die Auswertung ab und schliesst den Check-in ohne Anpassung ab.
  ///
  /// Der Check-in ist damit nicht verloren: Die Antworten stehen, nur die
  /// KI-Nachjustierung entfaellt. Genau dafuer war der Weg „ohne Auswertung
  /// abschliessen" schon immer da – er wird hier nur erreichbar, waehrend
  /// noch gewartet wird.
  void _abbrechen() {
    _abbruch?.ausloesen();
    if (!mounted) return;
    setState(() {
      _laeuft = false;
      _fehler = null;
      _auswertung = CheckinAuswertung.leer;
    });
  }

  Future<void> _auswerten() async {
    final abbruch = _abbruch = Abbruch();
    setState(() {
      _laeuft = true;
      _fehler = null;
    });

    // Ohne Foto-Einwilligung laeuft der Check-in ohne Bilder weiter, statt zu
    // scheitern: Die Rueckmeldung zum Plan ist das Wesentliche, der
    // Bildvergleich die Zugabe.
    final mitFotos = ref.read(analyseErlaubtProvider);

    final erstfoto = mitFotos
        ? ref
            .read(captureControllerProvider)
            .foto(CheckinController.fortschrittsTyp)
        : null;
    final neu = mitFotos ? widget.checkin.fortschrittsfoto : null;

    try {
      final auswertung =
          await ref.read(checkinServiceProvider).auswerten(
                checkin: widget.checkin,
                analyse: widget.analyse,
                historie: ref.read(checkinControllerProvider).historie,
                erstfoto: erstfoto == null ? null : File(erstfoto.pfad),
                fortschrittsfoto: neu == null ? null : File(neu),
                abbruch: abbruch,
              );

      if (!mounted) return;
      setState(() {
        _auswertung = auswertung;
        _laeuft = false;
      });
    } on AbbruchException {
      // Der Abbruch hat den Zustand schon gesetzt.
      return;
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
    ref
        .read(diagnoseDienstProvider)
        .melde(DiagnoseEreignis.checkinAbgeschlossen);

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
      SnackBar(content: Text(context.texte.checkinDankeText)),
    );
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    if (_laeuft) return _Laden(onAbbrechen: _abbrechen);
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
        Text(
          texte.checkinDankeTitel,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapM),

        if (auswertung.fazit.isNotEmpty) ...[
          SectionCard(
            title: texte.checkinFazitTitel,
            icon: Icons.insights_outlined,
            child: Text(auswertung.fazit, style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],

        SectionCard(
          title: texte.checkinAenderungenTitel,
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
                MutedText(texte.checkinKeineAenderung)
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
                ? texte.checkinBestaetigen
                : texte.checkinAbschliessen,
          ),
        ),
        if (auswertung.aendertPlan) ...[
          const SizedBox(height: AppTheme.gapS),
          OutlinedButton(
            onPressed:
                _speichert ? null : () => _abschliessen(mitAnpassung: false),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            child: Text(texte.checkinPlanUnveraendert),
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
  const _Laden({required this.onAbbrechen});

  final VoidCallback onAbbrechen;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXl),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppTheme.gapM),
          Text(
            texte.checkinAuswertungLaeuft,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.gapS),
          // Bei schlechter Verbindung laeuft der Wiederholungszyklus bis zu
          // drei Versuche durch. Ohne Ausweg bliebe nur, die App zu
          // schliessen – und der Check-in waere ganz weg.
          TextButton(
            onPressed: onAbbrechen,
            child: const Text('Ohne Auswertung fortfahren'),
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
    final texte = context.texte;
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
                fehler.titel(texte),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(fehler.tipp(texte)),
        const SizedBox(height: AppTheme.gapM),
        FilledButton.icon(
          onPressed: blockiert ? null : onErneut,
          style: FilledButton.styleFrom(shape: const StadiumBorder()),
          icon: const Icon(Icons.refresh),
          label: Text(texte.erneutVersuchen),
        ),
        const SizedBox(height: AppTheme.gapS),
        // Der Check-in darf nicht am Netz haengen bleiben: Die Antworten sind
        // gesammelt, der Plan bleibt eben unveraendert.
        OutlinedButton(
          onPressed: blockiert ? null : onTrotzdem,
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
          child: Text(context.texte.checkinOhneAnpassung),
        ),
      ],
    );
  }
}
