import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/einwilligung_controller.dart';
import '../models/einwilligung.dart';
import 'einwilligungs_auswahl.dart';

/// Holt die Einwilligung nach, wenn sie fehlt oder veraltet ist.
///
/// Zwei Faelle führen hierher:
///
/// - **Bestandsnutzer.** Sie haben früher eine einzelne Sammel-Checkbox
///   angehakt — ohne Zeitstempel, ohne Textversion, ohne Trennung zwischen
///   Nutzung und Fotoverarbeitung. Dieser Nachweis trägt nicht; sie werden
///   einmalig durch die neue Einwilligung geführt.
/// - **Neue Textversion.** Ändern sich die Rechtstexte inhaltlich, bezieht
///   sich die alte Zustimmung auf etwas anderes als das, was jetzt gilt.
class EinwilligungScreen extends ConsumerWidget {
  const EinwilligungScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final ausAlterZustimmung = ref.watch(ausAlterZustimmungProvider);
    final pflichtFehlt = ref.watch(pflichtEinwilligungFehltProvider);

    return AppPage(
      title: 'Kurz bestätigen',
      showBackButton: false,
      bottomBar: FilledButton(
        onPressed: pflichtFehlt
            ? null
            : () {
                // Was offen geblieben ist, gilt als gefragt und abgelehnt –
                // sonst landet dieselbe Person beim naechsten Start wieder
                // hier.
                ref
                    .read(einwilligungControllerProvider.notifier)
                    .offeneAlsGefragtVermerken();
                context.go(Routes.home);
              },
        child: Text(texte.weiter),
      ),
      children: [
        SectionCard(
          title: ausAlterZustimmung
              ? 'Wir haben nachgeschärft'
              : 'Neue Fassung der Texte',
          icon: Icons.fact_check_outlined,
          child: MutedText(
            ausAlterZustimmung
                ? 'Bisher gab es ein einzelnes Häkchen für alles. Weil deine '
                    'Fotos etwas anderes sind als die Nutzung der App, fragen '
                    'wir beides jetzt getrennt — einmalig und danach nie '
                    'wieder.'
                : 'Unsere Rechtstexte haben sich geändert. Damit deine '
                    'Zustimmung sich auf das bezieht, was tatsächlich gilt, '
                    'bitten wir dich einmal um Bestätigung.',
          ),
        ),
        const SizedBox(height: AppTheme.gapM),
        const EinwilligungsAuswahl(kanal: Einwilligungskanal.nachtrag),
        const SizedBox(height: AppTheme.gapM),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
          child: MutedText(
            'Deine bisherigen Analysen, dein Plan und deine Serie bleiben '
            'unverändert erhalten.',
          ),
        ),
      ],
    );
  }
}
