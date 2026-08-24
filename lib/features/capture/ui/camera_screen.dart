import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../checkin/logic/checkin_controller.dart';
import '../logic/capture_controller.dart';
import '../logic/live_face_guide.dart';
import '../models/aufnahme_typ.dart';
import 'widgets/silhouette_overlay.dart';

/// Warum die Kamera nicht laeuft.
enum _Kamerafehler { berechtigung, nichtVerfuegbar }

/// Fehlercodes des camera-Plugins, die auf eine verweigerte Berechtigung
/// hinauslaufen – alles andere behandeln wir als "Kamera nicht verfuegbar".
const _verweigert = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
  'cameraPermission',
};

/// Vollbild-Kamera mit Live-Vorschau, Silhouetten-Hilfe und laufender
/// Gesichtserkennung.
///
/// Die Erkennung dient nur der Positionierung – ueber Annahme oder Ablehnung
/// entscheidet weiterhin der Qualitaetscheck nach dem Ausloesen. Der Ausloeser
/// bleibt deshalb immer druckbar; ein "perfekt" hebt ihn nur hervor.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({
    super.key,
    required this.typ,
    this.fuerFortschritt = false,
  });

  final AufnahmeTyp typ;

  /// Fortschrittsfoto eines Check-ins statt Analyse-Aufnahme. Dasselbe
  /// Overlay und derselbe Qualitaetscheck, aber ein anderer Ablageort – das
  /// Erstfoto muss fuer den Vergleich erhalten bleiben.
  final bool fuerFortschritt;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  /// Abstand zwischen zwei ausgewerteten Frames. Rund vier Pruefungen pro
  /// Sekunde reichen fuer eine fluessige Rueckmeldung und lassen der UI Luft.
  static const _taktung = Duration(milliseconds: 250);

  /// Umrechnung der Geraeteausrichtung in Grad – Basis der Rotationsangabe
  /// fuer ML Kit.
  static const _ausrichtungen = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.05,
    ),
  );
  final LiveFaceGuide _guide = const LiveFaceGuide();
  final ImagePicker _picker = ImagePicker();

  CameraController? _controller;
  List<CameraDescription> _kameras = const [];
  late CameraLensDirection _richtung = widget.typ.rueckkamera
      ? CameraLensDirection.back
      : CameraLensDirection.front;

  LiveHinweis _hinweis = LiveHinweis.keinGesicht;
  _Kamerafehler? _fehler;
  bool _startet = true;
  bool _loest = false;

  /// Verhindert, dass sich Frames stauen: waehrend eine Erkennung laeuft,
  /// werden neue Frames verworfen.
  bool _erkennungLaeuft = false;
  DateTime _letztePruefung = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _starten();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState zustand) {
    // Im Hintergrund gibt Android die Kamera frei – beim Zurueckkommen muss
    // sie neu aufgebaut werden. Die Pruefung auf den aktuellen Controller
    // muss deshalb pro Zweig erfolgen: beim Fortsetzen ist er gerade null.
    switch (zustand) {
      case AppLifecycleState.inactive:
        final controller = _controller;
        if (controller == null) return;
        _controller = null;
        controller.dispose();
        if (mounted) setState(() => _startet = true);
      case AppLifecycleState.resumed:
        // Bei verweigerter Berechtigung nicht in einer Schleife neu starten –
        // der Nutzer kommt womoeglich gerade aus den App-Einstellungen und
        // bekommt den Hinweis-Screen mit erneutem Versuch.
        if (_controller == null && _fehler != _Kamerafehler.nichtVerfuegbar) {
          _starten();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _starten() async {
    setState(() {
      _startet = true;
      _fehler = null;
    });

    try {
      if (_kameras.isEmpty) _kameras = await availableCameras();
      if (_kameras.isEmpty) {
        _setzeFehler(_Kamerafehler.nichtVerfuegbar);
        return;
      }

      final beschreibung = _kameras.firstWhere(
        (k) => k.lensDirection == _richtung,
        orElse: () => _kameras.first,
      );
      _richtung = beschreibung.lensDirection;

      final controller = CameraController(
        beschreibung,
        ResolutionPreset.high,
        enableAudio: false,
        // NV21 kann ML Kit direkt lesen; ohne diese Vorgabe muesste jeder
        // Frame von Hand aus den YUV-Ebenen zusammengesetzt werden.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Ganzkoerper- und Outfit-Aufnahmen haben keine Gesichtshilfe – dann
      // laeuft auch kein Bildstrom und keine Erkennung.
      if (widget.typ.mitLiveHilfe) {
        await controller.startImageStream(_frameVerarbeiten);
      }

      setState(() {
        _controller = controller;
        _startet = false;
        _hinweis = LiveHinweis.keinGesicht;
      });
    } on CameraException catch (e) {
      debugPrint('Kamera-Start fehlgeschlagen: ${e.code} ${e.description}');
      _setzeFehler(
        _verweigert.contains(e.code)
            ? _Kamerafehler.berechtigung
            : _Kamerafehler.nichtVerfuegbar,
      );
    } catch (e) {
      debugPrint('Kamera-Start fehlgeschlagen: $e');
      _setzeFehler(_Kamerafehler.nichtVerfuegbar);
    }
  }

  void _setzeFehler(_Kamerafehler fehler) {
    if (!mounted) return;
    setState(() {
      _fehler = fehler;
      _startet = false;
    });
  }

  Future<void> _frameVerarbeiten(CameraImage bild) async {
    if (_erkennungLaeuft || _loest || !widget.typ.mitLiveHilfe) return;

    final jetzt = DateTime.now();
    if (jetzt.difference(_letztePruefung) < _taktung) return;
    _letztePruefung = jetzt;
    _erkennungLaeuft = true;

    try {
      final eingabe = _alsInputImage(bild);
      if (eingabe == null) return;

      final gesichter = await _detector.processImage(eingabe);
      if (!mounted) return;


      final hinweis = _guide.bewerte(
        gesichter: [for (final g in gesichter) g.boundingBox],
        bildGroesse: _aufrechteGroesse(eingabe.metadata!),
      );
      if (hinweis != _hinweis) setState(() => _hinweis = hinweis);
    } catch (e) {
      debugPrint('Live-Erkennung uebersprungen: $e');
    } finally {
      _erkennungLaeuft = false;
    }
  }

  /// Baut aus einem Vorschau-Frame die ML-Kit-Eingabe.
  InputImage? _alsInputImage(CameraImage bild) {
    final controller = _controller;
    if (controller == null || bild.planes.isEmpty) return null;

    final rotation = _rotation(controller.description);
    if (rotation == null) return null;

    // Entspricht der imageFormatGroup, die beim Controller gesetzt wurde.
    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    return InputImage.fromBytes(
      bytes: bild.planes.first.bytes,
      metadata: InputImageMetadata(
        // Rohgroesse des Puffers – ML Kit dreht selbst anhand von [rotation].
        // Hier die gedrehten Kanten anzugeben laesst ML Kit die Bytes
        // zeilenweise falsch lesen und es findet kein einziges Gesicht.
        size: Size(bild.width.toDouble(), bild.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bild.planes.first.bytesPerRow,
      ),
    );
  }

  /// Groesse des aufgerichteten Bildes. In genau diesem System liefert ML Kit
  /// die Gesichtsboxen, deshalb rechnet der [LiveFaceGuide] damit – bei 90
  /// oder 270 Grad sind Breite und Hoehe gegenueber dem Puffer vertauscht.
  Size _aufrechteGroesse(InputImageMetadata metadaten) {
    final gedreht =
        metadaten.rotation == InputImageRotation.rotation90deg ||
            metadaten.rotation == InputImageRotation.rotation270deg;
    return gedreht
        ? Size(metadaten.size.height, metadaten.size.width)
        : metadaten.size;
  }

  InputImageRotation? _rotation(CameraDescription beschreibung) {
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(
        beschreibung.sensorOrientation,
      );
    }

    final geraet = _ausrichtungen[_controller?.value.deviceOrientation ??
        DeviceOrientation.portraitUp];
    if (geraet == null) return null;

    // Frontkamera spiegelt, deshalb wird addiert statt subtrahiert.
    final grad = beschreibung.lensDirection == CameraLensDirection.front
        ? (beschreibung.sensorOrientation + geraet) % 360
        : (beschreibung.sensorOrientation - geraet + 360) % 360;

    return InputImageRotationValue.fromRawValue(grad);
  }

  Future<void> _wechseln() async {
    if (_kameras.length < 2 || _startet) return;

    final controller = _controller;
    _controller = null;
    await controller?.dispose();

    _richtung = _richtung == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    await _starten();
  }

  Future<void> _ausloesen() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _loest) return;

    setState(() => _loest = true);

    try {
      // Der Stream muss vor der Aufnahme stehen, sonst streiten sich
      // Standbild und Vorschau um den Sensor.
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      final aufnahme = await controller.takePicture();
      final angenommen = await _uebernehmen(File(aufnahme.path));

      if (!mounted) return;
      // In beiden Faellen zurueck zum Foto-Schritt: dort steht entweder das
      // gepruefte Bild oder die Problemkarte mit dem konkreten Tipp.
      Navigator.of(context).pop(angenommen);
    } catch (e) {
      debugPrint('Aufnahme fehlgeschlagen: $e');
      if (!mounted) return;
      setState(() => _loest = false);
      // Vorschau wieder anwerfen, damit der Nutzer es erneut versuchen kann.
      if (!(_controller?.value.isStreamingImages ?? true)) {
        await _controller?.startImageStream(_frameVerarbeiten);
      }
    }
  }

  Future<void> _ausGalerie() async {
    final auswahl = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (auswahl == null || !mounted) return;

    setState(() => _loest = true);
    final angenommen = await _uebernehmen(File(auswahl.path));

    if (!mounted) return;
    Navigator.of(context).pop(angenommen);
  }

  /// Leitet die Datei an den zustaendigen Controller weiter.
  Future<bool> _uebernehmen(File datei) {
    if (widget.fuerFortschritt) {
      return ref
          .read(checkinControllerProvider.notifier)
          .fortschrittsfotoUebernehmen(datei);
    }
    return ref
        .read(captureControllerProvider.notifier)
        .uebernehmen(widget.typ, datei);
  }

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final controller = _controller;
    // Ohne Live-Hilfe gibt es nichts zu treffen – dann ist der Ausloeser
    // dauerhaft hervorgehoben statt dauerhaft blass.
    final bereit = widget.typ.mitLiveHilfe ? _hinweis.bereit : true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_fehler != null)
            _Fehlerhinweis(
              fehler: _fehler!,
              onGalerie: _ausGalerie,
              onSchliessen: () => Navigator.of(context).pop(false),
            )
          else if (controller == null || !controller.value.isInitialized)
            const _Startet()
          else ...[
            _Vorschau(controller: controller),
            // Abdunklung aussen, damit die Silhouette klar hervortritt.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0, 0.35, 1],
                ),
              ),
            ),
            SilhouetteOverlay(
              overlay: widget.typ.overlay,
              farbe: bereit
                  ? farben.akzent
                  : Colors.white.withValues(alpha: 0.65),
              staerke: bereit ? 3.5 : 2,
            ),
            SafeArea(
              child: Column(
                children: [
                  _Kopfzeile(
                    label: widget.typ.label,
                    onSchliessen: () => Navigator.of(context).pop(false),
                  ),
                  const Spacer(),
                  if (widget.typ.mitLiveHilfe)
                    _Statustext(hinweis: _hinweis)
                  else
                    _Anleitung(text: widget.typ.hinweis),
                  const SizedBox(height: AppTheme.gapM),
                  _Bedienleiste(
                    bereit: bereit,
                    laeuft: _loest,
                    kannWechseln: _kameras.length > 1,
                    onAusloesen: _ausloesen,
                    onWechseln: _wechseln,
                    onGalerie: _ausGalerie,
                  ),
                  const SizedBox(height: AppTheme.gapM),
                ],
              ),
            ),
          ],
          if (_loest) const _PruefUeberlagerung(),
        ],
      ),
    );
  }
}

