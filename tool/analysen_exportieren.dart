// Holt gespeicherte Analysen aus einer Hive-Box und legt sie einzeln als
// JSON ab — die Vorstufe zur Diagnose-Stichprobe (`SETUP.md`, Abschnitt 6.5).
//
//   dart run tool/analysen_exportieren.dart <ordner-mit-analysen.hive> [ziel]
//
// Warum es dieses Werkzeug gibt: Die Antworten der Cloud Function stehen
// absichtlich in keinem Log (siehe `SETUP.md`, Abschnitt 6.2), und die
// Firebase-Konsole kann einzelne Firestore-Dokumente nicht als JSON
// exportieren. Die App legt jede Analyse aber ohnehin lokal ab — als reinen
// JSON-String, ohne TypeAdapter (`lib/core/storage/hive_service.dart`). Damit
// ist die Box auf dem Geraet die einfachste ehrliche Quelle.
//
// Die Box vom Android-Geraet holen (Debug-Build, USB-Debugging an):
//
//   adb shell run-as com.trueglow.app cp app_flutter/analysen.hive /sdcard/
//   adb pull /sdcard/analysen.hive <zielordner>/
//   adb shell rm /sdcard/analysen.hive
//
// Der Umweg ueber /sdcard vermeidet, eine Binaerdatei durch die Konsole zu
// leiten — `adb exec-out ... cat` beschaedigt sie unter Windows.
//
// Danach:
//
//   dart run tool/analysen_exportieren.dart <zielordner>
//   dart run tool/diagnose_stichprobe.dart <zielordner>/analyse_*.json
//
// Die Dateien enthalten echte Analysetexte. Sie gehoeren nicht ins Repo —
// `.gitignore` schliesst `tool/stichprobe/` deshalb aus.
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';

const _boxName = 'analysen';

Future<void> main(List<String> argumente) async {
  if (argumente.isEmpty) {
    stderr.writeln(
      'Aufruf: dart run tool/analysen_exportieren.dart '
      '<ordner-mit-analysen.hive> [ziel]',
    );
    exitCode = 2;
    return;
  }

  final quelle = Directory(argumente.first);
  if (!quelle.existsSync()) {
    stderr.writeln('✗ Ordner nicht gefunden: ${quelle.path}');
    exitCode = 2;
    return;
  }

  final boxDatei = File('${quelle.path}/$_boxName.hive');
  if (!boxDatei.existsSync()) {
    stderr.writeln('✗ ${boxDatei.path} nicht gefunden.');
    stderr.writeln('  Die Box zuerst vom Geraet holen — siehe Kopf dieser '
        'Datei.');
    exitCode = 2;
    return;
  }

  final ziel = Directory(argumente.length > 1 ? argumente[1] : quelle.path);
  ziel.createSync(recursive: true);

  Hive.init(quelle.path);
  final box = await Hive.openBox<dynamic>(_boxName);

  if (box.isEmpty) {
    stderr.writeln('✗ Die Box ist leer — keine gespeicherte Analyse.');
    await box.close();
    exitCode = 1;
    return;
  }

  var geschrieben = 0;
  var uebersprungen = 0;

  for (final schluessel in box.keys) {
    final roh = box.get(schluessel);
    if (roh is! String) {
      stderr.writeln('⚠ $schluessel: kein String, uebersprungen');
      uebersprungen++;
      continue;
    }

    // Einmal durch den Decoder: Das prueft die Datei gleich mit und macht die
    // Ausgabe lesbar, statt eine Zeile mit 4000 Zeichen zu schreiben.
    final Object? geparst;
    try {
      geparst = jsonDecode(roh);
    } on FormatException catch (e) {
      stderr.writeln('⚠ $schluessel: kein gueltiges JSON ($e)');
      uebersprungen++;
      continue;
    }

    final datei = File('${ziel.path}/analyse_$schluessel.json');
    datei.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(geparst),
    );
    stdout.writeln('✓ ${datei.path}');
    geschrieben++;
  }

  await box.close();

  stdout.writeln();
  stdout.writeln('$geschrieben Analyse(n) geschrieben'
      '${uebersprungen > 0 ? ', $uebersprungen uebersprungen' : ''}.');
  stdout.writeln('Weiter mit:');
  stdout.writeln(
    '  dart run tool/diagnose_stichprobe.dart ${ziel.path}/analyse_*.json',
  );

  if (geschrieben == 0) exitCode = 1;
}
