import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/l10n/sprache.dart';
import '../../../core/l10n/texte.dart';
import 'erinnerung_einstellung.dart';

/// Die tägliche Erinnerung ans Abhaken.
///
/// Eine lokale Benachrichtigung, kein Server. Wie bei der
/// Check-in-Erinnerung gilt: Sie ist die Kür, nicht die Pflicht. Schlägt das
/// Planen fehl – keine Berechtigung, kein Plugin, Testumgebung –, läuft die
/// App unverändert weiter.
///
/// **Warum mehrere Termine auf einmal geplant werden.** Eine lokale
/// Benachrichtigung kann beim Auslösen nichts prüfen; das Gerät zeigt nur an,
/// was vorher hinterlegt wurde. Ein einziger Termin hieße: Er feuert einmal,
/// und danach ist Ruhe, bis jemand die App wieder öffnet – ausgerechnet bei
/// dem, den die Erinnerung zurückholen soll.
///
/// Deshalb liegen [tage] Termine im Voraus. Der heutige nur dann, wenn heute
/// noch nichts abgehakt ist; die künftigen ohne Bedingung. Das ist kein
/// Kompromiss, sondern richtig: Abhaken geht nur in der App, und jedes
/// Abhaken plant neu. Wer morgen abhakt, löscht damit den Termin von morgen.
class TagesErinnerung {
  TagesErinnerung({
    required this.texte,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Die Texte in der Sprache, die gerade gilt – aus demselben Grund eine
  /// Funktion wie bei der Check-in-Erinnerung: Zwischen dem Planen und dem
  /// Zustellen kann die Sprache gewechselt haben.
  final L Function() texte;

  /// So viele Tage im Voraus.
  static const tage = 7;

  /// Eigener Nummernkreis, damit sich die Termine nicht mit der
  /// Check-in-Erinnerung (ID 1) ins Gehege kommen.
  static const _ersteId = 100;

  static const _kanalId = 'tagesziel';

  bool _bereit = false;

  Future<void> initialisieren() async {
    if (_bereit) return;

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _bereit = true;
    } catch (e) {
      debugPrint('Tageserinnerung nicht verfügbar: $e');
    }
  }

  /// Fragt die Systemberechtigung an und sagt, ob sie erteilt wurde.
  ///
  /// Ab Android 13 verlangt das System diese Zustimmung ausdrücklich; davor
  /// gilt sie als erteilt. `null` vom Plugin heißt „keine Angabe" – das wird
  /// als erteilt gewertet, sonst bliebe die Funktion auf älteren Geräten
  /// stumm, auf denen es gar nichts zu fragen gibt.
  Future<bool> berechtigungAnfragen() async {
    await initialisieren();
    if (!_bereit) return false;

    try {
      if (Platform.isAndroid) {
        final erteilt = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return erteilt ?? true;
      }
      if (Platform.isIOS) {
        final erteilt = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return erteilt ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('Berechtigung für die Tageserinnerung nicht erteilt: $e');
      return false;
    }
  }

  /// Ob das System Benachrichtigungen gerade zulässt.
  Future<bool> berechtigungVorhanden() async {
    await initialisieren();
    if (!_bereit) return false;

    try {
      if (Platform.isAndroid) {
        final erlaubt = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return erlaubt ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('Status der Benachrichtigungen nicht lesbar: $e');
      return false;
    }
  }

  /// Welche Termine anstehen – die ganze Entscheidung, ohne Plugin.
  ///
  /// Steht als eigene Funktion da, weil hier der Fehler passiert, den
  /// niemand bemerkt: eine Erinnerung, die nicht kommt. Das Plugin
  /// drumherum ruft nur noch `zonedSchedule` für jeden Eintrag.
  static List<DateTime> termine({
    required Erinnerung einstellung,
    required bool hatPlan,
    required bool heuteErledigt,
    required DateTime jetzt,
  }) {
    if (!einstellung.aktiv || !hatPlan) return const [];

    final liste = <DateTime>[];
    for (var tag = 0; tag < tage; tag += 1) {
      // Heute nur, wenn noch nichts abgehakt ist und die Uhrzeit noch
      // bevorsteht. Eine Erinnerung an etwas Erledigtes ist Lärm.
      if (tag == 0 && heuteErledigt) continue;

      final zeitpunkt = einstellung.naechsterZeitpunkt(jetzt, tageSpaeter: tag);
      if (!zeitpunkt.isAfter(jetzt)) continue;

      liste.add(zeitpunkt);
    }
    return liste;
  }

  /// Räumt alle Termine weg und legt die neuen an.
  ///
  /// [hatPlan] und [heuteErledigt] sind der Grund, warum diese Methode von
  /// überall gerufen wird, wo sich etwas daran ändern kann.
  Future<void> planen({
    required Erinnerung einstellung,
    required bool hatPlan,
    required bool heuteErledigt,
    DateTime? jetzt,
  }) async {
    await initialisieren();
    if (!_bereit) return;

    await abbrechen();

    final anstehend = termine(
      einstellung: einstellung,
      hatPlan: hatPlan,
      heuteErledigt: heuteErledigt,
      jetzt: jetzt ?? DateTime.now(),
    );
    if (anstehend.isEmpty) return;

    final t = texte();

    // Die IDs werden von vorn durchgezaehlt. Welcher Termin welche Nummer
    // bekommt, ist gleichgueltig – `abbrechen` raeumt ohnehin den ganzen
    // Nummernkreis, bevor neu geplant wird.
    for (var nummer = 0; nummer < anstehend.length; nummer += 1) {
      final zeitpunkt = anstehend[nummer];

      try {
        await _plugin.zonedSchedule(
          id: _ersteId + nummer,
          title: t.erinnerungPushTitel,
          body: t.erinnerungPushText,
          scheduledDate: tz.TZDateTime.from(zeitpunkt, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _kanalId,
              t.erinnerungKanalName,
              channelDescription: t.erinnerungKanalBeschreibung,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          // Ungenaue Planung reicht für eine Erinnerung und braucht keine
          // Sonderberechtigung für exakte Alarme.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('Tageserinnerung konnte nicht geplant werden: $e');
        return;
      }
    }
  }

  Future<void> abbrechen() async {
    if (!_bereit) return;
    for (var tag = 0; tag < tage; tag += 1) {
      try {
        await _plugin.cancel(id: _ersteId + tag);
      } catch (e) {
        debugPrint('Tageserinnerung konnte nicht entfernt werden: $e');
        return;
      }
    }
  }
}

final tagesErinnerungProvider = Provider<TagesErinnerung>(
  (ref) => TagesErinnerung(
    texte: () => lookupL(ref.read(aktiveSpracheProvider).locale),
  ),
);
