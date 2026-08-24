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
// Nach dem Lauf:
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';

import 'package:image/image.dart';

// --- Farben (Spiegel von lib/core/theme/app_colors.dart) -------------------

/// Deep Teal – Hintergrund des dunklen Schemas.
const _deepTeal = 0xFF173C3B;

/// Sand – Akzent des dunklen Schemas.
const _sand = 0xFFD8C6AA;

// Mocha (#F7F2E9) ist die Hintergrundfarbe des hellen Schemas. Sie steht
// nicht hier, sondern in der flutter_native_splash-Konfiguration in
// pubspec.yaml – der Generator zeichnet nur das Motiv, nicht den Grund.

/// Akzent des hellen Schemas.
const _mochaAkzent = 0xFF6B4F3A;

// --- Geometrie, normiert auf 0..1 ------------------------------------------

/// Das Gesichts-Oval.
const _ovalX = 0.500;
const _ovalY = 0.430;
const _ovalRx = 0.215;
const _ovalRy = 0.285;

/// Die angedeuteten Schultern: ein weiter Bogen, von dem nur die Oberkante
/// im Bild liegt.
const _schulterX = 0.500;
const _schulterY = 1.145;
const _schulterRx = 0.425;
const _schulterRy = 0.345;

/// Strichstärke beider Ringe.
const _strich = 0.050;

/// Unterhalb dieser Höhe wird der Schulterbogen abgeschnitten.
const _schulterUnterkante = 0.895;

void main(List<String> argumente) {
  final ziel = Directory('assets/branding')..createSync(recursive: true);

  // --- SVG: die menschenlesbare Quelle ------------------------------------
  File('${ziel.path}/app_icon.svg').writeAsStringSync(_svg());

  // --- Icons --------------------------------------------------------------
  // Vollbild, mit Hintergrund: Quelle für iOS und den Legacy-Launcher.
  _schreibe('${ziel.path}/app_icon.png', _icon(1024, mitHintergrund: true));

  // Store-Icon 512×512 – dieselbe Grafik, andere Kantenlänge.
  _schreibe('${ziel.path}/store_icon_512.png', _icon(512, mitHintergrund: true));

  // Adaptiver Vordergrund: transparent, Motiv auf 62 % geschrumpft. Android
  // beschneidet die äußeren 33 % je nach Launcher-Maske – was dort liegt,
  // kann weg sein.
  _schreibe(
    '${ziel.path}/app_icon_vordergrund.png',
    _icon(1024, mitHintergrund: false, motivAnteil: 0.62),
  );

  // --- Splash -------------------------------------------------------------
  // Klassischer Splash: Motiv ohne Hintergrund, die Farbe setzt
  // flutter_native_splash.
  _schreibe(
    '${ziel.path}/splash_dunkel.png',
    _icon(512, mitHintergrund: false, farbe: _sand, motivAnteil: 0.80),
  );
  _schreibe(
    '${ziel.path}/splash_hell.png',
    _icon(512, mitHintergrund: false, farbe: _mochaAkzent, motivAnteil: 0.80),
  );

  // Android 12+: Das System zeigt eine 1152×1152-Grafik, von der nur die
  // inneren 768×768 sichtbar sind – das Motiv muss also klein bleiben.
  _schreibe(
    '${ziel.path}/splash_android12_dunkel.png',
    _icon(1152, mitHintergrund: false, farbe: _sand, motivAnteil: 0.52),
  );
  _schreibe(
    '${ziel.path}/splash_android12_hell.png',
    _icon(1152, mitHintergrund: false, farbe: _mochaAkzent, motivAnteil: 0.52),
  );

  stdout.writeln('Fertig. Weiter mit:');
  stdout.writeln('  dart run flutter_launcher_icons');
  stdout.writeln('  dart run flutter_native_splash:create');
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
  int farbe = _sand,
  double motivAnteil = 1.0,
}) {
  final bild = Image(width: kante, height: kante, numChannels: 4);

  final hintergrund = ColorUint8.rgba(
    (_deepTeal >> 16) & 0xFF,
    (_deepTeal >> 8) & 0xFF,
    _deepTeal & 0xFF,
    mitHintergrund ? 255 : 0,
  );
  fill(bild, color: hintergrund);

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

  return bild;
}

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
