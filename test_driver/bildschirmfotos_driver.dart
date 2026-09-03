// Treiber fuer die App-Store-Bildschirmfotos.
//
// `flutter drive` startet die App auf dem Geraet oder Simulator und laesst
// diesen Prozess daneben laufen. Alles, was der Durchlauf drueben mit
// `binding.takeScreenshot(name)` aufnimmt, kommt hier als Bytefolge an — und
// nur hier kann sie auf die Platte geschrieben werden, denn die App selbst
// laeuft in einer Sandbox ohne Zugriff auf das Projektverzeichnis.
//
// Aufruf steht in integration_test/bildschirmfotos_test.dart.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Wohin die Bilder wandern. Der Ordner ist versioniert: Store-Material
/// gehoert zum Projekt, und weil das Repo oeffentlich ist, sind die Bilder
/// ohne Anmeldung abrufbar — anders als ein CI-Artefakt (DECISIONS 98).
const _ordner = 'store/screenshots/ios';

Future<void> main() async {
  // Eine Zeitgrenze nimmt integrationDriver in dieser Fassung nicht entgegen
  // (nachgesehen in integration_test_driver_extended.dart) - sie steht beim
  // Aufruf von `flutter drive` selbst.
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? _]) async {
      final datei = File('$_ordner/$name.png');
      await datei.parent.create(recursive: true);
      await datei.writeAsBytes(bytes);
      stdout.writeln('Bildschirmfoto: ${datei.path} (${bytes.length} Bytes)');
      return true;
    },
  );
}
