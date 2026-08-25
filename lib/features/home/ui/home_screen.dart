import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/datum.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../analysis/logic/analysis_controller.dart';
import '../../analysis/models/analysis_result.dart';
import '../../analysis/ui/unterbrochen_karte.dart';
import '../../capture/logic/capture_controller.dart';
import '../../checkin/logic/checkin_benachrichtigung.dart';
import '../../checkin/logic/checkin_controller.dart';
import '../../checkin/ui/widgets/checkin_karte.dart';
import '../../modules/logic/module_controller.dart';
import '../../history/logic/analysis_repository.dart';
import '../../plan/ui/widgets/checkliste_karte.dart';
import '../../streak/logic/streak_repository.dart';
import '../../streak/ui/jubel_overlay.dart';
import '../../streak/ui/widgets/abzeichen_sektion.dart';
import '../../streak/ui/widgets/streak_karte.dart';

/// Dashboard. Zeigt Serie, Abzeichen und entweder den Einstieg in die erste
/// Analyse oder den aktuellen Plan mit den Tages-Checklisten.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Verhindert, dass zwei Jubel-Dialoge uebereinander landen.
  bool _jubelLaeuft = false;

  /// Der Zeitplan wird pro App-Start einmal geprueft.
  bool _checkinGeprueft = false;

  @override
  void initState() {
    super.initState();
    // Beim Start pruefen statt nur auf die Push zu vertrauen: Erinnerungen
    // koennen abgeschaltet sein, faellig ist der Check-in trotzdem.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pruefeCheckin());
  }

  /// Startet den Check-in-Zyklus, sobald ein Plan existiert, und haelt die
  /// Erinnerung auf dem aktuellen Termin.
  Future<void> _pruefeCheckin() async {
    if (_checkinGeprueft || !mounted) return;
    _checkinGeprueft = true;

    final analyse = ref.read(aktuelleAnalyseProvider);
    if (analyse == null) return;

    final ctrl = ref.read(checkinControllerProvider.notifier);
    final vorher = ref.read(checkinControllerProvider).planStart;
    ctrl.planSicherstellen(analyse.erstelltAm);

    final benachrichtigung = ref.read(checkinBenachrichtigungProvider);
    // Beim allerersten Plan einmalig nach der Berechtigung fragen.
    if (vorher == null) await benachrichtigung.berechtigungAnfragen();

    await benachrichtigung.planen(
      ref.read(checkinControllerProvider).naechsterTermin,
    );
  }

  /// Zeigt den Jubel-Moment fuer ein frisch erreichtes Abzeichen und merkt
  /// ihn danach als gesehen vor.
  Future<void> _pruefeJubel() async {
    if (_jubelLaeuft) return;

    final abzeichen = ref.read(offenerJubelProvider);
    if (abzeichen == null || !mounted) return;

    _jubelLaeuft = true;
    try {
      await zeigeJubel(context, abzeichen);
      await ref.read(streakProvider.notifier).gefeiert(abzeichen);
    } finally {
      _jubelLaeuft = false;
    }
  }

  /// Setzt Fotos, Modulauswahl und Analysezustand zurueck, bevor ein neuer
  /// Durchlauf startet – sonst startet der Flow mit alten Aufnahmen.
  void _neueAnalyse(BuildContext context, WidgetRef ref) {
    ref.read(captureControllerProvider.notifier).alleVerwerfen();
    ref.read(moduleControllerProvider.notifier).zuruecksetzen();
    ref.read(analysisControllerProvider.notifier).zuruecksetzen();
    // Ein neuer Plan heisst ein neuer Check-in-Zyklus. Der Termin steht erst,
    // wenn die Analyse da ist – bis dahin bleibt der alte Zyklus stehen.
    _checkinGeprueft = false;
    context.push(Routes.module);
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final analyse = ref.watch(aktuelleAnalyseProvider);

    // Nach dem Frame pruefen: waehrend des Baus laesst sich kein Dialog
    // oeffnen, und der ausloesende Haken kommt aus einem anderen Widget.
    ref.watch(offenerJubelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pruefeJubel());

    return AppPage(
      title: texte.appName,
      showBackButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: texte.verlaufTitel,
          onPressed: () => context.push(Routes.history),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: texte.einstellungenTitel,
          onPressed: () => context.push(Routes.settings),
        ),
      ],
      children: [
        // Steht ganz oben und nur, wenn es etwas zu sagen gibt: Ein
        // Programmlauf, der mitten in der Analyse endete, hinterlaesst sonst
        // gar keine Spur.
        const UnterbrochenKarte(),
        ...analyse == null
            ? _ohneAnalyse(context, ref)
            : _mitAnalyse(context, ref, analyse),
      ],
    );
  }

  List<Widget> _ohneAnalyse(BuildContext context, WidgetRef ref) => [
        const SizedBox(height: AppTheme.gapL),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.farben.akzent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 42,
              color: context.farben.akzent,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.gapM),
        Text(
          context.texte.homeLeerTitel,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.gapM),
          child: MutedText(context.texte.homeLeerText, align: TextAlign.center),
        ),
        const SizedBox(height: AppTheme.gapL),
        FilledButton.icon(
          onPressed: () => _neueAnalyse(context, ref),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(context.texte.homeAnalyseStarten),
        ),
      ];

  List<Widget> _mitAnalyse(
    BuildContext context,
    WidgetRef ref,
    AnalysisResult analyse,
  ) {
    return [
      const CheckinKarte(),
      const StreakKarte(),
      const SizedBox(height: AppTheme.gapS),
      SectionCard(
        title: 'Dein Plan',
        icon: Icons.flag_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MutedText(
              '${Datum.relativ(analyse.erstelltAm)} erstellt · '
              '${analyse.anzahlEmpfehlungen} Empfehlungen',
            ),
            if (analyse.gesichtsform.isNotEmpty) ...[
              const SizedBox(height: AppTheme.gapS),
              Text(
                analyse.gesichtsform,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.5),
              ),
            ],
            const CheckinVorschau(),
            const SizedBox(height: AppTheme.gapM),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push(Routes.plan),
                    child: Text(context.texte.homePlanAnsehen),
                  ),
                ),
                const SizedBox(width: AppTheme.gapS),
                SizedBox(
                  width: 120,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('${Routes.result}/${analyse.id}'),
                    child: const Text('Analyse'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTheme.gapM),
      // Eine Checkliste pro Kapitel – Ueberschrift nennt den Bereich.
      for (final kapitel in analyse.checklisten) ...[
        ChecklisteKarte(kapitel: kapitel),
        const SizedBox(height: AppTheme.gapS),
      ],
      const SizedBox(height: AppTheme.gapS),
      const AbzeichenSektion(),
      const SizedBox(height: AppTheme.gapM),
      OutlinedButton.icon(
        onPressed: () => _neueAnalyse(context, ref),
        icon: const Icon(Icons.refresh),
        label: Text(context.texte.homeNeueAnalyse),
      ),
    ];
  }
}
