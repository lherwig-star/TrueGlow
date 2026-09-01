import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../analysis/models/analysis_result.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/models/analyse_modul.dart';
import '../../plan/logic/plan_progress_repository.dart';
import '../../plan/logic/wochen_challenge.dart';
import '../models/abzeichen.dart';

/// Wann ein Tag als geschafft gilt.
enum Tagesziel {
  /// Mindestens eine Aufgabe abgehakt.
  eineAufgabe,

  /// Alle Tagesaufgaben abgehakt.
  alleAufgaben,
}

/// Aktueller Stand der Serie.
class StreakStand {
  const StreakStand({
    required this.aktuell,
    required this.rekord,
    required this.letzterTag,
    required this.heuteGesichert,
    required this.gefeiert,
    this.jokerUebrig = StreakRepository.jokerProMonat,
    this.ungemeldeteJoker = 0,
  });

  /// Tage am Stueck.
  final int aktuell;

  /// Laengste je erreichte Serie. Bleibt beim Zuruecksetzen stehen.
  final int rekord;

  /// Letzter Tag, an dem das Tagesziel erreicht wurde.
  final DateTime? letzterTag;

  /// Ob der heutige Tag schon gesichert ist – steuert die gedimmte Flamme.
  final bool heuteGesichert;

  /// Abzeichen, deren Jubel-Moment bereits gezeigt wurde.
  final Set<Abzeichen> gefeiert;

  /// Joker, die diesen Kalendermonat noch zur Verfuegung stehen.
  final int jokerUebrig;

  /// Joker, die eingesprungen sind, ohne dass es der Nutzer schon gesehen
  /// hat. Steuert den freundlichen Hinweis auf der Streak-Karte.
  final int ungemeldeteJoker;

  /// Ob die Serie gerissen ist, obwohl es schon einmal eine gab. Der
  /// Unterschied zaehlt fuer den Ton: „Neustart" statt einer nackten Null.
  bool get neustartNachSerie => aktuell == 0 && rekord > 0;

  static const leer = StreakStand(
    aktuell: 0,
    rekord: 0,
    letzterTag: null,
    heuteGesichert: false,
    gefeiert: {},
  );
}

/// Was die Rueckwaertsrechnung ergeben hat.
class Serienstand {
  const Serienstand({required this.laenge, required this.neueJoker});

  /// Tage am Stueck, an denen wirklich etwas abgehakt wurde.
  final int laenge;

  /// Tage, fuer die bei dieser Rechnung erstmals ein Joker eingesprungen ist
  /// – als Tagesschluessel `jjjj-mm-tt`.
  final List<String> neueJoker;
}

/// Zaehlt die Serie rueckwaerts und laesst Joker fuer verpasste Tage
/// einspringen.
///
/// Bewusst eine freie Funktion ohne Speicher: Hier steckt die ganze Regel,
/// und sie soll sich ohne Hive und ohne Riverpod durchspielen lassen.
///
/// **Ein geretteter Tag ueberbrueckt, er zaehlt aber nicht mit.** „Tage am
/// Stueck" sind Tage, an denen wirklich etwas passiert ist – ein Joker haelt
/// die Kette zusammen, erfindet aber keinen Tag. Alles andere waere eine
/// Zahl, die dem Nutzer mehr erzaehlt, als er getan hat.
///
/// **Ein Joker wird nur zum Ueberbruecken ausgegeben**, nie am losen Ende.
/// Sonst verbraeuchte ein Nutzer, der noch nie etwas abgehakt hat, beim
/// ersten Start beide Joker und bekaeme eine Serie geschenkt. Ein vorlaeufig
/// gesetzter Joker zaehlt deshalb erst, wenn dahinter noch ein wirklich
/// geschaffter Tag kommt.
Serienstand serieRechnen({
  required DateTime start,
  required bool Function(DateTime tag) geschafft,
  required Set<String> jokerTage,
  required int jokerProMonat,
  int maxTage = 3650,
}) {
  final verbraucht = <String, int>{};
  for (final tag in jokerTage) {
    final monat = tag.length >= 7 ? tag.substring(0, 7) : tag;
    verbraucht[monat] = (verbraucht[monat] ?? 0) + 1;
  }

  var tag = start;
  var laenge = 0;
  final bestaetigt = <String>[];
  var offen = <String>[];

  for (var schritt = 0; schritt < maxTage; schritt += 1) {
    if (geschafft(tag)) {
      laenge += 1;
      // Alles, was bis hierher vorlaeufig ueberbrueckt wurde, ist jetzt ein
      // echter Lueckenschluss.
      bestaetigt.addAll(offen);
      offen = <String>[];
      tag = tag.subtract(const Duration(days: 1));
      continue;
    }

    final schluessel = PlanProgressRepository.schluessel(tag);

    // Ein Tag, der frueher schon gerettet wurde, bleibt gerettet – auch
    // wenn das Monatskontingent inzwischen anders aussieht.
    if (jokerTage.contains(schluessel)) {
      tag = tag.subtract(const Duration(days: 1));
      continue;
    }

    final monat = schluessel.substring(0, 7);
    final frei = jokerProMonat - (verbraucht[monat] ?? 0);
    // Ohne begonnene Serie gibt es nichts zu retten.
    if (frei <= 0 || laenge == 0) break;

    verbraucht[monat] = (verbraucht[monat] ?? 0) + 1;
    offen.add(schluessel);
    tag = tag.subtract(const Duration(days: 1));
  }

  return Serienstand(laenge: laenge, neueJoker: bestaetigt);
}

