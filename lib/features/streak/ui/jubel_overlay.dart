import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/abzeichen.dart';

/// Zeigt den Jubel-Moment fuer ein frisch erreichtes Abzeichen.
///
/// Kommt pro Abzeichen genau einmal – wer ihn schon gesehen hat, ist im
/// gespeicherten Stand vermerkt.
Future<void> zeigeJubel(BuildContext context, Abzeichen abzeichen) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _JubelDialog(abzeichen: abzeichen),
  );
}

class _JubelDialog extends StatefulWidget {
  const _JubelDialog({required this.abzeichen});

  final Abzeichen abzeichen;

  @override
  State<_JubelDialog> createState() => _JubelDialogState();
}

class _JubelDialogState extends State<_JubelDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  late final List<_Partikel> _partikel = _Partikel.streuen(36);

  bool _gestartet = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final bewegungErlaubt = !MediaQuery.disableAnimationsOf(context);

    // Bei reduzierter Bewegung bleibt es beim statischen Einblenden.
    if (!_gestartet) {
      _gestartet = true;
      if (bewegungErlaubt) {
        _controller.forward();
      } else {
        _controller.value = 1;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppTheme.gapM),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (bewegungErlaubt)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _KonfettiPainter(
                      partikel: _partikel,
                      fortschritt: _controller.value,
                      farben: [
                        farben.akzent,
                        farben.akzentZwei,
                        farben.erfolg,
                        farben.textPrimaer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          _Karte(abzeichen: widget.abzeichen, animation: _controller),
        ],
      ),
    );
  }
}

class _Karte extends StatelessWidget {
  const _Karte({required this.abzeichen, required this.animation});

  final Abzeichen abzeichen;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    final skalierung = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.35, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1).animate(skalierung),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.25),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(AppTheme.gapL),
          decoration: BoxDecoration(
            color: farben.flaeche,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: farben.akzent, width: 1.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: farben.akzent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: farben.akzent, width: 2),
                ),
                child: Icon(abzeichen.icon, size: 46, color: farben.akzent),
              ),
              const SizedBox(height: AppTheme.gapM),
              Text(
                abzeichen.jubel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              // Bei Abzeichen ohne Tageszahl ist die Ueberschrift bereits der
              // Titel – dann waere die Zeile eine reine Dopplung.
              if (abzeichen.jubel != abzeichen.titel) ...[
                const SizedBox(height: AppTheme.gapXs),
                Text(
                  abzeichen.titel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    // Primaer-Akzent: auf der Dialogflaeche traegt der
                    // Sekundaerton zu wenig Kontrast.
                    color: farben.akzent,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.gapS),
              Text(
                abzeichen.beschreibung,
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: farben.textSekundaer,
                ),
              ),
              const SizedBox(height: AppTheme.gapL),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('Weiter so'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ein Konfetti-Schnipsel mit fester Startrichtung.
class _Partikel {
  _Partikel({
    required this.richtung,
    required this.tempo,
    required this.drehung,
    required this.groesse,
    required this.farbIndex,
  });

  final double richtung;
  final double tempo;
  final double drehung;
  final double groesse;
  final int farbIndex;

  static List<_Partikel> streuen(int anzahl) {
    // Fester Startwert: der Jubel sieht bei jedem Aufruf gleich aus und ist
    // damit im Test reproduzierbar.
    final zufall = math.Random(7);
    return [
      for (var i = 0; i < anzahl; i++)
        _Partikel(
          richtung: (i / anzahl) * 2 * math.pi + zufall.nextDouble() * 0.3,
          tempo: 0.55 + zufall.nextDouble() * 0.6,
          drehung: zufall.nextDouble() * 8 - 4,
          groesse: 5 + zufall.nextDouble() * 6,
          farbIndex: zufall.nextInt(4),
        ),
    ];
  }
}

class _KonfettiPainter extends CustomPainter {
  _KonfettiPainter({
    required this.partikel,
    required this.fortschritt,
    required this.farben,
  });

  final List<_Partikel> partikel;
  final double fortschritt;
  final List<Color> farben;

  @override
  void paint(Canvas canvas, Size size) {
    if (fortschritt == 0) return;

    final mitte = Offset(size.width / 2, size.height / 2);
    final reichweite = size.shortestSide * 0.9;
    // Gegen Ende ausblenden, damit die Schnipsel nicht abrupt verschwinden.
    final deckkraft = (1 - fortschritt).clamp(0.0, 1.0);

    for (final teil in partikel) {
      final weg = fortschritt * teil.tempo;
      // Auswurf nach aussen plus Schwerkraft nach unten.
      final position = mitte +
          Offset(
            math.cos(teil.richtung) * weg * reichweite,
            math.sin(teil.richtung) * weg * reichweite +
                weg * weg * reichweite * 0.75,
          );

      final stift = Paint()
        ..color = farben[teil.farbIndex % farben.length]
            .withValues(alpha: deckkraft);

      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(teil.drehung * fortschritt * math.pi)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: teil.groesse,
            height: teil.groesse * 0.55,
          ),
          stift,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_KonfettiPainter alt) =>
      alt.fortschritt != fortschritt;
}
