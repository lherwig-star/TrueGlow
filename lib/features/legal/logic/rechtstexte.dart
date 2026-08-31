// Bewusst ohne Flutter-Abhaengigkeit: tool/rechtstexte_pruefen.dart laeuft als
// reines Dart-Skript vor dem Release-Build und muss diese Datei lesen koennen.
//
// Deshalb steht hier auch kein einziger Anzeigetext mehr. Titel und
// Beschreibung der Dokumente liegen in `ui/rechtsdokument_texte.dart` – der
// Umweg kostet eine Datei und haelt dieses Modul frei von Flutter.

/// Die drei Pflichtdokumente.
///
/// Die Reihenfolge ist die Anzeigereihenfolge; die Datenschutzerklaerung steht
/// oben, weil Play sie ausdruecklich verlangt und Nutzer sie am haeufigsten
/// suchen.
enum Rechtsdokument {
  datenschutz,
  nutzungsbedingungen,
  impressum;

  /// Stabiler Name fuer Routen und gespeicherte Einwilligungen.
  String get schluessel => name;

  static Rechtsdokument? ausName(String? name) {
    for (final dokument in values) {
      if (dokument.name == name) return dokument;
    }
    return null;
  }
}

/// Wo ein Rechtstext herkommt.
///
/// Beides ist optional und beides darf gleichzeitig gesetzt sein: Dann oeffnet
/// die App die Webseite und haelt den mitgelieferten Text als Rueckfallebene
/// bereit — praktisch, wenn jemand offline nachlesen will.
class Rechtsquelle {
  const Rechtsquelle({this.url, this.asset, this.assetEn});

  /// Oeffentliche Adresse des Dokuments. Play verlangt für die
  /// Datenschutzerklärung zwingend eine solche URL.
  final String? url;

  /// Pfad des deutschen Markdown-Assets im Bundle, z. B.
  /// `assets/rechtstexte/datenschutz_de.md`.
  final String? asset;

  /// Dasselbe auf Englisch. Fehlt es, wird die deutsche Fassung gezeigt –
  /// besser ein Text in der falschen Sprache als gar keiner.
  final String? assetEn;

  bool get hatUrl => (url ?? '').trim().isNotEmpty;
  bool get hatAsset => (asset ?? '').trim().isNotEmpty;

  /// Der Pfad zur Fassung in dieser Sprache.
  ///
  /// [sprachcode] ist der ISO-Code der App-Sprache (`de`, `en`).
  String? fuer(String sprachcode) {
    if (sprachcode == 'en' && (assetEn ?? '').trim().isNotEmpty) {
      return assetEn;
    }
    return hatAsset ? asset : null;
  }

  /// Ob das Dokument ueberhaupt anzeigbar ist.
  bool get vorhanden => hatUrl || hatAsset;
}

/// Die zentrale Stelle für alle Rechtstexte.
///
/// Hier — und nur hier — trägst du später die URLs bzw. die Markdown-Dateien
/// ein. Der Rest der App liest ausschließlich über diese Klasse; kein Screen
/// kennt eine Adresse.
///
/// **Was noch fehlt:** Bis die Texte aus dem Generator da sind, sind alle
/// Quellen leer. Die App zeigt dann in „Rechtliches" einen ehrlichen
/// „Noch nicht verfügbar"-Zustand statt eines toten Links. `tool/rechtstexte_pruefen.dart`
/// bricht einen Release-Build ab, solange etwas fehlt.
class Rechtstexte {
  Rechtstexte._();

  /// Version der Rechtstexte, die eine Einwilligung bestätigt.
  ///
  /// Sie wird bei jeder Einwilligung mitgespeichert (Phase 2.2). Ändern sich
  /// die Texte inhaltlich, wird diese Nummer erhöht — dann gilt die alte
  /// Einwilligung nicht mehr und die App fragt erneut.
  ///
  /// Die Endung `-entwurf` heißt ausdrücklich: Es gibt Texte, aber noch
  /// keine geprüften. `tool/rechtstexte_pruefen.dart` bricht einen
  /// Release-Build ab, solange sie dransteht.
  ///
  /// **Warum trotzdem `1-` und nicht mehr `0-`:** Seit SECURITY_AUDIT F2
  /// liegen alle drei Dokumente als vollständige Entwürfe bei. Die erhöhte
  /// Nummer sorgt dafür, dass jeder, der vorher zugestimmt hat, die
  /// Zustimmung erneut gibt — er hat damals nämlich einem leeren
  /// „Noch nicht verfügbar" zugestimmt. Verbindlich werden die Texte erst
  /// mit der juristischen Prüfung, und dann fällt das `-entwurf` weg.
  static const String version = '1-entwurf';

  /// Ab dieser Version gelten die Texte als verbindlich. Bis dahin ist der
  /// Zustand „Entwurf" und die Prüfung schlägt an.
  static bool get istEntwurf => version.endsWith('-entwurf');

  /// Die Quellen je Dokument.
  ///
  /// **Zum Ausfüllen:** URL eintragen (Play braucht sie), optional zusätzlich
  /// eine Markdown-Datei unter `assets/rechtstexte/` ablegen und in
  /// `pubspec.yaml` als Asset eintragen.
  /// **Die URLs fehlen noch mit Absicht.** Play verlangt für die
  /// Datenschutzerklärung eine öffentlich erreichbare Adresse; die gibt es
  /// erst, wenn die Seite steht (SETUP 11). Bis dahin liest man die Texte
  /// in der App.
  static const Map<Rechtsdokument, Rechtsquelle> quellen = {
    Rechtsdokument.datenschutz: Rechtsquelle(
      asset: 'assets/rechtstexte/datenschutz_de.md',
      assetEn: 'assets/rechtstexte/datenschutz_en.md',
    ),
    Rechtsdokument.nutzungsbedingungen: Rechtsquelle(
      asset: 'assets/rechtstexte/nutzungsbedingungen_de.md',
      assetEn: 'assets/rechtstexte/nutzungsbedingungen_en.md',
    ),
    Rechtsdokument.impressum: Rechtsquelle(
      asset: 'assets/rechtstexte/impressum_de.md',
      assetEn: 'assets/rechtstexte/impressum_en.md',
    ),
  };

  static Rechtsquelle quelle(Rechtsdokument dokument) =>
      quellen[dokument] ?? const Rechtsquelle();

  /// Die Dokumente, die noch keine Quelle haben.
  static List<Rechtsdokument> get fehlende => [
        for (final dokument in Rechtsdokument.values)
          if (!quelle(dokument).vorhanden) dokument,
      ];

  /// Ob alle drei Dokumente hinterlegt sind **und** die Version verbindlich
  /// ist. Nur dann ist die App einreichungsfähig.
  static bool get vollstaendig => fehlende.isEmpty && !istEntwurf;

  /// Ein Satz für Menschen, was noch fehlt.
  static String get fehlerbericht {
    if (vollstaendig) return 'Alle Rechtstexte sind hinterlegt.';

    final teile = <String>[];
    if (fehlende.isNotEmpty) {
      teile.add('ohne Quelle: ${fehlende.map((d) => d.name).join(', ')}');
    }
    if (istEntwurf) {
      teile.add('Textversion steht noch auf "$version"');
    }
    return 'Rechtstexte unvollständig – ${teile.join('; ')}. '
        'Einzutragen in lib/features/legal/logic/rechtstexte.dart.';
  }
}
