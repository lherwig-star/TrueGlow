// Prüft echte Analyse-Antworten auf Formulierungen, die wie eine Diagnose
// klingen.
//
//   dart run tool/diagnose_stichprobe.dart antwort1.json antwort2.json …
//
// Die Dateien sind die JSON-Antworten, wie sie aus der Cloud Function kommen
// (Function-Logs → Antwortobjekt kopieren, oder in der App abgreifen). Das
// Skript liest alle Textfelder heraus und hält sie gegen die Regeln in
// `diagnose_pruefung.dart`.
//
// Beendet sich mit Fehlercode, wenn ein harter Verstoß darin steht — so lässt
// sich die Stichprobe auch automatisiert fahren.
import 'dart:convert';
import 'dart:io';

import 'diagnose_pruefung.dart';

void main(List<String> argumente) {
  if (argumente.isEmpty) {
    stderr.writeln(
      'Aufruf: dart run tool/diagnose_stichprobe.dart <datei.json> …',
    );
    exitCode = 2;
    return;
  }

  var verstoesseGesamt = 0;

  for (final pfad in argumente) {
    final datei = File(pfad);
    if (!datei.existsSync()) {
      stderr.writeln('✗ $pfad: nicht gefunden');
      exitCode = 2;
      continue;
    }

    final text = _texteAus(datei.readAsStringSync());
    final befunde = pruefe(text);
    final hart =
        befunde.where((b) => b.regel.gewicht == Befundgewicht.verstoss).length;
    verstoesseGesamt += hart;

    stdout.writeln('--- $pfad (${text.length} Zeichen) ---');
    if (befunde.isEmpty) {
      stdout.writeln('✓ nichts gefunden');
    } else {
      for (final befund in befunde) {
        stdout.writeln('  $befund');
        stdout.writeln('    → ${befund.regel.warum}');
      }
    }
    stdout.writeln();
  }

  if (verstoesseGesamt > 0) {
    stderr.writeln(
      '$verstoesseGesamt harte Verstöße. Prompt nachschärfen '
      '(functions/src/analyse_prompt.ts) und Ergebnis in DECISIONS.md '
      'festhalten.',
    );
    exitCode = 1;
  }
}

/// Sammelt alle Zeichenketten aus einer beliebig verschachtelten JSON-Struktur.
///
/// Bewusst schematisch: Die Antwort kann sich ändern, die Frage bleibt
/// dieselbe — steht irgendwo ein Satz, der wie ein Befund klingt?
String _texteAus(String rohtext) {
  final gesammelt = <String>[];

  void gehe(Object? knoten) {
    if (knoten is String) {
      gesammelt.add(knoten);
    } else if (knoten is List) {
      knoten.forEach(gehe);
    } else if (knoten is Map) {
      knoten.values.forEach(gehe);
    }
  }

  try {
    gehe(jsonDecode(rohtext));
  } on FormatException {
    // Kein JSON? Dann eben der rohe Text – besser als gar keine Prüfung.
    return rohtext;
  }

  return gesammelt.join('\n');
}
