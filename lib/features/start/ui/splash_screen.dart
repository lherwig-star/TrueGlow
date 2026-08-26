import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/marke.dart';
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
  /// Kommt aus [Marke] und wird dort aus derselben Zahl gerechnet, mit der
  /// `tool/marke_erzeugen.dart` das Splash-PNG erzeugt. Wer hier eine eigene
  /// Zahl hinschreibt, baut denselben Fehler wieder ein, der in
  /// DECISIONS 52 steht: Das Zeichen sprang beim Übergang um ein Fünftel.
  ///
  /// Auf Geräten vor Android 12 ist das Motiv etwas kleiner; dort wächst es
  /// beim Übergang leicht. Das ist eine weiche Bewegung, kein Bruch.
  static const zeichenGroesse = Marke.splashZeichenDp;

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
      backgroundColor: Colors.transparent,
      // Derselbe Verlauf wie auf jeder Seite der App. Ohne ihn wäre der
      // Start flaches Petrol und der Sprung käme eine Sekunde später – beim
      // Wechsel auf die Startseite (DECISIONS 52).
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [farben.hintergrund, farben.hintergrundTief],
          ),
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, _ausgleich(context)),
            // Das Zeichen bleibt in der Mitte stehen, der Schriftzug wird
            // darunter eingeblendet. Ein `Column` hätte beide zusammen
            // zentriert und das Zeichen dabei nach oben geschoben – sichtbar
            // als Ruck genau in dem Moment, in dem der native Splash
            // verschwindet.
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
        ),
      ),
    );
  }

  /// Wie weit das Zeichen nach unten muss, um in der **Bildschirmmitte** zu
  /// stehen.
  ///
  /// Der native Splash gehört dem System und wird über den ganzen Bildschirm
  /// gezeichnet – sein Symbol sitzt exakt in dessen Mitte. Das Fenster der
  /// App ist kleiner: Es endet über der Navigationsleiste, weil
  /// `windowDrawsSystemBarBackgrounds` aus ist. Alles, was die App
  /// zentriert, sitzt deshalb um deren halbe Höhe zu hoch.
  ///
  /// Am Testgerät waren das 24 dp, und genau so weit sprang das Zeichen beim
  /// Übergang nach oben (DECISIONS 52).
  ///
  /// **Warum nicht über MediaQuery.** `MediaQuery.size` ist die Größe des
  /// *Fensters*, und die Navigationsleiste liegt außerhalb davon –
  /// `viewPadding.bottom` ist hier 0. Die App kann den Unterschied nur über
  /// den Bildschirm selbst sehen: [Display.size] ist das ganze Panel,
  /// `physicalSize` das Stück, das die App davon bekommt.
  ///
  /// Die Obergrenze ist ein Sicherheitsnetz. Bekäme die App aus einem
  /// anderen Grund viel weniger als den Bildschirm – geteilter Bildschirm,
  /// schwebendes Fenster –, wanderte das Zeichen sonst aus dem Bild.
  static double _ausgleich(BuildContext context) {
    final sicht = View.of(context);
    final dichte = sicht.devicePixelRatio;
    if (dichte <= 0) return 0;

    final bildschirm = sicht.display.size.height;
    final fenster = sicht.physicalSize.height;
    if (!bildschirm.isFinite || !fenster.isFinite) return 0;

    // Der ungenutzte Streifen liegt unten: Oben zeichnet die App hinter die
    // Statusleiste, unten nicht hinter die Navigationsleiste.
    return ((bildschirm - fenster) / dichte / 2).clamp(0.0, 40.0);
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
