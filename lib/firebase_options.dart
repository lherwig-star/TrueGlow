// PLATZHALTER — diese Datei wird von der FlutterFire CLI erzeugt.
//
//   flutterfire configure --project=DEINE-PROJEKT-ID \
//       --platforms=android,ios --out=lib/firebase_options.dart
//
// Bis dahin stehen hier bewusst ungueltige Werte. Sie halten das Projekt
// kompilierbar (analyze und die Tests laufen ohne Firebase-Projekt durch),
// erlauben aber keine echte Verbindung: [FirebaseStart] erkennt den
// Platzhalter an der Projekt-ID und zeigt statt eines Absturzes einen
// Hinweis auf SETUP.md, Abschnitt 2.
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
