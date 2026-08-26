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
/// **Er setzt genau dort an, wo der native Splash aufhört** (DECISIONS 49).
/// Das Zeichen steht in derselben Größe an derselben Stelle – exakt in der
/// Bildschirmmitte – und blendet deshalb nicht ein: Es ist ja schon da. Nur
/// der Schriftzug kommt hinzu, unterhalb des Zeichens, ohne es zu
/// verschieben. Genau das war vorher der sichtbare Bruch: zwei Bildschirme,
/// die beide dasselbe Zeichen aufblenden, an zwei verschiedenen Stellen.
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

  /// Kantenlänge des Zeichens – dieselbe wie beim nativen Splash.
  ///
  /// Ab Android 12 zeichnet das System das Symbol in eine Fläche von 240 dp;
  /// unser Motiv füllt davon 52 % (`motivAnteil` in
  /// `tool/marke_erzeugen.dart`), also rund 125 dp. Wer diese Zahl ändert,
  /// muss dort nachsehen — sonst springt das Zeichen beim Start.
  ///
  /// Auf Geräten vor Android 12 ist das Motiv etwas kleiner (rund 102 dp);
  /// dort wächst es beim Übergang leicht. Das ist eine weiche Bewegung, kein
  /// Bruch, und betrifft nur noch alte Geräte.
  static const zeichenGroesse = 125.0;

  /// Abstand zwischen Zeichen und Schriftzug.
  static const _abstand = 28.0;

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
        // Das Zeichen bleibt in der Mitte stehen, der Schriftzug wird
        // darunter eingeblendet. Ein `Column` haette beide zusammen
        // zentriert und das Zeichen dabei nach oben geschoben – sichtbar als
        // Ruck genau in dem Moment, in dem der native Splash verschwindet.
        child: SizedBox.square(
          dimension: SplashScreen.zeichenGroesse,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              MarkenLogo(
                groesse: SplashScreen.zeichenGroesse,
                farbe: farben.akzent,
              ),
              Positioned(
                top: SplashScreen.zeichenGroesse + SplashScreen._abstand,
                child: _Schriftzug(
                  ohneBewegung: ohneBewegung,
                  child: Text(
                    texte.appName,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: farben.textPrimaer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der Schriftzug blendet ein und kommt dabei ein Stück von unten.
///
/// Bewusst zurückhaltend: acht Pixel Weg und eine halbe Sekunde. Das Zeichen
/// darüber bewegt sich nicht — es stand schon vor dem ersten Flutter-Frame
/// da, und alles, was es jetzt noch täte, wäre ein zweites Aufblenden.
class _Schriftzug extends StatelessWidget {
  const _Schriftzug({required this.child, required this.ohneBewegung});

  final Widget child;
  final bool ohneBewegung;

  @override
  Widget build(BuildContext context) {
    if (ohneBewegung) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, wert, kind) => Opacity(
        opacity: wert.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - wert)),
          child: kind,
        ),
      ),
      child: child,
    );
  }
}
