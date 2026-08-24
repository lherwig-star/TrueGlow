import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/glowup_nutzer.dart';

/// Fehlerfaelle der Anmeldung – nach demselben Muster wie AnalysisFehler:
/// jeder Fall mit Titel und konkretem Tipp, damit die UI nichts erfinden muss.
enum AuthFehler {
  abgebrochen(
    'Anmeldung abgebrochen',
    'Kein Problem – du kannst es jederzeit noch einmal versuchen.',
  ),
  keinInternet(
    'Keine Verbindung',
    'Prüf deine Internetverbindung und versuch es noch einmal.',
  ),
  kontoBereitsVergeben(
    'Konto schon in Benutzung',
    'Dieses Google-Konto gehört bereits zu einem GlowUp-Zugang. Wir haben '
        'dich damit angemeldet.',
  ),
  nichtVerfuegbar(
    'Anmeldung nicht möglich',
    'Diese Anmeldeart steht auf deinem Gerät nicht zur Verfügung.',
  ),
  unbekannt(
    'Anmeldung fehlgeschlagen',
    'Da ist etwas schiefgelaufen. Versuch es bitte noch einmal.',
  );

  const AuthFehler(this.titel, this.tipp);

  final String titel;
  final String tipp;
}

class AuthException implements Exception {
  const AuthException(this.fehler, [this.details]);

  final AuthFehler fehler;
  final String? details;

  @override
  String toString() =>
      'AuthException(${fehler.name}${details == null ? '' : ': $details'})';
}

/// Die Anmeldung, wie die App sie sieht.
///
/// Zwischen UI und `firebase_auth` liegt bewusst diese Schicht. Sie kostet
/// fuenf Methoden und bringt zwei Dinge: „Sign in with Apple" ist spaeter nur
/// ein weiterer [AuthAnbieter], und die Widget-Tests laufen weiter ohne
/// Firebase-Initialisierung (siehe [FakeAuthRepository]).
abstract interface class AuthRepository {
  /// Das aktuell angemeldete Konto, synchron lesbar.
  ///
  /// Beim Start wartet `main()` auf den ersten Zustand, bevor die App
  /// gezeichnet wird – deshalb ist dieser Wert ab dem ersten Frame belastbar
  /// und der Router kann ihn direkt abfragen.
  GlowUpNutzer? get aktuell;

  /// Aenderungen des Anmeldezustands.
  Stream<GlowUpNutzer?> get zustand;

  /// Meldet mit dem gewaehlten Anbieter an.
  Future<GlowUpNutzer> anmelden(AuthAnbieter anbieter);

  /// Verknuepft das laufende (anonyme) Konto mit einem echten Anbieter.
  ///
  /// Das ist der Weg, auf dem aus „Erst ausprobieren" ein richtiges Konto
  /// wird, ohne dass Streak und Historie verlorengehen. Gehoert das
  /// Anbieterkonto bereits zu einem anderen Zugang, wird stattdessen dorthin
  /// angemeldet und [AuthFehler.kontoBereitsVergeben] als Hinweis geworfen –
  /// die Entscheidung, was dann passiert, faellt in der UI.
  Future<GlowUpNutzer> verknuepfen(AuthAnbieter anbieter);

  Future<void> abmelden();
}

/// Attrappe fuer Tests: kein Netz, kein Firebase, aber dieselbe Semantik.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({GlowUpNutzer? nutzer}) : _aktuell = nutzer {
    _melden();
  }

  /// Standardkonto der Widget-Tests: anonym angemeldet, wie nach
  /// „Erst ausprobieren".
  factory FakeAuthRepository.angemeldet() => FakeAuthRepository(
        nutzer: const GlowUpNutzer(uid: 'test-uid', anonym: true),
      );

  GlowUpNutzer? _aktuell;
  final StreamController<GlowUpNutzer?> _strom =
      StreamController<GlowUpNutzer?>.broadcast();

  /// Womit zuletzt angemeldet wurde – fuer Zusicherungen im Test.
  AuthAnbieter? zuletztGenutzt;

  /// Wird beim naechsten Aufruf geworfen statt anzumelden.
  AuthFehler? naechsterFehler;

  @override
  GlowUpNutzer? get aktuell => _aktuell;

  @override
  Stream<GlowUpNutzer?> get zustand => _strom.stream;

  @override
  Future<GlowUpNutzer> anmelden(AuthAnbieter anbieter) async {
    _pruefeFehler();
    zuletztGenutzt = anbieter;
    return _setze(
      GlowUpNutzer(
        uid: anbieter == AuthAnbieter.anonym ? 'anonym-uid' : 'konto-uid',
        anonym: anbieter == AuthAnbieter.anonym,
        email: anbieter == AuthAnbieter.anonym ? null : 'test@example.com',
        anzeigename: anbieter == AuthAnbieter.anonym ? null : 'Test',
      ),
    );
  }

  @override
  Future<GlowUpNutzer> verknuepfen(AuthAnbieter anbieter) async {
    _pruefeFehler();
    zuletztGenutzt = anbieter;
    final vorher = _aktuell;
    return _setze(
      GlowUpNutzer(
        // Beim Verknuepfen bleibt die uid erhalten – genau darum geht es.
        uid: vorher?.uid ?? 'konto-uid',
        anonym: false,
        email: 'test@example.com',
        anzeigename: 'Test',
      ),
    );
  }

  @override
  Future<void> abmelden() async {
    _aktuell = null;
    _melden();
  }

  void _pruefeFehler() {
    final fehler = naechsterFehler;
    if (fehler != null) {
      naechsterFehler = null;
      throw AuthException(fehler);
    }
  }

  GlowUpNutzer _setze(GlowUpNutzer nutzer) {
    _aktuell = nutzer;
    _melden();
    return nutzer;
  }

  void _melden() {
    if (!_strom.isClosed) _strom.add(_aktuell);
  }
}

/// Die Anmeldung der laufenden App.
///
/// Im Demo-/Screenshot-Modus laeuft alles ohne Backend – dort tritt die
/// Attrappe an die Stelle von Firebase, damit sich die App ohne Konto und
/// ohne Netz vorfuehren laesst.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider muss beim Start gesetzt werden – in main() über '
    'die Firebase-Fassung, in Tests über FakeAuthRepository.',
  );
});

/// Das angemeldete Konto als Zustand, fuer die UI.
final nutzerProvider = StreamProvider<GlowUpNutzer?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  // Der Strom meldet erst bei der naechsten Aenderung – der aktuelle Stand
  // steht deshalb voran.
  return repo.zustand.startsWith(repo.aktuell);
});

extension _MitStartwert<T> on Stream<T> {
  Stream<T> startsWith(T wert) async* {
    yield wert;
    yield* this;
  }
}

/// Kurzer Zugriff fuer Stellen, die nur „angemeldet ja/nein" brauchen.
final angemeldetProvider = Provider<bool>((ref) {
  return ref.watch(nutzerProvider).valueOrNull != null;
});
