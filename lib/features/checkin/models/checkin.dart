import '../../modules/models/analyse_modul.dart';

// Datenmodell der Check-ins. Ein Check-in ist eine kurze Rueckmeldung des
// Nutzers zum laufenden Plan: erst nur zur Alltagstauglichkeit, spaeter auch
// zur Wirkung.

/// Die Stufen der Check-in-Reihe.
///
/// Die Reihenfolge ist zugleich der Ablauf: Tag 7, Tag 14, Tag 30 und danach
/// im 30-Tage-Takt immer wieder [wirkung].
enum CheckinTyp {
  /// Tag 7 – ausschliesslich Machbarkeit.
  alltag(
    titel: 'Alltags-Check',
    intro: 'Eine Woche geschafft! Uns interessiert nur eins: Wie gut passen '
        'die Aufgaben in deinen Alltag?',
  ),

  /// Tag 14 – Machbarkeit der Wackelkandidaten plus weiche Schnell-Effekte.
  zwischen(
    titel: 'Zwischencheck',
    intro: 'Zwei Wochen dabei. Wir schauen kurz auf die Aufgaben, die zuletzt '
        'gehakt haben – und wie sich die ersten Tage anfühlen.',
  ),

  /// Tag 30 und alle 30 Tage danach – Wirkung inklusive Fortschrittsfoto.
  wirkung(
    titel: 'Wirkungs-Check',
    intro: 'Ein Monat ist um. Jetzt lohnt der Blick darauf, was sich getan '
        'hat – und was wir nachschärfen.',
  );

  const CheckinTyp({required this.titel, required this.intro});

  final String titel;
  final String intro;

  /// Ob in dieser Stufe nach Wirkung gefragt wird. Tag 7 bleibt bewusst
  /// aussen vor: sichtbare Veraenderungen brauchen Wochen, und eine zu fruehe
  /// Ergebnisfrage frustriert nur.
  bool get fragtNachWirkung => this != CheckinTyp.alltag;

  /// Ob ein Fortschrittsfoto angeboten wird.
  bool get mitFortschrittsfoto => this == CheckinTyp.wirkung;
}

/// Das 3-Tap-Rating pro Habit.
enum HabitBewertung {
  laeuftGut('Läuft gut'),
  gehtSo('Geht so'),
  passtNicht('Passt nicht');

  const HabitBewertung(this.label);

  final String label;

  /// Ob nach dem Grund gefragt wird.
  bool get brauchtGrund => this == HabitBewertung.passtNicht;

  static HabitBewertung? ausName(Object? name) {
    for (final wert in values) {
      if (wert.name == name) return wert;
    }
    return null;
  }
}

/// Warum ein Habit nicht passt – die Auswahl entscheidet, wie die KI den
/// Habit umbaut.
enum PasstNichtGrund {
  zeit('Zu zeitaufwendig'),
  vergessen('Vergesse ich'),
  unangenehm('Unangenehm / mag ich nicht'),
  teuer('Zu teuer'),
  anderer('Anderer Grund');

  const PasstNichtGrund(this.label);

  final String label;

  /// Was die KI aus dem Grund machen soll.
  String get anweisung => switch (this) {
        PasstNichtGrund.zeit =>
          'kürzere Alternative oder geringere Frequenz wählen',
        PasstNichtGrund.vergessen =>
          'an eine bestehende Alltagsroutine koppeln (Trigger nennen)',
        PasstNichtGrund.unangenehm =>
          'durch etwas ersetzen, das denselben Zweck angenehmer erreicht',
        PasstNichtGrund.teuer =>
          'günstigere Alternative mit gleichem Zweck vorschlagen',
        PasstNichtGrund.anderer => 'den genannten Grund berücksichtigen',
      };

  static PasstNichtGrund? ausName(Object? name) {
    for (final wert in values) {
      if (wert.name == name) return wert;
    }
    return null;
  }
}

/// Antwortskala der Wirkungsfragen.
enum WirkungsAntwort {
  besser('Besser'),
  gleich('Gleich'),
  schlechter('Schlechter');

  const WirkungsAntwort(this.label);

  final String label;

  static WirkungsAntwort? ausName(Object? name) {
    for (final wert in values) {
      if (wert.name == name) return wert;
    }
    return null;
  }
}

/// Die Rueckmeldung zu einem einzelnen Habit.
class HabitFeedback {
  const HabitFeedback({
    required this.habit,
    required this.bewertung,
    this.grund,
    this.notiz = '',
  });

  final String habit;
  final HabitBewertung bewertung;

  /// Nur bei [HabitBewertung.passtNicht] gesetzt.
  final PasstNichtGrund? grund;

  /// Optionaler Freitext zum Grund.
  final String notiz;

