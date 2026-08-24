import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analysis/logic/analysis_controller.dart';
import '../../features/capture/logic/capture_controller.dart';
import '../../features/consent/logic/einwilligung_controller.dart';
import '../../features/checkin/logic/checkin_controller.dart';
import '../../features/direction/logic/direction_controller.dart';
import '../../features/history/logic/analysis_repository.dart';
import '../../features/modules/logic/module_controller.dart';
import '../../features/onboarding/logic/onboarding_controller.dart';
import '../../features/plan/logic/plan_progress_repository.dart';
import '../storage/hive_service.dart';
import '../theme/theme_controller.dart';
import 'sync_dienst.dart';
import 'sync_store.dart';

/// Der Sync-Dienst der laufenden App.
///
/// Er sammelt die [SyncStore]s der vier Datenboxen. In Widget-Tests, die den
/// Speicher durch `MemoryStore` ersetzen, bleibt die Sammlung leer – der
/// Dienst ist dann folgenlos, und kein Test muss Firebase kennen.
final syncDienstProvider = Provider<SyncDienst>((ref) {
  final stores = <String, SyncStore>{};
  for (final name in HiveService.alleBoxen) {
    final store = ref.watch(storeProvider(name));
    if (store is SyncStore) stores[name] = store;
  }
  return SyncDienst(stores: stores);
});

/// Laedt alle Zustaende neu aus dem lokalen Speicher.
///
/// Wird nach einem Abgleich gebraucht: Der Sync schreibt an den Controllern
/// vorbei direkt in den Speicher, deshalb muessen sie danach einmal
/// nachlesen.
void zustaendeNeuLaden(WidgetRef ref) {
  ref.read(captureControllerProvider.notifier).neuLaden();
  ref.read(moduleControllerProvider.notifier).neuLaden();
  ref.read(directionControllerProvider.notifier).neuLaden();
  ref.read(checkinControllerProvider.notifier).neuLaden();
  ref.read(onboardingControllerProvider.notifier).neuLaden();
  ref.read(einwilligungControllerProvider.notifier).neuLaden();
  ref.read(analysenProvider.notifier).neuLaden();
  ref.read(planFortschrittProvider.notifier).neuLaden();
  ref.read(themeControllerProvider.notifier).neuLaden();
  ref.read(analysisControllerProvider.notifier).zuruecksetzen();
}
