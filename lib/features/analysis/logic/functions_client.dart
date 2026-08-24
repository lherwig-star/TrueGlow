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
  ///
  /// Uebersetzt jeden Fehler in die Fehlerwelt der Analyse. Fuer Aufrufe, die
  /// eigene Fehlerfaelle kennen (etwa die Kontoloeschung), gibt es
  /// [rufeRoh].
  Future<Map<String, dynamic>> rufe(
    String name,
    Map<String, dynamic> daten,
  ) async {
    try {
      return await rufeRoh(name, daten);
    } on FunctionsFehler catch (e) {
      throw AnalysisException(_fehler(e), '${e.code}: ${e.nachricht}');
    }
  }

  /// Derselbe Aufruf, aber mit unuebersetztem Fehler.
  ///
  /// Der Aufrufer bekommt Code und den Fall aus `details.fehler` und
  /// entscheidet selbst, was das fuer seine UI bedeutet.
  Future<Map<String, dynamic>> rufeRoh(
    String name,
    Map<String, dynamic> daten, {
    Duration? zeitlimit,
  }) async {
    try {
      final antwort = await _functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(
              timeout: zeitlimit ?? AnalysisConfig.zeitlimit,
            ),
          )
          .call<dynamic>(daten);

      final ergebnis = antwort.data;
      if (ergebnis is! Map) {
        throw const FunctionsFehler(
          code: 'internal',
          fall: 'ungueltigeAntwort',
        );
      }
      return Map<String, dynamic>.from(ergebnis);
    } on FirebaseFunctionsException catch (e) {
      throw FunctionsFehler(
        code: e.code,
        fall: _fall(e.details),
        nachricht: e.message,
      );
    } on TimeoutException {
      throw const FunctionsFehler(
        code: 'deadline-exceeded',
        fall: 'zeitueberschreitung',
      );
    } on SocketException catch (e) {
      throw FunctionsFehler(
        code: 'unavailable',
        fall: 'keinInternet',
        nachricht: e.message,
      );
    }
  }

  /// Der Fall, den die Function ausdruecklich mitschickt.
  static String? _fall(Object? details) =>
      details is Map && details['fehler'] is String
          ? details['fehler'] as String
          : null;

  /// Uebersetzt den Fehler der Function in den Fehlerfall der App.
  ///
  /// Die Function schickt ihren Fall ausdruecklich in `details.fehler` mit –
  /// nur wenn der fehlt (etwa weil der Aufruf gar nicht ankam), wird auf den
  /// gRPC-Code zurueckgefallen.
  static AnalysisFehler _fehler(FunctionsFehler e) {
    for (final fall in AnalysisFehler.values) {
      if (fall.name == e.fall) return fall;
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

/// Ein gescheiterter Function-Aufruf, bevor ihn jemand gedeutet hat.
class FunctionsFehler implements Exception {
  const FunctionsFehler({required this.code, this.fall, this.nachricht});

  /// Der gRPC-Code, etwa `unavailable` oder `failed-precondition`.
  final String code;

  /// Der Fall aus `details.fehler`, den die Function selbst benennt.
  final String? fall;

  final String? nachricht;

  @override
  String toString() => 'FunctionsFehler($code${fall == null ? '' : '/$fall'})';
}

/// Laedt eine Bilddatei als base64 – gemeinsame Vorstufe fuer alle Aufrufe
/// mit Bildern.
Future<String> base64Bild(File datei) async =>
    base64Encode(await datei.readAsBytes());
