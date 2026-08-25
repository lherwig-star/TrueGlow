import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/core/theme/app_colors.dart';
import 'package:trueglow/core/theme/app_theme.dart';
import 'package:trueglow/core/theme/theme_controller.dart';
import 'package:trueglow/core/l10n/texte.dart';
import 'package:trueglow/features/capture/logic/live_face_guide.dart';

/// Die deutschen Texte, gegen die geprueft wird.
final texte = lookupL(const Locale('de'));

/// Bildgroesse eines aufgerichteten Vorschau-Frames im Hochformat.
const _bild = Size(720, 1280);

/// Baut eine Gesichtsbox mit dem gewuenschten Flaechenanteil, mittig oder um
/// [versatzX] / [versatzY] (Anteil der Kantenlaenge) verschoben.
Rect _box(double anteil, {double versatzX = 0, double versatzY = 0}) {
  // Quadratische Box: Seitenlaenge so waehlen, dass die Flaeche stimmt.
  final flaeche = anteil * _bild.width * _bild.height;
  final kante = math.sqrt(flaeche);
  return Rect.fromCenter(
    center: Offset(
      _bild.width * (0.5 + versatzX),
      _bild.height * (0.5 + versatzY),
    ),
    width: kante,
    height: kante,
  );
}

void main() {
  group('LiveFaceGuide', () {
    const guide = LiveFaceGuide();

    test('ohne Gesicht kommt die neutrale Aufforderung', () {
      expect(
        guide.bewerte(gesichter: const [], bildGroesse: _bild),
        LiveHinweis.keinGesicht,
      );
    });

    test('zu kleines Gesicht heisst naeher rangehen', () {
      expect(
        guide.bewerte(gesichter: [_box(0.10)], bildGroesse: _bild),
        LiveHinweis.zuWeitWeg,
      );
    });

    test('zu grosses Gesicht heisst weiter weg', () {
      expect(
        guide.bewerte(gesichter: [_box(0.80)], bildGroesse: _bild),
        LiveHinweis.zuNah,
      );
    });

    test('passende Groesse, aber am Rand heisst mittig positionieren', () {
      expect(
        guide.bewerte(
          gesichter: [_box(0.35, versatzX: 0.30)],
          bildGroesse: _bild,
        ),
        LiveHinweis.nichtMittig,
      );
      expect(
        guide.bewerte(
          gesichter: [_box(0.35, versatzY: 0.30)],
          bildGroesse: _bild,
        ),
        LiveHinweis.nichtMittig,
      );
    });

    test('mittig und in passender Groesse ist bereit', () {
      final hinweis =
          guide.bewerte(gesichter: [_box(0.35)], bildGroesse: _bild);
      expect(hinweis, LiveHinweis.perfekt);
      expect(hinweis.bereit, isTrue);
    });

    test('nur das groesste Gesicht zaehlt', () {
      final hinweis = guide.bewerte(
        gesichter: [_box(0.02, versatzX: 0.4), _box(0.35)],
        bildGroesse: _bild,
      );
      expect(hinweis, LiveHinweis.perfekt);
    });

    test('die Untergrenze liegt ueber dem finalen Qualitaetscheck', () {
      // Der Check in ImageQualityService verlangt 0.25 – was die Vorschau als
      // "perfekt" meldet, muss das sicher bestehen.
      expect(LiveFaceGuide.minAnteil, greaterThan(0.25));
    });

    test('jeder Hinweis hat einen Text, nur perfekt ist bereit', () {
      for (final hinweis in LiveHinweis.values) {
        expect(hinweis.text(texte), isNotEmpty);
        expect(hinweis.bereit, hinweis == LiveHinweis.perfekt);
      }
    });
  });

  group('ThemeController', () {
    test('startet ohne gespeicherten Wert im dunklen Schema', () {
      final ctrl = ThemeController(MemoryStore());
      expect(ctrl.state, Erscheinungsbild.dunkel);
      expect(ctrl.state.modus, ThemeMode.dark);
    });

    test('Auswahl wird gespeichert und wieder geladen', () {
      final speicher = MemoryStore();
      ThemeController(speicher).setzen(Erscheinungsbild.hell);

      // Neuer Controller auf demselben Speicher – wie nach einem Neustart.
      expect(ThemeController(speicher).state, Erscheinungsbild.hell);
    });

    test('System-Auswahl bildet auf ThemeMode.system ab', () {
      final ctrl = ThemeController(MemoryStore())
        ..setzen(Erscheinungsbild.system);
      expect(ctrl.state.modus, ThemeMode.system);
    });

    test('nach dem Loeschen aller Daten steht wieder der Standard', () async {
      final speicher = MemoryStore();
      final ctrl = ThemeController(speicher)..setzen(Erscheinungsbild.hell);

      await speicher.clear();
      ctrl.neuLaden();

      expect(ctrl.state, Erscheinungsbild.dunkel);
    });

    test('kaputter Wert im Speicher faellt auf den Standard zurueck', () {
      final speicher = MemoryStore()..put('erscheinungsbild', 42);
      expect(ThemeController(speicher).state, Erscheinungsbild.dunkel);
    });
  });

  group('Farbschemata', () {
    test('beide Themes liefern die AppColors-Extension', () {
      expect(AppTheme.dark.extension<AppColors>(), AppColors.dunkel);
      expect(AppTheme.light.extension<AppColors>(), AppColors.hell);
    });

    test('Statusbar-Icons kontrastieren zum Schema', () {
      expect(
        AppTheme.overlayStyle(AppColors.dunkel, Brightness.dark)
            .statusBarIconBrightness,
        Brightness.light,
      );
      expect(
        AppTheme.overlayStyle(AppColors.hell, Brightness.light)
            .statusBarIconBrightness,
        Brightness.dark,
      );
    });

    test('Text auf Primaer-Buttons stammt aus derselben Palette', () {
      expect(AppColors.dunkel.aufAkzent, AppColors.dunkel.hintergrund);
      expect(AppColors.hell.aufAkzent, AppColors.hell.hintergrund);
    });
  });
}
