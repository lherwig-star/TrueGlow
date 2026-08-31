import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analysis/ui/analysis_loading_screen.dart';
import '../../features/analysis/ui/modus_screen.dart';
import '../../features/auth/logic/auth_repository.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/consent/logic/einwilligung_controller.dart';
import '../../features/consent/ui/alters_hinweis_screen.dart';
import '../../features/consent/ui/einwilligung_screen.dart';
import '../../features/legal/logic/rechtstexte.dart';
import '../../features/legal/ui/legal_screen.dart';
import '../../features/legal/ui/rechtsdokument_screen.dart';
import '../../features/capture/models/aufnahme_typ.dart';
import '../../features/capture/ui/camera_screen.dart';
import '../../features/capture/ui/capture_flow_screen.dart';
import '../../features/checkin/ui/checkin_screen.dart';
import '../../features/ausprobieren/ui/ausprobieren_screen.dart';
import '../../features/direction/ui/direction_screen.dart';
import '../../features/modules/models/analyse_modul.dart';
import '../../features/modules/ui/module_selection_screen.dart';
import '../../features/checkin/ui/fortschritt_screen.dart';
import '../../features/home/logic/home_tab.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/onboarding/logic/onboarding_controller.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
import '../../features/start/ui/splash_screen.dart';
import '../../features/result/ui/result_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/result/ui/erweitern_screen.dart';
import '../../features/result/ui/kapitel_screen.dart';
import '../../features/wissen/ui/wissen_screen.dart';
import '../../core/l10n/texte.dart';

/// Zentrale Routen-Namen. Ueber Konstanten, damit sich Tippfehler nicht
/// erst zur Laufzeit zeigen.
class Routes {
  Routes._();

  /// Die Startanimation. Erster Bildschirm nach dem Programmstart und der
  /// einzige, den keine Weiche schuetzt – er entscheidet nichts, er zeigt nur
  /// das Zeichen und schickt danach auf [home] weiter.
  static const start = '/start';

  static const onboarding = '/onboarding';

  /// Anmeldung. Liegt zwischen Onboarding und App: Ohne Konto nimmt die
  /// Cloud Function keine Analyse an.
  static const login = '/login';

  /// Nachtrag der Einwilligung – fuer Bestandsnutzer und nach einer neuen
  /// Fassung der Rechtstexte.
  static const einwilligung = '/einwilligung';

  /// Hinweis, dass der Analyse-Bereich Erwachsenen vorbehalten ist.
  static const altersHinweis = '/ab18';

  /// Der Analyse-Flow, den die Altersbestaetigung schuetzt. Wer eine dieser
  /// Routen ohne Bestaetigung aufruft, landet auf [altersHinweis].
  static const analyseFlow = {
    modus,
    module,
    richtung,
    ausprobieren,
    aufnahme,
    kamera,
    analysis,
  };

  static const home = '/';

  /// Erster Schritt jeder Analyse: verfeinern oder neu entdecken.
  static const modus = '/modus';
  static const module = '/module';
  static const richtung = '/richtung';

  /// „Das will ich ausprobieren" – der Schritt direkt nach der Richtung.
  static const ausprobieren = '/ausprobieren';
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

  /// Das Fortschritts-Tagebuch. Die Fotos darin verlassen das Geraet nie.
  static const fortschritt = '/fortschritt';
  static const settings = '/settings';

  /// Uebersicht der Rechtstexte.
  static const rechtliches = '/rechtliches';

  /// Die Wissens-Bibliothek zum Stoebern.
  static const wissen = '/wissen';

  /// Ein einzelner Bereich des Reports – der Weg hinter einer Kachel.
  static String kapitelFuer(String analyseId, AnalyseModul modul) =>
      '$result/$analyseId/kapitel/${modul.name}';

  /// Die noch offenen Bereiche mit den ausfuehrlichen Modul-Karten.
  static String erweiternFuer(String analyseId) =>
      '$result/$analyseId/erweitern';

