import '../../../core/l10n/sprache.dart';
import '../../capture/models/aufnahme_typ.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';

/// Baut die Nutzlast fuer die Cloud Function `analysiere`.
///
/// Der Prompt selbst liegt seit dem Umbau auf dem Server. Hierher gehoert nur
/// noch die Frage, *welche* Angaben ueberhaupt das Geraet verlassen – und das
/// ist bewusst eine kurze Liste:
///
/// - die Zielsprache des Reports,
/// - Modulauswahl und Aufnahmetypen als stabile Namen,
/// - die Antworten aus Onboarding, Modul-Fragebogen und Richtung,
/// - die Bilder als base64.
///
/// Ausdruecklich **nicht** dabei: Dateipfade, Geraetekennungen, der
/// Zustimmungsstatus oder irgendetwas, das der Prompt nicht braucht.
class AnalyseAnfrage {
  AnalyseAnfrage._();

  static Map<String, dynamic> bauen({
    required Map<AufnahmeTyp, String> bilder,
    required Set<AnalyseModul> module,
    required OnboardingProfile onboarding,
    required ModulEingaben eingaben,
    required Sprache sprache,
    Richtung richtung = Richtung.leer,
  }) {
    // Feste Reihenfolge, damit die Beschriftung im Prompt zu den angehaengten
    // Bildern passt.
    final reihenfolge = AufnahmeTyp.values.where(bilder.containsKey).toList();

    return {
      // Die Sprache des Reports. Sie steckt nicht in den Profilangaben,
      // weil sie keine Angabe ueber die Person ist, sondern eine ueber die
      // Ausgabe – und weil der Server sie an genau einer Stelle prueft.
      'sprache': sprache.code,
      // Wonach der Report ausgerichtet wird. Abgeleitet aus der Angabe im
      // Onboarding – die Angabe selbst („divers", „keine Angabe") bleibt auf
      // dem Geraet, der Server sieht nur die Entscheidung daraus.
      'ausrichtung': onboarding.geschlecht.ausrichtung.name,
      'module': AnalyseModul.values
          .where(module.contains)
          .map((m) => m.name)
          .toList(),
      'profil': {
        'alter': onboarding.alter?.name,
        'budget': onboarding.budget?.name,
        'zeit': onboarding.zeit?.name,
        'fokus': onboarding.fokus.map((f) => f.name).toList(),
      },
      'eingaben': eingaben.toJson(),
      'richtung': richtung.toJson(),
      'bilder': [
        for (final typ in reihenfolge)
          {'typ': typ.name, 'daten': bilder[typ]},
      ],
    };
  }
}
