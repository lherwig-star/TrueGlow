import '../../../core/l10n/texte.dart';

// Nachweisbare Einwilligungen. Eine pauschale Checkbox ohne Zeitstempel und
// ohne Textversion haelt einer Pruefung nicht stand – erst recht nicht bei
// Gesichtsfotos, die als biometrienah gelten.

/// Wofuer jemand einzeln zustimmt.
///
/// Bewusst getrennt: Die Nutzung der App und die Verarbeitung von
/// Gesichtsfotos durch einen KI-Dienst sind zwei verschiedene Dinge. Wer das
/// eine will, muss dem anderen nicht zustimmen.
enum Einwilligungsart {
  /// Nutzungsbedingungen und Datenschutzerklaerung. Ohne sie laeuft die App
  /// nicht – sie beschreibt, was ueberhaupt passiert.
  nutzung(pflicht: true),

  /// Bestaetigung, mindestens 18 Jahre alt zu sein.
  ///
  /// TrueGlow richtet sich ausschliesslich an Erwachsene. Ohne diese
  /// Bestaetigung bleibt der Analyse-Flow zu – der Rest der App nicht:
  /// Eine Sackgasse ohne Erklaerung waere die schlechtere Antwort auf ein
  /// unbeantwortetes Haekchen.
  ///
  /// Formal keine Einwilligung, sondern eine Erklaerung. Sie liegt trotzdem
  /// hier, weil sie denselben Nachweis braucht: wann, zu welcher Textfassung,
  /// an welcher Stelle.
  mindestalter(pflicht: false),

  /// Verarbeitung von Gesichtsfotos durch den KI-Dienst. Freiwillig und
  /// jederzeit widerrufbar; ohne sie gibt es keine neuen Analysen, die
  /// bestehenden Reports bleiben aber erhalten.
  fotoKi(pflicht: false),

  /// Absturzberichte und eine sehr sparsame Nutzungsstatistik.
  ///
  /// Standardmaessig aus. Ohne sie erfaehrt niemand von Abstuerzen ausser
  /// ueber Ein-Sterne-Bewertungen – deshalb wird gefragt, aber eben gefragt.
  diagnose(pflicht: false);

  const Einwilligungsart({required this.pflicht});

  /// Ob die App ohne diese Einwilligung gar nicht benutzbar ist.
  final bool pflicht;

  static Einwilligungsart? ausName(Object? name) {
    for (final art in values) {
      if (art.name == name) return art;
    }
    return null;
  }
}

/// Wo eine Einwilligung erteilt oder widerrufen wurde.
///
/// Teil des Nachweises: Bei einer Beschwerde ist die Frage nicht nur *ob*,
/// sondern auch *wo* jemand zugestimmt hat.
enum Einwilligungskanal {
  onboarding,
  einstellungen,

  /// Nachtraeglich eingeholt, weil sich die Textversion geaendert hat oder
  /// die alte Sammel-Checkbox abgeloest wurde.
  nachtrag;

  static Einwilligungskanal ausName(Object? name) {
    for (final kanal in values) {
      if (kanal.name == name) return kanal;
    }
    return Einwilligungskanal.nachtrag;
  }
}

/// Eine einzelne, nachweisbare Entscheidung.
class Einwilligung {
  const Einwilligung({
    required this.art,
    required this.erteilt,
    required this.zeitpunkt,
    required this.textversion,
    required this.kanal,
  });

  final Einwilligungsart art;

  /// `false` heisst: ausdruecklich widerrufen. Das ist etwas anderes als
  /// „nie gefragt" – dafuer fehlt der Eintrag ganz.
  final bool erteilt;

  final DateTime zeitpunkt;

  /// Version der Rechtstexte, auf die sich die Entscheidung bezieht.
  final String textversion;

  final Einwilligungskanal kanal;

  Map<String, dynamic> toJson() => {
        'art': art.name,
        'erteilt': erteilt,
        'zeitpunkt': zeitpunkt.toUtc().toIso8601String(),
        'textversion': textversion,
        'kanal': kanal.name,
      };

  /// Liefert null, wenn Art oder Zeitpunkt fehlen – ein Nachweis ohne beides
  /// ist keiner.
  static Einwilligung? fromJson(Map<String, dynamic> json) {
    final art = Einwilligungsart.ausName(json['art']);
    final zeitpunkt = DateTime.tryParse('${json['zeitpunkt']}');
    if (art == null || zeitpunkt == null) return null;

    return Einwilligung(
      art: art,
      erteilt: json['erteilt'] == true,
      zeitpunkt: zeitpunkt.toUtc(),
      textversion: json['textversion'] is String
          ? json['textversion'] as String
          : '',
      kanal: Einwilligungskanal.ausName(json['kanal']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Einwilligung &&
      other.art == art &&
      other.erteilt == erteilt &&
      other.zeitpunkt == zeitpunkt &&
      other.textversion == textversion &&
      other.kanal == kanal;

  @override
  int get hashCode => Object.hash(art, erteilt, zeitpunkt, textversion, kanal);

  @override
  String toString() =>
      'Einwilligung(${art.name}, erteilt: $erteilt, $textversion, '
      '${kanal.name}, $zeitpunkt)';
}

/// Der Stand aller Einwilligungen eines Kontos.
class Einwilligungsstand {
  const Einwilligungsstand({this.eintraege = const {}});

  final Map<Einwilligungsart, Einwilligung> eintraege;

  static const leer = Einwilligungsstand();

  Einwilligung? eintrag(Einwilligungsart art) => eintraege[art];

  /// Ob eine Einwilligung erteilt ist **und** sich auf die aktuell geltenden
  /// Texte bezieht.
  ///
  /// Aendert sich die Textversion, gilt die alte Zustimmung nicht mehr: Die
  /// Person hat etwas anderem zugestimmt als dem, was jetzt gilt.
  bool gilt(Einwilligungsart art, String textversion) {
    final eintrag = eintraege[art];
    return eintrag != null &&
        eintrag.erteilt &&
        eintrag.textversion == textversion;
  }

  /// Ob ueberhaupt schon einmal entschieden wurde.
  bool wurdeGefragt(Einwilligungsart art) => eintraege.containsKey(art);

  Einwilligungsstand mit(Einwilligung einwilligung) => Einwilligungsstand(
        eintraege: {...eintraege, einwilligung.art: einwilligung},
      );

  Map<String, dynamic> toJson() => {
        for (final eintrag in eintraege.values)
          eintrag.art.name: eintrag.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is Einwilligungsstand &&
      other.eintraege.length == eintraege.length &&
      eintraege.entries.every((e) => other.eintraege[e.key] == e.value);

  @override
  int get hashCode => Object.hashAllUnordered(eintraege.values);

  factory Einwilligungsstand.fromJson(Map<String, dynamic> json) {
    final eintraege = <Einwilligungsart, Einwilligung>{};
    for (final wert in json.values) {
      if (wert is! Map) continue;
      final gelesen = Einwilligung.fromJson(Map<String, dynamic>.from(wert));
      if (gelesen != null) eintraege[gelesen.art] = gelesen;
    }
    return Einwilligungsstand(eintraege: eintraege);
  }
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension EinwilligungsartText on Einwilligungsart {
  String titel(L texte) => switch (this) {
        Einwilligungsart.nutzung => texte.einwilligungNutzung,
        Einwilligungsart.mindestalter => texte.einwilligungMindestalter,
        Einwilligungsart.fotoKi => texte.einwilligungFotoKi,
        Einwilligungsart.diagnose => texte.einwilligungDiagnose,
      };
}
