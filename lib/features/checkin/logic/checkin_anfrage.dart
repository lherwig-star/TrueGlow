import '../../../core/l10n/sprache.dart';
import '../../analysis/models/analysis_result.dart';
import '../models/checkin.dart';

/// Baut die Nutzlast fuer die Cloud Function `checkinAuswerten`.
///
/// Wie bei der Analyse gilt: Der Prompt liegt auf dem Server, hier steht nur,
/// welche Angaben das Geraet verlassen.
///
/// Der Pfad des Fortschrittsfotos gehoert ausdruecklich **nicht** dazu. Er
/// steht im [Checkin]-Modell und wuerde ueber `toJson()` mitfahren – deshalb
/// wird die Nutzlast hier Feld fuer Feld gebaut statt durchgereicht. Das Bild
/// selbst geht getrennt als base64 mit und wird serverseitig verworfen.
class CheckinAnfrage {
  CheckinAnfrage._();

  static Map<String, dynamic> bauen({
    required Checkin checkin,
    required AnalysisResult analyse,
    required List<Checkin> historie,
    required Sprache sprache,
    List<String> bilder = const [],
  }) {
    return {
      'sprache': sprache.code,
      'checkin': {
        'typ': checkin.typ.name,
        'habits': [
          for (final feedback in checkin.habits)
            {
              'habit': feedback.habit,
              'bewertung': feedback.bewertung.name,
              'grund': feedback.grund?.name,
              'notiz': feedback.notiz,
            },
        ],
        'wirkung': [
          for (final w in checkin.wirkung)
            {'frage': w.frage, 'antwort': w.antwort.name, 'notiz': w.notiz},
        ],
      },
      'plan': [
        for (final kapitel in analyse.kapitel)
          {'modul': kapitel.modul.name, 'habits': kapitel.habits},
      ],
      'richtung': analyse.richtung.toJson(),
      'historie': [
        for (final eintrag in historie)
          {
            'datum': (eintrag.erledigtAm ?? eintrag.faelligAm)
                .toIso8601String(),
            'typ': eintrag.typ.name,
            'probleme': [
              for (final problem in eintrag.problemHabits)
                {'habit': problem.habit, 'grund': problem.grund?.name},
            ],
          },
      ],
      'bilder': bilder,
    };
  }
}
