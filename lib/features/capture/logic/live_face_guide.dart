import 'dart:ui';

import '../../../core/l10n/app_strings.dart';
import 'image_quality_service.dart';

/// Rueckmeldung der Live-Vorschau: was der Nutzer gerade aendern soll.
enum LiveHinweis {
  keinGesicht(S.kameraKeinGesicht),
  zuDunkel(S.kameraZuDunkel),
  zuWeitWeg(S.kameraZuWeitWeg),
  zuNah(S.kameraZuNah),
  nichtMittig(S.kameraNichtMittig),
  perfekt(S.kameraPerfekt);

  const LiveHinweis(this.text);

  final String text;

  /// Nur bei [perfekt] wird die Silhouette eingefaerbt und der Ausloeser
  /// hervorgehoben.
  bool get bereit => this == LiveHinweis.perfekt;
}

/// Bewertet einen Vorschau-Frame und leitet daraus den Hinweistext ab.
///
/// Die Grenzen sind absichtlich etwas strenger als der finale Qualitaetscheck
/// in `ImageQualityService`: was die Vorschau als "perfekt" meldet, soll den
/// Check danach auch bestehen und nicht knapp daran scheitern.
class LiveFaceGuide {
  const LiveFaceGuide();

  /// Untergrenze des Flaechenanteils. Der finale Check verlangt 0.25 – der
  /// Puffer faengt ab, dass Vorschau und Standbild leicht unterschiedlich
  /// beschnitten sind.
  static const double minAnteil = 0.28;

  /// Obergrenze: darueber ist der Kopf angeschnitten.
  static const double maxAnteil = 0.62;

  /// Zulaessige Abweichung der Gesichtsmitte vom Bildmittelpunkt, als Anteil
  /// der jeweiligen Kantenlaenge.
  static const double maxVersatz = 0.18;

  /// Untergrenze der mittleren Helligkeit (0–255) fuer den Live-Hinweis.
  ///
  /// Bewusst **ueber** der Ablehnungsgrenze des finalen Checks: Wer knapp
  /// darueber fotografiert, kommt zwar durch, steht aber am Rand. Der Hinweis
  /// kommt frueher, damit man Licht nachlegen kann, statt ein Foto zu machen,
  /// das anschliessend abgelehnt wird.
  ///
  /// Beide Werte messen dasselbe: mittlere Luminanz auf 0–255. Der Check
  /// rechnet sie aus dem dekodierten JPEG, die Vorschau aus der Y-Ebene des
  /// Kamerabildes – das *ist* der Luminanzkanal.
  static const int minHelligkeit = ImageQualityService.minHelligkeit + 10;

  /// [gesichter] sind die Bounding-Boxen aus ML Kit – bewusst nur Rechtecke,
  /// damit diese Bewertung ohne Kamera und ohne ML Kit testbar bleibt.
  ///
  /// [bildGroesse] muss die Groesse des aufgerichteten Bildes sein, also mit
  /// vertauschten Kanten, wenn der Frame um 90/270 Grad gedreht wurde.
  /// [helligkeit] ist die mittlere Luminanz des Frames (0–255) oder `null`,
  /// wenn sie sich nicht ermitteln liess.
  LiveHinweis bewerte({
    required List<Rect> gesichter,
    required Size bildGroesse,
    int? helligkeit,
  }) {
    // Das Licht zuerst. Zu dunkel ist haeufig der Grund, warum ML Kit gar
    // kein Gesicht findet – „mehr Licht" ist dann der hilfreiche Hinweis,
    // „niemand im Bild" waere irrefuehrend. Und es ist die einzige
    // Ablehnung des finalen Checks, die man vorher sehen kann.
    if (helligkeit != null && helligkeit < minHelligkeit) {
      return LiveHinweis.zuDunkel;
    }

    if (gesichter.isEmpty) return LiveHinweis.keinGesicht;
    if (bildGroesse.width <= 0 || bildGroesse.height <= 0) {
      return LiveHinweis.keinGesicht;
    }

    // Bei mehreren Personen zaehlt das groesste Gesicht – das ist im
    // Selfie-Abstand verlaesslich der Nutzer selbst.
    final box = gesichter
        .reduce((a, b) => a.width * a.height >= b.width * b.height ? a : b);

    final anteil =
        (box.width * box.height) / (bildGroesse.width * bildGroesse.height);

    if (anteil < minAnteil) return LiveHinweis.zuWeitWeg;
    if (anteil > maxAnteil) return LiveHinweis.zuNah;

    final versatzX = (box.center.dx / bildGroesse.width - 0.5).abs();
    final versatzY = (box.center.dy / bildGroesse.height - 0.5).abs();
    if (versatzX > maxVersatz || versatzY > maxVersatz) {
      return LiveHinweis.nichtMittig;
    }

    return LiveHinweis.perfekt;
  }
}
