import 'package:flutter/foundation.dart';

/// Ein Eintrag der Wissens-Bibliothek – die feste Erklärung zu einer Technik
/// oder einem Fachbegriff.
///
/// **Warum es die Bibliothek gibt.** Eine Aufgabe wie „5 Minuten
/// Gesichtsyoga" setzt Wissen voraus, das viele nicht haben. Bis hierher
/// ließ die App sie damit allein: Der Report nannte die Technik, der Plan
/// hakte sie ab, und wer nicht wusste, was gemeint ist, musste die App
/// verlassen, um es herauszufinden. Siehe DECISIONS 88.
///
/// **Warum fest hinterlegt und nicht erzeugt.** Eine Erklärung, die ein
/// Sprachmodell auf Zuruf schreibt, kostet bei jedem Antippen Geld und kann
/// bei jedem Antippen anders lauten. Diese Texte stehen im Bundle: kein
/// Aufruf, keine laufenden Kosten, keine Verbindung nötig – und sie sind
/// einmal gelesen und geprüft, statt jedes Mal neu erfunden.
@immutable
class Wissenseintrag {
  const Wissenseintrag({
    required this.id,
    required this.titel,
    required this.synonyme,
    required this.wasIstDas,
    required this.schritte,
    required this.wieOft,
    required this.womit,
    required this.woraufAchten,
  });

  /// Stabiler Name. Bei Techniken ist es der Enum-Name aus [Technik] – so
  /// hängen Katalog, Prompt und Bibliothek an derselben Kennung.
  final String id;

  /// Der Name, unter dem die Technik im Report auftaucht.
  final String titel;

  /// Weitere Schreibweisen, unter denen derselbe Eintrag erkannt wird –
  /// „Gua-Sha", „Chin Tucks", „SPF". Ohne sie hinge die Erkennung an einem
  /// Bindestrich.
  final List<String> synonyme;

  /// Zwei bis drei Sätze: was das ist und was es bringt.
  final String wasIstDas;

  /// Drei bis fünf Schritte, in der Reihenfolge, in der man sie tut.
  final List<String> schritte;

  /// Wie oft – der fachlich richtige Takt, nicht „regelmäßig".
  final String wieOft;

  /// Womit – Produktgattungen, keine Marken. Die App verkauft nichts.
  final String womit;

  /// Worauf zu achten ist: Verträglichkeit, Grenzen, wann man es lässt.
  /// Kein Kleingedrucktes – der Satz gehört zur Anleitung.
  final String woraufAchten;

  /// Alle Namen, unter denen dieser Eintrag gefunden wird.
  List<String> get namen => [titel, ...synonyme];

  factory Wissenseintrag.fromJson(Map<String, dynamic> json) =>
      Wissenseintrag(
        id: _text(json['id']),
        titel: _text(json['titel']),
        synonyme: _liste(json['synonyme']),
        wasIstDas: _text(json['wasIstDas']),
        schritte: _liste(json['schritte']),
        wieOft: _text(json['wieOft']),
        womit: _text(json['womit']),
        woraufAchten: _text(json['woraufAchten']),
      );

  static String _text(Object? wert) => wert is String ? wert : '';

  static List<String> _liste(Object? wert) => switch (wert) {
        final List<dynamic> l => [
            for (final e in l)
              if (e is String && e.trim().isNotEmpty) e,
          ],
        _ => const [],
      };
}
