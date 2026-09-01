import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/sprache.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../analysis/logic/analysis_controller.dart';
import '../../analysis/logic/neuberechnung.dart';
import '../../auth/logic/auth_repository.dart';
import '../../capture/logic/capture_controller.dart';
import '../../checkin/logic/checkin_controller.dart';
import '../../checkin/logic/checkin_benachrichtigung.dart';
import '../../consent/logic/einwilligung_controller.dart';
import '../../direction/logic/direction_controller.dart';
import '../../history/logic/analysis_repository.dart';
import '../../analysis/logic/modus_controller.dart';
import '../../modules/logic/module_controller.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../../plan/logic/plan_progress_repository.dart';
import '../../result/logic/plan_erzeugt.dart';
import '../../streak/logic/erinnerung_einstellung.dart';
import '../../streak/logic/tages_erinnerung.dart';

/// Räumt auf, nachdem die Cloud-Löschung durchgegangen ist.
///
/// **Warum das nicht mehr im Bildschirm steht (DECISIONS 93).** Es stand
/// dort, als eine Kette von zwei Dutzend `ref.read` hinter mehreren `await`.
/// Am 01.09.2026 hat genau das die Kontolöschung halb erledigt liegen
/// lassen: Der Server meldete `Loeschung abgeschlossen (konto)`, und einen
/// Wimpernschlag später stand im Geräteprotokoll
///
///     StateError: Cannot use "ref" after the widget was disposed.
///     #2 SettingsScreen._loeschen (settings_screen.dart:218)
///
/// Der Einstellungs-Bildschirm war während des Aufräumens verschwunden — und
/// mit ihm alles, was danach kam: das Abmelden, der Weg zurück zur Anmeldung.
/// Zurück blieb eine App, die auf ein Konto zeigte, das es nicht mehr gab.
///
/// Der `Ref` eines Providers lebt am Container und nicht an einem Widget. Was
/// hier drinsteht, läuft deshalb zu Ende, auch wenn der Bildschirm mitten im
/// Ablauf zumacht.
final aufraeumenNachLoeschenProvider =
    Provider<Future<void> Function({required bool kontoWeg})>((ref) {
  return ({required bool kontoWeg}) async {
    await ref.read(alleDatenLoeschenProvider)();
    await ref.read(imageQualityServiceProvider).fotosLoeschen();

    // Alle Zustaende zuruecksetzen, damit nichts Altes im Speicher bleibt.
    ref.read(captureControllerProvider.notifier).alleVerwerfen();
    ref.read(moduleControllerProvider.notifier).zuruecksetzen();
    ref.read(modusControllerProvider.notifier).zuruecksetzen();
    ref.read(directionControllerProvider.notifier).zuruecksetzen();
    ref.read(checkinControllerProvider.notifier).zuruecksetzen();
    await ref.read(checkinBenachrichtigungProvider).abbrechen();
    ref.read(analysisControllerProvider.notifier).zuruecksetzen();
    ref.read(neuberechnungProvider.notifier).state = false;
    ref.read(analysenProvider.notifier).neuLaden();
    ref.read(planFortschrittProvider.notifier).neuLaden();
    ref.read(onboardingControllerProvider.notifier).zuruecksetzen();
    ref.read(einwilligungControllerProvider.notifier).zuruecksetzen();
    ref.read(planErzeugtProvider.notifier).neuLaden();
    // Theme und Sprache liegen in derselben Box und wurden mitgeloescht.
    ref.read(themeControllerProvider.notifier).neuLaden();
    ref.read(sprachControllerProvider.notifier).neuLaden();
    ref.read(erinnerungProvider.notifier).neuLaden();
    await ref.read(tagesErinnerungProvider).abbrechen();

    if (!kontoWeg) return;

    // Das Abmelden steht ganz am Ende und in einem eigenen `try`: Ist das
    // Konto auf dem Server schon weg, kann auch das Abmelden stolpern — und
    // dann wäre der Nutzer in einer App gefangen, die auf ein totes Konto
    // zeigt. Lieber ein stiller Fehler hier als ein Bildschirm, aus dem es
    // keinen Weg heraus gibt.
    try {
      await ref.read(authRepositoryProvider).abmelden();
    } catch (_) {
      // Der Weg zur Anmeldung wird trotzdem gegangen.
    }
  };
});
