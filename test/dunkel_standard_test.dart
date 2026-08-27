import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/storage/key_value_store.dart';
import 'package:trueglow/core/theme/theme_controller.dart';

/// **Der Dunkelmodus ist der Standard** – DECISIONS 66.
///
/// Die App startet dunkel, unabhängig davon, wie das Handy eingestellt ist.
/// Das gilt für neue Nutzer und für alle, die nie selbst gewählt haben; eine
/// getroffene Wahl wird gespeichert und respektiert.
///
/// Der Standard war schon vor diesem Paket `dunkel` — was fehlte, war der
/// Nachweis. Genau den holt diese Datei nach: Ohne Test kann eine Zeile ihn
/// jederzeit still auf „Wie das System" zurückdrehen, und aufgefallen wäre es
/// erst auf einem hell gestellten Handy.
void main() {
  group('Ohne eigene Wahl', () {
    test('ist es dunkel – nicht „wie das System"', () {
      expect(ThemeController.standard, Erscheinungsbild.dunkel);
      expect(ThemeController(MemoryStore()).state, Erscheinungsbild.dunkel);
      expect(
        ThemeController(MemoryStore()).state.modus,
        ThemeMode.dark,
      );
    });

    test('auch bei einem kaputten Eintrag', () {
      // Ein Wert aus einer alten Fassung, ein halb geschriebener Sync: Was
      // sich nicht lesen laesst, faellt auf den Standard – und der ist
      // dunkel, nicht das Geraet.
      for (final muell in <Object?>[null, 42, 'gibtsNicht', '', true]) {
        final speicher = MemoryStore()..put('erscheinungsbild', muell);
        expect(
          ThemeController(speicher).state,
          Erscheinungsbild.dunkel,
          reason: '$muell',
        );
      }
    });
  });

  group('Eine getroffene Wahl gilt', () {
    test('und übersteht den Neustart', () {
      final speicher = MemoryStore();
      ThemeController(speicher).setzen(Erscheinungsbild.hell);

      expect(ThemeController(speicher).state, Erscheinungsbild.hell);
    });

    test('auch „wie das System" – das ist eine bewusste Option', () {
      final speicher = MemoryStore();
      ThemeController(speicher).setzen(Erscheinungsbild.system);

      expect(ThemeController(speicher).state, Erscheinungsbild.system);
      expect(ThemeController(speicher).state.modus, ThemeMode.system);
    });

    test('erst „Alle Daten löschen" bringt den Standard zurück', () {
      final speicher = MemoryStore();
      final ctrl = ThemeController(speicher)..setzen(Erscheinungsbild.hell);

      speicher.clear();
      ctrl.neuLaden();

      expect(ctrl.state, Erscheinungsbild.dunkel);
    });
  });

  group('Alle drei stehen zur Wahl', () {
    test('dunkel, hell und wie das System', () {
      expect(Erscheinungsbild.values, hasLength(3));
      expect(Erscheinungsbild.values, contains(Erscheinungsbild.dunkel));
      expect(Erscheinungsbild.values, contains(Erscheinungsbild.hell));
      expect(Erscheinungsbild.values, contains(Erscheinungsbild.system));
    });

    test('und der Standard steht in der Auswahl an erster Stelle', () {
      // Die Einstellungen zeigen `Erscheinungsbild.values` der Reihe nach.
      // Was voreingestellt ist, soll auch zuerst stehen.
      expect(Erscheinungsbild.values.first, ThemeController.standard);
    });
  });

  group('Auch der allererste Eindruck ist dunkel', () {
    /// Der native Splash gehört Android und folgt normalerweise der
    /// Systemeinstellung. Er ist deshalb in **allen vier** Style-Dateien auf
    /// denselben dunklen Ton festgenagelt — sonst startet ein hell
    /// gestelltes Handy hell und springt beim ersten Flutter-Frame ins
    /// Dunkle.
    const dateien = [
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
      'android/app/src/main/res/values-v31/styles.xml',
      'android/app/src/main/res/values-night-v31/styles.xml',
    ];

    test('der Start-Bildschirm trägt hell wie dunkel denselben Ton', () {
      for (final pfad in dateien) {
        final inhalt = File(pfad).readAsStringSync();
        expect(
          inhalt,
          contains('@color/splashHintergrund'),
          reason: pfad,
        );
      }

      // Und die Farbe selbst hat kein Gegenstueck unter values-night/.
      expect(
        File('android/app/src/main/res/values-night/colors.xml').existsSync(),
        isFalse,
        reason: 'Ein Nacht-Gegenstueck liesse die Startfarbe mit dem System '
            'umspringen',
      );
      expect(
        File('android/app/src/main/res/values/colors.xml')
            .readAsStringSync()
            .toLowerCase(),
        contains('<color name="splashhintergrund">#122c31</color>'),
      );
    });

    test('und die beiden v31-Fassungen nennen dieselbe Zahl', () {
      for (final pfad in [
        'android/app/src/main/res/values-v31/styles.xml',
        'android/app/src/main/res/values-night-v31/styles.xml',
      ]) {
        expect(
          File(pfad).readAsStringSync().toLowerCase(),
          contains('windowsplashscreenbackground">#122c31<'),
          reason: pfad,
        );
      }
    });
  });
}
