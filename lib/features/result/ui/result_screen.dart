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
import '../../modules/logic/module_controller.dart';
import '../../modules/models/analyse_modul.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../../modules/ui/widgets/modul_karte.dart';
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

    return AppPage(
      title: texte.ergebnisTitel,
      bottomFade: true,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () => context.go(Routes.plan),
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            icon: const Icon(Icons.checklist_rtl),
            label: Text(texte.ergebnisPlanErstellen),
          ),
          const SizedBox(height: AppTheme.gapS),
          OutlinedButton.icon(
            onPressed: () => context.go(Routes.home),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            icon: const Icon(Icons.home_outlined),
            label: Text(texte.zurStartseite),
          ),
        ],
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
        // Die Kapitel als Übersicht statt als langer Scroll: eine
        // Kachel je Bereich, dahinter der unveränderte Inhalt
        // (DECISIONS 89).
        KapitelRaster(ergebnis: ergebnis),
        const SizedBox(height: AppTheme.gapS),
        if (offene.isNotEmpty) ...[
          _Erweitern(module: offene),
          const SizedBox(height: AppTheme.gapM),
        ],
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

/// Noch nicht analysierte Module – ein Tipp startet nur deren Aufnahmen.
class _Erweitern extends ConsumerWidget {
  const _Erweitern({required this.module});

  final List<AnalyseModul> module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texte.moduleErweitern,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapXs),
        MutedText(texte.moduleErweiternText),
        const SizedBox(height: AppTheme.gapS),
        for (final modul in module) ...[
          ModulKarte(
            modul: modul,
            mitCheckbox: false,
            aktion: Icon(Icons.arrow_forward, color: farben.akzent, size: 20),
            onTap: () {
              // Auswahl merken, damit das Modul danach als Teil der Analyse
              // gilt und nicht erneut angeboten wird.
              ref.read(moduleControllerProvider.notifier).ergaenzen(modul);
              context.push(Routes.aufnahmeFuer(modul));
            },
          ),
          const SizedBox(height: AppTheme.gapS),
        ],
      ],
    );
  }
}
