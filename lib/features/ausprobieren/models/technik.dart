import '../../../core/l10n/texte.dart';
import '../../modules/models/analyse_modul.dart';
import '../../onboarding/models/onboarding_profile.dart';

/// Die Techniken, die der Nutzer sich vor der Analyse aussuchen kann –
/// „Das will ich ausprobieren".
///
/// **Warum es diese Liste gibt.** Die Empfehlungen waren richtig, aber zu
/// brav: Gesicht waschen, Zahnseide, Feuchtigkeitscreme. Das ueberrascht
/// niemanden, und ein Report, der niemanden ueberrascht, wird einmal gelesen
/// und dann nicht mehr. Hier steht deshalb das, wovon man schon gehoert hat
/// und es nie richtig gemacht hat: Gua Sha, Gesichtsyoga, Kopfhautmassage.
/// Siehe DECISIONS 79.
///
/// **Warum eine feste Liste und kein Freitext.** Fuer Wuensche in eigenen
/// Worten gibt es das Feld bei „Deine Richtung". Was hier steht, geht dagegen
/// als *Name* in den Prompt und muss deshalb bekannt sein: Der Server haengt
/// an jede Technik ihren fachlich richtigen Takt und einen Satz zur
/// Vertraeglichkeit. Beides kann er nur zu etwas sagen, das er kennt.
///
/// **Was hier bewusst nicht steht** (die Sicherheitsgrenze aus DECISIONS 79):
/// nichts Invasives, nichts Medizinisches, nichts aus der Looksmaxxing-Ecke
/// mit Verletzungsrisiko oder ohne Grundlage. Kein Dermaroller und kein
/// Microneedling zu Hause, keine rezeptpflichtigen Wirkstoffe, kein Mewing,
/// kein Kiefertraining mit Kaugummi oder Mastic Gum, keine Fasten- oder
/// Diaet-Regime.
enum Technik {
  // --- Haare & Bart (Basis) ---
  kopfhautmassage(AnalyseModul.basis),
  rosmarinoel(AnalyseModul.basis),
  foehnRundbuerste(AnalyseModul.basis),
  haaroelkur(AnalyseModul.basis),
  seidenkissen(AnalyseModul.basis),
  bartoelRoutine(AnalyseModul.basis, nur: Ausrichtung.maennlich),
  bartbuerste(AnalyseModul.basis, nur: Ausrichtung.maennlich),

  // --- Haut & Farbtyp ---
  guaSha(AnalyseModul.hautFarbtyp),
  gesichtsyoga(AnalyseModul.hautFarbtyp),
  iceRolling(AnalyseModul.hautFarbtyp),
  lymphmassage(AnalyseModul.hautFarbtyp),
  sanftesPeeling(AnalyseModul.hautFarbtyp),
  sheetMaske(AnalyseModul.hautFarbtyp),
  lippenpeeling(AnalyseModul.hautFarbtyp, nur: Ausrichtung.weiblich),
  nagelpflege(AnalyseModul.hautFarbtyp, nur: Ausrichtung.weiblich),

  // --- Make-up & Ausstrahlung ---
  augenbrauenWimpern(AnalyseModul.makeupAusstrahlung),
  pinselhygiene(AnalyseModul.makeupAusstrahlung),
  lidschattenbasis(AnalyseModul.makeupAusstrahlung),
  rougePlatzierung(AnalyseModul.makeupAusstrahlung),

  // --- Zähne & Lächeln ---
  oelziehen(AnalyseModul.zaehneLaecheln),
  zungenschaber(AnalyseModul.zaehneLaecheln),
  laechelntraining(AnalyseModul.zaehneLaecheln),
  aufhellung(AnalyseModul.zaehneLaecheln),

  // --- Figur & Passform ---
  chinTuck(AnalyseModul.figurPassform),
  mobilityMinuten(AnalyseModul.figurPassform),
  wandstand(AnalyseModul.figurPassform),
  kaltDuschen(AnalyseModul.figurPassform),
  schlafhygiene(AnalyseModul.figurPassform),

  // --- Stil & Kleiderschrank ---
  kleiderschrankAudit(AnalyseModul.stilKleiderschrank),
  capsuleWardrobe(AnalyseModul.stilKleiderschrank),
  schuhpflege(AnalyseModul.stilKleiderschrank),
  accessoireEinstieg(AnalyseModul.stilKleiderschrank);

  const Technik(this.modul, {this.nur});

  /// Das Kapitel, in dem diese Technik landet. Sie wird nur angeboten, wenn
  /// dieses Modul auch analysiert wird – ein Gua Sha ohne Haut-Kapitel
  /// haette im Report keinen Platz.
  final AnalyseModul modul;

  /// Fuer wen die Technik ueberhaupt angeboten wird. `null` heisst: fuer
  /// alle.
  ///
  /// Dieselbe Regel wie bei den Modulen ([AnalyseModul.waehlbareFuer]): Wer
  /// keine Angabe gemacht hat, bekommt alles zur Auswahl – „divers" und
  /// „keine Angabe" sind kein Auftrag, irgendetwas wegzulassen.
  final Ausrichtung? nur;

  bool passtZu(Ausrichtung ausrichtung) =>
      nur == null || ausrichtung == nur || ausrichtung == Ausrichtung.neutral;

  /// Was in dieser Analyse ueberhaupt zur Auswahl steht: die Techniken der
  /// gewaehlten Module, gefiltert nach der Ausrichtung, in
  /// Deklarationsreihenfolge.
  static List<Technik> angebot(
    Set<AnalyseModul> module,
    Ausrichtung ausrichtung,
  ) =>
      values
          .where((t) => module.contains(t.modul) && t.passtZu(ausrichtung))
          .toList();

