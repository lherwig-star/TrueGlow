import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/datum.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../../analysis/models/analyse_modus.dart';
import '../../analysis/models/analysis_result.dart';
import '../../direction/models/richtung.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/models/analyse_modul.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../logic/plan_erzeugt.dart';
import 'widgets/kapitel_kachel.dart';

/// Ergebnis der Analyse, gegliedert nach Modulen. Liest die Analyse anhand der
/// ID aus der lokalen Speicherung – damit funktioniert der Screen auch aus dem
/// Verlauf.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.analyseId});

  final String analyseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final ausrichtung = ref.watch(ausrichtungProvider);
    // Neuladen, sobald sich der Bestand aendert.
    ref.watch(analysenProvider);
    final ergebnis = ref.watch(analysisRepositoryProvider).laden(analyseId);

    if (ergebnis == null) {
      return AppPage(
        title: texte.ergebnisTitel,
        children: [
          const SizedBox(height: AppTheme.gapXl),
          Icon(
            Icons.search_off,
            size: 48,
            color: context.farben.textSekundaer,
          ),
          const SizedBox(height: AppTheme.gapS),
          MutedText(
            texte.ergebnisNichtVorhanden,
            align: TextAlign.center,
          ),
        ],
      );
    }

    // Angeboten wird nur, was zur Ausrichtung passt: Wer im maennlichen
    // Modus laeuft, soll unter „Analyse erweitern" kein Make-up-Kapitel
    // finden. Was bereits im Report steht, bleibt davon unberuehrt – deshalb
    // wird gefiltert und nicht entfernt.
    final offene = AnalyseModul.waehlbareFuer(ausrichtung)
        .where((m) => !ergebnis.module.contains(m))
        .toList();

    // Ob aus diesem Report schon ein Plan geworden ist – davon hängt ab,
    // was auf dem Knopf steht.
    final erzeugt = ref.watch(planErzeugtProvider).contains(ergebnis.id);

    return AppPage(
      title: texte.ergebnisTitel,
      bottomFade: true,
      // Ein Knopf statt zweier: „Zur Startseite" hat nichts getan, was die
      // Zurück-Taste und die Tab-Leiste nicht auch tun – er hat nur Höhe
      // gekostet, und zwar unten, wo sie am teuersten ist (DECISIONS 90).
      bottomBar: FilledButton.icon(
        onPressed: () {
          ref.read(planErzeugtProvider.notifier).merken(ergebnis.id);
          context.go(Routes.plan);
        },
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
        icon: Icon(erzeugt ? Icons.checklist_rtl : Icons.playlist_add_check),
        label: Text(
          erzeugt ? texte.ergebnisZumPlan : texte.ergebnisPlanErstellen,
        ),
      ),
      children: [
        _Kopf(ergebnis: ergebnis),
        const SizedBox(height: AppTheme.gapM),
        // Ganz oben, noch vor der Richtung: Im entdeckenden Modus ist das
        // der Einstieg, auf den alles Weitere sich bezieht.
        if (ergebnis.zeigtGesamtbild) ...[
          _GesamtbildKarte(
            titel: ergebnis.modus.gesamtbildTitel(texte),
            text: ergebnis.gesamtbild,
          ),
          const SizedBox(height: AppTheme.gapM),
        ],
        // Was der Nutzer selbst eingegeben hat – direkt unter dem
        // Gesamtbild, bevor die Kapitel anfangen (DECISIONS 87).
        _AuswahlEcho(ergebnis: ergebnis),
        const SizedBox(height: AppTheme.gapM),
        // Die Kapitel als Übersicht statt als langer Scroll: eine
        // Kachel je Bereich, dahinter der unveränderte Inhalt
        // (DECISIONS 89).
        KapitelRaster(ergebnis: ergebnis),
        if (offene.isNotEmpty) ...[
          const SizedBox(height: AppTheme.gapS),
          _ErweiternKarte(analyseId: ergebnis.id, module: offene),
        ],
        const SizedBox(height: AppTheme.gapM),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
          child: MutedText(texte.disclaimerMedizin),
        ),
      ],
    );
  }
}

class _Kopf extends StatelessWidget {
  const _Kopf({required this.ergebnis});

  final AnalysisResult ergebnis;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return Row(
      children: [
        Icon(Icons.event_outlined, size: 16, color: farben.textSekundaer),
        const SizedBox(width: 6),
        Expanded(
          // Die ganze Zeile kommt aus einem einzigen uebersetzten Satz.
          // Als drei Bausteine zusammengesetzt stand hier „today · 1 Kapitel
          // · 4 Empfehlungen" – halb englisch, halb deutsch.
          child: MutedText(
            texte.ergebnisKopf(
              Datum.relativ(
                ergebnis.erstelltAm,
                texte.localeName,
                heute: texte.datumHeute,
                gestern: texte.datumGestern,
              ),
              // Der Modus stand als Pille in der Auswahl-Zeile. Dort war er
              // fehl am Platz: Er ist keine Auswahl aus einer Liste, sondern
              // die Frage, die dieser Report beantwortet – und die gehört
              // in die Zeile, die den Report benennt (DECISIONS 90).
              ergebnis.modus.etikett(texte),
              ergebnis.kapitel.length,
              ergebnis.anzahlEmpfehlungen,
            ),
          ),
        ),
      ],
    );
  }
}

