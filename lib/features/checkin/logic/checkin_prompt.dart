import '../../analysis/models/analysis_result.dart';
import '../../direction/models/richtung.dart';
import '../models/checkin.dart';

/// Baut den Prompt, mit dem die KI einen Check-in auswertet und den Plan
/// nachjustiert.
///
/// Wie beim Analyse-Prompt bewusst isoliert: Hier steht die inhaltliche
/// Leitplanke, dass nur nachgebessert und nicht neu geschrieben wird.
class CheckinPrompt {
  CheckinPrompt._();

  static String system({
    required Checkin checkin,
    required AnalysisResult analyse,
    required List<Checkin> historie,
    bool mitFotos = false,
  }) {
    return '''
Du bist derselbe Styling- und Grooming-Coach, der den Plan dieser Person
erstellt hat. Sie meldet sich zum ${checkin.typ.titel} zurück.

${_planUeberblick(analyse)}
${_richtung(analyse.richtung)}
${_antworten(checkin)}
${_historie(historie)}
${mitFotos ? _fotoHinweis() : ''}
Deine Aufgabe: den bestehenden Plan minimal-invasiv nachjustieren.

Verbindliche Regeln:
- Ändere NUR das, was der Nutzer bemängelt hat. Alles andere bleibt exakt so
  stehen – kein Umschreiben des ganzen Plans, keine kosmetischen Umformulierungen.
- Ein Habit mit "Passt nicht" wird ersetzt, vereinfacht oder seltener gemacht,
  passend zum genannten Grund.
- Ein Habit mit "Geht so" bleibt bestehen; nur wenn ein Grund genannt wurde,
  darfst du ihn leichter machen.
- Ein Habit mit "Läuft gut" bleibt unverändert. Beim Wirkungs-Check darfst du
  dafür EINE nächste Stufe vorschlagen, wenn sie sinnvoll ist.
- Streiche nie ersatzlos, wenn der Zweck des Habits noch gebraucht wird –
  such lieber eine leichtere Variante.
- Höchstens $_maxAnpassungen Änderungen insgesamt.
- Vergib keine Noten, Punkte oder Vergleiche. Bewertet werden Aufgaben, nie
  die Person.
- Keine medizinischen Diagnosen; bei Auffälligkeiten freundlich an eine
  Fachpraxis verweisen.
- Deutsch, per Du, warm und sachlich.

Antworte AUSSCHLIESSLICH mit einem JSON-Objekt nach diesem Schema. Kein
Fließtext davor oder danach, keine Markdown-Codefences:

{
  "zusammenfassung": "1-2 Sätze: was wir anpassen und warum",
  "fazit": "${_fazitVorgabe(checkin)}",
  "anpassungen": [
    {
      "modul": "basis",
      "alt": "der bisherige Habit im exakten Wortlaut",
      "neu": "der neue Habit, unter 60 Zeichen",
      "grund": "ein kurzer Satz für den Nutzer"
    }
  ]
}

Vorgaben zum Inhalt:
- "modul" ist exakt einer der oben genannten Bezeichner.
- "alt" muss WORTGLEICH einem bestehenden Habit entsprechen, sonst greift die
  Änderung nicht. Für einen zusätzlichen Habit "alt" leer lassen, für eine
  Streichung "neu" leer lassen.
- "neu" ist eine konkrete, täglich abhakbare Aufgabe unter 60 Zeichen und
  gehört inhaltlich zum selben Modul wie "alt".
- Gibt es nichts zu ändern, ist "anpassungen" eine leere Liste und
  "zusammenfassung" sagt freundlich, dass der Plan so bleibt.
${checkin.typ.mitFortschrittsfoto ? '' : '- "fazit" bleibt ein leerer String.'}
''';
  }

  /// Hoechstzahl der Aenderungen pro Check-in.
  static const _maxAnpassungen = 4;

  static String _fazitVorgabe(Checkin checkin) => checkin.typ.mitFortschrittsfoto
      ? '2-4 Sätze Zwischenfazit: was sich verändert hat, was gut läuft, '
          'was wir nachschärfen'
      : '';

  static String nutzer(Checkin checkin, {bool mitFotos = false}) {
    final bilder = mitFotos
        ? '\n\nDie Bilder sind: 1. das Foto der Erstanalyse, 2. das heutige '
            'Fortschrittsfoto. Vergleiche sie sachlich und ohne '
            'Attraktivitätsurteil.'
        : '';

    return 'Hier ist mein ${checkin.typ.titel}. Bitte passe meinen Plan an '
        'und antworte im vorgegebenen JSON-Schema.$bilder';
  }

