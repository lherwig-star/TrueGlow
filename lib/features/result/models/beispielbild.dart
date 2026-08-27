/// Ein Beispielfoto zu einem Vorschlag im Report – DECISIONS 69.
///
/// Kommt von der Function `bilderSuchen`, die ihrerseits bei Pexels fragt.
/// Hier stehen nur Adressen und Namen; die Bilddatei selbst laedt die App
/// direkt beim Bildhoster, sie laeuft nie durch unseren Server.
///
/// [fotograf] und [quelle] sind Pflicht und kein Beiwerk: Die Pexels-Lizenz
/// verlangt die Nennung mit Link zurueck. Ein Bild, bei dem eines von beidem
/// fehlt, kommt schon auf dem Server nicht durch – und wird hier ein zweites
/// Mal abgewiesen, damit die Regel an der Stelle steht, an der sie angezeigt
/// wird.
class Beispielbild {
  const Beispielbild({
    required this.vorschau,
    required this.gross,
    required this.fotograf,
    required this.quelle,
    this.beschreibung = '',
  });

  /// Kleine Fassung fuer die Reihe unter dem Vorschlag.
  final String vorschau;

  /// Groessere Fassung fuer die Vollbildansicht.
  final String gross;

  /// Wer das Foto gemacht hat.
  final String fotograf;

  /// Die Seite beim Bildhoster, auf die die Nennung verlinkt.
  final String quelle;

  /// Die Bildbeschreibung des Hosters – fuer die Sprachausgabe.
  final String beschreibung;

  /// Ob es ueberhaupt eine Bilddatei zu laden gibt.
  ///
  /// Im Demo-Modus nicht: Dort gibt es kein Backend und damit keine echten
  /// Fotos. Die Reihe zeigt dann gezeichnete Platzhalter – dieselben, die
  /// auch beim Laden und bei einem Ladefehler stehen.
  bool get hatDatei => vorschau.isNotEmpty;

  static Beispielbild? ausJson(Object? roh) {
    if (roh is! Map) return null;

    String feld(String name) {
      final wert = roh[name];
      return wert is String ? wert.trim() : '';
    }

    final fotograf = feld('fotograf');
    final quelle = feld('quelle');
    if (fotograf.isEmpty || quelle.isEmpty) return null;

    final vorschau = feld('vorschau');
    final gross = feld('gross');
    if (vorschau.isEmpty) return null;

    return Beispielbild(
      vorschau: vorschau,
      gross: gross.isEmpty ? vorschau : gross,
      fotograf: fotograf,
      quelle: quelle,
      beschreibung: feld('beschreibung'),
    );
  }

  /// Liest die Liste zu einem Suchbegriff; alles Unlesbare faellt weg.
  static List<Beispielbild> listeAus(Object? roh) {
    if (roh is! List) return const [];
    return [
      for (final eintrag in roh) ?ausJson(eintrag),
    ];
  }

  /// Liest die Antwort der Function: Suchbegriff → Bilder.
  static Map<String, List<Beispielbild>> tabelleAus(Object? roh) {
    if (roh is! Map) return const {};

    final tabelle = <String, List<Beispielbild>>{};
    for (final eintrag in roh.entries) {
      final begriff = eintrag.key;
      if (begriff is! String) continue;
      tabelle[begriff] = listeAus(eintrag.value);
    }
    return tabelle;
  }
}
