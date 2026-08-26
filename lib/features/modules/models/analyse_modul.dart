import 'package:flutter/material.dart';

import '../../../core/l10n/texte.dart';
import '../../onboarding/models/onboarding_profile.dart';

/// Die waehlbaren Bausteine einer Analyse.
///
/// [basis] ist immer dabei und laesst sich nicht abwaehlen – alles andere
/// entscheidet der Nutzer vor der Aufnahme und kann es spaeter ueber
/// "Analyse erweitern" nachholen.
enum AnalyseModul {
  basis(icon: Icons.face_retouching_natural),
  hautFarbtyp(icon: Icons.spa_outlined),

  /// Nur im weiblichen und im neutralen Modus im Angebot – siehe
  /// [waehlbareFuer].
  makeupAusstrahlung(icon: Icons.brush_outlined),

  zaehneLaecheln(icon: Icons.sentiment_satisfied_alt_outlined),
  figurPassform(icon: Icons.accessibility_new_outlined),
  stilKleiderschrank(icon: Icons.checkroom_outlined),

  /// Das Kapitel, das aus dem Freitext bei „Deine Richtung" entsteht – und
  /// nur daraus.
  ///
  /// Es ist ein Kapitel wie jedes andere: Der Report zeigt es, die Tagesliste
  /// bekommt eine eigene Karte dafuer, der Check-in passt seine Aufgaben an.
  /// Waehlen kann es niemand – es steht deshalb in keiner der Listen unten
  /// und faellt in [ausNamen] heraus. Ob es das Kapitel gibt, entscheidet
  /// allein der Server anhand des Freitextfelds.
  ///
  /// Warum ueberhaupt: Vorher landeten die Aufgaben aus dem Freitext im
  /// „inhaltlich am besten passenden" Kapitel. Fuer „aufhoeren zu rauchen"
  /// gibt es keins – am Geraet stand es unter „Haare & Bart". Siehe
  /// DECISIONS 39.
  persoenlicheZiele(icon: Icons.flag_outlined);

  const AnalyseModul({required this.icon});

  final IconData icon;

  bool get istBasis => this == AnalyseModul.basis;

  /// Die Module, die eine Analyse ueberhaupt bestellen kann.
  ///
  /// Alles ausser dem Zielkapitel: Das haengt am Freitext und nicht an einem
  /// Haken im Modul-Bildschirm.
  static List<AnalyseModul> get bestellbar =>
      values.where((m) => m != AnalyseModul.persoenlicheZiele).toList();

  /// Alle bestellbaren Module ausser der Basis – die vollstaendige Liste,
  /// unabhaengig von der Ausrichtung.
  ///
  /// Gebraucht ueberall dort, wo es um *gespeicherte* Auswahl geht: Ein
  /// Report, der Make-up enthaelt, bleibt vollstaendig, auch wenn jemand
  /// spaeter auf den maennlichen Modus umstellt.
  static List<AnalyseModul> get waehlbare =>
      bestellbar.where((m) => !m.istBasis).toList();

  /// Was zur Auswahl steht.
  ///
  /// Im weiblichen Modus steht Make-up vorn – es ist der Baustein, der dort
  /// am ehesten gesucht wird. Im maennlichen Modus fehlt es ganz; wer Bart
  /// und Konturen bekommt, bekommt keine Lidschattenempfehlung. Neutral steht
  /// beides zur Wahl: „divers" und „keine Angabe" sind kein Auftrag,
  /// irgendetwas wegzulassen.
  static List<AnalyseModul> waehlbareFuer(Ausrichtung ausrichtung) =>
      switch (ausrichtung) {
        Ausrichtung.weiblich => [
            AnalyseModul.makeupAusstrahlung,
            ...waehlbare.where((m) => m != AnalyseModul.makeupAusstrahlung),
          ],
        Ausrichtung.maennlich =>
          waehlbare.where((m) => m != AnalyseModul.makeupAusstrahlung).toList(),
        Ausrichtung.neutral => waehlbare,
      };

