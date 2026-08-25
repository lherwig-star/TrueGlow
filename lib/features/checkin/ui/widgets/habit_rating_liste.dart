import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auswahl_chip.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/checkin_controller.dart';
import '../../models/checkin.dart';

/// Das 3-Tap-Rating aller abgefragten Habits als kompakte Liste.
///
/// Bewusst eine Liste statt ein Habit pro Screen: Der ganze Check-in soll
/// unter einer Minute bleiben, und die Ratings sind mit einem Blick zu
/// ueberschauen. Die Nachfrage nach dem Grund klappt direkt unter dem
/// betroffenen Habit auf – kein Sprung, kein Kontextverlust.
class HabitRatingListe extends ConsumerWidget {
  const HabitRatingListe({
    super.key,
    required this.checkin,
    required this.habits,
    this.nurNachzufragen = false,
  });

  final Checkin checkin;
  final List<String> habits;

  /// Ob nur die Wackelkandidaten des letzten Mals abgefragt werden.
  final bool nurNachzufragen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final ctrl = ref.read(checkinControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texte.checkinHabitsTitel,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(
          nurNachzufragen ? texte.checkinHabitsErneut : texte.checkinHabitsText,
        ),
        const SizedBox(height: AppTheme.gapM),
        for (final habit in habits) ...[
          _HabitKarte(
            habit: habit,
            feedback: checkin.feedbackZu(habit),
            onBewertung: (bewertung) =>
                ctrl.entwurfSichern(checkin.mitBewertung(habit, bewertung)),
            onGrund: (grund) =>
                ctrl.entwurfSichern(checkin.mitGrund(habit, grund)),
            onNotiz: (notiz) => ctrl.entwurfSichern(
              checkin.mitGrund(
                habit,
                checkin.feedbackZu(habit)?.grund,
                notiz: notiz,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
      ],
    );
  }
}

class _HabitKarte extends StatelessWidget {
  const _HabitKarte({
    required this.habit,
    required this.feedback,
    required this.onBewertung,
    required this.onGrund,
    required this.onNotiz,
  });

  final String habit;
  final HabitFeedback? feedback;
  final ValueChanged<HabitBewertung> onBewertung;
  final ValueChanged<PasstNichtGrund?> onGrund;
  final ValueChanged<String> onNotiz;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final gewaehlt = feedback?.bewertung;

    return SectionCard(
      padding: const EdgeInsets.all(AppTheme.gapS + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            habit,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: AppTheme.gapS),
          Row(
            children: [
              for (final bewertung in HabitBewertung.values) ...[
                Expanded(
                  child: _RatingKnopf(
                    bewertung: bewertung,
                    aktiv: gewaehlt == bewertung,
                    onTap: () => onBewertung(bewertung),
                  ),
                ),
                if (bewertung != HabitBewertung.values.last)
                  const SizedBox(width: AppTheme.gapXs),
              ],
            ],
          ),
          if (gewaehlt?.brauchtGrund ?? false) ...[
            const SizedBox(height: AppTheme.gapM),
            Text(
              texte.checkinGrundTitel,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.gapS),
            Wrap(
              spacing: AppTheme.gapXs,
              runSpacing: AppTheme.gapXs,
              children: [
                for (final grund in PasstNichtGrund.values)
                  AuswahlChip(
                    label: grund.label(texte),
                    aktiv: feedback?.grund == grund,
                    // Nochmal tippen hebt die Auswahl wieder auf.
                    onTap: () =>
                        onGrund(feedback?.grund == grund ? null : grund),
                  ),
              ],
            ),
            if (feedback?.grund == PasstNichtGrund.anderer) ...[
              const SizedBox(height: AppTheme.gapS),
              _Freitext(text: feedback?.notiz ?? '', onNotiz: onNotiz),
            ],
          ],
        ],
      ),
    );
  }
}

/// Ein Rating-Knopf. Gross genug zum schnellen Tippen, ohne die Zeile zu
/// sprengen.
class _RatingKnopf extends StatelessWidget {
  const _RatingKnopf({
    required this.bewertung,
    required this.aktiv,
    required this.onTap,
  });

  final HabitBewertung bewertung;
  final bool aktiv;
  final VoidCallback onTap;

  IconData get _icon => switch (bewertung) {
        HabitBewertung.laeuftGut => Icons.sentiment_satisfied_alt_outlined,
        HabitBewertung.gehtSo => Icons.sentiment_neutral_outlined,
        HabitBewertung.passtNicht => Icons.sentiment_dissatisfied_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return Semantics(
      button: true,
      selected: aktiv,
      label: bewertung.label(texte),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: AnimatedContainer(
          duration:
              AppTheme.animation(context, const Duration(milliseconds: 180)),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.gapS),
          decoration: BoxDecoration(
            color: aktiv
                ? farben.akzent.withValues(alpha: 0.18)
                : farben.flaecheHoch,
            border: Border.all(color: aktiv ? farben.akzent : farben.rand),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          child: Column(
            children: [
              Icon(
                _icon,
                size: 22,
                color: aktiv ? farben.akzent : farben.textSekundaer,
              ),
              const SizedBox(height: 4),
              Text(
                bewertung.label(texte),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: aktiv ? farben.textPrimaer : farben.textSekundaer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optionaler Freitext zum Grund "Anderer Grund".
class _Freitext extends StatefulWidget {
  const _Freitext({required this.text, required this.onNotiz});

  final String text;
  final ValueChanged<String> onNotiz;

  @override
  State<_Freitext> createState() => _FreitextState();
}

class _FreitextState extends State<_Freitext> {
  late final TextEditingController _feld =
      TextEditingController(text: widget.text);

  @override
  void dispose() {
    _feld.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return TextField(
      controller: _feld,
      onChanged: widget.onNotiz,
      maxLines: 3,
      minLines: 2,
      maxLength: 240,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(height: 1.4),
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          const SizedBox.shrink(),
      decoration: InputDecoration(
        hintText: texte.checkinGrundFreitext,
        hintStyle: TextStyle(color: farben.textSekundaer),
        filled: true,
        fillColor: farben.flaecheHoch,
        contentPadding: const EdgeInsets.all(AppTheme.gapS),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          borderSide: BorderSide(color: farben.rand),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          borderSide: BorderSide(color: farben.akzent, width: 1.6),
        ),
      ),
    );
  }
}
