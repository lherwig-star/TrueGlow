import '../../modules/models/analyse_modul.dart';

/// Welche Hilfslinien im Sucher liegen.
enum Overlaytyp {
  /// Gesichts-Oval mit angedeuteten Schultern.
  gesichtsOval,

  /// Seitenkopf-Kontur mit der Nase nach rechts.
  ///
  /// Bewusst nach der Zeichenrichtung benannt und nicht nach dem Profil: die
  /// Vorschau der Frontkamera spiegelt, deshalb gehoert zum *linken* Profil
  /// (linke Gesichtshaelfte zur Kamera) eine nach rechts zeigende Nase.
  profilNaseRechts,

  /// Dieselbe Kontur gespiegelt, Nase nach links.
  profilNaseLinks,

  /// Halb gedrehter Kopf fuer die 45-Grad-Aufnahme.
  winkel45,

  /// Stehende Ganzkoerper-Silhouette.
  ganzkoerper,

  /// Freies Bild ohne Hilfslinien (Outfit-Fotos).
  keins,
}

/// Wie streng eine Aufnahme geprueft wird.
///
/// Der bisherige Check verlangte immer genau ein Gesicht auf einem Viertel der
/// Bildflaeche. Das passt fuer Portraits, nicht aber fuer Ganzkoerper- oder
/// Outfit-Aufnahmen – dort gibt es entweder ein winziges oder gar kein
/// Gesicht. Deshalb bekommt jede Aufnahme ihr eigenes Profil.
enum Pruefprofil {
  /// Portrait aus der Naehe: Gesicht ist Pflicht und muss das Bild fuellen.
  gesichtNah(gesichtPflicht: true, minFlaeche: 0.25),

  /// Profil und 45-Grad-Winkel: Gesichtserkennung ist bei abgewandtem Kopf
  /// unzuverlaessig, deshalb kein Pflichtfeld. Wird doch eines gefunden, muss
  /// es wenigstens grob die richtige Groesse haben.
  gesichtWeit(gesichtPflicht: false, minFlaeche: 0.08),

  /// Ganzkoerper: nur Helligkeit und Lesbarkeit zaehlen.
  ganzkoerper(gesichtPflicht: false, minFlaeche: 0),

  /// Outfit-Fotos: keine Person noetig, das Kleidungsstueck kann auch auf dem
  /// Buegel haengen.
  frei(gesichtPflicht: false, minFlaeche: 0);

  const Pruefprofil({required this.gesichtPflicht, required this.minFlaeche});

  /// Ob ohne erkanntes Gesicht abgelehnt wird.
  final bool gesichtPflicht;

  /// Mindestanteil der Bildflaeche – nur geprueft, wenn ein Gesicht gefunden
  /// wurde oder [gesichtPflicht] gilt.
  final double minFlaeche;

  bool get pruefeGesicht => gesichtPflicht || minFlaeche > 0;
}

/// Eine einzelne Aufnahme im Flow. Die Reihenfolge der Werte ist zugleich die
/// Reihenfolge im Aufnahme-Flow.
enum AufnahmeTyp {
  // --- Basis ---
  basisFrontal(
    modul: AnalyseModul.basis,
    label: 'Frontalfoto',
    hinweis: 'Schau direkt in die Kamera. Neutrales Gesicht, gutes Licht, '
        'keine Kopfbedeckung.',
    overlay: Overlaytyp.gesichtsOval,
    pruefung: Pruefprofil.gesichtNah,
  ),
  basisProfilLinks(
    modul: AnalyseModul.basis,
    label: 'Profil links',
    hinweis: 'Dreh deinen Kopf nach rechts – deine linke Gesichtshälfte zeigt '
        'zur Kamera. Ohr und Kinnlinie sollten sichtbar sein.',
    overlay: Overlaytyp.profilNaseRechts,
    pruefung: Pruefprofil.gesichtWeit,
  ),
  basisProfilRechts(
    modul: AnalyseModul.basis,
    label: 'Profil rechts',
    hinweis: 'Dreh deinen Kopf nach links – deine rechte Gesichtshälfte zeigt '
        'zur Kamera. Ohr und Kinnlinie sollten sichtbar sein.',
    overlay: Overlaytyp.profilNaseLinks,
    pruefung: Pruefprofil.gesichtWeit,
  ),
  basisWinkel45(
    modul: AnalyseModul.basis,
    label: '45°-Winkel',
    hinweis: 'Dreh deinen Kopf nur halb nach rechts – etwa 45 Grad. Beide '
        'Augen bleiben dabei sichtbar.',
    overlay: Overlaytyp.winkel45,
    pruefung: Pruefprofil.gesichtWeit,
  ),

  // --- Haut & Farbtyp ---
  // Kein eigenes Foto mehr: Die Hautton-Einschaetzung liest das Frontalfoto
  // der Basis mit. Siehe DECISIONS.md, "Hautton ohne eigenes Foto".

  // --- Zaehne & Laecheln ---
  zaehneLaecheln(
    modul: AnalyseModul.zaehneLaecheln,
    label: 'Lächeln',
    hinweis: 'Frontal in die Kamera lächeln, sodass die Zähne gut sichtbar '
        'sind.',
    overlay: Overlaytyp.gesichtsOval,
    pruefung: Pruefprofil.gesichtNah,
  ),

