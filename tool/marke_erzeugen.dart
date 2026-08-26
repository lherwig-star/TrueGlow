// Erzeugt Icon- und Splash-Grafiken aus einer einzigen Geometrie.
//
//   dart run tool/marke_erzeugen.dart
//
// Warum ein Generator und keine gezeichnete Datei: Das Motiv gibt es in sechs
// Fassungen (Vollbild, adaptiver Vordergrund, Store-Icon, Splash hell, Splash
// dunkel, Android-12-Splash) in zwei Farbwelten. Von Hand gepflegt laufen die
// früher oder später auseinander. Hier steht die Form einmal, alles andere
// fällt heraus — auch die SVG-Quelle.
//
// Das Motiv ist das Gesichts-Oval aus dem Kamera-Sucher (`Overlaytyp.
// gesichtsOval`): ein hochkant stehender Ring mit angedeuteten Schultern
// darunter. Wer die App kennt, erkennt das Icon wieder.
//
// Seit DECISIONS 54 kommt die Glut dazu: ein warmer Kern in der Brustmitte,
// der weit und weich nach aussen streut. Man glueht von innen nach aussen.
// Die Kurve dafuer steht in `Marke.glutDeckung` – dieselbe, die die App zur
// Laufzeit benutzt.
//
// Nach dem Lauf:
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';
import 'package:trueglow/core/theme/marke.dart';

// --- Farben (Spiegel von lib/core/theme/app_colors.dart) -------------------

/// Deep Teal – oberes Ende des Seitenverlaufs.
const _deepTeal = 0xFF173C3B;

/// Fast schwarzes Blau – unteres Ende desselben Verlaufs. Die Icon-Kachel
/// traegt ihn, damit sie aussieht wie der Hintergrund der App.
const _tiefBlau = 0xFF0C1C26;

/// Sand – Akzent des dunklen Schemas.
const _sand = 0xFFD8C6AA;

/// Off-White – die Linienfarbe des Zeichens (Spiegel von `textPrimaer`).
const _offWhite = 0xFFF2EEE6;

/// Gedaempftes Gold – die Glut (Spiegel von `erreicht`).
const _gold = 0xFFE8BE6E;

/// Der weissgluehende Kern.
const _kernweiss = 0xFFFFFFFF;

/// Wie viel der Kachel das Motiv einnimmt.
///
/// Nachgemessen an der Vorlage: Der Kopfkreis nimmt dort knapp ein Drittel
/// der Kachelbreite ein, der Schulterbogen knapp die Haelfte. Bei diesem
/// Anteil trifft unsere Geometrie beides.
const _kachelAnteil = 0.72;

// Mocha (#F7F2E9) ist die Hintergrundfarbe des hellen Schemas. Sie steht
// nicht hier, sondern in der flutter_native_splash-Konfiguration in
// pubspec.yaml – der Generator zeichnet nur das Motiv, nicht den Grund.

/// Akzent des hellen Schemas.
const _mochaAkzent = 0xFF6B4F3A;

/// Die Glut im hellen Schema (Spiegel von `erreicht` in Mocha Light).
const _mochaGlut = 0xFF7A5200;

// --- Geometrie, normiert auf 0..1 ------------------------------------------
//
// Sie steht in `lib/core/theme/marke.dart`, weil die Startanimation dasselbe
// Motiv zur Laufzeit zeichnet. Zwei Kopien derselben Zahlen wären zwei
// Zeichen, die auseinanderlaufen – ähnlich genug, dass es niemandem auffällt.

const _ovalX = Marke.ovalX;
const _ovalY = Marke.ovalY;
const _ovalRx = Marke.ovalRx;
const _ovalRy = Marke.ovalRy;

const _schulterX = Marke.schulterX;
const _schulterY = Marke.schulterY;
const _schulterRx = Marke.schulterRx;
const _schulterRy = Marke.schulterRy;

const _strich = Marke.strich;
const _schulterUnterkante = Marke.schulterUnterkante;

