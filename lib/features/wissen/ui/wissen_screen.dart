import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/wissen_bibliothek.dart';
import '../models/wissenseintrag.dart';
import 'wissens_blatt.dart';

/// Die Wissens-Bibliothek zum Stöbern (DECISIONS 88).
///
/// Der Weg über das Info-Zeichen an einer Aufgabe deckt den Normalfall ab:
/// Man liest etwas und versteht es nicht. Dieser Bildschirm deckt den anderen
/// ab: Man will nachlesen, ohne dass gerade eine Aufgabe danebensteht – etwa
/// bevor man sich bei „Das will ich ausprobieren" für etwas entscheidet.
class WissenScreen extends ConsumerStatefulWidget {
  const WissenScreen({super.key});

  @override
  ConsumerState<WissenScreen> createState() => _WissenScreenState();
}

class _WissenScreenState extends ConsumerState<WissenScreen> {
  String _suche = '';

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final bibliothek =
        ref.watch(wissenProvider(texte.localeName)).valueOrNull;
    final alle = bibliothek?.eintraege ?? const <Wissenseintrag>[];

    final suche = _suche.trim().toLowerCase();
    final gefunden = suche.isEmpty
        ? alle
        : alle
            .where((e) =>
                e.namen.any((n) => n.toLowerCase().contains(suche)) ||
                e.wasIstDas.toLowerCase().contains(suche))
            .toList();

    return AppPage(
      title: texte.wissenTitel,
      children: [
        MutedText(texte.wissenText),
        const SizedBox(height: AppTheme.gapM),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: texte.wissenSuche,
            filled: true,
            fillColor: context.farben.flaecheHoch,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (wert) => setState(() => _suche = wert),
        ),
        const SizedBox(height: AppTheme.gapM),
        if (gefunden.isEmpty)
          MutedText(alle.isEmpty ? texte.wissenLaedt : texte.wissenLeer)
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXs),
            child: Column(
              children: [
                for (final (nummer, eintrag) in gefunden.indexed) ...[
                  if (nummer > 0)
                    const Divider(
                      height: 1,
                      indent: AppTheme.gapM,
                      endIndent: AppTheme.gapM,
                    ),
                  _Zeile(eintrag: eintrag),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppTheme.gapM),
      ],
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({required this.eintrag});

  final Wissenseintrag eintrag;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return InkWell(
      onTap: () => zeigeWissensblatt(context, eintrag),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gapM,
          vertical: AppTheme.gapS,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eintrag.titel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eintrag.wieOft,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: farben.textSekundaer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: farben.textSekundaer,
            ),
          ],
        ),
      ),
    );
  }
}
