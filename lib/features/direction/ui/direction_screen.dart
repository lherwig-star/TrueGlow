import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/auswahl_chip.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/direction_controller.dart';
import '../models/richtung.dart';

/// Optionaler Schritt zwischen Modul-Auswahl und Aufnahme: Der Nutzer gibt
/// der Analyse eigene Ziele mit.
///
/// Zwei Betriebsarten: im Flow (Weiter fuehrt in die Aufnahme, oben rechts
/// laesst sich der Schritt ueberspringen) und als nachtraegliche Bearbeitung
/// aus dem Report heraus, die einfach wieder zurueckspringt.
class DirectionScreen extends ConsumerStatefulWidget {
  const DirectionScreen({super.key, this.bearbeiten = false});

  /// true = aus dem Report aufgerufen, es geht danach dorthin zurueck.
  final bool bearbeiten;

  @override
  ConsumerState<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends ConsumerState<DirectionScreen> {
  late final TextEditingController _feld = TextEditingController(
    text: ref.read(directionControllerProvider).freitext,
  );

  @override
  void dispose() {
    _feld.dispose();
    super.dispose();
  }

  void _weiter() {
    if (widget.bearbeiten) {
      context.pop();
      return;
    }
    context.push(Routes.aufnahme);
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final richtung = ref.watch(directionControllerProvider);
    final ctrl = ref.read(directionControllerProvider.notifier);
    final farben = context.farben;

    return AppPage(
      title: texte.richtungTitel,
      bottomFade: true,
      actions: widget.bearbeiten
          ? null
          : [
              TextButton(
                onPressed: _weiter,
                child: Text(texte.flowUeberspringen),
              ),
            ],
      bottomBar: FilledButton(
        onPressed: _weiter,
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
        child: Text(
          widget.bearbeiten ? texte.richtungSpeichern : texte.richtungWeiter,
        ),
      ),
      children: [
        Text(
          texte.richtungEyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: farben.akzent,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        Text(
          texte.richtungUeberschrift,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        MutedText(texte.richtungEinleitung),
        const SizedBox(height: AppTheme.gapL),

        // --- Teil A: gefuehrte Auswahl ---
        Text(
          texte.richtungChipsTitel,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        MutedText(texte.richtungChipsText),
        const SizedBox(height: AppTheme.gapS),
        Wrap(
          spacing: AppTheme.gapS,
          runSpacing: AppTheme.gapS,
          children: [
            for (final ziel in Richtungsziel.values)
              AuswahlChip(
                label: ziel.label(texte),
                // Ohne den Untertext ist „Smart & hochwertig" fuer jemanden
                // ohne Modewissen eine leere Huelle (DECISIONS 58).
                untertext: ziel.untertext(texte),
                aktiv: richtung.ziele.contains(ziel),
                onTap: () => ctrl.umschalten(ziel),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.gapL),

        // --- Teil B: Freitext ---
        Text(
          texte.richtungFreitextTitel,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapS),
        _Nachrichtenfeld(controller: _feld, onChanged: ctrl.setzeFreitext),
        const SizedBox(height: AppTheme.gapS),
        SectionCard(
          title: texte.richtungBleibtLokal,
          icon: Icons.lock_outline,
          child: MutedText(texte.richtungFreitextHinweis),
        ),
      ],
    );
  }
}

/// Der Freitext als Nachricht an den Coach: Sprechblase mit Absender-Zeile
/// und Zeichenzaehler.
class _Nachrichtenfeld extends StatelessWidget {
  const _Nachrichtenfeld({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.forum_outlined, size: 16, color: farben.akzent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Deine Nachricht an den Coach',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: farben.akzent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.gapXs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 6,
          minLines: 4,
          maxLength: Richtung.maxZeichen,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          inputFormatters: [
            LengthLimitingTextInputFormatter(Richtung.maxZeichen),
          ],
          style: const TextStyle(height: 1.5),
          // Der eigene Zaehler haelt sich an die Textrollen des Themes; der
          // eingebaute waere hier ein Fremdkoerper.
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              Text(
            '$currentLength / ${maxLength ?? Richtung.maxZeichen}',
            style: TextStyle(fontSize: 12, color: farben.textSekundaer),
          ),
          decoration: InputDecoration(
            hintText: texte.richtungFreitextPlatzhalter,
            hintStyle: TextStyle(color: farben.textSekundaer, height: 1.5),
            filled: true,
            fillColor: farben.flaeche,
            contentPadding: const EdgeInsets.all(AppTheme.gapS + 2),
            // Eckig angesetzt oben links: die Blase "kommt" aus der
            // Absenderzeile darueber.
            enabledBorder: _rahmen(farben.rand),
            focusedBorder: _rahmen(farben.akzent, breite: 1.6),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _rahmen(Color farbe, {double breite = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(AppTheme.radiusCard),
        bottomLeft: Radius.circular(AppTheme.radiusCard),
        bottomRight: Radius.circular(AppTheme.radiusCard),
      ),
      borderSide: BorderSide(color: farbe, width: breite),
    );
  }
}
