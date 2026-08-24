import '../../analysis/models/analysis_result.dart';
import '../models/checkin_auswertung.dart';

/// Das Ergebnis einer angewandten Anpassung: der neue Report plus die Habits,
/// die dabei dazugekommen sind (fuer die "Neu ab heute"-Markierung).
class AngepassterPlan {
  const AngepassterPlan({required this.ergebnis, required this.neueHabits});

  final AnalysisResult ergebnis;
  final Set<String> neueHabits;
}

/// Wendet die Vorschlaege der KI auf den Report an.
///
/// Minimal-invasiv: Nur die genannten Habits werden getauscht, ergaenzt oder
/// gestrichen. Alles andere – Sektionen, Einleitungen, Plan-Phasen – bleibt
/// unangetastet, damit ein Check-in nie den ganzen Report umschreibt.
AngepassterPlan planAnwenden(
  AnalysisResult ergebnis,
  List<HabitAnpassung> anpassungen,
) {
  if (anpassungen.isEmpty) {
    return AngepassterPlan(ergebnis: ergebnis, neueHabits: const {});
  }

  final neueHabits = <String>{};

  final kapitel = [
    for (final k in ergebnis.kapitel)
      () {
        final fuerKapitel =
            anpassungen.where((a) => a.modul == k.modul).toList();
        if (fuerKapitel.isEmpty) return k;

        var habits = List<String>.from(k.habits);

        for (final anpassung in fuerKapitel) {
          final index = habits.indexOf(anpassung.alt);

          if (anpassung.istNeuzugang) {
            if (!habits.contains(anpassung.neu)) {
              habits.add(anpassung.neu);
              neueHabits.add(anpassung.neu);
            }
            continue;
          }

          // Der alte Wortlaut muss passen – sonst wuerde eine erfundene Zeile
          // stillschweigend einen fremden Habit ueberschreiben.
          if (index < 0) continue;

          if (anpassung.istStreichung) {
            habits.removeAt(index);
            continue;
          }

          habits[index] = anpassung.neu;
          neueHabits.add(anpassung.neu);
        }

        return Kapitel(
          modul: k.modul,
          einleitung: k.einleitung,
          sektionen: k.sektionen,
          habits: habits,
        );
      }(),
  ];

  return AngepassterPlan(
    ergebnis: AnalysisResult(
      id: ergebnis.id,
      erstelltAm: ergebnis.erstelltAm,
      kapitel: kapitel,
      plan: ergebnis.plan,
      richtung: ergebnis.richtung,
    ),
    neueHabits: neueHabits,
  );
}
