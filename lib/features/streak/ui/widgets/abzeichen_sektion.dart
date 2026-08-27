import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../logic/streak_repository.dart';
import '../../models/abzeichen.dart';
import '../../../../core/l10n/texte.dart';

/// Die Meilensteine als waagerechte Reihe.
///
/// Früher eine Liste untereinander mit Titel und Beschreibung je Zeile — das
/// waren acht Zeilen, die den halben Bildschirm füllten und dabei fast nur
/// Gesperrtes zeigten. Als Reihe passen sie in eine Kartenhöhe, das
/// Erreichte steht vorn im Blick, und was fehlt, steht weiterhin darunter.
///
/// Die Beschreibung ist deshalb nicht verschwunden: Sie liegt auf dem
/// Abzeichen als Tooltip (langes Drücken) und wird von TalkBack mitgelesen.
class AbzeichenSektion extends ConsumerWidget {
  const AbzeichenSektion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final staende = ref.watch(abzeichenProvider);
    final rekord = ref.watch(streakProvider).rekord;
    final erreicht = staende.where((s) => s.erreicht).length;

    return SectionCard(
      title: texte.abzeichenSektionTitel,
      icon: Icons.emoji_events_outlined,
      trailing: Text(
        '$erreicht/${staende.length}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          // Gold nur, wenn wirklich etwas erreicht ist – eine goldene Null
          // wäre ein Versprechen ohne Deckung.
          color: erreicht > 0
              ? context.farben.erreicht
              : context.farben.textSekundaer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rekord > 0) ...[
            MutedText(texte.streakRekord(rekord)),
            const SizedBox(height: AppTheme.gapS),
          ],
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: staende.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppTheme.gapS),
              itemBuilder: (_, index) => _Abzeichen(stand: staende[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Abzeichen extends StatelessWidget {
  const _Abzeichen({required this.stand});

  final AbzeichenStand stand;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final erreicht = stand.erreicht;

    // Erreicht: Gold. Gesperrt: derselbe Grauton wie jeder Sekundärtext,
    // zusätzlich abgedunkelt. Kein Rot, kein Durchgestrichenes – gesperrt
    // heißt „noch nicht", nicht „verpasst".
    // Freigeschaltet: das warme Amber – Kreis, Zierring und Icon
    // entstehen daraus (DECISIONS 64). Gesperrt: derselbe Grauton wie
    // jeder Sekundaertext, zusaetzlich abgedunkelt.
    final farbe = erreicht
        ? farben.erreichtFlaeche
        : farben.textSekundaer.withValues(alpha: 0.55);

    return Tooltip(
      message: stand.abzeichen.beschreibung(texte),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: farbe.withValues(alpha: erreicht ? 0.16 : 0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: farbe.withValues(alpha: erreicht ? 0.7 : 0.25),
                    ),
                  ),
                  child: Icon(stand.abzeichen.icon, size: 26, color: farbe),
                ),
                if (!erreicht)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: farben.flaecheHoch,
                        shape: BoxShape.circle,
                        border: Border.all(color: farben.rand),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 11,
                        color: farben.textSekundaer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.gapXs),
            Text(
              stand.abzeichen.titel(texte),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: erreicht ? farben.textPrimaer : farben.textSekundaer,
              ),
            ),
            if (!erreicht) ...[
              const SizedBox(height: 2),
              Text(
                _fortschritt(stand, texte),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: farben.textSekundaer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Was einem noch nicht erreichten Abzeichen fehlt.
///
/// Der Satz haengt am Abzeichen: Bei „Alles freigeschaltet" sind es Module,
/// bei den Challenges Wochen, bei den Streak-Zielen Tage, und die erste
/// Analyse ist gar keine Zahl, sondern eine Aufforderung.
String _fortschritt(AbzeichenStand stand, L texte) => switch (stand.abzeichen) {
      Abzeichen.ersteAnalyse => texte.abzeichenErsteAnalyseOffen,
      Abzeichen.alleModule => texte.abzeichenNochModule(stand.fehlend),
      Abzeichen.challenges => texte.abzeichenNochChallenges(stand.fehlend),
      _ => texte.abzeichenNochTage(stand.fehlend),
    };
