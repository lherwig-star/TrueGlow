import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/marken_logo.dart';

/// Der erste Bildschirm nach dem Start: Zeichen und Name, dann weiter.
///
/// Warum es ihn gibt: Zwischen dem nativen Splash und dem ersten Screen der
/// App liegen je nach Gerät ein bis zwei Sekunden, in denen Firebase seine
/// Sitzung wiederherstellt und Hive seine Boxen öffnet. Ohne diesen Schirm
/// wäre das eine leere Fläche in Markenfarbe – mit ihm ist es der Moment, in
/// dem die App sich vorstellt.
///
/// Er entscheidet nichts selbst. Nach der Animation geht es auf [Routes.home];
/// wohin es von dort tatsächlich weitergeht – Anmeldung, Onboarding oder
/// Dashboard – entscheiden die Weichen im Router. Sonst gäbe es zwei Stellen,
/// die dieselbe Frage beantworten.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Wie lange der Schirm mindestens steht.
  ///
  /// Kurz genug, dass niemand wartet, lang genug, dass die Animation nicht
  /// abgeschnitten wirkt. Die Animation selbst dauert 700 ms; der Rest ist
  /// Standzeit, damit der Name lesbar bleibt.
  static const dauer = Duration(milliseconds: 1700);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Ein abbrechbarer Timer und kein `Future.delayed`.
  ///
  /// Der Unterschied zeigt sich, wenn der Schirm vorzeitig verlassen wird –
  /// im Test durch das Ende des Falls, in der App durch einen Deep Link. Ein
  /// laufendes `Future` liesse sich dann nicht mehr stoppen; es liefe ins
  /// Leere und wuerde in Widget-Tests als „Timer is still pending" gemeldet.
  Timer? _uhr;

  @override
  void initState() {
    super.initState();
    _uhr = Timer(SplashScreen.dauer, () {
      if (mounted) context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _uhr?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final texte = context.texte;

    // „Animationen reduzieren" respektieren: Das Zeichen ist die Information,
    // das Einblenden die Zierde. Ohne Bewegung steht beides sofort da.
    final ohneBewegung = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: farben.hintergrund,
      body: Center(
        child: _Einblendung(
          ohneBewegung: ohneBewegung,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MarkenLogo(groesse: 132, farbe: farben.akzent),
              const SizedBox(height: 28),
              Text(
                texte.appName,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: farben.textPrimaer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sanftes Einblenden mit leichter Vergrößerung.
///
/// Bewusst zurückhaltend: Von 0,88 auf 1,0 ist gerade genug, dass die Fläche
/// lebendig wirkt. Ein größerer Sprung sieht auf einem Startbildschirm nach
/// Effekt aus, und den will hier niemand sehen, sondern weiter.
class _Einblendung extends StatelessWidget {
  const _Einblendung({required this.child, required this.ohneBewegung});

  final Widget child;
  final bool ohneBewegung;

  @override
  Widget build(BuildContext context) {
    if (ohneBewegung) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, wert, kind) => Opacity(
        opacity: wert.clamp(0, 1),
        child: Transform.scale(scale: 0.88 + 0.12 * wert, child: kind),
      ),
      child: child,
    );
  }
}