/// Fuellt den Bildschirm formatgetreu. [CameraController.value.previewSize]
/// kommt in Querformat-Konvention, deshalb sind die Kanten hier vertauscht.
class _Vorschau extends StatelessWidget {
  const _Vorschau({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final groesse = controller.value.previewSize;
    if (groesse == null) return CameraPreview(controller);

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: groesse.height,
          height: groesse.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _Startet extends StatelessWidget {
  const _Startet();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: AppTheme.gapS),
          Text(
            S.kameraStartet,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Kopfzeile extends StatelessWidget {
  const _Kopfzeile({required this.label, required this.onSchliessen});

  final String label;
  final VoidCallback onSchliessen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.gapS,
        vertical: AppTheme.gapXs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onSchliessen,
            icon: const Icon(Icons.close),
            color: Colors.white,
            tooltip: S.kameraSchliessen,
          ),
          const SizedBox(width: AppTheme.gapXs),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Statuszeile unter der Silhouette.
class _Statustext extends StatelessWidget {
  const _Statustext({required this.hinweis});

  final LiveHinweis hinweis;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final bereit = hinweis.bereit;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(hinweis),
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.gapM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gapM,
          vertical: AppTheme.gapS,
        ),
        decoration: BoxDecoration(
          color: bereit
              ? farben.akzent.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bereit ? Icons.check_circle : Icons.center_focus_weak,
              size: 18,
              color: bereit ? farben.aufAkzent : Colors.white,
            ),
            const SizedBox(width: AppTheme.gapXs + 2),
            Flexible(
              child: Text(
                hinweis.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: bereit ? farben.aufAkzent : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Galerie, Ausloeser, Kamerawechsel.
class _Bedienleiste extends StatelessWidget {
  const _Bedienleiste({
    required this.bereit,
    required this.laeuft,
    required this.kannWechseln,
    required this.onAusloesen,
    required this.onWechseln,
    required this.onGalerie,
  });

  final bool bereit;
  final bool laeuft;
  final bool kannWechseln;
  final VoidCallback onAusloesen;
  final VoidCallback onWechseln;
  final VoidCallback onGalerie;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RunderKnopf(
            icon: Icons.image_outlined,
            tooltip: S.fotoGalerie,
            onTap: laeuft ? null : onGalerie,
          ),
          // Immer druckbar – der Ring markiert nur, dass die Haltung passt.
          Semantics(
            button: true,
            label: S.kameraAusloesen,
            child: GestureDetector(
              onTap: laeuft ? null : onAusloesen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: bereit ? 1 : 0.75),
                  border: Border.all(
                    color: bereit ? farben.akzent : Colors.white54,
                    width: bereit ? 5 : 3,
                  ),
                  boxShadow: bereit
                      ? [
                          BoxShadow(
                            color: farben.akzent.withValues(alpha: 0.5),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          _RunderKnopf(
            icon: Icons.cameraswitch_outlined,
            tooltip: S.kameraWechseln,
            onTap: kannWechseln && !laeuft ? onWechseln : null,
          ),
        ],
      ),
    );
  }
}

class _RunderKnopf extends StatelessWidget {
  const _RunderKnopf({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 26,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.all(14),
      ),
    );
  }
}

class _PruefUeberlagerung extends StatelessWidget {
  const _PruefUeberlagerung();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: AppTheme.gapS),
          Text(
            'Foto wird geprüft...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Kein Zugriff auf die Kamera – mit Weg in die App-Einstellungen und dem
/// Galerie-Import als Ausweichweg.
class _Fehlerhinweis extends StatelessWidget {
  const _Fehlerhinweis({
    required this.fehler,
    required this.onGalerie,
    required this.onSchliessen,
  });

  final _Kamerafehler fehler;
  final VoidCallback onGalerie;
  final VoidCallback onSchliessen;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;
    final berechtigung = fehler == _Kamerafehler.berechtigung;

    return ColoredBox(
      color: farben.hintergrund,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gapM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: farben.warnung.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  berechtigung ? Icons.no_photography_outlined : Icons.videocam_off_outlined,
                  size: 32,
                  color: farben.warnung,
                ),
              ),
              const SizedBox(height: AppTheme.gapM),
              Text(
                berechtigung
                    ? S.kameraKeineBerechtigungTitel
                    : S.kameraNichtVerfuegbarTitel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.gapS),
              Text(
                berechtigung
                    ? S.kameraKeineBerechtigungText
                    : S.kameraNichtVerfuegbarText,
                textAlign: TextAlign.center,
                style: TextStyle(color: farben.textSekundaer, height: 1.5),
              ),
              const SizedBox(height: AppTheme.gapL),
              if (berechtigung) ...[
                FilledButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text(S.kameraEinstellungenOeffnen),
                ),
                const SizedBox(height: AppTheme.gapS),
              ],
              OutlinedButton.icon(
                onPressed: onGalerie,
                icon: const Icon(Icons.image_outlined),
                label: const Text(S.fotoGalerie),
              ),
              const SizedBox(height: AppTheme.gapS),
              TextButton(
                onPressed: onSchliessen,
                child: const Text(S.zurueck),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Steht anstelle der Statuszeile, wenn es keine Live-Erkennung gibt.
class _Anleitung extends StatelessWidget {
  const _Anleitung({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.gapM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.gapM,
        vertical: AppTheme.gapS,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, height: 1.4),
      ),
    );
  }
}
