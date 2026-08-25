import 'captured_photo.dart';
import '../../../core/l10n/texte.dart';

/// Moegliche Gruende, warum ein Foto den Qualitaetscheck nicht besteht.
/// Jeder Grund hat einen verstaendlichen Titel und einen konkreten Tipp –
/// eine reine Fehlermeldung hilft dem Nutzer nicht weiter.
enum PhotoProblem {
  keinGesicht,
  mehrereGesichter,
  zuKlein,
  zuDunkel,
  ungueltigeDatei,
  fehlgeschlagen,
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension PhotoProblemText on PhotoProblem {
  String titel(L texte) => switch (this) {
        PhotoProblem.keinGesicht => texte.fotoproblemKeinGesichtTitel,
        PhotoProblem.mehrereGesichter => texte.fotoproblemMehrereTitel,
        PhotoProblem.zuKlein => texte.fotoproblemZuKleinTitel,
        PhotoProblem.zuDunkel => texte.fotoproblemZuDunkelTitel,
        PhotoProblem.ungueltigeDatei => texte.fotoproblemUngueltigTitel,
        PhotoProblem.fehlgeschlagen => texte.fotoproblemFehlerTitel,
      };

  String tipp(L texte) => switch (this) {
        PhotoProblem.keinGesicht => texte.fotoproblemKeinGesichtTipp,
        PhotoProblem.mehrereGesichter => texte.fotoproblemMehrereTipp,
        PhotoProblem.zuKlein => texte.fotoproblemZuKleinTipp,
        PhotoProblem.zuDunkel => texte.fotoproblemZuDunkelTipp,
        PhotoProblem.ungueltigeDatei => texte.fotoproblemUngueltigTipp,
        PhotoProblem.fehlgeschlagen => texte.fotoproblemFehlerTipp,
      };
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
