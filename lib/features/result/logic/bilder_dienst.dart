import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analysis/logic/analysis_service.dart';
import '../../analysis/logic/functions_client.dart';
import '../models/beispielbild.dart';

/// Beschafft die Beispielbilder zu den Suchbegriffen eines Kapitels.
///
/// Als Schnittstelle, weil es drei Fassungen gibt: die echte ueber die Cloud
/// Function, die Demo-Fassung ohne Backend und die Test-Fassung.
abstract interface class BilderDienst {
  /// Bilder zu mehreren Begriffen auf einmal.
  ///
  /// Wirft **nie**. Was nicht geht, fehlt in der Antwort – die Reihe bleibt
  /// dann weg. Eine Fehlermeldung waere hier falsch: Der Report ist
  /// vollstaendig, es fehlen nur Bilder, die niemand bestellt hat
  /// (DECISIONS 69).
  Future<Map<String, List<Beispielbild>>> suche(List<String> begriffe);
}

/// Die echte Fassung: ein Aufruf der Function `bilderSuchen`.
class FunctionsBilderDienst implements BilderDienst {
  FunctionsBilderDienst({FunctionsClient? client})
      : _client = client ?? FunctionsClient();

  final FunctionsClient _client;

  /// Kuerzer als bei der Analyse: Auf ein Beispielbild wartet niemand eine
  /// Minute. Laeuft es ab, bleibt die Reihe weg.
  static const zeitlimit = Duration(seconds: 20);

  @override
  Future<Map<String, List<Beispielbild>>> suche(List<String> begriffe) async {
    if (begriffe.isEmpty) return const {};

    try {
      final antwort = await _client.rufeRoh(
        'bilderSuchen',
        {'begriffe': begriffe},
        zeitlimit: zeitlimit,
      );
      return Beispielbild.tabelleAus(antwort['treffer']);
    } catch (e) {
      // Bewusst alles: kein Netz, kein Konto, abgelehnter App Check, ein
      // Serverfehler – die Reaktion ist jedes Mal dieselbe.
      debugPrint('Beispielbilder uebersprungen: $e');
      return const {};
    }
  }
}

/// Der Demo-Modus.
///
/// Dort laeuft kein Firebase (siehe `main.dart`), also gibt es auch keine
/// Bildersuche. Statt die Reihe wegzulassen, liefert diese Fassung drei
/// Eintraege ohne Bilddatei: Die Reihe steht da, laesst sich antippen,
/// durchwischen und zeigt die Nennung – nur die Fotos selbst sind
/// gezeichnete Platzhalter.
///
/// Was der Demo-Modus damit **nicht** beweist: dass ein echtes Foto laedt und
/// sitzt. Das braucht einen Report vom Server (TESTPLAN 33).
class DemoBilderDienst implements BilderDienst {
  const DemoBilderDienst();

  static const _anzahl = 3;

  @override
  Future<Map<String, List<Beispielbild>>> suche(List<String> begriffe) async {
    return {
      for (final begriff in begriffe)
        begriff: [
          for (var i = 0; i < _anzahl; i++)
            Beispielbild(
              vorschau: '',
              gross: '',
              fotograf: 'Demo ${i + 1}',
              quelle: 'https://www.pexels.com/',
              beschreibung: begriff,
            ),
        ],
    };
  }
}

/// Waehlt die Fassung – wie beim [analysisServiceProvider].
final bilderDienstProvider = Provider<BilderDienst>((ref) {
  if (AnalysisConfig.useMockData) return const DemoBilderDienst();
  return FunctionsBilderDienst();
});

/// Die Bilder eines Kapitels, in einem Aufruf.
///
/// Der Schluessel ist die Liste der Suchbegriffe, mit `|` verbunden – ein
/// Zeichen, das in keinem Suchbegriff vorkommen darf. Riverpod braucht einen
/// vergleichbaren Wert; eine `List` ist keiner.
///
/// Ein Aufruf je Kapitel und nicht je Vorschlag: Ein Kapitel hat hoechstens
/// fuenf Sektionen, ein ganzer Report bis zu dreissig. Kapitelweise bleibt
/// unter der Obergrenze der Function und laedt trotzdem erst, wenn das
/// Kapitel gebaut wird.
///
/// Ohne `autoDispose`: Wer im Report hoch und runter scrollt, soll nicht bei
/// jedem Bauen neu laden. Die Antwort gilt fuer diese Sitzung.
final kapitelBilderProvider =
    FutureProvider.family<Map<String, List<Beispielbild>>, String>(
  (ref, schluessel) {
    final begriffe = [
      for (final b in schluessel.split('|'))
        if (b.isNotEmpty) b,
    ];
    return ref.watch(bilderDienstProvider).suche(begriffe);
  },
);

/// Baut den Schluessel aus den Suchbegriffen eines Kapitels.
String bilderSchluessel(Iterable<String> begriffe) => begriffe.join('|');
