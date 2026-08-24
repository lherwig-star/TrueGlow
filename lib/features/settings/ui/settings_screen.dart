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
import '../../account/logic/konto_dienst.dart';
import '../../analysis/logic/analysis_controller.dart';
import '../../analysis/logic/analysis_service.dart';
import '../../auth/logic/auth_repository.dart';
import '../../consent/logic/einwilligung_controller.dart';
import '../../consent/models/einwilligung.dart';
import '../../consent/ui/einwilligungs_auswahl.dart';
import '../../auth/models/trueglow_nutzer.dart';
import '../../migration/ui/migration_dialog.dart';
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
                onTap: () => _loeschen(context, ref, Loeschmodus.nurDaten),
              ),
              const Divider(indent: AppTheme.gapM, endIndent: AppTheme.gapM),
              _Eintrag(
                icon: Icons.no_accounts_outlined,
                label: S.einstellungenKontoLoeschen,
                gefahr: true,
                onTap: () =>
                    _loeschen(context, ref, Loeschmodus.kontoKomplett),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXs),
          child: _Eintrag(
            icon: Icons.gavel_outlined,
            label: S.einstellungenRechtliches,
            onTap: () => context.push(Routes.rechtliches),
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        const _EinwilligungsKarte(),
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

  /// Onboarding erneut durchlaufen. Analysen bleiben erhalten.
  void _angabenAendern(BuildContext context, WidgetRef ref) {
    ref.read(onboardingControllerProvider.notifier).zuruecksetzen();
    context.go(Routes.onboarding);
  }

  /// Loescht Daten – wahlweise samt Konto.
  ///
  /// Zwei Wege, ein Ablauf: erst fragen, dann die Cloud raeumen, dann das
  /// Geraet. Die Reihenfolge ist wichtig – bliebe die Cloud stehen, holte der
  /// naechste Sync alles zurueck.
  Future<void> _loeschen(
    BuildContext context,
    WidgetRef ref,
    Loeschmodus modus,
  ) async {
    final kontoWeg = modus == Loeschmodus.kontoKomplett;

    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          kontoWeg ? 'Konto endgültig löschen?' : 'Alle Daten löschen?',
        ),
        content: Text(
          kontoWeg
              ? 'Dein Konto und alle Inhalte werden unwiderruflich gelöscht – '
                  'auf diesem Gerät und in der Cloud. Auch deine Fotos auf '
                  'dem Gerät werden entfernt.\n\n'
                  'Danach kannst du dich mit diesem Konto nicht mehr anmelden.'
              : 'Analysen, Plan, Fortschritt und deine Angaben werden '
                  'unwiderruflich entfernt – auf diesem Gerät und in deinem '
                  'Konto. Auch deine Fotos auf dem Gerät werden gelöscht.\n\n'
                  'Dein Konto selbst bleibt bestehen.',
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
            child: Text(kontoWeg ? 'Konto löschen' : 'Löschen'),
          ),
        ],
      ),
    );

    if (bestaetigt != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    // Zuerst die Cloud. Scheitert sie, wird lokal nichts angefasst: Ein
    // halbes Loeschen waere schlimmer als keins, weil der Nutzer glaubt,
    // es sei erledigt.
    if (!await _cloudRaeumen(ref, modus, messenger)) return;

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
    ref.read(einwilligungControllerProvider.notifier).zuruecksetzen();
    // Die Theme-Auswahl liegt in derselben Box und wurde mitgeloescht.
    ref.read(themeControllerProvider.notifier).neuLaden();

    if (kontoWeg) {
      await ref.read(authRepositoryProvider).abmelden();
    }

    if (!context.mounted) return;
    context.go(kontoWeg ? Routes.login : Routes.onboarding);
  }

  /// Raeumt den Cloud-Anteil. Gibt zurueck, ob weitergemacht werden darf.
  ///
  /// Ohne Backend (Demo-Modus) gibt es nichts zu raeumen – dann geht es
  /// direkt weiter.
  Future<bool> _cloudRaeumen(
    WidgetRef ref,
    Loeschmodus modus,
    ScaffoldMessengerState? messenger,
  ) async {
    final dienst = ref.read(kontoDienstProvider);
    if (dienst == null) return true;

    try {
      await dienst.loeschen(modus);
      return true;
    } on KontoException catch (e) {
      if (e.fehler != KontoFehler.neuAnmelden) {
        _melden(messenger, e.fehler);
        return false;
      }
    }

    // Genau ein zweiter Versuch nach frischer Anmeldung. Mehr waere eine
    // Schleife, in der niemand mehr versteht, was gerade passiert.
    try {
      await ref.read(authRepositoryProvider).erneutAnmelden();
      await dienst.loeschen(modus);
      return true;
    } on KontoException catch (e) {
      _melden(messenger, e.fehler);
      return false;
    } on AuthException catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('${e.fehler.titel}: ${e.fehler.tipp}')),
      );
      return false;
    }
  }

  static void _melden(ScaffoldMessengerState? messenger, KontoFehler fehler) {
    messenger?.showSnackBar(
      SnackBar(content: Text('${fehler.titel}: ${fehler.tipp}')),
    );
  }
}

