import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/l10n/sprache.dart';
import '../../../core/l10n/texte.dart';

/// Erinnerung an einen faelligen Check-in.
///
/// Die Benachrichtigung ist die Kür, nicht die Pflicht: Ob ein Check-in
/// ansteht, entscheidet immer der Zeitplan beim App-Start. Deshalb ist hier
/// alles defensiv – schlaegt das Planen fehl (keine Berechtigung, kein
/// Plugin, Test-Umgebung), laeuft die App unveraendert weiter.
class CheckinBenachrichtigung {
  CheckinBenachrichtigung({
    required this.texte,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Die Texte in der Sprache, die gerade gilt.
  ///
  /// Absichtlich eine Funktion und kein fester Wert: Zwischen dem Bau dieses
  /// Dienstes und dem Planen einer Erinnerung kann der Nutzer die Sprache
  /// umgestellt haben. Gefragt wird deshalb erst, wenn der Text gebraucht
  /// wird.
  final L Function() texte;

  /// Feste ID: Es gibt immer nur eine offene Erinnerung, eine neue ersetzt
  /// die alte.
  static const _id = 1;

  static const _kanalId = 'checkins';

  /// Uhrzeit der Erinnerung am faelligen Tag.
  static const _stunde = 10;

  bool _bereit = false;

  Future<void> initialisieren() async {
    if (_bereit) return;

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Die Nachfrage kommt erst, wenn wirklich etwas zu planen ist.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _bereit = true;
    } catch (e) {
      debugPrint('Benachrichtigungen nicht verfügbar: $e');
    }
  }

  /// Fragt die Berechtigung an – erst beim ersten echten Termin.
  Future<void> berechtigungAnfragen() async {
    await initialisieren();
    if (!_bereit) return;

    try {
      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('Berechtigung für Benachrichtigungen nicht erteilt: $e');
    }
  }

  /// Plant die Erinnerung auf den [termin] um. Null oder ein Termin in der
  /// Vergangenheit loescht die Erinnerung – ein faelliger Check-in wird ueber
  /// die Karte auf der Startseite angeboten, nicht ueber eine Push von
  /// gestern.
  Future<void> planen(DateTime? termin) async {
    await initialisieren();
    if (!_bereit) return;

    await abbrechen();
    if (termin == null) return;

    final zeitpunkt = DateTime(
      termin.year,
      termin.month,
      termin.day,
      _stunde,
    );
    if (!zeitpunkt.isAfter(DateTime.now())) return;

    final t = texte();

    try {
      await _plugin.zonedSchedule(
        id: _id,
        title: t.checkinPushTitel,
        body: '${t.checkinKarteTitel} — ${t.checkinPushText}',
        // Geplant wird der absolute Zeitpunkt. Eine Zeitumstellung dazwischen
        // kann die Uhrzeit um eine Stunde verschieben – fuer eine Erinnerung
        // ohne feste Uhrzeit ist das unerheblich.
        scheduledDate: tz.TZDateTime.from(zeitpunkt, tz.UTC),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _kanalId,
            t.pushKanalName,
            channelDescription: t.pushKanalBeschreibung,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Ungenaue Planung reicht und braucht keine Sonderberechtigung.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Check-in-Erinnerung konnte nicht geplant werden: $e');
    }
  }

  Future<void> abbrechen() async {
    if (!_bereit) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (e) {
      debugPrint('Erinnerung konnte nicht entfernt werden: $e');
    }
  }
}

final checkinBenachrichtigungProvider = Provider<CheckinBenachrichtigung>(
  (ref) => CheckinBenachrichtigung(
    // Die Texte kommen aus der aktiven Sprache. Der Weg ueber `lookupL` statt
    // ueber einen BuildContext ist hier der richtige: Eine Erinnerung wird
    // geplant, wenn ein Check-in abgeschlossen wird – der Screen dahinter ist
    // im Moment der Zustellung laengst weg.
    //
    // Der Name des Benachrichtigungs-Kanals in den Android-Einstellungen
    // bleibt allerdings in der Sprache stehen, in der er angelegt wurde:
    // Android benennt einen bestehenden Kanal nicht um. Ihn bei jedem
    // Sprachwechsel neu anzulegen wuerde die Einstellungen des Nutzers
    // (stumm, Wichtigkeit) verwerfen – das waere der schlechtere Tausch.
    texte: () => lookupL(ref.read(aktiveSpracheProvider).locale),
  ),
);
