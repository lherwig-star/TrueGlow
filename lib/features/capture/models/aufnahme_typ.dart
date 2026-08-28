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

  // Die Ganzkoerper-Silhouette gibt es nicht mehr (DECISIONS 74). Sie war
  // eine Anweisung, die sich vor dem Spiegel nicht befolgen liess: Wer sein
  // Handy aufstellt, steht immer nur halb darin – und der Auto-Ausloeser
  // wartete auf eine Haltung, die nie eintrat.

  /// Freies Bild ohne Hilfslinien.
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
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.ganzkoerper,
    autoAusloeser: true,
  ),
  figurGanzkoerperSeitlich(
    modul: AnalyseModul.figurPassform,
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.ganzkoerper,
    autoAusloeser: true,
  ),

  // --- Stil & Kleiderschrank ---
  stilOutfitEins(
    modul: AnalyseModul.stilKleiderschrank,
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    autoAusloeser: true,
  ),
  stilOutfitZwei(
    modul: AnalyseModul.stilKleiderschrank,
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    autoAusloeser: true,
  ),
  stilOutfitDrei(
    modul: AnalyseModul.stilKleiderschrank,
    overlay: Overlaytyp.keins,
    pruefung: Pruefprofil.frei,
    optional: true,
    autoAusloeser: true,
  );

  const AufnahmeTyp({
    required this.modul,
    required this.overlay,
    required this.pruefung,
    this.optional = false,
    this.autoAusloeser = false,
  });

  final AnalyseModul modul;

  /// Die Hilfslinien im Sucher.
  ///
  /// Seit dem Wegfall der Ganzkoerper-Silhouette haengt sie an nichts
  /// weiter – die Gesichts-Umrisse sind fuer alle dieselben (DECISIONS 74).
  final Overlaytyp overlay;
  final Pruefprofil pruefung;

  /// Darf uebersprungen werden, ohne den Flow zu blockieren.
  final bool optional;

  /// Ob die App selbst ausloest, sobald jemand weit genug im Bild ist.
  ///
  /// Bei jeder Aufnahme, fuer die man das Handy abstellt und zuruecktritt:
  /// den beiden Ganzkoerperfotos und den drei Outfit-Fotos. Von dort ist der
  /// Ausloeser nicht erreichbar. Bei den Portraits haelt man das Geraet in
  /// der Hand – dort waere ein Automatismus nur ein Foto zum falschen
  /// Zeitpunkt.
  ///
  /// Bei den Outfit-Fotos ist er ein Angebot, keine Bedingung: Liegt das
  /// Outfit ausgelegt da, wird nie eine Pose erkannt, der Countdown startet
  /// gar nicht erst – und der Ausloeser bleibt druckbar wie immer
  /// (DECISIONS 68).
  final bool autoAusloeser;

  /// Ob die Live-Erkennung im Sucher sinnvoll ist.
  bool get mitLiveHilfe => pruefung.pruefeGesicht;

  /// Ob ueberhaupt ein Bildstrom laufen muss.
  ///
  /// Gesichtserkennung fuer die Portraits, Posenerkennung ueberall dort, wo
  /// die App selbst ausloest. Seit auch die Outfit-Fotos selbst ausloesen,
  /// trifft das auf jede Aufnahme zu – der Sucher verlaesst sich darauf und
  /// hat keine Fassung ohne Statuszeile mehr.
  bool get mitBildstrom => mitLiveHilfe || autoAusloeser;

  /// Ob das Bild auch ohne Person gueltig ist.
  ///
  /// Nur die Outfit-Fotos: Dort darf das Kleidungsstueck ausgelegt sein oder
  /// auf dem Buegel haengen. An der Auto-Ausloesung aendert das nichts, wohl
  /// aber an ihrem Ton – „Stell dich ins Bild" waere dort eine Forderung,
  /// die der Schritt gar nicht stellt.
  bool get personOptional => pruefung == Pruefprofil.frei;

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

  /// Die Erklaerung zum Auto-Ausloeser im Foto-Schritt.
  ///
  /// Zwei Fassungen, weil zwei Dinge verschieden sind: Die Ganzkoerperfotos
  /// haben einen Umriss, in den man sich stellt. Die Outfit-Fotos haben
  /// keinen und duerfen ohne Person auskommen – dort muss der Text sagen,
  /// dass der Automatismus dann einfach nicht anspringt.
  String autoHinweis(L texte) =>
      personOptional ? texte.outfitAutoHinweis : texte.koerperAutoHinweis;
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
