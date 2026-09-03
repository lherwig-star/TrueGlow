// Nimmt die Bildschirmfotos fuer den App Store auf.
//
// Ausfuehren (Simulator oder Geraet angeschlossen):
//
//   flutter drive \
//     --driver=test_driver/bildschirmfotos_driver.dart \
//     --target=integration_test/bildschirmfotos_test.dart \
//     --dart-define=TRUEGLOW_MOCK=true
//
// **Der Schalter ist Pflicht** — wie beim Hauptpfad-Test. Ohne ihn liefe der
// Durchlauf gegen Firebase, braeuchte ein Konto und wuerde echtes
// Analyse-Kontingent verbrauchen. Im Demo-Modus kommt die Analyse aus der
// hinterlegten Beispielantwort: keine Kosten, keine Tokens, und vor allem
// immer dieselben Zahlen — ein Store-Bild soll sich nicht bei jedem Lauf
// aendern.
//
// Warum dieser Durchlauf den Weg aus hauptpfad_test.dart noch einmal
// enthaelt, statt ihn zu teilen: Der Hauptpfad-Test ist der Nachweis, dass
// die App laeuft, und darf sich nicht aendern, weil ein Bild anders
// aussehen soll. Ein gemeinsamer Unterbau waere hier zwar kuerzer, wuerde
// aber beide Zwecke aneinanderbinden. Der Preis ist bekannt und benannt:
// Aendert sich das Onboarding, sind zwei Dateien nachzuziehen. Beide fallen
// dann laut um, keine still.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trueglow/core/l10n/sprache.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/analysis_service.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/home/logic/home_tab.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/onboarding/models/onboarding_profile.dart';
import 'package:trueglow/features/start/ui/splash_screen.dart';
import 'package:trueglow/main.dart' as app;

final texte = lookupL(const Locale('de'));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bildschirmfotos der vier Haupttabs', (tester) async {
    expect(
      AnalysisConfig.useMockData,
      isTrue,
      reason: 'Bitte mit --dart-define=TRUEGLOW_MOCK=true starten. Ohne den '
          'Schalter verbraucht der Durchlauf echtes Analyse-Kontingent.',
    );

    await app.main();
    await tester.pump(SplashScreen.dauer);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(app.TrueGlowApp)),
    );

    // Store-Bilder werden je Sprache eingereicht; dieser Durchlauf macht die
    // deutschen. Fuer die englischen genuegt es, hier umzustellen.
    container.read(sprachControllerProvider.notifier).setzen(Sprache.deutsch);
    await tester.pumpAndSettle();

    // Erstes Bild, bevor irgendetwas angetippt wird. Es dient nicht dem
    // Store, sondern der Fehlersuche: Bricht der Durchlauf spaeter ab, zeigt
    // es, auf welchem Bildschirm die App tatsaechlich stand.
    await binding.takeScreenshot('00_start');

    // --- bis zum fertigen Plan -------------------------------------------
    await _tippe(tester, texte.loginGast);

    await _tippe(tester, texte.weiter);
    await _tippe(tester, Geschlecht.maennlich.label(texte));
    await _tippe(tester, '25–34');
    await _tippe(tester, 'Mittel');
    await _tippe(tester, texte.weiter);
    await _tippe(tester, '15 Minuten');
    await _tippe(tester, texte.weiter);
    await _tippe(tester, 'Haut');
    await _tippe(tester, texte.weiter);

    for (final art in [
      Einwilligungsart.nutzung,
      Einwilligungsart.mindestalter,
      Einwilligungsart.fotoKi,
    ]) {
      await _hakeAn(tester, art.titel(texte));
    }
    await _tippe(tester, texte.lichtStarten);

    // Kamera und Galerie oeffnen einen Systemdialog, den kein Durchlauf
    // bedienen kann. Eingesetzt wird derselbe Zustand, den der Aufnahme-Flow
    // erzeugt — genau wie im Hauptpfad-Test.
    container.read(captureControllerProvider.notifier).setzeZustand(
          CaptureState(
            fotos: {
              for (final typ in AnalyseModul.basis.aufnahmen)
                typ: CapturedPhoto(
                  typ: typ,
                  pfad: '${typ.name}.jpg',
                  breite: 768,
                  hoehe: 1024,
                  groesseInBytes: 120000,
                ),
            },
          ),
        );

    final laeuft = container.read(analysisControllerProvider.notifier).starten();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await laeuft;
    await tester.pumpAndSettle();

    expect(
      container.read(analysenProvider),
      hasLength(1),
      reason: 'Ohne fertige Analyse zeigen drei der vier Tabs nur Leerzustaende.',
    );

    // Das erste Abzeichen legt sich als Jubel ueber das Dashboard und wuerde
    // sonst auf jedem Bild kleben.
    if (find.text('Weiter so').evaluate().isNotEmpty) {
      await _tippe(tester, 'Weiter so');
    }

    // --- die vier Aufnahmen ----------------------------------------------
    // Ueber den Provider statt ueber die Tab-Leiste: Ein Tipp waere von der
    // Position der Symbole abhaengig, und die verschiebt sich mit der
    // Bildschirmbreite. Die Reihenfolge ist die des Store-Eintrags — das
    // erste Bild ist das, das die meisten Leute als einziges sehen.
    const reihenfolge = <String, HomeTab>{
      '01_analyse': HomeTab.analyse,
      '02_plan': HomeTab.plan,
      '03_heute': HomeTab.heute,
      '04_fortschritt': HomeTab.fortschritt,
    };

    for (final eintrag in reihenfolge.entries) {
      container.read(homeTabProvider.notifier).state = eintrag.value;
      await tester.pumpAndSettle();
      await binding.takeScreenshot(eintrag.key);
    }
  });
}

