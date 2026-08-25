import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_start.dart';
import '../../../core/l10n/sprache.dart';
import '../../../core/l10n/texte.dart';
import '../../../core/netz/wiederholung.dart';
import '../../analysis/logic/analysis_service.dart';
import '../../analysis/logic/functions_client.dart';
import '../../analysis/models/analysis_result.dart';
import '../../modules/models/analyse_modul.dart';
import '../models/checkin.dart';
import '../models/checkin_auswertung.dart';
import 'checkin_anfrage.dart';

/// Wertet einen Check-in aus und liefert die Planaenderungen.
///
/// Eigenes Interface neben [AnalysisService]: Der Check-in schickt kein
/// Fotoset und bekommt keinen Report zurueck, sondern eine Handvoll gezielter
/// Aenderungen.
abstract interface class CheckinService {
  /// [erstfoto] und [fortschrittsfoto] gehen nur beim Wirkungs-Check mit.
  ///
  /// [abbruch] stoppt Warten und Wiederholen, wenn der Nutzer aufgibt.
  ///
  /// Wirft bei Problemen eine [AnalysisException].
  /// [sprache] bestimmt die Sprache der Auswertung – siehe
  /// [AnalysisService.analysiere].
  Future<CheckinAuswertung> auswerten({
    required Checkin checkin,
    required AnalysisResult analyse,
    required List<Checkin> historie,
    required Sprache sprache,
    File? erstfoto,
    File? fortschrittsfoto,
    Abbruch? abbruch,
  });
}

/// Auswertung ueber die eigene Cloud Function.
///
/// Wie bei der Analyse liegen Schluessel, Prompt, Kontingent und der zweite
/// Versuch bei unlesbarem JSON auf dem Server. Uebrig bleibt hier: Bilder
/// einsammeln, fragen, Antwort lesen.
class FunctionsCheckinService implements CheckinService {
  FunctionsCheckinService({FunctionsClient? client})
      : _client = client ?? FunctionsClient();

  final FunctionsClient _client;

  @override
  Future<CheckinAuswertung> auswerten({
    required Checkin checkin,
    required AnalysisResult analyse,
    required List<Checkin> historie,
    required Sprache sprache,
    File? erstfoto,
    File? fortschrittsfoto,
    Abbruch? abbruch,
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

    final antwort = await _client.rufe(
      FirebaseKonfig.functionCheckin,
      CheckinAnfrage.bauen(
        checkin: checkin,
        analyse: analyse,
        historie: historie,
        sprache: sprache,
        bilder: bilder,
      ),
      abbruch: abbruch,
    );

    final roh = antwort['auswertung'];
    if (roh is! Map) {
      throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
    }

    final auswertung =
        CheckinAuswertung.fromJson(Map<String, dynamic>.from(roh));
    // Eine Antwort ohne jeden Inhalt ist so unbrauchbar wie gar keine.
    if (auswertung.istLeer) {
      throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
    }

    return auswertung;
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
    required Sprache sprache,
    File? erstfoto,
    File? fortschrittsfoto,
    Abbruch? abbruch,
  }) async {
    await Future<void>.delayed(AnalysisConfig.mockDauer);
    if (abbruch?.istAusgeloest ?? false) throw const AbbruchException();

    // Die Attrappe schreibt selbst – also braucht sie die Texte in der
    // gewaehlten Sprache. `lookupL` statt eines BuildContext: Der Dienst ist
    // reine Logik und soll es bleiben.
    final texte = lookupL(sprache.locale);
    final anpassungen = <HabitAnpassung>[];

    for (final feedback in checkin.problemHabits) {
      final modul = _modulZu(analyse, feedback.habit);
      if (modul == null) continue;

      anpassungen.add(
        HabitAnpassung(
          modul: modul,
          alt: feedback.habit,
          neu: _leichtereVariante(feedback, texte),
          grund: switch (feedback.grund) {
            null => texte.mockGrundOhne,
            final grund => texte.mockGrundMit(grund.label(texte)),
          },
        ),
      );
    }

    final zusammenfassung = anpassungen.isEmpty
        ? texte.mockKeineAenderung
        : texte.mockAenderungen(anpassungen.length);

    return CheckinAuswertung(
      zusammenfassung: zusammenfassung,
      fazit: checkin.typ.mitFortschrittsfoto ? texte.mockFazit : '',
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
  static String _leichtereVariante(HabitFeedback feedback, L texte) {
    final kurz = feedback.habit.length > 34
        ? '${feedback.habit.substring(0, 34).trimRight()}…'
        : feedback.habit;

    return switch (feedback.grund) {
      PasstNichtGrund.zeit => texte.mockVarianteZeit(kurz),
      PasstNichtGrund.vergessen => texte.mockVarianteVergessen(kurz),
      PasstNichtGrund.unangenehm => texte.mockVarianteUnangenehm(kurz),
      PasstNichtGrund.teuer => texte.mockVarianteTeuer(kurz),
      PasstNichtGrund.anderer || null => texte.mockVarianteAnderer(kurz),
    };
  }
}

/// Waehlt Mock oder echten Anbieter – gesteuert ueber [AnalysisConfig].
final checkinServiceProvider = Provider<CheckinService>((ref) {
  if (AnalysisConfig.useMockData) return const MockCheckinService();
  return FunctionsCheckinService();
});
