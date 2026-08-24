import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../../legal/ui/rechtstexte_zeile.dart';
import '../logic/einwilligung_controller.dart';
import '../models/einwilligung.dart';

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
                      art.titel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: farben.textPrimaer,
                      ),
                    ),
                    const SizedBox(height: AppTheme.gapXs),
                    MutedText(erklaerung(art)),
                    if (!art.pflicht) ...[
                      const SizedBox(height: AppTheme.gapXs),
                      MutedText(freiwilligkeitshinweis(art)),
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
  static String erklaerung(Einwilligungsart art) => switch (art) {
        Einwilligungsart.mindestalter =>
          'TrueGlow verarbeitet Aufnahmen deines Gesichts und richtet sich '
              'deshalb ausschließlich an Erwachsene. Mit dem Häkchen '
              'bestätigst du, dass du volljährig bist.',
        Einwilligungsart.nutzung =>
          'Ich habe die Nutzungsbedingungen und die Datenschutzerklärung '
              'gelesen und stimme ihnen zu.',
        Einwilligungsart.fotoKi =>
          'Ich willige ein, dass meine Fotos – darunter Aufnahmen meines '
              'Gesichts – zur Auswertung an den KI-Dienst Google Gemini '
              'übermittelt werden. Die Verarbeitung findet auf Servern von '
              'Google statt, auch außerhalb der EU (Drittlandtransfer). Die '
              'Bilder werden dort nicht gespeichert und nicht protokolliert.',
      };

  static String freiwilligkeitshinweis(Einwilligungsart art) => switch (art) {
        Einwilligungsart.fotoKi =>
          'Freiwillig und jederzeit in den Einstellungen widerrufbar. Ohne '
              'diese Einwilligung sind keine neuen Analysen möglich – alles '
              'andere funktioniert weiter, bestehende Reports bleiben.',
        Einwilligungsart.mindestalter =>
          'Ohne Bestätigung bleibt der Analyse-Bereich zu. Plan, Checklisten '
              'und Check-ins kannst du trotzdem nutzen.',
        Einwilligungsart.nutzung => '',
      };
}
