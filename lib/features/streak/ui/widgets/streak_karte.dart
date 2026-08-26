import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../history/logic/analysis_repository.dart';
import '../../../plan/logic/plan_progress_repository.dart';
import '../../logic/streak_repository.dart';
import '../../../../core/l10n/texte.dart';

/// Tages-Serie oben auf der Startseite.
///
/// Die Flamme bleibt gedimmt, solange heute noch nichts abgehakt ist – so ist
/// auf einen Blick klar, ob der Tag schon gesichert ist. Beim ersten Haken des
/// Tages flackert sie kurz auf.
class StreakKarte extends ConsumerStatefulWidget {
  const StreakKarte({super.key});

  @override
  ConsumerState<StreakKarte> createState() => _StreakKarteState();
}

class _StreakKarteState extends ConsumerState<StreakKarte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flackern = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  bool? _zuletztGesichert;

  @override
  void dispose() {
    _flackern.dispose();
    super.dispose();
  }

  /// Startet das Aufflackern nur beim Wechsel "noch nichts" -> "gesichert".
  void _pruefeUebergang(bool gesichert, {required bool bewegungErlaubt}) {
    final vorher = _zuletztGesichert;
    _zuletztGesichert = gesichert;
    if (vorher == false && gesichert) {
      if (bewegungErlaubt) {
        _flackern.forward(from: 0);
      } else {
        _flackern.value = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final streak = ref.watch(streakProvider);

    // Systemeinstellung "Bewegung reduzieren" respektieren.
    final bewegungErlaubt = !MediaQuery.disableAnimationsOf(context);
    _pruefeUebergang(streak.heuteGesichert, bewegungErlaubt: bewegungErlaubt);

    final analyse = ref.watch(aktuelleAnalyseProvider);
    final habits = analyse?.alleHabits ?? const <String>[];
    final erledigt = ref
        .watch(planFortschrittProvider)
        .erledigt
        .where(habits.contains)
        .length;

    final aktiv = streak.heuteGesichert;
    final farbe = aktiv ? farben.akzent : farben.textSekundaer;

    return SectionCard(
      child: Row(
        children: [
          _Flamme(
            animation: _flackern,
            farbe: farbe,
            aktiv: aktiv,
            bewegungErlaubt: bewegungErlaubt,
          ),
          const SizedBox(width: AppTheme.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zahl gross, "Tage am Stueck" als Unterzeile darunter –
                // nebeneinander laeuft die Zeile auf schmalen Geraeten ueber.
                Text(
                  '${streak.aktuell}',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: farbe,
                  ),
                ),
                Text(
                  texte.streakTage,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: farben.textSekundaer,
                  ),
                ),
                const SizedBox(height: AppTheme.gapXs),
                MutedText(
                  switch (habits.isEmpty) {
                    // „Neustart" steht vor allem anderen: Wer die Serie
                    // verloren hat, soll nicht als Erstes eine nackte Null
                    // mit einer Aufgabenzahl daneben lesen.
                    _ when streak.neustartNachSerie => texte.streakNeustart,
                    true => texte.streakKeineAufgaben,
                    false when erledigt == habits.length =>
                      texte.streakAllesErledigt,
                    false when erledigt == 0 =>
                      texte.streakNichtsAbgehakt,
                    false => texte.streakHeuteErledigt(erledigt, habits.length),
                  },
                ),
                if (streak.rekord > 0 && streak.rekord != streak.aktuell) ...[
                  const SizedBox(height: 2),
                  MutedText(texte.streakRekord(streak.rekord)),
                ],
                if (streak.ungemeldeteJoker > 0) ...[
                  const SizedBox(height: AppTheme.gapXs),
                  _JokerHinweis(anzahl: streak.ungemeldeteJoker),
                ],
              ],
            ),
          ),
          _JokerVorrat(uebrig: streak.jokerUebrig),
        ],
      ),
    );
  }
}

/// „Ein Joker hat deinen Streak gerettet." – einmal, dann abgehakt.
///
/// Der Hinweis meldet sich selbst als gesehen, sobald er einmal gezeichnet
/// wurde. Er steht bewusst als Zeile in der Karte und nicht als Dialog: Es
/// ist eine gute Nachricht, kein Vorgang, den jemand bestätigen muss.
class _JokerHinweis extends ConsumerStatefulWidget {
  const _JokerHinweis({required this.anzahl});

  final int anzahl;

  @override
  ConsumerState<_JokerHinweis> createState() => _JokerHinweisState();
}

class _JokerHinweisState extends ConsumerState<_JokerHinweis> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(streakProvider.notifier).jokerGemeldet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_moon_outlined, size: 16, color: farben.akzentZwei),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.texte.streakJokerGerettet(widget.anzahl),
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: farben.akzentZwei,
            ),
          ),
        ),
      ],
    );
  }
}

/// Die Joker des laufenden Monats als kleine Schilde – verbrauchte blass.
class _JokerVorrat extends StatelessWidget {
  const _JokerVorrat({required this.uebrig});

  final int uebrig;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final texte = context.texte;

    return Tooltip(
      message: texte.streakJokerErklaerung(StreakRepository.jokerProMonat),
      child: Semantics(
        label: texte.streakJokerUebrig(uebrig),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < StreakRepository.jokerProMonat; i += 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Icon(
                      i < uebrig
                          ? Icons.shield_moon
                          : Icons.shield_moon_outlined,
                      size: 18,
                      color: i < uebrig
                          ? farben.akzentZwei
                          : farben.textSekundaer.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            ExcludeSemantics(
              child: Text(
                '$uebrig/${StreakRepository.jokerProMonat}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: farben.textSekundaer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Flamme extends StatelessWidget {
  const _Flamme({
    required this.animation,
    required this.farbe,
    required this.aktiv,
    required this.bewegungErlaubt,
  });

  final Animation<double> animation;
  final Color farbe;
  final bool aktiv;
  final bool bewegungErlaubt;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, kind) {
        // Kurzes Aufflackern: einmal groesser werden und zurueck.
        final puls = bewegungErlaubt
            ? 1 + 0.28 * (1 - (animation.value * 2 - 1).abs())
            : 1.0;
        return Transform.scale(scale: puls, child: kind);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: farbe.withValues(alpha: aktiv ? 0.18 : 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: farbe.withValues(alpha: aktiv ? 0.8 : 0.25),
            width: 1.6,
          ),
        ),
        child: Icon(
          aktiv
              ? Icons.local_fire_department
              : Icons.local_fire_department_outlined,
          size: 32,
          color: farbe,
        ),
      ),
    );
  }
}
