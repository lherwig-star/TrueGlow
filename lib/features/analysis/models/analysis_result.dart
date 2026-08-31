import 'analyse_modus.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../../core/l10n/texte.dart';
import '../../onboarding/models/onboarding_profile.dart';

// Datenmodell der KI-Antwort. Das Schema ist im System-Prompt fest
// vorgegeben; hier wird es defensiv gelesen: fehlende oder falsch getypte
// Felder fuehren nicht zum Absturz, sondern zu leeren Werten.

/// Ein empfohlenes Produkt. [affiliateUrl] bleibt vorerst leer – die Struktur
/// steht, damit Affiliate-Links spaeter nur noch eingetragen werden muessen.
class Produkt {
  const Produkt({
    required this.name,
    required this.kategorie,
    required this.beschreibung,
    this.affiliateUrl,
  });

  final String name;
  final String kategorie;
  final String beschreibung;
  final String? affiliateUrl;

  /// Das Wort zur Kennung, in der Sprache der App.
  ///
  /// Das Modell liefert seit dem Umbau nur noch eine Kennung
  /// (`'pflege'`, `'styling'`, …). Frueher schrieb es das Wort selbst, und
  /// dann stand „Pflege" auch in einem englischen Report. Alte Reports
  /// tragen dieses Wort noch – sie fallen deshalb auf sich selbst zurueck.
  String kategorieText(L texte) => switch (kategorie.toLowerCase()) {
        'reinigung' => texte.produktReinigung,
        'pflege' => texte.produktPflege,
        'styling' => texte.produktStyling,
        'werkzeug' => texte.produktWerkzeug,
        'makeup' || 'make-up' => texte.produktMakeup,
        'kleidung' => texte.produktKleidung,
        'sonstiges' => texte.produktSonstiges,
        _ => kategorie,
      };

  Map<String, dynamic> toJson() => {
        'name': name,
        'kategorie': kategorie,
        'beschreibung': beschreibung,
        'affiliateUrl': affiliateUrl,
      };

  factory Produkt.fromJson(Map<String, dynamic> json) => Produkt(
        name: _text(json['name']),
        kategorie: _text(json['kategorie']),
        beschreibung: _text(json['beschreibung']),
        affiliateUrl: switch (json['affiliateUrl']) {
          final String s when s.trim().isNotEmpty => s,
          _ => null,
        },
      );
}

/// Ein thematischer Block der Analyse, z. B. Haut oder Frisur.
class Sektion {
  const Sektion({
    required this.titel,
    required this.einschaetzung,
    required this.empfehlungen,
    required this.produkte,
  });

  final String titel;
  final String einschaetzung;
  final List<String> empfehlungen;
  final List<Produkt> produkte;

  Map<String, dynamic> toJson() => {
        'titel': titel,
        'einschaetzung': einschaetzung,
        'empfehlungen': empfehlungen,
        'produkte': produkte.map((p) => p.toJson()).toList(),
      };

  /// Reports aus der Zeit der Beispielbilder tragen hier noch ein Feld
  /// `bildSuchbegriff`. Es wird schlicht nicht gelesen – der Report bleibt
  /// vollstaendig, nur die Bilderreihe darunter gibt es nicht mehr
  /// (DECISIONS 78).
  factory Sektion.fromJson(Map<String, dynamic> json) => Sektion(
        titel: _text(json['titel']),
        einschaetzung: _text(json['einschaetzung']),
        empfehlungen: _textListe(json['empfehlungen']),
        produkte: _liste(json['produkte']).map(Produkt.fromJson).toList(),
      );
}

/// Der Step-by-Step-Plan in drei Zeithorizonten plus taegliche Habits.
class Plan {
  const Plan({
    required this.sofort,
    required this.dreissigTage,
    required this.langfristig,
    required this.taeglicheHabits,
  });

  final List<String> sofort;
  final List<String> dreissigTage;
  final List<String> langfristig;
  final List<String> taeglicheHabits;

  bool get istLeer =>
      sofort.isEmpty &&
      dreissigTage.isEmpty &&
      langfristig.isEmpty &&
      taeglicheHabits.isEmpty;

