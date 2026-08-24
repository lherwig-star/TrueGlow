import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  static const alleBoxen = [
    boxAnalysen,
    boxEinstellungen,
    boxFortschritt,
    boxCheckins,
  ];

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait(alleBoxen.map(Hive.openBox<dynamic>));
  }
}

/// Zugriff auf einen Speicherbereich. In Widget-Tests wird das durch einen
/// [MemoryStore] ersetzt.
final storeProvider = Provider.family<KeyValueStore, String>(
  (ref, name) => HiveStore(Hive.box<dynamic>(name)),
);

/// Loescht saemtliche lokal gespeicherten Daten (DSGVO-Funktion in den
/// Einstellungen).
final alleDatenLoeschenProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    for (final name in HiveService.alleBoxen) {
      await ref.read(storeProvider(name)).clear();
    }
  };
});
