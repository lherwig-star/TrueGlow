import 'dart:io';

import '../../../core/l10n/sprache.dart';
import '../../../core/netz/wiederholung.dart';
import '../../capture/models/aufnahme_typ.dart';
import '../../ausprobieren/models/technik.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../models/analyse_modus.dart';
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
  static const String modell = 'gemini-3.7-flash';

  /// Maximale Wartezeit auf die Cloud Function.
  ///
  /// Die Function raeumt sich selbst 300 s ein (zwei Gemini-Versuche à 120 s
  /// plus Aufschlag). Der Client wartet etwas kuerzer, damit er den Abbruch
  /// als Zeitueberschreitung anzeigt statt in einer offenen Verbindung zu
  /// haengen.
  ///
  /// Warum so lange: Das Modell denkt vor der Antwort. Bei elf Bildern
  /// dauert das spuerbar laenger als frueher – siehe DECISIONS 41.
  static const Duration zeitlimit = Duration(seconds: 280);

  /// Wartezeit im Mock-Modus, damit der Ladezustand realistisch wirkt.
  static const Duration mockDauer = Duration(seconds: 2);
}

/// Fehlerfaelle der Analyse – jeweils mit verstaendlichem Text fuer die UI.
enum AnalysisFehler {
  keinInternet,
  zeitueberschreitung,
  apiFehler,
  kontingent,

  /// Die Monatsgrenze, nicht die Tagesgrenze. Eigener Fall, weil „morgen
  /// wieder" hier nicht stimmt und der Check-in weiterhin geht.
  kontingentMonat,

  ungueltigeAntwort,
  keinApiKey,
  fotosFehlen,
  einwilligungFehlt,

  /// Der Server hat nicht das Konto abgelehnt, sondern die **Installation**.
  ///
  /// Das ist App Check: Die Cloud Function nimmt nur Aufrufe aus echten
  /// Installationen der App an. Fällt diese Prüfung durch, kommt
  /// `unauthenticated` zurück – und das sah bis DECISIONS 59 aus wie ein
  /// vorübergehender Ausfall des Dienstes („antwortet gerade nicht"). Es ist
  /// aber das Gegenteil: Der Dienst antwortet sofort und dauerhaft mit Nein,
  /// und Warten hilft nicht.
  zugangAbgelehnt,
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension AnalysisFehlerText on AnalysisFehler {
  String titel(L texte) => switch (this) {
        AnalysisFehler.keinInternet => texte.analyseKeinInternetTitel,
        AnalysisFehler.zeitueberschreitung => texte.analyseZeitTitel,
        AnalysisFehler.apiFehler => texte.analyseApiTitel,
        AnalysisFehler.kontingent => texte.analyseKontingentTitel,
        AnalysisFehler.kontingentMonat => texte.kontingentMonatsgrenze,
        AnalysisFehler.ungueltigeAntwort => texte.analyseAntwortTitel,
        AnalysisFehler.keinApiKey => texte.analyseKeinSchluesselTitel,
        AnalysisFehler.fotosFehlen => texte.analyseFotosFehlenTitel,
        AnalysisFehler.einwilligungFehlt => texte.analyseEinwilligungTitel,
        AnalysisFehler.zugangAbgelehnt => texte.analyseZugangTitel,
      };

  String tipp(L texte) => switch (this) {
        AnalysisFehler.keinInternet => texte.analyseKeinInternetTipp,
        AnalysisFehler.zeitueberschreitung => texte.analyseZeitTipp,
        AnalysisFehler.apiFehler => texte.analyseApiTipp,
        AnalysisFehler.kontingent => texte.analyseKontingentTipp,
        AnalysisFehler.kontingentMonat => texte.kontingentMonatsgrenzeText,
        AnalysisFehler.ungueltigeAntwort => texte.analyseAntwortTipp,
        AnalysisFehler.keinApiKey => texte.analyseKeinSchluesselTipp,
        AnalysisFehler.fotosFehlen => texte.analyseFotosFehlenTipp,
        AnalysisFehler.einwilligungFehlt => texte.analyseEinwilligungTipp,
        AnalysisFehler.zugangAbgelehnt => texte.analyseZugangTipp,
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
  /// [modus] entscheidet, welche Frage der Report beantwortet: den
  /// vorhandenen Look verbessern oder einen neuen entwerfen. Die Fotos und
  /// die Module sind in beiden Faellen dieselben.
  ///
  /// [techniken] sind die Techniken aus „Das will ich ausprobieren". Jede
  /// gewaehlte muss im Report auftauchen – als Empfehlung mit kurzer
  /// Anleitung und als Aufgabe im richtigen Takt (DECISIONS 79). Leer, wenn
  /// der Schritt uebersprungen wurde.
  ///
  /// [abbruch] stoppt Warten und Wiederholen, wenn der Nutzer aufgibt.
  ///
  /// Wirft bei Problemen eine [AnalysisException].
  /// [sprache] bestimmt, in welcher Sprache der Report geschrieben wird.
  /// Sie geht mit an die Cloud Function; ein fertiger Report behaelt sie
  /// danach, auch wenn der Nutzer die App spaeter umstellt.
  Future<AnalysisResult> analysiere({
    required Map<AufnahmeTyp, File> fotos,
    required Set<AnalyseModul> module,
    required OnboardingProfile onboarding,
    required ModulEingaben eingaben,
    required Sprache sprache,
    Richtung richtung = Richtung.leer,
    AnalyseModus modus = AnalyseModus.standard,
    Set<Technik> techniken = const {},
    Abbruch? abbruch,
  });
}
