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
    // Off-White bei 10 % – Licht, kein Rahmen.
    kartenrand: Color(0x1AF2EEE6),
  );

  /// Hell – "Petrol Light", das helle Geschwister des Dunkelmodus.
  ///
  /// Bis DECISIONS 62 war der helle Modus eine eigene Welt: flaches Beige,
  /// Kaffeebraun als Akzent. Er sah nicht aus wie derselbe Look bei Tag,
  /// sondern wie eine andere App. Jetzt teilt er sich die Farbfamilie mit
  /// dem Dunkelmodus – **dieselben Rollen an denselben Stellen, nur andere
  /// Werte**: Das dunkle Petrol, das dort die Flaeche traegt, ist hier die
  /// Tinte und die Buttonfarbe; das Gold steht an genau denselben Stellen.
  ///
  /// Kein Braun mehr, nirgends.
  static const hell = AppColors(
    // Fast Weiss mit einem kuehlen Petrol-Hauch, nach unten ins helle
    // Grau-Gruen – derselbe sanfte Verlauf wie dunkel, nur anders herum
    // gedacht.
    hintergrund: Color(0xFFF7F9F8),
    hintergrundTief: Color(0xFFE0E9E7),
    // Karten sind heller als der Hintergrund, nicht dunkler: Auf hellem
    // Grund hebt sich eine Flaeche nach oben ab, nicht nach unten.
    flaeche: Color(0xFFFCFEFD),
    // Und die Vertiefung wieder eine Spur tiefer als die Karte.
    flaecheHoch: Color(0xFFEDF3F2),
    rand: Color(0xFFB7CBC8),
    // Dunkles Petrol aus der Familie des Dunkelmodus – hier Buttonfarbe.
    akzent: Color(0xFF143C4A),
    aufAkzent: Color(0xFFF5F8F7),
    akzentZwei: Color(0xFF2E6E85),
    // Die Tinte: noch eine Spur tiefer als der Button.
    textPrimaer: Color(0xFF10262E),
    textSekundaer: Color(0xFF43606A),
    // Gedecktes Terrakotta, dunkel genug fuer hellen Grund.
    warnung: Color(0xFFA8442A),
    erfolg: Color(0xFF2E6E85),
    // Das Gold als Text: 4,5:1 auf jeder Flaeche, bis hinunter zum unteren
    // Ende des Seitenverlaufs. Der Vorschlag nannte hier #B27F26 – der
    // kommt als Text nur auf 3,3:1 und traegt die 12-Punkt-Zeile
    // „Geschafft!" nicht (DECISIONS 62).
    erreicht: Color(0xFF865F1B),
    // Als Flaeche dagegen genau der vorgeschlagene Ton.
    erreichtFlaeche: Color(0xFFB27F26),
    aufErreicht: Color(0xFF10262E),
    // Das Gegenstueck zur 10-%-Kontur im Dunkelmodus: dieselbe Deckkraft,
    // nur in Petrol statt in Off-White.
    kartenrand: Color(0x1A143C4A),
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
      kartenrand: Color.lerp(kartenrand, other.kartenrand, t)!,
    );
  }
}

/// Kurzzugriff auf die Farbrollen des aktiven Themes.
extension AppColorsX on BuildContext {
  AppColors get farben => Theme.of(this).extension<AppColors>()!;
}
