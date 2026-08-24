import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_modell.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';

/// Merkt sich, ob beim letzten Programmlauf eine Analyse offen geblieben ist.
///
/// Der Zustand des `AnalysisController` lebt nur im Arbeitsspeicher. Wird die
/// App mitten in einer Analyse beendet — vom Nutzer oder vom System —, ist
/// beim naechsten Start nichts davon mehr zu sehen: kein Ergebnis, kein
/// Fehler, kein Hinweis. Genau der haengende Zwischenzustand, den die Roadmap
/// ausschliessen will.
///
/// Fortsetzen laesst sich der Aufruf nicht — eine abgeschickte Anfrage ist
/// weg. Also wird sauber verworfen und einmal gesagt, dass es sie gab.
class UnterbrocheneAnalyse extends StateNotifier<bool> {
  UnterbrocheneAnalyse(this._box) : super(false) {
    final marke = _box.get(CloudModell.keyAnalyseLaeuftSeit);
    if (marke is String && marke.isNotEmpty) {
      // Direkt raeumen: Der Hinweis erscheint genau einmal, nicht bei jedem
      // Neustart.
      _box.delete(CloudModell.keyAnalyseLaeuftSeit);
      state = true;
    }
  }

  final KeyValueStore _box;

  void verstanden() => state = false;
}

final unterbrocheneAnalyseProvider =
    StateNotifierProvider<UnterbrocheneAnalyse, bool>(
  (ref) => UnterbrocheneAnalyse(
    ref.watch(storeProvider(HiveService.boxEinstellungen)),
  ),
);

/// Hinweis auf eine abgebrochene Analyse, einmalig und wegklickbar.
class UnterbrochenKarte extends ConsumerWidget {
  const UnterbrochenKarte({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(unterbrocheneAnalyseProvider)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapS),
      child: SectionCard(
        title: 'Analyse unterbrochen',
        icon: Icons.info_outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MutedText(
              'Deine letzte Analyse wurde nicht fertig — die App war '
              'zwischendurch geschlossen. Es wurde nichts gespeichert. '
              'Deine Fotos sind noch da, du kannst direkt neu starten.',
            ),
            const SizedBox(height: AppTheme.gapXs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    ref.read(unterbrocheneAnalyseProvider.notifier).verstanden(),
                child: const Text('Verstanden'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
