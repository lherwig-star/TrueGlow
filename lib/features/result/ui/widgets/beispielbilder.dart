import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/texte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/beispielbild.dart';

/// Die Reihe echter Beispielfotos unter einem Vorschlag – DECISIONS 69.
///
/// Warum es sie gibt: „Textured Crop mit mittelhohem Fade" ist fuer jemanden,
/// der das noch nie gesehen hat, kein Bild im Kopf, sondern eine Vokabel.
///
/// Der wichtigste Zug dieser Klasse ist, was sie **nicht** tut: Wenn nichts
/// kommt – kein Netz, kein Treffer, ein Serverfehler –, verschwindet sie
/// rueckstandslos. Keine Fehlermeldung, keine leere Flaeche, keine Luecke im
/// Layout. Der Report ist ohne Bilder vollstaendig; sie sind eine Zugabe.
class Beispielbilder extends StatelessWidget {
  const Beispielbilder({super.key, required this.bilder});

  /// Der Ladezustand der Bilder genau dieses Vorschlags.
  final AsyncValue<List<Beispielbild>> bilder;

  /// Hochkant, weil Frisur, Bart und Outfit stehende Motive sind.
  static const kachelBreite = 96.0;
  static const kachelHoehe = 128.0;

  /// So viele Platzhalter stehen waehrend des Ladens da.
  static const _platzhalter = 3;

  @override
  Widget build(BuildContext context) {
    return bilder.when(
      // Waehrend des Ladens Platzhalter statt einer springenden Karte: Die
      // Reihe belegt sofort ihre endgueltige Hoehe.
      loading: () => _Reihe(
        kacheln: [
          for (var i = 0; i < _platzhalter; i++) const _Platzhalter(),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (liste) => liste.isEmpty
          ? const SizedBox.shrink()
          : _Reihe(
              kacheln: [
                for (var i = 0; i < liste.length; i++)
                  _Kachel(
                    bild: liste[i],
                    onTap: () => _oeffne(context, liste, i),
                  ),
              ],
            ),
    );
  }

  void _oeffne(BuildContext context, List<Beispielbild> liste, int start) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BeispielbildBetrachter(bilder: liste, start: start),
      ),
    );
  }
}

/// Ueberschrift, Hinweis und die waagerechte Liste.
class _Reihe extends StatelessWidget {
  const _Reihe({required this.kacheln});

  final List<Widget> kacheln;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.gapM),
        Text(
          texte.beispielbilderTitel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: farben.textSekundaer,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        SizedBox(
          height: Beispielbilder.kachelHoehe,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Ohne das schluckt die Liste den senkrechten Zug des Reports.
            physics: const ClampingScrollPhysics(),
            itemCount: kacheln.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppTheme.gapXs),
            itemBuilder: (_, i) => kacheln[i],
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        Text(
          texte.beispielbilderHinweis,
          style: TextStyle(fontSize: 11, color: farben.textSekundaer),
        ),
      ],
    );
  }
}

/// Eine Kachel in der Reihe.
class _Kachel extends StatelessWidget {
  const _Kachel({required this.bild, required this.onTap});

  final Beispielbild bild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;

    return Semantics(
      button: true,
      label: bild.beschreibung.isEmpty
          ? texte.beispielbildOeffnen
          : '${texte.beispielbildOeffnen}: ${bild.beschreibung}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: SizedBox(
            width: Beispielbilder.kachelBreite,
            height: Beispielbilder.kachelHoehe,
            child: _Bildflaeche(adresse: bild.vorschau),
          ),
        ),
      ),
    );
  }
}

/// Das Bild selbst – oder der Platzhalter an seiner Stelle.
///
/// Drei Faelle, eine Flaeche: Es gibt keine Adresse (Demo-Modus), das Bild
/// laedt noch, das Bild ist nicht gekommen. Alle drei sehen gleich aus, weil
/// keiner davon dem Nutzer etwas zu tun gibt.
class _Bildflaeche extends StatelessWidget {
  const _Bildflaeche({required this.adresse});

