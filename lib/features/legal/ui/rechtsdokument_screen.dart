import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/markdown_ansicht.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/rechtstexte.dart';

/// Zeigt einen Rechtstext in der App an.
///
/// Die Rückfallebene für den Fall, dass die Webseite nicht erreichbar ist —
/// und der Weg für alle, die einen Text lieber offline lesen. Die Quelle ist
/// eine Markdown-Datei aus dem Bundle, eingetragen in [Rechtstexte].
class RechtsdokumentScreen extends StatelessWidget {
  const RechtsdokumentScreen({required this.dokument, super.key});

  final Rechtsdokument dokument;

  @override
  Widget build(BuildContext context) {
    final quelle = Rechtstexte.quelle(dokument);

    return AppPage(
      title: dokument.titel,
      children: [
        if (!quelle.hatAsset)
          const SectionCard(
            title: 'Noch nicht verfügbar',
            icon: Icons.pending_outlined,
            child: MutedText(
              'Für dieses Dokument ist noch kein Text hinterlegt.',
            ),
          )
        else
          FutureBuilder<String>(
            future: rootBundle.loadString(quelle.asset!),
            builder: (context, stand) {
              if (stand.hasError) {
                return const SectionCard(
                  title: 'Text nicht lesbar',
                  icon: Icons.error_outline,
                  child: MutedText(
                    'Der hinterlegte Text lässt sich nicht laden. Bitte ruf '
                    'ihn über die Webseite auf.',
                  ),
                );
              }
              if (!stand.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(AppTheme.gapL),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return MarkdownAnsicht(stand.data!);
            },
          ),
        const SizedBox(height: AppTheme.gapM),
        MutedText('Textstand: Version ${Rechtstexte.version}'),
      ],
    );
  }
}
