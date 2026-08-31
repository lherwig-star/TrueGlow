import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/widgets/markdown_ansicht.dart';
import 'package:trueglow/features/legal/logic/rechtstexte.dart';

import 'hilfen.dart';
import 'package:trueglow/features/legal/ui/rechtsdokument_texte.dart';

void main() {
  group('Rechtstexte-Konfiguration', () {
    test('jedes Dokument hat eine Quelle in beiden Sprachen', () {
      // Seit SECURITY_AUDIT F2 liegen alle drei als Entwurf bei.
      expect(Rechtstexte.fehlende, isEmpty);

      for (final dokument in Rechtsdokument.values) {
        final quelle = Rechtstexte.quelle(dokument);
        expect(quelle.fuer('de'), isNotNull, reason: dokument.name);
        expect(quelle.fuer('en'), isNotNull, reason: dokument.name);
        expect(quelle.fuer('de'), isNot(quelle.fuer('en')),
            reason: dokument.name);
      }
    });

    test('bleibt trotzdem nicht einreichungsfaehig', () {
      // Der Release-Build muss weiter blockiert sein: Die Texte sind
      // Entwuerfe und noch nicht juristisch geprueft.
      expect(Rechtstexte.vollstaendig, isFalse);
      expect(Rechtstexte.fehlerbericht, contains('rechtstexte.dart'));
      expect(Rechtstexte.fehlerbericht, contains('entwurf'));
    });

    test('faellt auf Deutsch zurueck, wenn eine Sprache fehlt', () {
      // Besser ein Text in der falschen Sprache als gar keiner.
      const nurDeutsch = Rechtsquelle(asset: 'a/de.md');

      expect(nurDeutsch.fuer('en'), 'a/de.md');
      expect(const Rechtsquelle().fuer('de'), isNull);
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
        expect(find.text(dokument.titel(texte)), findsOneWidget);
      }
      // Jetzt liegt zu jedem etwas bei – der Hinweis „noch nicht
      // verfuegbar" gehoert damit der Vergangenheit an.
      expect(find.text('Noch nicht verfügbar'), findsNothing);
      expect(find.text('Rechtstext folgt.'), findsNothing);
    });

    testWidgets('und laesst sie antippen', (tester) async {
      handyGroesse(tester, hoehe: 1600);

      final container = await appMitDashboard(tester);
      container.read(routerProvider).go(Routes.rechtliches);
      await tester.pumpAndSettle();

      final eintrag = tester.widget<ListTile>(
        find.ancestor(
          of: find.text(Rechtsdokument.datenschutz.titel(texte)),
          matching: find.byType(ListTile),
        ),
      );
      expect(eintrag.onTap, isNotNull);
    });
  });

  group('Die Entwuerfe selbst', () {
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    /// Liest ein Asset so, wie die App es liest.
    Future<String> text(Rechtsdokument dokument, String sprache) async {
      final pfad = Rechtstexte.quelle(dokument).fuer(sprache)!;
      final daten = await rootBundle.load(pfad);
      return utf8.decode(daten.buffer.asUint8List());
    }

    test('jeder Text ist da und als Entwurf gekennzeichnet', () async {
      for (final dokument in Rechtsdokument.values) {
        for (final sprache in ['de', 'en']) {
          final inhalt = await text(dokument, sprache);

          expect(inhalt.length, greaterThan(500),
              reason: '${dokument.name}/$sprache');
          expect(
            inhalt.toLowerCase(),
            anyOf(contains('entwurf'), contains('draft'),
                contains('nicht ausgefüllt'), contains('not been filled')),
            reason: '${dokument.name}/$sprache',
          );
        }
      }
    });

    test('die Datenschutzerklaerung nennt, worauf es ankommt', () async {
      // Was ein Nutzer als Erstes wissen will – und was das Audit unter F2
      // vermisst hat.
      final inhalt = await text(Rechtsdokument.datenschutz, 'de');

      for (final stichwort in [
        'Gemini',
        'Drittlandtransfer',
        'europe-west3',
        'Art. 15',
        'Widerruf',
        'Löschen',
        '18',
      ]) {
        expect(inhalt, contains(stichwort), reason: stichwort);
      }
    });

    test('und die englische Fassung dasselbe', () async {
      final inhalt = await text(Rechtsdokument.datenschutz, 'en');

      for (final stichwort in [
        'Gemini',
        'outside the European Union',
        'europe-west3',
        'Art. 15',
        'withdraw',
      ]) {
        expect(inhalt, contains(stichwort), reason: stichwort);
      }
    });
  });
}
