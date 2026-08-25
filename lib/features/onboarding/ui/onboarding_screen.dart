import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/diagnose/diagnose_dienst.dart';
import '../../consent/logic/einwilligung_controller.dart';
import '../../consent/models/einwilligung.dart';
import '../../consent/ui/einwilligungs_auswahl.dart';
import '../logic/onboarding_controller.dart';
import '../models/onboarding_profile.dart';

/// Onboarding: vier kurze Fragen plus Pflicht-Screen mit Datenschutzhinweis.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _seite = 0;

  static const _anzahlSeiten = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _weiter() {
    if (_seite == _anzahlSeiten - 1) {
      final ctrl = ref.read(onboardingControllerProvider.notifier);
      // Der alte Sammel-Haken bleibt als Vermerk stehen: „hat im Onboarding
      // zugestimmt". Der belastbare Nachweis liegt seit Phase 2.2 im
      // Einwilligungs-Controller.
      ctrl.setZustimmung(true);
      ctrl.abschliessen();
      // Was nicht angehakt wurde, gilt als gefragt und abgelehnt – sonst
      // schickt der Router direkt danach auf den Nachtrags-Screen.
      ref
          .read(einwilligungControllerProvider.notifier)
          .offeneAlsGefragtVermerken();
      ref
          .read(diagnoseDienstProvider)
          .melde(DiagnoseEreignis.onboardingAbgeschlossen);
      context.go(Routes.home);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _zurueck() => _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );

  /// Pro Seite pruefen, ob weitergeblaettert werden darf.
  ///
  /// Auf der letzten Seite zaehlt nur noch die Pflichteinwilligung; die
  /// Foto-Einwilligung ist freiwillig und darf niemanden aufhalten.
  bool _darfWeiter(OnboardingProfile p, {required bool pflichtErteilt}) =>
      switch (_seite) {
        0 => true,
        1 => p.alter != null && p.budget != null,
        2 => p.zeit != null,
        3 => p.fokus.isNotEmpty,
        4 => pflichtErteilt,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final profil = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final pflichtErteilt = !ref.watch(pflichtEinwilligungFehltProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Fortschritt(seite: _seite, gesamt: _anzahlSeiten),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _seite = i),
                children: [
                  const _WillkommenSeite(),
                  _AlterBudgetSeite(profil: profil, ctrl: ctrl),
                  _ZeitSeite(profil: profil, ctrl: ctrl),
                  _FokusSeite(profil: profil, ctrl: ctrl),
                  const _DatenschutzSeite(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gapM,
                AppTheme.gapS,
                AppTheme.gapM,
                AppTheme.gapM,
              ),
              child: Row(
                children: [
                  // Feste Breite: die Buttons im Theme setzen minimumSize ueber
                  // Size.fromHeight, was in einer Row sonst unendliche Breite
                  // anfordert.
                  if (_seite > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: AppTheme.gapS),
                      child: SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: _zurueck,
                          child: Text(texte.zurueck),
                        ),
                      ),
                    ),
                  Expanded(
                    child: FilledButton(
                      onPressed: _darfWeiter(profil, pflichtErteilt: pflichtErteilt)
                          ? _weiter
                          : null,
                      child: Text(
                        _seite == _anzahlSeiten - 1 ? 'Los geht es' : texte.weiter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.seite, required this.gesamt});

  final int seite;
  final int gesamt;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gapM,
        AppTheme.gapM,
        AppTheme.gapM,
        AppTheme.gapS,
      ),
      child: Row(
        children: List.generate(gesamt, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              margin: EdgeInsets.only(right: i == gesamt - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= seite ? farben.akzent : farben.rand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Gemeinsames Geruest einer Onboarding-Seite: Titel, Beschreibung, Inhalt.
class _Seite extends StatelessWidget {
  const _Seite({
    required this.titel,
    required this.text,
    required this.children,
  });

  final String titel;
  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gapM,
        AppTheme.gapM,
        AppTheme.gapM,
        AppTheme.gapL,
      ),
      children: [
        Text(
          titel,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(text),
        const SizedBox(height: AppTheme.gapL),
        ...children,
      ],
    );
  }
}

class _WillkommenSeite extends StatelessWidget {
  const _WillkommenSeite();

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return _Seite(
      titel: texte.onbWillkommenTitel,
      text: texte.onbWillkommenText,
      children: [
        SectionCard(
          child: Column(
            children: [
              _Punkt(
                icon: Icons.photo_camera_outlined,
                text: texte.onbPunktFotos,
              ),
              SizedBox(height: AppTheme.gapM),
              _Punkt(
                icon: Icons.auto_awesome_outlined,
                text: texte.onbPunktAnalyse,
              ),
              SizedBox(height: AppTheme.gapM),
              _Punkt(
                icon: Icons.checklist_rtl_outlined,
                text: texte.onbPunktPlan,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Punkt extends StatelessWidget {
  const _Punkt({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: farben.akzent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: farben.akzent, size: 20),
        ),
        const SizedBox(width: AppTheme.gapS),
        Expanded(
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _AlterBudgetSeite extends StatelessWidget {
  const _AlterBudgetSeite({required this.profil, required this.ctrl});

  final OnboardingProfile profil;
  final OnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return _Seite(
      titel: texte.onbAlterTitel,
      text: texte.onbAlterText,
      children: [
        Wrap(
          spacing: AppTheme.gapS,
          runSpacing: AppTheme.gapS,
          children: [
            for (final a in Altersbereich.values)
              _Chip(
                label: a.label(texte),
                aktiv: profil.alter == a,
                onTap: () => ctrl.setAlter(a),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.gapL),
        Text(
          texte.onbBudgetTitel,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapXs),
        MutedText(texte.onbBudgetText),
        const SizedBox(height: AppTheme.gapM),
        for (final b in Budget.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.gapS),
            child: _Auswahlkarte(
              titel: b.label(texte),
              untertitel: b.beschreibung(texte),
              aktiv: profil.budget == b,
              onTap: () => ctrl.setBudget(b),
            ),
          ),
      ],
    );
  }
}

class _ZeitSeite extends StatelessWidget {
  const _ZeitSeite({required this.profil, required this.ctrl});

  final OnboardingProfile profil;
  final OnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return _Seite(
      titel: texte.onbZeitTitel,
      text: texte.onbZeitText,
      children: [
        for (final z in Zeitbudget.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.gapS),
            child: _Auswahlkarte(
              titel: z.label(texte),
              untertitel: z.beschreibung(texte),
              aktiv: profil.zeit == z,
              onTap: () => ctrl.setZeit(z),
            ),
          ),
      ],
    );
  }
}

class _FokusSeite extends StatelessWidget {
  const _FokusSeite({required this.profil, required this.ctrl});

  final OnboardingProfile profil;
  final OnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return _Seite(
      titel: texte.onbFokusTitel,
      text: texte.onbFokusText,
      children: [
        for (final f in Fokusbereich.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.gapS),
            child: _Auswahlkarte(
              titel: f.label(texte),
              aktiv: profil.fokus.contains(f),
              mehrfach: true,
              onTap: () => ctrl.toggleFokus(f),
            ),
          ),
      ],
    );
  }
}

/// Die Einwilligungsseite des Onboardings.
///
/// Seit Phase 2.2 zwei getrennte Haekchen statt eines Sammel-Hakens: Die
/// Nutzung der App und die Verarbeitung von Gesichtsfotos durch einen
/// KI-Dienst sind rechtlich zwei Paar Schuhe. Nur das erste ist Pflicht.
class _DatenschutzSeite extends StatelessWidget {
  const _DatenschutzSeite();

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return _Seite(
      titel: texte.onbDatenschutzTitel,
      text: texte.onbDatenschutzText,
      children: [
        SectionCard(
          title: texte.onbKeineMedizin,
          icon: Icons.medical_information_outlined,
          child: MutedText(texte.disclaimerMedizin),
        ),
        SizedBox(height: AppTheme.gapS),
        SectionCard(
          title: texte.onbUmgangFotos,
          icon: Icons.lock_outline,
          child: MutedText(texte.disclaimerFotos),
        ),
        SizedBox(height: AppTheme.gapM),
        EinwilligungsAuswahl(kanal: Einwilligungskanal.onboarding),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.aktiv, required this.onTap});

  final String label;
  final bool aktiv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: aktiv
              ? farben.akzent.withValues(alpha: 0.14)
              : farben.flaeche,
          border: Border.all(color: aktiv ? farben.akzent : farben.rand),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: aktiv ? farben.akzent : farben.textPrimaer,
          ),
        ),
      ),
    );
  }
}

class _Auswahlkarte extends StatelessWidget {
  const _Auswahlkarte({
    required this.titel,
    required this.aktiv,
    required this.onTap,
    this.untertitel,
    this.mehrfach = false,
  });

  final String titel;
  final String? untertitel;
  final bool aktiv;
  final bool mehrfach;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppTheme.gapM),
        decoration: BoxDecoration(
          color: aktiv
              ? farben.akzent.withValues(alpha: 0.10)
              : farben.flaeche,
          border: Border.all(color: aktiv ? farben.akzent : farben.rand),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (untertitel != null) ...[
                    const SizedBox(height: 2),
                    MutedText(untertitel!),
                  ],
                ],
              ),
            ),
            Icon(
              mehrfach
                  ? (aktiv
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded)
                  : (aktiv
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
              color: aktiv ? farben.akzent : farben.textSekundaer,
            ),
          ],
        ),
      ),
    );
  }
}