/// Rechnet die Serie aus den abgehakten Tagen und haelt Rekord sowie die
/// bereits gefeierten Abzeichen fest.
///
/// Die Serie selbst wird bewusst immer neu aus den Tagesdaten abgeleitet statt
/// nur fortgeschrieben: damit stimmt sie auch dann, wenn die App tagelang
/// nicht offen war – der Reset passiert schon beim Laden und nicht erst beim
/// naechsten Abhaken.
class StreakRepository {
  StreakRepository(this._box, this._fortschritt);

  final KeyValueStore _box;
  final PlanProgressRepository _fortschritt;

  /// Umschalter fuer die Bedingung eines geschafften Tages.
  static const Tagesziel tagesziel = Tagesziel.eineAufgabe;

  /// So viele verpasste Tage faengt die App pro Kalendermonat ab.
  ///
  /// Kalendermonat, weil er sich erklaeren laesst: „am Ersten wieder zwei".
  /// Dieselbe Ueberlegung wie beim Analyse-Kontingent (DECISIONS 42).
  static const jokerProMonat = 2;

  /// Sicherheitsnetz gegen kaputte Daten beim Rueckwaertslaufen.
  static const _maxTage = 3650;

  static const _kAktuell = 'streakAktuell';
  static const _kRekord = 'streakRekord';
  static const _kLetzterTag = 'streakLetzterTag';
  static const _kGefeiert = 'abzeichenGefeiert';

  /// Tage, an denen ein Joker eingesprungen ist (`jjjj-mm-tt`).
  static const _kJoker = 'streakJokerTage';

  /// Davon diejenigen, die der Nutzer schon gesehen hat.
  static const _kJokerGemeldet = 'streakJokerGemeldet';

  static DateTime heute() {
    final jetzt = DateTime.now();
    return DateTime(jetzt.year, jetzt.month, jetzt.day);
  }

  /// Ob an [tag] das Tagesziel erreicht wurde.
  ///
  /// Im Modus [Tagesziel.alleAufgaben] wird die heutige Aufgabenliste auch auf
  /// vergangene Tage angewandt – die damalige Liste ist nicht gespeichert.
  bool geschafftAm(DateTime tag, List<String> habits) {
    final erledigt = _fortschritt.erledigteAm(tag);
    return switch (tagesziel) {
      Tagesziel.eineAufgabe => erledigt.isNotEmpty,
      Tagesziel.alleAufgaben =>
        habits.isNotEmpty && habits.every(erledigt.contains),
    };
  }