/// Der Vorspann des Reports – in beiden Modi (DECISIONS 67).
///
/// Er steht ueber allem anderen, weil er alles andere zusammenhaelt: Die
/// Kapitel darunter sind die Umsetzung dieser Richtung. Wer ihn ueberspringt,
/// liest den Rest als lose Tipps.
///
/// **Seit DECISIONS 90 eine Karte wie jede andere.** Sie trug einen goldenen
/// Rahmen und war damit das lauteste Element der Seite – eine Textkarte, die
/// mehr Aufmerksamkeit zog als der eigentliche Inhalt darunter. Und Gold
/// gehoert dem Erreichten (DECISIONS 50), nicht der Dekoration. Die
/// Ueberschrift darf dafuer eine Stufe groesser sein; der Inhalt ist
/// unveraendert.
class _GesamtbildKarte extends StatelessWidget {
  const _GesamtbildKarte({required this.titel, required this.text});

  final String titel;
  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore_outlined, size: 20, color: farben.akzent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titel,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapS),
          Text(text, style: const TextStyle(height: 1.55, fontSize: 15.5)),
        ],
      ),
    );
  }
}

/// Was der Nutzer selbst eingegeben hat, in genau einer Zeile
/// (DECISIONS 87, neu gefasst in DECISIONS 90).
///
/// Der Befund: Die gewaehlte Richtung floss in den Prompt ein und praegte den
/// Report – nur sah man das dem Report nicht an. Eine Auswahl, deren Folgen
/// unsichtbar bleiben, fuehlt sich folgenlos an.
///
/// **Eine Zeile, waagerecht scrollbar** und keine Chip-Wolke: Die Wolke wuchs
/// mit der Auswahl und schob die Kacheln nach unten – ausgerechnet das, was
/// der Kern der Seite sein soll. Laeuft die Zeile ueber, wird der letzte Chip
/// angeschnitten; das ist der Hinweis, dass es weitergeht.
///
/// Was hier steht, ist ausschliesslich Gewaehltes und nichts Erfundenes: erst
/// die Richtungen, dann die Techniken, die es wirklich in den Report
/// geschafft haben. Der Freitext steht bewusst **nicht** hier – er ist oft
/// ein ganzer Absatz und hat sein Zuhause im Zielkapitel. Gibt es nichts zu
/// zeigen, entfaellt die Zeile ganz, samt Beschriftung.
class _AuswahlEcho extends StatelessWidget {
  const _AuswahlEcho({required this.ergebnis});

  final AnalysisResult ergebnis;

  /// Die Techniken, die im Report tatsaechlich vorkommen.
  ///
  /// Quelle ist das Feld `neu` der Sektionen und nicht die angetippte Liste:
  /// Was das Modell nicht untergebracht hat, soll hier auch nicht behauptet
  /// werden. Reihenfolge und Dubletten kommen aus dem Report, deshalb das
  /// `Set` mit erhaltener Reihenfolge.
  List<String> get _techniken {
    final gesehen = <String>{};
    for (final sektion in ergebnis.sektionen) {
      gesehen.addAll(sektion.neu);
    }
    return gesehen.toList();
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final richtungen = ergebnis.richtung.sortierteZiele;
    final techniken = _techniken;
    if (richtungen.isEmpty && techniken.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
      child: Row(
        children: [
          MutedText('${texte.ergebnisAuswahl}:'),
          const SizedBox(width: AppTheme.gapXs),
          for (final ziel in richtungen) ...[
            _ZielPille(ziel.label(texte)),
            const SizedBox(width: AppTheme.gapXs),
          ],
          // Die Techniken tragen ein Funkeln vor dem Namen – dasselbe
          // Zeichen, an dem man „Neu für dich" im Kapitel wiedererkennt.
          // Ohne es waere „Gua Sha" von einer Stilrichtung nicht zu
          // unterscheiden.
          for (final technik in techniken) ...[
            _ZielPille(technik, symbol: Icons.auto_awesome),
            const SizedBox(width: AppTheme.gapXs),
          ],
        ],
      ),
    );
  }
}

/// Ein gewaehltes Ziel als kleine Pille. Die Farbe traegt die Flaeche, nicht
/// die Schrift – Kleinschrift in Akzentfarbe kaeme auf der Karte nicht auf
/// die noetigen 4,5:1.
class _ZielPille extends StatelessWidget {
  const _ZielPille(this.label, {this.symbol});

  final String label;

  /// Kleines Zeichen vor der Beschriftung – nur die Techniken tragen eines.
  final IconData? symbol;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: farben.akzent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (symbol case final zeichen?) ...[
            Icon(zeichen, size: 12, color: farben.textPrimaer),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: farben.textPrimaer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Was noch fehlt – eine Zeile statt dreier Karten (DECISIONS 90).
///
/// Sie ist bewusst kleiner und ruhiger als jede Inhalts-Kachel: Was noch
/// nicht analysiert ist, darf nicht mehr Platz bekommen als das, was schon
/// da ist. Die ausführlichen Modul-Karten stehen dahinter.
class _ErweiternKarte extends StatelessWidget {
  const _ErweiternKarte({required this.analyseId, required this.module});

  final String analyseId;
  final List<AnalyseModul> module;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ProviderScope.containerOf(context)
        .read(ausrichtungProvider);

    return SectionCard(
      padding: const EdgeInsets.all(AppTheme.gapS),
      onTap: () => context.push(Routes.erweiternFuer(analyseId)),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, size: 20, color: farben.akzent),
          const SizedBox(width: AppTheme.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texte.moduleErweitern,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texte.ergebnisErweiternZeile(
                    module.length,
                    [
                      for (final modul in module)
                        modul.titel(texte, ausrichtung),
                    ].join(' \u00b7 '),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: farben.textSekundaer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.gapXs),
          Icon(Icons.chevron_right, size: 20, color: farben.textSekundaer),
        ],
      ),
    );
  }
}
