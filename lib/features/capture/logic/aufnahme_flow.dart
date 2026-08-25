import '../../modules/models/analyse_modul.dart';
import '../models/aufnahme_typ.dart';

/// Ein Schritt im Aufnahme-Flow. Die Schrittliste ergibt sich aus den
/// gewaehlten Modulen, damit die Fortschrittsanzeige ("Schritt 3 von 7")
/// immer zur tatsaechlichen Auswahl passt.
///
/// Die Schritte trugen frueher eine Ueberschrift, die niemand las: Die
/// Kopfzeile des Flows zeigt die Schrittnummer, jeder Schritt seinen eigenen
/// Titel. Mit der Uebersetzung haette sie ueberall einen `L` durchgereicht –
/// fuer einen Wert, den kein Aufrufer je gelesen hat. Deshalb ist sie weg.
sealed class FlowSchritt {
  const FlowSchritt();
}

/// Einmalige Checkliste fuer gute Lichtbedingungen vor dem ersten Foto.
class LichtCheckSchritt extends FlowSchritt {
  const LichtCheckSchritt();
}

/// Hinweisseite vor den Aufnahmen eines Moduls.
class ModulHinweisSchritt extends FlowSchritt {
  const ModulHinweisSchritt(this.modul);

  final AnalyseModul modul;
}

/// Eine Foto-Aufnahme.
class FotoSchritt extends FlowSchritt {
  const FotoSchritt(this.typ);

  final AufnahmeTyp typ;
}

/// Koerpergroesse und Gewicht fuer "Figur & Passform".
class FigurFormularSchritt extends FlowSchritt {
  const FigurFormularSchritt();
}

/// Kurzer Fragebogen fuer "Stil & Kleiderschrank".
class StilFragebogenSchritt extends FlowSchritt {
  const StilFragebogenSchritt();
}

/// Baut die Schrittfolge aus den gewaehlten Modulen.
///
/// Mit [nur] entsteht der verkuerzte Flow eines einzelnen Moduls – das ist der
/// Weg ueber "Analyse erweitern", bei dem die Basis-Fotos bereits vorliegen
/// und nicht erneut aufgenommen werden.
List<FlowSchritt> baueAufnahmeFlow(
  Set<AnalyseModul> module, {
  AnalyseModul? nur,
}) {
  final gewaehlt = nur != null ? {nur} : module;
  final schritte = <FlowSchritt>[];

  // Reihenfolge folgt der Deklaration in AnalyseModul.
  for (final modul in AnalyseModul.values) {
    if (!gewaehlt.contains(modul)) continue;

    // Haut bringt keine eigene Aufnahme mit. Die Seite erklaert deshalb, dass
    // das Frontalfoto mitgelesen wird – ohne sie waere unklar, warum ein
    // gewaehltes Modul im Flow gar nicht vorkommt.
    if (modul == AnalyseModul.hautFarbtyp) {
      schritte.add(ModulHinweisSchritt(modul));
    }

    schritte.addAll(modul.aufnahmen.map(FotoSchritt.new));

    switch (modul) {
      case AnalyseModul.figurPassform:
        schritte.add(const FigurFormularSchritt());
      case AnalyseModul.stilKleiderschrank:
        schritte.add(const StilFragebogenSchritt());
      case AnalyseModul.basis:
      case AnalyseModul.hautFarbtyp:
      case AnalyseModul.zaehneLaecheln:
        break;
    }
  }

  // Die Lichtcheckliste steht vor dem ersten Foto – aber nur, wenn ueberhaupt
  // fotografiert wird.
  if (schritte.any((s) => s is FotoSchritt)) {
    schritte.insert(0, const LichtCheckSchritt());
  }

  return schritte;
}

/// Alle Aufnahmen, die fuer die gewaehlten Module gebraucht werden.
Set<AufnahmeTyp> benoetigteAufnahmen(
  Set<AnalyseModul> module, {
  AnalyseModul? nur,
}) {
  return baueAufnahmeFlow(module, nur: nur)
      .whereType<FotoSchritt>()
      .map((s) => s.typ)
      .toSet();
}

/// Aufnahmen, ohne die es nicht weitergeht (alles ausser den optionalen).
Set<AufnahmeTyp> pflichtAufnahmen(
  Set<AnalyseModul> module, {
  AnalyseModul? nur,
}) {
  return benoetigteAufnahmen(module, nur: nur)
      .where((t) => !t.optional)
      .toSet();
}
