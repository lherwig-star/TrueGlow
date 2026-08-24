import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../capture/models/aufnahme_typ.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../models/analysis_result.dart';
import 'analysis_prompt.dart';
import 'analysis_service.dart';
import 'gemini_client.dart';
import 'json_extractor.dart';

/// Vision-Analyse ueber die Google-Gemini-API.
///
/// Fuer einen anderen Anbieter reicht eine weitere Implementierung von
/// [AnalysisService] – Prompt, Schema und UI bleiben unveraendert.
class GeminiAnalysisService implements AnalysisService {
  GeminiAnalysisService({http.Client? client, String? apiKey})
      : _gemini = GeminiClient(client: client, apiKey: apiKey);

  final GeminiClient _gemini;

  @override
  Future<AnalysisResult> analysiere({
    required Map<AufnahmeTyp, File> fotos,
    required Set<AnalyseModul> module,
    required OnboardingProfile onboarding,
    required ModulEingaben eingaben,
    Richtung richtung = Richtung.leer,
  }) async {
    if (_gemini.apiKey == null) {
      throw const AnalysisException(AnalysisFehler.keinApiKey);
    }
    if (fotos.isEmpty) {
      throw const AnalysisException(AnalysisFehler.fotosFehlen);
    }

    // Feste Reihenfolge, damit die Beschriftung im Prompt zu den angehaengten
    // Bildern passt.
    final reihenfolge = AufnahmeTyp.values.where(fotos.containsKey).toList();

    final bilder = <String>[];
    for (final typ in reihenfolge) {
      final datei = fotos[typ]!;
      if (!await datei.exists()) {
        throw const AnalysisException(AnalysisFehler.fotosFehlen);
      }
      bilder.add(await base64Bild(datei));
    }

    final systemPrompt = AnalysisPrompt.system(
      profil: onboarding,
      module: module,
      eingaben: eingaben,
      richtung: richtung,
    );
    final nutzerText = AnalysisPrompt.nutzer(reihenfolge);

    // Erster Versuch.
    final antwort = await _gemini.frage(
      systemPrompt: systemPrompt,
      nutzerText: nutzerText,
      bilder: bilder,
    );

    final ergebnis = _lies(antwort, richtung);
    if (ergebnis != null) return ergebnis;

    // Zweiter Versuch mit ausdruecklichem Hinweis auf valides JSON.
    debugPrint('Analyse: erste Antwort nicht lesbar, versuche es erneut.');
    final zweiteAntwort = await _gemini.frage(
      systemPrompt: systemPrompt,
      nutzerText: '$nutzerText\n\n${AnalysisPrompt.jsonNachfassen}',
      bilder: bilder,
    );

    final zweitesErgebnis = _lies(zweiteAntwort, richtung);
    if (zweitesErgebnis != null) return zweitesErgebnis;

    throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
  }

  /// Baut die Antwort in ein [AnalysisResult] um – oder null, wenn das JSON
  /// fehlt oder inhaltlich unbrauchbar ist.
  AnalysisResult? _lies(String rohtext, Richtung richtung) {
    final json = JsonExtractor.extrahiere(rohtext);
    if (json == null) return null;

    final ergebnis = AnalysisResult.vonApi(
      json,
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      erstelltAm: DateTime.now(),
      richtung: richtung,
    );

    return ergebnis.istVollstaendig ? ergebnis : null;
  }
}
