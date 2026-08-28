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
    required this.fuesseSichtbar,
  });

  /// Umschliessendes Rechteck ueber alle sicher erkannten Punkte.
  final Rect umriss;

  /// Ob Nase bzw. Augen sicher erkannt wurden.
  final bool kopfSichtbar;

  /// Ob beide Knoechel sicher erkannt wurden.
  final bool fuesseSichtbar;
}

/// Bewertet, ob jemand vollstaendig im Bild steht.
///
/// Anders als beim Portrait entscheidet diese Bewertung nicht nur ueber einen
/// Hinweistext, sondern loest am Ende selbst aus.
///
/// **Ueberarbeitet in DECISIONS 74.** Vorher verlangte sie zusaetzlich, dass
/// die Person mittig steht und mindestens 55 % der Bildhoehe fuellt – gedacht
/// als Ergaenzung zur Silhouette, an der man sich ausrichten sollte. Am
/// Geraet hiess das: Vor dem Spiegel stand man immer daneben, nie darin, und
/// der Ausloeser sprang nie an. Jetzt zaehlt nur noch, ob jemand ganz im Bild
/// ist und gross genug – wo, ist egal.
class LiveKoerperGuide {
  const LiveKoerperGuide();

  /// Anteil der Bildhoehe, den die Person mindestens einnehmen muss.
  ///
  /// Darunter steht sie so weit weg, dass Proportionen und Haltung – der
  /// Grund fuer dieses Foto – kaum noch zu beurteilen sind.
  ///
  /// Von 0,55 auf 0,50 gesenkt (DECISIONS 74): Vor einem Spiegel steht man
  /// selten so, dass man fuenfundfuenfzig Prozent der Bildhoehe fuellt, und
  /// die fehlenden fuenf Prozent waren der Unterschied zwischen „loest aus"
  /// und „loest nie aus".
  static const double minHoehe = 0.5;

  /// Wie viel Luft ueber dem hoechsten und unter dem tiefsten erkannten
  /// Punkt bleiben muss, als Anteil der Bildhoehe.
  ///
  /// Ersetzt die fruehere Obergrenze `maxHoehe`: Sie sagte dasselbe, nur
  /// ungenauer. Der Rand ist der eigentliche Grund – ML Kit erkennt Nase und
  /// Knoechel, nicht Scheitel und Zehenspitzen. Wer mit dem Knoechel auf der
  /// Bildkante steht, hat die Fuesse abgeschnitten.
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
    if (!lage.kopfSichtbar || !lage.fuesseSichtbar) {
      return KoerperHinweis.nichtGanz;
    }

    final anteil = lage.umriss.height / bildGroesse.height;
    if (anteil < minHoehe) return KoerperHinweis.zuWeitWeg;

    // Und genug Luft nach oben und unten. Mehr wird nicht verlangt: WO im
    // Bild die Person steht, ist ausdruecklich egal (DECISIONS 74). Die
    // frueher geforderte Mitte war der zweite Grund, aus dem der Ausloeser
    // vor dem Spiegel nie ansprang – dort steht man neben dem Handy, nicht
    // dahinter.
    final oben = lage.umriss.top / bildGroesse.height;
    final unten = 1 - lage.umriss.bottom / bildGroesse.height;
    if (oben < rand || unten < rand) return KoerperHinweis.zuNah;

    return KoerperHinweis.bereit;
  }
}
