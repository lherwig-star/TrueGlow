import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trueglow/core/storage/hive_service.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/auth/logic/auth_repository.dart';
import 'package:trueglow/features/checkin/logic/checkin_service.dart';
import 'package:trueglow/features/consent/logic/einwilligung_controller.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/main.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Richtet Hive fuer einen Test in einem temporaeren Verzeichnis ein und
/// raeumt danach wieder auf. In jedem Test aufrufen, der Provider benutzt,
/// die auf Boxen zugreifen.
void hiveImTest() {
  late Directory verzeichnis;

  setUp(() async {
    verzeichnis = await Directory.systemTemp.createTemp('trueglow_test');
    Hive.init(verzeichnis.path);
    // Alle Boxen aus der Liste – so faellt eine neue Box hier nicht durchs
    // Raster, wenn sie in HiveService dazukommt. Die Sync-Box mit den
    // Zeitstempeln gehoert dazu.
    await Future.wait(HiveService.alleBoxenMitSync.map(Hive.openBox<dynamic>));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (verzeichnis.existsSync()) {
      verzeichnis.deleteSync(recursive: true);
    }
  });
}

/// Der Sucher und die Ergebnis-Karten sind hoch – im Standard-Testfenster
/// (800x600) liegt vieles ausserhalb der ListView und wird nicht gebaut.
void handyGroesse(WidgetTester tester, {double hoehe = 1400}) {
  tester.view.physicalSize = Size(400, hoehe);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Speicher-Overrides fuer Widget-Tests: ersetzt Hive durch einen
/// In-Memory-Store. Ohne das haengen Widget-Tests, sobald ein Controller
/// schreibt – Hives Datei-I/O kommt unter der gefakten Testuhr nie zurueck.
List<Override> speicherOverrides() => [
      for (final name in HiveService.alleBoxenMitSync)
        storeProvider(name).overrideWithValue(MemoryStore()),
    ];

/// Analyse und Check-in als Attrappe.
///
/// Seit dem Proxy-Umbau steht `AnalysisConfig.useMockData` standardmaessig auf
/// `false`; ohne diese Overrides wuerde ein Widget-Test versuchen, eine Cloud
/// Function zu rufen. Der Override macht ausserdem sichtbar, womit der Test
/// tatsaechlich laeuft – ein global richtig stehender Schalter waere Zufall.
List<Override> dienstOverrides() => [
      analysisServiceProvider.overrideWithValue(const MockAnalysisService()),
      checkinServiceProvider.overrideWithValue(const MockCheckinService()),
      // Standardmaessig angemeldet: Der Router laesst sonst niemanden am
      // Login-Screen vorbei, und die bestehenden Tests pruefen die Screens
      // dahinter.
      authRepositoryProvider.overrideWithValue(FakeAuthRepository.angemeldet()),
    ];

/// Speicher plus Dienste – der Standardsatz fuer Widget-Tests.
List<Override> testOverrides() => [...speicherOverrides(), ...dienstOverrides()];

/// Startet die App mit abgeschlossenem Onboarding und angemeldetem Konto –
/// der Zustand, in dem die eigentlichen Screens erreichbar sind.
Future<ProviderContainer> appMitDashboard(
  WidgetTester tester, {
  List<Override> zusatz = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...testOverrides(), ...zusatz],
      child: const TrueGlowApp(),
    ),
  );
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(TrueGlowApp)),
  );

  final onboarding = container.read(onboardingControllerProvider.notifier);
  onboarding.setAlter(Altersbereich.a25bis34);
  onboarding.setBudget(Budget.mittel);
  onboarding.setZeit(Zeitbudget.mittel);
  onboarding.toggleFokus(Fokusbereich.haut);
  onboarding.setZustimmung(true);
  onboarding.abschliessen();
  einwilligungErteilen(container);

  return container;
}

/// Erteilt beide Einwilligungen – der Zustand nach dem Onboarding.
///
/// Ohne sie fuehrt der Router auf den Einwilligungs-Screen und die Analyse
/// lehnt ab; beides ist gewollt, aber in den meisten Tests nicht das Thema.
void einwilligungErteilen(
  ProviderContainer container, {
  bool fotoKi = true,
}) {
  final ctrl = container.read(einwilligungControllerProvider.notifier);
  ctrl.setzen(
    Einwilligungsart.nutzung,
    erteilt: true,
    kanal: Einwilligungskanal.onboarding,
  );
  ctrl.setzen(
    Einwilligungsart.fotoKi,
    erteilt: fotoKi,
    kanal: Einwilligungskanal.onboarding,
  );
}