/// Wartet, bis etwas auf dem Schirm ist - hoechstens [_grenze] lang.
///
/// Warum das noetig ist: `pumpAndSettle` kehrt zurueck, sobald keine
/// Animation mehr laeuft. Eine noch laufende Anmeldung haelt es nicht auf.
/// Auf dem Testgeraet ist die schnell durch, auf einem kalt gestarteten
/// Simulator nicht - dort stand der Anmeldebildschirm noch gar nicht, als
/// der erste Tipp kam, und der Durchlauf brach mit "Bad state: No element"
/// ab (DECISIONS 105).
const _grenze = Duration(seconds: 40);
const _takt = Duration(milliseconds: 250);

Future<void> _warteAuf(WidgetTester tester, Finder ziel, String was) async {
  var gewartet = Duration.zero;
  while (ziel.evaluate().isEmpty) {
    if (gewartet >= _grenze) {
      throw StateError(
        'Nach ${_grenze.inSeconds} Sekunden nicht auf dem Schirm: "$was". '
        'Steht die App noch auf einem anderen Bildschirm? Das Bild '
        '00_start zeigt, womit der Durchlauf begonnen hat.',
      );
    }
    await tester.pump(_takt);
    gewartet += _takt;
  }
  await tester.pumpAndSettle();
}

Future<void> _tippe(WidgetTester tester, String text) async {
  final ziel = find.text(text);
  await _warteAuf(tester, ziel, text);
  await tester.ensureVisible(ziel.first);
  await tester.pumpAndSettle();
  await tester.tap(ziel.first);
  await tester.pumpAndSettle();
}

Future<void> _hakeAn(WidgetTester tester, String ueberschrift) async {
  final karte = find.ancestor(
    of: find.text(ueberschrift),
    matching: find.byType(InkWell),
  );
  await _warteAuf(tester, karte, 'Karte "$ueberschrift"');
  await tester.ensureVisible(karte.first);
  await tester.pumpAndSettle();
  await tester.tap(karte.first);
  await tester.pumpAndSettle();
}
