import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/consent/logic/einwilligung_controller.dart';
import '../../features/consent/models/einwilligung.dart';
import 'bereinigung.dart';

/// Die vollständige Liste der Ereignisse, die die App meldet.
///
/// Ein Enum und keine freien Strings: Was hier nicht steht, kann nicht
/// gesendet werden. Damit ist die Frage „was erfasst ihr eigentlich?" mit
/// einem Blick auf diese Datei beantwortet — für die Datenschutzerklärung,
/// für das Data-Safety-Formular und für jeden, der es wissen will.
///
/// **Kein Ereignis trägt Parameter.** Gemeldet wird ausschließlich, *dass*
/// ein Schritt erreicht wurde: keine Analyse-Inhalte, keine Freitexte, keine
/// Profilangaben, keine Modulauswahl. Der Funnel braucht nicht mehr, und
/// alles darüber hinaus wäre eine Zusage, die niemand geprüft hat.
enum DiagnoseEreignis {
  onboardingAbgeschlossen('onboarding_abgeschlossen'),
  anmeldungAbgeschlossen('anmeldung_abgeschlossen'),
  analyseGestartet('analyse_gestartet'),
  analyseFertig('analyse_fertig'),
  planGeoeffnet('plan_geoeffnet'),
  checkinGestartet('checkin_gestartet'),
  checkinAbgeschlossen('checkin_abgeschlossen');

  const DiagnoseEreignis(this.name);

  /// Name im Analytics-Backend. Klein und mit Unterstrichen, wie Firebase es
  /// verlangt.
  final String name;
}

/// Absturzberichte und Funnel-Ereignisse.
///
/// Hinter einer Schnittstelle, damit die Tests ohne Firebase auskommen und
/// damit sich prüfen lässt, *was* gemeldet würde, ohne etwas zu melden.
abstract interface class DiagnoseDienst {
  /// Schaltet die Erfassung an oder ab.
  ///
  /// Wird bei jeder Änderung der Einwilligung aufgerufen. `false` heißt: Die
  /// SDKs sammeln gar nicht erst — nicht „sie sammeln und wir senden nicht".
  Future<void> erfassungErlauben(bool erlaubt);

  /// Meldet ein Ereignis des Funnels.
  Future<void> melde(DiagnoseEreignis ereignis);

  /// Meldet einen abgefangenen Fehler.
  Future<void> fehler(Object fehler, StackTrace? spur, {bool schwer = false});
}

/// Die Firebase-Fassung.
class FirebaseDiagnose implements DiagnoseDienst {
  FirebaseDiagnose({
    FirebaseCrashlytics? crashlytics,
    FirebaseAnalytics? analytics,
  })  : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
        _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseCrashlytics _crashlytics;
  final FirebaseAnalytics _analytics;

  bool _erlaubt = false;

  @override
  Future<void> erfassungErlauben(bool erlaubt) async {
    _erlaubt = erlaubt;
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(erlaubt);
      await _analytics.setAnalyticsCollectionEnabled(erlaubt);
    } catch (e) {
      debugPrint('Diagnose-Erfassung nicht umschaltbar: $e');
    }
  }

  @override
  Future<void> melde(DiagnoseEreignis ereignis) async {
    if (!_erlaubt) return;
    try {
      await _analytics.logEvent(name: ereignis.name);
    } catch (e) {
      debugPrint('Ereignis nicht gemeldet: $e');
    }
  }

  @override
  Future<void> fehler(
    Object fehler,
    StackTrace? spur, {
    bool schwer = false,
  }) async {
    if (!_erlaubt) return;
    try {
      // Bereinigt, nicht roh: Eine Firestore-Ausnahme nennt den
      // Dokumentpfad, und der enthält die uid.
      await _crashlytics.recordError(
        BereinigterFehler.aus(fehler),
        spur,
        fatal: schwer,
      );
    } catch (e) {
      debugPrint('Fehler nicht gemeldet: $e');
    }
  }
}

/// Fassung ohne Backend: merkt sich, was gemeldet worden wäre.
///
/// Benutzt im Demo-Modus und in Tests. Dass sie mitschreibt statt zu
/// schweigen, ist der Punkt — so lässt sich prüfen, dass ohne Einwilligung
/// nichts gemeldet wird.
class DiagnoseOhneBackend implements DiagnoseDienst {
  bool erlaubt = false;

  final List<DiagnoseEreignis> ereignisse = [];
  final List<Object> fehlerliste = [];

  @override
  Future<void> erfassungErlauben(bool wert) async => erlaubt = wert;

  @override
  Future<void> melde(DiagnoseEreignis ereignis) async {
    if (!erlaubt) return;
    ereignisse.add(ereignis);
  }

  @override
  Future<void> fehler(
    Object fehler,
    StackTrace? spur, {
    bool schwer = false,
  }) async {
    if (!erlaubt) return;
    fehlerliste.add(BereinigterFehler.aus(fehler));
  }
}

/// Der Diagnose-Dienst der laufenden App.
///
/// Standard ist die Fassung ohne Backend — `main()` überschreibt sie, sobald
/// Firebase steht.
final diagnoseDienstProvider =
    Provider<DiagnoseDienst>((ref) => DiagnoseOhneBackend());

/// Hält die Erfassung am Einwilligungsstand.
///
/// Ein eigener Provider und kein Aufruf in der UI: Der Schalter steht in den
/// Einstellungen, die Einwilligung kann sich aber auch durch eine neue
/// Textversion ändern. Hier hängt beides an derselben Quelle.
final diagnoseSchalterProvider = Provider<void>((ref) {
  final erlaubt = ref.watch(einwilligungGiltProvider(Einwilligungsart.diagnose));
  ref.read(diagnoseDienstProvider).erfassungErlauben(erlaubt);
});
