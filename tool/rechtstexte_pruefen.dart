// Prüft vor einem Release-Build, ob die Rechtstexte hinterlegt sind.
//
//   dart run tool/rechtstexte_pruefen.dart
//
// Beendet sich mit Code 1, wenn eine URL oder ein Text fehlt oder die
// Textversion noch auf „Entwurf" steht. Damit lässt sich der Release-Build
// verweigern, ohne dass die App zur Laufzeit abstürzt — genau die Trennung,
// die die Roadmap verlangt: Checkliste statt Crash.
//
// Vorgesehener Platz: als erster Schritt vor `flutter build appbundle`
// (siehe SETUP.md, Abschnitt 10).
import 'dart:io';

import 'package:trueglow/features/legal/logic/rechtstexte.dart';

void main() {
  if (Rechtstexte.vollstaendig) {
    stdout.writeln('✓ ${Rechtstexte.fehlerbericht}');
    return;
  }

  stderr
    ..writeln('✗ ${Rechtstexte.fehlerbericht}')
    ..writeln()
    ..writeln('Ohne öffentliche Datenschutzerklärung lehnt Google Play die')
    ..writeln('Einreichung ab. Trage die Adressen in')
    ..writeln('lib/features/legal/logic/rechtstexte.dart ein und erhöhe dort')
    ..writeln('die Textversion.');
  exitCode = 1;
}
