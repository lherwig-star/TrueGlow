import '../../../core/l10n/texte.dart';
import '../logic/rechtstexte.dart';

/// Titel und Beschreibung der Pflichtdokumente.
///
/// Warum nicht am Enum selbst: `rechtstexte.dart` ist bewusst frei von
/// Flutter, damit `tool/rechtstexte_pruefen.dart` es als reines Dart-Skript
/// lesen kann. Ein übersetzter Text braucht aber die Flutter-Lokalisierung –
/// also liegt er hier.
///
/// Die Texte selbst – Datenschutzerklärung, Nutzungsbedingungen, Impressum –
/// sind davon nicht betroffen: Die kommen als fertige Dokumente von der
/// Webseite oder aus den Assets und tragen ihre Sprache selbst.
extension RechtsdokumentText on Rechtsdokument {
  String titel(L texte) => switch (this) {
        Rechtsdokument.datenschutz => texte.dokumentDatenschutzTitel,
        Rechtsdokument.nutzungsbedingungen => texte.dokumentAgbTitel,
        Rechtsdokument.impressum => texte.dokumentImpressumTitel,
      };

  String beschreibung(L texte) => switch (this) {
        Rechtsdokument.datenschutz => texte.dokumentDatenschutzText,
        Rechtsdokument.nutzungsbedingungen => texte.dokumentAgbText,
        Rechtsdokument.impressum => texte.dokumentImpressumText,
      };
}
