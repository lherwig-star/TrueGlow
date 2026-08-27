import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/core/theme/app_colors.dart';

/// **Der Dunkelmodus wird nicht angefasst.**
///
/// Das ist keine Bitte, sondern die Bedingung, unter der der helle Modus
/// überarbeitet wurde (DECISIONS 62): Der dunkle gefällt genau so, wie er
/// ist. Jede Farbe steht hier als Zahl — nicht als Verweis auf
/// `AppColors.dunkel`, denn dann prüfte sich der Test an sich selbst und
/// ginge jede Änderung stillschweigend mit.
///
/// Schlägt dieser Test fehl, ist die Frage nicht „welcher Wert ist jetzt
/// richtig?", sondern „warum wurde er überhaupt angefasst?".
void main() {
  group('Der Dunkelmodus ist eingefroren', () {
    /// Die Ist-Werte vom 27.08.2026, von Hand abgeschrieben.
    const eingefroren = <String, int>{
      'hintergrund': 0xFF173C3B,
      'hintergrundTief': 0xFF0C1C26,
      'flaeche': 0xFF295654,
      'flaecheHoch': 0xFF1E4746,
      'rand': 0xFF3C6F6C,
      'akzent': 0xFFD8C6AA,
      'aufAkzent': 0xFF173C3B,
      'akzentZwei': 0xFFC7B18C,
      'textPrimaer': 0xFFF2EEE6,
      'textSekundaer': 0xFFBCCCC8,
      'warnung': 0xFFEFB79E,
      'erfolg': 0xFFC7B18C,
      'erreicht': 0xFFE8BE6E,
      'kartenrand': 0x1AF2EEE6,
    };

    /// Dieselben Rollen, aus dem Schema gelesen.
    Map<String, Color> istWerte() {
      const f = AppColors.dunkel;
      return {
        'hintergrund': f.hintergrund,
        'hintergrundTief': f.hintergrundTief,
        'flaeche': f.flaeche,
        'flaecheHoch': f.flaecheHoch,
        'rand': f.rand,
        'akzent': f.akzent,
        'aufAkzent': f.aufAkzent,
        'akzentZwei': f.akzentZwei,
        'textPrimaer': f.textPrimaer,
        'textSekundaer': f.textSekundaer,
        'warnung': f.warnung,
        'erfolg': f.erfolg,
        'erreicht': f.erreicht,
        'kartenrand': f.kartenrand,
      };
    }

    test('jede einzelne Farbe steht noch auf ihrem Wert', () {
      final ist = istWerte();

      for (final rolle in eingefroren.entries) {
        expect(
          ist[rolle.key]?.toARGB32(),
          rolle.value,
          reason: 'Dunkelmodus: ${rolle.key} wurde geändert',
        );
      }
    });

    test('und keine Rolle ist verschwunden', () {
      expect(istWerte().keys.toSet(), eingefroren.keys.toSet());
    });

    test('neue Rollen ändern am Dunkelmodus nichts', () {
      // Die Trennung in Text-Gold und Flächen-Gold (DECISIONS 62) ist eine
      // Struktur-Änderung, die beide Modi berührt. Im Dunkelmodus bleibt
      // sie folgenlos, weil beide Rollen denselben Wert tragen wie zuvor —
      // gerendert wird Pixel für Pixel dasselbe.
      expect(AppColors.dunkel.erreichtFlaeche.toARGB32(), 0xFFE8BE6E);
      expect(AppColors.dunkel.aufErreicht.toARGB32(), 0xFF173C3B);

      expect(AppColors.dunkel.erreichtFlaeche, AppColors.dunkel.erreicht);
      expect(AppColors.dunkel.aufErreicht, AppColors.dunkel.aufAkzent);
    });

    test('und die Toenungen tragen die zuvor gerechneten Werte', () {
      // `erreichtLeer` und `erreichtChip` standen bis DECISIONS 63 als
      // Rechnung im Widget: `textSekundaer` bei 18 % und `erreicht` bei
      // 14 %. Als Rolle tragen sie exakt dieselben Zahlen – sonst waere aus
      // einer Aufraeumaktion eine Aenderung am Dunkelmodus geworden.
      // Verglichen wird der gerenderte 32-Bit-Wert, nicht die
      // Fliesskomma-Darstellung: `withValues(alpha: 0.18)` haelt 0,1800,
      // die Konstante 0x2E ergibt 0,1804 – auf dem Schirm dasselbe Pixel.
      expect(
        AppColors.dunkel.erreichtLeer.toARGB32(),
        AppColors.dunkel.textSekundaer.withValues(alpha: 0.18).toARGB32(),
      );
      expect(
        AppColors.dunkel.erreichtChip.toARGB32(),
        AppColors.dunkel.erreicht.withValues(alpha: 0.14).toARGB32(),
      );
    });

    test('auch die abgeleitete Startfläche bleibt, was sie war', () {
      // Sie steht in `styles.xml` als fester Hex-Wert und im nativen Splash
      // (DECISIONS 53). Verschöbe sie sich, blitzte der Start wieder auf.
      expect(AppColors.dunkel.startFlaeche.toARGB32(), 0xFF122C31);
    });
  });

  group('Die beiden Schemata bleiben zwei Schemata', () {
    test('keine Rolle trägt in beiden denselben Wert', () {
      // Ein hell wie dunkel identischer Ton wäre entweder ein
      // Copy-Paste-Unfall oder eine Farbe, die einen der beiden Modi nicht
      // ernst nimmt.
      const hell = AppColors.hell;
      const dunkel = AppColors.dunkel;

      final paare = <String, List<Color>>{
        'hintergrund': [hell.hintergrund, dunkel.hintergrund],
        'flaeche': [hell.flaeche, dunkel.flaeche],
        'akzent': [hell.akzent, dunkel.akzent],
        'textPrimaer': [hell.textPrimaer, dunkel.textPrimaer],
        'erreicht': [hell.erreicht, dunkel.erreicht],
        'erreichtFlaeche': [hell.erreichtFlaeche, dunkel.erreichtFlaeche],
      };

      for (final paar in paare.entries) {
        expect(
          paar.value.first,
          isNot(paar.value.last),
          reason: paar.key,
        );
      }
    });

    test('aber sie tragen dieselben Rollen', () {
      // Gleiche Rolle, gleicher Einsatzort — das ist die Zusage des hellen
      // Geschwisters. Der Compiler hält sie: Beide entstehen aus demselben
      // Konstruktor, keine Rolle darf fehlen.
      const hell = AppColors.hell;
      expect(hell.erreichtFlaeche, isNotNull);
      expect(hell.aufErreicht, isNotNull);
    });
  });
}
