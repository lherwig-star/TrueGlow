/// Kleine Datumsformatierung auf Deutsch. Bewusst ohne intl-Paket – die App
/// braucht genau zwei Formate.
class Datum {
  Datum._();

  static const _monate = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  /// z. B. "22. August 2026"
  static String lang(DateTime datum) =>
      '${datum.day}. ${_monate[datum.month - 1]} ${datum.year}';

  /// z. B. "22.08.2026"
  static String nurTag(DateTime datum) =>
      '${datum.day.toString().padLeft(2, '0')}.'
      '${datum.month.toString().padLeft(2, '0')}.${datum.year}';

  /// z. B. "22.08.2026, 14:05"
  static String kurz(DateTime datum) {
    final tag = datum.day.toString().padLeft(2, '0');
    final monat = datum.month.toString().padLeft(2, '0');
    final stunde = datum.hour.toString().padLeft(2, '0');
    final minute = datum.minute.toString().padLeft(2, '0');
    return '$tag.$monat.${datum.year}, $stunde:$minute';
  }

  /// "heute", "gestern" oder das lange Datum.
  static String relativ(DateTime datum) {
    final jetzt = DateTime.now();
    final tage = DateTime(jetzt.year, jetzt.month, jetzt.day)
        .difference(DateTime(datum.year, datum.month, datum.day))
        .inDays;

    return switch (tage) {
      0 => 'heute',
      1 => 'gestern',
      _ => lang(datum),
    };
  }
}
