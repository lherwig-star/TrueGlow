import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/diagnose/bereinigung.dart';
import 'package:trueglow/core/diagnose/diagnose_dienst.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/analysis_service.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/consent/logic/einwilligung_controller.dart';
import 'package:trueglow/features/consent/models/einwilligung.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';

import 'hilfen.dart';

void main() {
  group('Bereinigung', () {
    test('macht den Dokumentpfad unkenntlich', () {
      // Genau der Restfall aus dem Phase-2-Bericht: Firestore nennt in seinen
      // Ausnahmen den vollstaendigen Pfad, und der enthaelt die uid.
      const roh = 'PERMISSION_DENIED: Missing permissions on '
          'users/aB3xK9mQ7tR2vL5nP8wY1zC4/analysen/1755000000000';

      final sauber = bereinige(roh);

      expect(sauber, contains('users/<uid>'));
      expect(sauber, isNot(contains('aB3xK9mQ7tR2vL5nP8wY1zC4')));
    });

    test('macht E-Mail-Adressen unkenntlich', () {
      final sauber = bereinige('Konto jemand.name+test@example.com gesperrt');

      expect(sauber, 'Konto <email> gesperrt');
    });

    test('macht freistehende lange Kennungen unkenntlich', () {
      final sauber = bereinige('Analyse 1755000000123456 nicht gefunden');

      expect(sauber, 'Analyse <id> nicht gefunden');
    });

    test('laesst gewoehnliche Woerter in Ruhe', () {
      // Der Waechter darf den Fehlertext nicht unlesbar machen – sonst ist
      // der Absturzbericht nichts mehr wert.
      const roh = 'Zeitueberschreitung beim Aufruf der Cloud Function '
          'analysiere in Region europe-west3';

      expect(bereinige(roh), roh);
    });

    test('behaelt den Fehlertyp fuer die Gruppierung', () {
      final bereinigt = BereinigterFehler.aus(
        StateError('users/aB3xK9mQ7tR2vL5nP8wY1zC4 fehlt'),
      );

      expect(bereinigt.typ, 'StateError');
      expect(bereinigt.toString(), startsWith('StateError: '));
      expect(bereinigt.toString(), contains('users/<uid>'));
    });
  });

  group('Erfassung nur mit Einwilligung', () {
    test('ohne Einwilligung wird nichts gemeldet', () async {
      final dienst = DiagnoseOhneBackend();

      await dienst.melde(DiagnoseEreignis.analyseGestartet);
      await dienst.fehler(StateError('kaputt'), StackTrace.current);

      expect(dienst.ereignisse, isEmpty);
      expect(dienst.fehlerliste, isEmpty);
    });

    test('mit Einwilligung schon', () async {
      final dienst = DiagnoseOhneBackend();
      await dienst.erfassungErlauben(true);

      await dienst.melde(DiagnoseEreignis.analyseGestartet);
      await dienst.fehler(StateError('kaputt'), StackTrace.current);

      expect(dienst.ereignisse, [DiagnoseEreignis.analyseGestartet]);
      expect(dienst.fehlerliste, hasLength(1));
    });

    test('ein gemeldeter Fehler ist bereinigt', () async {
      final dienst = DiagnoseOhneBackend();
      await dienst.erfassungErlauben(true);

      await dienst.fehler(
        StateError('users/aB3xK9mQ7tR2vL5nP8wY1zC4 fehlt'),
        StackTrace.current,
      );

      expect(
        dienst.fehlerliste.single.toString(),
        isNot(contains('aB3xK9mQ7tR2vL5nP8wY1zC4')),
      );
    });
  });

  group('Ereignisliste', () {
    test('deckt den Funnel der Roadmap ab', () {
      // Onboarding → Analyse → Plan → Check-in.
      expect(DiagnoseEreignis.values.map((e) => e.name), containsAll([
        'onboarding_abgeschlossen',
        'analyse_gestartet',
        'plan_geoeffnet',
        'checkin_abgeschlossen',
      ]));
    });

    test('jeder Name ist ein zulaessiger Analytics-Name', () {
      // Firebase erlaubt Kleinbuchstaben, Ziffern und Unterstriche, hoechstens
      // 40 Zeichen, beginnend mit einem Buchstaben.
      final muster = RegExp(r'^[a-z][a-z0-9_]{0,39}$');
      for (final ereignis in DiagnoseEreignis.values) {
        expect(muster.hasMatch(ereignis.name), isTrue, reason: ereignis.name);
      }
    });
  });

  group('Im Zusammenspiel', () {
    testWidgets('der Funnel meldet Start und Abschluss einer Analyse',
        (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final dienst = DiagnoseOhneBackend();

      final container = await appMitDashboard(
        tester,
        zusatz: [diagnoseDienstProvider.overrideWithValue(dienst)],
      );
      container.read(einwilligungControllerProvider.notifier).setzen(
            Einwilligungsart.diagnose,
            erteilt: true,
            kanal: Einwilligungskanal.einstellungen,
          );
      await dienst.erfassungErlauben(true);

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

      final laeuft =
          container.read(analysisControllerProvider.notifier).starten();
      await tester.pump(AnalysisConfig.mockDauer);
      await laeuft;

      expect(dienst.ereignisse, [
        DiagnoseEreignis.analyseGestartet,
        DiagnoseEreignis.analyseFertig,
      ]);
    });

    testWidgets('ohne Einwilligung meldet derselbe Ablauf nichts',
        (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final dienst = DiagnoseOhneBackend();

      final container = await appMitDashboard(
        tester,
        zusatz: [diagnoseDienstProvider.overrideWithValue(dienst)],
      );

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

      final laeuft =
          container.read(analysisControllerProvider.notifier).starten();
      await tester.pump(AnalysisConfig.mockDauer);
      await laeuft;

      expect(dienst.ereignisse, isEmpty);
    });
  });
}
