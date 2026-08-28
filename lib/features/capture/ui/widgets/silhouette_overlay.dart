import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/aufnahme_typ.dart';

/// Gestrichelte Hilfslinien im Sucher: zeigen, wie Kopf bzw. Koerper im Bild
/// sitzen sollten.
///
/// In der Live-Vorschau setzt der Kamera-Screen [farbe] und [staerke], damit
/// die Silhouette den Positionierungs-Status widerspiegeln kann.
class SilhouetteOverlay extends StatelessWidget {
  const SilhouetteOverlay({
    super.key,
    required this.overlay,
    this.farbe,
    this.staerke = 2,
  });

  final Overlaytyp overlay;

  /// Ohne Angabe der Primaer-Akzent des aktiven Themes.
  final Color? farbe;

  final double staerke;

  @override
  Widget build(BuildContext context) {
    if (overlay == Overlaytyp.keins) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _SilhouettePainter(
          overlay: overlay,
          farbe: farbe ?? context.farben.akzent.withValues(alpha: 0.55),
          staerke: staerke,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({
    required this.overlay,
    required this.farbe,
    required this.staerke,
  });

  final Overlaytyp overlay;
  final Color farbe;
  final double staerke;

  /// Breite zu Hoehe des Kopfes – natuerliche Gesichtsproportion. Ein
  /// schmaleres Oval wirkt langgezogen und laesst den Nutzer zu weit
  /// zuruecktreten.
  static const double _kopfVerhaeltnis = 0.72;

  /// Anteil der Bildhoehe, den der Kopf einnimmt.
  static const double _kopfHoehe = 0.44;

  /// Vertikale Lage des Kopfmittelpunkts: oberhalb bleibt Platz fuer die
  /// Anleitung und den Drehpfeil, unterhalb fuer Hals und Schultern.
  static const double _kopfMitte = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final stift = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = staerke
      ..strokeCap = StrokeCap.round
      ..color = farbe;

    final feld = _kopffeld(size);

    switch (overlay) {
      case Overlaytyp.gesichtsOval:
        _zeichneGestrichelt(canvas, _frontalPfad(size, feld), stift);
      case Overlaytyp.profilNaseRechts:
        _zeichneGestrichelt(
          canvas,
          _profilPfad(size, feld, gespiegelt: false),
          stift,
        );
        _drehpfeil(canvas, feld, stift, nachRechts: true);
      case Overlaytyp.profilNaseLinks:
        _zeichneGestrichelt(
          canvas,
          _profilPfad(size, feld, gespiegelt: true),
          stift,
        );
        _drehpfeil(canvas, feld, stift, nachRechts: false);
      case Overlaytyp.winkel45:
        _zeichneGestrichelt(canvas, _winkelPfad(size, feld), stift);
        _drehpfeil(canvas, feld, stift, nachRechts: true, halb: true);
      case Overlaytyp.keins:
        break;
    }
  }

  /// Das Rechteck, in dem der Kopf sitzen soll. Die Breite folgt der Hoehe,
  /// nicht der Bildbreite – sonst wird das Oval auf schmalen Geraeten
  /// unnatuerlich schlank.
  Rect _kopffeld(Size size) {
    final hoehe = size.height * _kopfHoehe;
    final breite = math.min(hoehe * _kopfVerhaeltnis, size.width * 0.78);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * _kopfMitte),
      width: breite,
      height: hoehe,
    );
  }

  /// Kopf-Oval plus Schulterlinien, die am Oval ansetzen.
  Path _frontalPfad(Size size, Rect feld) {
    final pfad = Path()..addOval(feld);
    _schultern(pfad, feld, size);
    return pfad;
  }

  /// Schulterlinien laufen vom unteren Bildrand an die Seiten des Kopfes.
  void _schultern(Path pfad, Rect feld, Size size) {
    final ansatzY = feld.bottom + feld.height * 0.14;
    final weite = feld.width * 1.15;

    pfad
      ..moveTo(feld.center.dx - weite, size.height)
      ..quadraticBezierTo(
        feld.center.dx - weite * 0.82,
        ansatzY + feld.height * 0.18,
        feld.left + feld.width * 0.12,
        ansatzY,
      )
      ..moveTo(feld.center.dx + weite, size.height)
      ..quadraticBezierTo(
        feld.center.dx + weite * 0.82,
        ansatzY + feld.height * 0.18,
        feld.right - feld.width * 0.12,
        ansatzY,
      );
  }

  /// Seitenprofil mit deutlich herausstehender Nase, angedeuteter Stirn-,
  /// Lippen- und Kinnlinie sowie einem Ohrbogen auf der Gegenseite.
  ///
  /// Die Koordinaten sind auf das Kopffeld normiert (0..1), damit die Kontur
  /// in jedem Bildformat stimmt. x = 0 ist der Hinterkopf, x = 1 die
  /// Nasenspitze; [gespiegelt] dreht die Blickrichtung.
  Path _profilPfad(Size size, Rect feld, {required bool gespiegelt}) {
    Offset p(double x, double y) => Offset(
          feld.left + (gespiegelt ? 1 - x : x) * feld.width,
          feld.top + y * feld.height,
        );

    final pfad = Path()..moveTo(p(0.16, 0.86).dx, p(0.16, 0.86).dy);

    void kurve(Offset s1, Offset s2, Offset ziel) =>
        pfad.cubicTo(s1.dx, s1.dy, s2.dx, s2.dy, ziel.dx, ziel.dy);
    void linie(Offset ziel) => pfad.lineTo(ziel.dx, ziel.dy);

    // Hinterkopf hoch bis zum Scheitel
    kurve(p(-0.02, 0.64), p(0.02, 0.10), p(0.44, 0.00));
    // Scheitel ueber die Stirn nach unten
    kurve(p(0.72, 0.02), p(0.82, 0.16), p(0.78, 0.38));
    // Nasenwurzel – kleine Einbuchtung, macht die Nase erst erkennbar
    kurve(p(0.76, 0.42), p(0.78, 0.44), p(0.80, 0.46));
    // Nase: spitz nach aussen und wieder zurueck
    linie(p(1.00, 0.555));
    linie(p(0.79, 0.60));
    // Oberlippe, Lippen, Kinnfalte
    kurve(p(0.83, 0.635), p(0.85, 0.675), p(0.77, 0.705));
    kurve(p(0.82, 0.745), p(0.79, 0.80), p(0.64, 0.855));
    // Kieferlinie zurueck zum Hinterkopf
    kurve(p(0.46, 0.90), p(0.28, 0.90), p(0.16, 0.86));

    // Ohr: C-Bogen innerhalb der Silhouette, zur Gegenseite der Nase hin
    // geoeffnet. Nase zeigt nach aussen, Ohr liegt innen – daran ist die
    // Blickrichtung sofort ablesbar.
    const ohrX = 0.33;
    const ohrY = 0.52;
    const ohrB = 0.085;
    const ohrH = 0.115;
    pfad
      ..moveTo(p(ohrX + ohrB * 0.5, ohrY + ohrH * 0.87).dx,
          p(ohrX + ohrB * 0.5, ohrY + ohrH * 0.87).dy)
      ..quadraticBezierTo(
        p(ohrX - ohrB * 0.2, ohrY + ohrH * 1.5).dx,
        p(ohrX - ohrB * 0.2, ohrY + ohrH * 1.5).dy,
        p(ohrX - ohrB, ohrY).dx,
        p(ohrX - ohrB, ohrY).dy,
      )
      ..quadraticBezierTo(
        p(ohrX - ohrB * 0.2, ohrY - ohrH * 1.5).dx,
        p(ohrX - ohrB * 0.2, ohrY - ohrH * 1.5).dy,
        p(ohrX + ohrB * 0.5, ohrY - ohrH * 0.87).dx,
        p(ohrX + ohrB * 0.5, ohrY - ohrH * 0.87).dy,
      );

    // Hals und Schulter
    pfad
      ..moveTo(p(0.60, 0.87).dx, p(0.60, 0.87).dy)
      ..lineTo(p(0.64, 1.26).dx, p(0.64, 1.26).dy)
      ..quadraticBezierTo(
        p(0.95, 1.44).dx,
        p(0.95, 1.44).dy,
        p(1.25, 1.85).dx,
        size.height,
      )
      ..moveTo(p(0.26, 0.90).dx, p(0.26, 0.90).dy)
      ..lineTo(p(0.22, 1.28).dx, p(0.22, 1.28).dy)
      ..quadraticBezierTo(
        p(-0.05, 1.46).dx,
        p(-0.05, 1.46).dy,
        p(-0.30, 1.85).dx,
        size.height,
      );

    return pfad;
  }

  /// Halb gedrehter Kopf: schmaleres Oval, Nase deutlich zur Seite versetzt,
  /// beide Augenpartien noch angedeutet.
  Path _winkelPfad(Size size, Rect feld) {
    // Etwas schmaler als frontal – der Kopf steht ja bereits im Winkel.
    final oval = Rect.fromCenter(
      center: feld.center,
      width: feld.width * 0.88,
      height: feld.height,
    );

    Offset p(double x, double y) =>
        Offset(oval.left + x * oval.width, oval.top + y * oval.height);

    final pfad = Path();

    // Kontur: Oval, aber rechts mit herausgezogener Nasenpartie.
    pfad
      ..moveTo(p(0.5, 0.0).dx, p(0.5, 0.0).dy)
      // linke Haelfte herunter
      ..cubicTo(p(0.06, 0.04).dx, p(0.06, 0.04).dy, p(-0.02, 0.42).dx,
          p(-0.02, 0.42).dy, p(0.12, 0.76).dx, p(0.12, 0.76).dy)
      ..cubicTo(p(0.24, 0.98).dx, p(0.24, 0.98).dy, p(0.62, 1.02).dx,
          p(0.62, 1.02).dy, p(0.80, 0.78).dx, p(0.80, 0.78).dy)
      // rechte Wange hoch bis unter die Nase
      ..cubicTo(p(0.88, 0.68).dx, p(0.88, 0.68).dy, p(0.92, 0.64).dx,
          p(0.92, 0.64).dy, p(0.93, 0.60).dx, p(0.93, 0.60).dy)
      // Nase: nach aussen versetzt
      ..lineTo(p(1.08, 0.545).dx, p(1.08, 0.545).dy)
      ..lineTo(p(0.94, 0.47).dx, p(0.94, 0.47).dy)
      // Stirn zurueck zum Scheitel
      ..cubicTo(p(0.99, 0.30).dx, p(0.99, 0.30).dy, p(0.92, 0.04).dx,
          p(0.92, 0.04).dy, p(0.5, 0.0).dx, p(0.5, 0.0).dy);

    // Beide Augenpartien: die abgewandte kuerzer, das zeigt den Winkel.
    pfad
      ..moveTo(p(0.26, 0.44).dx, p(0.26, 0.44).dy)
      ..lineTo(p(0.44, 0.44).dx, p(0.44, 0.44).dy)
      ..moveTo(p(0.64, 0.43).dx, p(0.64, 0.43).dy)
      ..lineTo(p(0.76, 0.43).dx, p(0.76, 0.43).dy);

    _schultern(pfad, feld, size);
    return pfad;
  }

  /// Geschwungener Pfeil ueber dem Kopf, der die Drehrichtung andeutet.
  ///
  /// Bewusst durchgezogen statt gestrichelt: gestrichelt zerfaellt die
  /// Pfeilspitze optisch und der Pfeil liest sich nicht mehr als Pfeil.
  void _drehpfeil(
    Canvas canvas,
    Rect feld,
    Paint stift, {
    required bool nachRechts,
    bool halb = false,
  }) {
    final weite = feld.width * (halb ? 0.34 : 0.55);
    final hoehe = feld.top - feld.height * 0.13;
    final richtung = nachRechts ? 1 : -1;

    final start = Offset(feld.center.dx - weite * richtung, hoehe);
    final ende = Offset(feld.center.dx + weite * richtung, hoehe);
    final steuer = Offset(feld.center.dx, hoehe - feld.height * 0.14);

    final voll = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stift.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = stift.color;

    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(steuer.dx, steuer.dy, ende.dx, ende.dy),
      voll,
    );

    // Spitze am Ende, entlang der Tangente der Kurve.
    final tangente = ende - steuer;
    final laenge = tangente.distance;
    if (laenge == 0) return;

    final richtungsvektor = tangente / laenge;
    final spitze = feld.width * 0.12;
    final senkrecht = Offset(-richtungsvektor.dy, richtungsvektor.dx);

    canvas.drawPath(
      Path()
        ..moveTo(
          ende.dx - richtungsvektor.dx * spitze + senkrecht.dx * spitze * 0.55,
          ende.dy - richtungsvektor.dy * spitze + senkrecht.dy * spitze * 0.55,
        )
        ..lineTo(ende.dx, ende.dy)
        ..lineTo(
          ende.dx - richtungsvektor.dx * spitze - senkrecht.dx * spitze * 0.55,
          ende.dy - richtungsvektor.dy * spitze - senkrecht.dy * spitze * 0.55,
        ),
      voll,
    );
  }

  /// Zeichnet einen Pfad gestrichelt – Flutter kann das nicht von Haus aus.
  void _zeichneGestrichelt(Canvas canvas, Path pfad, Paint stift) {
    const strich = 7.0;
    const luecke = 6.0;

    for (final metrik in pfad.computeMetrics()) {
      var abstand = 0.0;
      while (abstand < metrik.length) {
        final ende = (abstand + strich).clamp(0.0, metrik.length);
        canvas.drawPath(metrik.extractPath(abstand, ende), stift);
        abstand = ende + luecke;
      }
    }
  }

  @override
  bool shouldRepaint(_SilhouettePainter alt) =>
      alt.overlay != overlay ||
      alt.farbe != farbe ||
      alt.staerke != staerke;
}