  /// Ein einzelner Rechtstext in der App (Rueckfallebene ohne Netz).
  static String rechtstextFuer(Rechtsdokument dokument) =>
      '$rechtliches/${dokument.schluessel}';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.start,
    // Zwei Tore vor der App, in dieser Reihenfolge: erst die Anmeldung, dann
    // das Onboarding. Beides wird beim naechsten Navigationsvorgang geprueft –
    // der Login-Screen und die Einstellungen navigieren nach Erfolg selbst
    // weiter.
    //
    // Die Reihenfolge war frueher umgekehrt. Die Anmeldung nach vorn zu
    // ziehen heisst: Wer die App zum zweiten Mal oeffnet, sieht sofort sein
    // Dashboard, und die Erklaerseiten kommen genau einmal – nach der
    // Anmeldung, wo sie zu einem Konto gehoeren statt zu einem Geraet.
    redirect: (context, state) {
      final ort = state.matchedLocation;

      // Die Startanimation liegt vor allen Weichen. Sie schickt sich selbst
      // weiter; wuerde eine Weiche hier greifen, waere sie nie zu sehen.
      if (ort == Routes.start) return null;

      final angemeldet = ref.read(authRepositoryProvider).aktuell != null;
      if (!angemeldet) {
        return ort == Routes.login ? null : Routes.login;
      }

      final onboardingFertig =
          ref.read(onboardingControllerProvider).abgeschlossen;
      if (!onboardingFertig) {
        return ort == Routes.onboarding ? null : Routes.onboarding;
      }

      // Drittes Tor: Ohne gueltige Pflichteinwilligung geht es nicht weiter.
      // Dazu kommt der einmalige Nachtrag, wenn nach der Altersbestaetigung
      // noch nie gefragt wurde. Die freiwilligen Punkte blockieren danach
      // nichts mehr – sie steuern nur, was moeglich ist.
      if (ref.read(nachtragNoetigProvider)) {
        return ort == Routes.einwilligung ? null : Routes.einwilligung;
      }

      if (ort == Routes.onboarding ||
          ort == Routes.login ||
          ort == Routes.einwilligung) {
        return Routes.home;
      }

      // Viertes Tor, aber nur vor dem Analyse-Flow: Die App ist ab 18. Ohne
      // Bestaetigung bleibt genau dieser Bereich zu – mit Erklaerung, nicht
      // als stumme Wand.
      if (_imAnalyseFlow(ort) &&
          !ref.read(volljaehrigBestaetigtProvider)) {
        return '${Routes.altersHinweis}?ziel=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (ort == Routes.altersHinweis &&
          ref.read(volljaehrigBestaetigtProvider) &&
          state.uri.queryParameters['ziel'] == null) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.start,
        builder: (context, state) => const SplashScreen(),
      ),
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
      GoRoute(
        path: Routes.altersHinweis,
        builder: (context, state) => AltersHinweisScreen(
          ziel: state.uri.queryParameters['ziel'],
        ),
      ),
      GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: Routes.modus,
        builder: (context, state) => const ModusScreen(),
      ),
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
        path: Routes.ausprobieren,
        builder: (context, state) => const AusprobierenScreen(),
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
        routes: [
          GoRoute(
            path: 'kapitel/:modul',
            builder: (context, state) => KapitelScreen(
              analyseId: state.pathParameters['id']!,
              modulName: state.pathParameters['modul']!,
            ),
          ),
          GoRoute(
            path: 'erweitern',
            builder: (context, state) => ErweiternScreen(
              analyseId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      // Plan und Verlauf haben seit DECISIONS 65 keinen eigenen
      // Bildschirm mehr – sie sind Tabs der Startseite. Die Pfade
      // bleiben trotzdem: Benachrichtigungen, der Check-in und aeltere
      // Wege zeigen darauf. Sie setzen den Tab und leiten weiter, statt
      // eine zweite Huelle aufzumachen – nur so behaelt die eine ihre
      // vier Scroll-Positionen.
      GoRoute(
        path: Routes.plan,
        redirect: (context, state) {
          ref.read(homeTabProvider.notifier).state = HomeTab.plan;
          return Routes.home;
        },
      ),
      GoRoute(
        path: Routes.history,
        redirect: (context, state) {
          ref.read(homeTabProvider.notifier).state = HomeTab.analyse;
          return Routes.home;
        },
      ),
      GoRoute(
        path: Routes.fortschritt,
        builder: (context, state) => const FortschrittScreen(),
      ),
      GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: Routes.wissen,
        builder: (context, state) => const WissenScreen(),
      ),
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
      body: Center(
        child: Text(context.texte.routeNichtGefunden('${state.uri}')),
      ),
    ),
  );
});

/// Ob ein Pfad zum Analyse-Flow gehoert.
///
/// Verglichen wird der Anfang des Pfads, weil die Kamera-Route ein Segment
/// anhaengt (`/kamera/basisFrontal`).
bool _imAnalyseFlow(String ort) =>
    Routes.analyseFlow.any((pfad) => ort == pfad || ort.startsWith('$pfad/'));

/// Liest den optionalen Modul-Parameter aus der Route.
AnalyseModul? _modul(Map<String, String> parameter) {
  final name = parameter['modul'];
  if (name == null) return null;
  return AnalyseModul.bestellbar.where((m) => m.name == name).firstOrNull;
}

/// Liest die optionale Modul-Liste aus der Route (Neuberechnung).
Set<AnalyseModul>? _module(Map<String, String> parameter) {
  final roh = parameter['module'];
  if (roh == null || roh.isEmpty) return null;
  return AnalyseModul.ausNamen(roh.split(','));
}
