import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../analysis/models/analysis_result.dart';
import '../../../onboarding/logic/onboarding_controller.dart';
import '../../../wissen/ui/wissens_blatt.dart';

/// Ein Modul-Kapitel: Ueberschrift, Einleitung und die Sektionen darunter.
class KapitelBlock extends ConsumerWidget {
  const KapitelBlock({super.key, required this.kapitel});

  final Kapitel kapitel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final ausrichtung = ref.watch(ausrichtungProvider);

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
                kapitel.titel(texte, ausrichtung),
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

class _SektionKarte extends StatelessWidget {
  const _SektionKarte({required this.sektion});

  final Sektion sektion;

  /// Passendes Symbol zum Sektionstitel – faellt auf ein neutrales zurueck,
  /// falls das Modell einen unerwarteten Titel liefert.
  ///
  /// Die Stichwoerter stehen in beiden Sprachen nebeneinander: Der Titel
  /// kommt vom Modell und ist in der Sprache geschrieben, in der der Report
  /// entstanden ist. Ein deutsches Stichwortverzeichnis haette bei jedem
  /// englischen Report auf das neutrale Symbol zurueckfallen lassen – nicht
  /// falsch, aber jedes Mal.
  ///
  /// Bewusst Teilzeichenketten statt ganzer Woerter: Das Modell schreibt
  /// „Frisur & Schnitt" ebenso wie „Haircut", und beides soll dieselbe
  /// Schere bekommen.
  static const _symbole = <(List<String>, IconData)>[
    (['haut', 'skin', 'complexion'], Icons.spa_outlined),
    (['haar', 'frisur', 'hair', 'haircut'], Icons.content_cut),
    (['bart', 'beard', 'stubble'], Icons.face_2_outlined),
    (
      ['zahn', 'zähne', 'teeth', 'tooth', 'smile', 'lächeln'],
      Icons.sentiment_satisfied_alt_outlined,
    ),
    (['farb', 'colour', 'color', 'palette'], Icons.palette_outlined),
    (
      ['haltung', 'figur', 'posture', 'body', 'figure'],
      Icons.accessibility_new_outlined,
    ),
    (
      [
        'styl',
        'kleid',
        'schnitt',
        'passform',
        'wardrobe',
        'outfit',
        'fit',
        'cut',
      ],
      Icons.checkroom_outlined,
    ),
    (
      ['habit', 'gewohnheit', 'routine'],
      Icons.self_improvement_outlined,
    ),
  ];

  IconData get _icon {
    final titel = sektion.titel.toLowerCase();
    for (final (woerter, symbol) in _symbole) {
      if (woerter.any(titel.contains)) return symbol;
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
          // Ganz oben, noch vor der Einschaetzung: Wer den Schritt
          // „Das will ich ausprobieren" ausgefuellt hat, soll hier sehen,
          // dass seine Wahl angekommen ist (DECISIONS 80).
          if (sektion.zeigtNeu) ...[
            Wrap(
              spacing: AppTheme.gapXs,
              runSpacing: AppTheme.gapXs,
              children: [
                for (final name in sektion.neu) _NeuPille(name),
              ],
            ),
            const SizedBox(height: AppTheme.gapS),
          ],
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

/// Die Marke „Neu für dich" an einer Sektion.
///
/// Traegt den Ton fuer Erreichtes – denselben wie das Gesamtbild oben und
/// das Etikett im Verlauf. Das ist keine Wertung gegenueber den anderen
/// Sektionen, sondern Wiedererkennung: Diese Farbe heisst in der ganzen App
/// „hier ist etwas passiert".
class _NeuPille extends StatelessWidget {
  const _NeuPille(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final texte = context.texte;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: farben.erreichtFlaeche.withValues(alpha: 0.16),
        border: Border.all(color: farben.erreichtFlaeche),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: farben.erreichtFlaeche),
          const SizedBox(width: 6),
          Text(
            // „Neu für dich · Gua Sha" – erst wofuer die Marke steht, dann
            // was gemeint ist. Der Name allein saehe aus wie eine
            // Ueberschrift.
            '${texte.ergebnisNeuFuerDich} · $name',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              // Nicht die Akzentfarbe: Kleinschrift darin kaeme auf dieser
              // Flaeche nicht auf die noetigen 4,5:1.
              color: farben.textPrimaer,
            ),
          ),
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
          // Steht in der Empfehlung eine Technik, die die Bibliothek kennt,
          // laesst sie sich hier nachschlagen (DECISIONS 88).
          WissenLink(text: text),
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
    final texte = context.texte;

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
                    produkt.kategorieText(texte),
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
