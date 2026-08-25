import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_modell.dart';
import '../../../core/l10n/sprache.dart';
import '../../../core/diagnose/diagnose_dienst.dart';
import '../../../core/netz/wiederholung.dart';
import '../../../core/storage/hive_service.dart';
import '../../capture/logic/aufnahme_flow.dart';
import '../../consent/logic/einwilligung_controller.dart';
import '../../capture/logic/capture_controller.dart';
import '../../capture/models/aufnahme_typ.dart';
import '../../direction/logic/direction_controller.dart';
import '../../direction/models/richtung.dart';
import '../../history/logic/analysis_repository.dart';
import '../../modules/logic/module_controller.dart';
import '../../modules/models/analyse_modul.dart';
import '../../onboarding/logic/onboarding_controller.dart';
import '../models/analysis_result.dart';
import 'analysis_service.dart';
import 'functions_analysis_service.dart';
import 'mock_analysis_service.dart';

/// Zustand des Analyse-Screens.
sealed class AnalyseZustand {
  const AnalyseZustand();
}

class AnalyseBereit extends AnalyseZustand {
  const AnalyseBereit();
}

class AnalyseLaeuft extends AnalyseZustand {
  const AnalyseLaeuft();
}

class AnalyseFertig extends AnalyseZustand {
  const AnalyseFertig(this.ergebnis);
  final AnalysisResult ergebnis;
}

class AnalyseFehlgeschlagen extends AnalyseZustand {
  const AnalyseFehlgeschlagen(this.fehler);
  final AnalysisFehler fehler;
}

/// Der Nutzer hat abgebrochen. Kein Fehler, deshalb ein eigener Zustand –
/// die UI soll hier nichts erklaeren muessen.
class AnalyseAbgebrochen extends AnalyseZustand {
  const AnalyseAbgebrochen();
}

/// Verbindet Aufnahmen, Modulauswahl, Onboarding-Antworten und Vision-Service
/// und legt das Ergebnis lokal ab.
class AnalysisController extends StateNotifier<AnalyseZustand> {
  AnalysisController(this._ref) : super(const AnalyseBereit());

  final Ref _ref;

  /// Der Abbruchwunsch des laufenden Durchlaufs.
  Abbruch? _abbruch;

  /// Bricht den laufenden Durchlauf ab.
  ///
  /// Was endet, ist das Warten und Wiederholen – eine schon abgeschickte
  /// Anfrage laesst sich nicht zurueckholen. Fuer den Nutzer ist der
  /// Unterschied unsichtbar; fuer die Rechnung nicht, deshalb steht er hier
  /// und nicht auf dem Knopf.
  void abbrechen() {
    _abbruch?.ausloesen();
    _laufmarke(null);
    if (state is AnalyseLaeuft) state = const AnalyseAbgebrochen();
  }

