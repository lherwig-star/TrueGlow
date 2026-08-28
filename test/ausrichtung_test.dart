
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/core/router/app_router.dart';
import 'package:trueglow/features/analysis/logic/analyse_anfrage.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/modules/models/modul_eingaben.dart';
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

  group('Was die Analyse-Anfrage mitnimmt', () {
    Map<String, dynamic> anfrage({
      Geschlecht? geschlecht,
      Set<AnalyseModul> module = const {AnalyseModul.basis},
      Sprache sprache = Sprache.deutsch,
    }) =>
        AnalyseAnfrage.bauen(
          bilder: const {AufnahmeTyp.basisFrontal: 'AAAA'},
          module: module,
          onboarding: OnboardingProfile(geschlecht: geschlecht),
          eingaben: const ModulEingaben(),
          sprache: sprache,
        );

    test('die Ausrichtung, nicht die Angabe', () {
      // Ob jemand „divers" oder „keine Angabe" gewählt hat, bleibt auf dem
      // Gerät. Der Prompt braucht die Entscheidung, nicht ihre Herkunft.
      expect(anfrage(geschlecht: Geschlecht.weiblich)['ausrichtung'],
          'weiblich');
      expect(anfrage(geschlecht: Geschlecht.maennlich)['ausrichtung'],
          'maennlich');
      expect(anfrage(geschlecht: Geschlecht.divers)['ausrichtung'], 'neutral');
      expect(anfrage(geschlecht: Geschlecht.keineAngabe)['ausrichtung'],
          'neutral');
      expect(anfrage()['ausrichtung'], 'maennlich');
    });

    test('genau die gewählten Module, in fester Reihenfolge', () {
      // Am Gerät kam ein Report mit einem einzigen Kapitel zurück, obwohl
      // zwei Module gewählt waren. Die Ursache lag auf dem Server – aber
      // dass die Auswahl das Gerät vollständig verlässt, gehört geprüft.
      final gewaehlt = anfrage(
        geschlecht: Geschlecht.weiblich,
        module: {AnalyseModul.makeupAusstrahlung, AnalyseModul.basis},
      );

      expect(gewaehlt['module'], ['basis', 'makeupAusstrahlung']);
    });

    test('Sprache und Ausrichtung stehen nebeneinander', () {
      final englischWeiblich = anfrage(
        geschlecht: Geschlecht.weiblich,
        sprache: Sprache.englisch,
      );

      expect(englischWeiblich['sprache'], 'en');
      expect(englischWeiblich['ausrichtung'], 'weiblich');
    });
  });
}
