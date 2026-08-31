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
import '../../direction/logic/direction_controller.dart';
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
        const SizedBox(height: AppTheme.gapM),
        _RichtungKarte(ergebnis: ergebnis),
        const SizedBox(height: AppTheme.gapM),
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
/// Optisch abgesetzt und nicht als gewoehnliche Karte: Der Ton fuer
/// Erreichtes umrandet ihn, derselbe, der das Etikett im Verlauf traegt.
/// Das ist keine Wertung des anderen Modus – es ist Wiedererkennung.
class _GesamtbildKarte extends StatelessWidget {
  const _GesamtbildKarte({required this.titel, required this.text});

  final String titel;
  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
      padding: const EdgeInsets.all(AppTheme.gapM),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          farben.erreichtFlaeche.withValues(alpha: 0.08),
          Theme.of(context).cardTheme.color ?? farben.flaeche,
        ),
        border: Border.all(color: farben.erreichtFlaeche, width: 1.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.explore_outlined,
                size: 18,
                color: farben.erreichtFlaeche,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titel,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: farben.erreicht,
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

/// Kompakte Zusammenfassung der persoenlichen Ziele, mit denen dieser Report
/// entstanden ist.
///
/// Weicht die gespeicherte Richtung inzwischen ab, bietet die Karte an, den
/// Plan mit den vorhandenen Fotos neu zu rechnen – neue Aufnahmen braucht es
/// dafuer nicht.
class _RichtungKarte extends ConsumerWidget {
  const _RichtungKarte({required this.ergebnis});

  final AnalysisResult ergebnis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final aktuell = ref.watch(directionControllerProvider);
    final verwendet = ergebnis.richtung;
    final geaendert = aktuell != verwendet;

    return SectionCard(
      title: texte.richtungTitel,
      icon: Icons.explore_outlined,
      trailing: TextButton(
        onPressed: () => context.push(Routes.richtungBearbeiten),
        child: Text(
          verwendet.istLeer ? texte.richtungAngeben : texte.richtungAendern,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (verwendet.istLeer)
            MutedText(texte.richtungLeerText)
          else ...[
            // Die gewählten Richtungen stehen als Pillen im Auswahl-Echo
            // weiter oben. Sie hier ein zweites Mal zu zeigen, wäre auf
            // demselben Bildschirm doppelt (DECISIONS 87); diese Karte
            // behält den Freitext und den Weg zum Ändern.
            if (verwendet.kurzfassung.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.only(left: AppTheme.gapS),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: farben.akzent, width: 2),
                  ),
                ),
                child: Text(
                  verwendet.kurzfassung,
                  style: TextStyle(
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: farben.textSekundaer,
                  ),
                ),
              ),
            ],
            // Ohne Freitext bliebe die Karte sonst leer. Ein Satz ist
            // besser als eine Überschrift über nichts – und er sagt
            // gleich, wo die Auswahl steht.
            if (verwendet.ziele.isNotEmpty && verwendet.kurzfassung.isEmpty)
              MutedText(texte.richtungStehtOben),
          ],
          if (geaendert) ...[
            const SizedBox(height: AppTheme.gapM),
            MutedText(texte.richtungAktualisierenText),
            const SizedBox(height: AppTheme.gapS),
            FilledButton.icon(
              onPressed: () =>
                  context.push(Routes.analyseNeu(ergebnis.module)),
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
              icon: const Icon(Icons.refresh),
              label: Text(texte.richtungAktualisieren),
            ),
          ],
        ],
      ),
    );
  }
}

/// Was der Nutzer selbst eingegeben hat, in einer Zeile (DECISIONS 87).
///
/// Der Befund: Die gewaehlte Richtung floss in den Prompt ein und praegte den
/// Report – nur sah man das dem Report nicht an. Eine Auswahl, deren Folgen
/// unsichtbar bleiben, fuehlt sich folgenlos an.
///
/// Was hier steht, ist ausschliesslich Gewaehltes und nichts Erfundenes:
/// die Richtungen dieser Analyse, die Techniken, die es wirklich in den
/// Report geschafft haben, und der Modus. Wurde der Richtungs-Schritt
/// uebersprungen, fehlen die Richtungs-Pillen – dann steht dort nur der
/// Modus, und der ist in jedem Durchlauf eine echte Entscheidung.
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
    final pillen = [
      for (final ziel in ergebnis.richtung.sortierteZiele) ziel.label(texte),
      ..._techniken,
      ergebnis.modus.etikett(texte),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapXs),
      child: Wrap(
        spacing: AppTheme.gapXs,
        runSpacing: AppTheme.gapXs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MutedText('${texte.ergebnisAuswahl}:'),
          for (final pille in pillen) _ZielPille(pille),
        ],
      ),
    );
  }
}

/// Ein gewaehltes Ziel als kleine Pille. Die Farbe traegt die Flaeche, nicht
/// die Schrift – Kleinschrift in Akzentfarbe kaeme auf der Karte nicht auf
/// die noetigen 4,5:1.
class _ZielPille extends StatelessWidget {
  const _ZielPille(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: farben.akzent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: farben.textPrimaer,
        ),
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
