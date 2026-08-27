import 'package:flutter/material.dart';

import '../../../core/l10n/texte.dart';

/// Mit welchem Auftrag die Analyse losgeschickt wird.
///
/// Bis hierher konnte die App genau eine Frage beantworten: „Wie hole ich aus
/// dem, was da ist, das Beste heraus?" Das ist die richtige Frage für jemanden,
/// der seinen Stil mag. Wer Veränderung will, bekam darauf eine Antwort, die
/// ihn festhielt.
///
/// Deshalb zwei Modi statt eines. Sie unterscheiden sich **nicht** in den
/// Fotos, den Modulen oder dem Preis – ein Lauf bleibt ein Lauf. Sie
/// unterscheiden sich in dem, was das Modell tun soll: den Ist-Zustand
/// verbessern oder eine neue, in sich stimmige Richtung entwerfen.
///
/// Die Wahl gilt **pro Analyse**, nicht fürs Konto: Sie steht am Anfang jedes
/// Durchlaufs und hängt am fertigen Report, damit im Verlauf ablesbar bleibt,
/// welche Frage er beantwortet hat.
enum AnalyseModus {
  /// Das bisherige Verhalten, unverändert.
  ///
  /// Steht bewusst an erster Stelle: Es ist der Rückfall für alles, was den
  /// Modus nicht kennt – ein alter gespeicherter Report, ein alter Client am
  /// Server, eine kaputte Zeile in der Datenbank. Wer nichts gewählt hat,
  /// bekommt das, was er bisher bekommen hat.
  verfeinern(icon: Icons.auto_fix_high_outlined),

  /// Die KI entwirft eine neue Richtung, statt die vorhandene zu polieren.
  entdecken(icon: Icons.explore_outlined);

  const AnalyseModus({required this.icon});

  final IconData icon;

  /// Der Rückfall, wenn nichts oder Unbekanntes gespeichert ist.
  static const standard = AnalyseModus.verfeinern;

  /// Liest einen gespeicherten Namen; unbekannte Namen fallen auf
  /// [standard] zurück.
  static AnalyseModus ausName(Object? name) {
    for (final modus in values) {
      if (modus.name == name) return modus;
    }
    return standard;
  }

  bool get istEntdecken => this == AnalyseModus.entdecken;
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension AnalyseModusText on AnalyseModus {
  /// Die Überschrift auf der Karte.
  String titel(L texte) => switch (this) {
        AnalyseModus.verfeinern => texte.modusVerfeinernTitel,
        AnalyseModus.entdecken => texte.modusEntdeckenTitel,
      };

  /// Der Satz darunter – die eigentliche Entscheidungshilfe.
  String beschreibung(L texte) => switch (this) {
        AnalyseModus.verfeinern => texte.modusVerfeinernText,
        AnalyseModus.entdecken => texte.modusEntdeckenText,
      };

  /// Das kurze Etikett am Verlaufseintrag.
  ///
  /// Absichtlich kürzer als [titel]: Es steht neben einem Datum und darf die
  /// Zeile nicht sprengen.
  String etikett(L texte) => switch (this) {
        AnalyseModus.verfeinern => texte.modusVerfeinernEtikett,
        AnalyseModus.entdecken => texte.modusEntdeckenEtikett,
      };
}
