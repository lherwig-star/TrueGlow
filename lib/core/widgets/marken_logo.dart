import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/marke.dart';

/// Das TrueGlow-Zeichen, zur Laufzeit gezeichnet.
///
/// Warum gezeichnet und nicht als Bilddatei: Das Motiv erscheint in zwei
/// Farbwelten und in jeder Größe. Als PNG wären das etliche Dateien, die beim
/// nächsten Farbwechsel alle neu erzeugt werden müssten. Als Pfad sind es
/// zwei Farben, zwei Argumente – und in jeder Größe scharf.
///
/// Die Geometrie kommt aus [Marke] und ist dieselbe, aus der
/// `tool/marke_erzeugen.dart` das App-Icon und den nativen Splash rechnet.
///
/// **Silhouette mit Glut** (DECISIONS 54): Kopfkreis und Schulterbogen als
/// feine helle Linien, und in der Brustmitte ein warmer Glutkern in der
/// Akzentfarbe für Erreichtes. Man glüht von innen nach außen – die Glut
/// liegt deshalb *über* den Linien und überstrahlt den Schulterbogen dort,
/// wo sie am dichtesten ist.
class MarkenLogo extends StatelessWidget {
  const MarkenLogo({
    super.key,
    required this.groesse,
    this.farbe,
    this.glut,
  });

  /// Kantenlänge des Quadrats, in dem das Zeichen sitzt.
  final double groesse;

  /// Farbe der Linien. Ohne Angabe die Textfarbe des aktiven Schemas – das
  /// weiche Weiß aus der Vorlage.
  final Color? farbe;

  /// Farbe der Glut. Ohne Angabe der Ton für Erreichtes.
  final Color? glut;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return SizedBox.square(
      dimension: groesse,
      child: CustomPaint(
        painter: _MarkenPainter(
          linien: farbe ?? farben.textPrimaer,
          glut: glut ?? farben.erreichtFlaeche,
        ),
        // Das Zeichen trägt keine Bedeutung, die ein Screenreader vorlesen
        // müsste: Der Name steht als Text daneben.
        isComplex: false,
      ),
    );
  }
}

class _MarkenPainter extends CustomPainter {
  _MarkenPainter({required this.linien, required this.glut});

  final Color linien;
  final Color glut;

  /// So viele Stützstellen bekommt der Verlauf.
  ///
  /// Der Verlauf kann die Kurve aus [Marke.glutDeckung] nicht selbst
  /// rechnen; er wird an diesen Stellen abgetastet. Sechzehn reichen: Der
  /// Abstand zwischen zwei Stellen ist dann kleiner als ein Pixel Unterschied
  /// in der Deckung, und die Kurve fällt ohnehin weich.
  static const _stuetzstellen = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final kante = size.shortestSide;
    _zeichneLinien(canvas, kante);
    _zeichneGlut(canvas, kante);
  }

  void _zeichneLinien(Canvas canvas, double kante) {
    final stift = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Marke.strich * kante
      ..color = linien;

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

  void _zeichneGlut(Canvas canvas, double kante) {
    final mitte = Offset(Marke.glutX * kante, Marke.glutY * kante);
    final radius = Marke.glutRadius * kante;

    final farben = <Color>[];
    final stellen = <double>[];
    for (var i = 0; i < _stuetzstellen; i += 1) {
      final anteil = i / (_stuetzstellen - 1);
      // Innen weißglühend, außen gold – und nach außen durchsichtig.
      final ton = Color.lerp(glut, Colors.white, Marke.glutWeiss(anteil))!;
      farben.add(ton.withValues(alpha: Marke.glutDeckung(anteil)));
      stellen.add(anteil);
    }

    canvas.drawCircle(
      mitte,
      radius,
      Paint()
        ..shader = RadialGradient(colors: farben, stops: stellen)
            .createShader(Rect.fromCircle(center: mitte, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_MarkenPainter alt) =>
      alt.linien != linien || alt.glut != glut;
}
