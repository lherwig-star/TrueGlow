import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/checkin_controller.dart';
import '../../models/checkin.dart';

/// Die Wirkungsfragen als einfache Skala Besser / Gleich / Schlechter.
///
/// Beim Wirkungs-Check gibt es zusaetzlich ein Notizfeld pro Frage – dort
/// lohnt sich der Satz, den kein Ankreuzfeld einfaengt.
class WirkungsListe extends ConsumerWidget {
  const WirkungsListe({
    super.key,
    required this.checkin,
    required this.fragen,
  });

  final Checkin checkin;
  final List<WirkungsFrage> fragen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(checkinControllerProvider.notifier);
    final spaet = checkin.typ == CheckinTyp.wirkung;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spaet ? S.checkinWirkungTitelSpaet : S.checkinWirkungTitelFrueh,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(
          spaet ? S.checkinWirkungTextSpaet : S.checkinWirkungTextFrueh,
        ),
        const SizedBox(height: AppTheme.gapM),
        for (final frage in fragen) ...[
          _FrageKarte(
            frage: frage,
            gewaehlt: checkin.antwortZu(frage.id),
            notiz: checkin.wirkung
                .where((w) => w.frageId == frage.id)
                .map((w) => w.notiz)
                .firstOrNull,
            mitNotiz: spaet,
            onAntwort: (antwort) =>
                ctrl.entwurfSichern(checkin.mitWirkung(frage, antwort)),
            onNotiz: (notiz) =>
                ctrl.entwurfSichern(checkin.mitWirkungsnotiz(frage.id, notiz)),
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
      ],
    );
  }
}

class _FrageKarte extends StatelessWidget {
  const _FrageKarte({
    required this.frage,
    required this.gewaehlt,
    required this.notiz,
    required this.mitNotiz,
    required this.onAntwort,
    required this.onNotiz,
  });

  final WirkungsFrage frage;
  final WirkungsAntwort? gewaehlt;
  final String? notiz;
  final bool mitNotiz;
  final ValueChanged<WirkungsAntwort> onAntwort;
  final ValueChanged<String> onNotiz;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(AppTheme.gapS + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            frage.text,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: AppTheme.gapS),
          Row(
            children: [
              for (final antwort in WirkungsAntwort.values) ...[
                Expanded(
                  child: _SkalaKnopf(
                    antwort: antwort,
                    aktiv: gewaehlt == antwort,
                    onTap: () => onAntwort(antwort),
                  ),
                ),
                if (antwort != WirkungsAntwort.values.last)
                  const SizedBox(width: AppTheme.gapXs),
              ],
            ],
          ),
          if (mitNotiz && gewaehlt != null) ...[
            const SizedBox(height: AppTheme.gapS),
            _Notizfeld(text: notiz ?? '', onNotiz: onNotiz),
          ],
        ],
      ),
    );
  }
}

class _SkalaKnopf extends StatelessWidget {
  const _SkalaKnopf({
    required this.antwort,
    required this.aktiv,
    required this.onTap,
  });

  final WirkungsAntwort antwort;
  final bool aktiv;
  final VoidCallback onTap;

  IconData get _icon => switch (antwort) {
        WirkungsAntwort.besser => Icons.trending_up,
        WirkungsAntwort.gleich => Icons.trending_flat,
        WirkungsAntwort.schlechter => Icons.trending_down,
      };

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Semantics(
      button: true,
      selected: aktiv,
      label: antwort.label,
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
                size: 20,
                color: aktiv ? farben.akzent : farben.textSekundaer,
              ),
              const SizedBox(height: 4),
              Text(
                antwort.label,
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

class _Notizfeld extends StatefulWidget {
  const _Notizfeld({required this.text, required this.onNotiz});

  final String text;
  final ValueChanged<String> onNotiz;

  @override
  State<_Notizfeld> createState() => _NotizfeldState();
}

class _NotizfeldState extends State<_Notizfeld> {
  late final TextEditingController _feld =
      TextEditingController(text: widget.text);

  @override
  void dispose() {
    _feld.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return TextField(
      controller: _feld,
      onChanged: widget.onNotiz,
      maxLines: 3,
      minLines: 1,
      maxLength: 240,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(height: 1.4),
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          const SizedBox.shrink(),
      decoration: InputDecoration(
        hintText: S.checkinWirkungNotiz,
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
