import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/diagnose/diagnose_dienst.dart';
import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../analysis/models/analysis_result.dart';
import '../../history/logic/analysis_repository.dart';
import '../logic/checkin_controller.dart';
import '../logic/checkin_flow.dart';
import '../logic/wirkungsfragen.dart';
import '../models/checkin.dart';
import 'widgets/checkin_abschluss.dart';
import 'widgets/fortschrittsfoto_schritt.dart';
import 'widgets/habit_rating_liste.dart';
import 'widgets/vergleich_ansicht.dart';
import 'widgets/wirkungs_liste.dart';

/// Der gefuehrte Check-in. Welche Schritte erscheinen, haengt an der Stufe:
/// Tag 7 fragt nur nach Alltagstauglichkeit, spaeter kommen Wirkungsfragen und
/// beim Wirkungs-Check ein optionales Fortschrittsfoto dazu.
///
/// Der Zwischenstand liegt im Controller und nicht im State dieses Screens –
/// so ueberlebt er Abbruch, Kamera-Abstecher und App-Neustart.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Entwurf anlegen, sobald der Screen steht: ab jetzt ist der Check-in
    // angefangen und jede Antwort landet sofort im Speicher.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(checkinControllerProvider.notifier);
      final offen = ctrl.faelligerCheckin();
      if (offen != null && ref.read(checkinControllerProvider).entwurf == null) {
        ctrl.entwurfSichern(offen);
        ref
            .read(diagnoseDienstProvider)
            .melde(DiagnoseEreignis.checkinGestartet);
      }
    });
  }

  void _weiter(int anzahlSchritte) {
    if (_index < anzahlSchritte - 1) setState(() => _index++);
  }

  void _zurueck() {
    if (_index > 0) {
      setState(() => _index--);
      return;
    }
    _verlassen();
  }

  /// Abbrechen heisst hier: Zwischenstand behalten und spaeter weitermachen.
  Future<void> _verlassen() async {
    final weg = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.texte.checkinAbbrechenTitel),
        content: Text(context.texte.checkinAbbrechenText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.texte.checkinFortsetzen),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.texte.checkinVerlassen),
          ),
        ],
      ),
    );

    if (weg == true && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final zustand = ref.watch(checkinControllerProvider);
    final analyse = ref.watch(aktuelleAnalyseProvider);
    final checkin = zustand.entwurf;

    if (analyse == null || checkin == null) {
      return AppPage(
        title: texte.checkinTitel,
        children: [
          SizedBox(height: AppTheme.gapXl),
          MutedText(
            'Gerade steht kein Check-in an.',
            align: TextAlign.center,
          ),
        ],
      );
    }

    final schritte = _schritte(checkin, analyse, zustand);
    final index = _index.clamp(0, schritte.length - 1);
    final schritt = schritte[index];
    final letzter = index == schritte.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _zurueck();
      },
      child: AppPage(
        title: checkin.typ.titel,
        showBackButton: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _zurueck,
        ),
        bottomFade: true,
        bottomBar: letzter
            ? null
            : FilledButton(
                onPressed: schrittErfuellt(schritt, checkin)
                    ? () => _weiter(schritte.length)
                    : null,
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                child: Text(_beschriftung(schritt)),
              ),
        children: [
          _Fortschritt(aktuell: index, gesamt: schritte.length),
          const SizedBox(height: AppTheme.gapM),
          switch (schritt) {
            IntroSchritt() => _Intro(checkin: checkin),
            HabitsSchritt(:final habits) => HabitRatingListe(
                checkin: checkin,
                habits: habits,
                nurNachzufragen: checkin.typ == CheckinTyp.zwischen,
              ),
            WirkungSchritt(:final fragen) =>
              WirkungsListe(checkin: checkin, fragen: fragen),
            ErwartungSchritt(:final text) => _Erwartung(text: text),
            FotoSchritt() => FortschrittsfotoSchritt(checkin: checkin),
            VergleichSchritt() => VergleichAnsicht(checkin: checkin),
            AbschlussSchritt() => CheckinAbschluss(
                checkin: checkin,
                analyse: analyse,
              ),
          },
        ],
      ),
    );
  }

  /// Die Schrittfolge dieses Check-ins.
  List<CheckinSchritt> _schritte(
    Checkin checkin,
    AnalysisResult analyse,
    CheckinZustand zustand,
  ) {
    return baueCheckinFlow(
      checkin: checkin,
      habits: _abzufragendeHabits(checkin, analyse, zustand),
      fragen: Wirkungsfragen.fuer(checkin.typ, analyse.module),
      erwartung: Wirkungsfragen.erwartung(analyse.module),
      // Ohne Erstfoto gibt es nichts zu vergleichen – dann entfaellt das
      // Fortschrittsfoto samt Vorher/Nachher.
      fotoMoeglich: checkin.typ.mitFortschrittsfoto,
    );
  }

  /// Welche Habits abgefragt werden.
  ///
  /// Tag 7 und der Wirkungs-Check nehmen alle. Der Zwischencheck nur die,
  /// die zuletzt gehakt haben oder seitdem angepasst wurden – alles andere
  /// laeuft ja bereits.
  List<String> _abzufragendeHabits(
    Checkin checkin,
    AnalysisResult analyse,
    CheckinZustand zustand,
  ) {
    final alle = analyse.alleHabits;
    if (checkin.typ != CheckinTyp.zwischen) return alle;

    final nachzufragen = {
      ...?zustand.letzter?.nachzufragen,
      ...zustand.neueHabits.keys,
    };
    return alle.where(nachzufragen.contains).toList();
  }

  String _beschriftung(CheckinSchritt schritt) => switch (schritt) {
        IntroSchritt() => 'Los geht es',
        _ => context.texte.weiter,
      };
}

/// Balkenanzeige wie im Aufnahme-Flow – gleiche Optik, gleiche Erwartung.
class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.aktuell, required this.gesamt});

  final int aktuell;
  final int gesamt;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < gesamt; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: AppTheme.animation(
                    context,
                    const Duration(milliseconds: 250),
                  ),
                  height: 4,
                  margin: EdgeInsets.only(right: i == gesamt - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: i <= aktuell ? farben.akzent : farben.rand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.gapXs),
        MutedText('${aktuell + 1} von $gesamt'),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.checkin});

  final Checkin checkin;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: farben.akzent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.waving_hand_outlined,
            color: farben.akzent,
            size: 30,
          ),
        ),
        const SizedBox(height: AppTheme.gapM),
        Text(
          checkin.typ.titel,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        Text(checkin.typ.intro, style: const TextStyle(height: 1.5)),
        const SizedBox(height: AppTheme.gapM),
        SectionCard(
          title: 'Unter einer Minute',
          icon: Icons.timer_outlined,
          child: const MutedText(
            'Du kannst jederzeit abbrechen – dein Zwischenstand bleibt '
            'gespeichert.',
          ),
        ),
      ],
    );
  }
}

class _Erwartung extends StatelessWidget {
  const _Erwartung({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texte.checkinHinweisTitel,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapM),
        SectionCard(
          title: 'Du bist auf Kurs',
          icon: Icons.schedule_outlined,
          child: Text(text, style: const TextStyle(height: 1.5)),
        ),
      ],
    );
  }
}
