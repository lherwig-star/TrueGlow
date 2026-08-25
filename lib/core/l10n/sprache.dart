import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_service.dart';
import '../storage/key_value_store.dart';

/// Die Sprachen, in denen die App vollständig vorliegt.
///
/// Eine weitere Sprache braucht drei Dinge: einen Wert hier, eine Datei
/// `lib/l10n/app_<code>.arb` und – falls der Report in dieser Sprache
/// erscheinen soll – einen Eintrag in `functions/src/sprache.ts`. Sonst
/// nichts; die Delegates und die Auflösung hängen an dieser Liste.
enum Sprache {
  deutsch('de', 'Deutsch', 'DE'),
  englisch('en', 'English', 'EN');

  const Sprache(this.code, this.name, this.kuerzel);

  /// ISO-639-1-Code. Geht so auch an die Cloud Function.
  final String code;

  /// Der Name in der jeweiligen Sprache selbst – „Deutsch", nicht „German".
  /// Wer die App auf Englisch sieht und Deutsch sucht, sucht nach „Deutsch".
  final String name;

  /// Zwei Buchstaben für den Umschalter auf dem Anmelde-Bildschirm.
  final String kuerzel;

  Locale get locale => Locale(code);

  static Sprache? ausCode(String? code) =>
      Sprache.values.where((s) => s.code == code).firstOrNull;

  /// Welche Sprache zu einem Gerät passt.
  ///
  /// Alles außer Deutsch bekommt Englisch. Das ist keine Bequemlichkeit,
  /// sondern die ehrlichere Antwort: Für Französisch gibt es keine
  /// Übersetzung, und ein französisches Gerät auf Deutsch zu stellen wäre
  /// eine schlechtere Vermutung als Englisch.
  static Sprache fuerGeraet(Locale geraet) =>
      geraet.languageCode == deutsch.code ? deutsch : englisch;
}

/// Hält die Sprachwahl und schreibt sie in denselben Speicher wie die übrigen
/// Einstellungen, damit sie einen Neustart übersteht.
///
/// `null` heißt „noch nicht gewählt" und ist etwas anderes als „Deutsch": Wer
/// nichts gewählt hat, folgt weiter dem Gerät, auch wenn er es später
/// umstellt. Erst eine bewusste Wahl friert die Sprache ein.
class SprachController extends StateNotifier<Sprache?> {
  SprachController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const _schluessel = 'sprache';

  static Sprache? _lade(KeyValueStore box) {
    final wert = box.get(_schluessel);
    return wert is String ? Sprache.ausCode(wert) : null;
  }

  void setzen(Sprache wahl) {
    if (wahl == state) return;
    state = wahl;
    _box.put(_schluessel, wahl.code);
  }

  /// Nach dem Löschen aller Daten steht nichts mehr im Speicher – dann folgt
  /// die App wieder dem Gerät.
  void neuLaden() => state = _lade(_box);
}

final sprachControllerProvider =
    StateNotifierProvider<SprachController, Sprache?>(
  (ref) => SprachController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);

/// Die Sprache, in der die App gerade läuft – Wahl des Nutzers, sonst die des
/// Geräts.
///
/// Gebraucht überall dort, wo es nicht um Anzeige geht, sondern um eine
/// Entscheidung: welche Sprache die Cloud Function für den Report bekommt,
/// welcher Eintrag im Umschalter hervorgehoben ist.
final aktiveSpracheProvider = Provider<Sprache>((ref) {
  return ref.watch(sprachControllerProvider) ??
      Sprache.fuerGeraet(PlatformDispatcher.instance.locale);
});
