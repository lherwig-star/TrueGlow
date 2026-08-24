import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../sync/sync_store.dart';
import 'key_value_store.dart';

/// Lokale Speicherung. Bewusst ohne generierte TypeAdapter: alles wird als
/// JSON-String abgelegt. Das spart den Code-Generator und macht spaetere
/// Schema-Aenderungen unkritisch.
class HiveService {
  HiveService._();

  /// Gespeicherte Analysen, Schluessel ist die Analyse-ID.
  static const boxAnalysen = 'analysen';

  /// Onboarding-Antworten und Verweis auf die aktuelle Analyse.
  static const boxEinstellungen = 'einstellungen';

  /// Abgehakte Habits pro Tag, Schluessel ist das Datum (yyyy-mm-tt).
  static const boxFortschritt = 'fortschritt';

  /// Zeitplan, Entwurf und Historie der Check-ins.
  static const boxCheckins = 'checkins';

  /// Wann welcher Schluessel zuletzt geschrieben wurde – die Grundlage der
  /// Konfliktregel „letzter Schreiber gewinnt".
  ///
  /// Bewusst eine eigene Box und kein Sonderschluessel in den Datenboxen: Der
  /// Analyse-Verlauf liest seine Box vollstaendig aus (`values`), ein
  /// Fremdkoerper darin waere ein Fehler mit Ansage.
  static const boxSync = 'sync';

  /// Die Boxen mit Nutzdaten. Sie werden synchronisiert und von
  /// „Alle Daten löschen" geleert.
  static const alleBoxen = [
    boxAnalysen,
    boxEinstellungen,
    boxFortschritt,
    boxCheckins,
  ];

  /// Alles, was geoeffnet werden muss – Nutzdaten plus Zeitstempel.
  static const alleBoxenMitSync = [...alleBoxen, boxSync];

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait(alleBoxenMitSync.map(Hive.openBox<dynamic>));
  }
}

/// Der reine lokale Speicher einer Box – ohne Cloud.
final _hiveStoreProvider = Provider.family<KeyValueStore, String>(
  (ref, name) => HiveStore(Hive.box<dynamic>(name)),
);

/// Zugriff auf einen Speicherbereich.
///
/// Liefert einen [SyncStore]: Er schreibt lokal und zieht die Cloud nach.
/// Weil saemtliche Controller seit jeher durch [KeyValueStore] schreiben,
/// haengt damit die komplette App am Sync, ohne dass ein einziger Controller
/// davon wissen muss.
///
/// In Widget-Tests wird das durch einen [MemoryStore] ersetzt.
final storeProvider = Provider.family<KeyValueStore, String>(
  (ref, name) => SyncStore(
    box: name,
    lokal: ref.watch(_hiveStoreProvider(name)),
    zeitstempel: ref.watch(_hiveStoreProvider(HiveService.boxSync)),
  ),
);

/// Loescht saemtliche lokal gespeicherten Daten (DSGVO-Funktion in den
/// Einstellungen).
///
/// Die Cloud-Haelfte macht der Aufrufer – siehe Einstellungen.
final alleDatenLoeschenProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Die Zeitstempel gehen mit: ohne Daten sagen sie nichts mehr aus.
    for (final name in HiveService.alleBoxenMitSync) {
      await ref.read(storeProvider(name)).clear();
    }
  };
});
