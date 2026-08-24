import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Feste Werte des Backends. Sie stehen hier zusammen, damit ein Wechsel der
/// Region oder ein umbenannter Endpunkt genau eine Datei betrifft.
class FirebaseKonfig {
  FirebaseKonfig._();

  /// Region von Functions und Firestore. DSGVO-Vorgabe: Frankfurt.
  ///
  /// Muss mit `functions/src/index.ts` und dem Standort der
  /// Firestore-Datenbank uebereinstimmen.
  static const String region = 'europe-west3';

  /// Name der Analyse-Function.
  static const String functionAnalysiere = 'analysiere';

  /// Name der Check-in-Function.
  static const String functionCheckin = 'checkinAuswerten';
}

/// Wie der Start ausgegangen ist.
enum FirebaseStartStand {
  /// Firebase steht bereit.
  bereit,

  /// `flutterfire configure` wurde noch nicht ausgefuehrt.
  nichtKonfiguriert,

  /// Initialisierung ist fehlgeschlagen (falsche Konfiguration, kein Netz
  /// beim ersten Start, fehlende google-services.json).
  fehlgeschlagen,
}

/// Ergebnis von [FirebaseStart.init] – Stand plus Details fuer den Hinweis.
class FirebaseStartErgebnis {
  const FirebaseStartErgebnis(this.stand, [this.details]);

  final FirebaseStartStand stand;
  final String? details;

  bool get bereit => stand == FirebaseStartStand.bereit;
}

/// Startet Firebase und schaltet App Check scharf.
///
/// Bewusst ohne Ausnahme nach aussen: Ein fehlendes Firebase-Projekt ist beim
/// Aufsetzen der Normalfall und soll einen lesbaren Hinweis erzeugen, keinen
/// Absturz beim ersten Frame.
class FirebaseStart {
  FirebaseStart._();

  static Future<FirebaseStartErgebnis> init() async {
    final optionen = DefaultFirebaseOptions.currentPlatform;

    if (optionen.projectId == DefaultFirebaseOptions.platzhalterProjektId) {
      return const FirebaseStartErgebnis(
        FirebaseStartStand.nichtKonfiguriert,
      );
    }

    try {
      await Firebase.initializeApp(options: optionen);
    } catch (e) {
      debugPrint('Firebase-Start fehlgeschlagen: $e');
      return FirebaseStartErgebnis(FirebaseStartStand.fehlgeschlagen, '$e');
    }

    // App Check ist die Tuersteherin vor der Cloud Function. Ohne sie koennte
    // jemand mit einem abgegriffenen Auth-Token direkt auf unsere Rechnung
    // Gemini rufen.
    //
    // Im Debug-Build laeuft der Debug-Provider: Er druckt beim ersten Start
    // ein Token in die Konsole, das in der Firebase-Konsole freigeschaltet
    // wird (SETUP.md, Abschnitt 4.3).
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    } catch (e) {
      // Ohne App Check laeuft die App weiter – die Function lehnt den Aufruf
      // dann ab und die UI zeigt den bekannten API-Fehler. Ein harter Abbruch
      // hier wuerde auch den Offline-Teil der App unbenutzbar machen.
      debugPrint('App Check nicht aktiviert: $e');
    }

    // Offline-Cache: Der Plan, die Checklisten und die Historie bleiben ohne
    // Netz lesbar, Schreibvorgaenge laufen nach. Das ist die Firestore-Seite
    // der Sync-Strategie aus Phase 1.6.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    return const FirebaseStartErgebnis(FirebaseStartStand.bereit);
  }
}
