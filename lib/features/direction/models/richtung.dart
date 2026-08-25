import 'package:flutter/foundation.dart';

import '../../../core/l10n/texte.dart';

// Was der Nutzer der Analyse an eigenen Zielen mitgibt: eine geführte
// Auswahl plus ein freier Text. Beides ist optional und fliesst als eigener
// Abschnitt in den Prompt ein.

/// Die angebotenen Richtungen. Bewusst wertfrei formuliert – es geht um
/// Richtung und Stil, nicht um "besser" oder "schlechter".
enum Richtungsziel {
  maskuliner,
  weicher,
  markanter,
  gepflegter,
  serioeser,
  juenger,
  reifer,
  natuerlicher,
  auffaelliger,
  sportlicher;

  /// Liest einen gespeicherten Namen; unbekannte Namen fallen weg.
  static Richtungsziel? ausName(Object? name) {
    for (final ziel in values) {
      if (ziel.name == name) return ziel;
    }
    return null;
  }
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension RichtungszielText on Richtungsziel {
  String label(L texte) => switch (this) {
        Richtungsziel.maskuliner => texte.richtungszielMaskuliner,
        Richtungsziel.weicher => texte.richtungszielWeicher,
        Richtungsziel.markanter => texte.richtungszielMarkanter,
        Richtungsziel.gepflegter => texte.richtungszielGepflegter,
        Richtungsziel.serioeser => texte.richtungszielSerioeser,
        Richtungsziel.juenger => texte.richtungszielJuenger,
        Richtungsziel.reifer => texte.richtungszielReifer,
        Richtungsziel.natuerlicher => texte.richtungszielNatuerlicher,
        Richtungsziel.auffaelliger => texte.richtungszielAuffaelliger,
        Richtungsziel.sportlicher => texte.richtungszielSportlicher,
      };
}

/// Die persönliche Richtung des Nutzers.
@immutable
class Richtung {
  const Richtung({this.ziele = const {}, this.freitext = ''});

  /// Mehrfachauswahl aus [Richtungsziel].
  final Set<Richtungsziel> ziele;

  /// Freitext an die Analyse. Kein Chat – der Text wird einmalig mit der
  /// Analyse verarbeitet.
  final String freitext;

  /// Grosszuegiges Limit fuer den Freitext.
  static const int maxZeichen = 1000;

  static const leer = Richtung();

  bool get istLeer => ziele.isEmpty && freitext.trim().isEmpty;

  /// Ziele in der Reihenfolge der Deklaration – damit Chips und Prompt
  /// unabhaengig von der Klickreihenfolge gleich sortiert sind.
  List<Richtungsziel> get sortierteZiele =>
      Richtungsziel.values.where(ziele.contains).toList();

  /// Kurzfassung des Freitexts fuer die Karte im Report.
  String get kurzfassung {
    final text = freitext.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= 140) return text;
    return '${text.substring(0, 139).trimRight()}…';
  }

  Richtung copyWith({Set<Richtungsziel>? ziele, String? freitext}) => Richtung(
        ziele: ziele ?? this.ziele,
        freitext: freitext ?? this.freitext,
      );

  Map<String, dynamic> toJson() => {
        'ziele': sortierteZiele.map((z) => z.name).toList(),
        'freitext': freitext,
      };

  factory Richtung.fromJson(Map<String, dynamic> json) => Richtung(
        ziele: {
          for (final name in (json['ziele'] as List? ?? const []))
            ?Richtungsziel.ausName(name),
        },
        freitext: switch (json['freitext']) {
          final String s => _gekuerzt(s),
          _ => '',
        },
      );

  /// Schneidet ueberlanges auf [maxZeichen] – schuetzt vor einem
  /// aufgeblaehten Prompt, egal woher der Text kommt.
  static String _gekuerzt(String text) =>
      text.length <= maxZeichen ? text : text.substring(0, maxZeichen);

  @override
  bool operator ==(Object other) =>
      other is Richtung &&
      setEquals(ziele, other.ziele) &&
      freitext.trim() == other.freitext.trim();

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(ziele),
        freitext.trim(),
      );
}
