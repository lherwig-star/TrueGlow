import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/texte.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/datum.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/section_card.dart';
import '../logic/checkin_controller.dart';
import '../logic/fortschritts_album.dart';

/// Das Fortschritts-Tagebuch: Vorher-Nachher und eine Zeitleiste.
///
/// Alle Bilder liegen ausschliesslich auf diesem Geraet (DECISIONS 48). Der
/// Hinweis darauf steht beim ersten Besuch als Karte und danach als Zeile am
/// Fuss – ehrlich, aber nicht jedes Mal im Weg.
class FortschrittScreen extends ConsumerStatefulWidget {
  const FortschrittScreen({super.key});

  @override
  ConsumerState<FortschrittScreen> createState() => _FortschrittScreenState();
}

class _FortschrittScreenState extends ConsumerState<FortschrittScreen> {
  /// Welches Foto rechts im Vergleich steht. Null heisst „das neueste".
  Fotoeintrag? _gewaehlt;

  /// Position des Schiebereglers, 0 = ganz vorher, 1 = ganz nachher.
  double _regler = 0.5;

  bool _hinweisGezeigt = false;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final fotos = ref.watch(vorhandeneFotosProvider);

    _hinweisPruefen(fotos.isNotEmpty);

    return AppPage(
      title: texte.fotosTitel,
      children: [
        if (fotos.isEmpty)
          _Leer()
        else ...[
          if (fotos.length == 1)
            _EinzelBild(eintrag: fotos.first)
          else
            _Vergleich(
              vorher: fotos.first,
              nachher: _gueltig(fotos),
              regler: _regler,
              onRegler: (wert) => setState(() => _regler = wert),
            ),
          const SizedBox(height: AppTheme.gapM),
          _Zeitleiste(
            fotos: fotos,
            gewaehlt: _gueltig(fotos),
            onWahl: (eintrag) => setState(() => _gewaehlt = eintrag),
            onLoeschen: (eintrag) => _loeschen(eintrag),
          ),
        ],
        const SizedBox(height: AppTheme.gapM),
        SectionCard(
          title: texte.fotosNurHierTitel,
          icon: Icons.lock_outline,
          child: MutedText(texte.fotosNurHierText),
        ),
      ],
    );
  }

  /// Beim ersten Foto einmal ausdruecklich sagen, was mit ihm passiert.
  void _hinweisPruefen(bool hatFotos) {
    if (_hinweisGezeigt || !hatFotos) return;
    final ctrl = ref.read(checkinControllerProvider.notifier);
    if (ctrl.fotohinweisGesehen) return;

    _hinweisGezeigt = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _hinweisDialog();
      await ctrl.fotohinweisGesehenMerken();
    });
  }

  Future<void> _hinweisDialog() {
    final texte = context.texte;
    return showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: const Icon(Icons.lock_outline),
        title: Text(texte.fotosNurHierTitel),
        content: Text(texte.fotosNurHierText),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(texte.fotosVerstanden),
          ),
        ],
      ),
    );
  }

  /// Die getroffene Wahl, solange es sie noch gibt – sonst das neueste Foto.
  Fotoeintrag _gueltig(List<Fotoeintrag> fotos) {
    final gewaehlt = _gewaehlt;
    if (gewaehlt != null && fotos.contains(gewaehlt)) return gewaehlt;
    return fotos.last;
  }

  Future<void> _loeschen(Fotoeintrag eintrag) async {
    final texte = context.texte;

    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(texte.fotosLoeschenFrage),
        content: Text(texte.fotosLoeschenText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(texte.abbrechen),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(texte.loeschen),
          ),
        ],
      ),
    );

    if (bestaetigt != true) return;
    await fotoLoeschen(ref, eintrag);
    if (mounted) setState(() => _gewaehlt = null);
  }
}

class _Leer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final texte = context.texte;

    return Column(
      children: [
        const SizedBox(height: AppTheme.gapXl),
        Icon(
          Icons.photo_camera_outlined,
          size: 48,
          color: context.farben.textSekundaer,
        ),
        const SizedBox(height: AppTheme.gapS),
        Text(
          texte.fotosLeerTitel,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.gapXs),
        MutedText(texte.fotosLeerText, align: TextAlign.center),
      ],
    );
  }
}

