import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/streak/logic/erinnerung_einstellung.dart';
import 'package:trueglow/features/streak/logic/tages_erinnerung.dart';

import 'hilfen.dart';

/// Die tägliche Erinnerung.
///
/// Geprüft wird die Entscheidung, nicht das Plugin: welche Termine anstehen
/// und wann gar keiner. Das ist die Stelle, an der ein Fehler unbemerkt
/// bleibt — eine Erinnerung, die nicht kommt, beschwert sich nicht.
void main() {
  // Ein Dienstag, 8 Uhr morgens. Die Erinnerung um 19 Uhr steht noch bevor.
  final morgens = DateTime(2026, 9, 1, 8);
  // Derselbe Tag um 22 Uhr — 19 Uhr ist vorbei.
  final abends = DateTime(2026, 9, 1, 22);

  List<DateTime> termine({
    Erinnerung einstellung = Erinnerung.standard,
    bool hatPlan = true,
    bool heuteErledigt = false,
    DateTime? jetzt,
  }) =>
      TagesErinnerung.termine(
        einstellung: einstellung,
        hatPlan: hatPlan,
        heuteErledigt: heuteErledigt,
        jetzt: jetzt ?? morgens,
      );

  group('Wann erinnert wird', () {
    test('mit Plan und nichts abgehakt: heute und die nächsten Tage', () {
      final liste = termine();

      expect(liste, hasLength(TagesErinnerung.tage));
      expect(liste.first, DateTime(2026, 9, 1, 19));
      expect(liste.last, DateTime(2026, 9, 7, 19));
    });

    test('heute schon abgehakt: der heutige Termin fällt weg', () {
      final liste = termine(heuteErledigt: true);

      expect(liste, hasLength(TagesErinnerung.tage - 1));
      expect(liste.first, DateTime(2026, 9, 2, 19));
    });

    test('die Uhrzeit ist heute schon vorbei: heute fällt ebenfalls weg', () {
      final liste = termine(jetzt: abends);

      expect(liste.first, DateTime(2026, 9, 2, 19));
    });

    test('ohne Plan gibt es nichts zu erinnern', () {
      expect(termine(hatPlan: false), isEmpty);
    });

    test('ausgeschaltet gibt es nichts', () {
      expect(
        termine(einstellung: Erinnerung.standard.kopie(aktiv: false)),
        isEmpty,
      );
    });

    test('ausgeschaltet schlägt auch alles andere', () {
      expect(
        termine(
          einstellung: Erinnerung.standard.kopie(aktiv: false),
          heuteErledigt: false,
          hatPlan: true,
        ),
        isEmpty,
      );
    });

    test('die eingestellte Uhrzeit gilt für jeden Tag', () {
      final liste = termine(
        einstellung: Erinnerung.standard.kopie(stunde: 21, minute: 15),
      );

      expect(liste.first, DateTime(2026, 9, 1, 21, 15));
      expect(liste[1], DateTime(2026, 9, 2, 21, 15));
      expect(liste.every((t) => t.hour == 21 && t.minute == 15), isTrue);
    });

    test('eine Uhrzeit, die heute schon vorbei ist, beginnt morgen', () {
      // 8 Uhr morgens, Erinnerung auf 7:30 gestellt: Heute war sie schon.
      final liste = termine(
        einstellung: Erinnerung.standard.kopie(stunde: 7, minute: 30),
      );

      expect(liste.first, DateTime(2026, 9, 2, 7, 30));
      expect(liste, hasLength(TagesErinnerung.tage - 1));
    });

    test('künftige Tage stehen ohne Bedingung', () {
      // Abhaken geht nur in der App, und jedes Abhaken plant neu. Wer morgen
      // abhakt, löscht damit den Termin von morgen — deshalb dürfen die
      // künftigen Tage hier unbedingt stehen.
      final liste = termine(heuteErledigt: true);

      expect(liste, contains(DateTime(2026, 9, 2, 19)));
      expect(liste, contains(DateTime(2026, 9, 7, 19)));
    });

    test('über den Monatswechsel hinweg', () {
      final liste = termine(jetzt: DateTime(2026, 9, 28, 8));

      expect(liste.first, DateTime(2026, 9, 28, 19));
      expect(liste.last, DateTime(2026, 10, 4, 19));
    });
  });

  group('Die Einstellung', () {
    test('ist von Anfang an eingeschaltet, 19 Uhr', () {
      final ctrl = ErinnerungController(speicherAttrappe());

      expect(ctrl.state.aktiv, isTrue);
      expect(ctrl.state.stunde, 19);
      expect(ctrl.state.minute, 0);
    });

    test('übersteht einen Neustart', () async {
      final speicher = speicherAttrappe();

      final erste = ErinnerungController(speicher);
      await erste.anAus(false);
      await erste.uhrzeit(7, 45);

      final zweite = ErinnerungController(speicher);
      expect(zweite.state.aktiv, isFalse);
      expect(zweite.state.stunde, 7);
      expect(zweite.state.minute, 45);
    });

    test('unsinnige Werte im Speicher fallen auf den Standard zurück', () async {
      final speicher = speicherAttrappe();
      await speicher.put('erinnerungStunde', 99);
      await speicher.put('erinnerungMinute', -1);

      final ctrl = ErinnerungController(speicher);
      expect(ctrl.state.stunde, 19);
      expect(ctrl.state.minute, 0);
    });

    test('die Frage nach der Berechtigung wird nur einmal gestellt', () async {
      final ctrl = ErinnerungController(speicherAttrappe());

      expect(ctrl.schonGefragt, isFalse);
      await ctrl.alsGefragtMerken();
      expect(ctrl.schonGefragt, isTrue);
    });

    test('nach dem Löschen aller Daten gilt wieder der Standard', () async {
      final speicher = speicherAttrappe();
      final ctrl = ErinnerungController(speicher);
      await ctrl.anAus(false);
      await ctrl.alsGefragtMerken();

      await speicher.clear();
      ctrl.neuLaden();

      expect(ctrl.state.aktiv, isTrue);
      expect(ctrl.schonGefragt, isFalse);
    });
  });

  group('Das Android-Manifest', () {
    // Diese Prüfung ist der Grund, warum die Check-in-Erinnerung monatelang
    // still war: Ohne `ScheduledNotificationReceiver` zeigt Android eine
    // geplante Benachrichtigung überhaupt nicht an. Das Plugin bringt den
    // Eintrag nicht mit — sein eigenes Manifest enthält nur zwei
    // Berechtigungen. Und weil nichts abstürzt, fällt es niemandem auf.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    test('stellt geplante Benachrichtigungen zu', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        ),
      );
    });

    test('legt sie nach einem Neustart des Geräts wieder an', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications'
          '.ScheduledNotificationBootReceiver',
        ),
      );
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
      expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    });

    test('darf Benachrichtigungen überhaupt senden', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    });
  });

  group('Der Text der Benachrichtigung', () {
    test('folgt der App-Sprache', () {
      expect(texte.erinnerungPushText, contains('abgehakt'));
      expect(englischeTexte.erinnerungPushText, contains('ticked'));
      expect(
        englischeTexte.erinnerungPushText,
        isNot(texte.erinnerungPushText),
      );
    });

    test('Titel und Kanalnamen gibt es in beiden Sprachen', () {
      for (final t in [texte, englischeTexte]) {
        expect(t.erinnerungPushTitel, isNotEmpty);
        expect(t.erinnerungKanalName, isNotEmpty);
        expect(t.erinnerungKanalBeschreibung, isNotEmpty);
      }
    });
  });
}