  HabitFeedback copyWith({
    HabitBewertung? bewertung,
    PasstNichtGrund? grund,
    bool grundLoeschen = false,
    String? notiz,
  }) {
    return HabitFeedback(
      habit: habit,
      bewertung: bewertung ?? this.bewertung,
      grund: grundLoeschen ? null : (grund ?? this.grund),
      notiz: notiz ?? this.notiz,
    );
  }

  Map<String, dynamic> toJson() => {
        'habit': habit,
        'bewertung': bewertung.name,
        'grund': grund?.name,
        'notiz': notiz,
      };

  /// Liefert null, wenn die Bewertung fehlt oder unbekannt ist.
  static HabitFeedback? fromJson(Map<String, dynamic> json) {
    final bewertung = HabitBewertung.ausName(json['bewertung']);
    final habit = json['habit'];
    if (bewertung == null || habit is! String || habit.isEmpty) return null;

    return HabitFeedback(
      habit: habit,
      bewertung: bewertung,
      grund: PasstNichtGrund.ausName(json['grund']),
      notiz: json['notiz'] is String ? json['notiz'] as String : '',
    );
  }
}

/// Eine Wirkungsfrage samt stabiler ID – die ID steht in der Historie, damit
/// spaetere Textaenderungen alte Antworten nicht entwerten.
class WirkungsFrage {
  const WirkungsFrage({
    required this.id,
    required this.text,
    this.modul,
  });

  final String id;
  final String text;

  /// Zu welchem Modul die Frage gehoert; null = modulunabhaengig.
  final AnalyseModul? modul;
}

/// Die Antwort auf eine Wirkungsfrage.
class WirkungsFeedback {
  const WirkungsFeedback({
    required this.frageId,
    required this.frage,
    required this.antwort,
    this.notiz = '',
  });

  final String frageId;

  /// Der Fragetext zum Zeitpunkt der Antwort – so bleibt die Historie ohne
  /// Nachschlagen lesbar.
  final String frage;
  final WirkungsAntwort antwort;
  final String notiz;

  WirkungsFeedback copyWith({WirkungsAntwort? antwort, String? notiz}) =>
      WirkungsFeedback(
        frageId: frageId,
        frage: frage,
        antwort: antwort ?? this.antwort,
        notiz: notiz ?? this.notiz,
      );

  Map<String, dynamic> toJson() => {
        'frageId': frageId,
        'frage': frage,
        'antwort': antwort.name,
        'notiz': notiz,
      };

  static WirkungsFeedback? fromJson(Map<String, dynamic> json) {
    final antwort = WirkungsAntwort.ausName(json['antwort']);
    final id = json['frageId'];
    if (antwort == null || id is! String) return null;

    return WirkungsFeedback(
      frageId: id,
      frage: json['frage'] is String ? json['frage'] as String : '',
      antwort: antwort,
      notiz: json['notiz'] is String ? json['notiz'] as String : '',
    );
  }
}

/// Ein Check-in – im Entwurf waehrend der Beantwortung, danach als Eintrag
/// der Feedback-Historie.
class Checkin {
  const Checkin({
    required this.id,
    required this.typ,
    required this.faelligAm,
    this.erledigtAm,
    this.habits = const [],
    this.wirkung = const [],
    this.fortschrittsfoto,
    this.fazit = '',
    this.zusammenfassung = '',
  });

  /// Laufende Nummer der Reihe als ID (0 = Tag 7). Damit ist der Eintrag ohne
  /// Zufallszahlen eindeutig und zugleich sortierbar.
  final int id;

  final CheckinTyp typ;
  final DateTime faelligAm;
  final DateTime? erledigtAm;

  final List<HabitFeedback> habits;
  final List<WirkungsFeedback> wirkung;

  /// Pfad des Fortschrittsfotos, sofern eines aufgenommen wurde.
  final String? fortschrittsfoto;

  /// Kurzes Zwischenfazit der KI (nur beim Wirkungs-Check).
  final String fazit;

  /// Was nach diesem Check-in am Plan angepasst wurde.
  final String zusammenfassung;

  bool get istErledigt => erledigtAm != null;

  /// Habits, die der Nutzer als nicht alltagstauglich markiert hat.
  List<HabitFeedback> get problemHabits =>
      habits.where((h) => h.bewertung == HabitBewertung.passtNicht).toList();

  /// Habits, die beim naechsten Mal erneut abgefragt werden: alles, was nicht
  /// rundlaeuft.
  Set<String> get nachzufragen => {
        for (final h in habits)
          if (h.bewertung != HabitBewertung.laeuftGut) h.habit,
      };

  /// Ob zu jedem Habit eine Bewertung vorliegt.
  bool habitsVollstaendig(List<String> erwartet) {
    final bewertet = habits.map((h) => h.habit).toSet();
    return erwartet.every(bewertet.contains);
  }

