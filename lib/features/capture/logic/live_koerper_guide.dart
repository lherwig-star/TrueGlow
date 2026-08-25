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
  nichtMittig,
  bereit;

  /// Nur hier laeuft der Auto-Ausloeser an.
  bool get loestAus => this == KoerperHinweis.bereit;
}

/// Der Satz, der im Sucher steht – aus demselben Grund eine Erweiterung wie
/// bei [LiveHinweisText].
extension KoerperHinweisText on KoerperHinweis {
  String text(L texte) => switch (this) {
        KoerperHinweis.niemand => texte.koerperNiemand,
        KoerperHinweis.zuDunkel => texte.kameraZuDunkel,
        KoerperHinweis.nichtGanz => texte.koerperNichtGanz,
        KoerperHinweis.zuWeitWeg => texte.koerperZuWeitWeg,
        KoerperHinweis.zuNah => texte.koerperZuNah,
        KoerperHinweis.nichtMittig => texte.koerperNichtMittig,
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

/// Bewertet, ob jemand vollstaendig und mittig im Bild steht.
///
/// Anders als beim Portrait entscheidet diese Bewertung nicht nur ueber einen
/// Hinweistext, sondern loest am Ende selbst aus. Sie ist deshalb strenger
/// gebaut: Im Zweifel „noch nicht", denn ein zu frueh geschossenes Foto
/// kostet den ganzen Weg zurueck ans Handy.
class LiveKoerperGuide {
  const LiveKoerperGuide();

  /// Anteil der Bildhoehe, den die Person mindestens einnehmen muss.
  ///
  /// Darunter steht sie so weit weg, dass Proportionen und Haltung – der
  /// Grund fuer dieses Foto – kaum noch zu beurteilen sind.
  static const double minHoehe = 0.55;

  /// Obergrenze. Darueber ist zu erwarten, dass Kopf oder Fuesse gleich aus
  /// dem Bild laufen.
  static const double maxHoehe = 0.94;

  /// Zulaessige seitliche Abweichung der Koerpermitte, als Anteil der Breite.
  static const double maxVersatz = 0.16;

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
    if (anteil > maxHoehe) return KoerperHinweis.zuNah;

    final versatz = (lage.umriss.center.dx / bildGroesse.width - 0.5).abs();
    if (versatz > maxVersatz) return KoerperHinweis.nichtMittig;

    return KoerperHinweis.bereit;
  }
}