  /// Zaehlt aufeinanderfolgende geschaffte Tage – Joker inbegriffen.
  ///
  /// Der heutige Tag zaehlt nur mit, wenn schon etwas erledigt ist – ein noch
  /// leerer Vormittag soll die Serie aber nicht abreissen lassen. Aus
  /// demselben Grund kann fuer heute nie ein Joker einspringen: Der Tag ist
  /// noch offen.
  Serienstand berechneSerie(List<String> habits) {
    final start = heute();
    return serieRechnen(
      start: geschafftAm(start, habits)
          ? start
          : start.subtract(const Duration(days: 1)),
      geschafft: (tag) => geschafftAm(tag, habits),
      jokerTage: jokerTage,
      jokerProMonat: jokerProMonat,
      maxTage: _maxTage,
    );
  }

  int berechneAktuell(List<String> habits) => berechneSerie(habits).laenge;

  /// Tage, an denen bisher ein Joker eingesprungen ist.
  Set<String> get jokerTage => _tagesliste(_kJoker);

  /// Wie viele Joker dieser Kalendermonat noch hergibt.
  int get jokerUebrig => jokerUebrigAm(heute());

  /// Dasselbe für einen beliebigen Tag.
  ///
  /// Mit Datum und nicht nur für heute, damit sich die Regel „am Ersten
  /// wieder zwei" prüfen lässt, ohne auf den Monatswechsel zu warten: Ein
  /// Test, der `DateTime.now()` benutzt, sagt am 15. etwas anderes als am 1.
  int jokerUebrigAm(DateTime tag) {
    final monat = PlanProgressRepository.schluessel(tag).substring(0, 7);
    final verbraucht = jokerTage.where((t) => t.startsWith(monat)).length;
    return (jokerProMonat - verbraucht).clamp(0, jokerProMonat);
  }

  Set<String> _tagesliste(String schluessel) {
    final roh = _box.get(schluessel);
    return roh is List ? roh.whereType<String>().toSet() : <String>{};
  }

  /// Merkt sich, dass der Nutzer den Joker-Hinweis gesehen hat.
  Future<void> jokerGemeldet() async {
    await _box.put(_kJokerGemeldet, jokerTage.toList());
  }

  /// Letzter geschaffter Tag – heute oder gestern, sonst der gespeicherte.
  DateTime? _letzterTag(List<String> habits) {
    final start = heute();
    if (geschafftAm(start, habits)) return start;

    final gestern = start.subtract(const Duration(days: 1));
    if (geschafftAm(gestern, habits)) return gestern;

    final gespeichert = _box.get(_kLetzterTag);
    return gespeichert is String ? DateTime.tryParse(gespeichert) : null;
  }

  /// Liest den Stand, rechnet ihn neu und schreibt ihn zurueck.
  StreakStand laden(List<String> habits) {
    final serie = berechneSerie(habits);
    final aktuell = serie.laenge;
    final gespeicherterRekord = switch (_box.get(_kRekord)) {
      final int i => i,
      _ => 0,
    };
    final rekord = math.max(aktuell, gespeicherterRekord);
    final letzter = _letzterTag(habits);

    // Ein eingesprungener Joker wird festgeschrieben, sonst spraenge er beim
    // naechsten Laden erneut ein und das Monatskontingent waere wertlos.
    final alleJoker = {...jokerTage, ...serie.neueJoker};
    if (serie.neueJoker.isNotEmpty) {
      _box.put(_kJoker, alleJoker.toList());
    }

    _box.put(_kAktuell, aktuell);
    _box.put(_kRekord, rekord);
    if (letzter != null) {
      _box.put(_kLetzterTag, letzter.toIso8601String());
    }

    final gemeldet = _tagesliste(_kJokerGemeldet);

    return StreakStand(
      aktuell: aktuell,
      rekord: rekord,
      letzterTag: letzter,
      heuteGesichert: geschafftAm(heute(), habits),
      gefeiert: _gefeierte(),
      jokerUebrig: jokerUebrig,
      ungemeldeteJoker: alleJoker.difference(gemeldet).length,
    );
  }

  Set<Abzeichen> _gefeierte() {
    final roh = _box.get(_kGefeiert);
    if (roh is! List) return {};
    return {
      for (final name in roh.whereType<String>())
        ...Abzeichen.values.where((a) => a.name == name),
    };
  }

