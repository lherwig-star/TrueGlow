import 'package:intl/intl.dart';

/// Datums- und Zeitformate der App.
///
/// Seit der Zweisprachigkeit über `intl` statt über eine eigene Monatsliste:
/// Ein deutscher „22. August 2026" heißt auf Englisch „August 22, 2026" – die
/// Reihenfolge ändert sich, nicht nur das Wort. Das von Hand nachzubauen wäre
/// für jede weitere Sprache erneut Arbeit und in jeder Sprache neu falsch.
///
/// Jede Methode nimmt den Sprachcode entgegen (`texte.localeName`). Die
/// Formatdaten dazu lädt `flutter_localizations` beim Setzen der Sprache mit;
/// eine eigene Initialisierung braucht es nicht.
class Datum {
  Datum._();

  /// z. B. „22. August 2026" bzw. „August 22, 2026"
  static String lang(DateTime datum, String sprache) =>
      DateFormat.yMMMMd(sprache).format(datum);

  /// z. B. „22.08.2026" bzw. „08/22/2026"
  static String nurTag(DateTime datum, String sprache) =>
      DateFormat.yMd(sprache).format(datum);

  /// z. B. „22.08.2026, 14:05"
  static String kurz(DateTime datum, String sprache) =>
      '${DateFormat.yMd(sprache).format(datum)}, '
      '${DateFormat.Hm(sprache).format(datum)}';

  /// „heute", „gestern" oder das lange Datum.
  ///
  /// [heute] und [gestern] kommen von außen, weil sie in der ARB-Datei stehen
  /// und nicht in `intl` – die Bibliothek kennt Monatsnamen, aber keine
  /// Umgangssprache.
  static String relativ(
    DateTime datum,
    String sprache, {
    required String heute,
    required String gestern,
  }) {
    final jetzt = DateTime.now();
    final tage = DateTime(jetzt.year, jetzt.month, jetzt.day)
        .difference(DateTime(datum.year, datum.month, datum.day))
        .inDays;

    return switch (tage) {
      0 => heute,
      1 => gestern,
      _ => lang(datum, sprache),
    };
  }
}
