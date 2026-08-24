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
      case Overlaytyp.ganzkoerperFrontal:
        _zeichneGestrichelt(canvas, _ganzkoerperFrontalPfad(size), stift);
      case Overlaytyp.ganzkoerperSeitlich:
        _zeichneGestrichelt(canvas, _ganzkoerperSeitlichPfad(size), stift);
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

  /// Halbe Kopfhoehe der Ganzkoerper-Figur, als Anteil der Bildhoehe.
  ///
  /// Alles Uebrige haengt daran: Der Kopf sitzt bei [_figurKopfMitte], sein
  /// unterer Rand trifft den Halsansatz der Umrisse bei 0,15.
  static const double _figurKopfHalb = 0.052;
  static const double _figurKopfMitte = 0.098;

  /// Stehende Figur von vorn.
  ///
  /// Der Umriss war frueher ein abgerundetes Rechteck. Ein Kasten sagt nur
  /// „irgendwo hier rein", eine Silhouette sagt „so weit weg und so
  /// ausgerichtet" – und genau darum geht es, wenn jemand das Handy aufstellt
  /// und mehrere Meter zuruecktritt.
  ///
  /// Gezeichnet wird die rechte Haelfte von oben nach unten; die linke
  /// entsteht durch Spiegeln. Das haelt die Figur zwangslaeufig symmetrisch –
  /// von Hand gesetzte Gegenpunkte laufen beim Nachjustieren auseinander.
  Path _ganzkoerperFrontalPfad(Size size) {
    Offset p(double dx, double dy) =>
        Offset(size.width * (0.5 + dx), size.height * dy);

    // Rumpf und Bein **ohne** den Arm: Wird der Arm in dieselbe Kontur
    // eingerechnet, zieht die Glaettung Schulter und Arm zu einem Ballon
    // zusammen und die Taille verschwindet darin.
    const rumpf = <(double, double)>[
      (0.032, 0.150), // Halsansatz
      (0.130, 0.196), // Schulter oben
      (0.158, 0.234), // Deltamuskel
      (0.126, 0.302), // Brustkorb
      (0.098, 0.382), // Taille
      (0.130, 0.462), // Huefte
      (0.120, 0.580), // Oberschenkel
      (0.092, 0.678), // Knie
      (0.082, 0.772), // Wade
      (0.054, 0.888), // Knoechel aussen
      (0.078, 0.928), // Fuss aussen
      (0.022, 0.928), // Fuss innen
      (0.028, 0.888), // Knoechel innen
      (0.034, 0.678), // Knie innen
      (0.012, 0.500), // Schrittmitte
    ];

    // Der Arm als eigene schmale Kontur: aussen hinunter, um die Hand herum,
    // innen wieder hinauf bis zur Achsel.
    //
    // Die Innenseite haelt bewusst Abstand zum Brustkorb (0,126). Liegen die
    // beiden Konturen zu dicht, kreuzen sie sich an der Schulter und aus der
    // Figur wird ein Knoten.
    const arm = <(double, double)>[
      (0.158, 0.236), // setzt am Deltamuskel an, sonst schwebt der Arm
      (0.180, 0.320),
      (0.184, 0.398), // Ellenbogen
      (0.174, 0.470),
      (0.162, 0.520), // Hand
      (0.144, 0.470),
      (0.150, 0.398),
      (0.146, 0.320),
      (0.130, 0.276), // Achsel, dicht am Brustkorb
    ];

    final pfad = Path()..addOval(_figurKopf(size, versatz: 0));

    pfad.addPath(
      _glattDurch(
        [
          for (final (dx, dy) in rumpf) p(dx, dy),
          // Rueckweg an der linken Seite hinauf.
          for (final (dx, dy) in rumpf.reversed) p(-dx, dy),
        ],
        geschlossen: true,
      ),
      Offset.zero,
    );

    for (final seite in [1, -1]) {
      pfad.addPath(
        _glattDurch(
          [for (final (dx, dy) in arm) p(dx * seite, dy)],
          geschlossen: false,
        ),
        Offset.zero,
      );
    }

    return pfad;
  }

  /// Dieselbe Figur im Profil, Blickrichtung rechts.
  ///
  /// Hier zaehlt die Rueckenlinie: Sie ist der Grund, warum ueberhaupt ein
  /// zweites Ganzkoerperfoto verlangt wird (Haltung und Proportionen von der
  /// Seite). Deshalb sind Hohlkreuz und Gesaess ausgepraegt gezeichnet und
  /// nicht zu einer geraden Linie vereinfacht.
  Path _ganzkoerperSeitlichPfad(Size size) {
    Offset p(double dx, double dy) =>
        Offset(size.width * (0.5 + dx), size.height * dy);

    // Ruecken hinunter, um den Fuss herum, Vorderseite wieder hinauf.
    //
    // Die Tiefenwerte sind rund anderthalbmal so gross wie beim ersten
    // Entwurf: Ein Mensch im Profil ist etwa ein Sechstel so tief wie hoch.
    // Zu schmal gezeichnet liest sich die Figur als Strich, und niemand
    // erkennt, wonach er sich ausrichten soll.
    const umriss = <(double, double)>[
      (-0.048, 0.152), // Nacken
      (-0.092, 0.200), // Schulter hinten
      (-0.108, 0.278), // oberer Ruecken
      (-0.076, 0.372), // Hohlkreuz
      (-0.132, 0.462), // Gesaess
      (-0.100, 0.585), // Oberschenkel hinten
      (-0.072, 0.678), // Kniekehle
      (-0.084, 0.752), // Wade
      // Der Fuss braucht vier Punkte. Mit nur Ferse und Spitze rundet die
      // Glaettung die Sohle zu einem Haken, der nach nichts aussieht.
      (-0.066, 0.900), // Ferse hinten
      (-0.056, 0.932), // Ferse unten
      (0.034, 0.936), // Sohle
      // Zweimal derselbe Punkt: Die Glaettung legt ihre Ankerpunkte zwischen
      // je zwei Stuetzpunkte, erreicht eine einzelne Spitze also nie. Bei
      // einem doppelten Punkt faellt der Anker auf ihn – die Zehen kommen
      // heraus statt abgerundet zu werden.
      (0.112, 0.930), // Zehenspitze, zeigt nach vorn
      (0.112, 0.930),
      (0.032, 0.886), // Spann
      (0.036, 0.752), // Schienbein
      (0.046, 0.676), // Knie vorn
      (0.066, 0.580), // Oberschenkel vorn
      (0.078, 0.475), // Huefte vorn
      (0.090, 0.390), // Bauch
      (0.086, 0.286), // Brust
      (0.058, 0.204), // Schulter vorn
      (0.022, 0.154), // Halsvorderseite
    ];

    // Kein Arm im Profil: Er laege genau ueber der Rumpfkontur. Als einzelne
    // Linie gezeichnet schwebt er wie ein Strichfehler in der Figur, als
    // Kontur verdeckt er die Rueckenlinie – und die ist der Grund, warum
    // dieses zweite Foto ueberhaupt verlangt wird.
    return Path()
      ..addOval(_figurKopf(size, versatz: 0.014))
      ..addPath(
        _glattDurch([for (final (dx, dy) in umriss) p(dx, dy)],
            geschlossen: true),
        Offset.zero,
      );
  }

  /// Kopf der Ganzkoerper-Figur. [versatz] schiebt ihn im Profil leicht nach
  /// vorn, weil der Hals dort nicht mittig sitzt.
  Rect _figurKopf(Size size, {required double versatz}) => Rect.fromCenter(
        center: Offset(
          size.width * (0.5 + versatz),
          size.height * _figurKopfMitte,
        ),
        width: size.height * _figurKopfHalb * 2 * _kopfVerhaeltnis,
        height: size.height * _figurKopfHalb * 2,
      );

  /// Weicher Streckenzug durch die Punkte.
  ///
  /// Die Stuetzpunkte werden zu Kontrollpunkten quadratischer Beziers, die
  /// Ankerpunkte liegen jeweils dazwischen. Mit `lineTo` saehe die Figur aus
  /// wie ein Polygon – bei einer Koerperkontur faellt jede Ecke sofort auf.
  Path _glattDurch(List<Offset> punkte, {required bool geschlossen}) {
    final pfad = Path();
    if (punkte.length < 2) return pfad;

    Offset mitte(Offset a, Offset b) =>
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);

    if (geschlossen) {
      // Start auf der Mitte zwischen letztem und erstem Punkt, damit auch die
      // Naht zwischen Ende und Anfang gerundet ist.
      final start = mitte(punkte.last, punkte.first);
      pfad.moveTo(start.dx, start.dy);
      for (var i = 0; i < punkte.length; i++) {
        final steuer = punkte[i];
        final ziel = mitte(steuer, punkte[(i + 1) % punkte.length]);
        pfad.quadraticBezierTo(steuer.dx, steuer.dy, ziel.dx, ziel.dy);
      }
      pfad.close();
      return pfad;
    }

    pfad.moveTo(punkte.first.dx, punkte.first.dy);
    for (var i = 1; i < punkte.length - 1; i++) {
      final ziel = mitte(punkte[i], punkte[i + 1]);
      pfad.quadraticBezierTo(punkte[i].dx, punkte[i].dy, ziel.dx, ziel.dy);
    }
    pfad.lineTo(punkte.last.dx, punkte.last.dy);
    return pfad;
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
