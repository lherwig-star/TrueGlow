import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/cloud/cloud_provider.dart';
import 'core/cloud/cloud_speicher.dart';
import 'core/diagnose/diagnose_dienst.dart';
import 'core/firebase/einrichtung_hinweis.dart';
import 'core/firebase/firebase_start.dart';
import 'core/l10n/sprache.dart';
import 'core/l10n/texte.dart';
import 'core/netz/netz_zustand.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/sync/sync_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/analysis/logic/analysis_service.dart';
import 'features/account/logic/konto_dienst.dart';
import 'features/auth/logic/auth_repository.dart';
import 'features/auth/logic/firebase_auth_repository.dart';
import 'features/legal/logic/rechtstexte.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Im Release schweigt die App.
  //
  // `debugPrint` heisst zwar so, wird aber nicht wegkompiliert: Die rund
  // vierzig Protokollzeilen der App laufen sonst auch in einer
  // veroeffentlichten Fassung ins Geraeteprotokoll. Der Inhalt ist harmlos
  // – abgefangene Ausnahmen, keine Fotos, keine Namen –, aber eine
  // Ausnahme kann einen Dateipfad mitbringen, und ein Pfad enthaelt den
  // Dateinamen eines Fotos (SECURITY_AUDIT C2).
  //
  // Im Debug- und im Profile-Build bleibt alles, wie es war.
  if (kReleaseMode) {
    debugPrint = (String? nachricht, {int? wrapWidth}) {};
  }

  // Meldet im Debug-Build, wenn noch Rechtstexte fehlen – als Assertion, nicht
  // als Absturz. Den harten Riegel vor dem Release zieht
  // tool/rechtstexte_pruefen.dart.
  assert(() {
    if (!Rechtstexte.vollstaendig) {
      debugPrint('⚠️  ${Rechtstexte.fehlerbericht}');
    }
    return true;
  }());

  // Der Demo-/Screenshot-Modus laeuft komplett ohne Backend: keine Fotos im
  // Netz, keine Konten, keine Kosten. Deshalb wird Firebase dort gar nicht
  // erst gestartet und die Anmeldung bleibt im Arbeitsspeicher – der
  // Login-Screen und „Erst ausprobieren" funktionieren trotzdem.
  final AuthRepository anmeldung;
  // Im Demo-Modus bleibt die Fabrik leer: Ohne Cloud-Speicher laufen
  // Migration und Sync ins Leere, statt Firestore zu rufen.
  CloudSpeicher Function(String uid)? cloudFabrik;
  DiagnoseDienst diagnose = DiagnoseOhneBackend();

  if (AnalysisConfig.useMockData) {
    anmeldung = FakeAuthRepository();
  } else {
    final firebase = await FirebaseStart.init();
    if (!firebase.bereit) {
      runApp(EinrichtungHinweisApp(ergebnis: firebase));
      return;
    }
    // Erst warten, bis Firebase eine gespeicherte Sitzung wiederhergestellt
    // hat – sonst zeigt der Router beim Start kurz den Login-Screen.
    await FirebaseAuthRepository.sitzungAbwarten();
    anmeldung = FirebaseAuthRepository();
    cloudFabrik = (uid) => FirestoreSpeicher(uid: uid);
    diagnose = FirebaseDiagnose();
  }

  // Die Erfassung startet aus. Eingeschaltet wird sie erst durch den
  // diagnoseSchalterProvider, und der haengt an der Einwilligung.
  await diagnose.erfassungErlauben(false);

  // Zwei Kanaele, zwei Handler: FlutterError.onError faengt, was im
  // Widget-Baum passiert, PlatformDispatcher.onError alles andere aus dem
  // Isolate. Ohne den zweiten fehlt genau die Sorte Absturz, die niemand
  // reproduzieren kann.
  final flutterFehler = FlutterError.onError;
  FlutterError.onError = (details) {
    flutterFehler?.call(details);
    diagnose.fehler(details.exception, details.stack, schwer: true);
  };
  PlatformDispatcher.instance.onError = (fehler, spur) {
    diagnose.fehler(fehler, spur, schwer: true);
    // false: Der Fehler gilt weiter als unbehandelt und landet in der
    // Konsole. Ihn hier zu schlucken hiesse, ihn im Debug-Build zu
    // verstecken.
    return false;
  };

  await HiveService.init();

  // Hochformat erzwingen – der Foto-Flow ist auf Portrait ausgelegt.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(anmeldung),
        cloudSpeicherFabrikProvider.overrideWithValue(cloudFabrik),
        // Ohne Backend gibt es nichts zu loeschen – die lokale Loeschung
        // laeuft im Demo-Modus trotzdem.
        kontoDienstProvider.overrideWithValue(
          cloudFabrik == null ? null : KontoDienst(),
        ),
        diagnoseDienstProvider.overrideWithValue(diagnose),
      ],
      child: const TrueGlowApp(),
    ),
  );
}


