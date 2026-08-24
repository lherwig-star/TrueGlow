import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_provider.dart';

/// Der Stand des Analyse-Kontingents, wie ihn die Cloud Function fuehrt.
///
/// Der Zaehler liegt in `users/{uid}/kontingent/analyse`. Die Security Rules
/// erlauben dem Client dort ausdruecklich das Lesen und verbieten jedes
/// Schreiben – der Kommentar in `firestore.rules` nennt genau diesen Zweck
/// („lesbar, damit die App den Stand anzeigen koennte").
///
/// **Massgeblich ist trotzdem der Server.** Was hier steht, ist ein Hinweis,
/// damit niemand erst den ganzen Fotoweg geht und dann abgewiesen wird. Die
/// Sperre selbst sitzt in `functions/src/limit.ts` und wird vor jedem
/// Gemini-Aufruf ausgewertet. Diese Klasse darf sich irren, ohne dass etwas
/// kaputtgeht – sie darf nur niemanden faelschlich aussperren, deshalb gilt
/// im Zweifel „unbekannt" statt „erschoepft".
@immutable
class KontingentStand {
  const KontingentStand({
    required this.tagVerbraucht,
    required this.monatVerbraucht,
  });

  /// Spiegel von `GRENZEN.analyse` in `functions/src/limit.ts`.
  ///
  /// Bewusst doppelt gehalten: Der Zaehler im Firestore-Dokument enthaelt die
  /// Grenze nicht, und eine eigene Cloud Function nur fuer zwei Zahlen waere
  /// teurer als dieser Kommentar. Laufen die Werte auseinander, stimmt der
  /// Hinweis nicht mehr – die Sperre aber schon, weil sie serverseitig
  /// entschieden wird.
  static const int proTag = 3;
  static const int proMonat = 30;

  final int tagVerbraucht;
  final int monatVerbraucht;

  int get tagUebrig => (proTag - tagVerbraucht).clamp(0, proTag);
  int get monatUebrig => (proMonat - monatVerbraucht).clamp(0, proMonat);

  /// Ob ein weiterer Aufruf abgelehnt wuerde – Tages- **oder** Monatsgrenze.
  bool get erschoepft => tagUebrig == 0 || monatUebrig == 0;

  /// Welche der beiden Grenzen zuerst greift. Die Unterscheidung zaehlt fuer
  /// den Text: „morgen wieder" stimmt bei der Monatsgrenze nicht.
  bool get monatsgrenzeErreicht => monatUebrig == 0;

  /// Liest den Zaehlerstand und normalisiert ihn auf heute.
  ///
  /// Dieselbe Regel wie `stand()` in `functions/src/limit.ts`: Ein Zaehler,
  /// dessen Tag bzw. Monat nicht mehr der aktuelle ist, zaehlt als 0. Ohne das
  /// wuerde ein gestriger Stand heute weitersperren.
  factory KontingentStand.ausDaten(
    Map<String, dynamic>? daten, {
    DateTime? jetzt,
  }) {
    final tag = _tagesSchluessel(jetzt ?? DateTime.now());
    final monat = tag.substring(0, 7);

    return KontingentStand(
      tagVerbraucht: daten?['tag'] == tag ? _zahl(daten?['tagZaehler']) : 0,
      monatVerbraucht:
          daten?['monat'] == monat ? _zahl(daten?['monatZaehler']) : 0,
    );
  }

  /// Tagesschluessel `jjjj-mm-tt` aus der **lokalen** Uhrzeit des Geraets.
  ///
  /// Der Server rechnet in `Europe/Berlin`. Auf einem Geraet in einer anderen
  /// Zeitzone kann der Hinweis deshalb um Mitternacht herum um einen Tag
  /// danebenliegen.
  ///
  /// Das `timezone`-Paket ist zwar ohnehin eingebunden (fuer die
  /// Check-in-Erinnerungen), benutzt dort aber ausschliesslich `tz.UTC` – die
  /// Zeitzonendatenbank wird nie geladen. Fuer `Europe/Berlin` muesste beim
  /// Start `initializeTimeZones()` laufen und die komplette Datenbank in den
  /// Speicher. Das ist viel Aufwand fuer einen Hinweis, ueber den ohnehin der
  /// Server entscheidet.
  static String _tagesSchluessel(DateTime zeitpunkt) =>
      '${zeitpunkt.year.toString().padLeft(4, '0')}-'
      '${zeitpunkt.month.toString().padLeft(2, '0')}-'
      '${zeitpunkt.day.toString().padLeft(2, '0')}';

  /// Wie `zahl()` serverseitig: alles Unplausible zaehlt als 0.
  static int _zahl(Object? wert) =>
      wert is num && wert.isFinite && wert > 0 ? wert.floor() : 0;

  @override
  bool operator ==(Object other) =>
      other is KontingentStand &&
      other.tagVerbraucht == tagVerbraucht &&
      other.monatVerbraucht == monatVerbraucht;

  @override
  int get hashCode => Object.hash(tagVerbraucht, monatVerbraucht);

  @override
  String toString() =>
      'KontingentStand(tag: $tagVerbraucht/$proTag, '
      'monat: $monatVerbraucht/$proMonat)';
}

/// Der aktuelle Kontingentstand oder `null`, wenn er sich nicht ermitteln
/// laesst.
///
/// `null` heisst ausdruecklich **„unbekannt"**, nicht „erschoepft": im Demo-
/// und Offline-Modus, ohne Anmeldung, bei einem Lesefehler. Die Oberflaeche
/// zeigt dann keinen Hinweis und sperrt nichts – der Server weist notfalls ab.
/// Andersherum waere es schlimmer: ein Hinweis, der jemanden aussperrt, obwohl
/// noch Kontingent da ist.
final kontingentProvider =
    FutureProvider.autoDispose<KontingentStand?>((ref) async {
  final speicher = ref.watch(cloudSpeicherProvider);
  if (speicher == null) return null;

  try {
    final dokument = await speicher.lesen('kontingent/analyse');
    // Kein Dokument heisst: noch nie eine Analyse gelaufen. Das ist ein
    // vollstaendig freier Zaehler, kein Fehler.
    return KontingentStand.ausDaten(dokument?.daten);
  } catch (e) {
    debugPrint('Kontingentstand nicht lesbar: $e');
    return null;
  }
});
