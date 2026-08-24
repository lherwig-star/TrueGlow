import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/logic/auth_repository.dart';
import 'cloud_speicher.dart';

/// Wie ein [CloudSpeicher] fuer eine uid entsteht.
///
/// Wird beim Start gesetzt: in `main()` mit der Firestore-Fassung, in Tests
/// mit einer Attrappe. Standard ist `null` – das ist der Demo-/Screenshot-
/// Modus, der ohne Backend laeuft.
final cloudSpeicherFabrikProvider =
    Provider<CloudSpeicher Function(String uid)?>((ref) => null);

/// Der Cloud-Speicher des angemeldeten Kontos.
///
/// `null`, solange niemand angemeldet ist oder keine Fabrik gesetzt wurde.
/// Jeder Nutzer dieses Providers muss den Fall behandeln – das ist der
/// Offline- und Demo-Fall und damit kein Ausnahmezustand.
final cloudSpeicherProvider = Provider<CloudSpeicher?>((ref) {
  final fabrik = ref.watch(cloudSpeicherFabrikProvider);
  if (fabrik == null) return null;

  final nutzer = ref.watch(nutzerProvider).valueOrNull;
  if (nutzer == null) return null;

  return fabrik(nutzer.uid);
});
