import 'dart:io';

import '../../capture/models/aufnahme_typ.dart';
import '../../direction/models/richtung.dart';
import '../models/analyse_modus.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../../../core/firebase/firebase_start.dart';
import '../../../core/l10n/sprache.dart';
import '../../../core/netz/wiederholung.dart';
import '../models/analysis_result.dart';
import 'analyse_anfrage.dart';
import 'analysis_service.dart';
import 'functions_client.dart';

/// Vision-Analyse ueber die eigene Cloud Function.
///
/// Ersetzt den fruheren Direktaufruf gegen die Gemini-API. Der Ablauf ist
/// derselbe geblieben – Bilder sammeln, fragen, Ergebnis lesen –, nur liegen
/// Schluessel, Prompt, Kontingent und der Wiederholungsversuch bei unlesbarem
/// JSON jetzt auf dem Server.
class FunctionsAnalysisService implements AnalysisService {
  FunctionsAnalysisService({FunctionsClient? client})
      : _client = client ?? FunctionsClient();

  final FunctionsClient _client;

  @override
  Future<AnalysisResult> analysiere({
    required Map<AufnahmeTyp, File> fotos,
    required Set<AnalyseModul> module,
    required OnboardingProfile onboarding,
    required ModulEingaben eingaben,
    required Sprache sprache,
    Richtung richtung = Richtung.leer,
    AnalyseModus modus = AnalyseModus.standard,
    Abbruch? abbruch,
  }) async {
    if (fotos.isEmpty) {
      throw const AnalysisException(AnalysisFehler.fotosFehlen);
    }

    final reihenfolge = AufnahmeTyp.values.where(fotos.containsKey).toList();

    final bilder = <AufnahmeTyp, String>{};
    for (final typ in reihenfolge) {
      final datei = fotos[typ]!;
      if (!await datei.exists()) {
        throw const AnalysisException(AnalysisFehler.fotosFehlen);
      }
      bilder[typ] = await base64Bild(datei);
    }

    final antwort = await _client.rufe(
      FirebaseKonfig.functionAnalysiere,
      AnalyseAnfrage.bauen(
        bilder: bilder,
        module: module,
        onboarding: onboarding,
        eingaben: eingaben,
        sprache: sprache,
        richtung: richtung,
        modus: modus,
      ),
      abbruch: abbruch,
    );

    final roh = antwort['ergebnis'];
    if (roh is! Map) {
      throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
    }

    final ergebnis = AnalysisResult.vonApi(
      Map<String, dynamic>.from(roh),
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      erstelltAm: DateTime.now(),
      richtung: richtung,
      modus: modus,
    );

    // Die Function prueft nur grob, ob Kapitel vorhanden sind. Ob der Report
    // inhaltlich trägt, entscheidet weiterhin das Modell hier.
    if (!ergebnis.istVollstaendig) {
      throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
    }

    return ergebnis;
  }
}
