import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../logic/wissen_bibliothek.dart';
import '../models/wissenseintrag.dart';

/// Ein kleines Info-Zeichen hinter einem Text, in dem eine bekannte Technik
/// vorkommt. Antippen öffnet die Erklärung (DECISIONS 88).
///
/// Steht in [text] nichts, das die Bibliothek kennt, entsteht überhaupt kein
/// Widget – kein Platzhalter, keine graue Fläche. Das Zeichen ist damit auch
/// ein Signal: Wo eines ist, gibt es etwas zu lesen.
///
/// **Das Zeichen ist klein, die Trefferfläche ist es nicht** (DECISIONS 94).
/// Am Gerät hakte ein Tipp auf das Zeichen manchmal die Aufgabe ab, statt die
/// Erklärung zu öffnen: Das Symbol maß 16 Punkte plus zwei Punkte Rand, und
/// wer daneben traf, traf die Zeile darunter – die ist ganz antippbar. Jetzt
/// sitzt es in einem Feld von [trefferflaeche] Punkten, der Norm für
/// Bedienelemente. Innerhalb dieses Feldes gewinnt immer das Zeichen; was
/// dane­ben liegt, gehört weiterhin der Aufgabe.
class WissenLink extends ConsumerWidget {
  const WissenLink({super.key, required this.text, this.groesse = 20});

  /// Der Satz, in dem gesucht wird – eine Aufgabe oder eine Empfehlung.
  final String text;

  /// Die Größe des Symbols. Die Trefferfläche hängt nicht daran.
  final double groesse;

  /// Kantenlänge der Trefferfläche in logischen Punkten.
  ///
  /// 48 ist die Untergrenze aus den Material-Richtlinien und zugleich die
  /// Zahl, die Android für Bedienhilfen prüft. Sie gilt hier unabhängig
  /// davon, wie groß das Symbol gezeichnet wird.
  static const double trefferflaeche = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texte = context.texte;
    final farben = context.farben;
    final eintrag = ref
        .watch(wissenProvider(texte.localeName))
        .valueOrNull
        ?.suche(text);
    if (eintrag == null) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: texte.wissenWasIst(eintrag.titel),
      child: SizedBox(
        width: trefferflaeche,
        height: trefferflaeche,
        child: InkResponse(
          onTap: () => zeigeWissensblatt(context, eintrag),
          radius: trefferflaeche / 2,
          child: Center(
            // Eine schwache Scheibe hinter dem Zeichen: Sie hebt es vom
            // Fließtext ab und sagt „hier kann man drücken", ohne so laut zu
            // werden wie ein Knopf.
            child: Container(
              width: groesse + 10,
              height: groesse + 10,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: farben.akzent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                size: groesse,
                color: farben.akzent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Öffnet die Erklärung als Blatt von unten.
///
/// Kein eigener Bildschirm: Ein Bottom-Sheet legt sich über die Stelle, an der
/// man gerade war, und ein Wisch nach unten bringt genau dorthin zurück. Wer
/// mitten in der Tagesliste nachschlägt, verliert seinen Platz nicht.
Future<void> zeigeWissensblatt(
  BuildContext context,
  Wissenseintrag eintrag,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.farben.flaeche,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusCard),
      ),
    ),
    builder: (context) => WissensBlatt(eintrag: eintrag),
  );
}

/// Der Inhalt des Blattes. Eigenes Widget, damit die Bibliothek denselben
/// Aufbau zeigen kann wie der Sprung aus einer Aufgabe.
class WissensBlatt extends StatelessWidget {
  const WissensBlatt({super.key, required this.eintrag});

  final Wissenseintrag eintrag;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gapM,
            0,
            AppTheme.gapM,
            AppTheme.gapL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eintrag.titel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppTheme.gapM),
              _Absatz(titel: texte.wissenWasIstDas, text: eintrag.wasIstDas),
              const SizedBox(height: AppTheme.gapM),
              _Ueberschrift(texte.wissenSoGehts),
              const SizedBox(height: AppTheme.gapXs),
              for (final (nummer, schritt) in eintrag.schritte.indexed)
                _Schritt(nummer: nummer + 1, text: schritt),
              const SizedBox(height: AppTheme.gapS),
              _Absatz(titel: texte.wissenWieOft, text: eintrag.wieOft),
              const SizedBox(height: AppTheme.gapM),
              _Absatz(titel: texte.wissenWomit, text: eintrag.womit),
              const SizedBox(height: AppTheme.gapM),
              // Der Verträglichkeitshinweis steht hervorgehoben und nicht als
              // Kleingedrucktes: Er gehört zur Anleitung (DECISIONS 79).
              Container(
                padding: const EdgeInsets.all(AppTheme.gapS),
                decoration: BoxDecoration(
                  color: farben.flaecheHoch,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  border: Border(
                    left: BorderSide(color: farben.akzent, width: 3),
                  ),
                ),
                child: _Absatz(
                  titel: texte.wissenWoraufAchten,
                  text: eintrag.woraufAchten,
                ),
              ),
              const SizedBox(height: AppTheme.gapM),
              Text(
                texte.disclaimerMedizin,
                style: TextStyle(fontSize: 12.5, color: farben.textSekundaer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ueberschrift extends StatelessWidget {
  const _Ueberschrift(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: context.farben.textSekundaer,
        ),
      );
}

class _Absatz extends StatelessWidget {
  const _Absatz({required this.titel, required this.text});

  final String titel;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Ueberschrift(titel),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(height: 1.5)),
        ],
      );
}

class _Schritt extends StatelessWidget {
  const _Schritt({required this.nummer, required this.text});

  final int nummer;
  final String text;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 2, right: AppTheme.gapS),
            decoration: BoxDecoration(
              color: farben.akzent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$nummer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: farben.textPrimaer,
              ),
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}