void main(List<String> argumente) {
  final ziel = Directory('assets/branding')..createSync(recursive: true);

  // --- SVG: die menschenlesbare Quelle ------------------------------------
  File('${ziel.path}/app_icon.svg').writeAsStringSync(_svg());

  // --- Icons --------------------------------------------------------------
  // Vollbild, mit Hintergrund: Quelle für iOS und den Legacy-Launcher.
  //
  // Das Motiv steht nicht randlos in der Kachel – die Vorlage lässt rundum
  // Luft, und ohne sie schneidet jede runde Launcher-Maske den
  // Schulterbogen an.
  _schreibe(
    '${ziel.path}/app_icon.png',
    _icon(1024, mitHintergrund: true, motivAnteil: _kachelAnteil),
  );

  // Store-Icon 512×512 – dieselbe Grafik, andere Kantenlänge.
  _schreibe(
    '${ziel.path}/store_icon_512.png',
    _icon(512, mitHintergrund: true, motivAnteil: _kachelAnteil),
  );

  // Adaptiver Vordergrund: transparent, derselbe Anteil wie in der Kachel.
  //
  // Die Schutzzone kommt oben drauf: `flutter_launcher_icons` setzt die
  // Grafik mit 16 % Einzug in die Adaptive-Icon-Fläche, das Motiv landet
  // also bei 0,72 × 0,68 ≈ 0,49 davon – gut innerhalb der inneren zwei
  // Drittel, die jede Launcher-Maske stehen lässt. Die Glut reicht weiter,
  // ist dort aber längst durchsichtig.
  _schreibe(
    '${ziel.path}/app_icon_vordergrund.png',
    _icon(1024, mitHintergrund: false, motivAnteil: _kachelAnteil),
  );

  // Adaptiver Hintergrund: nur der Verlauf, ohne Motiv. Eine Farbe reichte
  // frueher; der Verlauf braucht ein Bild.
  final grund = Image(width: 1024, height: 1024, numChannels: 4);
  _verlauf(grund);
  _schreibe('${ziel.path}/app_icon_hintergrund.png', grund);

  // --- Splash -------------------------------------------------------------
  // Klassischer Splash: Motiv ohne Hintergrund, die Farbe setzt
  // flutter_native_splash.
  _schreibe(
    '${ziel.path}/splash_dunkel.png',
    _icon(512, mitHintergrund: false, motivAnteil: 0.80),
  );
  _schreibe(
    '${ziel.path}/splash_hell.png',
    _icon(
      512,
      mitHintergrund: false,
      farbe: _mochaAkzent,
      glutfarbe: _mochaGlut,
      motivAnteil: 0.80,
    ),
  );

  // Android 12+: Das System zeigt eine 1152×1152-Grafik, von der nur die
  // inneren 768×768 sichtbar sind – das Motiv muss also klein bleiben.
  //
  // Der Anteil steht in `Marke`, nicht hier: Der eigene Startbildschirm
  // rechnet daraus die Größe seines Zeichens, damit beim Übergang nichts
  // springt (DECISIONS 52). Zwei Zahlen wären zwei Zahlen, die auseinander
  // laufen.
  _schreibe(
    '${ziel.path}/splash_android12_dunkel.png',
    _icon(
      1152,
      mitHintergrund: false,
      motivAnteil: Marke.splashMotivAnteil,
    ),
  );
  _schreibe(
    '${ziel.path}/splash_android12_hell.png',
    _icon(
      1152,
      mitHintergrund: false,
      farbe: _mochaAkzent,
      glutfarbe: _mochaGlut,
      motivAnteil: Marke.splashMotivAnteil,
    ),
  );

  // --- Vorschau -----------------------------------------------------------
  // Ein Bild zum Danebenhalten: dasselbe Zeichen gross, in
  // Homescreen-Groesse und so, wie es ohne Kachel auf dem Splash steht.
  _schreibe('${ziel.path}/icon_vorschau.png', _vorschau());

  stdout.writeln('Fertig. Weiter mit:');
  stdout.writeln('  dart run flutter_launcher_icons');
  stdout.writeln('  dart run flutter_native_splash:create');
}

/// Das Vergleichsbild.
///
/// Links die Kachel gross, in der Mitte in Homescreen-Groesse (48 dp auf
/// einem xxhdpi-Geraet sind 144 px), rechts das Zeichen ohne Kachel auf dem
/// Ton, mit dem der Start beginnt – so steht es im Splash.
Image _vorschau() {
  const rand = 24;
  const gross = 320;
  const klein = 144;
  final blatt = Image(width: 3 * gross + 4 * rand, height: gross + 2 * rand)
    ..clear(ColorUint8.rgb(14, 16, 18));

  final kachel = _icon(gross, mitHintergrund: true, motivAnteil: _kachelAnteil);
  compositeImage(blatt, kachel, dstX: rand, dstY: rand);

  final winzig = copyResize(kachel, width: klein, height: klein);
  compositeImage(
    blatt,
    winzig,
    dstX: 2 * rand + gross,
    dstY: rand + (gross - klein) ~/ 2,
  );

  // Der Splash: flache Startfarbe, Motiv ohne Kachel.
  final startton = Image(width: gross, height: gross, numChannels: 4)
    ..clear(ColorUint8.rgb(0x12, 0x2C, 0x31));
  final motiv = _icon(gross, mitHintergrund: false, motivAnteil: 0.52);
  compositeImage(startton, motiv);
  compositeImage(blatt, startton, dstX: 3 * rand + 2 * gross, dstY: rand);

  return blatt;
}

