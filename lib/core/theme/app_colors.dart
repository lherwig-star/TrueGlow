import 'package:flutter/material.dart';

/// Semantische Farbrollen der App.
///
/// Bewusst als [ThemeExtension] und nicht als statische Konstanten: nur so
/// liefert derselbe Aufruf im hellen und im dunklen Theme unterschiedliche
/// Werte. Widgets greifen ueber `context.farben` zu und kennen keine
/// konkreten Farbwerte.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.hintergrund,
    required this.hintergrundTief,
    required this.flaeche,
    required this.flaecheHoch,
    required this.rand,
    required this.akzent,
    required this.aufAkzent,
    required this.akzentZwei,
    required this.textPrimaer,
    required this.textSekundaer,
    required this.warnung,
    required this.erfolg,
    required this.erreicht,
    required this.erreichtFlaeche,
    required this.aufErreicht,
    required this.erreichtLeer,
    required this.erreichtChip,
    required this.kartenrand,
  });

  /// Seitenhintergrund – der obere Ton des Seitenverlaufs.
  final Color hintergrund;

  /// Der untere Ton desselben Verlaufs.
  ///
  /// Der Hintergrund ist seit DECISIONS 50 kein Flaechenton mehr, sondern
  /// ein sehr sanfter Verlauf von oben nach unten. Er soll auffallen, ohne
  /// aufzufallen: Man spuert Tiefe, sieht aber keinen Farbwechsel.
  final Color hintergrundTief;

  /// Karten und abgesetzte Flaechen.
  final Color flaeche;

  /// Eine Stufe von [flaeche] abgesetzt – Produktzeilen und Zaehler-Badges.
  /// Im hellen Schema dunkler, im dunklen Schema tiefer als die Karte: In
  /// beiden Faellen eine Vertiefung, auf der die Sand-Toene ihren Kontrast
  /// behalten.
  final Color flaecheHoch;

  /// Dezente Rahmen und Trennlinien.
  final Color rand;

  /// Primaer-Akzent: Buttons, aktive Zustaende, Fortschrittsbalken.
  final Color akzent;

  /// Textfarbe auf [akzent]-Flaechen.
  final Color aufAkzent;

  /// Sekundaer-Akzent: Icons, Highlights.
  final Color akzentZwei;

  final Color textPrimaer;
  final Color textSekundaer;

  /// Fehler und Warnungen – gedecktes Terrakotta statt grellem Rot.
  final Color warnung;

  /// Erfolgs-Zustaende (Haekchen, "Geprueft"-Badge, Streak). Teilt sich den
  /// Ton mit [akzentZwei]; als eigene Rolle gefuehrt, damit ein spaeterer
  /// Wechsel nicht alle Icons mitzieht.
  final Color erfolg;

  /// **Erreichtes und Ausgewaehltes** – und ausschliesslich das.
  ///
  /// Ein warmes, gedaempftes Gold. Es steht an der Streak-Flamme und ihrer
  /// Zahl, an gesetzten Haken, an gefuellten Fortschrittssegmenten, an
  /// freigeschalteten Abzeichen, an den Joker-Schilden – und seit DECISIONS
  /// 51 an jedem Zustand, den der Nutzer selbst eingeschaltet hat: gewaehlte
  /// Module, angeklickte Chips, gesetzte Checkboxen, das gewaehlte Foto in
  /// der Zeitleiste.
  ///
  /// Das ist die ganze Idee dahinter (DECISIONS 50): Wenn Gold ueberall
  /// auftaucht, heisst es nichts mehr. Wer es sieht, soll wissen, dass hier
  /// etwas an ist, ohne den Text zu lesen. Buttons, Titel und Icons bleiben
  /// deshalb im Sand-Ton von [akzent].
  final Color erreicht;

  /// Dasselbe Gold als **Flaeche** – gefuellte Haken, Fortschrittssegmente,
  /// Schrittpunkte.
  ///
  /// Warum zwei Werte (DECISIONS 62): Auf dunklem Grund darf derselbe Ton
  /// beides – im Dunkelmodus sind [erreicht] und [erreichtFlaeche] deshalb
  /// identisch, dort aendert sich durch diese Rolle nichts. Auf hellem Grund
  /// geht es nicht: Ein Gold, das als kleiner Text die noetigen 4,5:1
  /// erreicht, ist als Flaeche schon fast braun; ein Gold, das als Flaeche
  /// leuchtet, traegt keinen 12-Punkt-Text mehr. Also zwei Werte, jeder mit
  /// seiner eigenen Schwelle: [erreicht] 4,5:1 als Text, [erreichtFlaeche]
  /// 3:1 als Flaeche.
  final Color erreichtFlaeche;

  /// Was auf [erreichtFlaeche] liegt – der Haken im gefuellten Kaestchen.
  ///
  /// Im Dunkelmodus derselbe Wert wie [aufAkzent]; hell muss er ein anderer
  /// sein, denn dort ist [aufAkzent] fast weiss und auf Gold nicht zu sehen.
  final Color aufErreicht;

  /// Die ungefuellte Gegenseite eines Erreicht-Segments.
  ///
  /// Im Fortschrittsbalken der Wochen-Challenge liegt sie direkt neben den
  /// gefuellten Segmenten. Hell ist sie deshalb ein zarter Creme-Amber-Ton
  /// und kein neutrales Grau: Ein kuehles Segment neben einem warmen sieht
  /// aus, als gehoerte es nicht dazu (DECISIONS 63).
  ///
  /// Dunkel traegt sie genau den Wert, der dort vorher schon gerechnet
  /// wurde – `textSekundaer` bei 18 %.
  final Color erreichtLeer;

  /// Die Flaeche eines Erreicht-Zaehlers – der Chip „2/5" an einer fertigen
  /// Checkliste.
  ///
  /// Eine Spur tiefer als [erreichtLeer], damit der Zaehler als eigenes
  /// Element liest und nicht als Teil der Karte. Der Text darauf ist
  /// [erreicht] und haelt dort seine 4,5:1.
  ///
  /// Dunkel wieder der zuvor gerechnete Wert: [erreicht] bei 14 %.
  final Color erreichtChip;

  /// Die hauchduenne helle Kontur einer Karte.
  ///
  /// Seit DECISIONS 50 setzt sich eine Karte darueber ab und nicht mehr ueber
  /// einen Schlagschatten. Bewusst eine eigene Rolle und nicht `rand`: Der
  /// ist kraeftiger und zieht eine sichtbare Linie – richtig fuer
  /// Trennstriche und Eingabefelder, zu laut fuer eine Karte.
  ///
  /// Sie steht hier, damit es genau **eine** Stelle gibt. Vorher rechnete
  /// das Theme sie sich selbst aus, und jede handgebaute Karte nahm `rand` –
  /// das war der Grund, warum das neue Design auf den Unterseiten nur halb
  /// ankam (DECISIONS 51).
  final Color kartenrand;

  /// Dunkel – "Deep Teal & Sand" (Standard).
  ///
  /// Vorgegeben sind Hintergrund, Karte, Akzent, Sekundaerton und Text; die
  /// uebrigen Rollen sind daraus abgeleitet und so gewaehlt, dass jeder Text
  /// auf seiner Flaeche mindestens 4,5:1 erreicht.
  static const dunkel = AppColors(
    // Deep Teal / Petrol
    hintergrund: Color(0xFF173C3B),
    // Fast schwarzes Blau – das untere Ende des Seitenverlaufs.
    hintergrundTief: Color(0xFF0C1C26),
    // Muted Teal
    flaeche: Color(0xFF295654),
    // Nicht in der Vorgabe: eine Vertiefung innerhalb der Karte. Bewusst
    // dunkler als die Karte – nur so bleiben Sand-Toene darauf lesbar.
    flaecheHoch: Color(0xFF1E4746),
    rand: Color(0xFF3C6F6C),
    // Warm Sand
    akzent: Color(0xFFD8C6AA),
    aufAkzent: Color(0xFF173C3B),
    // Soft Sand
    akzentZwei: Color(0xFFC7B18C),
    // Off-White
    textPrimaer: Color(0xFFF2EEE6),
    textSekundaer: Color(0xFFBCCCC8),
    // Gedecktes Apricot – auf Petrol lesbar, ohne grell zu wirken.
    warnung: Color(0xFFEFB79E),
    erfolg: Color(0xFFC7B18C),
    // Gedaempftes Gold. Hell genug fuer 4,7:1 auf der Karte – der kleinste
    // Text in dieser Farbe ist die 12-Punkt-Zeile "Geschafft!".
    erreicht: Color(0xFFE8BE6E),
    // Auf dunklem Grund traegt derselbe Ton Text und Flaeche. Die beiden
    // Rollen sind hier bewusst wertgleich – so aendert die Trennung aus
    // DECISIONS 62 am Dunkelmodus kein einziges Pixel.
    erreichtFlaeche: Color(0xFFE8BE6E),
    aufErreicht: Color(0xFF173C3B),
    // Beide standen hier vorher als Rechnung im Widget und stehen jetzt als
    // Wert in der Palette – dieselben Zahlen, damit sich im Dunkelmodus
    // nichts bewegt: textSekundaer bei 18 %, erreicht bei 14 %.
    erreichtLeer: Color(0x2EBCCCC8),
    erreichtChip: Color(0x24E8BE6E),
    // Off-White bei 10 % – Licht, kein Rahmen.
    kartenrand: Color(0x1AF2EEE6),
  );

  /// Hell – "Creme, Teal & Amber".
  ///
  /// Die Vorgeschichte in zwei Saetzen: Bis DECISIONS 62 war der helle Modus
  /// Kaffeebraun auf Beige und sah aus wie eine andere App. Die erste
  /// Ueberarbeitung machte ihn zum hellen Geschwister des Dunkelmodus, aber
  /// in kuehlem Grau-Gruen – und das war zu kalt (DECISIONS 63).
  ///
  /// Jetzt ist er durchgehend **warm**: Creme als Grund, kraeftiges Teal fuer
  /// Ueberschriften und Buttons, Amber fuer alles Erreichte. Die Struktur ist
  /// dieselbe geblieben – gleiche Rollen an denselben Stellen wie dunkel,
  /// die zwei Gold-Rollen mit ihren eigenen Schwellen inklusive.
  static const hell = AppColors(
    // Warmes Creme, nach unten eine Spur tiefer und waermer. Der Verlauf ist
    // hauchzart – man soll Tiefe spueren, keinen Farbwechsel sehen.
    hintergrund: Color(0xFFFDF5EE),
    hintergrundTief: Color(0xFFF6E8D9),
    // Karten sind heller als der Grund: Auf hellem Untergrund hebt sich eine
    // Flaeche nach oben ab, nicht nach unten.
    flaeche: Color(0xFFFEFAF7),
    // Und die Vertiefung liegt zwischen Karte und Verlaufsende.
    flaecheHoch: Color(0xFFF9EFE4),
    rand: Color(0xFFDFC7AC),
    // Kraeftiges Teal – Ueberschriften, Primaer- und Umriss-Buttons.
    akzent: Color(0xFF025D70),
    // Der Buttontext ist das Karten-Weiss.
    aufAkzent: Color(0xFFFEFAF7),
    akzentZwei: Color(0xFF0E6D82),
    // Dunkle Tinte mit Teal-Charakter.
    textPrimaer: Color(0xFF12383F),
    textSekundaer: Color(0xFF4F6468),
    // Gedecktes Terrakotta – warm wie der Rest.
    warnung: Color(0xFFA8442A),
    erfolg: Color(0xFF0E6D82),
    // Amber als Text: dunkles Ocker. Die Vorgabe nannte #955900 – das
    // erreicht auf dem Zaehler-Chip nur 4,3:1 und ist deshalb um eine
    // Nuance nachgedunkelt (DECISIONS 63).
    erreicht: Color(0xFF8F5500),
    // Und als Flaeche das Amber aus dem Referenzbild.
    erreichtFlaeche: Color(0xFFE59305),
    // Was auf dem Amber liegt: das Karten-Weiss – wie im Referenzbild.
    //
    // Es erreicht dort 2,5:1 und damit keine Textschwelle. Das ist eine
    // bewusste, ausdrueckliche Ausnahme (DECISIONS 64): Der Haken ist
    // Zierrat, den Zustand tragen Durchstreichung und Zaehlerstand. Die
    // Tinte stand hier einen Commit lang und ergab dunkles Braun auf
    // Orange – genau der Look, der weg sollte.
    aufErreicht: Color(0xFFFEFAF7),
    erreichtLeer: Color(0xFFFDE9D2),
    erreichtChip: Color(0xFFF5DEB9),
    // Wie dunkel: die Textfarbe bei 10 %.
    kartenrand: Color(0x1A12383F),
  );

  /// Die flache Fläche, mit der der Start beginnt.
  ///
  /// Genau die Mitte des Seitenverlaufs – und genau der Ton, den der native
  /// Splash trägt. Der kann nämlich keinen Verlauf: `windowSplashScreenBack-
  /// ground` nimmt ab Android 12 nur eine einzelne Farbe.
  ///
  /// Damit ist das erste Bild der eigenen Startanimation vom letzten Bild
  /// des nativen Splash nicht zu unterscheiden, und die Übergabe ist nichts,
  /// was man sehen könnte (DECISIONS 53).
  Color get startFlaeche =>
      Color.lerp(hintergrund, hintergrundTief, 0.5)!;

  @override
  AppColors copyWith({
    Color? hintergrund,
    Color? hintergrundTief,
    Color? flaeche,
    Color? flaecheHoch,
    Color? rand,
    Color? akzent,
    Color? aufAkzent,
    Color? akzentZwei,
    Color? textPrimaer,
    Color? textSekundaer,
    Color? warnung,
    Color? erfolg,
    Color? erreicht,
    Color? erreichtFlaeche,
    Color? aufErreicht,
    Color? erreichtLeer,
    Color? erreichtChip,
    Color? kartenrand,
  }) {
    return AppColors(
      hintergrund: hintergrund ?? this.hintergrund,
      hintergrundTief: hintergrundTief ?? this.hintergrundTief,
      flaeche: flaeche ?? this.flaeche,
      flaecheHoch: flaecheHoch ?? this.flaecheHoch,
      rand: rand ?? this.rand,
      akzent: akzent ?? this.akzent,
      aufAkzent: aufAkzent ?? this.aufAkzent,
      akzentZwei: akzentZwei ?? this.akzentZwei,
      textPrimaer: textPrimaer ?? this.textPrimaer,
      textSekundaer: textSekundaer ?? this.textSekundaer,
      warnung: warnung ?? this.warnung,
      erfolg: erfolg ?? this.erfolg,
      erreicht: erreicht ?? this.erreicht,
      erreichtFlaeche: erreichtFlaeche ?? this.erreichtFlaeche,
      aufErreicht: aufErreicht ?? this.aufErreicht,
      erreichtLeer: erreichtLeer ?? this.erreichtLeer,
      erreichtChip: erreichtChip ?? this.erreichtChip,
      kartenrand: kartenrand ?? this.kartenrand,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      hintergrund: Color.lerp(hintergrund, other.hintergrund, t)!,
      hintergrundTief:
          Color.lerp(hintergrundTief, other.hintergrundTief, t)!,
      flaeche: Color.lerp(flaeche, other.flaeche, t)!,
      flaecheHoch: Color.lerp(flaecheHoch, other.flaecheHoch, t)!,
      rand: Color.lerp(rand, other.rand, t)!,
      akzent: Color.lerp(akzent, other.akzent, t)!,
      aufAkzent: Color.lerp(aufAkzent, other.aufAkzent, t)!,
      akzentZwei: Color.lerp(akzentZwei, other.akzentZwei, t)!,
      textPrimaer: Color.lerp(textPrimaer, other.textPrimaer, t)!,
      textSekundaer: Color.lerp(textSekundaer, other.textSekundaer, t)!,
      warnung: Color.lerp(warnung, other.warnung, t)!,
      erfolg: Color.lerp(erfolg, other.erfolg, t)!,
      erreicht: Color.lerp(erreicht, other.erreicht, t)!,
      erreichtFlaeche:
          Color.lerp(erreichtFlaeche, other.erreichtFlaeche, t)!,
      aufErreicht: Color.lerp(aufErreicht, other.aufErreicht, t)!,
      erreichtLeer: Color.lerp(erreichtLeer, other.erreichtLeer, t)!,
      erreichtChip: Color.lerp(erreichtChip, other.erreichtChip, t)!,
      kartenrand: Color.lerp(kartenrand, other.kartenrand, t)!,
    );
  }
}

/// Kurzzugriff auf die Farbrollen des aktiven Themes.
extension AppColorsX on BuildContext {
  AppColors get farben => Theme.of(this).extension<AppColors>()!;
}
