import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../legal/ui/rechtstexte_zeile.dart';
import '../logic/einwilligung_controller.dart';
import '../models/einwilligung.dart';
import '../../../core/l10n/texte.dart';

/// Alle Bestaetigungen zum Ankreuzen.
///
/// Steht im Onboarding, auf dem Nachtrags-Screen und – als einzelne Zeile –
/// in den Einstellungen und auf dem Alters-Hinweis. Eine Stelle, ein
/// Wortlaut: Sonst bestaetigt jemand an zwei Orten formal Verschiedenes.
class EinwilligungsAuswahl extends ConsumerWidget {
  const EinwilligungsAuswahl({required this.kanal, super.key});

  /// Wo die Entscheidung faellt – wandert in den Nachweis.
  final Einwilligungskanal kanal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final art in Einwilligungsart.values) ...[
          EinwilligungsHaken(art: art, kanal: kanal),
          if (art != Einwilligungsart.values.last)
            const SizedBox(height: AppTheme.gapS),
        ],
        const SizedBox(height: AppTheme.gapS),
        const RechtstexteZeile(),
      ],
    );
  }
}

/// Ein einzelnes Haekchen samt Erklaerung.
class EinwilligungsHaken extends ConsumerWidget {
  const EinwilligungsHaken({
    required this.art,
    required this.kanal,
    super.key,
  });

  final Einwilligungsart art;
  final Einwilligungskanal kanal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final gilt = ref.watch(einwilligungGiltProvider(art));

    void umschalten() => ref
        .read(einwilligungControllerProvider.notifier)
        .setzen(art, erteilt: !gilt, kanal: kanal);

    return SectionCard(
      padding: const EdgeInsets.all(AppTheme.gapS),
      child: InkWell(
        onTap: umschalten,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: gilt,
              onChanged: (_) => umschalten(),
            ),
            const SizedBox(width: AppTheme.gapXs),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      art.titel(texte),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: farben.textPrimaer,
                      ),
                    ),
                    const SizedBox(height: AppTheme.gapXs),
                    MutedText(erklaerung(art, texte)),
                    if (!art.pflicht) ...[
                      const SizedBox(height: AppTheme.gapXs),
                      MutedText(freiwilligkeitshinweis(art, texte)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Was genau bestaetigt wird.
  ///
  /// Der Drittlandbezug steht ausdruecklich drin: Gesichtsaufnahmen sind
  /// biometrienah, und die Uebermittlung an einen US-Anbieter ist der Punkt,
  /// den eine Einwilligung tragen muss.
  static String erklaerung(Einwilligungsart art, L texte) => switch (art) {
        Einwilligungsart.mindestalter => texte.erklaerungMindestalter,
        Einwilligungsart.nutzung => texte.erklaerungNutzung,
        Einwilligungsart.diagnose => texte.erklaerungDiagnose,
        Einwilligungsart.fotoKi => texte.erklaerungFotoKi,
      };

  static String freiwilligkeitshinweis(Einwilligungsart art, L texte) =>
      switch (art) {
        Einwilligungsart.fotoKi => texte.freiwilligFotoKi,
        Einwilligungsart.mindestalter => texte.freiwilligMindestalter,
        Einwilligungsart.diagnose => texte.freiwilligDiagnose,
        Einwilligungsart.nutzung => '',
      };
}