  Map<String, dynamic> toJson() => {
        'sofort': sofort,
        'dreissigTage': dreissigTage,
        'langfristig': langfristig,
        'taeglicheHabits': taeglicheHabits,
      };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        sofort: _textListe(json['sofort']),
        dreissigTage: _textListe(json['dreissigTage']),
        langfristig: _textListe(json['langfristig']),
        taeglicheHabits: _textListe(json['taeglicheHabits']),
      );

  /// Haengt die Eintraege eines weiteren Plans an, ohne Dubletten. Wird beim
  /// nachtraeglichen Ergaenzen eines Moduls gebraucht: der bestehende Plan
  /// bleibt stehen, das neue Kapitel steuert nur zusaetzliche Schritte bei.
  Plan ergaenztUm(Plan weiterer) {
    List<String> vereint(List<String> a, List<String> b) =>
        <String>{...a, ...b}.toList();

    return Plan(
      sofort: vereint(sofort, weiterer.sofort),
      dreissigTage: vereint(dreissigTage, weiterer.dreissigTage),
      langfristig: vereint(langfristig, weiterer.langfristig),
      taeglicheHabits: vereint(taeglicheHabits, weiterer.taeglicheHabits),
    );
  }

  static const leer = Plan(
    sofort: [],
    dreissigTage: [],
    langfristig: [],
    taeglicheHabits: [],
  );
}

/// Ein Report-Kapitel – genau ein gewaehltes Modul.
class Kapitel {
  const Kapitel({
    required this.modul,
    required this.einleitung,
    required this.sektionen,
    this.habits = const [],
  });

  final AnalyseModul modul;

  /// Kurzer Einstieg ins Kapitel, z. B. die Gesichtsform bei der Basis.
  final String einleitung;

  final List<Sektion> sektionen;

  /// Taegliche, abhakbare Aufgaben dieses Kapitels. Bewusst am Kapitel und
  /// nicht am Plan: nur so kann ueberhaupt keine Aufgabe aus einem nicht
  /// gewaehlten Modul in der Checkliste landen.
  final List<String> habits;

  /// Ueberschrift des Kapitels – dieselbe wie die des Moduls.
  String titel(L texte, Ausrichtung ausrichtung) =>
      modul.kapitel(texte, ausrichtung);

  int get anzahlEmpfehlungen =>
      sektionen.fold(0, (summe, s) => summe + s.empfehlungen.length);

  bool get istLeer => einleitung.isEmpty && sektionen.isEmpty;

  Map<String, dynamic> toJson() => {
        'modul': modul.name,
        'einleitung': einleitung,
        'sektionen': sektionen.map((s) => s.toJson()).toList(),
        'habits': habits,
      };

  /// Liefert null, wenn das Modul unbekannt ist – etwa weil das Modell einen
  /// Namen erfunden hat.
  static Kapitel? fromJson(Map<String, dynamic> json) {
    final modul = AnalyseModul.values
        .where((m) => m.name == json['modul'])
        .firstOrNull;
    if (modul == null) return null;

    return Kapitel(
      modul: modul,
      einleitung: _text(json['einleitung']),
      sektionen: _liste(json['sektionen']).map(Sektion.fromJson).toList(),
      habits: _textListe(json['habits']),
    );
  }
}

/// Vollstaendiges Analyse-Ergebnis inklusive Metadaten fuer den Verlauf.
class AnalysisResult {
  const AnalysisResult({
    required this.id,
    required this.erstelltAm,
    required this.kapitel,
    required this.plan,
    this.richtung = Richtung.leer,
    this.modus = AnalyseModus.standard,
    this.gesamtbild = '',
  });

  /// Eindeutige ID, gleichzeitig Schluessel in der lokalen Speicherung.
  final String id;
  final DateTime erstelltAm;

  /// Ein Kapitel pro analysiertem Modul, in Modul-Reihenfolge.
  final List<Kapitel> kapitel;

  final Plan plan;

  /// Die persoenlichen Ziele, mit denen dieser Report erstellt wurde. Sie
  /// haengen am Ergebnis und nicht nur am Controller, damit der Report zeigen
  /// kann, worauf er beruht – und damit auffaellt, wenn sich die Richtung
  /// seitdem geaendert hat.
  final Richtung richtung;

