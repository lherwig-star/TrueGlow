import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../analysis/logic/analysis_controller.dart';
import '../../analysis/logic/analysis_service.dart';
import '../../auth/logic/auth_repository.dart';
import '../../capture/logic/capture_controller.dart';
import '../../checkin/logic/checkin_benachrichtigung.dart';
import '../../checkin/logic/checkin_controller.dart';
import '../../direction/logic/direction_controller.dart';
import '../../modules/logic/module_controller.dart';
import '../../history/logic/analysis_repository.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../../plan/logic/plan_progress_repository.dart';

/// Einstellungen: Angaben aendern, Daten loeschen (DSGVO), Rechtstexte.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPage(
      title: S.einstellungenTitel,
      children: [
        const _KontoKarte(),
        const SizedBox(height: AppTheme.gapS),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXs),
          child: Column(
            children: [
              _Eintrag(
                icon: Icons.tune,
                label: S.einstellungenAngaben,
                onTap: () => _angabenAendern(context, ref),
              ),
              const Divider(indent: AppTheme.gapM, endIndent: AppTheme.gapM),
              _Eintrag(
                icon: Icons.delete_outline,
                label: S.einstellungenDatenLoeschen,
                gefahr: true,
                onTap: () => _datenLoeschen(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXs),
          child: Column(
            children: [
              _Eintrag(
                icon: Icons.description_outlined,
                label: S.einstellungenImpressum,
                onTap: () => _platzhalter(context),
              ),
              const Divider(indent: AppTheme.gapM, endIndent: AppTheme.gapM),
              _Eintrag(
                icon: Icons.privacy_tip_outlined,
                label: S.einstellungenDatenschutz,
                onTap: () => _platzhalter(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        const _ErscheinungsbildKarte(),
        const SizedBox(height: AppTheme.gapS),
        const _ModusKarte(),
        const SizedBox(height: AppTheme.gapM),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
          child: MutedText(S.disclaimerMedizin),
        ),
      ],
    );
  }

  void _platzhalter(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rechtstext folgt.')),
    );
  }

  /// Onboarding erneut durchlaufen. Analysen bleiben erhalten.
  void _angabenAendern(BuildContext context, WidgetRef ref) {
    ref.read(onboardingControllerProvider.notifier).zuruecksetzen();
    context.go(Routes.onboarding);
  }

  Future<void> _datenLoeschen(BuildContext context, WidgetRef ref) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alle Daten löschen?'),
        content: const Text(
          'Analysen, Plan, Fortschritt und deine Angaben werden unwiderruflich '
          'vom Gerät entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.abbrechen),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.farben.warnung,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (bestaetigt != true) return;

    await ref.read(alleDatenLoeschenProvider)();
    await ref.read(imageQualityServiceProvider).fotosLoeschen();

    // Alle Zustaende zuruecksetzen, damit nichts Altes im Speicher bleibt.
    ref.read(captureControllerProvider.notifier).alleVerwerfen();
    ref.read(moduleControllerProvider.notifier).zuruecksetzen();
    ref.read(directionControllerProvider.notifier).zuruecksetzen();
    ref.read(checkinControllerProvider.notifier).zuruecksetzen();
    await ref.read(checkinBenachrichtigungProvider).abbrechen();
    ref.read(analysisControllerProvider.notifier).zuruecksetzen();
    ref.read(analysenProvider.notifier).neuLaden();
    ref.read(planFortschrittProvider.notifier).neuLaden();
    ref.read(onboardingControllerProvider.notifier).zuruecksetzen();
    // Die Theme-Auswahl liegt in derselben Box und wurde mitgeloescht.
    ref.read(themeControllerProvider.notifier).neuLaden();

    if (!context.mounted) return;
    context.go(Routes.onboarding);
  }
}

/// Angemeldetes Konto und der Weg hinaus.
///
/// Bewusst weit oben auf der Seite: Wer nach „bin ich eigentlich angemeldet?"
/// sucht, soll nicht scrollen muessen.
class _KontoKarte extends ConsumerWidget {
  const _KontoKarte();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutzer = ref.watch(nutzerProvider).valueOrNull;
    final farben = context.farben;

    if (nutzer == null) {
      return const SectionCard(
        title: 'Konto',
        icon: Icons.person_outline,
        child: MutedText('Nicht angemeldet.'),
      );
    }

    return SectionCard(
      title: 'Konto',
      icon: nutzer.anonym ? Icons.person_outline : Icons.verified_user_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nutzer.beschriftung,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTheme.gapXs),
          MutedText(
            nutzer.anonym
                ? 'Deine Daten hängen an diesem Gerät. Melde dich mit Google '
                    'an, damit sie einen Gerätewechsel überleben – dein '
                    'bisheriger Stand wird dabei übernommen.'
                : 'Plan, Streak und Verlauf gehören zu diesem Konto. Fotos '
                    'bleiben auf dem Gerät.',
          ),
          const SizedBox(height: AppTheme.gapS),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _abmelden(context, ref, anonym: nutzer.anonym),
              icon: Icon(Icons.logout, size: 18, color: farben.warnung),
              label: Text(
                'Abmelden',
                style: TextStyle(color: farben.warnung),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abmelden(
    BuildContext context,
    WidgetRef ref, {
    required bool anonym,
  }) async {
    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abmelden?'),
        content: Text(
          anonym
              // Ein anonymes Konto laesst sich nach dem Abmelden nicht wieder
              // aufrufen – das gehoert vorher gesagt, nicht hinterher.
              ? 'Du bist ohne Konto angemeldet. Nach dem Abmelden kommst du '
                  'an diesen Stand nicht mehr heran. Die Daten auf diesem '
                  'Gerät bleiben erhalten.'
              : 'Deine Daten bleiben in deinem Konto. Nach der nächsten '
                  'Anmeldung sind sie wieder da.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(S.abbrechen),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.farben.warnung,
            ),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );

    if (bestaetigt != true) return;

    await ref.read(authRepositoryProvider).abmelden();
    if (!context.mounted) return;
    context.go(Routes.login);
  }
}

/// Zeigt an, ob die App gerade gegen die echte API oder gegen den Mock laeuft.
class _ModusKarte extends StatelessWidget {
  const _ModusKarte();

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final mock = AnalysisConfig.useMockData;
    final farbe = mock ? farben.akzent : farben.erfolg;

    return SectionCard(
      title: 'Analyse-Modus',
      icon: mock ? Icons.science_outlined : Icons.cloud_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: farbe.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        // Die Farbe traegt die Pille, nicht die Schrift: eingefaerbte
        // Kleinschrift auf der Karte bleibt sonst unter 4,5:1.
        child: Text(
          mock ? 'Mock' : 'Live',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: farben.textPrimaer,
          ),
        ),
      ),
      child: MutedText(
        mock
            ? 'Es werden keine Fotos versendet. Die App zeigt eine hinterlegte '
                'Beispiel-Analyse. Umschalten beim Build über '
                '--dart-define=GLOWUP_MOCK.'
            : 'Analysen laufen über den GlowUp-Dienst '
                '(${AnalysisConfig.modell}). Deine Fotos werden für die '
                'Auswertung übertragen und dort weder gespeichert noch '
                'protokolliert.',
      ),
    );
  }
}