  // --- Figur & Passform ---
  figurGanzkoerperFrontal(
    modul: AnalyseModul.figurPassform,
    label: 'Ganzkörper frontal',
    hinweis: 'Ganzer Körper im Bild, gerade stehen, Arme locker seitlich. '
        'Eng anliegende Kleidung zeigt die Silhouette am besten.',
    overlay: Overlaytyp.ganzkoerper,
    pruefung: Pruefprofil.ganzkoerper,
    rueckkamera: true,
  ),
  figurGanzkoerperSeitlich(
    modul: AnalyseModul.figurPassform,
    label: 'Ganzkörper seitlich',
    hinweis: 'Dieselbe Haltung um 90 Grad gedreht – so sieht man Haltung und '
        'Proportionen von der Seite.',
    overlay: Overlaytyp.ganzkoerper,
    pruefung: Pruefprofil.ganzkoerper,
    rueckkamera: true,
  ),

  // --- Stil & Kleiderschrank ---
  stilOutfitEins(
    modul: AnalyseModul.stilKleiderschrank,
    label: 'Outfit 1',
    hinweis: 'Ein Outfit, das du oft trägst – am Körper oder ausgelegt.',
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    rueckkamera: true,
  ),
  stilOutfitZwei(
    modul: AnalyseModul.stilKleiderschrank,
    label: 'Outfit 2',
    hinweis: 'Ein zweites Outfit, gern aus einem anderen Anlass.',
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    rueckkamera: true,
  ),
  stilOutfitDrei(
    modul: AnalyseModul.stilKleiderschrank,
    label: 'Outfit 3',
    hinweis: 'Optional: ein drittes Outfit. Du kannst diesen Schritt auch '
        'überspringen.',
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    rueckkamera: true,
    optional: true,
  );

  const AufnahmeTyp({
    required this.modul,
    required this.label,
    required this.hinweis,
    required this.overlay,
    required this.pruefung,
    this.rueckkamera = false,
    this.optional = false,
  });

  final AnalyseModul modul;
  final String label;
  final String hinweis;
  final Overlaytyp overlay;
  final Pruefprofil pruefung;

  /// Startet die Kamera mit der Rueckkamera – bei Ganzkoerper- und
  /// Outfit-Aufnahmen fotografiert ohnehin jemand anderes oder ein Spiegel.
  final bool rueckkamera;

  /// Darf uebersprungen werden, ohne den Flow zu blockieren.
  final bool optional;

  /// Ob die Live-Erkennung im Sucher sinnvoll ist.
  bool get mitLiveHilfe => pruefung.pruefeGesicht;

  /// Der Hinweistext, abhaengig von den gewaehlten Modulen.
  ///
  /// Nur ein Fall weicht ab: Das Frontalfoto traegt seit dem Wegfall der
  /// Hautton-Nahaufnahme deren Lichtbedingungen mit – aber nur, wenn „Haut &
  /// Farbtyp" ueberhaupt gewaehlt ist. Wer das Modul nicht gebucht hat, soll
  /// nicht mit Anforderungen belastet werden, die fuer seine Analyse nichts
  /// aendern.
  String hinweisFuer(Set<AnalyseModul> module) =>
      this == AufnahmeTyp.basisFrontal &&
              module.contains(AnalyseModul.hautFarbtyp)
          ? '$hinweis\n\n$hautLichtZusatz'
          : hinweis;

  /// Warum das Frontalfoto mit gewaehltem Haut-Modul mehr Gewicht hat.
  ///
  /// Bewusst **keine** Wiederholung der Lichtregeln: Die stehen wortgleich in
  /// der Licht-Checkliste (`licht_checkliste.dart`), die ohnehin vor dem
  /// ersten Foto laeuft. Doppelter Text liest sich wie eine neue Anforderung
  /// und wird dann ueberlesen. Hier zaehlt nur die Verknuepfung.
  static const String hautLichtZusatz =
      'Dieses Foto wertet auch die Hautanalyse aus. Das Tageslicht aus der '
      'Checkliste zählt hier deshalb doppelt.';
}

/// Die Aufnahmen eines Moduls in Flow-Reihenfolge.
extension AnalyseModulAufnahmen on AnalyseModul {
  List<AufnahmeTyp> get aufnahmen =>
      AufnahmeTyp.values.where((t) => t.modul == this).toList();

  /// Kurztext fuer die Modul-Karte: was an Material gebraucht wird.
  String get benoetigt => switch (this) {
        AnalyseModul.basis =>
          'Frontal, beide Seitenprofile und 45°-Winkel.',
        AnalyseModul.hautFarbtyp =>
          'Keine eigene Aufnahme – nutzt das Frontalfoto der Basis. Mach es '
              'bei indirektem Tageslicht.',
        AnalyseModul.zaehneLaecheln => '1 Foto lächelnd.',
        AnalyseModul.figurPassform =>
          '2 Ganzkörperfotos (frontal + seitlich) sowie Körpergröße und '
              'Gewicht.',
        AnalyseModul.stilKleiderschrank =>
          '2–3 Outfit-Fotos und ein paar kurze Fragen.',
      };
}
