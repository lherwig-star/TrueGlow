import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/sprache.dart';
import '../../history/logic/analysis_repository.dart';
import '../../plan/logic/plan_progress_repository.dart';
import 'erinnerung_einstellung.dart';
import 'tages_erinnerung.dart';

/// Hält die geplanten Erinnerungen auf dem aktuellen Stand.
///
/// Vier Dinge entscheiden, ob und wann erinnert wird: die Einstellung, ob es
/// überhaupt einen Plan gibt, ob heute schon abgehakt wurde, und die Sprache
/// des Textes. Ändert sich eines davon, muss neu geplant werden.
///
/// Das steht hier an einer Stelle und nicht verteilt an den vier Auslösern.
/// Verteilt hieße: Wer später einen fünften hinzufügt, muss von allen vier
/// wissen – und der Fehler, den man dann macht, ist eine Erinnerung, die
/// nicht kommt. Der fällt niemandem auf.
class ErinnerungPlaner {
  ErinnerungPlaner(this._ref);

  final Ref _ref;

  /// Liest den aktuellen Stand und plant danach.
  Future<void> aktualisieren() async {
    final analyse = _ref.read(aktuelleAnalyseProvider);
    final fortschritt = _ref.read(planFortschrittProvider);

    await _ref.read(tagesErinnerungProvider).planen(
          einstellung: _ref.read(erinnerungProvider),
          hatPlan: analyse != null && analyse.alleHabits.isNotEmpty,
          heuteErledigt: fortschritt.erledigt.isNotEmpty,
        );
  }

  /// Fragt beim allerersten Mal nach der Systemberechtigung.
  ///
  /// Danach nie wieder: Wer abgelehnt hat, hat geantwortet. Eine zweite Frage
  /// beim nächsten Start wäre Drängeln. Wieder einschalten geht in den
  /// Einstellungen.
  Future<void> erstmaligFragen() async {
    final ctrl = _ref.read(erinnerungProvider.notifier);
    if (ctrl.schonGefragt) return;

    await ctrl.alsGefragtMerken();
    final erteilt = await _ref.read(tagesErinnerungProvider).berechtigungAnfragen();

    // Die Ablehnung schaltet die Einstellung mit ab. Sonst stünde in den
    // Einstellungen ein Schalter auf „an", während nichts passiert – und
    // niemand käme auf die Idee, dass die Berechtigung fehlt.
    if (!erteilt) await ctrl.anAus(false);
  }
}

final erinnerungPlanerProvider = Provider<ErinnerungPlaner>((ref) {
  final planer = ErinnerungPlaner(ref);

  // Die vier Auslöser. Sie stehen zusammen, damit man sie zusammen sieht.
  ref.listen(erinnerungProvider, (_, _) => planer.aktualisieren());
  ref.listen(planFortschrittProvider, (_, _) => planer.aktualisieren());
  ref.listen(analysenProvider, (_, _) => planer.aktualisieren());
  ref.listen(aktiveSpracheProvider, (_, _) => planer.aktualisieren());

  return planer;
});
