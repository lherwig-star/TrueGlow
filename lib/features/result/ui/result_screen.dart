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
import '../../analysis/models/analysis_result.dart';
import '../../direction/logic/direction_controller.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/logic/module_controller.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/ui/widgets/modul_karte.dart';

/// Ergebnis der Analyse, gegliedert nach Modulen. Liest die Analyse anhand der
/// ID aus der lokalen Speicherung – damit funktioniert der Screen auch aus dem
/// Verlauf.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.analyseId});

  final String analyseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
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
          const MutedText(
            'Diese Analyse ist nicht mehr vorhanden.',
            align: TextAlign.center,
          ),
        ],
      );
    }

    final offene = AnalyseModul.waehlbare
        .where((m) => !ergebnis.module.contains(m))
        .toList();

    return AppPage(
      title: texte.ergebnisTitel,
      bottomFade: true,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () => context.push(Routes.plan),
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
        _RichtungKarte(ergebnis: ergebnis),
        const SizedBox(height: AppTheme.gapM),
        for (final kapitel in ergebnis.kapitel) ...[
          _KapitelBlock(kapitel: kapitel),
          const SizedBox(height: AppTheme.gapM),
        ],
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
    final farben = context.farben;

    return Row(
      children: [
        Icon(Icons.event_outlined, size: 16, color: farben.textSekundaer),
        const SizedBox(width: 6),
        Expanded(
          child: MutedText(
            '${Datum.relativ(ergebnis.erstelltAm)} · '
            '${ergebnis.kapitel.length} Kapitel · '
            '${ergebnis.anzahlEmpfehlungen} Empfehlungen',
          ),
        ),
      ],
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
            if (verwendet.ziele.isNotEmpty)
              Wrap(
                spacing: AppTheme.gapXs,
                runSpacing: AppTheme.gapXs,
                children: [
                  for (final ziel in verwendet.sortierteZiele)
                    _ZielPille(ziel.label),
                ],
              ),
            if (verwendet.kurzfassung.isNotEmpty) ...[
              if (verwendet.ziele.isNotEmpty)
                const SizedBox(height: AppTheme.gapS),
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

/// Ein Modul-Kapitel: Ueberschrift, Einleitung und die Sektionen darunter.
class _KapitelBlock extends StatelessWidget {
  const _KapitelBlock({required this.kapitel});

  final Kapitel kapitel;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: farben.akzent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(kapitel.modul.icon, size: 18, color: farben.akzent),
            ),
            const SizedBox(width: AppTheme.gapS),
            Expanded(
              child: Text(
                kapitel.titel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        if (kapitel.einleitung.isNotEmpty) ...[
          const SizedBox(height: AppTheme.gapS),
          Text(kapitel.einleitung, style: const TextStyle(height: 1.5)),
        ],
        const SizedBox(height: AppTheme.gapS),
        for (final sektion in kapitel.sektionen) ...[
          _SektionKarte(sektion: sektion),
          const SizedBox(height: AppTheme.gapS),
        ],
      ],
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

class _SektionKarte extends StatelessWidget {
  const _SektionKarte({required this.sektion});

  final Sektion sektion;

  /// Passendes Symbol zum Sektionstitel – faellt auf ein neutrales zurueck,
  /// falls das Modell einen unerwarteten Titel liefert.
  IconData get _icon {
    final titel = sektion.titel.toLowerCase();
    if (titel.contains('haut')) return Icons.spa_outlined;
    if (titel.contains('haar') || titel.contains('frisur')) {
      return Icons.content_cut;
    }
    if (titel.contains('bart')) return Icons.face_2_outlined;
    if (titel.contains('zahn') || titel.contains('zähne')) {
      return Icons.sentiment_satisfied_alt_outlined;
    }
    if (titel.contains('farb')) return Icons.palette_outlined;
    if (titel.contains('haltung') || titel.contains('figur')) {
      return Icons.accessibility_new_outlined;
    }
    if (titel.contains('styl') || titel.contains('kleid') ||
        titel.contains('schnitt') || titel.contains('passform')) {
      return Icons.checkroom_outlined;
    }
    if (titel.contains('habit') || titel.contains('gewohnheit')) {
      return Icons.self_improvement_outlined;
    }
    return Icons.auto_awesome_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    return SectionCard(
      title: sektion.titel,
      icon: _icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sektion.einschaetzung.isNotEmpty)
            Text(
              sektion.einschaetzung,
              style: const TextStyle(height: 1.5),
            ),
          if (sektion.empfehlungen.isNotEmpty) ...[
            const SizedBox(height: AppTheme.gapM),
            _Untertitel(texte.ergebnisEmpfehlungen),
            const SizedBox(height: AppTheme.gapXs),
            for (final empfehlung in sektion.empfehlungen)
              _Empfehlung(empfehlung),
          ],
          if (sektion.produkte.isNotEmpty) ...[
            const SizedBox(height: AppTheme.gapM),
            _Untertitel(texte.ergebnisProdukte),
            const SizedBox(height: AppTheme.gapXs),
            for (final produkt in sektion.produkte) _ProduktZeile(produkt),
          ],
        ],
      ),
    );
  }
}

class _Untertitel extends StatelessWidget {
  const _Untertitel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: context.farben.textSekundaer,
        ),
      );
}

/// Einzelne Empfehlung als Aufzaehlungspunkt mit Akzent-Marker.
class _Empfehlung extends StatelessWidget {
  const _Empfehlung(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: BoxDecoration(
              color: context.farben.akzent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

/// Produkt-Empfehlung. Die Struktur traegt bereits ein Feld fuer den
/// Affiliate-Link; solange es leer ist, wird kein Link angezeigt.
class _ProduktZeile extends StatelessWidget {
  const _ProduktZeile(this.produkt);

  final Produkt produkt;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.gapXs),
      padding: const EdgeInsets.all(AppTheme.gapS),
      decoration: BoxDecoration(
        color: farben.flaecheHoch,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  produkt.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (produkt.kategorie.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: farben.akzentZwei.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  // Farbe in der Pille, Text in der Vordergrundfarbe – sonst
                  // reicht der Kontrast der Kleinschrift nicht.
                  child: Text(
                    produkt.kategorie,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: farben.textPrimaer,
                    ),
                  ),
                ),
            ],
          ),
          if (produkt.beschreibung.isNotEmpty) ...[
            const SizedBox(height: 4),
            MutedText(produkt.beschreibung),
          ],
        ],
      ),
    );
  }
}
