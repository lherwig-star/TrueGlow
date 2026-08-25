import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../core/l10n/texte.dart';

/// Ob das Geraet gerade eine Netzwerkverbindung hat.
///
/// **Was das nicht heisst:** Eine Verbindung ist kein Internet. Ein WLAN ohne
/// Uplink oder ein Hotel-Portal melden hier „online". Die Angabe taugt
/// deshalb fuer einen Hinweis, nicht fuer eine Entscheidung — jede
/// Netzoperation muss weiterhin ihren eigenen Fehler behandeln.
///
/// Faellt das Plugin aus (Emulator, Test, fehlende Plattform), gilt „online".
/// Ein Hinweisband, das faelschlich erscheint, waere schlimmer als keins.
final netzVerbindungProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  try {
    yield _hatVerbindung(await connectivity.checkConnectivity());
  } catch (e) {
    debugPrint('Netzstatus nicht abrufbar: $e');
    yield true;
    return;
  }

  yield* connectivity.onConnectivityChanged
      .map(_hatVerbindung)
      .handleError((Object e) => debugPrint('Netzstatus-Strom endet: $e'));
});

bool _hatVerbindung(List<ConnectivityResult> ergebnisse) =>
    ergebnisse.any((e) => e != ConnectivityResult.none);

/// Ob gerade offline gearbeitet wird.
///
/// Solange der Zustand unbekannt ist, gilt „online" – siehe oben.
final offlineProvider = Provider<bool>((ref) {
  return ref.watch(netzVerbindungProvider).valueOrNull == false;
});

/// Schmales Band ueber der App, solange keine Verbindung besteht.
///
/// Es sagt ausdruecklich, was **weiterhin** geht: Der haeufigste Reflex bei
/// einem Offline-Hinweis ist, die App wegzulegen. Plan, Checkliste und Serie
/// funktionieren aber vollstaendig ohne Netz, und Haken werden nachgetragen,
/// sobald wieder Verbindung da ist.
class OfflineBand extends ConsumerWidget {
  const OfflineBand({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(offlineProvider)) return child;

    final farben = context.farben;

    return Column(
      children: [
        Material(
          color: farben.flaecheHoch,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.gapM,
                vertical: AppTheme.gapXs,
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: farben.textSekundaer),
                  const SizedBox(width: AppTheme.gapXs),
                  Expanded(
                    child: Text(
                      context.texte.offlineBand,
                      style: TextStyle(
                        fontSize: 12,
                        color: farben.textSekundaer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
