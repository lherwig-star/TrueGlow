import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/firebase/firebase_start.dart';
import 'analysis_service.dart';

/// Der Transport zu den eigenen Cloud Functions.
///
/// Nachfolger des `GeminiClient`: Der Gemini-Schluessel liegt jetzt im Secret
/// Manager und die App spricht nur noch mit dem eigenen Backend. Damit kennt
/// der Client weder den Schluessel noch den Prompt – beides ist aus einem APK
/// nicht mehr herauszuholen.
///
/// Wie beim Vorgaenger kommt alles als [AnalysisException] heraus, damit die
/// UI nur eine Fehlerwelt kennt.
class FunctionsClient {
  FunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: FirebaseKonfig.region);

  final FirebaseFunctions _functions;

  /// Ruft die Function und gibt ihre Antwort als Map zurueck.
  Future<Map<String, dynamic>> rufe(
    String name,
    Map<String, dynamic> daten,
  ) async {
    try {
      final antwort = await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: AnalysisConfig.zeitlimit),
          )
          .call<dynamic>(daten);

      final ergebnis = antwort.data;
      if (ergebnis is! Map) {
        throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
      }
      return Map<String, dynamic>.from(ergebnis);
    } on FirebaseFunctionsException catch (e) {
      throw AnalysisException(_fehler(e), '${e.code}: ${e.message}');
    } on TimeoutException {
      throw const AnalysisException(AnalysisFehler.zeitueberschreitung);
    } on SocketException catch (e) {
      throw AnalysisException(AnalysisFehler.keinInternet, e.message);
    }
  }

  /// Uebersetzt den Fehler der Function in den Fehlerfall der App.
  ///
  /// Die Function schickt ihren Fall ausdruecklich in `details.fehler` mit –
  /// nur wenn der fehlt (etwa weil der Aufruf gar nicht ankam), wird auf den
  /// gRPC-Code zurueckgefallen.
  static AnalysisFehler _fehler(FirebaseFunctionsException e) {
    final details = e.details;
    if (details is Map) {
      final name = details['fehler'];
      for (final fall in AnalysisFehler.values) {
        if (fall.name == name) return fall;
      }
    }

    return switch (e.code) {
      'unavailable' => AnalysisFehler.keinInternet,
      'deadline-exceeded' => AnalysisFehler.zeitueberschreitung,
      'resource-exhausted' => AnalysisFehler.kontingent,
      // 'unauthenticated' deckt beides ab: fehlende Anmeldung und ein
      // abgelehntes App-Check-Token.
      _ => AnalysisFehler.apiFehler,
    };
  }
}

/// Laedt eine Bilddatei als base64 – gemeinsame Vorstufe fuer alle Aufrufe
/// mit Bildern.
Future<String> base64Bild(File datei) async =>
    base64Encode(await datei.readAsBytes());
