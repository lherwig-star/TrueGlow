import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/trueglow_nutzer.dart';
import 'auth_repository.dart';

/// Die Anmeldung ueber Firebase Auth.
///
/// Jeder Anbieter ist genau ein `case` in [_zugangsdaten]. „Sign in with
/// Apple" steht bereits darin: Sobald die iOS-App gebaut wird, ist nichts
/// weiter zu tun, als den Anbieter in der Firebase-Konsole zu aktivieren
/// (SETUP.md, Abschnitt 7).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  /// `initialize()` darf genau einmal laufen und muss vor `authenticate()`
  /// abgeschlossen sein.
  Future<void>? _googleBereit;

  @override
  TrueGlowNutzer? get aktuell => _uebersetze(_auth.currentUser);

  @override
  Stream<TrueGlowNutzer?> get zustand =>
      _auth.userChanges().map(_uebersetze);

  @override
  Future<TrueGlowNutzer> anmelden(AuthAnbieter anbieter) async {
    return _mitFehlerbehandlung(() async {
      if (anbieter == AuthAnbieter.anonym) {
        final ergebnis = await _auth.signInAnonymously();
        return _erwarte(ergebnis.user);
      }

      final zugang = await _zugangsdaten(anbieter);
      final ergebnis = await _auth.signInWithCredential(zugang);
      return _erwarte(ergebnis.user);
    });
  }

  @override
  Future<TrueGlowNutzer> verknuepfen(AuthAnbieter anbieter) async {
    final laufend = _auth.currentUser;
    if (laufend == null || anbieter == AuthAnbieter.anonym) {
      return anmelden(anbieter);
    }

    return _mitFehlerbehandlung(() async {
      final zugang = await _zugangsdaten(anbieter);
      try {
        final ergebnis = await laufend.linkWithCredential(zugang);
        return _erwarte(ergebnis.user);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use' &&
            e.code != 'email-already-in-use') {
          rethrow;
        }

        // Das Anbieterkonto gehoert schon zu einem anderen Zugang. Statt die
        // Anmeldung scheitern zu lassen, wird dorthin angemeldet – die Daten
        // des anonymen Kontos bleiben dabei allerdings zurueck. Genau darum
        // meldet das Repository den Sonderfall als Fehler nach oben: Die UI
        // soll ihn benennen koennen.
        final ersatz = e.credential ?? zugang;
        await _auth.signInWithCredential(ersatz);
        throw const AuthException(AuthFehler.kontoBereitsVergeben);
      }
    });
  }

  @override
  Future<void> abmelden() async {
    // Erst den Anbieter abmelden, sonst bietet Google beim naechsten Versuch
    // wortlos wieder dasselbe Konto an.
    try {
      await _google.signOut();
    } catch (e) {
      debugPrint('Google-Abmeldung: $e');
    }
    await _auth.signOut();
  }

  /// Holt die Zugangsdaten des Anbieters. Ein neuer Anbieter kommt hier dazu.
  Future<AuthCredential> _zugangsdaten(AuthAnbieter anbieter) async {
    switch (anbieter) {
      case AuthAnbieter.google:
        _googleBereit ??= _google.initialize();
        await _googleBereit;

        final konto = await _google.authenticate();
        final idToken = konto.authentication.idToken;
        if (idToken == null) {
          throw const AuthException(
            AuthFehler.unbekannt,
            'Google liefert kein idToken',
          );
        }
        return GoogleAuthProvider.credential(idToken: idToken);

      case AuthAnbieter.apple:
        // Firebase erledigt den Apple-Ablauf selbst; ein eigenes Paket
        // braucht es dafuer nicht.
        final anbieterDaten = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
        final ergebnis = await _auth.signInWithProvider(anbieterDaten);
        final zugang = ergebnis.credential;
        if (zugang == null) {
          throw const AuthException(
            AuthFehler.unbekannt,
            'Apple liefert keine Zugangsdaten',
          );
        }
        return zugang;

      case AuthAnbieter.anonym:
        throw const AuthException(AuthFehler.nichtVerfuegbar);
    }
  }

  Future<TrueGlowNutzer> _mitFehlerbehandlung(
    Future<TrueGlowNutzer> Function() aufruf,
  ) async {
    try {
      return await aufruf();
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      throw AuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthFehler.abgebrochen
            : AuthFehler.unbekannt,
        '${e.code}: ${e.description}',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        switch (e.code) {
          'network-request-failed' => AuthFehler.keinInternet,
          'operation-not-allowed' => AuthFehler.nichtVerfuegbar,
          'web-context-canceled' || 'canceled' => AuthFehler.abgebrochen,
          'credential-already-in-use' ||
          'email-already-in-use' =>
            AuthFehler.kontoBereitsVergeben,
          _ => AuthFehler.unbekannt,
        },
        '${e.code}: ${e.message}',
      );
    } on SocketException catch (e) {
      throw AuthException(AuthFehler.keinInternet, e.message);
    } catch (e) {
      throw AuthException(AuthFehler.unbekannt, '$e');
    }
  }

  TrueGlowNutzer _erwarte(User? nutzer) {
    final uebersetzt = _uebersetze(nutzer);
    if (uebersetzt == null) {
      throw const AuthException(AuthFehler.unbekannt, 'Kein Konto zurueck');
    }
    return uebersetzt;
  }

  static TrueGlowNutzer? _uebersetze(User? nutzer) {
    if (nutzer == null) return null;
    return TrueGlowNutzer(
      uid: nutzer.uid,
      anonym: nutzer.isAnonymous,
      email: nutzer.email,
      anzeigename: nutzer.displayName,
    );
  }

  /// Wartet auf den ersten Zustand von Firebase Auth.
  ///
  /// Firebase stellt eine gespeicherte Sitzung asynchron wieder her. Ohne
  /// dieses Warten wuerde der Router beim Start kurz „nicht angemeldet"
  /// sehen und auf den Login-Screen springen, obwohl das Konto gleich darauf
  /// da ist.
  static Future<void> sitzungAbwarten() async {
    await FirebaseAuth.instance.authStateChanges().first;
  }
}
