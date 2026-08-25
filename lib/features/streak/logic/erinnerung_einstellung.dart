import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';

/// Ob und wann die tägliche Erinnerung kommt.
///
/// Sie ist von Anfang an eingeschaltet. Das ist eine bewusste Entscheidung
/// und keine Bequemlichkeit: Die Serie lebt vom täglichen Abhaken, und wer
/// eine Erinnerung erst suchen muss, schaltet sie nie ein. Aufdringlich wird
/// es dadurch nicht – ohne Systemberechtigung passiert nichts, und wer heute
/// schon abgehakt hat, hört gar nichts.
class Erinnerung {
  const Erinnerung({
    required this.aktiv,
    required this.stunde,
    required this.minute,
  });

  final bool aktiv;
  final int stunde;
  final int minute;

  /// 19 Uhr: nach dem Feierabend, vor dem Abendprogramm. Früh genug, dass
  /// sich eine Aufgabe noch erledigen lässt.
  static const standard = Erinnerung(aktiv: true, stunde: 19, minute: 0);

  Erinnerung kopie({bool? aktiv, int? stunde, int? minute}) => Erinnerung(
        aktiv: aktiv ?? this.aktiv,
        stunde: stunde ?? this.stunde,
        minute: minute ?? this.minute,
      );

  /// Der nächste Zeitpunkt ab [ab], an dem die Uhr diese Zeit zeigt.
  DateTime naechsterZeitpunkt(DateTime ab, {int tageSpaeter = 0}) {
    final tag = DateTime(ab.year, ab.month, ab.day + tageSpaeter);
    return DateTime(tag.year, tag.month, tag.day, stunde, minute);
  }

  @override
  bool operator ==(Object other) =>
      other is Erinnerung &&
      other.aktiv == aktiv &&
      other.stunde == stunde &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(aktiv, stunde, minute);
}

/// Hält die Einstellung und schreibt sie in denselben Speicher wie die
/// übrigen Einstellungen, damit sie einen Neustart übersteht.
class ErinnerungController extends StateNotifier<Erinnerung> {
  ErinnerungController(this._box) : super(_lade(_box));

  final KeyValueStore _box;

  static const _aktiv = 'erinnerungAktiv';
  static const _stunde = 'erinnerungStunde';
  static const _minute = 'erinnerungMinute';

  /// Ob schon einmal nach der Systemberechtigung gefragt wurde.
  ///
  /// Steht bewusst hier und nicht im Zustand: Es ist keine Einstellung,
  /// sondern eine Notiz darüber, was schon passiert ist. Ohne sie fragt die
  /// App bei jedem Start erneut – und genau das war die Bitte, es nicht zu
  /// tun.
  static const _gefragt = 'erinnerungGefragt';

  static Erinnerung _lade(KeyValueStore box) {
    final aktiv = box.get(_aktiv);
    return Erinnerung(
      aktiv: aktiv is bool ? aktiv : Erinnerung.standard.aktiv,
      stunde: _zahl(box.get(_stunde), 0, 23) ?? Erinnerung.standard.stunde,
      minute: _zahl(box.get(_minute), 0, 59) ?? Erinnerung.standard.minute,
    );
  }

  static int? _zahl(Object? wert, int min, int max) {
    if (wert is! int || wert < min || wert > max) return null;
    return wert;
  }

  bool get schonGefragt => _box.get(_gefragt) == true;

  Future<void> alsGefragtMerken() => _box.put(_gefragt, true);

  Future<void> anAus(bool aktiv) async {
    if (aktiv == state.aktiv) return;
    state = state.kopie(aktiv: aktiv);
    await _box.put(_aktiv, aktiv);
  }

  Future<void> uhrzeit(int stunde, int minute) async {
    if (stunde == state.stunde && minute == state.minute) return;
    state = state.kopie(stunde: stunde, minute: minute);
    await _box.put(_stunde, stunde);
    await _box.put(_minute, minute);
  }

  /// Nach dem Löschen aller Daten steht nichts mehr im Speicher – dann gilt
  /// wieder der Standard, und die Frage nach der Berechtigung kommt erneut.
  void neuLaden() => state = _lade(_box);
}

final erinnerungProvider =
    StateNotifierProvider<ErinnerungController, Erinnerung>(
  (ref) => ErinnerungController(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);
