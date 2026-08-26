import '../../modules/models/analyse_modul.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../../../core/l10n/texte.dart';

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

  /// Stehende Ganzkoerper-Silhouette von vorn.
  ganzkoerperFrontal,

  /// Dieselbe Figur im Profil, Blickrichtung rechts.
  ganzkoerperSeitlich,

  /// Weibliche Fassung derselben beiden Umrisse.
  ///
  /// Warum ueberhaupt eine zweite Figur: Der Umriss ist eine Anweisung, wie
  /// weit man zuruecktreten und wie man stehen soll. Wer sich an einer Figur
  /// ausrichten soll, die anders gebaut ist als er selbst, richtet sich
  /// schlechter aus – und die Schulter-Huefte-Verhaeltnisse sind genau das,
  /// was das Ganzkoerperfoto zeigen soll.
  ganzkoerperFrontalWeiblich,
  ganzkoerperSeitlichWeiblich,

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
    overlay: Overlaytyp.gesichtsOval,
    pruefung: Pruefprofil.gesichtNah,
  ),
  basisProfilLinks(
    modul: AnalyseModul.basis,
    overlay: Overlaytyp.profilNaseRechts,
    pruefung: Pruefprofil.gesichtWeit,
  ),
  basisProfilRechts(
    modul: AnalyseModul.basis,
    overlay: Overlaytyp.profilNaseLinks,
    pruefung: Pruefprofil.gesichtWeit,
  ),
  basisWinkel45(
    modul: AnalyseModul.basis,
    overlay: Overlaytyp.winkel45,
    pruefung: Pruefprofil.gesichtWeit,
  ),

  // --- Haut & Farbtyp ---
  // Kein eigenes Foto mehr: Die Hautton-Einschaetzung liest das Frontalfoto
  // der Basis mit. Siehe DECISIONS.md, "Hautton ohne eigenes Foto".

  // --- Zaehne & Laecheln ---
  zaehneLaecheln(
    modul: AnalyseModul.zaehneLaecheln,
    overlay: Overlaytyp.gesichtsOval,
    pruefung: Pruefprofil.gesichtNah,
  ),

  // --- Figur & Passform ---
  figurGanzkoerperFrontal(
    modul: AnalyseModul.figurPassform,
    overlay: Overlaytyp.ganzkoerperFrontal,
    pruefung: Pruefprofil.ganzkoerper,
    rueckkamera: true,
    autoAusloeser: true,
  ),
  figurGanzkoerperSeitlich(
    modul: AnalyseModul.figurPassform,
    overlay: Overlaytyp.ganzkoerperSeitlich,
    pruefung: Pruefprofil.ganzkoerper,
    rueckkamera: true,
    autoAusloeser: true,
  ),

  // --- Stil & Kleiderschrank ---
  stilOutfitEins(
    modul: AnalyseModul.stilKleiderschrank,
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    rueckkamera: true,
  ),
  stilOutfitZwei(
    modul: AnalyseModul.stilKleiderschrank,
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    rueckkamera: true,
  ),
  stilOutfitDrei(
    modul: AnalyseModul.stilKleiderschrank,
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    rueckkamera: true,
    optional: true,
  );

  const AufnahmeTyp({
    required this.modul,
    required this.overlay,
    required this.pruefung,
    this.rueckkamera = false,
    this.optional = false,
    this.autoAusloeser = false,
  });

  final AnalyseModul modul;

  /// Die Hilfslinien im Sucher – die neutrale Fassung.
  ///
  /// Fuer die tatsaechlich gezeigte Fassung [overlayFuer] benutzen: Bei den
  /// Ganzkoerperfotos haengt sie an der Ausrichtung.
  final Overlaytyp overlay;
  final Pruefprofil pruefung;

  /// Startet die Kamera mit der Rueckkamera – bei Ganzkoerper- und
  /// Outfit-Aufnahmen fotografiert ohnehin jemand anderes oder ein Spiegel.
  final bool rueckkamera;

  /// Darf uebersprungen werden, ohne den Flow zu blockieren.
  final bool optional;

  /// Ob die App selbst ausloest, sobald jemand vollstaendig im Bild steht.
  ///
  /// Nur bei den Ganzkoerperfotos: Dort stellt man das Handy ab und tritt
  /// mehrere Meter zurueck – der Ausloeser ist von dort nicht erreichbar.
  /// Bei allen anderen Aufnahmen haelt man das Geraet in der Hand, und ein
  /// Automatismus waere nur ein Foto zum falschen Zeitpunkt.
  final bool autoAusloeser;

  /// Die Hilfslinien, die im Sucher wirklich liegen.
  ///
  /// Nur die beiden Ganzkoerper-Umrisse haben eine weibliche Fassung. Das
  /// Gesichts-Oval hat keine: Gesichtsformen unterscheiden sich zwischen
  /// Menschen mehr als zwischen Geschlechtern, und ein zweites Oval waere
  /// eine Aussage ohne Grundlage.
  Overlaytyp overlayFuer(Ausrichtung ausrichtung) {
    if (ausrichtung != Ausrichtung.weiblich) return overlay;
    return switch (overlay) {
      Overlaytyp.ganzkoerperFrontal => Overlaytyp.ganzkoerperFrontalWeiblich,
      Overlaytyp.ganzkoerperSeitlich => Overlaytyp.ganzkoerperSeitlichWeiblich,
      _ => overlay,
    };
  }

  /// Ob die Live-Erkennung im Sucher sinnvoll ist.
  bool get mitLiveHilfe => pruefung.pruefeGesicht;

  /// Ob ueberhaupt ein Bildstrom laufen muss.
  ///
  /// Gesichtserkennung fuer die Portraits, Posenerkennung fuer die
  /// Ganzkoerperfotos – Outfit-Aufnahmen brauchen keins von beidem und
  /// bekommen deshalb auch keinen Strom.
  bool get mitBildstrom => mitLiveHilfe || autoAusloeser;

  /// Der Hinweistext, abhaengig von den gewaehlten Modulen.
  ///
  /// Nur ein Fall weicht ab: Das Frontalfoto traegt seit dem Wegfall der
  /// Hautton-Nahaufnahme deren Lichtbedingungen mit – aber nur, wenn „Haut &
  /// Farbtyp" ueberhaupt gewaehlt ist. Wer das Modul nicht gebucht hat, soll
  /// nicht mit Anforderungen belastet werden, die fuer seine Analyse nichts
  /// aendern.
  String hinweisFuer(Set<AnalyseModul> module, L texte) =>
      this == AufnahmeTyp.basisFrontal &&
              module.contains(AnalyseModul.hautFarbtyp)
          ? '${hinweis(texte)}\n\n${texte.aufnahmeHautLichtZusatz}'
          : hinweis(texte);

}

