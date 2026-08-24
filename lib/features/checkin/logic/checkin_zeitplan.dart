import '../models/checkin.dart';

/// Reine Terminrechnung der Check-in-Reihe – ohne Speicher und ohne Riverpod,
/// damit sich die Regeln direkt testen lassen.
///
/// Die Reihe laeuft relativ zum Start des Plans: Tag 7, Tag 14, Tag 30, danach
/// alle 30 Tage. Faellt ein Check-in aus, verfaellt er nicht: Er bleibt offen,
/// und der naechste bekommt seinen Abstand erst ab dem Tag, an dem der
/// vorherige tatsaechlich erledigt wurde. So stapeln sich nie mehrere.
class CheckinZeitplan {
  CheckinZeitplan._();

  /// Abstaende der ersten drei Termine ab Planstart.
  static const tagesmarken = [7, 14, 30];

  /// Takt aller weiteren Check-ins.
  static const folgeAbstand = 30;

  /// Welche Stufe der Check-in mit dieser laufenden Nummer hat.
  static CheckinTyp typFuer(int index) => switch (index) {
        0 => CheckinTyp.alltag,
        1 => CheckinTyp.zwischen,
        _ => CheckinTyp.wirkung,
      };

  /// Abstand in Tagen zum vorherigen Check-in – fuer den ersten der Abstand
  /// zum Planstart.
  static int abstandTage(int index) {
    if (index <= 0) return tagesmarken.first;
    if (index < tagesmarken.length) {
      return tagesmarken[index] - tagesmarken[index - 1];
    }
    return folgeAbstand;
  }

  /// Termin des Check-ins [index]. [zuletztErledigt] ist der Zeitpunkt, an dem
  /// der vorherige Check-in abgeschlossen wurde; ohne Vorgaenger zaehlt der
  /// Planstart.
  static DateTime termin({
    required int index,
    required DateTime planStart,
    DateTime? zuletztErledigt,
  }) {
    final basis = index == 0 ? planStart : (zuletztErledigt ?? planStart);
    return _aufTag(basis).add(Duration(days: abstandTage(index)));
  }

  /// Ob ein Check-in mit diesem Termin ansteht. Verglichen wird auf Tagesebene:
  /// Der Check-in ist den ganzen faelligen Tag ueber offen, nicht erst zur
  /// Uhrzeit des Planstarts.
  static bool istFaellig(DateTime termin, {DateTime? jetzt}) {
    final heute = _aufTag(jetzt ?? DateTime.now());
    return !heute.isBefore(_aufTag(termin));
  }

  /// Tage bis zum Termin; 0 oder negativ heisst faellig.
  static int tageBis(DateTime termin, {DateTime? jetzt}) =>
      _aufTag(termin).difference(_aufTag(jetzt ?? DateTime.now())).inDays;

  static DateTime _aufTag(DateTime zeitpunkt) =>
      DateTime(zeitpunkt.year, zeitpunkt.month, zeitpunkt.day);
}
