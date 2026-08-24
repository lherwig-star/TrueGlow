import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/aufnahme_typ.dart';
import '../models/captured_photo.dart';
import '../models/photo_check_result.dart';

/// Prueft Fotos on-device (ML Kit Face Detection) und komprimiert sie fuer den
/// spaeteren API-Call. Es verlaesst nichts das Geraet, solange die Analyse nicht
/// bewusst gestartet wird.
class ImageQualityService {
  ImageQualityService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            // Schnellmodus reicht: wir brauchen nur Position und Groesse.
            performanceMode: FaceDetectorMode.fast,
            // Bewusst klein, damit auch ein zu kleines Gesicht noch gefunden
            // wird – sonst meldet die App "kein Gesicht" statt "zu klein".
            minFaceSize: 0.05,
          ),
        );

  final FaceDetector _detector;

  /// Mittlere Helligkeit (0–255), unter der ein Bild als zu dunkel gilt.
  static const int minHelligkeit = 55;

  /// Laengste Kante des hochgeladenen Bildes – spart Tokens und Kosten.
  static const int maxKantenlaenge = 1024;

  /// JPEG-Qualitaet des komprimierten Uploads.
  static const int jpegQualitaet = 80;

  /// Fuehrt den kompletten Check durch und legt bei Erfolg die komprimierte
  /// Datei im App-Verzeichnis ab.
  ///
  /// [namensraum] trennt Dateien, die denselben Aufnahmetyp haben, aber
  /// nebeneinander bestehen bleiben muessen – etwa das Erstfoto und das
  /// Fortschrittsfoto eines Check-ins. Ohne Angabe gilt der Typname.
  Future<PhotoCheckResult> pruefeUndVerarbeite({
    required File datei,
    required AufnahmeTyp typ,
    String? namensraum,
  }) async {
    try {
      final rohdaten = await datei.readAsBytes();

      // Dekodieren und Helligkeit messen laeuft in einem eigenen Isolate,
      // damit die UI waehrend der Verarbeitung nicht einfriert.
      final info = await compute(_leseBildinfo, rohdaten);
      if (info == null) {
        return const PhotoCheckFehler(PhotoProblem.ungueltigeDatei);
      }

      final fehler = await _pruefeGesicht(datei, typ.pruefung, info);
      if (fehler != null) return PhotoCheckFehler(fehler);

      if (info.helligkeit < minHelligkeit) {
        return const PhotoCheckFehler(PhotoProblem.zuDunkel);
      }

      final verkleinert = await compute(_skaliereUndKomprimiere, rohdaten);
      if (verkleinert == null) {
        return const PhotoCheckFehler(PhotoProblem.ungueltigeDatei);
      }

      final ziel = await _zieldatei(namensraum ?? typ.name);
      await ziel.writeAsBytes(verkleinert.daten, flush: true);

      return PhotoCheckOk(
        CapturedPhoto(
          typ: typ,
          pfad: ziel.path,
          breite: verkleinert.breite,
          hoehe: verkleinert.hoehe,
          groesseInBytes: verkleinert.daten.length,
        ),
      );
    } catch (e, s) {
      debugPrint('Qualitaetscheck fehlgeschlagen: $e\n$s');
      return const PhotoCheckFehler(PhotoProblem.fehlgeschlagen);
    }
  }

  /// Gesichtspruefung nach dem Profil der Aufnahme.
  ///
  /// Ganzkoerper- und Outfit-Aufnahmen laufen hier gar nicht erst durch die
  /// Erkennung: dort ist ein Gesicht entweder winzig oder gar nicht im Bild,
  /// und der alte Pauschal-Check haette sie immer abgelehnt.
  Future<PhotoProblem?> _pruefeGesicht(
    File datei,
    Pruefprofil profil,
    _Bildinfo info,
  ) async {
    if (!profil.pruefeGesicht) return null;

    final gesichter =
        await _detector.processImage(InputImage.fromFilePath(datei.path));

    if (gesichter.isEmpty) {
      return profil.gesichtPflicht ? PhotoProblem.keinGesicht : null;
    }
    // Mehrere Personen stoeren nur da, wo genau ein Portrait erwartet wird.
    if (profil.gesichtPflicht && gesichter.length > 1) {
      return PhotoProblem.mehrereGesichter;
    }

    // Flaechenvergleich ist unabhaengig von der EXIF-Drehung: ML Kit liefert
    // die Box im gedrehten Bild, die Gesamtflaeche bleibt dabei gleich. Bei
    // mehreren Gesichtern zaehlt das groesste.
    final box = gesichter
        .map((g) => g.boundingBox)
        .reduce((a, b) => a.width * a.height >= b.width * b.height ? a : b);

    final bildflaeche = (info.breite * info.hoehe).toDouble();
    if (bildflaeche <= 0) return PhotoProblem.ungueltigeDatei;

    final anteil = (box.width * box.height) / bildflaeche;
    return anteil < profil.minFlaeche ? PhotoProblem.zuKlein : null;
  }

  /// Zielpfad im App-Verzeichnis. Der Zeitstempel im Namen sorgt dafuer, dass
  /// eine neue Aufnahme nicht am Bild-Cache von Flutter haengen bleibt; die
  /// vorherige Datei desselben Typs wird vorher aufgeraeumt.
  Future<File> _zieldatei(String namensraum) async {
    final ordner = await _fotoOrdner();

    await for (final eintrag in ordner.list()) {
      final name = eintrag.path.split(Platform.pathSeparator).last;
      if (eintrag is File && name.startsWith('${namensraum}_')) {
        await eintrag.delete().catchError((_) => eintrag);
      }
    }

    final stempel = DateTime.now().millisecondsSinceEpoch;
    return File('${ordner.path}/${namensraum}_$stempel.jpg');
  }

  Future<Directory> _fotoOrdner() async {
    final verzeichnis = await getApplicationDocumentsDirectory();
    final ordner = Directory('${verzeichnis.path}/glowup_fotos');
    if (!await ordner.exists()) {
      await ordner.create(recursive: true);
    }
    return ordner;
  }

  /// Entfernt alle abgelegten Fotos – Teil der DSGVO-Loeschfunktion in den
  /// Einstellungen.
  Future<void> fotosLoeschen() async {
    try {
      final ordner = await _fotoOrdner();
      await ordner.delete(recursive: true);
    } catch (e) {
      debugPrint('Fotos konnten nicht geloescht werden: $e');
    }
  }

  void dispose() => _detector.close();
}

