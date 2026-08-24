import 'package:flutter/foundation.dart';

/// Womit sich jemand angemeldet hat.
///
/// Das Enum ist der Grund, warum „Sign in with Apple" spaeter kein Umbau ist:
/// Ein weiterer Wert, ein weiterer `case` im Repository, eine weitere
/// Schaltfläche auf dem Login-Screen – mehr nicht.
enum AuthAnbieter {
  google('Google'),

  /// Pflicht von Apple, sobald die iOS-App Google Sign-In anbietet.
  apple('Apple'),

  /// „Erst ausprobieren": ein echtes Firebase-Konto ohne Anmeldedaten. Es
  /// wird beim spaeteren Google-Login per Verknuepfung uebernommen, nicht
  /// verworfen.
  anonym('Ohne Konto');

  const AuthAnbieter(this.label);

  final String label;

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
  String get beschriftung {
    if (anonym) return 'Ohne Konto angemeldet';
    final name = anzeigename?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email ?? 'Angemeldet';
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
