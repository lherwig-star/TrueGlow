import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/ui/widgets/silhouette_overlay.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/logic/onboarding_controller.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';

import 'hilfen.dart';

/// Der Frauen-Modus: was sich mit der Angabe ändert und was nicht.
void main() {
  group('Ausrichtung', () {
    test('vier Angaben, drei Ausrichtungen', () {
      expect(Geschlecht.maennlich.ausrichtung, Ausrichtung.maennlich);
      expect(Geschlecht.weiblich.ausrichtung, Ausrichtung.weiblich);
      // „Divers" und „keine Angabe" sind verschiedene Aussagen und führen
      // trotzdem zum selben Verhalten: alles bleibt offen.
      expect(Geschlecht.divers.ausrichtung, Ausrichtung.neutral);
      expect(Geschlecht.keineAngabe.ausrichtung, Ausrichtung.neutral);
    });

    test('ohne Angabe bleibt alles, wie es war', () {
      // Der Fall der Bestandsnutzer: Sie haben die Frage nie gestellt
      // bekommen und sollen von dem Update nichts merken.
      const Geschlecht? nieGefragt = null;
      expect(nieGefragt.ausrichtung, Ausrichtung.maennlich);
    });

    test('die Angabe übersteht einen Neustart', () {
      final speicher = MemoryStore();

      OnboardingController(speicher).setGeschlecht(Geschlecht.weiblich);

      expect(
        OnboardingController(speicher).state.geschlecht,
        Geschlecht.weiblich,
      );
    });

    test('jede Angabe hat einen Text in beiden Sprachen', () {
      final englisch = englischeTexte;
      for (final g in Geschlecht.values) {
        expect(g.label(texte), isNotEmpty, reason: g.name);
        expect(g.label(englisch), isNotEmpty, reason: g.name);
      }
    });
  });

  group('Modulangebot', () {
    test('weiblich: Make-up steht vorn, Bart-Empfehlungen entfallen', () {
      final module = AnalyseModul.waehlbareFuer(Ausrichtung.weiblich);

      expect(module.first, AnalyseModul.makeupAusstrahlung);
      // „Bart" ist kein eigenes Modul, sondern ein Abschnitt der Basis. Dass
      // er entfällt, steht im Prompt und zeigt sich hier am Titel.
      expect(
        AnalyseModul.basis.titel(texte, Ausrichtung.weiblich),
        isNot(contains('Bart')),
      );
      // Alle übrigen Module bleiben.
      for (final m in AnalyseModul.waehlbare) {
        if (m == AnalyseModul.makeupAusstrahlung) continue;
        expect(module, contains(m), reason: m.name);
      }
    });

    test('männlich: kein Make-up, Bart bleibt in der Basis', () {
      final module = AnalyseModul.waehlbareFuer(Ausrichtung.maennlich);

      expect(module, isNot(contains(AnalyseModul.makeupAusstrahlung)));
      expect(
        AnalyseModul.basis.titel(texte, Ausrichtung.maennlich),
        contains('Bart'),
      );
    });

    test('neutral: beides steht zur Wahl', () {
      final module = AnalyseModul.waehlbareFuer(Ausrichtung.neutral);

      expect(module, contains(AnalyseModul.makeupAusstrahlung));
      expect(
        AnalyseModul.basis.titel(texte, Ausrichtung.neutral),
        contains('Bart'),
      );
      expect(module.length, AnalyseModul.waehlbare.length);
    });

    test('jedes Modul hat in jeder Ausrichtung vollständige Texte', () {
      for (final ausrichtung in Ausrichtung.values) {
        for (final modul in AnalyseModul.values) {
          expect(modul.titel(texte, ausrichtung), isNotEmpty);
          expect(modul.beschreibung(texte, ausrichtung), isNotEmpty);
          expect(modul.checkliste(texte, ausrichtung), isNotEmpty);
          expect(modul.benoetigt(texte, ausrichtung), isNotEmpty);
        }
      }
    });

    test('Bart fällt im weiblichen Modus aus den Schwerpunkten', () {
      expect(
        Fokusbereich.fuer(Ausrichtung.weiblich),
        isNot(contains(Fokusbereich.bart)),
      );
      expect(
        Fokusbereich.fuer(Ausrichtung.maennlich),
        contains(Fokusbereich.bart),
      );
      expect(
        Fokusbereich.fuer(Ausrichtung.neutral),
        contains(Fokusbereich.bart),
      );
    });
  });

  group('Silhouetten', () {
    const flaechen = <Size>[
      Size(411, 914), // Galaxy A52
      Size(360, 640),
      Size(768, 1024),
    ];

    Rect umriss(Size flaeche, {required bool seitlich, required bool weiblich}) =>
        SilhouetteOverlay.ganzkoerperUmriss(
          flaeche,
          seitlich: seitlich,
          weiblich: weiblich,
        ).getBounds();

    test('nur die Ganzkörper-Umrisse haben eine weibliche Fassung', () {
      // Das Gesichts-Oval bleibt, wie es ist: Gesichtsformen unterscheiden
      // sich zwischen Menschen mehr als zwischen Geschlechtern.
      expect(
        AufnahmeTyp.basisFrontal.overlayFuer(Ausrichtung.weiblich),
        Overlaytyp.gesichtsOval,
      );
      expect(
        AufnahmeTyp.figurGanzkoerperFrontal.overlayFuer(Ausrichtung.weiblich),
        Overlaytyp.ganzkoerperFrontalWeiblich,
      );
      expect(
        AufnahmeTyp.figurGanzkoerperSeitlich.overlayFuer(Ausrichtung.weiblich),
        Overlaytyp.ganzkoerperSeitlichWeiblich,
      );
    });

    test('neutral und männlich bekommen den bestehenden Umriss', () {
      for (final ausrichtung in [
        Ausrichtung.maennlich,
        Ausrichtung.neutral,
      ]) {
        expect(
          AufnahmeTyp.figurGanzkoerperFrontal.overlayFuer(ausrichtung),
          Overlaytyp.ganzkoerperFrontal,
          reason: ausrichtung.name,
        );
        expect(
          AufnahmeTyp.figurGanzkoerperSeitlich.overlayFuer(ausrichtung),
          Overlaytyp.ganzkoerperSeitlich,
          reason: ausrichtung.name,
        );
      }
    });

    for (final seitlich in [false, true]) {
      final name = seitlich ? 'seitlich' : 'frontal';

      test('$name: die weibliche Figur hält dieselben Regeln ein', () {
        for (final flaeche in flaechen) {
          final grenzen = umriss(flaeche, seitlich: seitlich, weiblich: true);
          final schlankheit = grenzen.height / grenzen.width;

          expect(
            schlankheit,
            seitlich ? inInclusiveRange(5, 7.5) : inInclusiveRange(3.5, 5),
            reason: '$flaeche: 1:${schlankheit.toStringAsFixed(1)}',
          );
          expect(grenzen.left, greaterThanOrEqualTo(0), reason: '$flaeche');
          expect(grenzen.right, lessThanOrEqualTo(flaeche.width),
              reason: '$flaeche');
          expect(grenzen.top, greaterThanOrEqualTo(0), reason: '$flaeche');
          expect(grenzen.bottom, lessThanOrEqualTo(flaeche.height * 0.85),
              reason: '$flaeche');
        }
      });

      test('$name: sie steht genauso hoch wie die männliche', () {
        // Beide Figuren sind eine Anweisung, wie weit man zurücktreten soll.
        // Stünden sie verschieden hoch, hieße derselbe Umriss je nach Modus
        // einen anderen Abstand – und der Auto-Auslöser prüft die Höhe.
        for (final flaeche in flaechen) {
          final w = umriss(flaeche, seitlich: seitlich, weiblich: true);
          final m = umriss(flaeche, seitlich: seitlich, weiblich: false);

          expect(w.height, closeTo(m.height, 0.5), reason: '$flaeche');
          expect(w.top, closeTo(m.top, 0.5), reason: '$flaeche');
        }
      });
    }

    test('frontal: Arme und Rumpf berühren sich nicht', () {
      // Der Fehler, den erst ein Blick aufs Gerät gezeigt hat: Die weibliche
      // Hüfte ist breiter als die männliche, und der Arm lag auf derselben
      // Bahn. Auf Hüfthöhe kreuzte er dadurch in den Rumpf – aus Arm und
      // Hüfte wurde ein Knoten.
      //
      // Geprüft wird der Zwischenraum: Von der Mitte nach außen muss der
      // Rumpf enden, lange bevor der äußerste Punkt der Figur erreicht ist.
      // Sind Arm und Rumpf verschmolzen, läuft die Messung durch bis zur
      // Handaußenkante.
      const flaeche = Size(411, 914);

      for (final weiblich in [false, true]) {
        final pfad = SilhouetteOverlay.ganzkoerperUmriss(
          flaeche,
          seitlich: false,
          weiblich: weiblich,
        );
        final grenzen = pfad.getBounds();
        final halbeBreite = grenzen.width / 2;
        final mitte = grenzen.center.dx;

        // Der Bereich, in dem die Arme neben dem Rumpf liegen.
        for (var anteil = 0.28; anteil <= 0.56; anteil += 0.02) {
          final y = grenzen.top + grenzen.height * anteil;
          var x = mitte;
          while (x < grenzen.right && pfad.contains(Offset(x, y))) {
            x += 0.25;
          }

          expect(
            x - mitte,
            lessThan(halbeBreite * 0.8),
            reason: weiblich
                ? 'weiblich, ${(anteil * 100).round()} % der Höhe: Arm und '
                    'Rumpf hängen zusammen'
                : 'männlich, ${(anteil * 100).round()} % der Höhe: Arm und '
                    'Rumpf hängen zusammen',
          );
        }
      }
    });

    test('frontal: schmalere Taille, breitere Hüfte als beim Mann', () {
      // Der eigentliche Unterschied. Gemessen an der Gesamtbreite auf
      // Taillen- und Hüfthöhe.
      const flaeche = Size(411, 914);
      final w = SilhouetteOverlay.ganzkoerperUmriss(
        flaeche,
        seitlich: false,
        weiblich: true,
      );
      final m = SilhouetteOverlay.ganzkoerperUmriss(
        flaeche,
        seitlich: false,
        weiblich: false,
      );

      /// Halbe Breite des Rumpfes auf dieser Höhe.
      ///
      /// Von der Mitte nach außen gelaufen und beim ersten Loch gestoppt:
      /// Auf Taillen- und Hüfthöhe hängen auch die Arme im Bild, und eine
      /// Messung über die ganze Breite würde deren Ausschlag messen statt
      /// den des Rumpfes.
      double rumpfBreiteBei(Path pfad, double anteil) {
        final grenzen = pfad.getBounds();
        final y = grenzen.top + grenzen.height * anteil;
        final mitte = grenzen.center.dx;

        var x = mitte;
        while (x < grenzen.right && pfad.contains(Offset(x, y))) {
          x += 0.25;
        }
        return x - mitte;
      }

      // Taille liegt bei rund 38 % der Figurhöhe, Hüfte bei rund 48 %.
      expect(rumpfBreiteBei(w, 0.38), lessThan(rumpfBreiteBei(m, 0.38)));
      expect(rumpfBreiteBei(w, 0.48), greaterThan(rumpfBreiteBei(m, 0.48)));
    });
  });

  group('Im laufenden Betrieb', () {
    testWidgets('die Modulauswahl folgt der Angabe', (tester) async {
      handyGroesse(tester, hoehe: 2600);
      final container = await appMitDashboard(tester);

      container
          .read(onboardingControllerProvider.notifier)
          .setGeschlecht(Geschlecht.weiblich);
      container.read(routerProvider).go(Routes.module);
      await tester.pumpAndSettle();

      expect(
        find.text(
          AnalyseModul.makeupAusstrahlung.titel(texte, Ausrichtung.weiblich),
        ),
        findsOneWidget,
      );

      container
          .read(onboardingControllerProvider.notifier)
          .setGeschlecht(Geschlecht.maennlich);
      await tester.pumpAndSettle();

      expect(
        find.text(
          AnalyseModul.makeupAusstrahlung.titel(texte, Ausrichtung.maennlich),
        ),
        findsNothing,
      );
    });
  });
}
