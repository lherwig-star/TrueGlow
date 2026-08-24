import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/einrichtung_hinweis.dart';
import 'core/firebase/firebase_start.dart';
import 'core/l10n/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/analysis/logic/analysis_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fehlt die .env, laeuft die App im Mock-Modus trotzdem – der Key wird erst
  // beim echten API-Call gebraucht.
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('.env nicht geladen: $e');
  }

  // Der Demo-/Screenshot-Modus laeuft komplett ohne Backend: keine Fotos im
  // Netz, keine Konten, keine Kosten. Deshalb wird Firebase dort gar nicht
  // erst gestartet.
  if (!AnalysisConfig.useMockData) {
    final firebase = await FirebaseStart.init();
    if (!firebase.bereit) {
      runApp(EinrichtungHinweisApp(ergebnis: firebase));
      return;
    }
  }

  await HiveService.init();

  // Hochformat erzwingen – der Foto-Flow ist auf Portrait ausgelegt.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: GlowUpApp()));
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