  /// Mit [nurModul] wird ausschliesslich dieses Kapitel erzeugt und in die
  /// bestehende Analyse eingehaengt – der Weg ueber "Analyse erweitern".
  ///
  /// [module] uebersteuert die aktuelle Modulauswahl. Gebraucht wird das beim
  /// Neuberechnen aus dem Report heraus: Dort zaehlt der Umfang des Reports,
  /// nicht das, was gerade in der Auswahl steht.
  Future<void> starten({
    AnalyseModul? nurModul,
    Set<AnalyseModul>? module,
  }) async {
    if (state is AnalyseLaeuft) return;

    // Ohne gueltige Foto-Einwilligung verlaesst kein Bild das Geraet. Die
    // Pruefung steht hier und nicht in der UI: Es ist der einzige Weg, auf
    // dem eine Analyse startet.
    if (!_ref.read(analyseErlaubtProvider)) {
      state = const AnalyseFehlgeschlagen(AnalysisFehler.einwilligungFehlt);
      return;
    }

    final aufnahmen = _ref.read(captureControllerProvider);
    final modulZustand = _ref.read(moduleControllerProvider);
    final richtung = _ref.read(directionControllerProvider);
    final gewaehlteModule = module ?? modulZustand.module;

    final pflicht = pflichtAufnahmen(gewaehlteModule, nur: nurModul);
    if (!aufnahmen.vollstaendig(pflicht)) {
      state = const AnalyseFehlgeschlagen(AnalysisFehler.fotosFehlen);
      return;
    }

    // Beim Erweitern gehen die Basis-Fotos als Kontext mit – sie muessen nicht
    // neu aufgenommen werden, helfen dem Modell aber bei der Einordnung.
    final bildTypen = nurModul == null
        ? benoetigteAufnahmen(gewaehlteModule)
        : <AufnahmeTyp>{
            ...AnalyseModul.basis.aufnahmen,
            ...nurModul.aufnahmen,
          };

    final fotos = <AufnahmeTyp, File>{
      for (final typ in bildTypen)
        if (aufnahmen.foto(typ) case final foto?) typ: File(foto.pfad),
    };

    if (fotos.isEmpty) {
      state = const AnalyseFehlgeschlagen(AnalysisFehler.fotosFehlen);
      return;
    }

    state = const AnalyseLaeuft();
    _melde(DiagnoseEreignis.analyseGestartet);
    final abbruch = _abbruch = Abbruch();
    // Marke fuer den Fall, dass die App mitten im Lauf beendet wird.
    _laufmarke(DateTime.now());

    try {
      final antwort = await _ref.read(analysisServiceProvider).analysiere(
            fotos: fotos,
            module: nurModul == null ? gewaehlteModule : {nurModul},
            onboarding: _ref.read(onboardingControllerProvider),
            eingaben: modulZustand.eingaben,
            sprache: _ref.read(aktiveSpracheProvider),
            richtung: richtung,
            abbruch: abbruch,
          );

      final ergebnis = nurModul == null
          ? antwort
          : _einhaengen(antwort, nurModul, richtung);

      await _ref.read(analysenProvider.notifier).speichern(ergebnis);
      _laufmarke(null);
      _melde(DiagnoseEreignis.analyseFertig);
      if (!mounted) return;
      state = AnalyseFertig(ergebnis);
    } on AbbruchException {
      _laufmarke(null);
      if (!mounted) return;
      state = const AnalyseAbgebrochen();
    } on AnalysisException catch (e) {
      debugPrint('Analyse fehlgeschlagen: $e');
      _laufmarke(null);
      if (!mounted) return;
      state = AnalyseFehlgeschlagen(e.fehler);
    } catch (e, s) {
      debugPrint('Analyse unerwartet fehlgeschlagen: $e\n$s');
      _laufmarke(null);
      if (!mounted) return;
      state = const AnalyseFehlgeschlagen(AnalysisFehler.apiFehler);
    }
  }

  /// Meldet ein Funnel-Ereignis. Ohne Einwilligung passiert dabei nichts.
  void _melde(DiagnoseEreignis ereignis) =>
      _ref.read(diagnoseDienstProvider).melde(ereignis);

  /// Haelt fest, dass gerade eine Analyse laeuft – oder raeumt die Marke weg.
  ///
  /// Der Zustand des Controllers lebt nur im Arbeitsspeicher. Wird die App
  /// mitten im Lauf beendet, waere ohne diese Marke nicht mehr feststellbar,
  /// dass ueberhaupt etwas offen war: Der Nutzer saehe beim naechsten Start
  /// ein unveraendertes Dashboard und wuesste nicht, ob seine Analyse noch
  /// kommt.
  void _laufmarke(DateTime? seit) {
    final box = _ref.read(storeProvider(HiveService.boxEinstellungen));
    if (seit == null) {
      box.delete(CloudModell.keyAnalyseLaeuftSeit);
    } else {
      box.put(CloudModell.keyAnalyseLaeuftSeit, seit.toIso8601String());
    }
  }

  /// Haengt das neue Kapitel in die bestehende Analyse ein, ohne die
  /// vorhandenen Kapitel anzufassen. Gibt es noch keine Analyse, bleibt die
  /// Antwort fuer sich stehen.
  AnalysisResult _einhaengen(
    AnalysisResult antwort,
    AnalyseModul modul,
    Richtung richtung,
  ) {
    final bestehend = _ref.read(analysisRepositoryProvider).aktuelle();
    if (bestehend == null) return antwort;

    final neues = antwort.kapitel
        .where((k) => k.modul == modul)
        .firstOrNull;
    if (neues == null) return bestehend;

    // Das neue Kapitel entstand mit der aktuellen Richtung – die gilt ab
    // jetzt fuer den ganzen Report.
    return bestehend.mitKapitel(
      neues,
      planErgaenzung: antwort.plan,
      richtung: richtung,
    );
  }

  void zuruecksetzen() {
    _laufmarke(null);
    state = const AnalyseBereit();
  }
}

/// Waehlt Mock oder echten Anbieter – gesteuert ueber [AnalysisConfig].
final analysisServiceProvider = Provider<AnalysisService>((ref) {
  if (AnalysisConfig.useMockData) return const MockAnalysisService();
  return FunctionsAnalysisService();
});

final analysisControllerProvider =
    StateNotifierProvider<AnalysisController, AnalyseZustand>(
  (ref) => AnalysisController(ref),
);