  Future<void> alsGefeiertMerken(Abzeichen abzeichen) async {
    final neu = {..._gefeierte(), abzeichen};
    await _box.put(_kGefeiert, neu.map((a) => a.name).toList());
  }
}

/// Ermittelt, welche Abzeichen erreicht sind und was den offenen noch fehlt.
List<AbzeichenStand> abzeichenStaende({
  required StreakStand streak,
  required AnalysisResult? analyse,
  int challenges = 0,
}) {
  final module = analyse?.module ?? const <AnalyseModul>{};
  // Gezaehlt wird nur, was sich bestellen laesst. Das Zielkapitel entsteht
  // aus dem Freitext und waere sonst ein Abzeichen fuer einen Satz Text.
  final bestellbar = AnalyseModul.bestellbar;
  final erreichte = module.where(bestellbar.contains).length;
  final alleModule = erreichte == bestellbar.length;

  return [
    for (final abzeichen in Abzeichen.values)
      switch (abzeichen) {
        Abzeichen.ersteAnalyse => AbzeichenStand(
            abzeichen: abzeichen,
            erreicht: analyse != null,
            fehlend: analyse != null ? 0 : 1,
          ),
        Abzeichen.alleModule => AbzeichenStand(
            abzeichen: abzeichen,
            erreicht: alleModule,
            fehlend: bestellbar.length - erreichte,
          ),
        Abzeichen.challenges => AbzeichenStand(
            abzeichen: abzeichen,
            erreicht: challenges >= Abzeichen.challengeZiel,
            fehlend: (Abzeichen.challengeZiel - challenges)
                .clamp(0, Abzeichen.challengeZiel),
          ),
        _ => AbzeichenStand(
            abzeichen: abzeichen,
            erreicht: streak.aktuell >= abzeichen.tage!,
            fehlend: (abzeichen.tage! - streak.aktuell).clamp(0, abzeichen.tage!),
          ),
      },
  ];
}

class StreakNotifier extends StateNotifier<StreakStand> {
  StreakNotifier(this._repo, this._habits) : super(StreakStand.leer) {
    aktualisieren();
  }

  final StreakRepository _repo;
  final List<String> Function() _habits;

  void aktualisieren() => state = _repo.laden(_habits());

  Future<void> gefeiert(Abzeichen abzeichen) async {
    await _repo.alsGefeiertMerken(abzeichen);
    aktualisieren();
  }

  /// Der Joker-Hinweis wurde gezeigt.
  Future<void> jokerGemeldet() async {
    await _repo.jokerGemeldet();
    aktualisieren();
  }
}

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepository(
    ref.watch(storeProvider(HiveService.boxFortschritt)),
    ref.watch(planProgressRepositoryProvider),
  );
});

final streakProvider = StateNotifierProvider<StreakNotifier, StreakStand>(
  (ref) {
    final notifier = StreakNotifier(
      ref.watch(streakRepositoryProvider),
      () => ref.read(aktuelleAnalyseProvider)?.alleHabits ?? const [],
    );
    // Jeder Haken und jede neue Analyse kann die Serie veraendern.
    ref.listen(planFortschrittProvider, (_, _) => notifier.aktualisieren());
    ref.listen(analysenProvider, (_, _) => notifier.aktualisieren());
    return notifier;
  },
);

/// Abzeichen mit ihrem aktuellen Stand, in Anzeigereihenfolge.
final abzeichenProvider = Provider<List<AbzeichenStand>>((ref) {
  return abzeichenStaende(
    streak: ref.watch(streakProvider),
    analyse: ref.watch(aktuelleAnalyseProvider),
    challenges: ref.watch(geschaffteChallengesProvider),
  );
});

/// Das naechste Abzeichen, dessen Jubel-Moment noch aussteht.
final offenerJubelProvider = Provider<Abzeichen?>((ref) {
  final gefeiert = ref.watch(streakProvider).gefeiert;
  return ref
      .watch(abzeichenProvider)
      .where((s) => s.erreicht && !gefeiert.contains(s.abzeichen))
      .map((s) => s.abzeichen)
      .firstOrNull;
});
