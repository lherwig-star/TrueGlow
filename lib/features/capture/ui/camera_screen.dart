import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/diagnose/diagnose_dienst.dart';
import '../../../core/l10n/texte.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../../checkin/logic/checkin_controller.dart';
import '../logic/auto_ausloeser.dart';
import '../logic/capture_controller.dart';
import '../logic/live_face_guide.dart';
import '../logic/live_koerper_guide.dart';
import '../logic/signalton.dart';
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
  final LiveKoerperGuide _koerperGuide = const LiveKoerperGuide();
  final ImagePicker _picker = ImagePicker();

  /// Nur fuer die Ganzkoerperfotos – die Posenerkennung haelt native
  /// Ressourcen und wird sonst nicht angelegt.
  late final PoseDetector? _pose = widget.typ.autoAusloeser
      ? PoseDetector(options: PoseDetectorOptions())
      : null;

  late final AutoAusloeser? _auto =
      widget.typ.autoAusloeser ? AutoAusloeser() : null;

  CameraController? _controller;
  List<CameraDescription> _kameras = const [];
  late CameraLensDirection _richtung = widget.typ.rueckkamera
      ? CameraLensDirection.back
      : CameraLensDirection.front;

  LiveHinweis _hinweis = LiveHinweis.keinGesicht;
  _Kamerafehler? _fehler;
  bool _startet = true;
  bool _loest = false;

  /// Haltungs-Rueckmeldung bei den Ganzkoerperfotos.
  KoerperHinweis _koerperHinweis = KoerperHinweis.niemand;

  /// Stand des Countdowns.
  AutoZustand _autoZustand = const AutoZustand(AutoPhase.warten);

  /// Die zuletzt vertonte Sekunde – ohne das kaeme bei vier Frames pro
  /// Sekunde viermal derselbe Ton.
  int? _letzteVertonteSekunde;

  /// Die eben gemachte Aufnahme, solange sie noch nicht bestaetigt ist.
  ///
  /// Sie liegt hier bewusst **vor** dem Qualitaetscheck: Verwackelt, Augen zu,
  /// falscher Bildausschnitt – das sieht ein Mensch sofort und keine Pruefung
  /// zuverlaessig. Erst „Passt" schickt die Datei durch den Check und in den
  /// Aufnahmen-Index. Bei Ganzkoerperfotos aus drei Metern Abstand ist das der
  /// einzige Moment, in dem das Ergebnis ueberhaupt zu beurteilen ist.
  File? _vorschau;

  /// Steht hier ein Text, ist die letzte Aufnahme fehlgeschlagen.
  ///
  /// Ohne diese Anzeige endete ein Fehlschlag in einem `debugPrint` und sonst
  /// nirgends: Wer drei Meter entfernt steht, sah den Countdown ablaufen und
  /// danach nichts – nicht zu unterscheiden von einem Ausloeser, der gar
  /// nicht erst angesprungen ist.
  String? _fehlschlag;

  /// Verhindert, dass sich Frames stauen: waehrend eine Erkennung laeuft,
  /// werden neue Frames verworfen.
  bool _erkennungLaeuft = false;
  DateTime _letztePruefung = DateTime.fromMillisecondsSinceEpoch(0);

  /// Praefix aller Protokollzeilen dieses Screens.
  ///
  /// Ein fester Text, damit sich der komplette Weg vom Countdown-Ende bis zur
  /// fertigen Datei mit einem `adb logcat | grep` verfolgen laesst.
  static const _marke = 'TrueGlow/Aufnahme';

  void _protokoll(String text) => debugPrint('$_marke: $text');

  /// Spielt einen Signalton – und laesst die Aufnahme davon unberuehrt.
  ///
  /// Der Ausloese-Ton steht eine Zeile vor der Aufnahme. Riss er ab, riss die
  /// ganze Kette ab: Genau daran hing der tote Auto-Ausloeser. `Signalton`
  /// faengt seine eigenen Abspielfehler zwar ab, aber schon das *Beschaffen*
  /// des Dienstes kann scheitern – ein fehlerhaft gebauter Provider wirft bei
  /// jedem `read` erneut.
  ///
  /// Ein Ton ist Zierde, das Foto ist der Zweck. Was hier schiefgeht, gehoert
  /// ins Protokoll und sonst nirgendwohin.
  void _ton(Future<void> Function(Signalton) welcher) {
    try {
      unawaited(welcher(ref.read(signaltonProvider)));
    } catch (e, spur) {
      _protokoll('Signalton uebersprungen: $e');
      unawaited(ref.read(diagnoseDienstProvider).fehler(e, spur));
    }
  }

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
    _pose?.close();
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

      // Gesichter bei den Portraits, Posen ueberall dort, wo die App selbst
      // ausloest. Die Abfrage bleibt stehen, obwohl derzeit jede Aufnahme
      // einen Strom braucht: Sie ist die eine Stelle, an der eine kuenftige
      // Aufnahme ohne Erkennung wieder aussteigen koennte.
      if (widget.typ.mitBildstrom) {
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
    // Waehrend die Vorschau steht, ist der Sucher verdeckt – jede weitere
    // Erkennung waere Rechenzeit fuer ein Bild, das niemand sieht.
    if (_erkennungLaeuft ||
        _loest ||
        _vorschau != null ||
        !widget.typ.mitBildstrom) {
      return;
    }

    final jetzt = DateTime.now();
    if (jetzt.difference(_letztePruefung) < _taktung) return;
    _letztePruefung = jetzt;
    _erkennungLaeuft = true;

    try {
      final eingabe = _alsInputImage(bild);
      if (eingabe == null) return;

      final groesse = _aufrechteGroesse(eingabe.metadata!);
      final helligkeit = _helligkeit(bild);

      if (widget.typ.autoAusloeser) {
        await _koerperFrame(eingabe, groesse, helligkeit, jetzt);
      } else {
        final gesichter = await _detector.processImage(eingabe);
        if (!mounted) return;

        final hinweis = _guide.bewerte(
          gesichter: [for (final g in gesichter) g.boundingBox],
          bildGroesse: groesse,
          helligkeit: helligkeit,
        );
        if (hinweis != _hinweis) setState(() => _hinweis = hinweis);
      }
    } catch (e) {
      debugPrint('Live-Erkennung uebersprungen: $e');
    } finally {
      _erkennungLaeuft = false;
    }
  }

  /// Ein Frame der Ganzkoerper-Aufnahme: Haltung bewerten, Countdown fuehren,
  /// gegebenenfalls selbst ausloesen.
  Future<void> _koerperFrame(
    InputImage eingabe,
    Size groesse,
    int? helligkeit,
    DateTime jetzt,
  ) async {
    final posen = await _pose!.processImage(eingabe);
    if (!mounted) return;

    final hinweis = _koerperGuide.bewerte(
      lage: _alsKoerperlage(posen),
      bildGroesse: groesse,
      helligkeit: helligkeit,
    );

    final zustand = _auto!.melde(bereit: hinweis.loestAus, jetzt: jetzt);

    if (hinweis != _koerperHinweis || zustand != _autoZustand) {
      // Nur bei Aenderung, sonst waeren es vier Zeilen je Sekunde. Damit ist
      // im Protokoll ablesbar, ob der Countdown ueberhaupt bis zum Ende lief
      // oder ob die Haltung kurz davor verloren ging.
      _protokoll('Haltung ${hinweis.name}, Countdown $zustand');
      setState(() {
        _koerperHinweis = hinweis;
        _autoZustand = zustand;
      });
    }

    switch (zustand.phase) {
      case AutoPhase.zaehlt:
        if (zustand.verbleibend != _letzteVertonteSekunde) {
          _letzteVertonteSekunde = zustand.verbleibend;
          // Der neue Countdown ersetzt die Meldung des letzten Fehlschlags.
          if (_fehlschlag != null) setState(() => _fehlschlag = null);
          _ton((ton) => ton.zaehlen());
        }
      case AutoPhase.warten:
        _letzteVertonteSekunde = null;
      case AutoPhase.ausgeloest:
        _letzteVertonteSekunde = null;
        _protokoll('Countdown zu Ende – Auto-Ausloeser greift');
        _ton((ton) => ton.ausloesen());
        await _ausloesen();
    }
  }

  /// Uebersetzt die ML-Kit-Pose in die Form, mit der [LiveKoerperGuide]
  /// rechnet – Rechteck plus zwei Flags, sonst nichts.
  Koerperlage? _alsKoerperlage(List<Pose> posen) {
    if (posen.isEmpty) return null;

    // Nur sichere Punkte: Bei niedriger Wahrscheinlichkeit raet ML Kit die
    // Lage, und ein geratener Knoechel liesse den Ausloeser zu frueh
    // anspringen.
    const mindestGuete = 0.5;
    final punkte = posen.first.landmarks.values
        .where((p) => p.likelihood >= mindestGuete)
        .toList();
    if (punkte.isEmpty) return null;

    var links = double.infinity;
    var rechts = double.negativeInfinity;
    var oben = double.infinity;
    var unten = double.negativeInfinity;

    for (final p in punkte) {
      links = math.min(links, p.x);
      rechts = math.max(rechts, p.x);
      oben = math.min(oben, p.y);
      unten = math.max(unten, p.y);
    }

    bool sicher(PoseLandmarkType typ) =>
        (posen.first.landmarks[typ]?.likelihood ?? 0) >= mindestGuete;

    return Koerperlage(
      umriss: Rect.fromLTRB(links, oben, rechts, unten),
      kopfSichtbar: sicher(PoseLandmarkType.nose),
      // Beide Knoechel: Steht nur einer im Bild, ist die Person angeschnitten
      // oder verdreht – in beiden Faellen taugt das Foto nicht.
      fuesseSichtbar: sicher(PoseLandmarkType.leftAnkle) &&
          sicher(PoseLandmarkType.rightAnkle),
    );
  }

  /// Mittlere Helligkeit des Frames (0–255), oder `null`, wenn sie sich nicht
  /// bestimmen laesst.
  ///
  /// Nur jedes 16. Pixel wird gelesen. Ein Mittelwert braucht keine
  /// Vollstaendigkeit, und bei vier Frames pro Sekunde in Vollaufloesung waere
  /// sie auf schwachen Geraeten spuerbar.
  int? _helligkeit(CameraImage bild) {
    final bytes = bild.planes.first.bytes;
    if (bytes.isEmpty) return null;

    var summe = 0;
    var anzahl = 0;

    if (Platform.isAndroid) {
      // NV21: Die erste Ebene ist der Luma-Kanal – ein Byte je Pixel, und
      // genau die Groesse, die der Check nach dem Ausloesen misst.
      for (var i = 0; i < bytes.length; i += 16) {
        summe += bytes[i];
        anzahl++;
      }
    } else {
      // BGRA8888: Luminanz aus den Farbkanaelen, vier Bytes je Pixel.
      for (var i = 0; i + 2 < bytes.length; i += 64) {
        summe +=
            (0.0722 * bytes[i] + 0.7152 * bytes[i + 1] + 0.2126 * bytes[i + 2])
                .round();
        anzahl++;
      }
    }

    return anzahl == 0 ? null : summe ~/ anzahl;
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

  /// Die komplette Kette vom Ausloesen bis zur stehenden Vorschau.
  ///
  /// Jeder Schritt landet im Protokoll. Der Grund steht bei [_fehlschlag]:
  /// Beim Auto-Ausloeser sieht niemand zu, und ein hier verschluckter Fehler
  /// ist von aussen nicht von einem nicht ausgeloesten Countdown zu
  /// unterscheiden.
  Future<void> _ausloesen() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _loest ||
        _vorschau != null) {
      _protokoll(
        'Ausloesen uebersprungen – kamera=${controller != null}, '
        'initialisiert=${controller?.value.isInitialized ?? false}, '
        'laeuft=$_loest, vorschau=${_vorschau != null}',
      );
      return;
    }

    setState(() {
      _loest = true;
      _fehlschlag = null;
    });
    _protokoll('Ausloesen gestartet (${widget.typ.name})');

    try {
      // Der Stream muss vor der Aufnahme stehen, sonst streiten sich
      // Standbild und Vorschau um den Sensor.
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
        _protokoll('Bildstrom gestoppt');
      }

      final aufnahme = await controller.takePicture();
      _protokoll('Datei geschrieben: ${aufnahme.path}');

      if (!mounted) return;

      // Noch nichts uebernehmen – erst zeigt die Vorschau das Bild.
      setState(() {
        _vorschau = File(aufnahme.path);
        _loest = false;
      });
      _protokoll('Vorschau steht');
    } catch (e, spur) {
      await _aufnahmeFehlgeschlagen(e, spur);
    }
  }

  /// Nach einem Fehlschlag zurueck in den Sucher – und zwar so, dass ein
  /// zweiter Versuch ueberhaupt zustande kommt.
  Future<void> _aufnahmeFehlgeschlagen(Object fehler, StackTrace spur) async {
    _protokoll('Aufnahme fehlgeschlagen: $fehler\n$spur');
    unawaited(ref.read(diagnoseDienstProvider).fehler(fehler, spur));

    if (!mounted) return;
    setState(() {
      _loest = false;
      _fehlschlag = context.texte.aufnahmeFehlgeschlagen;
      // Ohne Zuruecksetzen bliebe der Auto-Ausloeser auf „ausgeloest" stehen:
      // Der Countdown liefe kein zweites Mal an, und wer drei Meter entfernt
      // steht, wartet vor einer Kamera, die nichts mehr tut.
      _auto?.zuruecksetzen();
      _autoZustand = const AutoZustand(AutoPhase.warten);
      _letzteVertonteSekunde = null;
    });

    // Vorschau wieder anwerfen, damit der Nutzer es erneut versuchen kann.
    await _bildstromStarten();
  }

  /// Startet den Bildstrom, falls er stehen sollte und gerade nicht laeuft.
  Future<void> _bildstromStarten() async {
    final controller = _controller;
    if (!widget.typ.mitBildstrom ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.startImageStream(_frameVerarbeiten);
      _protokoll('Bildstrom wieder gestartet');
    } catch (e, spur) {
      // Ohne Strom steht nur die Live-Hilfe still; der Ausloeser bleibt
      // druckbar. Kein Grund, den Screen zu verlassen – aber sichtbar machen.
      _protokoll('Bildstrom nicht startbar: $e\n$spur');
      unawaited(ref.read(diagnoseDienstProvider).fehler(e, spur));
    }
  }

  /// „Nochmal": Aufnahme wegwerfen und zurueck in den Sucher.
  Future<void> _vorschauVerwerfen() async {
    final datei = _vorschau;
    setState(() {
      _vorschau = null;
      // Ohne Zuruecksetzen bliebe der Ausloeser auf „ausgeloest" stehen und
      // der zweite Versuch kaeme nie zustande.
      _auto?.zuruecksetzen();
      _autoZustand = const AutoZustand(AutoPhase.warten);
      _koerperHinweis = KoerperHinweis.niemand;
      _letzteVertonteSekunde = null;
      _fehlschlag = null;
    });

    // Die Datei liegt im Cache-Verzeichnis der Kamera. Wegraeumen, sonst
    // sammelt jeder verworfene Versuch ein Vollbild-JPEG an.
    try {
      await datei?.delete();
    } catch (e) {
      debugPrint('Verworfene Aufnahme nicht loeschbar: $e');
    }

    // Der Bildstrom wurde vor dem Ausloesen gestoppt – ohne ihn steht die
    // Live-Hilfe still und der Ausloeser bliebe dauerhaft blass.
    await _bildstromStarten();
  }

  /// „Passt": jetzt erst durch den Qualitaetscheck und in den Index.
  Future<void> _vorschauBestaetigen() async {
    final datei = _vorschau;
    if (datei == null) return;

    setState(() => _loest = true);
    final angenommen = await _uebernehmen(datei);

    if (!mounted) return;
    // In beiden Faellen zurueck zum Foto-Schritt: dort steht entweder das
    // gepruefte Bild oder die Problemkarte mit dem konkreten Tipp.
    Navigator.of(context).pop(angenommen);
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
    final texte = context.texte;
    final controller = _controller;

    // Ohne Erkennung gibt es nichts zu treffen – dann ist der Ausloeser
    // dauerhaft hervorgehoben statt dauerhaft blass.
    final bereit = switch (widget.typ) {
      final t when t.autoAusloeser => _koerperHinweis.loestAus,
      final t when t.mitLiveHilfe => _hinweis.bereit,
      _ => true,
    };

    // Ein Fehlschlag schlaegt die Positionierungshilfe: Wer gerade kein Foto
    // bekommen hat, braucht diese Nachricht und nicht „Steht – nicht bewegen".
    final statustext = _fehlschlag ??
        (widget.typ.autoAusloeser
            ? _koerperHinweis.text(
                texte,
                personOptional: widget.typ.personOptional,
              )
            : _hinweis.text(texte));

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
              overlay: widget.typ.overlayFuer(ref.watch(ausrichtungProvider)),
              farbe: bereit
                  ? farben.akzent
                  : Colors.white.withValues(alpha: 0.65),
              staerke: bereit ? 3.5 : 2,
            ),
            SafeArea(
              child: Column(
                children: [
                  _Kopfzeile(
                    label: widget.typ.label(texte),
                    onSchliessen: () => Navigator.of(context).pop(false),
                  ),
                  const Spacer(),
                  // Jede Aufnahme hat inzwischen eine Erkennung, also auch
                  // eine Statuszeile. Die frueher hier stehende stumme
                  // Anleitung fuer die Outfit-Fotos ist damit weg – ihr Text
                  // steht unveraendert eine Ebene hoeher im Foto-Schritt.
                  _Statustext(
                    text: statustext,
                    bereit: bereit && _fehlschlag == null,
                  ),
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
          if (_autoZustand.phase == AutoPhase.zaehlt && _vorschau == null)
            _Countdown(sekunden: _autoZustand.verbleibend),
          if (_vorschau case final datei?)
            _Vorschaupruefung(
              datei: datei,
              laeuft: _loest,
              onUebernehmen: _vorschauBestaetigen,
              onWiederholen: _vorschauVerwerfen,
            ),
          if (_loest) const _PruefUeberlagerung(),
        ],
      ),
    );
  }
}