class _EinzelBild extends StatelessWidget {
  const _EinzelBild({required this.eintrag});

  final Fotoeintrag eintrag;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.file(File(eintrag.pfad), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: AppTheme.gapS),
        Text(
          texte.fotosEinsTitel,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        MutedText(texte.fotosEinsText),
      ],
    );
  }
}

/// Zwei Bilder uebereinander, der Regler schneidet das obere frei.
///
/// Ein Schieberegler statt zweier Bilder nebeneinander: Bei einem Gesicht
/// zaehlen Details, und nebeneinander ist jedes Bild nur halb so breit. Der
/// Regler laesst beide in voller Groesse und legt sie exakt uebereinander –
/// dieselbe Aufnahmeposition vorausgesetzt, und genau die verlangt der
/// Foto-Schritt.
class _Vergleich extends StatelessWidget {
  const _Vergleich({
    required this.vorher,
    required this.nachher,
    required this.regler,
    required this.onRegler,
  });

  final Fotoeintrag vorher;
  final Fotoeintrag nachher;
  final double regler;
  final ValueChanged<double> onRegler;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;
    final sprache = texte.localeName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(nachher.pfad), fit: BoxFit.cover),
                // Das linke Stueck zeigt weiterhin das aeltere Bild.
                Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRect(
                    clipper: _LinkerTeil(regler),
                    child: Image.file(File(vorher.pfad), fit: BoxFit.cover),
                  ),
                ),
                Align(
                  alignment: Alignment(regler * 2 - 1, 0),
                  child: Container(width: 2, color: Colors.white70),
                ),
                Positioned(
                  left: AppTheme.gapS,
                  top: AppTheme.gapS,
                  child: _Marke(text: texte.fotosVorher),
                ),
                Positioned(
                  right: AppTheme.gapS,
                  top: AppTheme.gapS,
                  child: _Marke(text: texte.fotosNachher),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          label: texte.fotosReglerHinweis,
          child: Slider(
            value: regler,
            onChanged: onRegler,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MutedText(Datum.nurTag(vorher.datum, sprache)),
            MutedText(Datum.nurTag(nachher.datum, sprache)),
          ],
        ),
        const SizedBox(height: AppTheme.gapXs),
        Center(
          child: Text(
            texte.fotosReglerHinweis,
            style: TextStyle(fontSize: 12, color: farben.textSekundaer),
          ),
        ),
      ],
    );
  }
}

/// Schneidet den linken Teil frei – [anteil] von 0 bis 1.
class _LinkerTeil extends CustomClipper<Rect> {
  const _LinkerTeil(this.anteil);

  final double anteil;

  @override
  Rect getClip(Size groesse) =>
      Rect.fromLTWH(0, 0, groesse.width * anteil, groesse.height);

  @override
  bool shouldReclip(_LinkerTeil alt) => alt.anteil != anteil;
}

class _Marke extends StatelessWidget {
  const _Marke({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Alle Fotos mit Datum, aeltestes links.
class _Zeitleiste extends StatelessWidget {
  const _Zeitleiste({
    required this.fotos,
    required this.gewaehlt,
    required this.onWahl,
    required this.onLoeschen,
  });

  final List<Fotoeintrag> fotos;
  final Fotoeintrag gewaehlt;
  final ValueChanged<Fotoeintrag> onWahl;
  final ValueChanged<Fotoeintrag> onLoeschen;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return SectionCard(
      title: texte.fotosZeitleiste(fotos.length),
      icon: Icons.timeline,
      child: SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: fotos.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppTheme.gapS),
          itemBuilder: (_, index) {
            final eintrag = fotos[index];
            final aktiv = eintrag == gewaehlt;

            return GestureDetector(
              onTap: () => onWahl(eintrag),
              onLongPress: eintrag.istStart ? null : () => onLoeschen(eintrag),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: aktiv ? farben.erreicht : farben.kartenrand,
                        width: aktiv ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(
                        File(eintrag.pfad),
                        width: 72,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 74,
                    child: Text(
                      eintrag.istStart
                          ? texte.fotosStart
                          : Datum.nurTag(eintrag.datum, texte.localeName),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: aktiv ? FontWeight.w800 : FontWeight.w600,
                        color: aktiv ? farben.erreicht : farben.textSekundaer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
