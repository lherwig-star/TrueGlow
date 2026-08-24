import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/cloud/cloud_provider.dart';
import 'core/cloud/cloud_speicher.dart';
import 'core/firebase/einrichtung_hinweis.dart';
import 'core/firebase/firebase_start.dart';
import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/analysis/logic/analysis_service.dart';
import 'features/auth/logic/auth_repository.dart';
import 'features/auth/logic/firebase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Der Demo-/Screenshot-Modus laeuft komplett ohne Backend: keine Fotos im
  // Netz, keine Konten, keine Kosten. Deshalb wird Firebase dort gar nicht
  // erst gestartet und die Anmeldung bleibt im Arbeitsspeicher – der
  // Login-Screen und „Erst ausprobieren" funktionieren trotzdem.
  final AuthRepository anmeldung;
  // Im Demo-Modus bleibt die Fabrik leer: Ohne Cloud-Speicher laufen
  // Migration und Sync ins Leere, statt Firestore zu rufen.
  CloudSpeicher Function(String uid)? cloudFabrik;

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
  }

  await HiveService.init();

  // Hochformat erzwingen – der Foto-Flow ist auf Portrait ausgelegt.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(anmeldung),
        cloudSpeicherFabrikProvider.overrideWithValue(cloudFabrik),
      ],
      child: const GlowUpApp(),
    ),
  );
}

class GlowUpApp extends ConsumerWidget {
  const GlowUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeControllerProvider).modus,
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
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
