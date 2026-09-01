import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/logic/analysis_repository.dart';
import '../../modules/logic/module_controller.dart';
import 'analysis_controller.dart';

/// Ob der laufende Analyse-Durchgang eine **Neuberechnung** ist: dieselben
/// Fotos, andere Richtung oder andere Techniken (DECISIONS 91).
///
/// **Warum ein Merker und kein Wegparameter.** Der Weg führt über
/// Modulauswahl, Richtung und „Das will ich ausprobieren"; erst am Ende
/// entscheidet sich, ob die Kamera kommt oder gleich gerechnet wird. Ein
/// Parameter müsste durch jede dieser Routen durchgereicht werden und an
/// jedem Weiter-Knopf mitgeschrieben — vier Stellen, an denen er vergessen
/// werden kann. Der Merker steht an einer.
///
/// **Er hält bewusst nur, solange der Flow läuft.** Nichts davon wird
/// gespeichert: Ein abgebrochener Durchgang soll den nächsten nicht
/// beeinflussen, und ein Neustart der App fängt ohnehin wieder vorn an. Der
/// reguläre Weg („Neue Analyse") setzt ihn zurück, und die Berechnung selbst
/// löscht ihn, sobald sie läuft.
final neuberechnungProvider = StateProvider<bool>((ref) => false);

/// Bereitet einen Durchgang mit den vorhandenen Fotos vor.
///
/// Zwei Unterschiede zur regulären neuen Analyse, und beide sind der ganze
/// Punkt: Die Aufnahmen bleiben stehen – kein `alleVerwerfen` –, und
/// vorbelegt sind die Bereiche des letzten Reports. Wer neu rechnet, will die
/// Richtung ändern und nicht von vorn anfangen.
///
/// Sie steht hier und nicht im Bildschirm, damit sie sich prüfen lässt, ohne
/// einen Knopf zu tippen: Der Bildschirm navigiert, diese Funktion entscheidet.
void neuberechnungVorbereiten(WidgetRef ref) {
  final letzte = ref.read(aktuelleAnalyseProvider);
  if (letzte != null) {
    ref.read(moduleControllerProvider.notifier).vorbereiten(letzte.module);
  }
  ref.read(analysisControllerProvider.notifier).zuruecksetzen();
  ref.read(neuberechnungProvider.notifier).state = true;
}