void _schreibe(String pfad, Image bild) {
  File(pfad).writeAsBytesSync(encodePng(bild));
  stdout.writeln('  ✓ $pfad (${bild.width}×${bild.height})');
}

/// Zeichnet das Motiv.
///
/// [motivAnteil] skaliert es um die Bildmitte – gebraucht für die adaptive
/// Maske und für die Splash-Vorgaben, die beide eine Schutzzone verlangen.
Image _icon(
  int kante, {
  required bool mitHintergrund,
  int farbe = _offWhite,
  int glutfarbe = _gold,
  double motivAnteil = 1.0,
}) {
  final bild = Image(width: kante, height: kante, numChannels: 4);

  if (mitHintergrund) {
    _verlauf(bild);
  } else {
    fill(bild, color: ColorUint8.rgba(0, 0, 0, 0));
  }

  final r = (farbe >> 16) & 0xFF;
  final g = (farbe >> 8) & 0xFF;
  final b = farbe & 0xFF;

  // 4×4-Überabtastung je Pixel. Ohne sie sind die Ränder bei 48 px so
  // ausgefranst, dass das Icon billig aussieht.
  const raster = 4;
  const schritt = 1.0 / raster;

  for (var py = 0; py < kante; py++) {
    for (var px = 0; px < kante; px++) {
      var treffer = 0;

      for (var sy = 0; sy < raster; sy++) {
        for (var sx = 0; sx < raster; sx++) {
          final x = (px + (sx + 0.5) * schritt) / kante;
          final y = (py + (sy + 0.5) * schritt) / kante;
          if (_imMotiv(x, y, motivAnteil)) treffer++;
        }
      }

      if (treffer == 0) continue;

      final deckung = treffer / (raster * raster);
      _mische(bild, px, py, r, g, b, deckung);
    }
  }

  _glut(bild, motivAnteil, glutfarbe);
  return bild;
}

/// Der Petrol-Verlauf der App als Kachel-Hintergrund.
///
/// Kein flacher Ton mehr: Das Icon soll aussehen wie der Grund, auf dem die
/// App steht (DECISIONS 54). Oben Deep Teal, unten fast schwarzes Blau.
void _verlauf(Image bild) {
  final kante = bild.height;
  for (var y = 0; y < kante; y++) {
    final t = y / (kante - 1);
    final farbe = ColorUint8.rgba(
      _misch((_deepTeal >> 16) & 0xFF, (_tiefBlau >> 16) & 0xFF, t),
      _misch((_deepTeal >> 8) & 0xFF, (_tiefBlau >> 8) & 0xFF, t),
      _misch(_deepTeal & 0xFF, _tiefBlau & 0xFF, t),
      255,
    );
    for (var x = 0; x < bild.width; x++) {
      bild.setPixel(x, y, farbe);
    }
  }
}

/// Die Glut – über die Linien gelegt, nicht darunter.
///
/// Sie überstrahlt den Schulterbogen dort, wo sie am dichtesten ist. Genau so
/// steht es in der Vorlage: Das Licht kommt von innen und liegt vor dem
/// Körper, nicht dahinter.
///
/// Die Kurve kommt aus [Marke.glutDeckung] – dieselbe, die [MarkenLogo] zur
/// Laufzeit abtastet. Zwei Kurven wären zwei verschiedene Zeichen.
void _glut(Image bild, double motivAnteil, int glutfarbe) {
  final kante = bild.height;
  final radius = Marke.glutRadius * motivAnteil;

  final gr = (glutfarbe >> 16) & 0xFF;
  final gg = (glutfarbe >> 8) & 0xFF;
  final gb = glutfarbe & 0xFF;
  final wr = (_kernweiss >> 16) & 0xFF;
  final wg = (_kernweiss >> 8) & 0xFF;
  final wb = _kernweiss & 0xFF;

  // Mittelpunkt mitskaliert, wie beim Motiv auch.
  final cx = 0.5 + (Marke.glutX - 0.5) * motivAnteil;
  final cy = 0.5 + (Marke.glutY - 0.5) * motivAnteil;

  for (var py = 0; py < kante; py++) {
    for (var px = 0; px < bild.width; px++) {
      final x = (px + 0.5) / kante;
      final y = (py + 0.5) / kante;
      final dx = x - cx;
      final dy = y - cy;
      final abstand = math.sqrt(dx * dx + dy * dy);
      if (abstand >= radius) continue;

      final anteil = abstand / radius;
      final deckung = Marke.glutDeckung(anteil);
      if (deckung <= 0.002) continue;

      final weiss = Marke.glutWeiss(anteil);
      _mische(
        bild,
        px,
        py,
        _misch(gr, wr, weiss),
        _misch(gg, wg, weiss),
        _misch(gb, wb, weiss),
        deckung,
      );
    }
  }
}

