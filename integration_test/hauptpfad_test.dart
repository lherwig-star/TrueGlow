// Der Hauptpfad auf echter Hardware: Onboarding → Foto → Analyse → Plan →
// Check-in.
//
// Ausfuehren (Geraet oder Emulator angeschlossen):
//
//   flutter test integration_test --dart-define=TRUEGLOW_MOCK=true
//
// **Der Schalter ist Pflicht.** Ohne ihn startet die App gegen Firebase, und
// der Test braeuchte ein Projekt, ein Konto und ein Kontingent. Im
// Demo-Modus laeuft alles lokal: Anmeldung im Arbeitsspeicher, Analyse aus
// der hinterlegten Beispielantwort, keine Kosten.
//
// Was dieser Test gegenueber den Widget-Tests bringt: Er startet `main()` mit
// allem, was dort passiert — echtes Hive auf der Platte, echter Router, echte
// Bildschirmgroesse, echte Schriftgroessen. Genau die Schicht, in der ein
// Ueberlauf oder ein fehlender Plattformkanal auffaellt.
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
import 'package:trueglow/features/checkin/logic/checkin_controller.dart';
import 'package:trueglow/features/checkin/models/checkin.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/history/logic/analysis_repository.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';
import 'package:trueglow/features/plan/logic/plan_progress_repository.dart';
import 'package:trueglow/main.dart' as app;

/// Der Test prueft sichtbare Saetze und legt sich dafuer auf Deutsch fest.
/// Auf welche Sprache das Testgeraet gestellt ist, darf ihn nicht
/// beeinflussen – die App bekommt die Sprache gleich nach dem Start gesetzt.
final texte = lookupL(const Locale('de'));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

/// Der Test prueft sichtbare Saetze und legt sich dafuer auf Deutsch fest.
/// Auf welche Sprache das Testgeraet gestellt ist, darf ihn nicht
/// beeinflussen – die App bekommt die Sprache gleich nach dem Start gesetzt.
  testWidgets('Onboarding, Analyse, Plan und Check-in laufen durch',
      (tester) async {
    expect(
      AnalysisConfig.useMockData,
      isTrue,
      reason: 'Bitte mit --dart-define=TRUEGLOW_MOCK=true starten. '
          'Ohne den Schalter braucht der Test ein Firebase-Projekt.',
    );

    await app.main();
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(app.TrueGlowApp)),
    );

    container.read(sprachControllerProvider.notifier).setzen(Sprache.deutsch);
    await tester.pumpAndSettle();

    // --- Onboarding ---------------------------------------------------
    // Fuenf Seiten, jede mit einer Pflichtangabe. Die Reihenfolge steht in
    // onboarding_screen.dart.
    await _tippe(tester, texte.weiter);
    await _tippe(tester, '25–34');
    await _tippe(tester, 'Mittel');
    await _tippe(tester, texte.weiter);
    await _tippe(tester, '15 Minuten');
    await _tippe(tester, texte.weiter);
    await _tippe(tester, 'Haut');
    await _tippe(tester, texte.weiter);

    // Einwilligungen: Pflicht plus die beiden freiwilligen, die den
    // Analyse-Flow oeffnen.
    for (final art in [
      Einwilligungsart.nutzung,
      Einwilligungsart.mindestalter,
      Einwilligungsart.fotoKi,
    ]) {
      await _hakeAn(tester, art.titel(texte));
    }
    await _tippe(tester, 'Los geht es');

    // --- Anmeldung ------------------------------------------------------
    // Im Demo-Modus legt „Erst ausprobieren" ein Konto im Arbeitsspeicher an.
    await _tippe(tester, 'Erst ausprobieren');
    expect(find.text(texte.homeLeerTitel), findsOneWidget);

    // --- Fotos ----------------------------------------------------------
    // Die einzige Stelle, die nicht ueber die Oberflaeche laeuft: Kamera und
    // Galerie oeffnen einen Systemdialog, den kein Test bedienen kann.
    // Eingesetzt wird derselbe Zustand, den der Aufnahme-Flow erzeugt.
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

    // --- Analyse --------------------------------------------------------
    final laeuft = container.read(analysisControllerProvider.notifier).starten();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await laeuft;
    await tester.pumpAndSettle();

    final analysen = container.read(analysenProvider);
    expect(analysen, hasLength(1));
    expect(analysen.single.istVollstaendig, isTrue);

    // Das erste Abzeichen legt sich als Jubel ueber das Dashboard.
    if (find.text('Weiter so').evaluate().isNotEmpty) {
      await _tippe(tester, 'Weiter so');
    }

    // --- Plan -----------------------------------------------------------
    expect(find.text('Dein Plan'), findsOneWidget);

    final habit = analysen.single.alleHabits.first;
    await tester.tap(find.text(habit).first);
    await tester.pumpAndSettle();

    expect(container.read(planFortschrittProvider).erledigt, contains(habit));

    // --- Check-in -------------------------------------------------------
    // Der Zyklus startet mit dem Plan; faellig ist der erste Check-in nach
    // sieben Tagen. Fuer den Test wird der Termin vorgezogen — die Uhr des
    // Geraets laesst sich nicht stellen.
    final checkins = container.read(checkinControllerProvider.notifier);
    checkins.entwurfSichern(
      Checkin(
        id: 0,
        typ: CheckinTyp.alltag,
        faelligAm: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(checkinControllerProvider).entwurf, isNotNull);
  });
}

/// Tippt auf einen Text und laesst die App zur Ruhe kommen.
///
/// `scrollUntilVisible` waere hier falsch: Auf einem kleinen Geraet liegt das
/// Ziel manchmal ausserhalb, auf einem grossen nie — der Aufruf muss beides
/// vertragen.
Future<void> _tippe(WidgetTester tester, String text) async {
  final ziel = find.text(text);
  await tester.ensureVisible(ziel.first);
  await tester.pumpAndSettle();
  await tester.tap(ziel.first);
  await tester.pumpAndSettle();
}

/// Setzt das Haekchen in der Karte mit dieser Ueberschrift.
Future<void> _hakeAn(WidgetTester tester, String ueberschrift) async {
  final karte = find.ancestor(
    of: find.text(ueberschrift),
    matching: find.byType(InkWell),
  );
  await tester.ensureVisible(karte.first);
  await tester.pumpAndSettle();
  await tester.tap(karte.first);
  await tester.pumpAndSettle();
}
