import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/sprache.dart';
import '../../../core/l10n/texte.dart';
import '../../../core/diagnose/diagnose_dienst.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/marken_logo.dart';
import '../../../core/widgets/section_card.dart';
import '../../legal/ui/rechtstexte_zeile.dart';
import '../../migration/ui/migration_dialog.dart';
import '../logic/auth_repository.dart';
import '../models/trueglow_nutzer.dart';

/// Anmeldung – der erste Bildschirm, auf dem jemand etwas tut.
///
/// Warum es diesen Screen ueberhaupt gibt: Die Analyse laeuft seit Phase 1.2
/// ueber eine Cloud Function, und die nimmt nur Aufrufe mit gueltigem
/// Auth-Token an. Ohne Konto gaebe es also gar keine Analyse. „Erst mal
/// umschauen" macht daraus trotzdem keine Huerde – das anonyme Konto kostet
/// nichts und wird beim spaeteren Google-Login uebernommen.
///
/// Warum er vor dem Onboarding steht: Die Erklaerseiten gehoeren zu einem
/// Konto, nicht zu einem Geraet. Wer die App auf einem zweiten Handy
/// installiert, hat sie schon gesehen – und wer sie hier zum ersten Mal
/// oeffnet, will meistens zuerst wissen, ob er sich anmelden muss.
///
/// Der Sprachumschalter oben rechts steht genau hier, weil dies der erste
/// Text ist, den jemand liest: Wer die App auf Deutsch bekommt, obwohl er
/// Englisch erwartet, soll das im selben Moment aendern koennen.
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
        // Scrollbar, weil unten inzwischen mehr steht als nur zwei Knoepfe:
        // Auf kleinen Geraeten mit grosser Schrift laeuft die Spalte sonst
        // ueber.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapM),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _Sprachumschalter(),
                  ),
                  const SizedBox(height: AppTheme.gapL),
                  MarkenLogo(groesse: 76, farbe: farben.akzent),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gapS,
                    ),
                    child: MutedText(
                      texte.loginWillkommen,
                      align: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  if (_fehler case final fehler?) ...[
                    _Fehlerkarte(fehler: fehler),
                    const SizedBox(height: AppTheme.gapS),
                  ],
                  for (final a
                      in anbieter.where((a) => a != AuthAnbieter.anonym))
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
                  const SizedBox(height: AppTheme.gapS),
                  MutedText(texte.loginFotosBleiben, align: TextAlign.center),
                  const SizedBox(height: AppTheme.gapM),
                  // Die Rechtstexte stehen hier, nicht erst im Onboarding:
                  // Wer sich anmeldet, legt ein Konto an, und wer das tut,
                  // soll vorher nachlesen koennen, worauf er sich einlaesst.
                  // Die verbindliche Einwilligung kommt trotzdem erst danach –
                  // als Haekchen, nicht als Kleingedrucktes.
                  MutedText(texte.loginRechtliches, align: TextAlign.center),
                  const SizedBox(height: AppTheme.gapXs),
                  const RechtstexteZeile(ausrichtung: WrapAlignment.center),
                  const SizedBox(height: AppTheme.gapM),
                ],
              ),
            ),
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

/// DE / EN, oben rechts.
///
/// Bewusst zwei feste Kuerzel und kein Auswahlmenue: Bei zwei Sprachen ist
/// eine Liste ein Klick zu viel, und das Kuerzel der anderen Sprache ist
/// zugleich die Erklaerung, was passiert.
class _Sprachumschalter extends ConsumerWidget {
  const _Sprachumschalter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farben = context.farben;
    final aktiv = ref.watch(aktiveSpracheProvider);

    return Semantics(
      label: context.texte.spracheWaehlen,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final sprache in Sprache.values)
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.gapXs),
              child: InkWell(
                onTap: () => ref
                    .read(sprachControllerProvider.notifier)
                    .setzen(sprache),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sprache == aktiv
                        ? farben.akzent.withValues(alpha: 0.16)
                        : Colors.transparent,
                    border: Border.all(
                      color: sprache == aktiv ? farben.akzent : farben.rand,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sprache.kuerzel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: sprache == aktiv
                          ? farben.akzent
                          : farben.textSekundaer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
