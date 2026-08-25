import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/marke.dart';

/// Das TrueGlow-Zeichen, zur Laufzeit gezeichnet.
///
/// Warum gezeichnet und nicht als Bilddatei: Das Motiv erscheint im hellen
/// Schema in Mocha-Braun und im dunklen in Sand. Als PNG wären das zwei
/// Dateien in je drei Auflösungen, die beim nächsten Farbwechsel alle neu
/// erzeugt werden müssten. Als Pfad ist es eine Farbe, ein Argument – und in
/// jeder Größe scharf.
///
/// Die Geometrie kommt aus [Marke] und ist dieselbe, aus der
/// `tool/marke_erzeugen.dart` das App-Icon und den nativen Splash rechnet.
class MarkenLogo extends StatelessWidget {
  const MarkenLogo({super.key, required this.groesse, this.farbe});

  /// Kantenlänge des Quadrats, in dem das Zeichen sitzt.
  final double groesse;

  /// Ohne Angabe der Akzent des aktiven Schemas.
  final Color? farbe;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: groesse,
      child: CustomPaint(
        painter: _MarkenPainter(farbe ?? context.farben.akzent),
        // Das Zeichen trägt keine Bedeutung, die ein Screenreader vorlesen
        // müsste: Der Name steht als Text daneben.
        isComplex: false,
      ),
    );
  }
}

class _MarkenPainter extends CustomPainter {
  _MarkenPainter(this.farbe);

  final Color farbe;

  @override
  void paint(Canvas canvas, Size size) {
    final kante = size.shortestSide;
    final stift = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Marke.strich * kante
      ..color = farbe;

    Rect ellipse(double cx, double cy, double rx, double ry) => Rect.fromCenter(
          center: Offset(cx * kante, cy * kante),
          width: rx * 2 * kante,
          height: ry * 2 * kante,
        );

    canvas.drawOval(
      ellipse(Marke.ovalX, Marke.ovalY, Marke.ovalRx, Marke.ovalRy),
      stift,
    );

    // Der Schulterbogen ist eine große Ellipse, von der nur die Oberkante
    // sichtbar sein soll. Statt einen Bogenwinkel zu rechnen wird alles
    // unterhalb der Kante weggeschnitten – dieselbe Regel, nach der auch der
    // Generator entscheidet, und damit dieselbe Form.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, kante, Marke.schulterUnterkante * kante),
    );
    canvas.drawOval(
      ellipse(
        Marke.schulterX,
        Marke.schulterY,
        Marke.schulterRx,
        Marke.schulterRy,
      ),
      stift,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkenPainter alt) => alt.farbe != farbe;
}
