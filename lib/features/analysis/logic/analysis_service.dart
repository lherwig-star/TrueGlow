import 'dart:io';

import '../../capture/models/aufnahme_typ.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../models/analysis_result.dart';

/// Zentrale Konfiguration der Analyse. Alles, was man beim Wechsel des
/// Vision-Modells oder des Anbieters anfassen muss, steht hier.
class AnalysisConfig {
  AnalysisConfig._();

  /// Schalter fuer den Demo-/Screenshot-Modus. Auf `true` verlaesst kein Foto
  /// das Geraet, es gibt keine Konten und keine Kosten – die App zeigt eine
  /// hinterlegte Beispiel-Analyse.
  ///
  /// Standard ist `false`, damit im Release nie versehentlich der Mock laeuft.
  /// Einschalten ausdruecklich beim Build:
  /// `flutter run --dart-define=TRUEGLOW_MOCK=true`.
  static const bool useMockData = bool.fromEnvironment('TRUEGLOW_MOCK');

  /// Das verwendete Vision-Modell – nur noch zur Anzeige in den
  /// Einstellungen. Massgeblich ist `MODELL` in `functions/src/gemini.ts`:
  /// Das Modell wird seit dem Umbau ausschliesslich serverseitig gewaehlt.
  static const String modell = 'gemini-3.5-flash-lite';

  /// Maximale Wartezeit auf die Cloud Function.
  ///
  /// Die Function raeumt sich selbst 180 s ein (zwei Gemini-Versuche à 60 s
  /// plus Aufschlag). Der Client wartet etwas kuerzer, damit er den Abbruch
  /// als Zeitueberschreitung anzeigt statt in einer offenen Verbindung zu
  /// haengen.
  static const Duration zeitlimit = Duration(seconds: 150);

  /// Wartezeit im Mock-Modus, damit der Ladezustand realistisch wirkt.
  static const Duration mockDauer = Duration(seconds: 2);
}

/// Fehlerfaelle der Analyse – jeweils mit verstaendlichem Text fuer die UI.
enum AnalysisFehler {
  keinInternet(
    'Keine Verbindung',
    'Prüf deine Internetverbindung und versuch es noch einmal.',
  ),
  zeitueberschreitung(
    'Zeitüberschreitung',
    'Die Analyse hat zu lange gedauert. Versuch es bitte erneut.',
  ),
  apiFehler(
    'Analyse nicht möglich',
    'Der Analyse-Dienst antwortet gerade nicht. Bitte später noch einmal versuchen.',
  ),
  kontingent(
    'Kontingent erschöpft',
    'Das Limit des Analyse-Dienstes ist erreicht. Versuch es später noch einmal.',
  ),
  ungueltigeAntwort(
    'Antwort nicht lesbar',
    'Die Analyse kam unvollständig zurück. Ein erneuter Versuch hilft meistens.',
  ),
  keinApiKey(
    'Analyse-Dienst nicht eingerichtet',
    'Der Dienst ist gerade nicht einsatzbereit. Wir kümmern uns darum – '
        'versuch es später noch einmal.',
  ),
  fotosFehlen(
    'Fotos fehlen',
    'Für diese Auswahl fehlen noch Aufnahmen. Geh zurück und hol sie nach.',
  );

  const AnalysisFehler(this.titel, this.tipp);
  final String titel;
  final String tipp;
}

/// Wird vom Service geworfen und vom Controller in einen Zustand uebersetzt.
class AnalysisException implements Exception {
  const AnalysisException(this.fehler, [this.details]);

  final AnalysisFehler fehler;
  final String? details;

  @override
  String toString() =>
      'AnalysisException(${fehler.name}${details == null ? '' : ': $details'})';
}

/// Abstraktion ueber den Vision-Anbieter. Die UI kennt nur dieses Interface –
/// ein neuer Anbieter braucht nur eine weitere Implementierung.
abstract interface class AnalysisService {
  /// Schickt die Aufnahmen an die Vision-KI und liefert das geparste
  /// Ergebnis. [module] bestimmt, welche Kapitel entstehen – beim
  /// nachtraeglichen Erweitern ist das genau ein Modul.
  ///
  /// [richtung] sind die persoenlichen Ziele des Nutzers; sie sind optional
  /// und leer, wenn der Schritt uebersprungen wurde.
  ///
  /// Wirft bei Problemen eine [AnalysisException].
  Future<AnalysisResult> analysiere({
    required Map<AufnahmeTyp, File> fotos,
    required Set<AnalyseModul> module,
    required OnboardingProfile onboarding,
    required ModulEingaben eingaben,
    Richtung richtung = Richtung.leer,
  });
}
