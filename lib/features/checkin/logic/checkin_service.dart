import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analysis/logic/analysis_service.dart';
import '../../analysis/logic/gemini_client.dart';
import '../../analysis/logic/json_extractor.dart';
import '../../analysis/models/analysis_result.dart';
import '../../modules/models/analyse_modul.dart';
import '../models/checkin.dart';
import '../models/checkin_auswertung.dart';
import 'checkin_prompt.dart';

/// Wertet einen Check-in aus und liefert die Planaenderungen.
///
/// Eigenes Interface neben [AnalysisService]: Der Check-in schickt kein
/// Fotoset und bekommt keinen Report zurueck, sondern eine Handvoll gezielter
/// Aenderungen.
abstract interface class CheckinService {
  /// [erstfoto] und [fortschrittsfoto] gehen nur beim Wirkungs-Check mit.
  ///
  /// Wirft bei Problemen eine [AnalysisException].
  Future<CheckinAuswertung> auswerten({
    required Checkin checkin,
    required AnalysisResult analyse,
    required List<Checkin> historie,
    File? erstfoto,
    File? fortschrittsfoto,
  });
}

/// Auswertung ueber die Gemini-API.
class GeminiCheckinService implements CheckinService {
  GeminiCheckinService({GeminiClient? client})
      : _gemini = client ?? GeminiClient();

  final GeminiClient _gemini;

  @override
  Future<CheckinAuswertung> auswerten({
    required Checkin checkin,
    required AnalysisResult analyse,
    required List<Checkin> historie,
    File? erstfoto,
    File? fortschrittsfoto,
  }) async {
    // Der Vergleich braucht beide Bilder; fehlt eines, laeuft der Check-in
    // ohne Fotos weiter statt zu scheitern.
    final beide = erstfoto != null &&
        fortschrittsfoto != null &&
        await erstfoto.exists() &&
        await fortschrittsfoto.exists();

    final bilder = beide
        ? [await base64Bild(erstfoto), await base64Bild(fortschrittsfoto)]
        : const <String>[];

    final systemPrompt = CheckinPrompt.system(
      checkin: checkin,
      analyse: analyse,
      historie: historie,
      mitFotos: beide,
    );
    final nutzerText = CheckinPrompt.nutzer(checkin, mitFotos: beide);

    final antwort = await _gemini.frage(
      systemPrompt: systemPrompt,
      nutzerText: nutzerText,
      bilder: bilder,
    );

    final auswertung = _lies(antwort);
    if (auswertung != null) return auswertung;

    debugPrint('Check-in: erste Antwort nicht lesbar, versuche es erneut.');
    final zweite = await _gemini.frage(
      systemPrompt: systemPrompt,
      nutzerText: '$nutzerText\n\n${CheckinPrompt.jsonNachfassen}',
      bilder: bilder,
    );

    final zweiteAuswertung = _lies(zweite);
    if (zweiteAuswertung != null) return zweiteAuswertung;

    throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
  }

  CheckinAuswertung? _lies(String rohtext) {
    final json = JsonExtractor.extrahiere(rohtext);
    if (json == null) return null;

    final auswertung = CheckinAuswertung.fromJson(json);
    // Eine Antwort ohne jeden Inhalt ist so unbrauchbar wie gar keine.
    return auswertung.istLeer ? null : auswertung;
  }
}

/// Auswertung ohne Netz: baut die Aenderungen aus den Antworten selbst.
///
/// Der Mock ist bewusst mehr als ein fester Text – er befolgt dieselben
/// Regeln wie die KI (nur Bemaengeltes anfassen, Grund beruecksichtigen), so
/// dass sich der ganze Ablauf inklusive Bestaetigung ohne Key testen laesst.
class MockCheckinService implements CheckinService {
  const MockCheckinService();

  @override
  Future<CheckinAuswertung> auswerten({
    required Checkin checkin,
    required AnalysisResult analyse,
    required List<Checkin> historie,
    File? erstfoto,
    File? fortschrittsfoto,
  }) async {
    await Future<void>.delayed(AnalysisConfig.mockDauer);

    final anpassungen = <HabitAnpassung>[];

    for (final feedback in checkin.problemHabits) {
      final modul = _modulZu(analyse, feedback.habit);
      if (modul == null) continue;

      anpassungen.add(
        HabitAnpassung(
          modul: modul,
          alt: feedback.habit,
          neu: _leichtereVariante(feedback),
          grund: switch (feedback.grund) {
            null => 'Passt so nicht in deinen Alltag.',
            final grund => '${grund.label} – wir machen es dir leichter.',
          },
        ),
      );
    }

    final zusammenfassung = anpassungen.isEmpty
        ? 'Dein Plan bleibt, wie er ist – das läuft gut so.'
        : 'Das passen wir an: ${anpassungen.length} '
            '${anpassungen.length == 1 ? 'Aufgabe' : 'Aufgaben'}, die nicht in '
            'deinen Alltag gepasst haben.';

    return CheckinAuswertung(
      zusammenfassung: zusammenfassung,
      fazit: checkin.typ.mitFortschrittsfoto
          ? 'Im Vergleich zum Startfoto wirkt die Pflege insgesamt '
              'gleichmäßiger. Bleib bei den Aufgaben, die dir leichtfallen – '
              'die zwei angepassten Punkte nehmen dir Zeit ab.'
          : '',
      anpassungen: anpassungen,
    );
  }

  /// In welchem Kapitel der Habit steht.
  static AnalyseModul? _modulZu(AnalysisResult analyse, String habit) {
    for (final kapitel in analyse.kapitel) {
      if (kapitel.habits.contains(habit)) return kapitel.modul;
    }
    return null;
  }

  /// Eine leichtere Fassung, passend zum genannten Grund.
  static String _leichtereVariante(HabitFeedback feedback) {
    final kurz = feedback.habit.length > 34
        ? '${feedback.habit.substring(0, 34).trimRight()}…'
        : feedback.habit;

    return switch (feedback.grund) {
      PasstNichtGrund.zeit => '$kurz – nur 30 Sekunden',
      PasstNichtGrund.vergessen => '$kurz – direkt nach dem Zähneputzen',
      PasstNichtGrund.unangenehm => '$kurz – in der leichten Variante',
      PasstNichtGrund.teuer => '$kurz – mit günstiger Alternative',
      PasstNichtGrund.anderer || null => '$kurz – jeden zweiten Tag',
    };
  }
}

/// Waehlt Mock oder echten Anbieter – gesteuert ueber [AnalysisConfig].
final checkinServiceProvider = Provider<CheckinService>((ref) {
  if (AnalysisConfig.useMockData) return const MockCheckinService();
  return GeminiCheckinService();
});
