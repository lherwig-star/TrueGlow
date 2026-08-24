import 'dart:ui';

import '../../../core/l10n/app_strings.dart';

/// Rueckmeldung der Live-Vorschau: was der Nutzer gerade aendern soll.
enum LiveHinweis {
  keinGesicht(S.kameraKeinGesicht),
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

  /// [gesichter] sind die Bounding-Boxen aus ML Kit – bewusst nur Rechtecke,
  /// damit diese Bewertung ohne Kamera und ohne ML Kit testbar bleibt.
  ///
  /// [bildGroesse] muss die Groesse des aufgerichteten Bildes sein, also mit
  /// vertauschten Kanten, wenn der Frame um 90/270 Grad gedreht wurde.
  LiveHinweis bewerte({
    required List<Rect> gesichter,
    required Size bildGroesse,
  }) {
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
