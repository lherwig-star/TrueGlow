import 'package:hive_flutter/hive_flutter.dart';

/// Schmale Abstraktion ueber den lokalen Speicher.
///
/// Sie existiert aus einem konkreten Grund: Hive schreibt echte Dateien, und
/// in Widget-Tests laeuft die Uhr gefaked – ein Schreibvorgang kommt dort nie
/// zurueck und der Test haengt. Mit dieser Schnittstelle bekommen Widget-Tests
/// einen In-Memory-Store, waehrend die Hive-Variante in normalen Unit-Tests
/// weiterhin gegen echte Dateien geprueft wird.
abstract interface class KeyValueStore {
  Object? get(String schluessel);
  Future<void> put(String schluessel, Object? wert);
  Future<void> delete(String schluessel);
  Future<void> clear();
  Iterable<Object?> get values;
  bool get isEmpty;
}

/// Produktive Implementierung auf Basis einer geoeffneten Hive-Box.
class HiveStore implements KeyValueStore {
  HiveStore(this._box);

  final Box<dynamic> _box;

  @override
  Object? get(String schluessel) => _box.get(schluessel);

  @override
  Future<void> put(String schluessel, Object? wert) =>
      _box.put(schluessel, wert);

  @override
  Future<void> delete(String schluessel) => _box.delete(schluessel);

  @override
  Future<void> clear() => _box.clear();

  @override
  Iterable<Object?> get values => _box.values;

  @override
  bool get isEmpty => _box.isEmpty;
}

/// Implementierung ohne Dateizugriff – fuer Widget-Tests.
class MemoryStore implements KeyValueStore {
  final Map<String, Object?> _daten = {};

  @override
  Object? get(String schluessel) => _daten[schluessel];

  @override
  Future<void> put(String schluessel, Object? wert) async =>
      _daten[schluessel] = wert;

  @override
  Future<void> delete(String schluessel) async => _daten.remove(schluessel);

  @override
  Future<void> clear() async => _daten.clear();

  @override
  Iterable<Object?> get values => _daten.values;

  @override
  bool get isEmpty => _daten.isEmpty;
}