  /// Mit welchem Auftrag dieser Report entstanden ist.
  ///
  /// Haengt am Ergebnis und nicht am Controller: Der Modus gilt pro Analyse,
  /// und im Verlauf soll ablesbar bleiben, welche Frage ein Report
  /// beantwortet hat. Alte Reports kennen das Feld nicht – sie sind per
  /// Definition [AnalyseModus.verfeinern], weil es damals nichts anderes gab.
  final AnalyseModus modus;

  /// Der Einstieg des Reports: die Richtung in zwei bis vier Sätzen.
  ///
  /// **In beiden Modi** (DECISIONS 67) – im entdeckenden beschreibt er die
  /// neue Richtung, im verfeinernden, was am jetzigen Look trägt und wohin
  /// die Verfeinerung zielt. Beide Male ohne konkrete Namen: Schnitt, Bart
  /// und Kleidungsstücke fallen zum ersten Mal im jeweiligen Kapitel.
  ///
  /// Leer, wenn das Modell das Feld vergisst oder der Report von vor
  /// DECISIONS 67 stammt. Der Report ist deswegen nicht kaputt, er hat nur
  /// seinen Vorspann verloren; die Karte fällt dann weg, statt eine leere
  /// Fläche zu zeigen.
  final String gesamtbild;

  /// Ob der Report seinen Vorspann wirklich hat.
  bool get zeigtGesamtbild => gesamtbild.isNotEmpty;

  /// Welche Module dieser Report abdeckt.
  Set<AnalyseModul> get module => kapitel.map((k) => k.modul).toSet();

  List<Sektion> get sektionen => [for (final k in kapitel) ...k.sektionen];

  /// Kapitel, die eine Tages-Checkliste mitbringen – die Grundlage der Karten
  /// auf Startseite und Plan.
  List<Kapitel> get checklisten =>
      kapitel.where((k) => k.habits.isNotEmpty).toList();

  /// Alle Checklisten-Punkte zusammen. Enthaelt per Konstruktion nur Punkte
  /// aus Kapiteln, die es auch wirklich in den Report geschafft haben.
  List<String> get alleHabits => [for (final k in kapitel) ...k.habits];

  /// Einstiegstext der Basis – Grundlage der Kurzfassung im Dashboard.
  String get gesichtsform =>
      kapitel
          .where((k) => k.modul.istBasis)
          .map((k) => k.einleitung)
          .firstOrNull ??
      '';

  int get anzahlEmpfehlungen =>
      kapitel.fold(0, (summe, k) => summe + k.anzahlEmpfehlungen);

  /// Fuegt ein nachtraeglich erzeugtes Kapitel hinzu, ohne die bestehenden zu
  /// veraendern. Ein bereits vorhandenes Kapitel desselben Moduls wird
  /// ersetzt; die Reihenfolge folgt weiterhin der Modul-Reihenfolge.
  AnalysisResult mitKapitel(
    Kapitel neues, {
    Plan? planErgaenzung,
    Richtung? richtung,
  }) {
    final zusammen = <AnalyseModul, Kapitel>{
      for (final k in kapitel) k.modul: k,
      neues.modul: neues,
    };

    final sortiert = [
      for (final modul in AnalyseModul.values) ?zusammen[modul],
    ];

    return AnalysisResult(
      id: id,
      erstelltAm: erstelltAm,
      kapitel: sortiert,
      plan: planErgaenzung == null ? plan : plan.ergaenztUm(planErgaenzung),
      richtung: richtung ?? this.richtung,
      gesamtbild: gesamtbild,
      // Ein nachtraegliches Kapitel aendert den Auftrag des Reports nicht:
      // Wer erweitert, bekommt das neue Kapitel im Modus des Reports, in den
      // es eingehaengt wird.
      modus: modus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'erstelltAm': erstelltAm.toIso8601String(),
        'kapitel': kapitel.map((k) => k.toJson()).toList(),
        'plan': plan.toJson(),
        'richtung': richtung.toJson(),
        'modus': modus.name,
        'gesamtbild': gesamtbild,
      };

  /// Liest eine bereits gespeicherte Analyse (inkl. ID und Datum).
  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: _text(json['id']),
        erstelltAm:
            DateTime.tryParse(_text(json['erstelltAm'])) ?? DateTime.now(),
        kapitel: _kapitel(json),
        plan: json['plan'] is Map
            ? Plan.fromJson(Map<String, dynamic>.from(json['plan'] as Map))
            : Plan.leer,
        // Analysen aus der Zeit vor dem Feature haben kein Feld – die laufen
        // ohne Richtung weiter.
        richtung: json['richtung'] is Map
            ? Richtung.fromJson(
                Map<String, dynamic>.from(json['richtung'] as Map))
            : Richtung.leer,
        // Dito: ohne Feld der Rueckfall, und der ist das bisherige Verhalten.
        modus: AnalyseModus.ausName(json['modus']),
        // Reports von vor DECISIONS 67 tragen das Feld unter seinem alten
        // Namen. Sie behalten damit ihren Vorspann.
        gesamtbild: _text(json['gesamtbild']).isNotEmpty
            ? _text(json['gesamtbild'])
            : _text(json['neuerLook']),
      );