  /// Nachfassen, wenn die erste Antwort kein gueltiges JSON war.
  static const String jsonNachfassen =
      'Deine letzte Antwort war kein gültiges JSON. Antworte nur mit validem '
      'JSON nach dem vorgegebenen Schema – ohne Erklärung, ohne Markdown-'
      'Codefences.';

  /// Der aktuelle Plan, gegliedert nach Kapiteln – nur die Habits, denn nur
  /// die werden angepasst.
  static String _planUeberblick(AnalysisResult analyse) {
    final zeilen = <String>[];
    for (final kapitel in analyse.kapitel) {
      zeilen.add('- Modul "${kapitel.modul.name}" (${kapitel.titel}):');
      for (final habit in kapitel.habits) {
        zeilen.add('  * $habit');
      }
    }

    if (zeilen.isEmpty) return 'Der Plan enthält aktuell keine Tagesaufgaben.';
    return 'Aktuelle Tagesaufgaben:\n${zeilen.join('\n')}';
  }

  static String _richtung(Richtung richtung) {
    if (richtung.istLeer) return '';

    final teile = <String>[];
    if (richtung.ziele.isNotEmpty) {
      teile.add(richtung.sortierteZiele.map((z) => z.label).join(', '));
    }
    if (richtung.freitext.trim().isNotEmpty) {
      teile.add('in eigenen Worten: "${richtung.freitext.trim()}"');
    }

    return '\nDie Person verfolgt weiterhin diese Richtung: '
        '${teile.join(' – ')}\n';
  }

  /// Die Antworten dieses Check-ins.
  static String _antworten(Checkin checkin) {
    final zeilen = <String>[];

    for (final feedback in checkin.habits) {
      final grund = feedback.grund;
      final zusatz = switch (grund) {
        null => '',
        final g => ' – Grund: ${g.label} (${g.anweisung})',
      };
      final notiz = feedback.notiz.trim().isEmpty
          ? ''
          : ' – Anmerkung: "${feedback.notiz.trim()}"';
      zeilen.add(
        '- "${feedback.habit}": ${feedback.bewertung.label}$zusatz$notiz',
      );
    }

    if (checkin.wirkung.isNotEmpty) {
      zeilen.add('Wirkung aus Sicht der Person:');
      for (final w in checkin.wirkung) {
        final notiz =
            w.notiz.trim().isEmpty ? '' : ' – "${w.notiz.trim()}"';
        zeilen.add('- ${w.frage} ${w.antwort.label}$notiz');
      }
    }

    if (zeilen.isEmpty) return 'Es liegen keine Antworten vor.';
    return '\nAntworten aus diesem Check-in:\n${zeilen.join('\n')}\n';
  }

  /// Verdichtete Feedback-Historie: Was frueher schon bemaengelt wurde, darf
  /// nicht erneut in derselben Form vorgeschlagen werden.
  static String _historie(List<Checkin> historie) {
    if (historie.isEmpty) return '';

    final zeilen = <String>[];
    for (final eintrag in historie) {
      final datum = eintrag.erledigtAm ?? eintrag.faelligAm;
      final probleme = eintrag.problemHabits
          .map((h) => '"${h.habit}" (${h.grund?.label ?? 'ohne Grund'})')
          .join(', ');
      zeilen.add(
        '- ${_datum(datum)}, ${eintrag.typ.titel}: '
        '${probleme.isEmpty ? 'nichts bemängelt' : 'passte nicht: $probleme'}',
      );
    }

    return '\nFrühere Check-ins:\n${zeilen.join('\n')}\n'
        'Schlage nichts vor, was schon einmal als unpassend gemeldet wurde.\n';
  }

  static String _fotoHinweis() =>
      '\nZu diesem Check-in liegen zwei Fotos vor: das Foto der Erstanalyse '
      'und ein heutiges Fortschrittsfoto unter denselben Bedingungen. Nutze '
      'sie für das Zwischenfazit – beschreibe Veränderungen sachlich, ohne '
      'Bewertung der Attraktivität und ohne Gewichtsurteil.\n';

  static String _datum(DateTime tag) =>
      '${tag.day.toString().padLeft(2, '0')}.'
      '${tag.month.toString().padLeft(2, '0')}.${tag.year}';
}
