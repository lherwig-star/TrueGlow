import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../wissen/ui/wissens_blatt.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/l10n/texte.dart';
import '../../../modules/models/analyse_modul.dart';
import '../../../onboarding/logic/onboarding_controller.dart';
import '../../../checkin/logic/checkin_controller.dart';
import '../../logic/plan_progress_repository.dart';
import '../../logic/tagesabschnitt.dart';

/// Die Aufgaben eines Tagesabschnitts – „Morgens", „Abends", …
///
/// Bis DECISIONS 70 stand hier eine Karte je Kapitel. Das war ordentlich
/// sortiert nach Thema und unbrauchbar sortiert nach Tag: Innerhalb von
/// „Haare & Bart" sprang die Liste vom Zubettgehen zurueck zum Fruehstueck.
/// Jetzt gruppiert der Wenn-dann-Anker, und das Thema steht als Abzeichen an
/// der Zeile.
///
/// Was sich **nicht** geaendert hat: Eine Aufgabe kann weiterhin nur aus
/// einem Kapitel des Reports stammen und damit nur aus einem gewaehlten
/// Modul. Die Gruppierung ordnet um, sie holt nichts dazu.
class AbschnittKarte extends ConsumerWidget {
  const AbschnittKarte({super.key, required this.gruppe});

  final Abschnittsgruppe gruppe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final fortschritt = ref.watch(planFortschrittProvider);
    final neueHabits = ref.watch(neueHabitsProvider);
    final ausrichtung = ref.watch(ausrichtungProvider);

    final erledigt = gruppe.aufgaben
        .where((a) => fortschritt.erledigt.contains(a.text))
        .length;
    final alleErledigt = erledigt == gruppe.aufgaben.length;

    return SectionCard(
      title: gruppe.abschnitt.titel(texte),
      icon: gruppe.abschnitt.icon,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: alleErledigt
              ? farben.erreichtChip
              : farben.textSekundaer.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$erledigt/${gruppe.aufgaben.length}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            // Gold erst, wenn der Abschnitt steht – ein halb voller Zaehler
            // ist kein Erreichtes (DECISIONS 50).
            color: alleErledigt ? farben.erreicht : farben.textSekundaer,
          ),
        ),
      ),
      child: Column(
        children: [
          for (final aufgabe in gruppe.aufgaben)
            HabitZeile(
              text: aufgabe.text,
              erledigt: fortschritt.erledigt.contains(aufgabe.text),
              hinweis: neueHabits[aufgabe.text],
              thema: aufgabe.modul,
              themaName: aufgabe.modul.checkliste(texte, ausrichtung),
              onTap: () => ref
                  .read(planFortschrittProvider.notifier)
                  .umschalten(aufgabe.text),
            ),
        ],
      ),
    );
  }
}

/// Der Haken einer Zeile – gesetzt in Gold, mit kurzem Einzoomen.
///
/// Die Bewegung dauert 220 ms und laeuft nur beim Setzen, nicht beim
/// Entfernen: Gefeiert wird das Abhaken, nicht das Zuruecknehmen. Bei
/// „Bewegung reduzieren" wechselt nur die Farbe.
class _Haken extends StatefulWidget {
  const _Haken({required this.erledigt});

  final bool erledigt;

  @override
  State<_Haken> createState() => _HakenState();
}

class _HakenState extends State<_Haken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _puls = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didUpdateWidget(_Haken alt) {
    super.didUpdateWidget(alt);
    if (widget.erledigt && !alt.erledigt) {
      MediaQuery.disableAnimationsOf(context)
          ? _puls.value = 1
          : _puls.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _puls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AnimatedBuilder(
      animation: _puls,
      builder: (context, kind) {
        // Einmal auf 1,25 und zurueck – die Spitze liegt in der Mitte der
        // Bewegung, deshalb der Abstand zum Scheitel.
        final wert = _puls.value;
        final skala = 1 + 0.25 * (1 - (wert * 2 - 1).abs());
        return Transform.scale(scale: wert == 0 ? 1 : skala, child: kind);
      },
      child: Icon(
        widget.erledigt
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked,
        color: widget.erledigt
            ? farben.erreichtFlaeche
            : farben.textSekundaer,
        size: 22,
      ),
    );
  }
}

/// Eine abhakbare Zeile. Der Fortschritt liegt in Hive und setzt sich am
/// naechsten Tag von selbst zurueck – der Schluessel ist das Datum.
class HabitZeile extends StatelessWidget {
  const HabitZeile({
    super.key,
    required this.text,
    required this.erledigt,
    required this.onTap,
    this.hinweis,
    this.thema,
    this.themaName,
  });

  final String text;
  final bool erledigt;
  final VoidCallback onTap;

  /// Dezente Markierung frisch angepasster Aufgaben ("Neu ab heute").
  final String? hinweis;

  /// Das Kapitel, aus dem die Aufgabe stammt – als kleines Abzeichen.
  ///
  /// Seit die Liste nach Tageszeit gruppiert, sagt die Ueberschrift nichts
  /// mehr ueber das Thema. Das Abzeichen ist der Ersatz: nur zur
  /// Orientierung, nicht antippbar (DECISIONS 70).
  final AnalyseModul? thema;

  /// Der Name des Kapitels – nur fuer die Sprachausgabe. Ein Symbol allein
  /// ist fuer einen Screenreader nichts.
  final String? themaName;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.gapXs),
        child: Row(
          children: [
            _Haken(erledigt: erledigt),
            const SizedBox(width: AppTheme.gapS),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  height: 1.4,
                  color: erledigt ? farben.textSekundaer : farben.textPrimaer,
                  decoration: erledigt ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // Das Info-Zeichen sitzt vor dem Themen-Abzeichen: Es ist
            // antippbar, das Abzeichen nicht, und Antippbares gehoert
            // naeher an den Text, um den es geht (DECISIONS 88).
            //
            // Es bringt seine eigene Trefferflaeche mit (DECISIONS 94) und
            // steht deshalb ohne zusaetzlichen Abstand da: Der Platz
            // gehoert ihm ganz, und der Text daneben schrumpft dafuer.
            WissenLink(text: text),
            if (thema case final modul?) ...[
              const SizedBox(width: AppTheme.gapXs),
              Semantics(
                label: themaName == null
                    ? null
                    : context.texte.abschnittThema(themaName!),
                child: Icon(
                  modul.icon,
                  size: 16,
                  color: farben.textSekundaer.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (hinweis case final text?) ...[
              const SizedBox(width: AppTheme.gapXs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: farben.akzent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: farben.textPrimaer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
