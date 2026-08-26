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
/// **Sein erstes Bild ist das letzte Bild des nativen Splash** (DECISIONS 53):
/// dieselbe flache Farbe, dasselbe Zeichen an derselben Stelle, noch kein
/// Schriftzug. Die Übergabe ist damit nichts, was man sehen könnte. Erst
/// danach blendet der Hintergrund weich in den Verlauf über und der Name
/// glüht auf.
///
/// Vorher lag genau hier der Bruch: Das erste Flutter-Bild trug bereits den
/// Verlauf **und** den fertigen Schriftzug. Am Gerät gemessen wechselte
/// beides innerhalb von zwei Bildern – ein harter Schnitt.
///
/// Er entscheidet nichts selbst. Nach der Animation geht es auf [Routes.home];
/// wohin es von dort tatsächlich weitergeht – Anmeldung, Onboarding oder
/// Dashboard – entscheiden die Weichen im Router. Sonst gäbe es zwei Stellen,
/// die dieselbe Frage beantworten.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Wie lange der Schirm mindestens steht.
  ///
  /// Kurz genug, dass niemand wartet, lang genug, dass die Blende nicht
  /// abgeschnitten wirkt: Warten, Blende und eine Standzeit, in der der Name
  /// ruhig dasteht.
  static const dauer = Duration(milliseconds: 1800);

  /// Wie lange die weiche Blende dauert.
  static const blende = Duration(milliseconds: 600);

  /// Wie lange das erste Bild unverändert stehen bleibt.
  ///
  /// Android zieht seinen eigenen Splash mit einer kurzen Animation weg,
  /// nachdem die App gezeichnet hat. Solange die läuft, liegen zwei fast
  /// gleiche Bilder übereinander – begänne die Blende schon dort, sähe man
  /// beides gleichzeitig. Die Wartezeit deckt das ab.
  static const vorlauf = Duration(milliseconds: 200);

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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Ein abbrechbarer Timer und kein `Future.delayed`.
  ///
  /// Der Unterschied zeigt sich, wenn der Schirm vorzeitig verlassen wird –
  /// im Test durch das Ende des Falls, in der App durch einen Deep Link. Ein
  /// laufendes `Future` liesse sich dann nicht mehr stoppen; es liefe ins
  /// Leere und wuerde in Widget-Tests als „Timer is still pending" gemeldet.
  Timer? _uhr;
  Timer? _start;

  /// 0 = wie der native Splash, 1 = fertiger Startbildschirm.
  late final AnimationController _blende = AnimationController(
    vsync: this,
    duration: SplashScreen.blende,
  );

  @override
  void initState() {
    super.initState();

    _uhr = Timer(SplashScreen.dauer, () {
      if (mounted) context.go(Routes.home);
    });

    // Erst nach dem ersten gezeichneten Bild: Bis dahin muss auf dem Schirm
    // exakt das stehen, was der native Splash hinterlassen hat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (MediaQuery.disableAnimationsOf(context)) {
        _blende.value = 1;
        return;
      }
      _start = Timer(SplashScreen.vorlauf, () {
        if (mounted) _blende.forward();
      });
    });
  }

  @override
  void dispose() {
    _uhr?.cancel();
    _start?.cancel();
    _blende.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final texte = context.texte;

    return AnimatedBuilder(
      animation: _blende,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_blende.value);

        // Bei t = 0 sind beide Enden dieselbe flache Farbe – das Bild ist
        // dann nicht von einer einfarbigen Fläche zu unterscheiden, und
        // genau die zeigt der native Splash.
        final oben = Color.lerp(farben.startFlaeche, farben.hintergrund, t)!;
        final unten =
            Color.lerp(farben.startFlaeche, farben.hintergrundTief, t)!;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [oben, unten],
              ),
            ),
            child: Center(
              child: Transform.translate(
                offset: Offset(0, _ausgleich(context)),
                // Das Zeichen bleibt in der Mitte stehen, der Schriftzug wird
                // darunter eingeblendet. Ein `Column` hätte beide zusammen
                // zentriert und das Zeichen dabei nach oben geschoben –
                // sichtbar als Ruck genau in dem Moment, in dem der native
                // Splash verschwindet.
                child: SizedBox.square(
                  dimension: SplashScreen.zeichenGroesse,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      MarkenLogo(groesse: SplashScreen.zeichenGroesse),
                      Positioned(
                        top: SplashScreen.zeichenGroesse +
                            SplashScreen._abstand,
                        child: _Schriftzug(anteil: t, text: texte.appName),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

/// Der Name glüht auf, statt aufzublenden.
///
/// Er kommt aus dem Nichts, wird dabei erst warm (der Sand-Ton des Zeichens)
/// und dann hell (die Textfarbe) und steigt ein Stück. Das ist der
/// Unterschied zwischen „erscheint" und „glüht auf" – und es passt zum
/// Namen, ohne dass ein Schein unter dem Text läge.
///
/// Ganz zum Schluss, damit nichts vor der Zeit lesbar wird: Die Schrift setzt
/// erst bei einem Drittel der Blende ein. Vorher ist das Bild identisch mit
/// dem nativen Splash.
class _Schriftzug extends StatelessWidget {
  const _Schriftzug({required this.anteil, required this.text});

  /// Fortschritt der Blende, 0 bis 1.
  final double anteil;
  final String text;

  /// Ab hier setzt die Schrift ein.
  static const _einsatz = 0.34;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    if (anteil <= _einsatz) return const SizedBox.shrink();

    final t = ((anteil - _einsatz) / (1 - _einsatz)).clamp(0.0, 1.0);

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - t)),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            // Von warm nach hell: das Aufglühen.
            color: Color.lerp(farben.akzent, farben.textPrimaer, t),
          ),
        ),
      ),
    );
  }
}
