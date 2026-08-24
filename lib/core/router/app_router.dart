import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analysis/ui/analysis_loading_screen.dart';
import '../../features/auth/logic/auth_repository.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/consent/logic/einwilligung_controller.dart';
import '../../features/consent/ui/einwilligung_screen.dart';
import '../../features/legal/logic/rechtstexte.dart';
import '../../features/legal/ui/legal_screen.dart';
import '../../features/legal/ui/rechtsdokument_screen.dart';
import '../../features/capture/models/aufnahme_typ.dart';
import '../../features/capture/ui/camera_screen.dart';
import '../../features/capture/ui/capture_flow_screen.dart';
import '../../features/checkin/ui/checkin_screen.dart';
import '../../features/direction/ui/direction_screen.dart';
import '../../features/modules/models/analyse_modul.dart';
import '../../features/modules/ui/module_selection_screen.dart';
import '../../features/history/ui/history_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/onboarding/logic/onboarding_controller.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
import '../../features/plan/ui/plan_screen.dart';
import '../../features/result/ui/result_screen.dart';
import '../../features/settings/ui/settings_screen.dart';

/// Zentrale Routen-Namen. Ueber Konstanten, damit sich Tippfehler nicht
/// erst zur Laufzeit zeigen.
class Routes {
  Routes._();
  static const onboarding = '/onboarding';

  /// Anmeldung. Liegt zwischen Onboarding und App: Ohne Konto nimmt die
  /// Cloud Function keine Analyse an.
  static const login = '/login';

  /// Nachtrag der Einwilligung – fuer Bestandsnutzer und nach einer neuen
  /// Fassung der Rechtstexte.
  static const einwilligung = '/einwilligung';
  static const home = '/';
  static const module = '/module';
  static const richtung = '/richtung';
  static const aufnahme = '/aufnahme';

  /// "Deine Richtung" nachtraeglich aendern – der Screen springt danach
  /// dorthin zurueck, von wo er aufgerufen wurde.
  static const richtungBearbeiten = '$richtung?bearbeiten=1';
  static const kamera = '/kamera';
  static const checkin = '/checkin';

  /// Vollbild-Kamera fuer den angegebenen Aufnahmetyp.
  static String kameraFuer(AufnahmeTyp typ) => '$kamera/${typ.name}';

  /// Dieselbe Kamera, aber fuer das Fortschrittsfoto eines Check-ins: Das
  /// Bild ersetzt nicht die Analyse-Aufnahme, sondern kommt zusaetzlich dazu.
  static String kameraFortschritt(AufnahmeTyp typ) =>
      '$kamera/${typ.name}?fortschritt=1';

  /// Aufnahme-Flow. Ohne Modul laeuft die komplette Auswahl, mit Modul nur
  /// dessen Schritte – der Weg ueber "Analyse erweitern".
  static String aufnahmeFuer(AnalyseModul? modul) =>
      modul == null ? aufnahme : '$aufnahme?modul=${modul.name}';

  /// Analyse. Das Modul schraenkt den Umfang auf ein einzelnes Kapitel ein.
  static String analyseFuer(AnalyseModul? modul) =>
      modul == null ? analysis : '$analysis?modul=${modul.name}';

  /// Analyse mit den vorhandenen Fotos neu rechnen – der Weg ueber "Plan mit
  /// neuer Richtung aktualisieren". Der Umfang steht ausdruecklich in der
  /// Route, damit die Neuberechnung genau die Kapitel des Reports trifft.
  static String analyseNeu(Set<AnalyseModul> module) =>
      '$analysis?module=${module.map((m) => m.name).join(',')}';
  static const analysis = '/analysis';
  static const result = '/result';
  static const plan = '/plan';
  static const history = '/history';
  static const settings = '/settings';

  /// Uebersicht der Rechtstexte.
  static const rechtliches = '/rechtliches';

