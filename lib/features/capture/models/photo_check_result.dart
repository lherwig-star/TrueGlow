import 'captured_photo.dart';

/// Moegliche Gruende, warum ein Foto den Qualitaetscheck nicht besteht.
/// Jeder Grund hat einen verstaendlichen Titel und einen konkreten Tipp –
/// eine reine Fehlermeldung hilft dem Nutzer nicht weiter.
enum PhotoProblem {
  keinGesicht(
    'Kein Gesicht erkannt',
    'Halte die Kamera so, dass dein Gesicht vollständig im Bild ist – ohne '
        'Sonnenbrille, Mütze oder Maske.',
  ),
  mehrereGesichter(
    'Mehrere Gesichter im Bild',
    'Auf dem Foto darf nur dein Gesicht zu sehen sein. Such dir einen ruhigen '
        'Hintergrund ohne andere Personen.',
  ),
  zuKlein(
    'Gesicht zu klein im Bild',
    'Geh näher an die Kamera oder halte das Handy näher an dein Gesicht, bis '
        'der Kopf den Großteil des Bildes ausfüllt.',
  ),
  zuDunkel(
    'Foto zu dunkel',
    'Stell dich an ein Fenster oder mach mehr Licht an. Gleichmäßiges Licht '
        'von vorne funktioniert am besten.',
  ),
  ungueltigeDatei(
    'Bild konnte nicht gelesen werden',
    'Versuch es mit einem anderen Foto oder nimm ein neues auf.',
  ),
  fehlgeschlagen(
    'Etwas ist schiefgelaufen',
    'Bitte versuch es noch einmal.',
  );

  const PhotoProblem(this.titel, this.tipp);
  final String titel;
  final String tipp;
}

/// Ergebnis der Pruefung: entweder ein fertiges Foto oder ein Problem.
sealed class PhotoCheckResult {
  const PhotoCheckResult();
}

class PhotoCheckOk extends PhotoCheckResult {
  const PhotoCheckOk(this.foto);
  final CapturedPhoto foto;
}

class PhotoCheckFehler extends PhotoCheckResult {
  const PhotoCheckFehler(this.problem);
  final PhotoProblem problem;
}
