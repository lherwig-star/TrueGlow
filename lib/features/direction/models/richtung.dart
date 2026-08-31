import 'package:flutter/foundation.dart';

import '../../../core/l10n/texte.dart';

// Was der Nutzer der Analyse an eigenen Zielen mitgibt: eine geführte
// Auswahl plus ein freier Text. Beides ist optional und fliesst als eigener
// Abschnitt in den Prompt ein.

/// Die angebotenen Stilrichtungen.
///
/// Bewusst wertfrei formuliert – es geht um Richtung und Stil, nicht um
/// „besser" oder „schlechter".
///
/// **Überarbeitet in DECISIONS 58.** Die alte Liste („maskuliner", „weicher",
/// „markanter", „seriöser" …) beschrieb *Wirkungen* und traf damit die
/// Zielgruppe nicht: Für jemanden zwischen 16 und 25 ist „Seriöser wirken"
/// keine Stilrichtung, und jugendliche Stile kamen überhaupt nicht vor.
/// Die neue Liste beschreibt *Stile*, die man auch außerhalb dieser App so
/// nennt – und jeder trägt einen kurzen Untertext, damit sie auch ohne
/// Modewissen verständlich sind.
///
/// Alte gespeicherte Werte gehen dabei nicht verloren: [ausName] führt sie
/// auf ihren nächsten Nachfolger über.
enum Richtungsziel {
  cleanGepflegt,
  markantMaskulin,
  natuerlichEntspannt,
  weichElegant,
  streetwearLaessig,
  smartHochwertig,
  sportlichFunktional,
  kreativAuffaellig;

  /// Was aus den Werten der alten Liste geworden ist.
  ///
  /// Der Grundsatz: der **nächste vorhandene Nachbar**, nie ein Wegfall. Wer
  /// „Gepflegter" gewählt hatte, findet seine Auswahl als „Clean & gepflegt"
  /// wieder und muss nicht rätseln, warum sie leer ist.
  ///
  /// Zwei Fälle sind ehrliche Näherungen und keine Übersetzungen:
  /// `juenger` wird zu „Streetwear & lässig" – die jugendliche Richtung, die
  /// die neue Liste überhaupt erst eingeführt hat –, und `reifer` zu
  /// „Smart & hochwertig". Beides ist das Nächstgelegene, nicht dasselbe.
  /// Wer das anders sieht, ändert es mit zwei Tipps im Bildschirm „Deine
  /// Richtung".
  static const _alteNamen = {
    'maskuliner': Richtungsziel.markantMaskulin,
    'markanter': Richtungsziel.markantMaskulin,
    'weicher': Richtungsziel.weichElegant,
    'gepflegter': Richtungsziel.cleanGepflegt,
    'serioeser': Richtungsziel.smartHochwertig,
    'reifer': Richtungsziel.smartHochwertig,
    'juenger': Richtungsziel.streetwearLaessig,
    'natuerlicher': Richtungsziel.natuerlichEntspannt,
    'auffaelliger': Richtungsziel.kreativAuffaellig,
    'sportlicher': Richtungsziel.sportlichFunktional,
  };

  /// Liest einen gespeicherten Namen – auch einen aus der alten Liste.
  /// Unbekannte Namen fallen weg.
  static Richtungsziel? ausName(Object? name) {
    for (final ziel in values) {
      if (ziel.name == name) return ziel;
    }
    return _alteNamen[name];
  }
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension RichtungszielText on Richtungsziel {
  String label(L texte) => switch (this) {
        Richtungsziel.cleanGepflegt => texte.richtungszielClean,
        Richtungsziel.markantMaskulin => texte.richtungszielMarkant,
        Richtungsziel.natuerlichEntspannt => texte.richtungszielNatuerlich,
        Richtungsziel.weichElegant => texte.richtungszielWeich,
        Richtungsziel.streetwearLaessig => texte.richtungszielStreetwear,
        Richtungsziel.smartHochwertig => texte.richtungszielSmart,
        Richtungsziel.sportlichFunktional => texte.richtungszielSportlich,
        Richtungsziel.kreativAuffaellig => texte.richtungszielKreativ,
      };

  /// Drei bis sieben Wörter, die den Stil greifbar machen.
  ///
  /// Ohne sie ist „Smart & hochwertig" für jemanden ohne Modewissen eine
  /// leere Hülle.
  ///
  /// **Neu gefasst in DECISIONS 86.** Die alten Untertexte beschrieben fast
  /// nur Kleidung („Baggy, Oversized, Sneaker"). Eine Richtung prägt aber
  /// Frisur, Bart, Ausstrahlung *und* Kleidung – der Server sagt das in
  /// `RICHTUNGSVORGABE` längst so, die App sagte es nicht. Jetzt ist der
  /// Untertext die Kurzfassung derselben Vorgabe.
  String untertext(L texte) => switch (this) {
        Richtungsziel.cleanGepflegt => texte.richtungszielCleanUnter,
        Richtungsziel.markantMaskulin => texte.richtungszielMarkantUnter,
        Richtungsziel.natuerlichEntspannt =>
          texte.richtungszielNatuerlichUnter,
        Richtungsziel.weichElegant => texte.richtungszielWeichUnter,
        Richtungsziel.streetwearLaessig => texte.richtungszielStreetwearUnter,
        Richtungsziel.smartHochwertig => texte.richtungszielSmartUnter,
        Richtungsziel.sportlichFunktional => texte.richtungszielSportlichUnter,
        Richtungsziel.kreativAuffaellig => texte.richtungszielKreativUnter,
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