  Checkin copyWith({
    DateTime? erledigtAm,
    List<HabitFeedback>? habits,
    List<WirkungsFeedback>? wirkung,
    String? fortschrittsfoto,
    bool fotoLoeschen = false,
    String? fazit,
    String? zusammenfassung,
  }) {
    return Checkin(
      id: id,
      typ: typ,
      faelligAm: faelligAm,
      erledigtAm: erledigtAm ?? this.erledigtAm,
      habits: habits ?? this.habits,
      wirkung: wirkung ?? this.wirkung,
      fortschrittsfoto:
          fotoLoeschen ? null : (fortschrittsfoto ?? this.fortschrittsfoto),
      fazit: fazit ?? this.fazit,
      zusammenfassung: zusammenfassung ?? this.zusammenfassung,
    );
  }

  /// Setzt die Bewertung eines Habits, ohne die Reihenfolge zu veraendern.
  Checkin mitBewertung(String habit, HabitBewertung bewertung) {
    final vorhanden = habits.where((h) => h.habit == habit).firstOrNull;
    final neu = vorhanden == null
        ? HabitFeedback(habit: habit, bewertung: bewertung)
        // Wechselt die Bewertung weg von "passt nicht", ist der Grund hinfaellig.
        : vorhanden.copyWith(
            bewertung: bewertung,
            grundLoeschen: !bewertung.brauchtGrund,
          );

    return copyWith(
      habits: [
        for (final h in habits)
          if (h.habit != habit) h,
        neu,
      ],
    );
  }

  Checkin mitGrund(String habit, PasstNichtGrund? grund, {String? notiz}) {
    return copyWith(
      habits: [
        for (final h in habits)
          if (h.habit == habit)
            h.copyWith(grund: grund, grundLoeschen: grund == null, notiz: notiz)
          else
            h,
      ],
    );
  }

  Checkin mitWirkung(WirkungsFrage frage, WirkungsAntwort antwort) {
    final vorhanden = wirkung.where((w) => w.frageId == frage.id).firstOrNull;
    final neu = vorhanden == null
        ? WirkungsFeedback(
            frageId: frage.id,
            frage: frage.text,
            antwort: antwort,
          )
        : vorhanden.copyWith(antwort: antwort);

    return copyWith(
      wirkung: [
        for (final w in wirkung)
          if (w.frageId != frage.id) w,
        neu,
      ],
    );
  }

  Checkin mitWirkungsnotiz(String frageId, String notiz) => copyWith(
        wirkung: [
          for (final w in wirkung)
            if (w.frageId == frageId) w.copyWith(notiz: notiz) else w,
        ],
      );

  HabitFeedback? feedbackZu(String habit) =>
      habits.where((h) => h.habit == habit).firstOrNull;

  WirkungsAntwort? antwortZu(String frageId) =>
      wirkung.where((w) => w.frageId == frageId).firstOrNull?.antwort;

  Map<String, dynamic> toJson() => {
        'id': id,
        'typ': typ.name,
        'faelligAm': faelligAm.toIso8601String(),
        'erledigtAm': erledigtAm?.toIso8601String(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'wirkung': wirkung.map((w) => w.toJson()).toList(),
        'fortschrittsfoto': fortschrittsfoto,
        'fazit': fazit,
        'zusammenfassung': zusammenfassung,
      };

  /// Liefert null, wenn Typ oder Termin fehlen – ein Eintrag ohne beides ist
  /// nicht sinnvoll zu retten.
  static Checkin? fromJson(Map<String, dynamic> json) {
    final typ = CheckinTyp.values
        .where((t) => t.name == json['typ'])
        .firstOrNull;
    final faellig = DateTime.tryParse(json['faelligAm']?.toString() ?? '');
    if (typ == null || faellig == null) return null;

    return Checkin(
      id: (json['id'] as num?)?.toInt() ?? 0,
      typ: typ,
      faelligAm: faellig,
      erledigtAm: DateTime.tryParse(json['erledigtAm']?.toString() ?? ''),
      habits: [
        for (final e in (json['habits'] as List? ?? const []).whereType<Map>())
          ?HabitFeedback.fromJson(Map<String, dynamic>.from(e)),
      ],
      wirkung: [
        for (final e in (json['wirkung'] as List? ?? const []).whereType<Map>())
          ?WirkungsFeedback.fromJson(Map<String, dynamic>.from(e)),
      ],
      fortschrittsfoto: switch (json['fortschrittsfoto']) {
        final String s when s.isNotEmpty => s,
        _ => null,
      },
      fazit: json['fazit'] is String ? json['fazit'] as String : '',
      zusammenfassung: json['zusammenfassung'] is String
          ? json['zusammenfassung'] as String
          : '',
    );
  }
}
