import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/wochen_challenge.dart';

/// Die Challenge der laufenden Woche.
///
/// Eine kleine Extra-Aufgabe über die Tagesliste hinaus, aus einem festen
/// Vorrat von zehn Vorlagen rotiert. Alles daran wird aus den vorhandenen
/// Haken gerechnet – kein Modellaufruf, keine Kosten.
///
/// Eine nicht geschaffte Challenge verschwindet am Montag kommentarlos. Es
/// gibt kein „leider verpasst": Die naechste steht schon da, und das ist die
/// einzige Nachricht, die hier hilft.
class ChallengeKarte extends ConsumerWidget {
  const ChallengeKarte({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(wochenChallengeProvider);
    if (challenge == null) return const SizedBox.shrink();

    final texte = context.texte;
    final farben = context.farben;
    final geschafft = challenge.geschafft;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: SectionCard(
        title: texte.challengeTitel,
        icon: challenge.vorlage.icon,
        trailing: geschafft
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 18, color: farben.erreicht),
                  const SizedBox(width: 4),
                  Text(
                    texte.challengeGeschafft,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: farben.erreicht,
                    ),
                  ),
                ],
              )
            : Text(
                texte.challengeStand(challenge.stand, challenge.ziel),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: farben.textSekundaer,
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.vorlage.art.text(texte, challenge.ziel),
              style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.gapS),
            Semantics(
              label: texte.challengeStand(challenge.stand, challenge.ziel),
              child: _Segmente(
                gefuellt: challenge.gefuellteSegmente,
                gesamt: challenge.segmente,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Der Fortschritt als Segmente statt als Balken.
///
/// Ein durchgehender Balken sagt „irgendwo dazwischen". Segmente sagen
/// „drei von vier" – dieselbe Information, aber abzählbar, und man sieht
/// ohne zu rechnen, wie viel noch fehlt (DECISIONS 50).
///
/// Beim Öffnen füllen sie sich nacheinander, jedes in gut einer Zehntel-
/// sekunde und der ganze Lauf unter einer halben. Bei „Bewegung reduzieren"
/// stehen sie sofort.
class _Segmente extends StatelessWidget {
  const _Segmente({required this.gefuellt, required this.gesamt});

  final int gefuellt;
  final int gesamt;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final bewegungErlaubt = !MediaQuery.disableAnimationsOf(context);

    return Row(
      children: [
        for (var i = 0; i < gesamt; i += 1) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: _Segment(
              voll: i < gefuellt,
              // Gestaffelt, aber nur so weit, dass der letzte Punkt noch
              // innerhalb einer halben Sekunde steht.
              verzoegerung: bewegungErlaubt
                  ? Duration(milliseconds: 40 * i)
                  : Duration.zero,
              bewegungErlaubt: bewegungErlaubt,
              gefuellteFarbe: farben.erreichtFlaeche,
              leereFarbe: farben.erreichtLeer,
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.voll,
    required this.verzoegerung,
    required this.bewegungErlaubt,
    required this.gefuellteFarbe,
    required this.leereFarbe,
  });

  final bool voll;
  final Duration verzoegerung;
  final bool bewegungErlaubt;
  final Color gefuellteFarbe;
  final Color leereFarbe;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _an = false;
  Timer? _start;

  @override
  void initState() {
    super.initState();
    if (!widget.bewegungErlaubt) {
      _an = true;
      return;
    }
    _start = Timer(widget.verzoegerung, () {
      if (mounted) setState(() => _an = true);
    });
  }

  @override
  void didUpdateWidget(_Segment alt) {
    super.didUpdateWidget(alt);
    // Ein Segment, das nachträglich voll wird, füllt sich ohne Wartezeit –
    // der Nutzer hat gerade eben etwas abgehakt.
    if (widget.voll != alt.voll) _an = true;
  }

  @override
  void dispose() {
    _start?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voll = widget.voll && _an;

    return AnimatedContainer(
      duration: Duration(milliseconds: widget.bewegungErlaubt ? 220 : 0),
      curve: Curves.easeOutCubic,
      height: 8,
      decoration: BoxDecoration(
        color: voll ? widget.gefuellteFarbe : widget.leereFarbe,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
