import '../storage/hive_service.dart';

/// Die Uebersetzung zwischen lokalem Speicher und Cloud-Datenmodell.
///
/// Lokal liegt alles in vier Hive-Boxen als flache Schluessel-Wert-Paare. In
/// der Cloud steht die Struktur aus der Roadmap:
///
/// ```
/// users/{uid}
///   daten/profil        Onboarding-Antworten
///   daten/richtung      Persoenliche Richtung
///   daten/streak        Rekord und gefeierte Abzeichen
///   daten/module        Modulauswahl und Modul-Eingaben
///   daten/checkinPlan   Zeitplan und Markierungen der Check-ins
///   daten/verweise      Zeiger auf die aktuelle Analyse
///   daten/migration     Marker der einmaligen Hive-Uebernahme
///   analysen/{id}       je ein Report
///   checkins/{id}       je ein abgeschlossener Check-in
///   fortschritt/{tag}   abgehakte Aufgaben, Schluessel yyyy-mm-tt
///   kontingent/{art}    Zaehler der Cloud Function (nur serverseitig)
/// ```
///
/// Diese Datei ist die einzige Stelle, an der beide Welten aufeinandertreffen.
/// Migration (Phase 1.5) und Sync (Phase 1.6) benutzen sie gemeinsam – sonst
/// gaebe es zwei Abbildungen, die auseinanderlaufen koennen.
class CloudModell {
  CloudModell._();

  // --- Sammlungen -------------------------------------------------------

  static const String sammlungDaten = 'daten';
  static const String sammlungAnalysen = 'analysen';
  static const String sammlungCheckins = 'checkins';
  static const String sammlungFortschritt = 'fortschritt';

  /// Nur die Cloud Function schreibt hier – die Regeln verbieten es dem
  /// Client. Steht hier, damit der Name nicht doppelt gepflegt wird.
  static const String sammlungKontingent = 'kontingent';

  // --- Einzeldokumente --------------------------------------------------

  static const String dokProfil = '$sammlungDaten/profil';
  static const String dokRichtung = '$sammlungDaten/richtung';
  static const String dokStreak = '$sammlungDaten/streak';
  static const String dokModule = '$sammlungDaten/module';
  static const String dokCheckinPlan = '$sammlungDaten/checkinPlan';
  static const String dokVerweise = '$sammlungDaten/verweise';
  static const String dokMigration = '$sammlungDaten/migration';

  /// Alle Sammlungen, die der Client selbst schreibt – die Grundlage fuer
  /// „alle Cloud-Daten loeschen".
  static const List<String> alleSammlungen = [
    sammlungDaten,
    sammlungAnalysen,
    sammlungCheckins,
    sammlungFortschritt,
  ];

  // --- Lokale Schluessel ------------------------------------------------

  static const String keyOnboarding = 'onboarding';
  static const String keyRichtung = 'richtung';
  static const String keyModule = 'analyseModule';
  static const String keyModulEingaben = 'modulEingaben';
  static const String keyAktuelleAnalyse = 'aktuelleAnalyseId';
  static const String keyAufnahmen = 'aufnahmen';
  static const String keyErscheinungsbild = 'erscheinungsbild';

  static const String keyStreakRekord = 'streakRekord';
  static const String keyAbzeichen = 'abzeichenGefeiert';
  static const String keyStreakAktuell = 'streakAktuell';
  static const String keyStreakLetzterTag = 'streakLetzterTag';

  static const String keyPlanStart = 'planStart';
  static const String keyNaechsterIndex = 'naechsterIndex';
  static const String keyNaechsterTermin = 'naechsterTermin';
  static const String keyNeueHabits = 'neueHabits';
  static const String keyHistorie = 'historie';
  static const String keyEntwurf = 'entwurf';

  /// Ein Tagesschluessel der Fortschritts-Box (yyyy-mm-tt).
  static final RegExp _tagesschluessel = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static bool istTagesschluessel(String schluessel) =>
      _tagesschluessel.hasMatch(schluessel);

  // --- Abbildung --------------------------------------------------------

