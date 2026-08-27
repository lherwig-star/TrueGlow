import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/features/capture/logic/auto_ausloeser.dart';
import 'package:trueglow/features/capture/logic/live_face_guide.dart';
import 'package:trueglow/features/capture/logic/live_koerper_guide.dart';
import 'package:trueglow/features/capture/logic/signalton.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/ui/widgets/silhouette_overlay.dart';

/// Die deutschen Texte, gegen die geprueft wird.
final texte = lookupL(const Locale('de'));

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

    test('Aussetzer kurz vor Schluss verhindert die Aufnahme nicht', () {
      // Der Fehler aus dem Geraete-Test: Der Countdown zaehlte 3-2-1 herunter
      // und danach passierte nichts. Grund war die Nachsicht – lief die Zeit
      // waehrend eines Aussetzers ab, blieb die Anzeige auf „1" stehen, statt
      // auszuloesen, und nach 700 ms fing alles von vorn an.
      //
      // Genau so verhaelt sich die Posenerkennung aus drei Metern: Ein
      // einzelner Frame ohne sichere Knoechel genuegt, und der faellt mit
      // einiger Wahrscheinlichkeit auf die letzte Sekunde.
      final ausloeser = AutoAusloeser();

      ausloeser.melde(bereit: true, jetzt: t0);
      expect(
        ausloeser
            .melde(
              bereit: true,
              jetzt: t0.add(const Duration(milliseconds: 2500)),
            )
            .verbleibend,
        1,
      );

      // Ab hier zweifelt die Erkennung – die Person steht aber weiter.
      expect(
        ausloeser.melde(
          bereit: false,
          jetzt: t0.add(const Duration(milliseconds: 2750)),
        ),
        const AutoZustand(AutoPhase.zaehlt, 1),
        reason: 'in der Nachsicht laeuft der Countdown sichtbar weiter',
      );
      expect(
        ausloeser.melde(
          bereit: false,
          jetzt: t0.add(const Duration(milliseconds: 3050)),
        ),
        const AutoZustand(AutoPhase.ausgeloest),
        reason: 'die drei Sekunden sind um – jetzt muss ein Foto entstehen',
      );
    });

    test('ein voller Ablauf loest genau einmal aus – auch mit Flackern', () {
      // Der Ablauf, wie er am Geraet stattfindet: vier ausgewertete Frames je
      // Sekunde, dazwischen zweifelt die Erkennung gelegentlich. Am Ende muss
      // genau ein Ausloesen stehen, nicht keines und nicht drei.
      final ausloeser = AutoAusloeser();

      // Jeder vierte Frame faellt aus – ein einzelner Aussetzer, nie zwei
      // hintereinander, also immer innerhalb der Nachsicht.
      var ausgeloest = 0;
      var zaehlstaende = <int>[];

      for (var i = 0; i <= 16; i++) {
        final zustand = ausloeser.melde(
          bereit: i % 4 != 3,
          jetzt: t0.add(Duration(milliseconds: 250 * i)),
        );
        switch (zustand.phase) {
          case AutoPhase.ausgeloest:
            ausgeloest++;
          case AutoPhase.zaehlt:
            zaehlstaende.add(zustand.verbleibend);
          case AutoPhase.warten:
            fail('der Countdown darf bei einzelnen Aussetzern nicht abbrechen');
        }
      }

      expect(zaehlstaende.toSet(), {3, 2, 1});
      expect(ausgeloest, greaterThan(0), reason: 'es wurde nie ausgeloest');
      expect(
        ausloeser.phase,
        AutoPhase.ausgeloest,
        reason: 'nach dem Ausloesen bleibt es dabei',
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
        expect(hinweis.text(texte), isNotEmpty, reason: '${hinweis.name} ohne Text');
        expect(hinweis.loestAus, hinweis == KoerperHinweis.bereit);
      }
    });
  });

  group('Signalton', () {
    test('der Audio-Kontext laesst sich ueberhaupt bauen', () {
      // Der eigentliche Fehler hinter „Countdown laeuft, kein Foto": Die
      // Kombination `ambient` + `mixWithOthers` ist unzulaessig, und
      // `AudioContextIOS` bricht deshalb schon beim Bauen mit einer
      // Zusicherung ab. Der Ausloese-Ton steht eine Zeile vor der Aufnahme –
      // die Ausnahme riss die Kette genau dort auseinander.
      //
      // Geprueft wird der Kontext und nicht das Abspielen: Die Zusicherung
      // schlaegt vor jeder Tonausgabe zu, und ein Test braucht dafuer weder
      // Lautsprecher noch Geraet.
      expect(EchterSignalton.kontext, returnsNormally);
    });
  });

  group('Ganzkoerper-Silhouette', () {
    /// Vom sehr schmalen Handy bis zum Tablet. Der Galaxy A52 (20:9) ist das
    /// Geraet, auf dem die gestreckte Figur aufgefallen ist.
    const flaechen = <Size>[
      Size(411, 914), // Galaxy A52, 20:9
      Size(360, 640), // 16:9, das Format, fuer das die Figur entworfen ist
      Size(430, 932), // grosses iPhone
      Size(768, 1024), // Tablet, 3:4
      Size(320, 800), // absichtlich extrem schmal
    ];

    /// Aussenmasse der Figur auf einer Flaeche dieser Groesse.
    Rect umriss(Size flaeche, {required bool seitlich}) =>
        SilhouetteOverlay.ganzkoerperUmriss(flaeche, seitlich: seitlich)
            .getBounds();

    for (final (name, seitlich) in [('frontal', false), ('seitlich', true)]) {
      test('$name: Seitenverhaeltnis haengt nicht an der Bildschirmgroesse',
          () {
        // Der eigentliche Fehler: x-Werte hingen an der Bildschirmbreite,
        // y-Werte an der Bildschirmhoehe. Auf einem 20:9-Handy wurde die
        // Figur damit fast doppelt so schlank wie auf einem 16:9-Geraet.
        final verhaeltnisse = [
          for (final flaeche in flaechen)
            umriss(flaeche, seitlich: seitlich).width /
                umriss(flaeche, seitlich: seitlich).height,
        ];

        for (final v in verhaeltnisse) {
          expect(
            v,
            closeTo(verhaeltnisse.first, 0.001),
            reason: 'Figur wird je nach Bildschirmformat anders gestaucht',
          );
        }
      });

      test('$name: die Figur hat menschliche Proportionen', () {
        for (final flaeche in flaechen) {
          final grenzen = umriss(flaeche, seitlich: seitlich);
          final schlankheit = grenzen.height / grenzen.width;

          // Von vorn ist ein stehender Mensch grob viermal so hoch wie breit,
          // im Profil rund sechsmal (Bauch bis Gesaess, Ferse bis Zehen).
          // Achtmal so hoch wie breit ist ein Strich, kein Mensch.
          expect(
            schlankheit,
            seitlich ? inInclusiveRange(5, 7.5) : inInclusiveRange(3.5, 5),
            reason: '$flaeche: 1:${schlankheit.toStringAsFixed(1)}',
          );
        }
      });

      test('$name: die Figur liegt vollstaendig im Bild', () {
        for (final flaeche in flaechen) {
          final grenzen = umriss(flaeche, seitlich: seitlich);

          expect(grenzen.left, greaterThanOrEqualTo(0), reason: '$flaeche');
          expect(grenzen.right, lessThanOrEqualTo(flaeche.width),
              reason: '$flaeche');
          expect(grenzen.top, greaterThanOrEqualTo(0), reason: '$flaeche');

          // Unten bleibt die Bedienleiste frei: Ausloeser, Galerie und
          // Kamerawechsel brauchen rund ein Siebtel der Bildhoehe. Genau da
          // liefen die Beine der alten Figur hinein.
          expect(
            grenzen.bottom,
            lessThanOrEqualTo(flaeche.height * 0.85),
            reason: '$flaeche: Fuesse ragen in die Bedienleiste',
          );
        }
      });

      test('$name: die Figur passt in das, was der Guide akzeptiert', () {
        // Wer sich genau nach der Silhouette ausrichtet, muss den
        // Auto-Ausloeser ausloesen koennen. Die Kameravorschau fuellt den
        // Bildschirm in der Hoehe vollstaendig aus, deshalb ist der Anteil
        // an der Bildhoehe direkt vergleichbar.
        for (final flaeche in flaechen) {
          final anteil = umriss(flaeche, seitlich: seitlich).height /
              flaeche.height;

          // Und zwar mit Abstand zu beiden Raendern: Die alte Figur fuellte
          // 89 % der Bildhoehe, die Obergrenze liegt bei 94 %. Wer sich
          // danach ausrichtete, stand am Rand des Erlaubten, und jedes
          // Zittern der Posenerkennung kippte die Bewertung auf „zu nah".
          const spanne = LiveKoerperGuide.maxHoehe - LiveKoerperGuide.minHoehe;
          expect(
            anteil,
            inInclusiveRange(
              LiveKoerperGuide.minHoehe + spanne * 0.25,
              LiveKoerperGuide.maxHoehe - spanne * 0.25,
            ),
            reason: '$flaeche: Silhouette zielt auf den Rand dessen, was der '
                'Guide akzeptiert',
          );
        }
      });
    }
  });

  group('Der Auto-Ausloeser spricht bei den Outfit-Fotos anders', () {
    test('die Erklaerung nennt dort keinen Umriss', () {
      // Die Ganzkoerperfotos haben eine Silhouette, in die man sich stellt.
      // Die Outfit-Fotos haben keine – „stell dich in den Umriss" schickte
      // den Nutzer dort nach etwas suchen, was nicht da ist.
      final koerper =
          AufnahmeTyp.figurGanzkoerperFrontal.autoHinweis(texte);
      final outfit = AufnahmeTyp.stilOutfitEins.autoHinweis(texte);

      expect(koerper, contains('Umriss'));
      expect(outfit, isNot(contains('Umriss')));
      expect(outfit, isNot(equals(koerper)));
    });

    test('und sagt, was beim ausgelegten Outfit passiert', () {
      // Ohne diesen Satz wartet jemand mit einem Outfit auf dem Bett auf
      // einen Countdown, der nie kommt.
      expect(
        AufnahmeTyp.stilOutfitEins.autoHinweis(texte),
        contains('von Hand'),
      );
    });

    test('alle drei Outfit-Fotos bekommen denselben Text', () {
      for (final typ in [
        AufnahmeTyp.stilOutfitZwei,
        AufnahmeTyp.stilOutfitDrei,
      ]) {
        expect(
          typ.autoHinweis(texte),
          AufnahmeTyp.stilOutfitEins.autoHinweis(texte),
          reason: typ.name,
        );
      }
    });

    test('im Sucher ist „niemand im Bild" dort kein Vorwurf', () {
      // Beim Ganzkoerperfoto ist ein leeres Bild ein Fehler, beim Outfit
      // nicht. Derselbe Hinweis, zwei Saetze.
      const niemand = KoerperHinweis.niemand;

      expect(niemand.text(texte), texte.koerperNiemand);
      expect(
        niemand.text(texte, personOptional: true),
        texte.koerperNiemandFrei,
      );
      expect(texte.koerperNiemandFrei, contains('von Hand'));
    });

    test('alle uebrigen Hinweise bleiben wortgleich', () {
      // Nur „niemand" hat eine zweite Fassung. Wer im Bild steht, bekommt
      // dieselbe Anweisung wie beim Ganzkoerperfoto – die Haltungsregeln
      // sind identisch.
      for (final hinweis in KoerperHinweis.values) {
        if (hinweis == KoerperHinweis.niemand) continue;
        expect(
          hinweis.text(texte, personOptional: true),
          hinweis.text(texte),
          reason: hinweis.name,
        );
      }
    });
  });
}
