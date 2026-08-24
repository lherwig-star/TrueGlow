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
  static const String platzhalterProjektId = 'glowup-platzhalter';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'GlowUp ist eine reine Mobil-App – Web ist nicht konfiguriert.',
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
    apiKey: 'PLATZHALTER-BITTE-FLUTTERFIRE-CONFIGURE-AUSFUEHREN',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: platzhalterProjektId,
    storageBucket: '$platzhalterProjektId.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLATZHALTER-BITTE-FLUTTERFIRE-CONFIGURE-AUSFUEHREN',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: platzhalterProjektId,
    storageBucket: '$platzhalterProjektId.firebasestorage.app',
    iosBundleId: 'com.glowup.glowup',
  );
}
