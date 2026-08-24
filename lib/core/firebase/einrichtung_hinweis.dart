import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'firebase_start.dart';

/// Wird statt der App gezeigt, wenn Firebase nicht startet.
///
/// Das ist beim Aufsetzen der Normalfall (`flutterfire configure` fehlt noch)
/// und soll deshalb erklaeren statt abzustuerzen. Im Release-Build ist der
/// Fall praktisch ausgeschlossen: dort liegt die Konfiguration im Bundle.
class EinrichtungHinweisApp extends StatelessWidget {
  const EinrichtungHinweisApp({required this.ergebnis, super.key});

  final FirebaseStartErgebnis ergebnis;

  @override
  Widget build(BuildContext context) {
    final nichtKonfiguriert =
        ergebnis.stand == FirebaseStartStand.nichtKonfiguriert;

    return MaterialApp(
      title: 'GlowUp – Einrichtung',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.gapL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: AppTheme.gapM),
                  Text(
                    nichtKonfiguriert
                        ? 'Firebase ist noch nicht eingerichtet'
                        : 'Firebase konnte nicht starten',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.gapS),
                  Text(
                    nichtKonfiguriert
                        ? 'Führe die Schritte aus SETUP.md, Abschnitt 2 aus:\n\n'
                            'flutterfire configure --project=DEINE-PROJEKT-ID '
                            '--platforms=android,ios '
                            '--out=lib/firebase_options.dart\n\n'
                            'Für einen Durchlauf ohne Backend (Demo- und '
                            'Screenshot-Modus) startest du die App mit\n'
                            '--dart-define=GLOWUP_MOCK=true.'
                        : 'Die Konfiguration ist vorhanden, der Start ist '
                            'trotzdem fehlgeschlagen. Häufigste Ursache: '
                            'android/app/google-services.json fehlt oder '
                            'gehört zu einem anderen Projekt '
                            '(SETUP.md, Abschnitt 2).',
                  ),
                  if (ergebnis.details case final details?) ...[
                    const SizedBox(height: AppTheme.gapM),
                    SelectableText(
                      details,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
