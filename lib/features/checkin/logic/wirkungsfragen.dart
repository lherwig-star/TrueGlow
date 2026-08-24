import '../../modules/models/analyse_modul.dart';
import '../models/checkin.dart';

/// Die Fragen zur Wirkung – getrennt nach dem, was frueh ueberhaupt spuerbar
/// ist, und dem, was sich erst nach Wochen zeigt.
///
/// Bewusst eine eigene Datei: Welche Frage wann erlaubt ist, ist die
/// inhaltliche Kernregel des Features und soll nicht in einem Screen
/// verschwinden.
class Wirkungsfragen {
  Wirkungsfragen._();

  /// Hoechstzahl der Fragen pro Check-in – der ganze Check-in soll unter einer
  /// Minute bleiben.
  static const maxFragen = 3;

  /// Tag 14: nur Schnell-Effekte. Nichts, was Wochen braucht (Haarwuchs,
  /// Hautbild im Spiegel, Koerperform).
  static const _frueh = [
    WirkungsFrage(
      id: 'routine',
      text: 'Wie gut läuft deine Morgenroutine?',
    ),
    WirkungsFrage(
      id: 'hautGefuehl',
      text: 'Wie fühlt sich deine Haut an?',
      modul: AnalyseModul.hautFarbtyp,
    ),
    WirkungsFrage(
      id: 'zaehneGefuehl',
      text: 'Wie sauber fühlen sich deine Zähne an?',
      modul: AnalyseModul.zaehneLaecheln,
    ),
    WirkungsFrage(
      id: 'haltungGefuehl',
      text: 'Wie bewusst nimmst du deine Haltung wahr?',
      modul: AnalyseModul.figurPassform,
    ),
    WirkungsFrage(
      id: 'anziehen',
      text: 'Wie leicht fällt dir das Anziehen morgens?',
      modul: AnalyseModul.stilKleiderschrank,
    ),
  ];

  /// Tag 30 und danach: Ergebnisfragen pro Bereich.
  static const _wirkung = [
    WirkungsFrage(
      id: 'basisErgebnis',
      text: 'Wie haben sich Frisur und Bart entwickelt?',
      modul: AnalyseModul.basis,
    ),
    WirkungsFrage(
      id: 'hautErgebnis',
      text: 'Wie hat sich dein Hautbild entwickelt?',
      modul: AnalyseModul.hautFarbtyp,
    ),
    WirkungsFrage(
      id: 'zaehneErgebnis',
      text: 'Wie haben sich Zähne und Lächeln entwickelt?',
      modul: AnalyseModul.zaehneLaecheln,
    ),
    WirkungsFrage(
      id: 'figurErgebnis',
      text: 'Wie hat sich deine Haltung entwickelt?',
      modul: AnalyseModul.figurPassform,
    ),
    WirkungsFrage(
      id: 'stilErgebnis',
      text: 'Wie gut funktionieren deine Outfits inzwischen?',
      modul: AnalyseModul.stilKleiderschrank,
    ),
  ];

  /// Die Fragen dieses Check-ins, passend zu den Modulen des Reports.
  ///
  /// Tag 7 bekommt keine – dort geht es ausschliesslich um Machbarkeit.
  static List<WirkungsFrage> fuer(CheckinTyp typ, Set<AnalyseModul> module) {
    final quelle = switch (typ) {
      CheckinTyp.alltag => const <WirkungsFrage>[],
      CheckinTyp.zwischen => _frueh,
      CheckinTyp.wirkung => _wirkung,
    };

    final passend = quelle
        .where((f) => f.modul == null || module.contains(f.modul))
        .toList();

    // Beim Wirkungs-Check zaehlt jeder Bereich, beim Zwischencheck reichen
    // wenige weiche Fragen.
    if (typ == CheckinTyp.wirkung) return passend;
    return passend.take(maxFragen).toList();
  }

  /// Erwartungsmanagement fuer den Zwischencheck: was jetzt noch nicht zu
  /// sehen sein kann. Der Text richtet sich nach dem Modul, bei dem die
  /// Ungeduld am groessten ist.
  static String erwartung(Set<AnalyseModul> module) {
    if (module.contains(AnalyseModul.hautFarbtyp)) {
      return 'Sichtbare Hautveränderungen zeigen sich meist ab Woche 4–6 – '
          'du bist auf Kurs.';
    }
    if (module.contains(AnalyseModul.zaehneLaecheln)) {
      return 'Verfärbungen gehen langsam zurück: Der Unterschied wird meist '
          'ab Woche 4 sichtbar – du bist auf Kurs.';
    }
    if (module.contains(AnalyseModul.figurPassform)) {
      return 'Haltung ändert sich über Wochen, nicht über Tage – ab Woche 4 '
          'bis 6 fällt es auch anderen auf. Du bist auf Kurs.';
    }
    if (module.contains(AnalyseModul.stilKleiderschrank)) {
      return 'Ein Kleiderschrank verändert sich Stück für Stück – nach vier '
          'bis sechs Wochen greift die neue Kombination von selbst.';
    }
    return 'Haare wachsen rund einen Zentimeter im Monat – die neue Form '
        'zeigt sich ab Woche 4. Du bist auf Kurs.';
  }
}