class TrueGlowApp extends ConsumerStatefulWidget {
  const TrueGlowApp({super.key});

  @override
  ConsumerState<TrueGlowApp> createState() => _TrueGlowAppState();
}

class _TrueGlowAppState extends ConsumerState<TrueGlowApp> {
  @override
  void initState() {
    super.initState();
    // Nach dem ersten Frame, damit der Start nicht am Netz haengt: Die App
    // ist mit dem lokalen Bestand sofort bedienbar, der Cloud-Stand kommt
    // gleich darauf dazu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _abgleichen());
  }

  /// Holt den Cloud-Stand und laedt die Controller neu, wenn sich etwas
  /// geaendert hat.
  Future<void> _abgleichen() async {
    final dienst = ref.read(syncDienstProvider);
    final cloud = ref.read(cloudSpeicherProvider);

    dienst.cloudSetzen(cloud);
    if (cloud == null) return;

    final geaendert = await dienst.abgleichen(cloud);
    if (geaendert && mounted) {
      zustaendeNeuLaden(ref);
    }
  }

  /// Welche Sprache das Geraet bekommt, wenn der Nutzer keine gewaehlt hat.
  ///
  /// Ohne diesen Rueckfall nimmt Flutter bei einer unbekannten Sprache den
  /// **ersten** Eintrag aus `supportedLocales`, und das waere Deutsch – ein
  /// franzoesisches Handy bekaeme also Deutsch statt Englisch.
  static Locale _spracheAufloesen(
    Locale? geraet,
    Iterable<Locale> unterstuetzt,
  ) =>
      Sprache.fuerGeraet(geraet ?? const Locale('en')).locale;

  @override
  Widget build(BuildContext context) {
    // Nach jedem Wechsel des Kontos – Anmeldung, Abmeldung, Verknuepfung –
    // wird neu abgeglichen.
    ref.listen(cloudSpeicherProvider, (_, _) => _abgleichen());

    // Haelt die Diagnose-Erfassung an der Einwilligung. `watch` und nicht
    // `read`: Der Widerruf soll sofort wirken, nicht beim naechsten Start.
    ref.watch(diagnoseSchalterProvider);

    // `null` heisst „der Nutzer hat nichts gewaehlt" – dann entscheidet
    // [_spracheAufloesen] anhand des Geraets.
    final gewaehlt = ref.watch(sprachControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.texte.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeControllerProvider).modus,
      locale: gewaehlt?.locale,
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        // Die drei bringen die uebersetzten Systemtexte mit – Datumsauswahl,
        // Kontextmenue der Textfelder, Vorlesefunktion – und die Datums- und
        // Zahlformate der jeweiligen Sprache.
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: _spracheAufloesen,
      routerConfig: ref.watch(routerProvider),
      // Statusbar und Navigationsleiste folgen dem tatsaechlich aufgeloesten
      // Schema – bei "System" also der Systemeinstellung des Handys.
      builder: (context, child) {
        final theme = Theme.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayStyle(
            theme.extension<AppColors>()!,
            theme.brightness,
          ),
          // Das Offline-Band liegt ueber allen Screens – ein Hinweis, den man
          // je nach Route neu bauen muesste, fehlt irgendwann auf einer.
          child: OfflineBand(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
