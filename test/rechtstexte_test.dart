import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/widgets/markdown_ansicht.dart';
import 'package:trueglow/features/legal/logic/rechtstexte.dart';

import 'hilfen.dart';

void main() {
  group('Rechtstexte-Konfiguration', () {
    test('erkennt fehlende Quellen und meldet sie verstaendlich', () {
      // Solange nichts eingetragen ist, muss die App das auch sagen –
      // ein stiller Zustand waere hier der gefaehrlichste.
      expect(Rechtstexte.fehlende, isNotEmpty);
      expect(Rechtstexte.vollstaendig, isFalse);
      expect(Rechtstexte.fehlerbericht, contains('rechtstexte.dart'));
    });

    test('eine Quelle ohne URL und ohne Asset gilt als nicht vorhanden', () {
      expect(const Rechtsquelle().vorhanden, isFalse);
      expect(const Rechtsquelle(url: '   ').vorhanden, isFalse);
      expect(const Rechtsquelle(url: 'https://x.de').vorhanden, isTrue);
      expect(const Rechtsquelle(asset: 'a/b.md').vorhanden, isTrue);
    });

    test('eine Entwurfsversion allein blockiert schon', () {
      // Auch mit allen drei Adressen ist die App nicht einreichungsfaehig,
      // solange die Textversion "Entwurf" sagt.
      expect(Rechtstexte.istEntwurf, isTrue);
      expect(Rechtstexte.version, isNotEmpty);
    });

    test('jedes Dokument hat einen stabilen Schluessel', () {
      for (final dokument in Rechtsdokument.values) {
        expect(Rechtsdokument.ausName(dokument.schluessel), dokument);
      }
      expect(Rechtsdokument.ausName('gibtsNicht'), isNull);
      expect(Rechtsdokument.ausName(null), isNull);
    });
  });

  group('MarkdownBlock', () {
    test('erkennt Ueberschriften bis Ebene 3', () {
      final bloecke = MarkdownBlock.zerlege('# Eins\n## Zwei\n### Drei');

      expect(
        bloecke.map((b) => b.art),
        [
          MarkdownArt.ueberschrift1,
          MarkdownArt.ueberschrift2,
          MarkdownArt.ueberschrift3,
        ],
      );
      expect(bloecke.map((b) => b.text), ['Eins', 'Zwei', 'Drei']);
    });

    test('zieht harte Zeilenumbrueche zu einem Absatz zusammen', () {
      final bloecke = MarkdownBlock.zerlege(
        'Erste Zeile\nzweite Zeile\n\nNeuer Absatz',
      );

      expect(bloecke, hasLength(2));
      expect(bloecke.first.text, 'Erste Zeile zweite Zeile');
      expect(bloecke.last.text, 'Neuer Absatz');
    });

    test('erkennt Aufzaehlungen mit Strich, Stern und Nummer', () {
      final bloecke = MarkdownBlock.zerlege('- eins\n* zwei\n3. drei');

      expect(bloecke.every((b) => b.art == MarkdownArt.aufzaehlung), isTrue);
      expect(bloecke.map((b) => b.text), ['eins', 'zwei', 'drei']);
      expect(bloecke.map((b) => b.aufzaehlungszeichen), ['•', '•', '3.']);
    });

    test('loest fett und kursiv auf', () {
      final teile = MarkdownBlock.inlineZerlegen('ganz **fett** und *schief*');

      expect(teile, [
        const MarkdownTeil('ganz '),
        const MarkdownTeil('fett', fett: true),
        const MarkdownTeil(' und '),
        const MarkdownTeil('schief', kursiv: true),
      ]);
    });

    test('macht die Adresse eines Links sichtbar', () {
      // Ein Rechtstext wird oft vorgelesen oder ausgedruckt – eine Adresse,
      // die nur im Tap steckt, ist dort verloren.
      final teile = MarkdownBlock.inlineZerlegen(
        'Mehr unter [unserer Seite](https://trueglow.app).',
      );

      expect(
        teile.map((t) => t.text).join(),
        'Mehr unter unserer Seite (https://trueglow.app).',
      );
    });

    test('kommt mit leerem Text klar', () {
      expect(MarkdownBlock.zerlege(''), isEmpty);
      expect(MarkdownBlock.zerlege('\n\n  \n'), isEmpty);
      expect(MarkdownBlock.inlineZerlegen(''), [const MarkdownTeil('')]);
    });
  });

  group('Rechtliches-Screen', () {
    testWidgets('zeigt alle drei Dokumente und ihren Zustand', (tester) async {
      handyGroesse(tester, hoehe: 1600);

      final container = await appMitDashboard(tester);
      container.read(routerProvider).go(Routes.rechtliches);
      await tester.pumpAndSettle();

      for (final dokument in Rechtsdokument.values) {
        expect(find.text(dokument.titel), findsOneWidget);
      }
      // Solange nichts hinterlegt ist, sagt der Screen das dreimal deutlich.
      expect(find.text('Noch nicht verfügbar'), findsNWidgets(3));
      // Und die alte Platzhalter-Snackbar gibt es nicht mehr.
      expect(find.text('Rechtstext folgt.'), findsNothing);
    });

    testWidgets('ein Eintrag ohne Quelle laesst sich nicht antippen',
        (tester) async {
      handyGroesse(tester, hoehe: 1600);

      final container = await appMitDashboard(tester);
      container.read(routerProvider).go(Routes.rechtliches);
      await tester.pumpAndSettle();

      final eintrag = tester.widget<ListTile>(
        find.ancestor(
          of: find.text(Rechtsdokument.datenschutz.titel),
          matching: find.byType(ListTile),
        ),
      );
      expect(eintrag.onTap, isNull);
    });
  });
}