  /// Ein einzelner Rechtstext in der App (Rueckfallebene ohne Netz).
  static String rechtstextFuer(Rechtsdokument dokument) =>
      '$rechtliches/${dokument.schluessel}';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    // Zwei Tore vor der App, in dieser Reihenfolge: erst das Onboarding
    // (Einwilligung), dann die Anmeldung. Beides wird beim naechsten
    // Navigationsvorgang geprueft – der Login-Screen und die Einstellungen
    // navigieren nach Erfolg selbst weiter.
    redirect: (context, state) {
      final ort = state.matchedLocation;

      final onboardingFertig =
          ref.read(onboardingControllerProvider).abgeschlossen;
      if (!onboardingFertig) {
        return ort == Routes.onboarding ? null : Routes.onboarding;
      }

      final angemeldet = ref.read(authRepositoryProvider).aktuell != null;
      if (!angemeldet) {
        return ort == Routes.login ? null : Routes.login;
      }

      // Drittes Tor: Ohne gueltige Pflichteinwilligung geht es nicht weiter.
      // Die Foto-Einwilligung ist ausdruecklich nicht dabei – sie ist
      // freiwillig und blockiert nur Analysen, nicht die App.
      if (ref.read(pflichtEinwilligungFehltProvider)) {
        return ort == Routes.einwilligung ? null : Routes.einwilligung;
      }

      if (ort == Routes.onboarding ||
          ort == Routes.login ||
          ort == Routes.einwilligung) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.einwilligung,
        builder: (context, state) => const EinwilligungScreen(),
      ),
      GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: Routes.module,
        builder: (context, state) => const ModuleSelectionScreen(),
      ),
      GoRoute(
        path: Routes.richtung,
        builder: (context, state) => DirectionScreen(
          bearbeiten: state.uri.queryParameters['bearbeiten'] == '1',
        ),
      ),
      GoRoute(
        path: Routes.aufnahme,
        builder: (context, state) =>
            CaptureFlowScreen(nurModul: _modul(state.uri.queryParameters)),
      ),
      GoRoute(
        path: '${Routes.kamera}/:typ',
        builder: (context, state) {
          final name = state.pathParameters['typ'];
          final typ = AufnahmeTyp.values.firstWhere(
            (t) => t.name == name,
            orElse: () => AufnahmeTyp.basisFrontal,
          );
          return CameraScreen(
            typ: typ,
            fuerFortschritt:
                state.uri.queryParameters['fortschritt'] == '1',
          );
        },
      ),
      GoRoute(
        path: Routes.checkin,
        builder: (context, state) => const CheckinScreen(),
      ),
      GoRoute(
        path: Routes.analysis,
        builder: (context, state) => AnalysisLoadingScreen(
          nurModul: _modul(state.uri.queryParameters),
          module: _module(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '${Routes.result}/:id',
        builder: (context, state) =>
            ResultScreen(analyseId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.plan, builder: (context, state) => const PlanScreen()),
      GoRoute(path: Routes.history, builder: (context, state) => const HistoryScreen()),
      GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: Routes.rechtliches,
        builder: (context, state) => const LegalScreen(),
        routes: [
          GoRoute(
            path: ':dokument',
            builder: (context, state) => RechtsdokumentScreen(
              dokument:
                  Rechtsdokument.ausName(state.pathParameters['dokument']) ??
                      Rechtsdokument.datenschutz,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route nicht gefunden: ${state.uri}')),
    ),
  );
});

/// Liest den optionalen Modul-Parameter aus der Route.
AnalyseModul? _modul(Map<String, String> parameter) {
  final name = parameter['modul'];
  if (name == null) return null;
  return AnalyseModul.values.where((m) => m.name == name).firstOrNull;
}

/// Liest die optionale Modul-Liste aus der Route (Neuberechnung).
Set<AnalyseModul>? _module(Map<String, String> parameter) {
  final roh = parameter['module'];
  if (roh == null || roh.isEmpty) return null;
  return AnalyseModul.ausNamen(roh.split(','));
}
