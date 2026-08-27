import 'package:flutter/material.dart';

import '../../../core/l10n/texte.dart';
import '../../analysis/models/analysis_result.dart';
import '../../modules/models/analyse_modul.dart';

/// Die Tagesliste nach Tagesabschnitten statt nach Kapiteln – DECISIONS 70.
///
/// Der Anlass kam vom Geraet: Innerhalb eines Kapitels sprangen die Aufgaben
/// wild durch den Tag. „Haare & Bart" las sich als nach dem Aufstehen → nach
/// dem Duschen → nach dem Zaehneputzen → vor dem Schlafengehen → nach dem
/// Fruehstueck. Wer die Liste von oben nach unten abarbeitet, springt damit
/// vom Zubettgehen zurueck zum Fruehstueck.
///
/// Die Sortierung kommt aus dem Wenn-dann-Anker, den seit DECISIONS 44
/// ohnehin jede Aufgabe traegt: „Nach dem Aufstehen: Gesicht waschen". Der
/// Anker sagt, *wann* etwas passiert – also kann er die Liste auch ordnen.

/// Die vier Abschnitte, in der Reihenfolge, in der sie angezeigt werden.
enum Tagesabschnitt {
  morgens(Icons.wb_twilight),
  tagsueber(Icons.wb_sunny_outlined),
  abends(Icons.nightlight_outlined),

  /// Situative Anker ohne feste Tageszeit – „bei Rauchverlangen", „wenn der
  /// Feierabend-Drang einsetzt". Sie stehen zuletzt, weil sie an keinem
  /// Zeitpunkt haengen, den man abarbeiten kann.
  beiBedarf(Icons.bolt_outlined);

  const Tagesabschnitt(this.icon);

  final IconData icon;
}

extension TagesabschnittText on Tagesabschnitt {
  String titel(L texte) => switch (this) {
        Tagesabschnitt.morgens => texte.abschnittMorgens,
        Tagesabschnitt.tagsueber => texte.abschnittTagsueber,
        Tagesabschnitt.abends => texte.abschnittAbends,
        Tagesabschnitt.beiBedarf => texte.abschnittBeiBedarf,
      };
}

/// Ein Anker der festen Liste, mit seinem Platz im Tag.
///
/// Beide Sprachen stehen nebeneinander, weil der Anker in der Sprache im
/// Report steht, in der er entstanden ist. Wer die App danach auf Englisch
/// stellt, behaelt seine deutschen Aufgaben – und die muessen weiter
/// einsortiert werden.
class _Anker {
  const _Anker(this.de, this.en, this.abschnitt);

  final String de;
  final String en;
  final Tagesabschnitt abschnitt;
}

/// Die Zuordnungstabelle: Anker → Abschnitt, und die Reihenfolge *innerhalb*
/// des Abschnitts ist die Reihenfolge in dieser Liste.
///
/// Sie ist die einzige Stelle, an der ueber die Tagesordnung entschieden
/// wird. Die Anker selbst stammen aus `functions/src/labels.ts` (`ANKER`) –
/// wer dort einen hinzufuegt, muss ihn hier einsortieren, sonst landet er in
/// „Bei Bedarf". Genau das prueft ein Test.
///
/// Warum „nach dem Zaehneputzen" morgens steht, obwohl auch abends Zaehne
/// geputzt werden: Der Anker gibt es nur einmal, und morgens ist er der
/// letzte Griff vor dem Haus – der Punkt, an dem eine Aufgabe wie „Haare
/// richten" sitzt. Abends gibt es dafuer „vor dem Schlafengehen".
const List<_Anker> _anker = [
  _Anker('nach dem aufstehen', 'after getting up', Tagesabschnitt.morgens),
  _Anker('beim duschen', 'in the shower', Tagesabschnitt.morgens),
  _Anker('nach dem duschen', 'after your shower', Tagesabschnitt.morgens),
  _Anker('nach dem frühstück', 'after breakfast', Tagesabschnitt.morgens),
  _Anker(
    'nach dem zähneputzen',
    'after brushing your teeth',
    Tagesabschnitt.morgens,
  ),
  _Anker('nach dem abendessen', 'after dinner', Tagesabschnitt.abends),
  _Anker('vor dem schlafengehen', 'before bed', Tagesabschnitt.abends),
];

/// Laenger als das ist kein Ausloeser mehr, sondern ein Satz mit Doppelpunkt.
///
/// Ohne diese Schranke wuerde „Zähne putzen: zwei Minuten, auch die
/// Innenseiten" als unbekannter Anker gelesen und landete in „Bei Bedarf".
const int _maxAnkerZeichen = 45;