/// Die verbleibenden Sekunden, so gross wie moeglich.
///
/// Aus drei Metern Abstand ist eine gewoehnliche Ziffer nicht mehr zu lesen –
/// deshalb fuellt sie hier die halbe Bildhoehe und liegt auf einem
/// abgedunkelten Kreis, damit sie sich vom Kamerabild abhebt. Das ist die
/// einzige Rueckmeldung darueber, wie lange noch stillzuhalten ist.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.sekunden});

  final int sekunden;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    // „Animationen reduzieren" respektieren: Der Puls ist Zierde, die Ziffer
    // ist die Information. Ohne Bewegung bleibt sie vollstaendig erhalten.
    final ohneBewegung = MediaQuery.disableAnimationsOf(context);

    final ziffer = Semantics(
      liveRegion: true,
      label: 'Noch $sekunden',
      child: Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: farben.akzent, width: 4),
        ),
        child: Text(
          '$sekunden',
          style: TextStyle(
            color: Colors.white,
            fontSize: 128,
            fontWeight: FontWeight.w800,
            height: 1,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 12),
            ],
          ),
        ),
      ),
    );

    return Center(
      child: ohneBewegung
          ? ziffer
          : TweenAnimationBuilder<double>(
              // Der Schluessel setzt die Animation je Sekunde neu auf, sonst
              // pulst nur die erste Ziffer.
              key: ValueKey(sekunden),
              tween: Tween(begin: 0.7, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, wert, kind) =>
                  Transform.scale(scale: wert, child: kind),
              child: ziffer,
            ),
    );
  }
}