// Anzeigetexte als Erweiterung – Begruendung in `features/onboarding/models/onboarding_profile.dart`.
///
/// Warum das Frontalfoto mit gewaehltem Haut-Modul einen Zusatz bekommt:
/// Bewusst **keine** Wiederholung der Lichtregeln – die stehen wortgleich in
/// der Licht-Checkliste (`licht_checkliste.dart`), die ohnehin vor dem ersten
/// Foto laeuft. Doppelter Text liest sich wie eine neue Anforderung und wird
/// dann ueberlesen. Der Zusatz nennt nur die Verknuepfung.
extension AufnahmeTypText on AufnahmeTyp {
  String label(L texte) => switch (this) {
        AufnahmeTyp.basisFrontal => texte.aufnahmeBasisFrontalLabel,
        AufnahmeTyp.basisProfilLinks => texte.aufnahmeProfilLinksLabel,
        AufnahmeTyp.basisProfilRechts => texte.aufnahmeProfilRechtsLabel,
        AufnahmeTyp.basisWinkel45 => texte.aufnahmeWinkelLabel,
        AufnahmeTyp.zaehneLaecheln => texte.aufnahmeLaechelnLabel,
        AufnahmeTyp.figurGanzkoerperFrontal =>
          texte.aufnahmeGanzkoerperFrontalLabel,
        AufnahmeTyp.figurGanzkoerperSeitlich =>
          texte.aufnahmeGanzkoerperSeitlichLabel,
        AufnahmeTyp.stilOutfitEins => texte.aufnahmeOutfitEinsLabel,
        AufnahmeTyp.stilOutfitZwei => texte.aufnahmeOutfitZweiLabel,
        AufnahmeTyp.stilOutfitDrei => texte.aufnahmeOutfitDreiLabel,
      };

  String hinweis(L texte) => switch (this) {
        AufnahmeTyp.basisFrontal => texte.aufnahmeBasisFrontalHinweis,
        AufnahmeTyp.basisProfilLinks => texte.aufnahmeProfilLinksHinweis,
        AufnahmeTyp.basisProfilRechts => texte.aufnahmeProfilRechtsHinweis,
        AufnahmeTyp.basisWinkel45 => texte.aufnahmeWinkelHinweis,
        AufnahmeTyp.zaehneLaecheln => texte.aufnahmeLaechelnHinweis,
        AufnahmeTyp.figurGanzkoerperFrontal =>
          texte.aufnahmeGanzkoerperFrontalHinweis,
        AufnahmeTyp.figurGanzkoerperSeitlich =>
          texte.aufnahmeGanzkoerperSeitlichHinweis,
        AufnahmeTyp.stilOutfitEins => texte.aufnahmeOutfitEinsHinweis,
        AufnahmeTyp.stilOutfitZwei => texte.aufnahmeOutfitZweiHinweis,
        AufnahmeTyp.stilOutfitDrei => texte.aufnahmeOutfitDreiHinweis,
      };
}

/// Die Aufnahmen eines Moduls in Flow-Reihenfolge.
extension AnalyseModulAufnahmen on AnalyseModul {
  List<AufnahmeTyp> get aufnahmen =>
      AufnahmeTyp.values.where((t) => t.modul == this).toList();

  /// Kurztext fuer die Modul-Karte: was an Material gebraucht wird.
  String benoetigt(L texte, Ausrichtung ausrichtung) => switch (this) {
        AnalyseModul.basis => ausrichtung == Ausrichtung.weiblich
            ? texte.modulBenoetigtBasisOhneBart
            : texte.modulBenoetigtBasis,
        AnalyseModul.hautFarbtyp => texte.modulBenoetigtHaut,
        AnalyseModul.makeupAusstrahlung => texte.modulBenoetigtMakeup,
        AnalyseModul.zaehneLaecheln => texte.modulBenoetigtZaehne,
        AnalyseModul.figurPassform => texte.modulBenoetigtFigur,
        AnalyseModul.stilKleiderschrank => texte.modulBenoetigtStil,
        AnalyseModul.persoenlicheZiele => texte.modulBenoetigtZiele,
      };
}