/// Eine Aufgabe mit allem, was die Liste ueber sie wissen muss.
@immutable
class Tagesaufgabe {
  const Tagesaufgabe({
    required this.text,
    required this.modul,
    required this.abschnitt,
    required this.rang,
  });

  /// Der volle Text samt Anker – er bleibt stehen. Der Anker ist nicht nur
  /// Sortierhilfe, sondern der Kern der Gewohnheit (DECISIONS 44).
  final String text;

  /// Fuer das Themen-Abzeichen an der Zeile.
  final AnalyseModul modul;

  final Tagesabschnitt abschnitt;

  /// Platz innerhalb des Abschnitts. Kleiner ist frueher.
  final int rang;
}

/// Ein Abschnitt mit seinen Aufgaben. Leere Abschnitte entstehen gar nicht.
@immutable
class Abschnittsgruppe {
  const Abschnittsgruppe({required this.abschnitt, required this.aufgaben});

  final Tagesabschnitt abschnitt;
  final List<Tagesaufgabe> aufgaben;
}

/// Der Anker einer Aufgabe – alles vor dem ersten Doppelpunkt.
///
/// Liefert `null`, wenn die Aufgabe gar keinen traegt. Das ist der Fall bei
/// Reports von vor DECISIONS 44.
String? ankerVon(String aufgabe) {
  final trenner = aufgabe.indexOf(':');
  if (trenner <= 0) return null;

  final anker = aufgabe.substring(0, trenner).trim();
  if (anker.isEmpty || anker.length > _maxAnkerZeichen) return null;
  return anker;
}

/// In welchen Abschnitt eine Aufgabe gehoert, und an welche Stelle darin.
///
/// Drei Faelle, drei Antworten:
///
///  * **Bekannter Anker** → sein Abschnitt, an seiner Stelle.
///  * **Unbekannter Anker** → „Bei Bedarf". Der Ausloeser ist dann eine
///    Situation und keine Tageszeit; genau das laesst der Prompt fuer die
///    Aufgaben aus dem Freitext zu.
///  * **Gar kein Anker** → „Tagsueber". Das trifft alte Reports. Sie
///    verschwinden nicht, sie stehen in der Mitte des Tages.
({Tagesabschnitt abschnitt, int rang}) einordnen(String aufgabe) {
  final anker = ankerVon(aufgabe);
  if (anker == null) {
    return (abschnitt: Tagesabschnitt.tagsueber, rang: 0);
  }

  final klein = anker.toLowerCase();
  for (var i = 0; i < _anker.length; i++) {
    if (_anker[i].de == klein || _anker[i].en == klein) {
      return (abschnitt: _anker[i].abschnitt, rang: i);
    }
  }

  return (abschnitt: Tagesabschnitt.beiBedarf, rang: 0);
}

/// Baut die Tagesliste aus den Kapiteln des Reports.
///
/// Die Kapitel bleiben die Quelle: Eine Aufgabe kann per Konstruktion nur aus
/// einem Kapitel kommen, das es im Report gibt – und damit nur aus einem
/// gewaehlten Modul. Umgebaut wird ausschliesslich die Anordnung.
List<Abschnittsgruppe> tagesliste(List<Kapitel> kapitel) {
  final aufgaben = <Tagesabschnitt, List<(int, Tagesaufgabe)>>{};

  // Der Laufindex haelt die urspruengliche Reihenfolge fest. Ohne ihn
  // vertauscht `sort` gleichrangige Aufgaben bei jedem Bauen neu – Dart
  // sortiert nicht stabil, und eine Liste, die beim Scrollen die Reihenfolge
  // wechselt, ist unbenutzbar.
  var lauf = 0;

  for (final k in kapitel) {
    for (final habit in k.habits) {
      final platz = einordnen(habit);
      aufgaben.putIfAbsent(platz.abschnitt, () => []).add((
        lauf++,
        Tagesaufgabe(
          text: habit,
          modul: k.modul,
          abschnitt: platz.abschnitt,
          rang: platz.rang,
        ),
      ));
    }
  }

  final gruppen = <Abschnittsgruppe>[];
  for (final abschnitt in Tagesabschnitt.values) {
    final eintraege = aufgaben[abschnitt];
    // Leere Abschnitte werden ausgeblendet – eine Ueberschrift ohne Inhalt
    // sieht aus, als fehle etwas.
    if (eintraege == null || eintraege.isEmpty) continue;

    eintraege.sort((a, b) {
      final nachRang = a.$2.rang.compareTo(b.$2.rang);
      return nachRang != 0 ? nachRang : a.$1.compareTo(b.$1);
    });

    gruppen.add(
      Abschnittsgruppe(
        abschnitt: abschnitt,
        aufgaben: [for (final e in eintraege) e.$2],
      ),
    );
  }

  return gruppen;
}
