import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../capture/models/aufnahme_typ.dart';
import '../../models/analyse_modul.dart';
import '../../../onboarding/logic/onboarding_controller.dart';
import '../../../../core/l10n/texte.dart';

/// Karte eines Analyse-Moduls.
///
/// Wird zweimal verwendet: im Auswahlscreen vor der Aufnahme und unter
/// "Analyse erweitern" auf dem Ergebnis-Screen. Deshalb ist die Checkbox
/// optional – beim Erweitern startet ein Tipp direkt den Flow.
class ModulKarte extends ConsumerWidget {
  const ModulKarte({
    super.key,
    required this.modul,
    required this.onTap,
    this.ausgewaehlt = false,
    this.mitCheckbox = true,
    this.badge,
    this.aktion,
  });

  final AnalyseModul modul;
  final VoidCallback? onTap;
  final bool ausgewaehlt;
  final bool mitCheckbox;

  /// Kleines Label rechts oben, z. B. "Basis".
  final String? badge;

  /// Ersetzt die Checkbox, etwa durch einen Pfeil beim Erweitern.
  final Widget? aktion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ref.watch(ausrichtungProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppTheme.gapM),
          // Dieselbe Flaeche und dieselbe Kontur wie jede andere Karte der
          // App – nur eben handgebaut, weil der Auswahlzustand mitanimiert
          // wird. Die Werte kommen aus dem Theme, damit sie nicht wieder
          // auseinanderlaufen (DECISIONS 51).
          decoration: BoxDecoration(
            color: ausgewaehlt
                ? Color.alphaBlend(
                    farben.erreichtFlaeche.withValues(alpha: 0.10),
                    Theme.of(context).cardTheme.color ?? farben.flaeche,
                  )
                : Theme.of(context).cardTheme.color ?? farben.flaeche,
            border: Border.all(
              color: ausgewaehlt
                  ? farben.erreichtFlaeche
                  : farben.kartenrand,
              width: ausgewaehlt ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: farben.akzent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(modul.icon, size: 22, color: farben.akzent),
              ),
              const SizedBox(width: AppTheme.gapS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            modul.titel(texte, ausrichtung),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null) _Badge(text: badge!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modul.beschreibung(texte, ausrichtung),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: farben.textSekundaer,
                      ),
                    ),
                    const SizedBox(height: AppTheme.gapXs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 14,
                          // Primaer-Akzent statt Sekundaerton: Der Sekundaerton
                          // erreicht auf der Karte keine 4,5:1.
                          color: farben.akzent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            modul.benoetigt(texte, ausrichtung),
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: farben.akzent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (aktion != null) ...[
                const SizedBox(width: AppTheme.gapXs),
                aktion!,
              ] else if (mitCheckbox) ...[
                const SizedBox(width: AppTheme.gapXs),
                _Haken(aktiv: ausgewaehlt),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: farben.akzent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: farben.akzent,
        ),
      ),
    );
  }
}

class _Haken extends StatelessWidget {
  const _Haken({required this.aktiv});

  final bool aktiv;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: aktiv ? farben.erreichtFlaeche : Colors.transparent,
        border: Border.all(
          color: aktiv ? farben.erreichtFlaeche : farben.textSekundaer,
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: aktiv
          ? Icon(Icons.check, size: 18, color: farben.aufErreicht)
          : null,
    );
  }
}
