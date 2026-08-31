import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/firebase/firebase_start.dart';
import '../../analysis/logic/functions_client.dart';
import 'konto_dienst.dart';

/// „Meine Daten herunterladen" – die Auskunft nach Art. 15 und 20 DSGVO.
///
/// **Warum der Server die Daten sammelt und nicht die App.** Aus demselben
/// Grund wie beim Loeschen: Die App kennt ihren Teilbaum nur, soweit ihr
/// Datenmodell reicht. Ein spaeter hinzugekommener Zweig fehlte in der
/// Auskunft, ohne dass es auffiele – und eine Auskunft, die etwas
/// verschweigt, ist keine.
///
/// **Warum eine Datei und keine Anzeige im Bildschirm.** Das Recht ist ein
/// Recht auf eine *Kopie*. Etwas, das man nur ansehen und nicht mitnehmen
/// kann, ist keine Kopie. Die Datei geht deshalb durch den Teilen-Dialog des
/// Geraets – von dort landet sie in der Mail, in der Cloud oder im
/// Dateimanager, wie der Nutzer es will (SECURITY_AUDIT F2).
class DatenExport {
  DatenExport({FunctionsClient? client})
      : _client = client ?? FunctionsClient();

  final FunctionsClient _client;

  /// Zeitlimit. Hier wird nur gelesen, nicht gerechnet.
  static const Duration zeitlimit = Duration(seconds: 60);

  /// Holt die Auskunft, legt sie als Datei ab und liefert deren Pfad.
  ///
  /// Wirft [KontoException] – dieselben Faelle wie beim Loeschen, damit die
  /// Oberflaeche nur eine Fehlerbehandlung braucht.
  Future<File> erzeugen() async {
    final Map<String, dynamic> antwort;
    try {
      antwort = await _client.rufeRoh(
        FirebaseKonfig.functionDatenExport,
        const {},
        zeitlimit: zeitlimit,
      );
    } on FunctionsFehler catch (e) {
      debugPrint('Datenauskunft fehlgeschlagen: $e');
      throw KontoException(
        switch (e.code) {
          'unavailable' => KontoFehler.keinInternet,
          _ => KontoFehler.fehlgeschlagen,
        },
        '${e.code}: ${e.nachricht}',
      );
    }

    final auskunft = antwort['auskunft'];
    if (auskunft is! Map) {
      throw const KontoException(KontoFehler.fehlgeschlagen, 'leere Auskunft');
    }

    // Eingerueckt, damit die Datei ohne Werkzeug lesbar ist – sie soll ein
    // Mensch aufmachen koennen, nicht nur ein Programm.
    final text = const JsonEncoder.withIndent('  ').convert(auskunft);

    final ordner = await getApplicationDocumentsDirectory();
    final datei = File('${ordner.path}/$dateiname');
    await datei.writeAsString(text);
    return datei;
  }

  /// Uebergibt die Datei an den Teilen-Dialog des Geraets.
  Future<void> teilen(File datei) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(datei.path, mimeType: 'application/json')],
        fileNameOverrides: [dateiname],
      ),
    );
  }

  /// Fester Name statt eines Zeitstempels: Wer die Auskunft ein zweites Mal
  /// zieht, soll nicht zehn fast gleiche Dateien im Ordner haben.
  static const String dateiname = 'trueglow-meine-daten.json';
}

final datenExportProvider = Provider<DatenExport>((ref) => DatenExport());
