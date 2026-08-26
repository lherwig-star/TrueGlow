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
/// **Er zeigt vom ersten Bild an den Endzustand** (DECISIONS 55): Verlauf,
/// Zeichen und Schriftzug gleichzeitig. Hier läuft nichts an, hier wartet
/// nichts, hier blendet nichts ein.
///
/// **Die eine Überblendung macht Android**, nicht dieser Schirm – siehe
/// `MainActivity.kt`. Der Grund steht dort ausführlich und kurz hier: Eine
/// Blende in Dart startet, sobald der Schirm gebaut ist. Bis sein Inhalt aber
/// tatsächlich auf dem Bildschirm ankommt, ist sie vorbei. Zweimal am Gerät
/// gemessen, zweimal war das erste sichtbare Bild schon der Endzustand – die
/// Blende lief hinter dem Vorhang. Deshalb liegt sie jetzt im Vorhang selbst:
/// Android blendet seinen Start-Bildschirm über diesem fertigen Bild weg.
///
/// Er entscheidet nichts selbst. Nach [dauer] geht es auf [Routes.home];
/// wohin es von dort tatsächlich weitergeht – Anmeldung, Onboarding oder
/// Dashboard – entscheiden die Weichen im Router. Sonst gäbe es zwei Stellen,
/// die dieselbe Frage beantworten.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Wie lange der Schirm mindestens steht.
  ///
  /// Kurz genug, dass niemand wartet, lang genug, dass der Name danach noch
  /// ruhig dasteht.
  static const dauer = Duration(milliseconds: 1600);

  /// Die eine Überblendung – vom flachen Bild des System-Splash auf dieses.
  ///
  /// Ausgeführt wird sie in `MainActivity.kt`; die Zahl steht hier, weil hier
  /// jeder nachsieht, der den Start versteht will. `splash_test.dart` hält
  /// beide Stellen auf demselben Wert.
  static const blende = Duration(milliseconds: 300);

  /// Kantenlänge des Zeichens – dieselbe wie beim nativen Splash.
  ///
  /// Kommt aus [Marke] und wird dort aus derselben Zahl gerechnet, mit der
  /// `tool/marke_erzeugen.dart` das Splash-PNG erzeugt. Wer hier eine eigene
  /// Zahl hinschreibt, baut denselben Fehler wieder ein, der in
  /// DECISIONS 52 steht: Das Zeichen sprang beim Übergang um ein Fünftel.
  ///
  /// Es ist zugleich die Bedingung dafür, dass die Überblendung sauber
  /// aussieht: Weil oben und unten dasselbe Zeichen an derselben Stelle
  /// liegt, bleibt es beim Überblenden unverändert stehen.
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

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            // Das Zeichen bleibt in der Mitte stehen, der Schriftzug hängt
            // darunter. Ein `Column` hätte beide zusammen zentriert und das
            // Zeichen dabei nach oben geschoben – und damit genau die Stelle
            // verschoben, an der der System-Splash sein Zeichen hat.
            child: SizedBox.square(
              dimension: SplashScreen.zeichenGroesse,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  MarkenLogo(groesse: SplashScreen.zeichenGroesse),
                  Positioned(
                    top: SplashScreen.zeichenGroesse + SplashScreen._abstand,
                    child: _Schriftzug(text: texte.appName),
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

/// Der Name, fertig da.
///
/// Keine Animation, kein Einsatzpunkt: Er gehört zum Endzustand, und den
/// zeigt dieser Schirm ab dem ersten Bild (DECISIONS 55). Sichtbar wird er
/// zusammen mit dem Verlauf – dann nämlich, wenn Android seinen
/// Start-Bildschirm darüber wegblendet.
class _Schriftzug extends StatelessWidget {
  const _Schriftzug({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Text(
      text,
      style: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: farben.textPrimaer,
      ),
    );
  }
}
