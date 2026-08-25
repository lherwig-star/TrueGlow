import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/diagnose/diagnose_dienst.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../migration/ui/migration_dialog.dart';
import '../logic/auth_repository.dart';
import '../models/trueglow_nutzer.dart';

/// Anmeldung – im Design der uebrigen Screens: Karten, Akzentfarbe, beide
/// Farbschemata.
///
/// Warum es diesen Screen ueberhaupt gibt: Die Analyse laeuft seit Phase 1.2
/// ueber eine Cloud Function, und die nimmt nur Aufrufe mit gueltigem
/// Auth-Token an. Ohne Konto gaebe es also gar keine Analyse. „Erst
/// ausprobieren" macht daraus trotzdem keine Huerde – das anonyme Konto
/// kostet nichts und wird beim spaeteren Google-Login uebernommen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  AuthAnbieter? _laeuft;
  AuthFehler? _fehler;

  Future<void> _anmelden(AuthAnbieter anbieter) async {
    if (_laeuft != null) return;
    setState(() {
      _laeuft = anbieter;
      _fehler = null;
    });

    try {
      await ref.read(authRepositoryProvider).anmelden(anbieter);
      ref
          .read(diagnoseDienstProvider)
          .melde(DiagnoseEreignis.anmeldungAbgeschlossen);
      if (!mounted) return;

      // Beim ersten echten Login kommt die Frage nach dem lokalen Bestand –
      // noch bevor das Dashboard ihn anzeigt.
      await MigrationDialog.zeigenWennNoetig(context, ref);
      if (!mounted) return;

      context.go(Routes.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _laeuft = null;
        _fehler = e.fehler;
      });
      return;
    }

    if (mounted) setState(() => _laeuft = null);
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final anbieter = AuthAnbieter.values
        .where((a) => a.verfuegbarAuf(defaultTargetPlatform))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapM),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.auto_awesome, size: 48, color: farben.akzent),
              const SizedBox(height: AppTheme.gapM),
              Text(
                texte.appName,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.gapS),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.gapS),
                child: MutedText(
                  texte.loginWarumKonto,
                  align: TextAlign.center,
                ),
              ),
              const Spacer(),
              if (_fehler case final fehler?) ...[
                _Fehlerkarte(fehler: fehler),
                const SizedBox(height: AppTheme.gapS),
              ],
              for (final a in anbieter.where((a) => a != AuthAnbieter.anonym))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.gapS),
                  child: FilledButton.icon(
                    onPressed: _laeuft == null ? () => _anmelden(a) : null,
                    icon: _laeuft == a
                        ? const _Spinner()
                        : Icon(_symbol(a), size: 20),
                    label: Text(texte.loginMitAnbieter(a.label(texte))),
                  ),
                ),
              OutlinedButton(
                onPressed: _laeuft == null
                    ? () => _anmelden(AuthAnbieter.anonym)
                    : null,
                child: _laeuft == AuthAnbieter.anonym
                    ? const _Spinner()
                    : Text(texte.loginGast),
              ),
              const SizedBox(height: AppTheme.gapM),
              MutedText(texte.loginGastErklaerung, align: TextAlign.center),
              const SizedBox(height: AppTheme.gapM),
              MutedText(texte.loginFotosBleiben, align: TextAlign.center),
              const SizedBox(height: AppTheme.gapM),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _symbol(AuthAnbieter anbieter) => switch (anbieter) {
        AuthAnbieter.google => Icons.login,
        AuthAnbieter.apple => Icons.apple,
        AuthAnbieter.anonym => Icons.visibility_outlined,
      };
}

class _Fehlerkarte extends StatelessWidget {
  const _Fehlerkarte({required this.fehler});

  final AuthFehler fehler;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: fehler.titel(context.texte),
      icon: Icons.error_outline,
      child: MutedText(fehler.tipp(context.texte)),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