  final String adresse;

  @override
  Widget build(BuildContext context) {
    if (adresse.isEmpty) return const _Platzhalter(voll: true);

    return Image.network(
      adresse,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (_, kind, fortschritt) =>
          fortschritt == null ? kind : const _Platzhalter(voll: true),
      errorBuilder: (_, _, _) => const _Platzhalter(voll: true),
    );
  }
}

/// Eine ruhige Flaeche in der Groesse einer Kachel.
class _Platzhalter extends StatelessWidget {
  const _Platzhalter({this.voll = false});

  /// `true`, wenn der Platzhalter schon in einer Kachel steckt und deshalb
  /// keine eigene Groesse und keine eigenen Ecken braucht.
  final bool voll;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    final flaeche = DecoratedBox(
      decoration: BoxDecoration(
        color: farben.flaecheHoch,
        borderRadius: voll ? null : BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 22,
          color: farben.textSekundaer.withValues(alpha: 0.5),
        ),
      ),
    );

    if (voll) return SizedBox.expand(child: flaeche);

    return SizedBox(
      width: Beispielbilder.kachelBreite,
      height: Beispielbilder.kachelHoehe,
      child: flaeche,
    );
  }
}

/// Vollbild mit Wischen zwischen den Bildern.
///
/// Die Nennung des Fotografen steht fest am unteren Rand und ist anklickbar –
/// die Pexels-Lizenz verlangt beides, Namen und Rueckweg zur Quelle.
class BeispielbildBetrachter extends StatefulWidget {
  const BeispielbildBetrachter({
    super.key,
    required this.bilder,
    required this.start,
  });

  final List<Beispielbild> bilder;
  final int start;

  @override
  State<BeispielbildBetrachter> createState() =>
      _BeispielbildBetrachterState();
}

class _BeispielbildBetrachterState extends State<BeispielbildBetrachter> {
  late final PageController _seiten = PageController(initialPage: widget.start);
  late int _aktuell = widget.start;

  @override
  void dispose() {
    _seiten.dispose();
    super.dispose();
  }

  Future<void> _zurQuelle(String adresse) async {
    final ziel = Uri.tryParse(adresse);
    if (ziel == null) return;
    // Scheitert das Oeffnen, passiert nichts weiter – ein Fehlerdialog fuer
    // einen Link, den niemand angefordert hat, waere Laerm.
    await launchUrl(ziel, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final bild = widget.bilder[_aktuell];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _seiten,
            itemCount: widget.bilder.length,
            onPageChanged: (i) => setState(() => _aktuell = i),
            itemBuilder: (_, i) {
              final adresse = widget.bilder[i].gross;
              return Center(
                child: adresse.isEmpty
                    ? _DemoFlaeche(text: texte.beispielbildDemo)
                    : Image.network(
                        adresse,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, kind, fortschritt) =>
                            fortschritt == null
                                ? kind
                                : const CircularProgressIndicator(),
                        errorBuilder: (_, _, _) =>
                            _DemoFlaeche(text: texte.beispielbildDemo),
                      ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: texte.zurueck,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.gapM),
                color: Colors.black.withValues(alpha: 0.55),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.bilder.length > 1)
                      Text(
                        texte.beispielbildZaehler(
                          _aktuell + 1,
                          widget.bilder.length,
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: AppTheme.gapXs),
                    Text(
                      texte.beispielbildFotograf(bild.fotograf),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: AppTheme.gapXs),
                    TextButton.icon(
                      onPressed: () => _zurQuelle(bild.quelle),
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        texte.beispielbildQuelle,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Steht im Vollbild anstelle eines Fotos, das es nicht gibt.
class _DemoFlaeche extends StatelessWidget {
  const _DemoFlaeche({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.gapXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: AppTheme.gapS),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
