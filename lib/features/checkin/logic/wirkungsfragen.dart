import '../../modules/models/analyse_modul.dart';
import '../models/checkin.dart';
import '../../../core/l10n/texte.dart';

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
    ),
    WirkungsFrage(
      id: 'hautGefuehl',
      modul: AnalyseModul.hautFarbtyp,
    ),
    WirkungsFrage(
      id: 'zaehneGefuehl',
      modul: AnalyseModul.zaehneLaecheln,
    ),
    WirkungsFrage(
      id: 'haltungGefuehl',
      modul: AnalyseModul.figurPassform,
    ),
    WirkungsFrage(
      id: 'anziehen',
      modul: AnalyseModul.stilKleiderschrank,
    ),
  ];

  /// Tag 30 und danach: Ergebnisfragen pro Bereich.
  static const _wirkung = [
    WirkungsFrage(
      id: 'basisErgebnis',
      modul: AnalyseModul.basis,
    ),
    WirkungsFrage(
      id: 'hautErgebnis',
      modul: AnalyseModul.hautFarbtyp,
    ),
    WirkungsFrage(
      id: 'zaehneErgebnis',
      modul: AnalyseModul.zaehneLaecheln,
    ),
    WirkungsFrage(
      id: 'figurErgebnis',
      modul: AnalyseModul.figurPassform,
    ),
    WirkungsFrage(
      id: 'stilErgebnis',
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
  static String erwartung(Set<AnalyseModul> module, L texte) {
    if (module.contains(AnalyseModul.hautFarbtyp)) return texte.einordnungHaut;
    if (module.contains(AnalyseModul.zaehneLaecheln)) {
      return texte.einordnungZaehne;
    }
    if (module.contains(AnalyseModul.figurPassform)) {
      return texte.einordnungHaltung;
    }
    if (module.contains(AnalyseModul.stilKleiderschrank)) {
      return texte.einordnungStil;
    }
    return texte.einordnungBasis;
  }
}