class _Eintrag extends StatelessWidget {
  const _Eintrag({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gefahr = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool gefahr;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final farbe = gefahr ? farben.warnung : farben.textPrimaer;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: gefahr ? farben.warnung : farben.akzent),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: farbe),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: farben.textSekundaer,
        size: 20,
      ),
    );
  }
}

/// Umschalter Hell / Dunkel / System. Die Auswahl wirkt sofort, weil das
/// Theme im [MaterialApp] direkt am Provider haengt.
class _ErscheinungsbildKarte extends ConsumerWidget {
  const _ErscheinungsbildKarte();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktuell = ref.watch(themeControllerProvider);

    return SectionCard(
      title: S.einstellungenErscheinungsbild,
      icon: Icons.palette_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<Erscheinungsbild>(
            segments: [
              for (final wahl in Erscheinungsbild.values)
                ButtonSegment(
                  value: wahl,
                  label: Text(wahl.label),
                  icon: Icon(wahl.icon, size: 18),
                ),
            ],
            selected: {aktuell},
            showSelectedIcon: false,
            onSelectionChanged: (auswahl) => ref
                .read(themeControllerProvider.notifier)
                .setzen(auswahl.first),
          ),
          const SizedBox(height: AppTheme.gapS),
          MutedText(
            aktuell == Erscheinungsbild.system
                ? 'GlowUp folgt der Systemeinstellung deines Handys.'
                : 'Feste Auswahl – unabhängig von der Systemeinstellung.',
          ),
        ],
      ),
    );
  }
}
