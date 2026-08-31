import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kein Bildschirm bringt seine eigenen Farben mit.
///
/// Der Anlass steht in DECISIONS 51: Nach dem Design-Umbau war der neue Look
/// auf der Startseite, aber nicht auf den Unterseiten — dort standen noch die
/// alten Werte. So etwas fällt niemandem auf, der nicht gerade auf genau
/// diesen Bildschirm schaut, und deshalb prüft es hier eine Maschine.
///
/// Zwei Regeln, beide über den ganzen Quelltext:
///
///  1. Farbwerte (`Color(0x…)`) und Material-Farben (`Colors.rot`) stehen nur
///     dort, wo es einen benannten Grund dafür gibt.
///  2. Wer eine Farbe braucht, holt sie über `context.farben` aus
///     [AppColors] — die einzige Stelle, an der ein Ton beschlossen wird.
void main() {
  final dateien = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // Erzeugte Übersetzungen enthalten keine Farben und sind riesig.
      .where((f) => !f.path.contains('l10n${Platform.pathSeparator}app_'))
      .toList();

  /// Wo ein fester Farbwert stehen darf – jeweils mit dem Grund.
  ///
  /// Die Liste ist kurz und soll es bleiben. Kommt eine Zeile dazu, gehört
  /// der Grund daneben; „ist mir gerade eingefallen" ist keiner.
  const erlaubt = <String, String>{
    // Hier werden die Töne beschlossen. Ohne Farbwerte ginge es nicht.
    'app_colors.dart': 'die Farbpalette selbst',
    // Über einem Kamerabild oder einem Foto trägt keine Themefarbe: Der
    // Untergrund ist beliebig, und Schwarz/Weiß ist das Einzige, was darauf
    // in jedem Fall lesbar bleibt.
    'camera_screen.dart': 'Bedienelemente über dem Kamerabild',
    'silhouette_overlay.dart': 'Silhouette über dem Kamerabild',
    'fortschritt_screen.dart': 'Marken über dem Foto',
    'jubel_overlay.dart': 'Abdunkelung hinter dem Jubel-Dialog',
    // Weißglühend ist weiß. Der Kern der Glut ist kein Designton, sondern
    // die Mitte eines Leuchtens – in beiden Schemata dieselbe Physik.
    'marken_logo.dart': 'der weißglühende Kern der Glut',
  };

  bool istErlaubt(String pfad) =>
      erlaubt.keys.any((name) => pfad.endsWith(name));

  /// `Colors.transparent` ist keine Farbe, sondern deren Abwesenheit – und
  /// `AppColors.dunkel` ist die Palette selbst, nicht ein einzelner Ton.
  final farbwert =
      RegExp(r'Color\(0x|(?<!App)Colors\.(?!transparent)[a-z]');

  test('kein Bildschirm setzt eigene Farbwerte', () {
    final funde = <String>[];

    for (final datei in dateien) {
      if (istErlaubt(datei.path)) continue;

      final zeilen = datei.readAsLinesSync();
      for (var i = 0; i < zeilen.length; i += 1) {
        final zeile = zeilen[i];
        // Kommentare dürfen Farbwerte nennen – sie erklären sie oft.
        if (zeile.trimLeft().startsWith('//')) continue;
        if (farbwert.hasMatch(zeile)) {
          funde.add('${datei.path}:${i + 1}  ${zeile.trim()}');
        }
      }
    }

    expect(
      funde,
      isEmpty,
      reason: 'Diese Zeilen setzen eine Farbe selbst, statt sie aus '
          '`context.farben` zu holen:\n${funde.join('\n')}',
    );
  });

  test('die Ausnahmen gibt es alle noch', () {
    // Eine Ausnahme für eine Datei, die es nicht mehr gibt, ist eine Tür,
    // die offen steht, ohne dass jemand hindurchgeht.
    for (final name in erlaubt.keys) {
      expect(
        dateien.any((f) => f.path.endsWith(name)),
        isTrue,
        reason: 'Ausnahme für $name, aber die Datei fehlt',
      );
    }
  });

  test('jede Ausnahme trägt einen Grund', () {
    for (final eintrag in erlaubt.entries) {
      expect(eintrag.value.trim(), isNotEmpty, reason: eintrag.key);
    }
  });

  test('alle Farbrollen werden auch benutzt', () {
    // Eine Rolle, die niemand aufruft, ist entweder vergessen worden oder
    // überflüssig. Beides gehört bemerkt.
    final quelle = File('lib/core/theme/app_colors.dart').readAsStringSync();
    final rollen = RegExp(r'^  final Color (\w+);', multiLine: true)
        .allMatches(quelle)
        .map((m) => m.group(1)!)
        .toList();

    expect(rollen, isNotEmpty);

    final gesamt = dateien
        .where((f) => !f.path.endsWith('app_colors.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    for (final rolle in rollen) {
      expect(
        gesamt.contains('.$rolle'),
        isTrue,
        reason: 'Die Farbrolle "$rolle" wird nirgends verwendet',
      );
    }
  });
}
