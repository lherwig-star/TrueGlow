// Erzeugt von der FlutterFire CLI - nicht von Hand bearbeiten:
//
//   flutterfire configure --project=trueglow-b2c1c \
//       --platforms=android,ios --out=lib/firebase_options.dart
//
// ACHTUNG: Hier stehen die ECHTEN Werte des Projekts trueglow-b2c1c, nicht
// mehr die Platzhalter. Der Kopf dieser Datei behauptete bis zum 03.09.2026
// das Gegenteil. Aufgefallen ist es beim Hochladen ins oeffentliche Repo -
// da wurde die Frage "was wird hier eigentlich sichtbar" zum ersten Mal
// gestellt.
//
// Die beiden `apiKey` sind keine Geheimnisse: Sie benennen das Projekt und
// stecken in jeder ausgelieferten App-Datei, aus der sie jeder auslesen
// kann. Der Schutz liegt bei den Firestore-Regeln und App Check
// (SECURITY_AUDIT A1, A3); zusaetzlich einschraenken lassen sie sich in der
// Google-Cloud-Konsole, siehe SETUP.md 16.8.
//
// [platzhalterProjektId] unten bleibt trotzdem stehen und wird weiter
// gebraucht: In einer frischen Arbeitskopie ohne `flutterfire configure`
// erkennt [FirebaseStart] daran, dass keine Konfiguration vorliegt, und
// zeigt statt eines Absturzes einen Hinweis auf SETUP.md, Abschnitt 2.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Standard-Firebase-Konfiguration je Plattform.
class DefaultFirebaseOptions {
  /// Projekt-ID der Platzhalter-Fassung. Steht absichtlich hier und nicht in
  /// [FirebaseStart]: So bleibt die Erkennung auch dann korrekt, wenn die
  /// FlutterFire CLI diese Datei ueberschreibt – dann stimmt die ID nicht
  /// mehr ueberein und die App gilt als konfiguriert.
  static const String platzhalterProjektId = 'trueglow-platzhalter';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'TrueGlow ist eine reine Mobil-App – Web ist nicht konfiguriert.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Fuer $defaultTargetPlatform gibt es keine Firebase-Konfiguration.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUbqiJfz9dM7xzXcpoayAc3CBlITv6vYA',
    appId: '1:732767304100:android:6ebbf8d8b1d52711b7e931',
    messagingSenderId: '732767304100',
    projectId: 'trueglow-b2c1c',
    storageBucket: 'trueglow-b2c1c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCe5yvWHXl2ABolQ33uIWqqblg24_YsXKo',
    appId: '1:732767304100:ios:ea3e3e17f2595ecdb7e931',
    messagingSenderId: '732767304100',
    projectId: 'trueglow-b2c1c',
    storageBucket: 'trueglow-b2c1c.firebasestorage.app',
    androidClientId: '732767304100-27sdgmvqi47bp8b1vgd13c1anfo7imel.apps.googleusercontent.com',
    iosClientId: '732767304100-kla0806tj9i6qo4qk10v141neuah3su2.apps.googleusercontent.com',
    iosBundleId: 'com.trueglow.app',
  );
}
