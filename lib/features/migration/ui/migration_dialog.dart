import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/hive_migration.dart';

/// Fragt beim ersten echten Login, ob der bisherige Bestand mitkommen soll.
///
/// Bewusst eine Frage und keine stille Uebernahme: Wer die App auf einem
/// fremden oder geteilten Geraet zum ersten Mal mit seinem Konto oeffnet,
/// soll die Daten des Vorbesitzers nicht kommentarlos erben.
class MigrationDialog {
  MigrationDialog._();

  /// Prueft, fragt und uebernimmt. Tut nichts, wenn es nichts zu uebernehmen
  /// gibt oder die Frage schon einmal beantwortet wurde.
  static Future<void> zeigenWennNoetig(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final migration = ref.read(hiveMigrationProvider);
    if (migration == null) return;

    final bool noetig;
    try {
      noetig = await migration.istNoetig();
    } catch (e) {
      debugPrint('Migration: Pruefung fehlgeschlagen ($e)');
      return;
    }
    if (!noetig || !context.mounted) return;

    // Vor dem Warten holen: Nach dem Dialog kann der Screen weg sein, und
    // dann gibt es keinen BuildContext mehr zu benutzen.
    final messenger = ScaffoldMessenger.maybeOf(context);

    final uebernehmen = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Deine bisherigen Daten übernehmen?'),
        content: const Text(
          'Auf diesem Gerät liegen Analysen, Plan, Streak und Check-ins aus '
          'der Zeit ohne Konto. Sollen sie zu deinem Konto gehören?\n\n'
          'Deine Fotos bleiben in jedem Fall nur auf dem Gerät.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein, frisch starten'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );

    try {
      if (uebernehmen == true) {
        final anzahl = await migration.ausfuehren();
        _melden(
          messenger,
          anzahl == 0
              ? 'Es gab nichts zu übernehmen.'
              : 'Übernommen: $anzahl Einträge.',
        );
      } else {
        // Die Frage gilt als beantwortet – sonst kaeme sie bei jeder
        // Anmeldung wieder.
        await migration.ablehnen();
      }
    } catch (e) {
      debugPrint('Migration fehlgeschlagen: $e');
      _melden(
        messenger,
        'Übernahme fehlgeschlagen. Deine Daten sind weiter auf dem Gerät – '
        'wir fragen beim nächsten Start erneut.',
      );
    }
  }

  static void _melden(ScaffoldMessengerState? messenger, String text) {
    messenger?.showSnackBar(SnackBar(content: Text(text)));
  }
}
