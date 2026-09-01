import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../analysis/logic/analysis_controller.dart';
import '../../analysis/logic/neuberechnung.dart';
import '../../analysis/logic/modus_controller.dart';
import '../../capture/logic/capture_controller.dart';
import '../../checkin/logic/checkin_benachrichtigung.dart';
import '../../checkin/logic/checkin_controller.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/logic/module_controller.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../../plan/logic/plan_progress_repository.dart';
import '../../streak/logic/erinnerung_planer.dart';
import '../../streak/logic/streak_repository.dart';
import '../../streak/ui/jubel_overlay.dart';
import '../logic/home_tab.dart';
import 'tabs/analyse_tab.dart';
import 'tabs/fortschritt_tab.dart';
import 'tabs/heute_tab.dart';
import 'tabs/plan_tab.dart';
import 'widgets/tab_leiste.dart';

/// Die Hülle der Startseite: eine AppBar, vier Tabs, eine Leiste unten.
///
/// **Warum vier Tabs** (DECISIONS 65): Die Startseite war eine einzige sehr
/// lange Liste — Serie, Challenge, Plan-Zusammenfassung, alle Checklisten,
/// Abzeichen, und ganz unten der Knopf für eine neue Analyse. Die
/// Kernfunktion stand am Seitenende, und wer nur abhaken wollte, scrollte an
/// allem anderen vorbei.
///
/// Jeder Tab beantwortet jetzt eine Frage, und **kein Inhalt existiert
/// doppelt** — die Regel steht in [HomeTab].
///
/// **Die Hülle hält die Zustände, nicht die Tabs.** Der Check-in-Termin, die
/// Erinnerung und der Jubel-Moment hängen an der Sitzung, nicht an einem
/// Tab. Ein `IndexedStack` hält alle vier am Leben; deshalb überlebt jede
/// Scroll-Position den Wechsel.
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
    // Nacheinander, nicht nebeneinander: Beide koennen nach der Berechtigung
    // fuer Benachrichtigungen fragen, und zwei Systemdialoge gleichzeitig
    // enden damit, dass einer davon keine Antwort bekommt.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _pruefeCheckin();
      await _erinnerungEinrichten();
    });
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

  /// Fragt beim allerersten Start nach der Berechtigung und plant danach.
  ///
  /// Das Lesen des Providers ist kein Beiwerk: Er haengt sich dabei an die
  /// vier Ausloeser, die eine Neuplanung noetig machen, und bleibt danach
  /// stehen, solange die App laeuft.
  Future<void> _erinnerungEinrichten() async {
    final planer = ref.read(erinnerungPlanerProvider);
    await planer.erstmaligFragen();
    await planer.aktualisieren();
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

  /// Setzt Fotos, Modulauswahl, Modus und Analysezustand zurueck, bevor ein
  /// neuer Durchlauf startet – sonst startet der Flow mit alten Aufnahmen.
  ///
  /// Der Modus gehoert ausdruecklich dazu: Er gilt pro Analyse und nicht als
  /// Vorliebe. Wer beim letzten Mal einen neuen Look wollte, bekommt die
  /// Frage beim naechsten Mal neu gestellt.
  void _neueAnalyse() {
    ref.read(captureControllerProvider.notifier).alleVerwerfen();
    // Die Schwerpunkte aus dem Onboarding waehlen die passenden Module vor
    // (DECISIONS 60). Aendern kann der Nutzer sie auf dem naechsten
    // Bildschirm frei – vorausgewaehlt heisst nicht festgelegt.
    ref.read(moduleControllerProvider.notifier).vorbereiten(
          Fokusbereich.moduleFuer(
            ref.read(onboardingControllerProvider).fokus,
            ref.read(ausrichtungProvider),
          ),
        );
    ref.read(modusControllerProvider.notifier).zuruecksetzen();
    ref.read(analysisControllerProvider.notifier).zuruecksetzen();
    ref.read(neuberechnungProvider.notifier).state = false;
    // Ein neuer Plan heisst ein neuer Check-in-Zyklus. Der Termin steht erst,
    // wenn die Analyse da ist – bis dahin bleibt der alte Zyklus stehen.
    _checkinGeprueft = false;
    context.push(Routes.modus);
  }

  /// Denselben Weg noch einmal gehen, aber mit den Fotos von letztem Mal.
  ///
  /// Zwei Unterschiede zu [_neueAnalyse], und beide sind der ganze Punkt:
  /// Die Aufnahmen bleiben stehen (kein `alleVerwerfen`), und der Weg beginnt
  /// bei der Modulauswahl statt beim Modus – wer neu rechnet, will die
  /// Richtung ändern und nicht die Frage. Vorbelegt sind die Bereiche des
  /// letzten Reports (DECISIONS 91).
  void _neuBerechnen() {
    neuberechnungVorbereiten(ref);
    _checkinGeprueft = false;
    context.push(Routes.module);
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final aktiv = ref.watch(homeTabProvider);

    // Nach dem Frame pruefen: waehrend des Baus laesst sich kein Dialog
    // oeffnen, und der ausloesende Haken kommt aus einem anderen Widget.
    ref.watch(offenerJubelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pruefeJubel());

    // Der Punkt am „Heute"-Tab: Solange heute noch keine Aufgabe abgehakt
    // ist, gibt es etwas zu tun. Mit dem ersten Haken verschwindet er.
    //
    // Gezaehlt werden nur echte Tagesaufgaben – im selben Satz steht auch
    // die Marke eines erledigten Check-ins, und die ist kein Haken. Dieselbe
    // Rechnung wie in der Streak-Karte, damit Punkt und Kartentext nicht
    // auseinanderlaufen.
    final analyse = ref.watch(aktuelleAnalyseProvider);
    final habits = analyse?.alleHabits ?? const <String>[];
    final nochNichtsAbgehakt = analyse != null &&
        !ref.watch(planFortschrittProvider).erledigt.any(habits.contains);

    return PopScope(
      // Aus einem anderen Tab fuehrt die Zurueck-Taste erst nach „Heute" –
      // und erst von dort aus der App. Ohne das waere ein Tabwechsel eine
      // Einbahnstrasse: Die Leiste kennt keinen Verlauf, die Taste schon.
      canPop: aktiv == HomeTab.heute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(homeTabProvider.notifier).state = HomeTab.heute;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [farben.hintergrund, farben.hintergrundTief],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(texte.appName),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: texte.verlaufTitel,
                // Der Verlauf hat keinen eigenen Bildschirm mehr – er lebt
                // im Analyse-Tab. Das Symbol fuehrt dorthin, statt eine
                // zweite Liste derselben Eintraege zu oeffnen.
                onPressed: () => ref.read(homeTabProvider.notifier).state =
                    HomeTab.analyse,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: texte.einstellungenTitel,
                onPressed: () => context.push(Routes.settings),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: IndexedStack(
              index: aktiv.index,
              children: [
                HeuteTab(onNeueAnalyse: _neueAnalyse),
                const PlanTab(),
                AnalyseTab(
                  onNeueAnalyse: _neueAnalyse,
                  onNeuBerechnen: _neuBerechnen,
                ),
                const FortschrittTab(),
              ],
            ),
          ),
          bottomNavigationBar: TabLeiste(
            aktiv: aktiv,
            punktAmHeute: nochNichtsAbgehakt,
            onWechsel: (tab) =>
                ref.read(homeTabProvider.notifier).state = tab,
          ),
        ),
      ),
    );
  }
}
