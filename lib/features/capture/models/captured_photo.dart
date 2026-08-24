import 'aufnahme_typ.dart';

/// Ein bereits geprueftes und komprimiertes Foto, bereit fuer den API-Call.
class CapturedPhoto {
  const CapturedPhoto({
    required this.typ,
    required this.pfad,
    required this.breite,
    required this.hoehe,
    required this.groesseInBytes,
  });

  final AufnahmeTyp typ;

  /// Pfad zur komprimierten JPEG-Datei im App-Verzeichnis.
  final String pfad;

  final int breite;
  final int hoehe;
  final int groesseInBytes;

  /// Fuer Log-Ausgaben waehrend der Entwicklung.
  String get kurzinfo =>
      '$breite x $hoehe, ${(groesseInBytes / 1024).round()} KB';

  Map<String, dynamic> toJson() => {
        'typ': typ.name,
        'pfad': pfad,
        'breite': breite,
        'hoehe': hoehe,
        'groesseInBytes': groesseInBytes,
      };

  /// Liefert null, wenn der Aufnahmetyp nicht mehr bekannt ist – etwa nachdem
  /// ein Typ aus dem Flow entfernt wurde.
  static CapturedPhoto? fromJson(Map<String, dynamic> json) {
    final typ = AufnahmeTyp.values
        .where((t) => t.name == json['typ'])
        .firstOrNull;
    if (typ == null) return null;

    return CapturedPhoto(
      typ: typ,
      pfad: json['pfad'] as String? ?? '',
      breite: (json['breite'] as num?)?.toInt() ?? 0,
      hoehe: (json['hoehe'] as num?)?.toInt() ?? 0,
      groesseInBytes: (json['groesseInBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
