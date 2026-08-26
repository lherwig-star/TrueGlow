import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/l10n/texte.dart';
import '../../../modules/models/analyse_modul.dart';
import '../../../onboarding/logic/onboarding_controller.dart';
import '../../../analysis/models/analysis_result.dart';
import '../../../checkin/logic/checkin_controller.dart';
import '../../logic/plan_progress_repository.dart';

/// Tages-Checkliste eines Report-Kapitels.
///
/// Eine Karte pro Kapitel statt einer gemeinsamen Liste: so kann per
/// Konstruktion keine Aufgabe aus einem nicht gewaehlten Modul auftauchen –
/// die Punkte haengen am Kapitel, und ein nicht gewaehltes Modul hat gar kein
/// Kapitel.
class ChecklisteKarte extends ConsumerWidget {
  const ChecklisteKarte({super.key, required this.kapitel});

  final Kapitel kapitel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final fortschritt = ref.watch(planFortschrittProvider);
    final neueHabits = ref.watch(neueHabitsProvider);

    final erledigt =
        kapitel.habits.where(fortschritt.erledigt.contains).length;
    final alleErledigt = erledigt == kapitel.habits.length;

    return SectionCard(
      title: kapitel.modul.checkliste(texte, ref.watch(ausrichtungProvider)),
      icon: kapitel.modul.icon,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: (alleErledigt ? farben.erreicht : farben.textSekundaer)
              .withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$erledigt/${kapitel.habits.length}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            // Gold erst, wenn die Liste steht – ein halb voller Zaehler ist
            // kein Erreichtes (DECISIONS 50).
            color: alleErledigt ? farben.erreicht : farben.textSekundaer,
          ),
        ),
      ),
      child: Column(
        children: [
          for (final habit in kapitel.habits)
            HabitZeile(
              text: habit,
              erledigt: fortschritt.erledigt.contains(habit),
              hinweis: neueHabits[habit],
              onTap: () =>
                  ref.read(planFortschrittProvider.notifier).umschalten(habit),
            ),
        ],
      ),
    );
  }
}

/// Der Haken einer Zeile – gesetzt in Gold, mit kurzem Einzoomen.
///
/// Die Bewegung dauert 220 ms und laeuft nur beim Setzen, nicht beim
/// Entfernen: Gefeiert wird das Abhaken, nicht das Zuruecknehmen. Bei
/// „Bewegung reduzieren" wechselt nur die Farbe.
class _Haken extends StatefulWidget {
  const _Haken({required this.erledigt});

  final bool erledigt;

  @override
  State<_Haken> createState() => _HakenState();
}

class _HakenState extends State<_Haken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _puls = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didUpdateWidget(_Haken alt) {
    super.didUpdateWidget(alt);
    if (widget.erledigt && !alt.erledigt) {
      MediaQuery.disableAnimationsOf(context)
          ? _puls.value = 1
          : _puls.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _puls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AnimatedBuilder(
      animation: _puls,
      builder: (context, kind) {
        // Einmal auf 1,25 und zurueck – die Spitze liegt in der Mitte der
        // Bewegung, deshalb der Abstand zum Scheitel.
        final wert = _puls.value;
        final skala = 1 + 0.25 * (1 - (wert * 2 - 1).abs());
        return Transform.scale(scale: wert == 0 ? 1 : skala, child: kind);
      },
      child: Icon(
        widget.erledigt
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked,
        color: widget.erledigt ? farben.erreicht : farben.textSekundaer,
        size: 22,
      ),
    );
  }
}

/// Eine abhakbare Zeile. Der Fortschritt liegt in Hive und setzt sich am
/// naechsten Tag von selbst zurueck – der Schluessel ist das Datum.
class HabitZeile extends StatelessWidget {
  const HabitZeile({
    super.key,
    required this.text,
    required this.erledigt,
    required this.onTap,
    this.hinweis,
  });

  final String text;
  final bool erledigt;
  final VoidCallback onTap;

  /// Dezente Markierung frisch angepasster Aufgaben ("Neu ab heute").
  final String? hinweis;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXs),
        child: Row(
          children: [
            _Haken(erledigt: erledigt),
            const SizedBox(width: AppTheme.gapS),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  height: 1.4,
                  color: erledigt ? farben.textSekundaer : farben.textPrimaer,
                  decoration: erledigt ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (hinweis case final text?) ...[
              const SizedBox(width: AppTheme.gapXs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: farben.akzent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: farben.textPrimaer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
