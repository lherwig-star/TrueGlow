import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/cloud/cloud_dokument.dart';
import 'package:trueglow/core/cloud/cloud_provider.dart';
import 'package:trueglow/core/cloud/cloud_speicher.dart';
import 'package:trueglow/features/analysis/logic/analysis_controller.dart';
import 'package:trueglow/features/analysis/logic/kontingent.dart';
import 'package:trueglow/features/auth/logic/auth_repository.dart';
import 'package:trueglow/features/capture/logic/capture_controller.dart';
import 'package:trueglow/features/capture/models/aufnahme_typ.dart';
import 'package:trueglow/features/capture/models/captured_photo.dart';
import 'package:trueglow/features/home/ui/tabs/analyse_tab.dart';
import 'package:trueglow/features/modules/logic/module_controller.dart';
import 'package:trueglow/features/modules/models/analyse_modul.dart';

import 'hilfen.dart';

/// Zähler schreiben → Anzeige in der App – DECISIONS 95.
///
/// Der Befund vom 01.09.2026: Zwei echte Läufe, zwei Verbrauchszeilen im
/// Server-Protokoll, und in der App stand weiterhin „3 von 3 heute". Der
/// Server zählte richtig; die App las den Stand genau einmal, beim ersten
/// Aufbau der Startseite, und nie wieder.
///
/// Dieser Test hält die Kette zusammen: Was der Server schreibt, muss die
/// App nach einem Lauf auch zeigen.
void main() {
  hiveImTest();

  /// Der Zählerstand, wie ihn die Cloud Function hinterlässt.
  CloudDokument zaehler({required int tag, required int monat}) {
    final heute = DateTime.now();
    final schluessel = '${heute.year.toString().padLeft(4, '0')}-'
        '${heute.month.toString().padLeft(2, '0')}-'
        '${heute.day.toString().padLeft(2, '0')}';

    return CloudDokument(
      pfad: 'kontingent/analyse',
      daten: {
        'tag': schluessel,
        'tagZaehler': tag,
        'monat': schluessel.substring(0, 7),
        'monatZaehler': monat,
      },
      aktualisiertAm: heute.toUtc(),
    );
  }

  late SpeicherAttrappe wolke;

  Future<ProviderContainer> aufsetzen() async {
    wolke = SpeicherAttrappe();
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        cloudSpeicherFabrikProvider.overrideWithValue((uid) => wolke),
      ],
    );
    addTearDown(container.dispose);
    // Der Nutzer kommt aus einem Strom und steht erst nach dem ersten
    // Ereignis fest; ohne ihn gibt es keinen Cloud-Speicher.
    await container.read(nutzerProvider.future);
    // Ohne Einwilligung startet keine Analyse – und dann gaebe es auch
    // nichts nachzulesen.
    einwilligungErteilen(container);
    return container;
  }

  group('Der Stand kommt aus der Wolke', () {
    test('kein Dokument heißt: noch nichts verbraucht', () async {
      final container = await aufsetzen();

      final stand = await container.read(kontingentProvider.future);
      expect(stand?.tagVerbraucht, 0);
      expect(stand?.monatVerbraucht, 0);
    });

    test('und ein geschriebener Zähler wird gelesen', () async {
      final container = await aufsetzen();
      await wolke.schreiben([zaehler(tag: 2, monat: 5)]);

      final stand = await container.read(kontingentProvider.future);
      expect(stand?.tagVerbraucht, 2);
      expect(stand?.monatVerbraucht, 5);
      expect(stand?.tagUebrig, KontingentStand.proTag - 2);
      expect(stand?.monatUebrig, KontingentStand.proMonat - 5);
    });
  });

  group('Nach einem Lauf steht die neue Zahl da', () {
    testWidgets('die Anzeige folgt dem Zähler', (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final container = await aufsetzen();

      // Fotos und Module, damit der Lauf überhaupt startet.
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
      container
          .read(moduleControllerProvider.notifier)
          .vorbereiten({AnalyseModul.basis});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            AnalyseTab(onNeueAnalyse: () {}, onNeuBerechnen: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vorher: noch nichts verbraucht.
      expect(
        find.text(
          texte.kontingentUebrig(
            KontingentStand.proTag,
            KontingentStand.proTag,
          ),
        ),
        findsOneWidget,
      );

      // Der Server zaehlt den Lauf mit – hier die Attrappe an seiner Stelle.
      await wolke.schreiben([zaehler(tag: 1, monat: 1)]);

      // Der Demo-Dienst wartet eine echte Spanne ab; in der Testzeit laeuft
      // die nur unter `runAsync`.
      await tester.runAsync(
        () => container.read(analysisControllerProvider.notifier).starten(),
      );
      await tester.pumpAndSettle();

      // Nachher: eine weniger. Ohne das Nachlesen stand hier stundenlang
      // dieselbe Zahl (DECISIONS 95).
      expect(
        find.text(
          texte.kontingentUebrig(
            KontingentStand.proTag - 1,
            KontingentStand.proTag,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('bei null verbleibenden sperrt die Anzeige den Knopf',
        (tester) async {
      handyGroesse(tester, hoehe: 1600);
      final container = await aufsetzen();
      await wolke.schreiben(
        [zaehler(tag: KontingentStand.proTag, monat: 5)],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testHuelle(
            AnalyseTab(onNeueAnalyse: () {}, onNeuBerechnen: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final knopf = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, texte.homeNeueAnalyse),
      );
      expect(knopf.onPressed, isNull, reason: 'gesperrt');
    });
  });
}