  /// Wohin ein lokaler Schluessel in der Cloud gehoert.
  ///
  /// `null` heisst: bleibt bewusst auf dem Geraet. Das betrifft genau drei
  /// Dinge, und jedes aus einem eigenen Grund:
  ///
  /// - `aufnahmen` und `entwurf` enthalten **Dateipfade lokaler Fotos**. Sie
  ///   waeren auf einem neuen Geraet wertlos und wuerden nur den Eindruck
  ///   erwecken, die Bilder seien mitgewandert.
  /// - `erscheinungsbild` ist eine Geraeteeinstellung, keine Kontoeinstellung.
  /// - `streakAktuell` und `streakLetzterTag` werden aus den Tagesdaten neu
  ///   gerechnet (siehe StreakRepository) – sie zu synchronisieren hiesse,
  ///   zwei Rechenwege fuer dieselbe Zahl zu pflegen.
  static CloudZiel? ziel(String box, String schluessel) {
    switch (box) {
      case HiveService.boxEinstellungen:
        return switch (schluessel) {
          keyOnboarding => const CloudZiel(dokProfil, 'wert'),
          keyRichtung => const CloudZiel(dokRichtung, 'wert'),
          keyModule => const CloudZiel(dokModule, 'module'),
          keyModulEingaben => const CloudZiel(dokModule, 'eingaben'),
          keyAktuelleAnalyse => const CloudZiel(dokVerweise, 'analyseId'),
          _ => null,
        };

      case HiveService.boxFortschritt:
        if (istTagesschluessel(schluessel)) {
          return CloudZiel('$sammlungFortschritt/$schluessel', 'erledigt');
        }
        return switch (schluessel) {
          keyStreakRekord => const CloudZiel(dokStreak, 'rekord'),
          keyAbzeichen => const CloudZiel(dokStreak, 'gefeiert'),
          _ => null,
        };

      case HiveService.boxCheckins:
        return switch (schluessel) {
          keyPlanStart => const CloudZiel(dokCheckinPlan, 'planStart'),
          keyNaechsterIndex => const CloudZiel(dokCheckinPlan, 'naechsterIndex'),
          keyNaechsterTermin =>
            const CloudZiel(dokCheckinPlan, 'naechsterTermin'),
          keyNeueHabits => const CloudZiel(dokCheckinPlan, 'neueHabits'),
          // Die Historie wird aufgefaechert – ein Dokument je Check-in.
          // Das laeuft nicht ueber diese Abbildung, sondern ueber
          // [historieZuDokumenten].
          _ => null,
        };

      case HiveService.boxAnalysen:
        return CloudZiel('$sammlungAnalysen/$schluessel', 'wert');
    }
    return null;
  }

  /// Ob ein lokaler Schluessel ueberhaupt in die Cloud gehoert.
  static bool wirdSynchronisiert(String box, String schluessel) =>
      ziel(box, schluessel) != null ||
      (box == HiveService.boxCheckins && schluessel == keyHistorie);

  /// Der lokale Ort zu einem Cloud-Dokument – die Rueckrichtung.
  ///
  /// Liefert `null` fuer Dokumente ohne lokale Entsprechung
  /// (`daten/migration`, `kontingent/…`) und fuer die Check-in-Dokumente,
  /// die als Liste zusammengesetzt werden.
  static LokalesZiel? lokal(String pfad, String feld) {
    final teile = pfad.split('/');
    if (teile.length != 2) return null;
    final sammlung = teile.first;
    final id = teile.last;

    if (sammlung == sammlungAnalysen) {
      return LokalesZiel(HiveService.boxAnalysen, id);
    }
    if (sammlung == sammlungFortschritt && istTagesschluessel(id)) {
      return LokalesZiel(HiveService.boxFortschritt, id);
    }

    return switch ((pfad, feld)) {
      (dokProfil, 'wert') =>
        const LokalesZiel(HiveService.boxEinstellungen, keyOnboarding),
      (dokRichtung, 'wert') =>
        const LokalesZiel(HiveService.boxEinstellungen, keyRichtung),
      (dokModule, 'module') =>
        const LokalesZiel(HiveService.boxEinstellungen, keyModule),
      (dokModule, 'eingaben') =>
        const LokalesZiel(HiveService.boxEinstellungen, keyModulEingaben),
      (dokVerweise, 'analyseId') =>
        const LokalesZiel(HiveService.boxEinstellungen, keyAktuelleAnalyse),
      (dokStreak, 'rekord') =>
        const LokalesZiel(HiveService.boxFortschritt, keyStreakRekord),
      (dokStreak, 'gefeiert') =>
        const LokalesZiel(HiveService.boxFortschritt, keyAbzeichen),
      (dokCheckinPlan, 'planStart') =>
        const LokalesZiel(HiveService.boxCheckins, keyPlanStart),
      (dokCheckinPlan, 'naechsterIndex') =>
        const LokalesZiel(HiveService.boxCheckins, keyNaechsterIndex),
      (dokCheckinPlan, 'naechsterTermin') =>
        const LokalesZiel(HiveService.boxCheckins, keyNaechsterTermin),
      (dokCheckinPlan, 'neueHabits') =>
        const LokalesZiel(HiveService.boxCheckins, keyNeueHabits),
      _ => null,
    };
  }

  /// Der Pfad zu einem einzelnen Check-in-Dokument.
  static String checkinPfad(Object? id) => '$sammlungCheckins/$id';
}

/// Ein Feld in einem Cloud-Dokument.
class CloudZiel {
  const CloudZiel(this.pfad, this.feld);

  /// Pfad relativ zu `users/{uid}`.
  final String pfad;

  /// Feldname innerhalb des Dokuments.
  final String feld;

  @override
  bool operator ==(Object other) =>
      other is CloudZiel && other.pfad == pfad && other.feld == feld;

  @override
  int get hashCode => Object.hash(pfad, feld);

  @override
  String toString() => '$pfad#$feld';
}

/// Ein Schluessel in einer Hive-Box.
class LokalesZiel {
  const LokalesZiel(this.box, this.schluessel);

  final String box;
  final String schluessel;

  @override
  bool operator ==(Object other) =>
      other is LokalesZiel &&
      other.box == box &&
      other.schluessel == schluessel;

  @override
  int get hashCode => Object.hash(box, schluessel);

  @override
  String toString() => '$box/$schluessel';
}
