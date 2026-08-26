import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/analysis/logic/kontingent.dart';

/// Der Kontingent-Hinweis vor der Aufnahme (`SETUP.md` 6.4, DECISIONS.md).
///
/// Die Regeln hier spiegeln `stand()` in `functions/src/limit.ts`. Laufen die
/// beiden auseinander, zeigt die App etwas anderes an, als der Server
/// entscheidet — der teuerste Fall waere ein Hinweis, der jemanden aussperrt,
/// obwohl noch Kontingent da ist.
void main() {
  /// Baut den Zaehler so, wie `reservieren()` ihn schreibt.
  Map<String, dynamic> zaehler({
    required String tag,
    required int tagZaehler,
    String? monat,
    int? monatZaehler,
  }) =>
      {
        'tag': tag,
        'tagZaehler': tagZaehler,
        'monat': monat ?? tag.substring(0, 7),
        'monatZaehler': monatZaehler ?? tagZaehler,
      };

  final heute = DateTime(2026, 8, 24, 14, 30);

  group('KontingentStand', () {
    test('ohne Dokument ist alles frei', () {
      // Kein Dokument heisst: noch nie eine Analyse gelaufen.
      final stand = KontingentStand.ausDaten(null, jetzt: heute);

      expect(stand.tagVerbraucht, 0);
      expect(stand.tagUebrig, KontingentStand.proTag);
      expect(stand.erschoepft, isFalse);
    });

    test('zaehlt den heutigen Stand', () {
      final stand = KontingentStand.ausDaten(
        zaehler(tag: '2026-08-24', tagZaehler: 2),
        jetzt: heute,
      );

      expect(stand.tagUebrig, 1);
      expect(stand.erschoepft, isFalse);
    });

    test('erkennt die Tagesgrenze', () {
      final stand = KontingentStand.ausDaten(
        zaehler(tag: '2026-08-24', tagZaehler: 3),
        jetzt: heute,
      );

      expect(stand.tagUebrig, 0);
      expect(stand.erschoepft, isTrue);
      expect(stand.monatsgrenzeErreicht, isFalse);
    });

    test('ein gestriger Zaehler sperrt heute nicht mehr', () {
      // Der Kern der Normalisierung: Der Server setzt den Zaehler nicht
      // zurueck, er vergleicht den Tagesschluessel. Ohne dieselbe Regel im
      // Client wuerde die App nach drei Analysen fuer immer sperren.
      final stand = KontingentStand.ausDaten(
        zaehler(tag: '2026-08-23', tagZaehler: 3),
        jetzt: heute,
      );

      expect(stand.tagVerbraucht, 0);
      expect(stand.erschoepft, isFalse);
    });

    test('der Monatszaehler ueberlebt den Tageswechsel', () {
      // Gestern, aber derselbe Monat: Der Tag ist frei, der Monat zaehlt weiter.
      final stand = KontingentStand.ausDaten(
        zaehler(
          tag: '2026-08-23',
          tagZaehler: 3,
          monat: '2026-08',
          monatZaehler: 4,
        ),
        jetzt: heute,
      );

      expect(stand.tagVerbraucht, 0);
      expect(stand.monatVerbraucht, 4);
      expect(stand.erschoepft, isFalse);
    });

    test('erkennt die Monatsgrenze und unterscheidet sie von der Tagesgrenze',
        () {
      // Wichtig fuer den Text: „ab morgen wieder" waere hier gelogen.
      final stand = KontingentStand.ausDaten(
        zaehler(
          tag: '2026-08-24',
          tagZaehler: 0,
          monat: '2026-08',
          monatZaehler: KontingentStand.proMonat,
        ),
        jetzt: heute,
      );

      expect(stand.tagUebrig, KontingentStand.proTag);
      expect(stand.erschoepft, isTrue);
      expect(stand.monatsgrenzeErreicht, isTrue);
    });

    test('ein Zaehler aus dem Vormonat zaehlt nicht mehr', () {
      final stand = KontingentStand.ausDaten(
        zaehler(
          tag: '2026-07-31',
          tagZaehler: 3,
          monat: '2026-07',
          monatZaehler: KontingentStand.proMonat,
        ),
        jetzt: heute,
      );

      expect(stand.monatVerbraucht, 0);
      expect(stand.erschoepft, isFalse);
    });

    test('unplausible Werte zaehlen als 0 statt zu sperren', () {
      // Spiegel von `zahl()` serverseitig. Im Zweifel nicht aussperren.
      for (final kaputt in <Object?>[null, -5, 'drei', double.nan, {}]) {
        final stand = KontingentStand.ausDaten(
          {'tag': '2026-08-24', 'tagZaehler': kaputt, 'monat': '2026-08'},
          jetzt: heute,
        );

        expect(
          stand.tagVerbraucht,
          0,
          reason: 'Wert $kaputt darf nicht sperren',
        );
      }
    });

    test('Nachkommastellen werden abgerundet, nicht aufgerundet', () {
      final stand = KontingentStand.ausDaten(
        zaehler(tag: '2026-08-24', tagZaehler: 2)..['tagZaehler'] = 2.9,
        jetzt: heute,
      );

      expect(stand.tagVerbraucht, 2);
    });

    test('zehn Analysen im Monat, drei am Tag', () {
      // Die Zahlen spiegeln GRENZEN.analyse in `functions/src/limit.ts`.
      // Laufen sie auseinander, zeigt die App etwas anderes an, als der
      // Server entscheidet.
      expect(KontingentStand.proTag, 3);
      expect(KontingentStand.proMonat, 10);
    });

    test('die neunte Analyse im Monat ist noch frei', () {
      final stand = KontingentStand.ausDaten(
        zaehler(
          tag: '2026-08-24',
          tagZaehler: 1,
          monat: '2026-08',
          monatZaehler: 9,
        ),
        jetzt: heute,
      );

      expect(stand.monatUebrig, 1);
      expect(stand.erschoepft, isFalse);
    });

    test('mehr als die Grenze ergibt nie eine negative Restzahl', () {
      // Kaeme durch einen Serverfehler ein zu hoher Stand, soll die Anzeige
      // „0 uebrig" sagen und nicht „-2".
      final stand = KontingentStand.ausDaten(
        zaehler(tag: '2026-08-24', tagZaehler: 99),
        jetzt: heute,
      );

      expect(stand.tagUebrig, 0);
      expect(stand.monatUebrig, 0);
    });
  });
}
