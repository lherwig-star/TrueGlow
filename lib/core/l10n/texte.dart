import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// [lookupL] fuer Code ohne BuildContext – Benachrichtigungen zum Beispiel
/// werden geplant, wenn der ausloesende Screen laengst weg ist.
export '../../l10n/app_localizations.dart' show L, lookupL;

/// Zugriff auf die übersetzten Texte.
///
/// Geschrieben wie [context.farben] in `app_colors.dart`, damit sich beide
/// gleich anfühlen: oben im `build` einmal
///
/// ```dart
/// final texte = context.texte;
/// ```
///
/// und darunter `texte.weiter`. Der Umweg über eine lokale Variable ist kein
/// Stil, sondern nötig – `L.of(context)` in jeder Zeile aufzurufen macht die
/// Zeilen unlesbar.
///
/// Warum kein statischer Zugriff wie beim früheren `S`: Ein Wechsel der
/// Sprache muss die Oberfläche neu aufbauen. Über den Kontext hängt jeder
/// Text an `Localizations` und wird dabei mitgezogen; eine globale Variable
/// bliebe stehen, bis der jeweilige Screen zufällig aus einem anderen Grund
/// neu baut.
extension AppTexte on BuildContext {
  L get texte => L.of(this);
}
