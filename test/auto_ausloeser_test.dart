import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/capture/logic/auto_ausloeser.dart';
import 'package:trueglow/features/capture/logic/live_face_guide.dart';
import 'package:trueglow/features/capture/logic/live_koerper_guide.dart';

/// Der Auto-Ausloeser fuer die Ganzkoerperfotos.
///
/// Diese Logik laesst sich am Geraet kaum pruefen: Man steht drei Meter
/// entfernt, sieht den Bildschirm nicht und merkt einen Fehler erst am
/// misslungenen Foto. Deshalb liegt der gesamte Ablauf in gewoehnlichen
/// Tests, in denen die Zeit von Hand weitergesetzt wird.
void main() {
  final t0 = DateTime(2026, 8, 25, 12);

  group('AutoAusloeser', () {
    test('zaehlt bei guter Haltung von 3 herunter und loest aus', () {
      final ausloeser = AutoAusloeser();

      expect(
        ausloeser.melde(bereit: true, jetzt: t0),
        const AutoZustand(AutoPhase.zaehlt, 3),
      );
      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 1100)),
        ),
        const AutoZustand(AutoPhase.zaehlt, 2),
      );
      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 2100)),
        ),
        const AutoZustand(AutoPhase.zaehlt, 1),
      );
      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 3100)),
        ),
        const AutoZustand(AutoPhase.ausgeloest),
      );
    });

    test('die erste Sekunde zeigt voll „3", nicht sofort „2"', () {
      // Abgerundet spraenge die Anzeige beim ersten Frame auf 2 und der
      // Countdown fuehlte sich um eine Sekunde zu kurz an.
      final ausloeser = AutoAusloeser();
      ausloeser.melde(bereit: true, jetzt: t0);

      expect(
        ausloeser
            .melde(
              bereit: true,
              jetzt: t0.add(const Duration(milliseconds: 999)),
            )
            .verbleibend,
        3,
      );
    });

    test('ohne gute Haltung passiert nichts', () {
      final ausloeser = AutoAusloeser();

      expect(
        ausloeser.melde(bereit: false, jetzt: t0),
        const AutoZustand(AutoPhase.warten),
      );
      expect(
        ausloeser.melde(
          bereit: false,
          jetzt: t0.add(const Duration(seconds: 10)),
        ),
        const AutoZustand(AutoPhase.warten),
      );
    });

    test('kurzes Flackern der Erkennung bricht nicht ab', () {
      // Der wichtigste Fall: Die Posenerkennung ist unstet, ein einzelner
      // Frame ohne sichere Knoechel genuegt. Ohne Nachsicht kaeme der
      // Countdown nie durch.
      final ausloeser = AutoAusloeser();

      ausloeser.melde(bereit: true, jetzt: t0);
      final waehrendFlackern = ausloeser.melde(
        bereit: false,
        jetzt: t0.add(const Duration(milliseconds: 1200)),
      );
      expect(waehrendFlackern.phase, AutoPhase.zaehlt);

      // Haltung ist wieder da – der Countdown lief unterdessen weiter.
      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 3100)),
        ),
        const AutoZustand(AutoPhase.ausgeloest),
      );
    });

    test('anhaltender Haltungsverlust bricht ab und setzt zurueck', () {
      final ausloeser = AutoAusloeser();

      ausloeser.melde(bereit: true, jetzt: t0);
      expect(
        ausloeser.melde(
          bereit: false,
          jetzt: t0.add(const Duration(milliseconds: 1000)),
        ).phase,
        AutoPhase.zaehlt,
        reason: 'innerhalb der Nachsicht',
      );
      expect(
        ausloeser.melde(
          bereit: false,
          jetzt: t0.add(const Duration(milliseconds: 1900)),
        ),
        const AutoZustand(AutoPhase.warten),
        reason: 'Nachsicht abgelaufen',
      );

      // Und danach faengt der Countdown wieder bei 3 an, nicht dort, wo er
      // aufgehoert hat.
      expect(
        ausloeser
            .melde(
              bereit: true,
              jetzt: t0.add(const Duration(milliseconds: 2000)),
            )
            .verbleibend,
        3,
      );
    });

    test('nach dem Ausloesen bleibt es dabei, bis zurueckgesetzt wird', () {
      // Sonst schiesst die Kamera waehrend der Vorschau munter weiter.
      final ausloeser = AutoAusloeser();

      ausloeser.melde(bereit: true, jetzt: t0);
      ausloeser.melde(bereit: true, jetzt: t0.add(const Duration(seconds: 4)));

      for (final bereit in [true, false, true]) {
        expect(
          ausloeser.melde(
            bereit: bereit,
            jetzt: t0.add(const Duration(seconds: 5)),
          ),
          const AutoZustand(AutoPhase.ausgeloest),
        );
      }

      ausloeser.zuruecksetzen();
      expect(ausloeser.phase, AutoPhase.warten);
      expect(
        ausloeser
            .melde(bereit: true, jetzt: t0.add(const Duration(seconds: 6)))
            .verbleibend,
        3,
      );
    });
  });

  group('LiveKoerperGuide', () {
    const guide = LiveKoerperGuide();
    const bild = Size(1000, 2000);

    /// Person mittig, 70 % der Bildhoehe – der Normalfall.
    Koerperlage lage({
      double hoeheAnteil = 0.70,
      double mitteX = 0.5,
      bool kopf = true,
      bool fuesse = true,
    }) {
      final hoehe = bild.height * hoeheAnteil;
      return Koerperlage(
        umriss: Rect.fromCenter(
          center: Offset(bild.width * mitteX, bild.height / 2),
          width: bild.width * 0.25,
          height: hoehe,
        ),
        kopfSichtbar: kopf,
        fuesseSichtbar: fuesse,
      );
    }

    test('mittig und vollstaendig ist bereit', () {
      expect(
        guide.bewerte(lage: lage(), bildGroesse: bild),
        KoerperHinweis.bereit,
      );
    });

    test('ohne Person kommt keine Aufforderung zum Stillhalten', () {
      expect(
        guide.bewerte(lage: null, bildGroesse: bild),
        KoerperHinweis.niemand,
      );
    });

    test('angeschnitten sagt „ganz ins Bild", nicht „zu nah"', () {
      // Der Unterschied zaehlt: Das eine sagt, was zu tun ist, das andere
      // laesst raten.
      expect(
        guide.bewerte(lage: lage(fuesse: false), bildGroesse: bild),
        KoerperHinweis.nichtGanz,
      );
      expect(
        guide.bewerte(lage: lage(kopf: false), bildGroesse: bild),
        KoerperHinweis.nichtGanz,
      );
    });

    test('zu klein und zu gross werden unterschieden', () {
      expect(
        guide.bewerte(lage: lage(hoeheAnteil: 0.35), bildGroesse: bild),
        KoerperHinweis.zuWeitWeg,
      );
      expect(
        guide.bewerte(lage: lage(hoeheAnteil: 0.99), bildGroesse: bild),
        KoerperHinweis.zuNah,
      );
    });

    test('seitlich versetzt loest nicht aus', () {
      expect(
        guide.bewerte(lage: lage(mitteX: 0.80), bildGroesse: bild),
        KoerperHinweis.nichtMittig,
      );
    });

    test('zu dunkel geht allem voraus', () {
      // Bei zu wenig Licht findet die Posenerkennung ohnehin nichts
      // Verlaessliches – „mehr Licht" ist der brauchbare Hinweis.
      expect(
        guide.bewerte(
          lage: lage(),
          bildGroesse: bild,
          helligkeit: LiveFaceGuide.minHelligkeit - 1,
        ),
        KoerperHinweis.zuDunkel,
      );
      expect(
        guide.bewerte(lage: null, bildGroesse: bild, helligkeit: 10),
        KoerperHinweis.zuDunkel,
      );
    });

    test('nur „bereit" loest aus, und jeder Hinweis hat einen Text', () {
      for (final hinweis in KoerperHinweis.values) {
        expect(hinweis.text, isNotEmpty, reason: '${hinweis.name} ohne Text');
        expect(hinweis.loestAus, hinweis == KoerperHinweis.bereit);
      }
    });
  });
}
