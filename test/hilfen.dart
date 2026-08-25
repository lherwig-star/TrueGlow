import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/core/storage/hive_service.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/mock_analysis_service.dart';
import 'package:trueglow/features/auth/logic/auth_repository.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/logic/image_quality_service.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/photo_check_result.dart';
import 'package:trueglow/features/checkin/logic/checkin_service.dart';
import 'package:trueglow/features/consent/logic/einwilligung_controller.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/main.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Die deutschen Texte – dieselbe Quelle, aus der auch die App sie zieht.
///
/// Die Tests pruefen auf sichtbare Saetze. Waeren die hier von Hand
/// abgeschrieben, wuerde eine geaenderte Formulierung in der ARB-Datei den
/// Test nicht mehr erreichen: Er suchte weiter nach dem alten Satz und faende
/// ihn nicht – als Fehler, der nach einem echten Fehler aussieht.
final texte = lookupL(const Locale('de'));

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

/// Rahmen fuer Tests, die ein einzelnes Widget pruefen statt der ganzen App.
///
/// Enthaelt genau das, was die Widgets von oben erwarten: die App-Themes –
/// die Farben haengen an einer Theme-Extension und waeren sonst nicht da –
/// und die Lokalisierung, festgenagelt auf Deutsch.
Widget testHuelle(Widget kind) => MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: kind,
    );

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
/// [anmeldung] ersetzt die Standard-Attrappe. Wichtig: Denselben Provider
/// zweimal zu ueberschreiben ist keine gute Idee – wer eine eigene Anmeldung
/// braucht, reicht sie hier durch, statt einen zweiten Override anzuhaengen.
List<Override> dienstOverrides({AuthRepository? anmeldung}) => [
      analysisServiceProvider.overrideWithValue(const MockAnalysisService()),
      checkinServiceProvider.overrideWithValue(const MockCheckinService()),
      // Standardmaessig angemeldet: Der Router laesst sonst niemanden am
      // Login-Screen vorbei, und die bestehenden Tests pruefen die Screens
      // dahinter.
      authRepositoryProvider.overrideWithValue(
        anmeldung ?? FakeAuthRepository.angemeldet(),
      ),
      // Die Bildpruefung haengt an ML Kit und am Dateisystem des Geraets –
      // beides gibt es im Widget-Test nicht. Ohne diesen Override bleibt
      // etwa `fotosLoeschen()` haengen, weil der Plattformkanal nie antwortet.
      imageQualityServiceProvider.overrideWithValue(const BildpruefungOhneGeraet()),
      // Widget-Tests laufen auf Deutsch. Ohne diese Festlegung entscheidet
      // das Gebietsschema der Testumgebung – und das steht auf en_US. Die
      // Tests suchten dann deutsche Saetze in einer englischen Oberflaeche.
      sprachControllerProvider.overrideWith((ref) {
        final ctrl = SprachController(MemoryStore());
        ctrl.setzen(Sprache.deutsch);
        return ctrl;
      }),
    ];

/// Speicher plus Dienste – der Standardsatz fuer Widget-Tests.
List<Override> testOverrides({AuthRepository? anmeldung}) =>
    [...speicherOverrides(), ...dienstOverrides(anmeldung: anmeldung)];

/// Startet die App mit abgeschlossenem Onboarding und angemeldetem Konto –
/// der Zustand, in dem die eigentlichen Screens erreichbar sind.
Future<ProviderContainer> appMitDashboard(
  WidgetTester tester, {
  List<Override> zusatz = const [],
  AuthRepository? anmeldung,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...testOverrides(anmeldung: anmeldung), ...zusatz],
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

/// Erteilt alle Bestaetigungen – der Zustand nach dem Onboarding.
///
/// Ohne sie fuehrt der Router auf den Nachtrags-Screen und die Analyse lehnt
/// ab; beides ist gewollt, aber in den meisten Tests nicht das Thema.
void einwilligungErteilen(
  ProviderContainer container, {
  bool fotoKi = true,
  bool mindestalter = true,
}) {
  final ctrl = container.read(einwilligungControllerProvider.notifier);
  ctrl.setzen(
    Einwilligungsart.nutzung,
    erteilt: true,
    kanal: Einwilligungskanal.onboarding,
  );
  ctrl.setzen(
    Einwilligungsart.mindestalter,
    erteilt: mindestalter,
    kanal: Einwilligungskanal.onboarding,
  );
  ctrl.setzen(
    Einwilligungsart.fotoKi,
    erteilt: fotoKi,
    kanal: Einwilligungskanal.onboarding,
  );
}

/// Bildpruefung ohne Geraet: tut nichts und kommt sofort zurueck.
class BildpruefungOhneGeraet implements ImageQualityService {
  const BildpruefungOhneGeraet();

  @override
  Future<PhotoCheckResult> pruefeUndVerarbeite({
    required File datei,
    required AufnahmeTyp typ,
    String? namensraum,
  }) async =>
      const PhotoCheckFehler(PhotoProblem.fehlgeschlagen);

  @override
  Future<void> fotosLoeschen() async {}

  @override
  void dispose() {}
}

/// Ein leerer Speicher fuer Controller-Tests ohne Hive.
KeyValueStore speicherAttrappe() => MemoryStore();
