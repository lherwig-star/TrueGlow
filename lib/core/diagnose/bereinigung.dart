/// Entfernt Kennungen aus Fehlertexten, bevor sie das Geraet verlassen.
///
/// Der Anlass steht im Phase-2-Bericht: Die Debug-Ausgaben der App selbst
/// enthalten keine personenbezogenen Daten, aber eine Firestore-Ausnahme
/// nennt den Dokumentpfad — und der enthaelt die uid. In einer lokalen
/// Log-Zeile ist das harmlos, in einem hochgeladenen Absturzbericht nicht.
///
/// Bewusst grob: Lieber ein Bezeichner zu viel unkenntlich gemacht als einer
/// zu wenig. Was hier verlorengeht, ist die Zuordnung zu einem Konto — und
/// genau die soll ja weg.
library;

/// Ein Fehler mit unkenntlich gemachter Nachricht.
///
/// Die Klasse traegt den urspruenglichen Typnamen weiter: Ohne ihn stuenden
/// in Crashlytics lauter gleich aussehende Meldungen, und die Gruppierung
/// nach Fehlerart waere dahin.
class BereinigterFehler implements Exception {
  BereinigterFehler(this.typ, this.nachricht);

  /// Laufzeittyp des urspruenglichen Fehlers, etwa `FirebaseException`.
  final String typ;

  /// Die bereinigte Meldung.
  final String nachricht;

  /// Baut den bereinigten Fehler aus einem beliebigen Objekt.
  factory BereinigterFehler.aus(Object fehler) => BereinigterFehler(
        fehler.runtimeType.toString(),
        bereinige(fehler.toString()),
      );

  @override
  String toString() => '$typ: $nachricht';
}

/// Ersetzt alles, was wie eine Kennung aussieht.
///
/// Die Reihenfolge zaehlt: Der Dokumentpfad zuerst, sonst frisst die
/// allgemeine Bezeichner-Regel schon das Segment dahinter und der Pfad ist
/// nicht mehr als solcher zu erkennen.
String bereinige(String text) {
  var bereinigt = text;

  // users/<uid>/…  – der haeufigste Fall, weil Firestore-Ausnahmen den
  // vollstaendigen Dokumentpfad melden.
  bereinigt = bereinigt.replaceAll(
    RegExp(r'users/[^\s/,)\]}]+'),
    'users/<uid>',
  );

  // E-Mail-Adressen.
  bereinigt = bereinigt.replaceAll(
    RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'),
    '<email>',
  );

  // Freistehende lange Bezeichner: Firebase-uids sind 28 Zeichen, unsere
  // Analyse-IDs sind Mikrosekunden-Zeitstempel. Ab 16 Zeichen ist ein
  // zusammenhaengender alphanumerischer Block kein Wort mehr.
  bereinigt = bereinigt.replaceAll(
    RegExp(r'\b(?=[A-Za-z0-9]*\d)[A-Za-z0-9]{16,}\b'),
    '<id>',
  );

  return bereinigt;
}