  /// Stabile Namen fuer die lokale Speicherung.
  ///
  /// Das Zielkapitel faellt hier heraus: Diese Liste ist eine *Auswahl*, und
  /// ausgewaehlt wird es nie. Ein alter oder manipulierter Aufruf, der es
  /// mitschickt, bestellt damit trotzdem kein Kapitel.
  static Set<AnalyseModul> ausNamen(Iterable<Object?> namen) {
    final gefunden = <AnalyseModul>{};
    for (final name in namen) {
      for (final modul in bestellbar) {
        if (modul.name == name) gefunden.add(modul);
      }
    }
    // Die Basis ist nicht verhandelbar.
    return {AnalyseModul.basis, ...gefunden};
  }
}

/// Titel, Beschreibung und Ueberschriften eines Moduls.
///
/// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
/// [kapitel] ist die Ueberschrift im Report und stimmt bewusst mit [titel]
/// ueberein; getrennt gehalten, weil beide Stellen unabhaengig voneinander
/// umformuliert werden koennen.
/// Die Basis heisst im weiblichen Modus anders, weil sie dort etwas anderes
/// enthaelt: „Gesicht, Haare & Bart" wird zu „Gesicht & Haare".
///
/// Deshalb nehmen alle Texte die [Ausrichtung] entgegen. Sie durchzureichen
/// kostet an jeder Aufrufstelle ein Argument – die Alternative waere ein
/// zweites Modul mit fast demselben Inhalt gewesen, und damit zwei Kapitel,
/// die getrennt gepflegt werden muessten.
extension AnalyseModulText on AnalyseModul {
  String titel(L texte, Ausrichtung ausrichtung) => switch (this) {
        AnalyseModul.basis => ausrichtung == Ausrichtung.weiblich
            ? texte.modulBasisTitelOhneBart
            : texte.modulBasisTitel,
        AnalyseModul.hautFarbtyp => texte.modulHautTitel,
        AnalyseModul.makeupAusstrahlung => texte.modulMakeupTitel,
        AnalyseModul.zaehneLaecheln => texte.modulZaehneTitel,
        AnalyseModul.figurPassform => texte.modulFigurTitel,
        AnalyseModul.stilKleiderschrank => texte.modulStilTitel,
        AnalyseModul.persoenlicheZiele => texte.modulZieleTitel,
      };

  String beschreibung(L texte, Ausrichtung ausrichtung) => switch (this) {
        AnalyseModul.basis => ausrichtung == Ausrichtung.weiblich
            ? texte.modulBasisTextOhneBart
            : texte.modulBasisText,
        AnalyseModul.hautFarbtyp => texte.modulHautText,
        AnalyseModul.makeupAusstrahlung => texte.modulMakeupText,
        AnalyseModul.zaehneLaecheln => texte.modulZaehneText,
        AnalyseModul.figurPassform => texte.modulFigurText,
        AnalyseModul.stilKleiderschrank => texte.modulStilText,
        AnalyseModul.persoenlicheZiele => texte.modulZieleText,
      };

  /// Ueberschrift des zugehoerigen Report-Kapitels.
  String kapitel(L texte, Ausrichtung ausrichtung) =>
      titel(texte, ausrichtung);

  /// Kurze Ueberschrift der Tages-Checkliste dieses Kapitels.
  String checkliste(L texte, Ausrichtung ausrichtung) => switch (this) {
        AnalyseModul.basis => ausrichtung == Ausrichtung.weiblich
            ? texte.modulBasisCheckisteOhneBart
            : texte.modulBasisCheckliste,
        AnalyseModul.hautFarbtyp => texte.modulHautCheckliste,
        AnalyseModul.makeupAusstrahlung => texte.modulMakeupCheckliste,
        AnalyseModul.zaehneLaecheln => texte.modulZaehneCheckliste,
        AnalyseModul.figurPassform => texte.modulFigurCheckliste,
        AnalyseModul.stilKleiderschrank => texte.modulStilCheckliste,
        AnalyseModul.persoenlicheZiele => texte.modulZieleCheckliste,
      };
}
