import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/markdown_ansicht.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/rechtstexte.dart';
import 'rechtsdokument_texte.dart';
import '../../../core/l10n/texte.dart';

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
    final texte = context.texte;
    final quelle = Rechtstexte.quelle(dokument);

    return AppPage(
      title: dokument.titel(texte),
      children: [
        if (!quelle.hatAsset)
          SectionCard(
            title: texte.dokumentKeinTextTitel,
            icon: Icons.pending_outlined,
            child: MutedText(texte.dokumentKeinTextText),
          )
        else
          FutureBuilder<String>(
            future: rootBundle.loadString(quelle.asset!),
            builder: (context, stand) {
              if (stand.hasError) {
                return SectionCard(
                  title: texte.dokumentNichtLesbarTitel,
                  icon: Icons.error_outline,
                  child: MutedText(texte.dokumentNichtLesbarText),
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
