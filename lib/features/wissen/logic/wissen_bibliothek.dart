import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wissenseintrag.dart';

/// Die Wissens-Bibliothek: alle Erklärungen einer Sprache, plus die Fähigkeit,
/// in einem Satz die Technik zu erkennen, um die es geht.
///
/// **Warum Erkennung am Text und nicht an einer Kennung.** Die Analyse liefert
/// zwar Kennungen mit – im Feld `neu` der Sektionen –, aber nur für die
/// Techniken, die der Nutzer vorher ausdrücklich angetippt hat. Der Befund,
/// um den es hier geht, ist ein anderer: Eine Aufgabe wie „5 Minuten
/// Gesichtsyoga" steht auch dann in der Tagesliste, wenn niemand sie
/// angetippt hat – das Modell hat sie selbst vorgeschlagen. Solche Aufgaben
/// tragen keine Kennung, und gerade sie sind es, bei denen jemand ratlos vor
/// der Liste steht.
///
/// Die Erkennung am Namen deckt beide Fälle ab, und sie ist für den ersten
/// Fall genauso exakt: Der Prompt schreibt dem Modell vor, gewählte Techniken
/// **wörtlich** mit dem Namen aus dem Katalog zu nennen (DECISIONS 79). Der
/// Name IST die Kennung.
///
/// **Warum das nicht wild um sich greift.** Gesucht wird ausschließlich nach
/// den Namen aus dieser Bibliothek, jeder davon mehrwortig oder eindeutig –
/// kein „Öl", kein „Peeling". Und ein Treffer zählt nur, wenn links und
/// rechts kein Buchstabe steht: „Ölziehen" wird nicht in „Ölziehenden"
/// gefunden.
class WissenBibliothek {
  WissenBibliothek(this.eintraege)
      : _namen = [
          for (final eintrag in eintraege)
            for (final name in eintrag.namen) (name.toLowerCase(), eintrag),
        ];

  final List<Wissenseintrag> eintraege;

  /// Alle Suchnamen in Kleinschreibung, einmal vorbereitet statt bei jedem
  /// Antippen neu.
  final List<(String, Wissenseintrag)> _namen;

  /// Ein Buchstabe oder eine Ziffer – in jeder Sprache, nicht nur A–Z.
  static final _wortzeichen = RegExp(r'[\p{L}\p{N}]', unicode: true);

  Wissenseintrag? nachId(String id) =>
      eintraege.where((e) => e.id == id).firstOrNull;

  /// Der Eintrag, um den es in [text] geht – oder `null`.
  ///
  /// Bei mehreren Treffern gewinnt der, der am weitesten vorn steht; bei
  /// gleichem Anfang der längere Name. „Gua Sha" schlägt damit einen
  /// Eintrag, der nur „Sha" hieße – und in „Nach dem Duschen: Gua Sha"
  /// gewinnt nicht das erstbeste Wort, sondern die Technik.
  Wissenseintrag? suche(String text) {
    if (text.isEmpty) return null;
    final klein = text.toLowerCase();

    Wissenseintrag? bester;
    var bestePosition = -1;
    var besteLaenge = 0;

    for (final (name, eintrag) in _namen) {
      final position = _fundstelle(klein, name);
      if (position < 0) continue;
      final besser = bester == null ||
          position < bestePosition ||
          (position == bestePosition && name.length > besteLaenge);
      if (besser) {
        bester = eintrag;
        bestePosition = position;
        besteLaenge = name.length;
      }
    }
    return bester;
  }

  /// Die erste Stelle, an der [name] als eigenes Wort in [text] steht.
  static int _fundstelle(String text, String name) {
    var ab = 0;
    while (true) {
      final position = text.indexOf(name, ab);
      if (position < 0) return -1;
      if (_freiRundherum(text, position, position + name.length)) {
        return position;
      }
      ab = position + 1;
    }
  }

  static bool _freiRundherum(String text, int von, int bis) {
    final davor = von == 0 ? '' : text[von - 1];
    final danach = bis >= text.length ? '' : text[bis];
    return !_wortzeichen.hasMatch(davor) && !_wortzeichen.hasMatch(danach);
  }

  static WissenBibliothek ausJson(String roh) {
    final gelesen = jsonDecode(roh);
    return WissenBibliothek([
      for (final eintrag in gelesen is List ? gelesen : const [])
        if (eintrag is Map<String, dynamic>) Wissenseintrag.fromJson(eintrag),
    ]);
  }
}

/// Wo die Texte liegen. Eine Datei je Sprache, wie bei den Rechtstexten.
///
/// [sprachcode] ist der ISO-Code der gerade angezeigten Sprache
/// (`texte.localeName`). Alles außer `en` bekommt die deutsche Fassung –
/// besser ein Text in der falschen Sprache als gar keiner.
String wissenAsset(String sprachcode) =>
    'assets/wissen/wissen_${sprachcode == 'en' ? 'en' : 'de'}.json';

/// Die Bibliothek in der Sprache, in der die Oberfläche gerade steht.
///
/// **Warum der Sprachcode von außen kommt und nicht aus dem Sprach-Provider.**
/// Maßgeblich ist die Sprache, in der der Bildschirm gerade beschriftet ist –
/// dieselbe Quelle, aus der auch die Rechtstexte ihre Fassung wählen
/// (`texte.localeName`). Die beiden gehen im Betrieb nie auseinander, wohl
/// aber in einem Test, der die Oberfläche auf Deutsch stellt: Dort stand
/// sonst ein deutscher Bildschirm mit englischen Erklärungen darin.
///
/// Der Ladevorgang ist einmalig und liegt im Bundle – kein Netz, kein
/// Modellaufruf, keine laufenden Kosten (DECISIONS 88).
final wissenProvider =
    FutureProvider.family<WissenBibliothek, String>((ref, sprachcode) async {
  return WissenBibliothek.ausJson(await rootBundle.loadString(
    wissenAsset(sprachcode),
  ));
});
