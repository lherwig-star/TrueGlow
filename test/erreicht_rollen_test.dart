import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Ocker ist Schrift. Amber ist alles Sichtbare.**
///
/// Der Anlass steht in DECISIONS 64: Nach der Umstellung auf Creme, Teal und
/// Amber trugen alle kleinen Erreicht-Elemente — Haken, Joker-Schilde,
/// gewählte Radio-Punkte, Abzeichen — das dunkle Ocker. Das ist die richtige
/// Farbe für 12-Punkt-Schrift auf hellem Grund und die falsche für alles
/// andere: Als Fläche wirkt sie schlammig statt golden.
///
/// Die Regel ist deshalb hart und ohne Ausnahme: `erreicht` steht
/// ausschließlich in einem `TextStyle`. Jede Fläche, jeder Rahmen, jedes
/// Symbol nimmt `erreichtFlaeche`.
///
/// Dieser Test liest den Quelltext, weil sich die Regel anders nicht prüfen
/// lässt — eine Farbe im Widgetbaum sagt nicht mehr, wofür sie gedacht war.
void main() {
  /// Alle Dart-Dateien unter `lib/`.
  Iterable<File> quellen() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // Die erzeugten Lokalisierungen enthalten keine Farben.
      .where((f) => !f.path.contains('l10n'));

  /// Steht diese Zeile innerhalb eines `TextStyle`?
  ///
  /// Gesucht wird rückwärts: Ein `TextStyle(` in den letzten Zeilen ohne
  /// dazwischenliegendes `)` auf gleicher oder geringerer Einrückung reicht
  /// als Nachweis. Das ist keine Syntaxanalyse, aber es fängt genau den
  /// Fall, um den es geht — eine Farbe, die an einem `Icon`, einem
  /// `Border` oder einer `BoxDecoration` hängt.
  bool inTextStyle(List<String> zeilen, int nr) {
    for (var i = nr; i >= 0 && i > nr - 8; i -= 1) {
      final zeile = zeilen[i];
      if (zeile.contains('TextStyle(')) return true;
      if (zeile.contains('Icon(') ||
          zeile.contains('Border.all(') ||
          zeile.contains('BoxDecoration(') ||
          zeile.contains('BoxShadow(')) {
        return false;
      }
    }
    return false;
  }

  test('die Schrift-Rolle steht nur in einem TextStyle', () {
    final verstoesse = <String>[];

    for (final datei in quellen()) {
      final zeilen = datei.readAsLinesSync();
      for (var i = 0; i < zeilen.length; i += 1) {
        final zeile = zeilen[i];
        // Nur die blanke Rolle – nicht erreichtFlaeche, erreichtLeer,
        // erreichtChip oder aufErreicht.
        final treffer = RegExp(r'farben\.erreicht\b(?!F|L|C)').hasMatch(zeile) ||
            RegExp(r'farben\.erreicht$').hasMatch(zeile.trimRight());
        if (!treffer) continue;
        if (zeile.contains('erreichtFlaeche') ||
            zeile.contains('erreichtLeer') ||
            zeile.contains('erreichtChip')) {
          continue;
        }
        // Eine Zuweisung an eine Variable ist noch keine Verwendung. Was
        // damit geschieht, entscheidet die Stelle, an der sie eingesetzt
        // wird — dort steht dann nicht mehr `farben.erreicht`. Diese Luecke
        // bleibt bewusst offen: Der Test faengt das Muster, das der Anlass
        // war (eine Rolle direkt an Icon, Rahmen oder Flaeche), nicht jede
        // denkbare Umleitung.
        final rumpf = zeile.trimLeft();
        if (rumpf.startsWith('final ') || rumpf.startsWith('var ')) continue;

        if (!inTextStyle(zeilen, i)) {
          verstoesse.add('${datei.path}:${i + 1}  ${zeile.trim()}');
        }
      }
    }

    expect(
      verstoesse,
      isEmpty,
      reason: 'Diese Stellen tragen die Schrift-Rolle an etwas, das keine '
          'Schrift ist. Sie gehoeren auf `erreichtFlaeche`:\n'
          '${verstoesse.join('\n')}',
    );
  });

  test('und die Flaechen-Rolle steht nirgends in einem TextStyle', () {
    // Die Gegenrichtung: Ein Amber-Text auf hellem Grund waere nicht
    // lesbar – 2,4:1 auf der Karte.
    final verstoesse = <String>[];

    for (final datei in quellen()) {
      final zeilen = datei.readAsLinesSync();
      for (var i = 0; i < zeilen.length; i += 1) {
        if (!zeilen[i].contains('farben.erreichtFlaeche')) continue;
        // Eine Toenung ist keine Schrift, auch wenn sie in der Naehe einer
        // steht.
        if (zeilen[i].contains('.withValues(')) continue;
        if (inTextStyle(zeilen, i)) {
          verstoesse.add('${datei.path}:${i + 1}  ${zeilen[i].trim()}');
        }
      }
    }

    expect(verstoesse, isEmpty, reason: verstoesse.join('\n'));
  });

  test('kein Bildschirm hat die Regel per Einzelfarbe umgangen', () {
    // Der Gegencheck zum bestehenden Test gegen fest verdrahtete Werte:
    // Die Hex-Zahlen der beiden Amber-Rollen duerfen nirgends im Code
    // stehen ausser in der Palette.
    for (final datei in quellen()) {
      if (datei.path.endsWith('app_colors.dart')) continue;
      final inhalt = datei.readAsStringSync().toUpperCase();
      for (final wert in ['E59305', '8F5500', 'FDE9D2', 'F5DEB9']) {
        expect(
          inhalt.contains(wert),
          isFalse,
          reason: '${datei.path} schreibt $wert von Hand hin',
        );
      }
    }
  });
}