/// Erteilte Einwilligungen mit Nachweis und Widerrufsweg.
///
/// Der Widerruf gehoert sichtbar in die Einstellungen und nicht in ein
/// Untermenue: Eine Einwilligung, die sich nur schwer zuruecknehmen laesst,
/// ist keine freiwillige.
class _EinwilligungsKarte extends ConsumerWidget {
  const _EinwilligungsKarte();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(einwilligungControllerProvider);
    final fotoErlaubt = ref.watch(einwilligungGiltProvider(Einwilligungsart.fotoKi));

    return SectionCard(
      title: 'Einwilligungen',
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MutedText(
            fotoErlaubt
                ? 'Analysen sind möglich. Deine Fotos gehen nur für die Dauer '
                    'der Auswertung an den KI-Dienst.'
                : 'Ohne Foto-Einwilligung sind keine neuen Analysen möglich. '
                    'Deine bisherigen Reports, dein Plan und deine Serie '
                    'bleiben erhalten.',
          ),
          const SizedBox(height: AppTheme.gapS),
          // Das Haekchen ist zugleich der Widerrufsweg: abwaehlen genuegt.
          const EinwilligungsHaken(
            art: Einwilligungsart.fotoKi,
            kanal: Einwilligungskanal.einstellungen,
          ),
          const SizedBox(height: AppTheme.gapS),
          for (final art in Einwilligungsart.values)
            _Nachweis(eintrag: stand.eintrag(art), art: art),
        ],
      ),
    );
  }
}

/// Eine Zeile des Nachweises: was, wann, auf welche Textfassung.
class _Nachweis extends StatelessWidget {
  const _Nachweis({required this.eintrag, required this.art});

  final Einwilligung? eintrag;
  final Einwilligungsart art;

  @override
  Widget build(BuildContext context) {
    final e = eintrag;
    if (e == null) {
      return MutedText('${art.titel}: noch nicht gefragt');
    }

    final zeitpunkt = e.zeitpunkt.toLocal();
    final datum = '${zeitpunkt.day.toString().padLeft(2, '0')}.'
        '${zeitpunkt.month.toString().padLeft(2, '0')}.${zeitpunkt.year}';

    return MutedText(
      '${art.titel}: ${e.erteilt ? 'erteilt' : 'nicht erteilt'} am $datum '
      '(Textstand $_textversion, ${_kanal(e.kanal)})',
    );
  }

  String get _textversion => eintrag!.textversion.isEmpty
      ? 'unbekannt'
      : eintrag!.textversion;

  static String _kanal(Einwilligungskanal kanal) => switch (kanal) {
        Einwilligungskanal.onboarding => 'im Onboarding',
        Einwilligungskanal.einstellungen => 'in den Einstellungen',
        Einwilligungskanal.nachtrag => 'nachträglich',
      };
}

/// Angemeldetes Konto und der Weg hinaus.
///
/// Bewusst weit oben auf der Seite: Wer nach „bin ich eigentlich angemeldet?"
/// sucht, soll nicht scrollen muessen.
class _KontoKarte extends ConsumerWidget {
  const _KontoKarte();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(nutzerProvider);
    final farben = context.farben;

    // Drei Zustaende statt einem: Waehrend der Anmeldezustand noch geladen
    // wird, waere „Nicht angemeldet" schlicht falsch.
    if (stand.isLoading) {
      return const SectionCard(
        title: 'Konto',
        icon: Icons.person_outline,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppTheme.gapS),
            MutedText('Wird geladen …'),
          ],
        ),
      );
    }

    if (stand.hasError) {
      return const SectionCard(
        title: 'Konto',
        icon: Icons.error_outline,
        child: MutedText(
          'Der Anmeldezustand lässt sich gerade nicht abfragen. '
          'Deine Daten auf dem Gerät sind davon nicht betroffen.',
        ),
      );
    }

    final nutzer = stand.valueOrNull;
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
          if (nutzer.anonym) ...[
            // Verknuepfen statt neu anmelden: Die uid bleibt dieselbe,
            // deshalb bleiben Streak, Plan und Historie da, wo sie sind.
            FilledButton.icon(
              onPressed: () => _verknuepfen(context, ref),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Mit Google verknüpfen'),
            ),
            const SizedBox(height: AppTheme.gapXs),
          ],
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

  /// Macht aus dem anonymen Konto ein Google-Konto, ohne die Daten zu
  /// verlieren.
  Future<void> _verknuepfen(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      await ref.read(authRepositoryProvider).verknuepfen(AuthAnbieter.google);
      if (!context.mounted) return;

      // Falls der lokale Bestand noch nie in die Cloud gewandert ist, ist
      // jetzt der richtige Moment dafuer.
      await MigrationDialog.zeigenWennNoetig(context, ref);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Konto verknüpft.')),
      );
    } on AuthException catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('${e.fehler.titel}: ${e.fehler.tipp}')),
      );
    }
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
                '--dart-define=TRUEGLOW_MOCK.'
            : 'Analysen laufen über den TrueGlow-Dienst '
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
                ? 'TrueGlow folgt der Systemeinstellung deines Handys.'
                : 'Feste Auswahl – unabhängig von der Systemeinstellung.',
          ),
        ],
      ),
    );
  }
}
