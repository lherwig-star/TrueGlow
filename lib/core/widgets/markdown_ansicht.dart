import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Zeigt Markdown an – so viel davon, wie Rechtstexte brauchen.
///
/// Bewusst ohne Paket: Datenschutzerklärung, AGB und Impressum bestehen aus
/// Überschriften, Absätzen und Aufzählungen. Dafür ein Paket einzubinden,
/// dessen Pflegezustand man mitschleppt, wäre teurer als diese knapp
/// hundert Zeilen.
///
/// Unterstützt: `#`/`##`/`###`-Überschriften, Absätze, `-`/`*`-Listen,
/// nummerierte Listen, `**fett**`, `*kursiv*` und `[Text](URL)` (die Adresse
/// wird sichtbar dahintergesetzt, damit sie auch beim Vorlesen ankommt).
class MarkdownAnsicht extends StatelessWidget {
  const MarkdownAnsicht(this.markdown, {super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in MarkdownBlock.zerlege(markdown))
          Padding(
            padding: EdgeInsets.only(bottom: block.abstandDanach),
            child: _blockWidget(context, block),
          ),
      ],
    );
  }

  Widget _blockWidget(BuildContext context, MarkdownBlock block) {
    final farben = context.farben;

    return switch (block.art) {
      MarkdownArt.ueberschrift1 => Text(
          block.text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      MarkdownArt.ueberschrift2 => Text(
          block.text,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      MarkdownArt.ueberschrift3 => Text(
          block.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      MarkdownArt.aufzaehlung => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.gapXs),
              child: Text(
                block.aufzaehlungszeichen,
                style: TextStyle(height: 1.5, color: farben.akzent),
              ),
            ),
            Expanded(
              child: SelectableText.rich(
                TextSpan(children: _inline(block.text)),
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ],
        ),
      MarkdownArt.absatz => SelectableText.rich(
          TextSpan(children: _inline(block.text)),
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
    };
  }

  List<TextSpan> _inline(String text) => [
        for (final teil in MarkdownBlock.inlineZerlegen(text))
          TextSpan(
            text: teil.text,
            style: TextStyle(
              fontWeight: teil.fett ? FontWeight.w700 : null,
              fontStyle: teil.kursiv ? FontStyle.italic : null,
            ),
          ),
      ];
}

enum MarkdownArt {
  ueberschrift1,
  ueberschrift2,
  ueberschrift3,
  absatz,
  aufzaehlung,
}

/// Ein Sinnabschnitt des Dokuments.
@immutable
class MarkdownBlock {
  const MarkdownBlock({
    required this.art,
    required this.text,
    this.aufzaehlungszeichen = '•',
  });

  final MarkdownArt art;
  final String text;

  /// Punkt oder Nummer vor einem Listeneintrag.
  final String aufzaehlungszeichen;

  double get abstandDanach => switch (art) {
        MarkdownArt.ueberschrift1 => AppTheme.gapS,
        MarkdownArt.ueberschrift2 => AppTheme.gapXs,
        MarkdownArt.ueberschrift3 => AppTheme.gapXs,
        MarkdownArt.aufzaehlung => AppTheme.gapXs,
        MarkdownArt.absatz => AppTheme.gapS,
      };

  /// Zerlegt ein Dokument in Bloecke.
  ///
  /// Zeilen innerhalb eines Absatzes werden zusammengezogen – so bleibt der
  /// harte Zeilenumbruch der Quelldatei ohne Wirkung auf die Darstellung.
  static List<MarkdownBlock> zerlege(String markdown) {
    final bloecke = <MarkdownBlock>[];
    final absatz = <String>[];

    void absatzAbschliessen() {
      if (absatz.isEmpty) return;
      bloecke.add(
        MarkdownBlock(art: MarkdownArt.absatz, text: absatz.join(' ')),
      );
      absatz.clear();
    }

    for (final rohzeile in markdown.split('\n')) {
      final zeile = rohzeile.trimRight();
      final ohneEinzug = zeile.trimLeft();

      if (ohneEinzug.isEmpty) {
        absatzAbschliessen();
        continue;
      }

      final ueberschrift = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(ohneEinzug);
      if (ueberschrift != null) {
        absatzAbschliessen();
        bloecke.add(
          MarkdownBlock(
            art: switch (ueberschrift.group(1)!.length) {
              1 => MarkdownArt.ueberschrift1,
              2 => MarkdownArt.ueberschrift2,
              _ => MarkdownArt.ueberschrift3,
            },
            text: ueberschrift.group(2)!.trim(),
          ),
        );
        continue;
      }

      final punkt = RegExp(r'^[-*]\s+(.*)$').firstMatch(ohneEinzug);
      if (punkt != null) {
        absatzAbschliessen();
        bloecke.add(
          MarkdownBlock(
            art: MarkdownArt.aufzaehlung,
            text: punkt.group(1)!.trim(),
          ),
        );
        continue;
      }

      final nummer = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(ohneEinzug);
      if (nummer != null) {
        absatzAbschliessen();
        bloecke.add(
          MarkdownBlock(
            art: MarkdownArt.aufzaehlung,
            text: nummer.group(2)!.trim(),
            aufzaehlungszeichen: '${nummer.group(1)}.',
          ),
        );
        continue;
      }

      absatz.add(ohneEinzug);
    }

    absatzAbschliessen();
    return bloecke;
  }

  /// Loest `**fett**`, `*kursiv*` und `[Text](URL)` auf.
  static List<MarkdownTeil> inlineZerlegen(String text) {
    // Links zuerst: Die Adresse bleibt sichtbar, damit sie auch dann
    // ankommt, wenn niemand tippen kann oder ein Screenreader vorliest.
    final aufgeloest = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (treffer) => '${treffer.group(1)} (${treffer.group(2)})',
    );

    final teile = <MarkdownTeil>[];
    final muster = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    var position = 0;

    for (final treffer in muster.allMatches(aufgeloest)) {
      if (treffer.start > position) {
        teile.add(
          MarkdownTeil(aufgeloest.substring(position, treffer.start)),
        );
      }
      if (treffer.group(1) != null) {
        teile.add(MarkdownTeil(treffer.group(1)!, fett: true));
      } else {
        teile.add(MarkdownTeil(treffer.group(2)!, kursiv: true));
      }
      position = treffer.end;
    }

    if (position < aufgeloest.length) {
      teile.add(MarkdownTeil(aufgeloest.substring(position)));
    }
    return teile.isEmpty ? [MarkdownTeil(aufgeloest)] : teile;
  }
}

/// Ein Textstück mit seiner Auszeichnung.
@immutable
class MarkdownTeil {
  const MarkdownTeil(this.text, {this.fett = false, this.kursiv = false});

  final String text;
  final bool fett;
  final bool kursiv;

  @override
  bool operator ==(Object other) =>
      other is MarkdownTeil &&
      other.text == text &&
      other.fett == fett &&
      other.kursiv == kursiv;

  @override
  int get hashCode => Object.hash(text, fett, kursiv);

  @override
  String toString() =>
      'MarkdownTeil("$text"${fett ? ', fett' : ''}${kursiv ? ', kursiv' : ''})';
}
