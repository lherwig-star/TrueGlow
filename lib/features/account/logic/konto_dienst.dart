import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_start.dart';
import '../../analysis/logic/functions_client.dart';
import '../../../core/l10n/texte.dart';

/// Was beim Löschen schiefgehen kann.
enum KontoFehler { neuAnmelden, keinInternet, fehlgeschlagen }

// Anzeigetexte als Erweiterung – Begruendung in `onboarding_profile.dart`.
extension KontoFehlerText on KontoFehler {
  String titel(L texte) => switch (this) {
        KontoFehler.neuAnmelden => texte.kontoNeuAnmeldenTitel,
        KontoFehler.keinInternet => texte.kontoKeinInternetTitel,
        KontoFehler.fehlgeschlagen => texte.kontoFehlgeschlagenTitel,
      };

  String tipp(L texte) => switch (this) {
        KontoFehler.neuAnmelden => texte.kontoNeuAnmeldenTipp,
        KontoFehler.keinInternet => texte.kontoKeinInternetTipp,
        KontoFehler.fehlgeschlagen => texte.kontoFehlgeschlagenTipp,
      };
}

class KontoException implements Exception {
  const KontoException(this.fehler, [this.details]);

  final KontoFehler fehler;
  final String? details;

  @override
  String toString() =>
      'KontoException(${fehler.name}${details == null ? '' : ': $details'})';
}

/// Was gelöscht werden soll.
enum Loeschmodus {
  /// Alle Inhalte weg, Konto bleibt bestehen – „ich fange neu an".
  nurDaten('daten'),

  /// Inhalte und Konto weg – „ich will hier weg".
  kontoKomplett('konto');

  const Loeschmodus(this.wert);

  final String wert;
}

/// Löscht Cloud-Daten und optional das Konto.
///
/// Das läuft über eine Cloud Function und nicht über den Client, weil der
/// Client `users/{uid}` nicht vollständig leeren kann: Firestore löscht
/// Unterkollektionen nicht mit, und die Kontingentzähler darf der Client gar
/// nicht anfassen. Ein „gelöscht", das etwas stehen lässt, wäre schlimmer als
/// keins.
class KontoDienst {
  KontoDienst({FunctionsClient? client})
      : _client = client ?? FunctionsClient();

  final FunctionsClient _client;

  /// Zeitlimit für den Löschaufruf.
  ///
  /// Deutlich kürzer als bei der Analyse: Hier rechnet niemand, hier wird
  /// aufgeräumt.
  static const Duration zeitlimit = Duration(seconds: 60);

  Future<void> loeschen(Loeschmodus modus) async {
    try {
      await _client.rufeRoh(
        FirebaseKonfig.functionKontoLoeschen,
        {'modus': modus.wert},
        zeitlimit: zeitlimit,
      );
    } on FunctionsFehler catch (e) {
      debugPrint('Loeschung fehlgeschlagen: $e');
      throw KontoException(_uebersetze(e), '${e.code}: ${e.nachricht}');
    }
  }

  static KontoFehler _uebersetze(FunctionsFehler e) => switch (e.fall) {
        'neuAnmelden' => KontoFehler.neuAnmelden,
        'keinInternet' => KontoFehler.keinInternet,
        _ => switch (e.code) {
            'unavailable' => KontoFehler.keinInternet,
            'failed-precondition' => KontoFehler.neuAnmelden,
            _ => KontoFehler.fehlgeschlagen,
          },
      };
}

/// Der Löschdienst der laufenden App.
///
/// `null` im Demo-Modus: Dort gibt es kein Backend, aus dem etwas zu löschen
/// wäre – die lokale Löschung läuft trotzdem.
final kontoDienstProvider = Provider<KontoDienst?>((ref) => null);