/// Ergebnis der Bildanalyse im Isolate.
typedef _Bildinfo = ({int breite, int hoehe, int helligkeit});

/// Ergebnis der Komprimierung im Isolate.
typedef _Komprimiert = ({Uint8List daten, int breite, int hoehe});

/// Laeuft im Isolate: Masse ermitteln und mittlere Helligkeit schaetzen.
_Bildinfo? _leseBildinfo(Uint8List rohdaten) {
  final bild = img.decodeImage(rohdaten);
  if (bild == null) return null;

  // Fuer die Helligkeit reicht eine stark verkleinerte Kopie.
  final klein = img.copyResize(bild, width: 64);
  var summe = 0;
  for (final pixel in klein) {
    summe += img.getLuminance(pixel).round();
  }
  final helligkeit = summe ~/ (klein.width * klein.height);

  return (breite: bild.width, hoehe: bild.height, helligkeit: helligkeit);
}

/// Laeuft im Isolate: auf maximale Kantenlaenge verkleinern und als JPEG
/// speichern. Die EXIF-Drehung wird dabei fest ins Bild gerechnet, damit die
/// Vision-API kein gekipptes Gesicht sieht.
_Komprimiert? _skaliereUndKomprimiere(Uint8List rohdaten) {
  final dekodiert = img.decodeImage(rohdaten);
  if (dekodiert == null) return null;

  final bild = img.bakeOrientation(dekodiert);
  final laengsteKante = bild.width > bild.height ? bild.width : bild.height;

  final skaliert = laengsteKante <= ImageQualityService.maxKantenlaenge
      ? bild
      : img.copyResize(
          bild,
          width: bild.width >= bild.height
              ? ImageQualityService.maxKantenlaenge
              : null,
          height: bild.height > bild.width
              ? ImageQualityService.maxKantenlaenge
              : null,
          interpolation: img.Interpolation.average,
        );

  final jpeg = img.encodeJpg(
    skaliert,
    quality: ImageQualityService.jpegQualitaet,
  );

  return (daten: jpeg, breite: skaliert.width, hoehe: skaliert.height);
}