/// Das eben aufgenommene Bild mit „Passt" und „Nochmal".
///
/// Vollflaechig und nicht als Dialog: Beurteilt werden soll das Foto, nicht
/// eine Frage darueber. Aus drei Metern Abstand ist das ausserdem der einzige
/// Moment, in dem ueberhaupt etwas zu erkennen ist.
class _Vorschaupruefung extends StatelessWidget {
  const _Vorschaupruefung({
    required this.datei,
    required this.laeuft,
    required this.onUebernehmen,
    required this.onWiederholen,
  });

  final File datei;
  final bool laeuft;
  final VoidCallback onUebernehmen;
  final VoidCallback onWiederholen;

  @override
  Widget build(BuildContext context) {
    final texte = context.texte;
    final farben = context.farben;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            datei,
            fit: BoxFit.contain,
            // Der Pfad wechselt bei jeder Aufnahme, der Key haelt Flutter
            // trotzdem davon ab, ein zwischengespeichertes Bild zu zeigen.
            key: ValueKey(datei.path),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black87],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppTheme.gapM),
                Text(
                  texte.vorschauTitel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.gapXs),
                Text(
                  texte.vorschauHinweis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.gapL,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: laeuft ? null : onWiederholen,
                          icon: const Icon(Icons.refresh),
                          label: Text(texte.vorschauWiederholen),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.gapS + 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.gapS),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: laeuft ? null : onUebernehmen,
                          icon: const Icon(Icons.check),
                          label: Text(texte.vorschauUebernehmen),
                          style: FilledButton.styleFrom(
                            backgroundColor: farben.akzent,
                            foregroundColor: farben.aufAkzent,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.gapS + 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.gapM),
              ],
            ),
          ),
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
    final texte = context.texte;
    return ColoredBox(
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
            texte.kameraStartet,
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
    final texte = context.texte;
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
            tooltip: texte.kameraSchliessen,
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
///
/// Nimmt Text und Bereitschaft statt eines Enums: Portrait und Ganzkoerper
/// haben verschiedene Hinweislisten, die Darstellung ist dieselbe.
class _Statustext extends StatelessWidget {
  const _Statustext({required this.text, required this.bereit});

  final String text;
  final bool bereit;

  @override
  Widget build(BuildContext context) {
    final farben = context.farben;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(text),
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
                text,
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
    final texte = context.texte;
    final farben = context.farben;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gapL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RunderKnopf(
            icon: Icons.image_outlined,
            tooltip: texte.fotoGalerie,
            onTap: laeuft ? null : onGalerie,
          ),
          // Immer druckbar – der Ring markiert nur, dass die Haltung passt.
          Semantics(
            button: true,
            label: texte.kameraAusloesen,
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
            tooltip: texte.kameraWechseln,
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
            context.texte.fotoWirdGeprueft,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
    final texte = context.texte;
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
                    ? texte.kameraKeineBerechtigungTitel
                    : texte.kameraNichtVerfuegbarTitel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.gapS),
              Text(
                berechtigung
                    ? texte.kameraKeineBerechtigungText
                    : texte.kameraNichtVerfuegbarText,
                textAlign: TextAlign.center,
                style: TextStyle(color: farben.textSekundaer, height: 1.5),
              ),
              const SizedBox(height: AppTheme.gapL),
              if (berechtigung) ...[
                FilledButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(texte.kameraEinstellungenOeffnen),
                ),
                const SizedBox(height: AppTheme.gapS),
              ],
              OutlinedButton.icon(
                onPressed: onGalerie,
                icon: const Icon(Icons.image_outlined),
                label: Text(texte.fotoGalerie),
              ),
              const SizedBox(height: AppTheme.gapS),
              TextButton(
                onPressed: onSchliessen,
                child: Text(texte.zurueck),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
