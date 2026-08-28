import 'dart:ui';

import '../../../core/l10n/texte.dart';
import 'live_face_guide.dart';

/// Rueckmeldung des Suchers bei Ganzkoerper-Aufnahmen.
enum KoerperHinweis {
  niemand,
  zuDunkel,
  nichtGanz,
  zuWeitWeg,
  zuNah,
  bereit;

  /// Nur hier laeuft der Auto-Ausloeser an.
  bool get loestAus => this == KoerperHinweis.bereit;
}

/// Der Satz, der im Sucher steht – aus demselben Grund eine Erweiterung wie
/// bei [LiveHinweisText].
extension KoerperHinweisText on KoerperHinweis {
  /// [personOptional] gilt bei den Outfit-Fotos: Dort ist ein Bild ohne
  /// Person kein Fehler, sondern der ausgelegte Fall. „Stell dich ins Bild"
  /// laese sich dort wie eine Bedingung – deshalb nennt der Satz dort auch
  /// den anderen Weg.
  String text(L texte, {bool personOptional = false}) => switch (this) {
        KoerperHinweis.niemand =>
          personOptional ? texte.koerperNiemandFrei : texte.koerperNiemand,
        KoerperHinweis.zuDunkel => texte.kameraZuDunkel,
        KoerperHinweis.nichtGanz => texte.koerperNichtGanz,
        KoerperHinweis.zuWeitWeg => texte.koerperZuWeitWeg,
        KoerperHinweis.zuNah => texte.koerperZuNah,
        KoerperHinweis.bereit => texte.koerperBereit,
      };
}

/// Was die Posenerkennung von einer Person geliefert hat.
///
/// Bewusst nur Rechteck und zwei Flags statt der ML-Kit-Typen: So laesst sich
/// die Bewertung ohne Kamera, ohne ML Kit und ohne Geraet testen – und genau
/// das ist noetig, denn diese Regeln entscheiden, wann von selbst ausgeloest
/// wird.
class Koerperlage {
  const Koerperlage({
    required this.umriss,
    required this.kopfSichtbar,
    required this.hueftenSichtbar,
    this.fuesseSichtbar = false,
  });

  /// Umschliessendes Rechteck ueber alle sicher erkannten Punkte.
  final Rect umriss;

  /// Ob Nase bzw. Augen sicher erkannt wurden.
  final bool kopfSichtbar;

  /// Ob beide Hueftpunkte sicher erkannt wurden – der Anfang der
  /// Oberschenkel und seit DECISIONS 76 die untere Grenze.
  final bool hueftenSichtbar;

  /// Ob beide Knoechel sicher erkannt wurden.
  ///
  /// **Kein Kriterium mehr** (DECISIONS 76), nur noch eine Angabe fuers
  /// Protokoll: Sind die Fuesse mit drauf, umso besser.
  final bool fuesseSichtbar;
}

/// Bewertet, ob jemand weit genug im Bild ist.
///
/// Anders als beim Portrait entscheidet diese Bewertung nicht nur ueber einen
/// Hinweistext, sondern loest am Ende selbst aus.
///
/// **Zweimal gelockert, beide Male nach einem Befund vom Geraet:**
///
///  * DECISIONS 74 – die Forderung nach der Bildmitte fiel weg. Sie gehoerte
///    zur Silhouette, an der man sich ausrichten sollte, und die gibt es
///    nicht mehr.
///  * DECISIONS 76 – die Fuesse sind keine Pflicht mehr. Fuer Silhouette,
///    Proportionen und Passform reicht der Koerper von den Oberschenkeln
///    aufwaerts, und fuer die Fuesse musste man unangenehm weit weg stehen.
///
/// Uebrig bleibt: Kopf sichtbar, Huefte sichtbar, ein Rand ueber dem Kopf,
/// gross genug. Wo im Bild jemand steht, ist egal.
class LiveKoerperGuide {
  const LiveKoerperGuide();

  /// Anteil der Bildhoehe, den das erkannte Stueck Koerper mindestens
  /// einnehmen muss.
  ///
  /// Darunter steht die Person so weit weg, dass Proportionen und Haltung –
  /// der Grund fuer dieses Foto – kaum noch zu beurteilen sind.
  ///
  /// **0,30 ist ein Anfangswert, kein Messergebnis.** Er ist so gewaehlt,
  /// dass er denselben Abstand zulaesst wie die alte Regel: Dort musste der
  /// ganze Koerper 50 % der Bildhoehe fuellen, und Kopf bis Huefte sind
  /// ungefaehr die halbe Koerperhoehe – also rund 26 %. Mit 0,30 bleibt
  /// etwas Luft nach oben, ohne dass jemand aus dem Nebenzimmer ausloest.
  /// Der endgueltige Wert kommt aus der Protokollzeile (TESTPLAN 36).
  static const double minHoehe = 0.3;

  /// Wie viel Luft ueber dem hoechsten erkannten Punkt bleiben muss, als
  /// Anteil der Bildhoehe.
  ///
  /// Nur oben. Unten darf abgeschnitten sein – das ist seit DECISIONS 76
  /// der Normalfall. Oben nicht: ML Kit erkennt die Nase, nicht den
  /// Scheitel, und wer die Nase an der Bildkante hat, hat den Kopf nicht
  /// drauf.
  static const double rand = 0.02;

  /// [bildGroesse] ist die Groesse des aufgerichteten Bildes – also mit
  /// vertauschten Kanten, wenn der Frame um 90/270 Grad gedreht wurde.
  KoerperHinweis bewerte({
    required Koerperlage? lage,
    required Size bildGroesse,
    int? helligkeit,
  }) {
    // Wie beim Portrait zuerst das Licht: Zu dunkel ist oft der Grund, warum
    // gar keine Pose erkannt wird.
    if (helligkeit != null && helligkeit < LiveFaceGuide.minHelligkeit) {
      return KoerperHinweis.zuDunkel;
    }

    if (lage == null) return KoerperHinweis.niemand;
    if (bildGroesse.width <= 0 || bildGroesse.height <= 0) {
      return KoerperHinweis.niemand;
    }

    // Erst Vollstaendigkeit, dann Groesse: Wer angeschnitten ist, soll
    // „ganz ins Bild" lesen und nicht „zu nah" – das eine sagt, was zu tun
    // ist, das andere laesst raten.
    // Kopf und Huefte – mehr nicht. Die Fuesse sind seit DECISIONS 76
    // ausdruecklich keine Bedingung: Fuer sie musste man unangenehm weit weg
    // stehen, und fuer Silhouette und Passform tragen sie nichts bei.
    if (!lage.kopfSichtbar || !lage.hueftenSichtbar) {
      return KoerperHinweis.nichtGanz;
    }

    final anteil = lage.umriss.height / bildGroesse.height;
    if (anteil < minHoehe) return KoerperHinweis.zuWeitWeg;

    // Und Luft ueber dem Kopf. Nach unten ausdruecklich nicht: WO im Bild
    // die Person steht, ist egal (DECISIONS 74), und dass unten etwas fehlt,
    // ist der Normalfall.
    final oben = lage.umriss.top / bildGroesse.height;
    if (oben < rand) return KoerperHinweis.zuNah;

    return KoerperHinweis.bereit;
  }
}
