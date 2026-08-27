
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/core/widgets/auswahl_chip.dart';
import 'package:trueglow/features/direction/models/richtung.dart';

import 'hilfen.dart';

/// Das Raster der Stilrichtungs-Chips – DECISIONS 61.
///
/// Der Anlass: Acht Pillen mit unterschiedlich langen Beschriftungen in einem
/// `Wrap` ergaben ein ausgefranstes Bild — zwei in der ersten Zeile, eine in
/// der zweiten, eine einzelne rechts außen. Am Gerät sah das aus wie ein
/// Fehler.
///
/// Was hier geprüft wird, ist die Eigenschaft, die das ausschließt: **alle
/// gleich breit, alle untereinander, keiner schert aus** — auf schmalen
/// Geräten und in beiden Sprachen.
Widget _liste({required Locale sprache, Set<Richtungsziel> aktiv = const {}}) {
  return MaterialApp(
    theme: AppTheme.dark,
    locale: sprache,
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: Builder(
      builder: (context) {
        final texte = context.texte;
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppTheme.gapM),
            children: [
              for (final ziel in Richtungsziel.values) ...[
                AuswahlChip(
                  label: ziel.label(texte),
                  untertext: ziel.untertext(texte),
                  vollBreite: true,
                  aktiv: aktiv.contains(ziel),
                  onTap: () {},
                ),
                const SizedBox(height: AppTheme.gapS),
              ],
            ],
          ),
        );
      },
    ),
  );
}

/// Die Breiten aller Chips auf dem Schirm.
List<double> _breiten(WidgetTester tester) => tester
    .widgetList<AuswahlChip>(find.byType(AuswahlChip))
    .map((c) => tester.getSize(find.byWidget(c)).width)
    .toList();

void main() {
  group('Alle acht stehen im selben Raster', () {
    for (final fall in {'schmal': 320.0, 'normal': 400.0, 'breit': 480.0}
        .entries) {
      testWidgets('bei ${fall.key}en Geräten (${fall.value.toInt()} dp)',
          (tester) async {
        tester.view.physicalSize = Size(fall.value, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_liste(sprache: const Locale('de')));
        await tester.pumpAndSettle();

        final breiten = _breiten(tester);
        expect(breiten, hasLength(Richtungsziel.values.length));

        // Eine Form für alle acht: Kein Chip ist auch nur ein Pixel breiter
        // als ein anderer.
        expect(breiten.toSet(), hasLength(1), reason: '$breiten');

        // Und sie füllen die Spalte, statt sich an ihren Text zu schmiegen.
        expect(breiten.first, closeTo(fall.value - 2 * AppTheme.gapM, 0.5));
      });
    }

    testWidgets('auch auf Englisch – die Texte sind dort länger',
        (tester) async {
      tester.view.physicalSize = const Size(320, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_liste(sprache: const Locale('en')));
      await tester.pumpAndSettle();

      expect(_breiten(tester).toSet(), hasLength(1));
      // Kein Überlauf: Ein „RenderFlex overflowed" käme hier als Exception an.
      expect(tester.takeException(), isNull);
    });

    testWidgets('der Haken ändert die Breite nicht', (tester) async {
      // Der ausgewählte Zustand hat einen dickeren Rahmen. Wenn der die
      // Breite verschöbe, ruckelte die ganze Liste beim Antippen.
      tester.view.physicalSize = const Size(400, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _liste(
          sprache: const Locale('de'),
          aktiv: {Richtungsziel.streetwearLaessig},
        ),
      );
      await tester.pumpAndSettle();

      expect(_breiten(tester).toSet(), hasLength(1));
    });
  });

  group('Jede Zeile trägt beides', () {
    testWidgets('Titel und Untertext, bündig untereinander', (tester) async {
      tester.view.physicalSize = const Size(400, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_liste(sprache: const Locale('de')));
      await tester.pumpAndSettle();

      for (final ziel in Richtungsziel.values) {
        final titel = find.text(ziel.label(texte));
        final unter = find.text(ziel.untertext(texte));

        expect(titel, findsOneWidget, reason: ziel.name);
        expect(unter, findsOneWidget, reason: ziel.name);

        // Bündig: Beide beginnen an derselben Kante.
        expect(
          tester.getTopLeft(titel).dx,
          closeTo(tester.getTopLeft(unter).dx, 0.5),
          reason: ziel.name,
        );
        // Und der Untertext steht darunter, nicht daneben.
        expect(
          tester.getTopLeft(unter).dy,
          greaterThan(tester.getTopLeft(titel).dy),
          reason: ziel.name,
        );
      }
    });

    testWidgets('untereinander, nicht nebeneinander', (tester) async {
      tester.view.physicalSize = const Size(400, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_liste(sprache: const Locale('de')));
      await tester.pumpAndSettle();

      final chips = find.byType(AuswahlChip);
      var vorher = double.negativeInfinity;
      for (var i = 0; i < Richtungsziel.values.length; i += 1) {
        final oben = tester.getTopLeft(chips.at(i));
        // Jeder Chip beginnt tiefer als der vorige und links an derselben
        // Kante – das ist die Definition von „untereinander".
        expect(oben.dy, greaterThan(vorher), reason: 'Chip $i');
        expect(oben.dx, closeTo(AppTheme.gapM, 0.5), reason: 'Chip $i');
        vorher = oben.dy;
      }
    });
  });
}
