import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/cloud/cloud_modell.dart';
import 'package:trueglow/core/netz/wiederholung.dart';
import 'package:trueglow/core/storage/hive_service.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/analysis_service.dart';
import 'package:trueglow/features/analysis/logic/functions_client.dart';
import 'package:trueglow/features/analysis/ui/unterbrochen_karte.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';

import 'hilfen.dart';

/// Kurze Pausen, damit die Tests nicht sekundenlang warten.
const _flott = Duration(milliseconds: 5);

void main() {
  group('Wiederholung', () {
    test('gibt beim ersten Erfolg sofort zurueck', () async {
      var aufrufe = 0;

      final ergebnis = await mitWiederholung(
        () async {
          aufrufe++;
          return 'da';
        },
        wiederholbar: (_) => true,
        grundpause: _flott,
      );

      expect(ergebnis, 'da');
      expect(aufrufe, 1);
    });

    test('versucht es hoechstens dreimal', () async {
      // Die harte Grenze aus der Roadmap: Jeder Versuch kann Kontingent und
      // Tokens kosten.
      var aufrufe = 0;

      await expectLater(
        mitWiederholung(
          () async {
            aufrufe++;
            throw StateError('kaputt');
          },
          wiederholbar: (_) => true,
          grundpause: _flott,
        ),
        throwsA(isA<StateError>()),
      );

      expect(aufrufe, 3);
    });

    test('wiederholt nicht, was nicht wiederholt werden darf', () async {
      var aufrufe = 0;

      await expectLater(
        mitWiederholung(
          () async {
            aufrufe++;
            throw StateError('endgueltig');
          },
          wiederholbar: (_) => false,
          grundpause: _flott,
        ),
        throwsA(isA<StateError>()),
      );

      expect(aufrufe, 1);
    });

    test('die Pause waechst exponentiell', () async {
      final zeiten = <Duration>[];
      final start = Stopwatch()..start();

      await expectLater(
        mitWiederholung(
          () async {
            zeiten.add(start.elapsed);
            throw StateError('kaputt');
          },
          wiederholbar: (_) => true,
          grundpause: const Duration(milliseconds: 60),
        ),
        throwsA(isA<StateError>()),
      );

      expect(zeiten, hasLength(3));
      final ersteLuecke = zeiten[1] - zeiten[0];
      final zweiteLuecke = zeiten[2] - zeiten[1];
      expect(zweiteLuecke, greaterThan(ersteLuecke));
    });

    test('ein Abbruch beendet das Warten', () async {
      final abbruch = Abbruch();
      var aufrufe = 0;

      final laeuft = mitWiederholung(
        () async {
          aufrufe++;
          if (aufrufe == 1) abbruch.ausloesen();
          throw StateError('kaputt');
        },
        wiederholbar: (_) => true,
        abbruch: abbruch,
        grundpause: const Duration(seconds: 5),
      );

      // Ohne Abbruch waere hier fuenf Sekunden Pause.
      await expectLater(laeuft, throwsA(isA<AbbruchException>()));
      expect(aufrufe, 1);
    });

    test('ein Abbruch vor dem ersten Versuch spart ihn ganz', () async {
      var aufrufe = 0;

      await expectLater(
        mitWiederholung(
          () async {
            aufrufe++;
            return 'nie';
          },
          wiederholbar: (_) => true,
          abbruch: Abbruch()..ausloesen(),
          grundpause: _flott,
        ),
        throwsA(isA<AbbruchException>()),
      );

      expect(aufrufe, 0);
    });
  });

  group('Was wiederholt werden darf', () {
    test('nur Fehler, die den Server nicht erreicht haben', () {
      // Sonst zahlt der Nutzer zweimal fuer dieselbe Analyse.
      expect(
        FunctionsClient.darfWiederholtWerden(
          const FunctionsFehler(code: 'unavailable'),
        ),
        isTrue,
      );
      expect(
        FunctionsClient.darfWiederholtWerden(
          const FunctionsFehler(code: 'internal', fall: 'keinInternet'),
        ),
        isTrue,
      );
    });

    test('alles, was Kosten verursacht haben kann, wird nicht wiederholt', () {
      for (final fehler in [
        const FunctionsFehler(code: 'deadline-exceeded'),
        const FunctionsFehler(code: 'resource-exhausted', fall: 'kontingent'),
        const FunctionsFehler(code: 'internal', fall: 'ungueltigeAntwort'),
        const FunctionsFehler(code: 'unauthenticated'),
        const FunctionsFehler(code: 'failed-precondition', fall: 'neuAnmelden'),
      ]) {
        expect(
          FunctionsClient.darfWiederholtWerden(fehler),
          isFalse,
          reason: '${fehler.code}/${fehler.fall}',
        );
      }
    });
  });

  group('Was der Fehler dem Nutzer sagt', () {
    test('ein abgelehnter Zugang ist kein Ausfall des Dienstes', () {
      // Der Anlass steht in DECISIONS 59: Am 27.08.2026 lehnte App Check die
      // Installation ab, und die App meldete „Der Analyse-Dienst antwortet
      // gerade nicht". Das ist das Gegenteil der Wahrheit – der Dienst
      // antwortet sofort und dauerhaft mit Nein.
      expect(
        FunctionsClient.fehlerFuer(
          const FunctionsFehler(code: 'unauthenticated'),
        ),
        AnalysisFehler.zugangAbgelehnt,
      );
      expect(
        FunctionsClient.fehlerFuer(
          const FunctionsFehler(code: 'permission-denied'),
        ),
        AnalysisFehler.zugangAbgelehnt,
      );
    });

    test('und der Text sagt ausdruecklich, dass Warten nicht hilft', () {
      final tipp = AnalysisFehler.zugangAbgelehnt.tipp(texte);

      expect(tipp, contains('Warten'));
      expect(tipp, isNot(contains('später')));
      // Der alte Text ist der, der in die Irre geführt hat.
      expect(
        AnalysisFehler.zugangAbgelehnt.titel(texte),
        isNot(AnalysisFehler.apiFehler.titel(texte)),
      );
    });

    test('der Fall der Function schlaegt den gRPC-Code', () {
      // Ein Server, der seinen Fall ausdruecklich mitschickt, wird ernst
      // genommen – auch wenn der Code etwas anderes nahelegt.
      expect(
        FunctionsClient.fehlerFuer(
          const FunctionsFehler(code: 'unauthenticated', fall: 'kontingent'),
        ),
        AnalysisFehler.kontingent,
      );
    });

    test('alles Unbekannte bleibt der allgemeine API-Fehler', () {
      expect(
        FunctionsClient.fehlerFuer(const FunctionsFehler(code: 'internal')),
        AnalysisFehler.apiFehler,
      );
    });
  });

  group('Unterbrochene Analyse', () {
    KeyValueStore mitMarke() =>
        MemoryStore()..put(CloudModell.keyAnalyseLaeuftSeit, '2026-08-24T10:00:00.000');

    test('erkennt die Marke und raeumt sie sofort weg', () {
      final box = mitMarke();
      final notifier = UnterbrocheneAnalyse(box);

      expect(notifier.state, isTrue);
      expect(box.get(CloudModell.keyAnalyseLaeuftSeit), isNull,
          reason: 'der Hinweis erscheint genau einmal');
    });

    test('ohne Marke passiert nichts', () {
      expect(UnterbrocheneAnalyse(MemoryStore()).state, isFalse);
    });

    testWidgets('ein sauberer Durchlauf hinterlaesst keine Marke',
        (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final container = await appMitDashboard(tester);

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

      expect(container.read(analysisControllerProvider), isA<AnalyseFertig>());
      expect(
        container
            .read(storeProvider(HiveService.boxEinstellungen))
            .get(CloudModell.keyAnalyseLaeuftSeit),
        isNull,
      );
    });
  });
}
