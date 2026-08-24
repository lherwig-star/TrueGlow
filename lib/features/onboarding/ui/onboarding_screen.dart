import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
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
      ref.read(onboardingControllerProvider.notifier).abschliessen();
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
  bool _darfWeiter(OnboardingProfile p) => switch (_seite) {
        0 => true,
        1 => p.alter != null && p.budget != null,
        2 => p.zeit != null,
        3 => p.fokus.isNotEmpty,
        4 => p.zugestimmt,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

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
                  _DatenschutzSeite(profil: profil, ctrl: ctrl),
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
                          child: const Text(S.zurueck),
                        ),
                      ),
                    ),
                  Expanded(
                    child: FilledButton(
                      onPressed: _darfWeiter(profil) ? _weiter : null,
                      child: Text(
                        _seite == _anzahlSeiten - 1 ? 'Los geht es' : S.weiter,
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
    return const _Seite(
      titel: S.onbWillkommenTitel,
      text: S.onbWillkommenText,
      children: [
        SectionCard(
          child: Column(
            children: [
              _Punkt(
                icon: Icons.photo_camera_outlined,
                text: 'Zwei Fotos aufnehmen',
              ),
              SizedBox(height: AppTheme.gapM),
              _Punkt(
                icon: Icons.auto_awesome_outlined,
                text: 'KI-Analyse deiner Merkmale',
              ),
              SizedBox(height: AppTheme.gapM),
              _Punkt(
                icon: Icons.checklist_rtl_outlined,
                text: 'Konkreter Plan mit Checkliste',
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
    return _Seite(
      titel: S.onbAlterTitel,
      text: S.onbAlterText,
      children: [
        Wrap(
          spacing: AppTheme.gapS,
          runSpacing: AppTheme.gapS,
          children: [
            for (final a in Altersbereich.values)
              _Chip(
                label: a.label,
                aktiv: profil.alter == a,
                onTap: () => ctrl.setAlter(a),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.gapL),
        const Text(
          S.onbBudgetTitel,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapXs),
        const MutedText(S.onbBudgetText),
        const SizedBox(height: AppTheme.gapM),
        for (final b in Budget.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.gapS),
            child: _Auswahlkarte(
              titel: b.label,
              untertitel: b.beschreibung,
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
    return _Seite(
      titel: S.onbZeitTitel,
      text: S.onbZeitText,
      children: [
        for (final z in Zeitbudget.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.gapS),
            child: _Auswahlkarte(
              titel: z.label,
              untertitel: z.beschreibung,
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
    return _Seite(
      titel: S.onbFokusTitel,
      text: S.onbFokusText,
      children: [
        for (final f in Fokusbereich.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.gapS),
            child: _Auswahlkarte(
              titel: f.label,
              aktiv: profil.fokus.contains(f),
              mehrfach: true,
              onTap: () => ctrl.toggleFokus(f),
            ),
          ),
      ],
    );
  }
}

class _DatenschutzSeite extends StatelessWidget {
  const _DatenschutzSeite({required this.profil, required this.ctrl});

  final OnboardingProfile profil;
  final OnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    return _Seite(
      titel: S.onbDatenschutzTitel,
      text: 'Bitte lies die folgenden Hinweise, bevor es losgeht.',
      children: [
        const SectionCard(
          title: 'Keine medizinische Beratung',
          icon: Icons.medical_information_outlined,
          child: MutedText(S.disclaimerMedizin),
        ),
        const SizedBox(height: AppTheme.gapS),
        const SectionCard(
          title: 'Umgang mit deinen Fotos',
          icon: Icons.lock_outline,
          child: MutedText(S.disclaimerFotos),
        ),
        const SizedBox(height: AppTheme.gapM),
        InkWell(
          onTap: () => ctrl.setZustimmung(!profil.zugestimmt),
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.gapXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: profil.zugestimmt,
                  onChanged: (v) => ctrl.setZustimmung(v ?? false),
                ),
                const SizedBox(width: AppTheme.gapXs),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(S.disclaimerZustimmung),
                  ),
                ),
              ],
            ),
          ),
        ),
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
