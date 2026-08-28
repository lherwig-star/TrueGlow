import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/features/capture/logic/auto_ausloeser.dart';
import 'package:trueglow/features/capture/logic/live_face_guide.dart';
import 'package:trueglow/features/capture/logic/live_koerper_guide.dart';
import 'package:trueglow/features/capture/logic/signalton.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';

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
    // Ohne Stabilisierung, weil es hier um den Countdown geht: Die Sekunde
    // Ruhe davor hat ihre eigene Gruppe. Ein Test, der beides zugleich
    // prueft, sagt bei einem Fehlschlag nicht, welches der beiden kaputt ist.
    test('zaehlt bei guter Haltung von 3 herunter und loest aus', () {
      final ausloeser = AutoAusloeser(stabil: Duration.zero);

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
      final ausloeser = AutoAusloeser(stabil: Duration.zero);
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
      final ausloeser = AutoAusloeser(stabil: Duration.zero);

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
      final ausloeser = AutoAusloeser(stabil: Duration.zero);

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
      final ausloeser = AutoAusloeser(stabil: Duration.zero);

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
      final ausloeser = AutoAusloeser(stabil: Duration.zero);

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
      final ausloeser = AutoAusloeser(stabil: Duration.zero);

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
      final ausloeser = AutoAusloeser(stabil: Duration.zero);

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

  group('Die Sekunde Ruhe vor dem Countdown', () {
    // Seit die Bedingung positionsunabhaengig ist (DECISIONS 74), ist sie
    // leichter zu erfuellen – auch versehentlich, waehrend man das Handy
    // noch hinstellt.

    test('der Countdown faengt erst nach der Stabilisierung an', () {
      final ausloeser = AutoAusloeser();

      // Erst mal passiert nichts Sichtbares.
      expect(
        ausloeser.melde(bereit: true, jetzt: t0),
        const AutoZustand(AutoPhase.warten),
      );
      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 900)),
        ),
        const AutoZustand(AutoPhase.warten),
      );

      // Nach einer Sekunde geht es los – mit vollen drei Sekunden.
      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 1000)),
        ),
        const AutoZustand(AutoPhase.zaehlt, 3),
      );
    });

    test('wer sich zwischendurch wegdreht, faengt von vorn an', () {
      final ausloeser = AutoAusloeser();

      ausloeser.melde(bereit: true, jetzt: t0);
      // Laenger weg als die Nachsicht: Die halbe Sekunde ist verfallen.
      ausloeser.melde(
        bereit: false,
        jetzt: t0.add(const Duration(milliseconds: 500)),
      );
      ausloeser.melde(
        bereit: false,
        jetzt: t0.add(const Duration(milliseconds: 1400)),
      );

      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 1500)),
        ),
        const AutoZustand(AutoPhase.warten),
      );
      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 2600)),
        ),
        const AutoZustand(AutoPhase.zaehlt, 3),
      );
    });

    test('ein einzelner Aussetzer wirft sie nicht zurueck', () {
      // Sonst faengt die Sekunde bei jedem Flackern der Posenerkennung von
      // vorn an und kommt nie zusammen – derselbe Fehler wie beim Countdown
      // vor DECISIONS 51.
      final ausloeser = AutoAusloeser();

      ausloeser.melde(bereit: true, jetzt: t0);
      ausloeser.melde(
        bereit: false,
        jetzt: t0.add(const Duration(milliseconds: 400)),
      );

      expect(
        ausloeser.melde(
          bereit: true,
          jetzt: t0.add(const Duration(milliseconds: 1050)),
        ),
        const AutoZustand(AutoPhase.zaehlt, 3),
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
      double mitteY = 0.5,
      bool kopf = true,
      bool fuesse = true,
    }) {
      final hoehe = bild.height * hoeheAnteil;
      return Koerperlage(
        umriss: Rect.fromCenter(
          center: Offset(bild.width * mitteX, bild.height * mitteY),
          width: bild.width * 0.25,
          height: hoehe,
        ),
        kopfSichtbar: kopf,
        fuesseSichtbar: fuesse,
      );
    }

    test('vollstaendig im Bild ist bereit', () {
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

    test('seitlich versetzt loest trotzdem aus', () {
      // Das war der zweite Grund, aus dem der Ausloeser vor dem Spiegel nie
      // ansprang: Dort steht man neben dem Handy, nicht dahinter
      // (DECISIONS 74). Wo im Bild jemand steht, ist jetzt egal.
      for (final x in [0.15, 0.5, 0.85]) {
        expect(
          guide.bewerte(lage: lage(mitteX: x), bildGroesse: bild),
          KoerperHinweis.bereit,
          reason: 'Mitte bei $x',
        );
      }
    });

    test('aber oben oder unten angeschnitten nicht', () {
      // Der Rand ist das, was von der alten Obergrenze uebrig ist: ML Kit
      // erkennt Nase und Knoechel, nicht Scheitel und Zehen. Wer mit dem
      // Knoechel auf der Bildkante steht, hat die Fuesse abgeschnitten.
      expect(
        guide.bewerte(
          lage: lage(hoeheAnteil: 0.9, mitteY: 0.1),
          bildGroesse: bild,
        ),
        KoerperHinweis.zuNah,
      );
      expect(
        guide.bewerte(
          lage: lage(hoeheAnteil: 0.9, mitteY: 0.9),
          bildGroesse: bild,
        ),
        KoerperHinweis.zuNah,
      );
    });

    test('die halbe Bildhoehe reicht', () {
      // Von 0,55 auf 0,50 gesenkt: Die fehlenden fuenf Prozent waren der
      // Unterschied zwischen "loest aus" und "loest nie aus".
      expect(
        guide.bewerte(
          lage: lage(hoeheAnteil: LiveKoerperGuide.minHoehe + 0.01),
          bildGroesse: bild,
        ),
        KoerperHinweis.bereit,
      );
      expect(LiveKoerperGuide.minHoehe, lessThanOrEqualTo(0.5));
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

  group('Der Auto-Ausloeser spricht bei den Outfit-Fotos anders', () {
    test('beide Erklaerungen nennen keinen Umriss', () {
      // Es gibt keinen mehr (DECISIONS 74). Die Texte bleiben trotzdem zwei:
      // Beim Outfit steht dazu, was passiert, wenn es ausgelegt ist.
      final koerper =
          AufnahmeTyp.figurGanzkoerperFrontal.autoHinweis(texte);
      final outfit = AufnahmeTyp.stilOutfitEins.autoHinweis(texte);

      // Seit DECISIONS 74 gibt es bei beiden keinen Umriss mehr.
      expect(koerper, isNot(contains('Umriss')));
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
