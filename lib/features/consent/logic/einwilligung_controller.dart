import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_modell.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../legal/logic/rechtstexte.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../models/einwilligung.dart';

/// Haelt die erteilten Einwilligungen und schreibt jede Aenderung sofort weg.
///
/// Der Speicherweg laeuft ueber denselben [KeyValueStore] wie alles andere –
/// damit liegt der Stand automatisch auch im `profil`-Dokument in der Cloud
/// (siehe `CloudModell`), so wie es die Roadmap verlangt.
class EinwilligungController extends StateNotifier<Einwilligungsstand> {
  EinwilligungController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static Einwilligungsstand _lade(KeyValueStore box) {
    final roh = box.get(CloudModell.keyEinwilligungen);
    if (roh is! String || roh.isEmpty) return Einwilligungsstand.leer;
    try {
      final json = jsonDecode(roh);
      if (json is! Map) return Einwilligungsstand.leer;
      return Einwilligungsstand.fromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      // Ein kaputter Eintrag darf nicht als „hat zugestimmt" durchgehen –
      // im Zweifel wird erneut gefragt.
      return Einwilligungsstand.leer;
    }
  }

  /// Setzt eine Einwilligung mit vollstaendigem Nachweis.
  void setzen(
    Einwilligungsart art, {
    required bool erteilt,
    required Einwilligungskanal kanal,
    DateTime? zeitpunkt,
  }) {
    _setze(
      state.mit(
        Einwilligung(
          art: art,
          erteilt: erteilt,
          zeitpunkt: (zeitpunkt ?? DateTime.now()).toUtc(),
          textversion: Rechtstexte.version,
          kanal: kanal,
        ),
      ),
    );
  }

  /// Widerruft die Foto-Einwilligung.
  ///
  /// Der Eintrag bleibt stehen und wird auf `erteilt: false` gesetzt: Ein
  /// Widerruf ist eine Entscheidung, die genauso nachweisbar sein muss wie
  /// die Zustimmung.
  void widerrufen(Einwilligungsart art, {DateTime? zeitpunkt}) => setzen(
        art,
        erteilt: false,
        kanal: Einwilligungskanal.einstellungen,
        zeitpunkt: zeitpunkt,
      );

  void zuruecksetzen() {
    state = Einwilligungsstand.leer;
    _box.delete(CloudModell.keyEinwilligungen);
  }

  void neuLaden() => state = _lade(_box);

  void _setze(Einwilligungsstand neu) {
    state = neu;
    _box.put(CloudModell.keyEinwilligungen, jsonEncode(neu.toJson()));
  }
}

final einwilligungControllerProvider =
    StateNotifierProvider<EinwilligungController, Einwilligungsstand>(
  (ref) => EinwilligungController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);

/// Ob eine bestimmte Einwilligung gerade gilt.
final einwilligungGiltProvider =
    Provider.family<bool, Einwilligungsart>((ref, art) {
  return ref.watch(einwilligungControllerProvider).gilt(art, Rechtstexte.version);
});

/// Ob die App ueberhaupt benutzbar ist.
///
/// Der Router haengt daran: Fehlt die Pflichteinwilligung – weil sie nie
/// erteilt wurde oder weil sich die Textversion geaendert hat –, fuehrt der
/// Weg zuerst auf den Einwilligungs-Screen.
final pflichtEinwilligungFehltProvider = Provider<bool>((ref) {
  final stand = ref.watch(einwilligungControllerProvider);
  return !stand.gilt(Einwilligungsart.nutzung, Rechtstexte.version);
});

/// Ob Analysen erlaubt sind.
final analyseErlaubtProvider = Provider<bool>((ref) {
  return ref.watch(einwilligungGiltProvider(Einwilligungsart.fotoKi));
});

/// Ob jemand aus der Zeit der alten Sammel-Checkbox kommt.
///
/// Diese Nutzer haben bereits zugestimmt – nur eben pauschal, ohne
/// Zeitstempel und ohne Textversion. Sie werden einmalig durch die neue,
/// getrennte Einwilligung gefuehrt statt still weiterzulaufen.
final ausAlterZustimmungProvider = Provider<bool>((ref) {
  final stand = ref.watch(einwilligungControllerProvider);
  if (stand.eintraege.isNotEmpty) return false;
  return ref.watch(onboardingControllerProvider).zugestimmt;
});
