import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trueglow/features/checkin/logic/fortschritts_album.dart';
import 'package:trueglow/features/checkin/models/checkin.dart';

/// Die Fortschritts-Fotos.
///
/// Das Versprechen lautet: **gespeichert** wird nur auf diesem Gerät. Zur
/// Auswertung dürfen die Bilder an das Modell — dort bleibt keins liegen,
/// genau wie bei der Erst-Analyse (DECISIONS 48).
///
/// Der stille Teil davon steht unten: die Backup-Ausschlüsse im Manifest.
/// Ohne sie wandern die Bilder über Googles automatisches Backup in die
/// Cloud, und niemand merkt es, weil nichts abstürzt.
void main() {
  group('Das Foto wird bei jedem Check-in angeboten', () {
    test('nicht mehr nur beim Wirkungs-Check', () {
      // Ein Tagebuch mit einem Eintrag alle dreißig Tage ist keins.
      for (final typ in CheckinTyp.values) {
        expect(typ.mitFortschrittsfoto, isTrue, reason: typ.name);
      }
    });

    test('das Zwischenfazit hängt weiterhin nur am Wirkungs-Check', () {
      // `mitFortschrittsfoto` taugt seitdem nicht mehr als Bedingung dafür,
      // ob Fotos mitgehen – es ist überall wahr. Maßgeblich ist der Typ.
      expect(CheckinTyp.alltag.fragtNachWirkung, isFalse);
      expect(CheckinTyp.zwischen.fragtNachWirkung, isTrue);
      expect(CheckinTyp.wirkung.fragtNachWirkung, isTrue);

      // Und nur der Wirkungs-Check schickt Fotos zur Auswertung mit.
      expect(CheckinTyp.alltag.fotosZurAuswertung, isFalse);
      expect(CheckinTyp.zwischen.fotosZurAuswertung, isFalse);
      expect(CheckinTyp.wirkung.fotosZurAuswertung, isTrue);
    });
  });

  group('Ein Eintrag im Album', () {
    test('das Startfoto lässt sich nicht löschen', () {
      // Es gehört zur Analyse, nicht zum Tagebuch.
      final start = Fotoeintrag(pfad: '/x/start.jpg', datum: _egal);
      final spaeter =
          Fotoeintrag(pfad: '/x/c1.jpg', datum: _egal, checkinId: 1);

      expect(start.istStart, isTrue);
      expect(spaeter.istStart, isFalse);
    });

    test('meldet eine fehlende Datei, statt sie zu zeigen', () {
      // Nach einem Gerätewechsel steht der Check-in noch da (er kommt aus
      // der Cloud), das Bild nicht.
      final fehlt = Fotoeintrag(
        pfad: '/gibt/es/nicht.jpg',
        datum: _egal,
        checkinId: 1,
      );

      expect(fehlt.vorhanden, isFalse);
    });

    test('erkennt eine vorhandene Datei', () async {
      final datei = File(
        '${Directory.systemTemp.path}/trueglow_foto_test.jpg',
      )..writeAsBytesSync([0]);
      addTearDown(() => datei.existsSync() ? datei.deleteSync() : null);

      final eintrag = Fotoeintrag(pfad: datei.path, datum: _egal, checkinId: 1);

      expect(eintrag.vorhanden, isTrue);
    });
  });

  group('Der Check-in vergisst sein Foto auf Wunsch', () {
    test('ohneFortschrittsfoto lässt die Antworten stehen', () {
      final checkin = Checkin(
        id: 1,
        typ: CheckinTyp.wirkung,
        faelligAm: DateTime(2026, 9, 1),
        erledigtAm: DateTime(2026, 9, 1),
        habits: const [
          HabitFeedback(habit: 'Haare stylen', bewertung: HabitBewertung.laeuftGut),
        ],
        fortschrittsfoto: '/x/c1.jpg',
      );

      final ohne = checkin.ohneFortschrittsfoto();

      expect(ohne.fortschrittsfoto, isNull);
      expect(ohne.habits, hasLength(1));
      expect(ohne.id, checkin.id);
      expect(ohne.erledigtAm, checkin.erledigtAm);
    });
  });

  group('Android holt die Fotos nicht ab', () {
    // Das ist die Zusicherung, die sonst niemand prüft: Ohne diese Einträge
    // wandern die Bilder unbemerkt über Googles automatisches Backup in die
    // Cloud – und niemand merkt es, weil nichts abstürzt.
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final regeln =
        File('android/app/src/main/res/xml/datenausnahmen.xml').readAsStringSync();

    test('das alte Backup ist abgeschaltet', () {
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
    });

    test('die neuen Regeln sind eingehängt', () {
      expect(manifest, contains('android:dataExtractionRules="@xml/datenausnahmen"'));
    });

    test('Cloud-Backup und Gerätewechsel nehmen nichts mit', () {
      for (final block in ['cloud-backup', 'device-transfer']) {
        final anfang = regeln.indexOf('<$block>');
        final ende = regeln.indexOf('</$block>');
        expect(anfang, greaterThanOrEqualTo(0), reason: block);

        final inhalt = regeln.substring(anfang, ende);
        for (final bereich in ['root', 'file', 'database', 'sharedpref']) {
          expect(
            inhalt,
            contains('<exclude domain="$bereich" />'),
            reason: '$block: $bereich',
          );
        }
      }
    });
  });
}

final _egal = DateTime(2026, 8, 26);
