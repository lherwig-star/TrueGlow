// Bewusst ohne Flutter-Abhaengigkeit: tool/rechtstexte_pruefen.dart laeuft als
// reines Dart-Skript vor dem Release-Build und muss diese Datei lesen koennen.

/// Die drei Pflichtdokumente.
///
/// Die Reihenfolge ist die Anzeigereihenfolge; die Datenschutzerklaerung steht
/// oben, weil Play sie ausdruecklich verlangt und Nutzer sie am haeufigsten
/// suchen.
enum Rechtsdokument {
  datenschutz(
    titel: 'Datenschutzerklärung',
    beschreibung: 'Welche Daten wir verarbeiten, wozu und wie lange.',
  ),
  nutzungsbedingungen(
    titel: 'Nutzungsbedingungen',
    beschreibung: 'Die Regeln für die Nutzung von TrueGlow.',
  ),
  impressum(
    titel: 'Impressum',
    beschreibung: 'Wer hinter der App steht und wie du uns erreichst.',
  );

  const Rechtsdokument({required this.titel, required this.beschreibung});

  final String titel;
  final String beschreibung;

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
  const Rechtsquelle({this.url, this.asset});

  /// Oeffentliche Adresse des Dokuments. Play verlangt für die
  /// Datenschutzerklärung zwingend eine solche URL.
  final String? url;

  /// Pfad eines Markdown-Assets im Bundle, z. B.
  /// `assets/rechtstexte/datenschutz.md`.
  final String? asset;

  bool get hatUrl => (url ?? '').trim().isNotEmpty;
  bool get hatAsset => (asset ?? '').trim().isNotEmpty;

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
  /// `0-entwurf` heißt ausdrücklich: Es gibt noch keine verbindlichen Texte.
  static const String version = '0-entwurf';

  /// Ab dieser Version gelten die Texte als verbindlich. Bis dahin ist der
  /// Zustand „Entwurf" und die Prüfung schlägt an.
  static bool get istEntwurf => version.endsWith('-entwurf');

  /// Die Quellen je Dokument.
  ///
  /// **Zum Ausfüllen:** URL eintragen (Play braucht sie), optional zusätzlich
  /// eine Markdown-Datei unter `assets/rechtstexte/` ablegen und in
  /// `pubspec.yaml` als Asset eintragen.
  static const Map<Rechtsdokument, Rechtsquelle> quellen = {
    Rechtsdokument.datenschutz: Rechtsquelle(
      // url: 'https://trueglow.app/datenschutz',
      // asset: 'assets/rechtstexte/datenschutz.md',
    ),
    Rechtsdokument.nutzungsbedingungen: Rechtsquelle(
      // url: 'https://trueglow.app/agb',
      // asset: 'assets/rechtstexte/agb.md',
    ),
    Rechtsdokument.impressum: Rechtsquelle(
      // url: 'https://trueglow.app/impressum',
      // asset: 'assets/rechtstexte/impressum.md',
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
      teile.add('ohne Quelle: ${fehlende.map((d) => d.titel).join(', ')}');
    }
    if (istEntwurf) {
      teile.add('Textversion steht noch auf "$version"');
    }
    return 'Rechtstexte unvollständig – ${teile.join('; ')}. '
        'Einzutragen in lib/features/legal/logic/rechtstexte.dart.';
  }
}