int _misch(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);

/// Liegt ein Punkt auf einem der beiden Ringe?
bool _imMotiv(double x, double y, double anteil) {
  // Um die Bildmitte skalieren: Der Punkt wird zurückgerechnet, statt die
  // Geometrie zu verändern.
  final gx = 0.5 + (x - 0.5) / anteil;
  final gy = 0.5 + (y - 0.5) / anteil;

  if (_imRing(gx, gy, _ovalX, _ovalY, _ovalRx, _ovalRy)) return true;

  // Der Schulterbogen endet, bevor er den unteren Rand erreicht – sonst
  // wirkt er wie ein abgeschnittener Kreis statt wie Schultern.
  if (gy <= _schulterUnterkante &&
      _imRing(gx, gy, _schulterX, _schulterY, _schulterRx, _schulterRy)) {
    return true;
  }

  return false;
}

/// Ring zwischen zwei konzentrischen Ellipsen.
bool _imRing(double x, double y, double cx, double cy, double rx, double ry) {
  final h = _strich / 2;

  final aussen = _inEllipse(x, y, cx, cy, rx + h, ry + h);
  if (!aussen) return false;

  final innenRx = rx - h;
  final innenRy = ry - h;
  if (innenRx <= 0 || innenRy <= 0) return true;

  return !_inEllipse(x, y, cx, cy, innenRx, innenRy);
}

bool _inEllipse(double x, double y, double cx, double cy, double rx, double ry) {
  final dx = (x - cx) / rx;
  final dy = (y - cy) / ry;
  return dx * dx + dy * dy <= 1.0;
}

/// Legt Farbe mit Deckung über das Pixel.
void _mische(Image bild, int x, int y, int r, int g, int b, double deckung) {
  final vorhanden = bild.getPixel(x, y);
  final aA = vorhanden.a / 255.0;
  final aB = deckung;
  final aNeu = aB + aA * (1 - aB);
  if (aNeu <= 0) return;

  double kanal(num alt, int neu) =>
      (neu * aB + alt * aA * (1 - aB)) / aNeu;

  bild.setPixelRgba(
    x,
    y,
    kanal(vorhanden.r, r).round(),
    kanal(vorhanden.g, g).round(),
    kanal(vorhanden.b, b).round(),
    (aNeu * 255).round(),
  );
}

/// Dieselbe Geometrie als SVG – die Fassung zum Weiterbearbeiten.
///
/// Wird mitgeneriert und nicht von Hand gepflegt: Sonst zeigt sie irgendwann
/// etwas anderes als das Icon auf dem Gerät.
String _svg() {
  String prozent(double wert) => (wert * 1024).toStringAsFixed(1);

  final strich = prozent(_strich);
  final sand = '#${_sand.toRadixString(16).substring(2).toUpperCase()}';
  final teal = '#${_deepTeal.toRadixString(16).substring(2).toUpperCase()}';

  // Der Schulterbogen wird über eine Maske beschnitten – dasselbe, was
  // `_schulterUnterkante` beim Rastern tut.
  final schnitt = prozent(_schulterUnterkante);

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!--
  ERZEUGT von tool/marke_erzeugen.dart – Änderungen hier gehen beim nächsten
  Lauf verloren. Die Geometrie steht in dieser Datei ganz oben.

  Motiv: das Gesichts-Oval aus dem Kamera-Sucher, mit angedeuteten Schultern.
  Farben: Deep Teal $teal, Sand $sand.
-->
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"
     viewBox="0 0 1024 1024">
  <defs>
    <clipPath id="schulterschnitt">
      <rect x="0" y="0" width="1024" height="$schnitt" />
    </clipPath>
  </defs>

  <rect width="1024" height="1024" fill="$teal" />

  <ellipse cx="${prozent(_ovalX)}" cy="${prozent(_ovalY)}"
           rx="${prozent(_ovalRx)}" ry="${prozent(_ovalRy)}"
           fill="none" stroke="$sand" stroke-width="$strich" />

  <g clip-path="url(#schulterschnitt)">
    <ellipse cx="${prozent(_schulterX)}" cy="${prozent(_schulterY)}"
             rx="${prozent(_schulterRx)}" ry="${prozent(_schulterRy)}"
             fill="none" stroke="$sand" stroke-width="$strich" />
  </g>
</svg>
''';
}
