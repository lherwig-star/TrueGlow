import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'analysis_service.dart';

/// Der reine Transport zur Gemini-API: ein Aufruf, ein Antworttext.
///
/// Bewusst ohne jedes Wissen ueber Analyse oder Check-in – beide schicken
/// System-Prompt, Nutzertext und optional Bilder und bekommen den Rohtext des
/// Modells zurueck. Fehler kommen als [AnalysisException] heraus, damit die
/// UI nur eine Fehlerwelt kennt.
class GeminiClient {
  GeminiClient({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKeyOverride = apiKey;

  final http.Client _client;
  final String? _apiKeyOverride;

  static const _basisUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Key aus der .env-Datei. Der Override existiert fuer Tests.
  String? get apiKey {
    if (_apiKeyOverride != null) return _apiKeyOverride;
    if (!dotenv.isInitialized) return null;
    final key = dotenv.env[AnalysisConfig.apiKeyName]?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  /// Ein Aufruf gegen die API. Liefert den reinen Antworttext des Modells.
  ///
  /// [bilder] sind base64-kodierte JPEGs in der Reihenfolge, in der sie im
  /// Nutzertext benannt werden.
  Future<String> frage({
    required String systemPrompt,
    required String nutzerText,
    List<String> bilder = const [],
  }) async {
    final key = apiKey;
    if (key == null) {
      throw const AnalysisException(AnalysisFehler.keinApiKey);
    }

    // Der Schluessel geht als Header raus, nicht als Query-Parameter – so
    // landet er nicht in Logs oder Proxy-Historien.
    final url = Uri.parse(
      '$_basisUrl/models/${AnalysisConfig.modell}:generateContent',
    );

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': nutzerText},
            for (final bild in bilder)
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': bild},
              },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'responseMimeType': 'application/json',
      },
    });

    http.Response antwort;
    try {
      antwort = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key,
            },
            body: body,
          )
          .timeout(AnalysisConfig.zeitlimit);
    } on TimeoutException {
      throw const AnalysisException(AnalysisFehler.zeitueberschreitung);
    } on SocketException catch (e) {
      throw AnalysisException(AnalysisFehler.keinInternet, e.message);
    } on http.ClientException catch (e) {
      throw AnalysisException(AnalysisFehler.keinInternet, e.message);
    }

    if (antwort.statusCode == 429) {
      throw const AnalysisException(AnalysisFehler.kontingent);
    }
    if (antwort.statusCode == 401 || antwort.statusCode == 403) {
      throw AnalysisException(
        AnalysisFehler.keinApiKey,
        'HTTP ${antwort.statusCode}',
      );
    }
    if (antwort.statusCode != 200) {
      throw AnalysisException(
        AnalysisFehler.apiFehler,
        'HTTP ${antwort.statusCode}',
      );
    }

    return _textAusAntwort(antwort.body);
  }

  /// Schaelt den Modelltext aus der Gemini-Antwortstruktur.
  String _textAusAntwort(String rohtext) {
    try {
      final json = jsonDecode(rohtext);
      if (json is! Map) return '';

      final kandidaten = json['candidates'];
      if (kandidaten is! List || kandidaten.isEmpty) {
        // Kommt vor, wenn der Sicherheitsfilter greift.
        throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
      }

      final teile = (kandidaten.first as Map)['content']?['parts'];
      if (teile is! List) return '';

      return teile
          .whereType<Map>()
          .map((t) => t['text'])
          .whereType<String>()
          .join();
    } on FormatException {
      return '';
    }
  }
}

/// Laedt eine Bilddatei als base64 – gemeinsame Vorstufe fuer alle Aufrufe
/// mit Bildern.
Future<String> base64Bild(File datei) async =>
    base64Encode(await datei.readAsBytes());
