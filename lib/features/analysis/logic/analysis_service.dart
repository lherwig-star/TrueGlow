import 'dart:io';

import '../../../core/netz/wiederholung.dart';
import '../../capture/models/aufnahme_typ.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../models/analysis_result.dart';
import '../../../core/l10n/texte.dart';

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
  keinInternet,
  zeitueberschreitung,
  apiFehler,
  kontingent,
  ungueltigeAntwort,
  keinApiKey,
  fotosFehlen,
  einwilligungFehlt,
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension AnalysisFehlerText on AnalysisFehler {
  String titel(L texte) => switch (this) {
        AnalysisFehler.keinInternet => texte.analyseKeinInternetTitel,
        AnalysisFehler.zeitueberschreitung => texte.analyseZeitTitel,
        AnalysisFehler.apiFehler => texte.analyseApiTitel,
        AnalysisFehler.kontingent => texte.analyseKontingentTitel,
        AnalysisFehler.ungueltigeAntwort => texte.analyseAntwortTitel,
        AnalysisFehler.keinApiKey => texte.analyseKeinSchluesselTitel,
        AnalysisFehler.fotosFehlen => texte.analyseFotosFehlenTitel,
        AnalysisFehler.einwilligungFehlt => texte.analyseEinwilligungTitel,
      };

  String tipp(L texte) => switch (this) {
        AnalysisFehler.keinInternet => texte.analyseKeinInternetTipp,
        AnalysisFehler.zeitueberschreitung => texte.analyseZeitTipp,
        AnalysisFehler.apiFehler => texte.analyseApiTipp,
        AnalysisFehler.kontingent => texte.analyseKontingentTipp,
        AnalysisFehler.ungueltigeAntwort => texte.analyseAntwortTipp,
        AnalysisFehler.keinApiKey => texte.analyseKeinSchluesselTipp,
        AnalysisFehler.fotosFehlen => texte.analyseFotosFehlenTipp,
        AnalysisFehler.einwilligungFehlt => texte.analyseEinwilligungTipp,
      };
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
  /// [abbruch] stoppt Warten und Wiederholen, wenn der Nutzer aufgibt.
  ///
  /// Wirft bei Problemen eine [AnalysisException].
  Future<AnalysisResult> analysiere({
    required Map<AufnahmeTyp, File> fotos,
    required Set<AnalyseModul> module,
    required OnboardingProfile onboarding,
    required ModulEingaben eingaben,
    Richtung richtung = Richtung.leer,
    Abbruch? abbruch,
  });
}
