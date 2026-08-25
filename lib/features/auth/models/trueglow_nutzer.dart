import 'package:flutter/foundation.dart';
import '../../../core/l10n/texte.dart';

/// Womit sich jemand angemeldet hat.
///
/// Das Enum ist der Grund, warum „Sign in with Apple" spaeter kein Umbau ist:
/// Ein weiterer Wert, ein weiterer `case` im Repository, eine weitere
/// Schaltfläche auf dem Login-Screen – mehr nicht.
enum AuthAnbieter {
  google,

  /// Pflicht von Apple, sobald die iOS-App Google Sign-In anbietet.
  apple,

  /// „Erst ausprobieren": ein echtes Firebase-Konto ohne Anmeldedaten. Es
  /// wird beim spaeteren Google-Login per Verknuepfung uebernommen, nicht
  /// verworfen.
  anonym;

  /// Ob der Anbieter auf dieser Plattform angeboten wird.
  ///
  /// Apple erscheint nur auf Apple-Geraeten: Auf Android waere es ein
  /// Web-Umweg ohne Nutzen, und Apples eigene Regel verlangt es nur dort.
  bool verfuegbarAuf(TargetPlatform plattform) => switch (this) {
        AuthAnbieter.apple => plattform == TargetPlatform.iOS ||
            plattform == TargetPlatform.macOS,
        _ => true,
      };
}

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
///
/// „Google" und „Apple" sind Eigennamen und stehen trotzdem in der
/// Uebersetzungsdatei: Sie werden in einen Satz eingesetzt („Mit Google
/// anmelden"), und wie dieser Satz gebaut wird, entscheidet die Sprache.
extension AuthAnbieterText on AuthAnbieter {
  String label(L texte) => switch (this) {
        AuthAnbieter.google => texte.anbieterGoogle,
        AuthAnbieter.apple => texte.anbieterApple,
        AuthAnbieter.anonym => texte.anbieterAnonym,
      };
}

/// Das angemeldete Konto, so weit die App es braucht.
@immutable
class TrueGlowNutzer {
  const TrueGlowNutzer({
    required this.uid,
    required this.anonym,
    this.email,
    this.anzeigename,
  });

  final String uid;

  /// Ob es sich um ein anonymes Konto handelt („Erst ausprobieren").
  final bool anonym;

  final String? email;
  final String? anzeigename;

  /// Was in den Einstellungen unter dem Konto steht.
  String beschriftung(L texte) {
    if (anonym) return texte.nutzerOhneKonto;
    final name = anzeigename?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email ?? texte.nutzerAngemeldet;
  }

  @override
  bool operator ==(Object other) =>
      other is TrueGlowNutzer &&
      other.uid == uid &&
      other.anonym == anonym &&
      other.email == email &&
      other.anzeigename == anzeigename;

  @override
  int get hashCode => Object.hash(uid, anonym, email, anzeigename);

  @override
  String toString() => 'TrueGlowNutzer($uid, anonym: $anonym)';
}