  /// Stabile Namen aus der Speicherung. Unbekanntes faellt weg – dieselbe
  /// Haltung wie bei [AnalyseModul.ausNamen].
  static Set<Technik> ausNamen(Iterable<Object?> namen) {
    final gefunden = <Technik>{};
    for (final name in namen) {
      for (final technik in values) {
        if (technik.name == name) gefunden.add(technik);
      }
    }
    return gefunden;
  }

  /// Die Auswahl in Deklarationsreihenfolge – damit dieselbe Auswahl
  /// unabhaengig von der Klickreihenfolge dieselbe Anfrage ergibt.
  static List<Technik> sortiert(Set<Technik> gewaehlt) =>
      values.where(gewaehlt.contains).toList();
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension TechnikText on Technik {
  String label(L texte) => switch (this) {
        Technik.kopfhautmassage => texte.technikKopfhautmassage,
        Technik.rosmarinoel => texte.technikRosmarinoel,
        Technik.foehnRundbuerste => texte.technikFoehnRundbuerste,
        Technik.haaroelkur => texte.technikHaaroelkur,
        Technik.seidenkissen => texte.technikSeidenkissen,
        Technik.bartoelRoutine => texte.technikBartoelRoutine,
        Technik.bartbuerste => texte.technikBartbuerste,
        Technik.guaSha => texte.technikGuaSha,
        Technik.gesichtsyoga => texte.technikGesichtsyoga,
        Technik.iceRolling => texte.technikIceRolling,
        Technik.lymphmassage => texte.technikLymphmassage,
        Technik.sanftesPeeling => texte.technikSanftesPeeling,
        Technik.sheetMaske => texte.technikSheetMaske,
        Technik.lippenpeeling => texte.technikLippenpeeling,
        Technik.nagelpflege => texte.technikNagelpflege,
        Technik.augenbrauenWimpern => texte.technikAugenbrauenWimpern,
        Technik.pinselhygiene => texte.technikPinselhygiene,
        Technik.lidschattenbasis => texte.technikLidschattenbasis,
        Technik.rougePlatzierung => texte.technikRougePlatzierung,
        Technik.oelziehen => texte.technikOelziehen,
        Technik.zungenschaber => texte.technikZungenschaber,
        Technik.laechelntraining => texte.technikLaechelntraining,
        Technik.aufhellung => texte.technikAufhellung,
        Technik.chinTuck => texte.technikChinTuck,
        Technik.mobilityMinuten => texte.technikMobilityMinuten,
        Technik.wandstand => texte.technikWandstand,
        Technik.kaltDuschen => texte.technikKaltDuschen,
        Technik.schlafhygiene => texte.technikSchlafhygiene,
        Technik.kleiderschrankAudit => texte.technikKleiderschrankAudit,
        Technik.capsuleWardrobe => texte.technikCapsuleWardrobe,
        Technik.schuhpflege => texte.technikSchuhpflege,
        Technik.accessoireEinstieg => texte.technikAccessoireEinstieg,
      };

  /// Eine Zeile, die die Technik greifbar macht.
  ///
  /// Dieselbe Begruendung wie bei den Stilrichtungen (DECISIONS 58): „Gua
  /// Sha" allein ist fuer jemanden, der es noch nie gemacht hat, eine
  /// Vokabel. „Stein am Gesicht entlang, immer nach aussen" ist ein Bild.
  String untertext(L texte) => switch (this) {
        Technik.kopfhautmassage => texte.technikKopfhautmassageUnter,
        Technik.rosmarinoel => texte.technikRosmarinoelUnter,
        Technik.foehnRundbuerste => texte.technikFoehnRundbuersteUnter,
        Technik.haaroelkur => texte.technikHaaroelkurUnter,
        Technik.seidenkissen => texte.technikSeidenkissenUnter,
        Technik.bartoelRoutine => texte.technikBartoelRoutineUnter,
        Technik.bartbuerste => texte.technikBartbuersteUnter,
        Technik.guaSha => texte.technikGuaShaUnter,
        Technik.gesichtsyoga => texte.technikGesichtsyogaUnter,
        Technik.iceRolling => texte.technikIceRollingUnter,
        Technik.lymphmassage => texte.technikLymphmassageUnter,
        Technik.sanftesPeeling => texte.technikSanftesPeelingUnter,
        Technik.sheetMaske => texte.technikSheetMaskeUnter,
        Technik.lippenpeeling => texte.technikLippenpeelingUnter,
        Technik.nagelpflege => texte.technikNagelpflegeUnter,
        Technik.augenbrauenWimpern => texte.technikAugenbrauenWimpernUnter,
        Technik.pinselhygiene => texte.technikPinselhygieneUnter,
        Technik.lidschattenbasis => texte.technikLidschattenbasisUnter,
        Technik.rougePlatzierung => texte.technikRougePlatzierungUnter,
        Technik.oelziehen => texte.technikOelziehenUnter,
        Technik.zungenschaber => texte.technikZungenschaberUnter,
        Technik.laechelntraining => texte.technikLaechelntrainingUnter,
        Technik.aufhellung => texte.technikAufhellungUnter,
        Technik.chinTuck => texte.technikChinTuckUnter,
        Technik.mobilityMinuten => texte.technikMobilityMinutenUnter,
        Technik.wandstand => texte.technikWandstandUnter,
        Technik.kaltDuschen => texte.technikKaltDuschenUnter,
        Technik.schlafhygiene => texte.technikSchlafhygieneUnter,
        Technik.kleiderschrankAudit => texte.technikKleiderschrankAuditUnter,
        Technik.capsuleWardrobe => texte.technikCapsuleWardrobeUnter,
        Technik.schuhpflege => texte.technikSchuhpflegeUnter,
        Technik.accessoireEinstieg => texte.technikAccessoireEinstiegUnter,
      };
}