  /// Liest die rohe KI-Antwort, die weder ID noch Datum enthaelt.
  factory AnalysisResult.vonApi(
    Map<String, dynamic> json, {
    required String id,
    required DateTime erstelltAm,
    Richtung richtung = Richtung.leer,
    AnalyseModus modus = AnalyseModus.standard,
  }) =>
      AnalysisResult(
        id: id,
        erstelltAm: erstelltAm,
        kapitel: _kapitel(json),
        plan: json['plan'] is Map
            ? Plan.fromJson(Map<String, dynamic>.from(json['plan'] as Map))
            : Plan.leer,
        richtung: richtung,
        modus: modus,
        // Kommt aus der Antwort des Modells – seit DECISIONS 67 in beiden
        // Modi. `neuerLook` ist der alte Feldname; ein Modell, das ihn noch
        // liefert, soll seinen Vorspann nicht verlieren.
        gesamtbild: _text(json['gesamtbild']).isNotEmpty
            ? _text(json['gesamtbild'])
            : _text(json['neuerLook']),
      );

  /// Minimalpruefung, ob die Antwort ueberhaupt brauchbar ist.
  bool get istVollstaendig =>
      kapitel.any((k) => !k.istLeer) && !plan.istLeer;

  /// Liest die Kapitel – und faengt dabei zwei Faelle ab: Analysen aus der
  /// Zeit vor den Modulen hatten "sektionen" direkt auf oberster Ebene, und
  /// ein Modell liefert das gelegentlich auch heute noch so.
  static List<Kapitel> _kapitel(Map<String, dynamic> json) {
    final ausKapiteln = _liste(json['kapitel'])
        .map(Kapitel.fromJson)
        .whereType<Kapitel>()
        .toList();
    if (ausKapiteln.isNotEmpty) return ausKapiteln;

    final flach = _liste(json['sektionen']).map(Sektion.fromJson).toList();
    if (flach.isEmpty) return const [];

    // Damals hingen die Habits am Plan – sie gehoeren zur Basis, weil es
    // nichts anderes gab.
    final planHabits = json['plan'] is Map
        ? _textListe((json['plan'] as Map)['taeglicheHabits'])
        : const <String>[];

    return [
      Kapitel(
        modul: AnalyseModul.basis,
        einleitung: _text(json['gesichtsform']),
        sektionen: flach,
        habits: planHabits,
      ),
    ];
  }
}

// --- Defensive Lesehilfen ---

String _text(dynamic wert) => switch (wert) {
      final String s => s.trim(),
      null => '',
      _ => wert.toString(),
    };

List<Map<String, dynamic>> _liste(dynamic wert) => switch (wert) {
      final List l => l
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      _ => const [],
    };

List<String> _textListe(dynamic wert) => switch (wert) {
      final List l => l
          .map(_text)
          .where((s) => s.isNotEmpty)
          .toList(),
      _ => const [],
    };
