import 'dart:io';

import '../../../core/l10n/sprache.dart';
import '../../../core/netz/wiederholung.dart';
import '../../capture/models/aufnahme_typ.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../models/analysis_result.dart';
import 'analysis_service.dart';
import 'json_extractor.dart';

/// Liefert eine fest hinterlegte Beispiel-Antwort, ohne das Geraet zu
/// verlassen. Die Antwort laeuft bewusst durch denselben Parser wie eine echte
/// API-Antwort – so wird der Lesepfad im Mock-Modus mitgetestet.
class MockAnalysisService implements AnalysisService {
  const MockAnalysisService();

  @override
  Future<AnalysisResult> analysiere({
    required Map<AufnahmeTyp, File> fotos,
    required Set<AnalyseModul> module,
    required OnboardingProfile onboarding,
    required ModulEingaben eingaben,
    // Die Beispielantwort liegt nur auf Deutsch vor. Die Sprache wird
    // deshalb entgegengenommen und bewusst nicht benutzt – der Demo-Modus
    // zeigt einen fertigen Beispiel-Report, keine erzeugte Antwort.
    required Sprache sprache,
    // Die Beispielantwort ist fest hinterlegt und kann die Richtung nicht
    // beruecksichtigen; sie wird aber wie im Echtbetrieb ans Ergebnis
    // geheftet, damit der Report sie anzeigen kann.
    Richtung richtung = Richtung.leer,
    Abbruch? abbruch,
  }) async {
    await Future<void>.delayed(AnalysisConfig.mockDauer);
    if (abbruch?.istAusgeloest ?? false) throw const AbbruchException();

    final json = JsonExtractor.extrahiere(antwortFuer(module));
    if (json == null) {
      throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
    }

    return AnalysisResult.vonApi(
      json,
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      erstelltAm: DateTime.now(),
      richtung: richtung,
    );
  }

  /// Baut die Beispielantwort aus den Kapiteln der gewaehlten Module.
  ///
  /// Absichtlich mit Codefence, weil echte Modelle die auch dann liefern, wenn
  /// man ausdruecklich darum bittet, es zu lassen.
  static String antwortFuer(Set<AnalyseModul> module) {
    final kapitel = AnalyseModul.values
        .where(module.contains)
        .map((m) => _kapitel[m]!)
        .join(',\n');

    return '```json\n{\n  "kapitel": [\n$kapitel\n  ],\n  "plan": $_plan\n}\n```';
  }

  /// Vollstaendige Beispielantwort ueber alle Module – die Grundlage der
  /// Parser-Tests.
  static String get beispielAntwort => antwortFuer(AnalyseModul.values.toSet());

  static const Map<AnalyseModul, String> _kapitel = {
    AnalyseModul.basis: '''
    {
      "modul": "basis",
      "einleitung": "Ovale Grundform mit klarer Kieferlinie und leicht höherer Stirn. Diese Form ist unkompliziert: fast jede Frisur funktioniert, solange oben etwas Volumen bleibt und die Seiten nicht zu breit werden.",
      "habits": [
        "Haare morgens mit Paste in Form bringen",
        "Bartkontur an den Wangen nachziehen",
        "Abends Bartöl einarbeiten",
        "Kopfhaut beim Waschen kurz massieren"
      ],
      "sektionen": [
        {
          "titel": "Frisur",
          "einschaetzung": "Das Haar ist kräftig und leicht wellig, an den Seiten aktuell etwas voluminöser als oben. Dadurch wirkt das Gesicht breiter, als es ist.",
          "empfehlungen": [
            "Die Seiten kürzer halten als das Deckhaar – etwa 2 zu 5 im Verhältnis.",
            "Oben Länge lassen und mit etwas Volumen nach hinten oben stylen.",
            "Alle 4 bis 6 Wochen nachschneiden lassen, damit die Form hält."
          ],
          "produkte": [
            {
              "name": "Mattes Stylingpaste mit mittlerem Halt",
              "kategorie": "Styling",
              "beschreibung": "Haselnussgroße Menge im handtuchtrockenen Haar verteilen, von hinten nach vorn durchfahren.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Bart",
          "einschaetzung": "Der Bartwuchs ist an den Wangen etwas lichter als am Kinn. Eine klar gezogene Wangenlinie sorgt trotzdem für ein sauberes Bild.",
          "empfehlungen": [
            "Die Wangenlinie knapp unterhalb des höchsten Bartwuchses ziehen, nicht höher.",
            "Kinnbereich einen Hauch länger lassen – das streckt die Gesichtsform.",
            "Zweimal pro Woche Bartöl einarbeiten, das nimmt den Struppigkeitsfaktor."
          ],
          "produkte": [
            {
              "name": "Bartöl mit Jojoba",
              "kategorie": "Pflege",
              "beschreibung": "Drei Tropfen in die Handflächen, in Bart und Haut einmassieren. Abends nach dem Waschen.",
              "affiliateUrl": null
            }
          ]
        }
      ]
    }''',
    AnalyseModul.hautFarbtyp: '''
    {
      "modul": "hautFarbtyp",
      "einleitung": "Die Haut wirkt in der T-Zone leicht glänzend, an den Wangen eher trocken – eine typische Mischhaut. Der Unterton ist warm, mit einem leichten Goldstich.",
      "habits": [
        "Morgens mit mildem Gel reinigen",
        "Direkt danach eincremen",
        "Sonnenschutz LSF 30 auftragen",
        "Abends Gesicht reinigen",
        "Zu warmen Farbtönen greifen"
      ],
      "sektionen": [
        {
          "titel": "Hautbild",
          "einschaetzung": "Um die Nase sind ein paar vergrößerte Poren zu sehen, sonst ist das Hautbild ruhig. Nichts davon braucht eine Behandlung, nur eine passende Routine.",
          "empfehlungen": [
            "Morgens und abends mit einem milden, pH-neutralen Reinigungsgel waschen statt mit Seife.",
            "Direkt nach der Reinigung eine leichte Feuchtigkeitscreme auftragen, solange die Haut noch feucht ist.",
            "Täglich Sonnenschutz mit LSF 30 auftragen, auch im Winter."
          ],
          "produkte": [
            {
              "name": "Mildes Reinigungsgel",
              "kategorie": "Reinigung",
              "beschreibung": "Morgens und abends eine haselnussgroße Menge auf die feuchte Haut, 30 Sekunden einmassieren, lauwarm abspülen.",
              "affiliateUrl": null
            },
            {
              "name": "Leichte Feuchtigkeitscreme (ölfrei)",
              "kategorie": "Pflege",
              "beschreibung": "Nach der Reinigung dünn auftragen. Ölfrei, damit die T-Zone nicht zusätzlich glänzt.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Farbpalette",
          "einschaetzung": "Zum warmen Unterton passen gedeckte, erdige Töne deutlich besser als kühle Kontraste. Reines Schwarz direkt am Gesicht wirkt hart.",
          "empfehlungen": [
            "Setz auf Oliv, Camel, Rostbraun, Creme und warmes Marineblau.",
            "Statt reinem Weiß lieber Off-White oder Ecru direkt am Hals tragen.",
            "Kühles Grau und Knallpink nur als Akzent weiter unten am Körper einsetzen."
          ],
          "produkte": []
        }
      ]
    }''',
    AnalyseModul.zaehneLaecheln: '''
    {
      "modul": "zaehneLaecheln",
      "einleitung": "Das Lächeln wirkt offen und symmetrisch. Die Zahnfarbe liegt im natürlichen Bereich mit einem leichten Gelbstich, wie er bei Kaffee- und Teetrinkern üblich ist.",
      "habits": [
        "Abends Zahnseide benutzen",
        "Nach Kaffee mit Wasser nachspülen",
        "Zweimal täglich zwei Minuten putzen",
        "Einmal Interdentalbürste durchziehen"
      ],
      "sektionen": [
        {
          "titel": "Zahnfarbe und Pflege",
          "einschaetzung": "Die Verfärbungen sitzen vor allem an den Zahnzwischenräumen der Schneidezähne. Das ist oberflächlich und gut in den Griff zu bekommen.",
          "empfehlungen": [
            "Nach Kaffee oder Tee einmal mit Wasser nachspülen statt sofort zu putzen.",
            "Einmal täglich Interdentalbürsten benutzen – dort sitzt der Großteil der Verfärbung.",
            "Für eine professionelle Zahnreinigung einmal im Jahr einen Termin machen."
          ],
          "produkte": [
            {
              "name": "Interdentalbürsten im Set",
              "kategorie": "Werkzeug",
              "beschreibung": "Abends vor dem Zähneputzen, verschiedene Größen ausprobieren und die passende behalten.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Mimik",
          "einschaetzung": "Beim Lächeln sind die Augen mitbeteiligt, das wirkt echt und sympathisch. Auf dem Foto ist die Kinnpartie leicht angespannt.",
          "empfehlungen": [
            "Vor Fotos einmal bewusst ausatmen und den Kiefer lockern.",
            "Kinn minimal nach vorn und leicht nach unten – das definiert die Kieferlinie."
          ],
          "produkte": []
        }
      ]
    }''',
    AnalyseModul.figurPassform: '''
    {
      "modul": "figurPassform",
      "einleitung": "Die Silhouette zeigt gleichmäßig verteilte Proportionen mit leicht breiteren Schultern als Hüfte – eine dankbare Ausgangslage für die meisten Schnitte.",
      "habits": [
        "30 Sekunden Brustöffner im Türrahmen",
        "Bildschirm auf Augenhöhe prüfen",
        "Bewusst aufrecht hinsetzen",
        "Abends Nacken fünf Minuten lockern"
      ],
      "sektionen": [
        {
          "titel": "Schnitte und Passform",
          "einschaetzung": "Das Schulter-Hüft-Verhältnis trägt gerade geschnittene Oberteile gut. Zu weite Hemden nehmen der Silhouette dagegen Struktur.",
          "empfehlungen": [
            "Bei Hemden auf die Schulternaht achten: Sie sollte genau auf dem Schulterknochen enden.",
            "Gerade geschnittene Hosen mit leichtem Taper statt sehr enger oder sehr weiter Modelle.",
            "Oberteile so wählen, dass sie knapp über der Hosentasche enden."
          ],
          "produkte": []
        },
        {
          "titel": "Haltung",
          "einschaetzung": "Im Seitenprofil ist eine leicht nach vorn gerollte Schulterposition zu sehen – typisch für viel Schreibtischarbeit.",
          "empfehlungen": [
            "Zweimal täglich 30 Sekunden Brustöffner im Türrahmen.",
            "Bildschirm auf Augenhöhe bringen, das nimmt Zug aus dem Nacken."
          ],
          "produkte": []
        }
      ]
    }''',
    AnalyseModul.stilKleiderschrank: '''
    {
      "modul": "stilKleiderschrank",
      "einleitung": "Die gezeigten Outfits sind funktional und zurückhaltend. Zum angegebenen Stilziel fehlt vor allem Struktur in der obersten Schicht.",
      "habits": [
        "Outfit am Abend vorher rauslegen",
        "Ein Teil pro Woche kritisch prüfen",
        "Schuhe nach dem Tragen auslüften",
        "Neues Teil gegen drei vorhandene testen"
      ],
      "sektionen": [
        {
          "titel": "Abgleich mit deinem Ziel",
          "einschaetzung": "Die Basis stimmt: neutrale Farben, saubere Passform. Was fehlt, ist ein Teil, das den Look zusammenhält – meist eine leichte Jacke oder ein Overshirt.",
          "empfehlungen": [
            "Ein Overshirt in Oliv oder Camel ergänzen, das über beide gezeigten Outfits passt.",
            "Sneaker in einem ruhigen Ton statt mit auffälligem Logo wählen.",
            "Zwei einfarbige T-Shirts in guter Qualität ersetzen fünf mittelmäßige."
          ],
          "produkte": [
            {
              "name": "Overshirt aus Baumwolltwill",
              "kategorie": "Kleidung",
              "beschreibung": "Als dritte Schicht über T-Shirt oder Hemd. Gedeckte Farbe, damit es zu allem passt.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Alltagstauglichkeit",
          "einschaetzung": "Beide Outfits sind pflegeleicht und passen zum angegebenen Dresscode. Das ist eine gute Grundlage, um gezielt zu ergänzen statt neu anzufangen.",
          "empfehlungen": [
            "Erst ergänzen, dann aussortieren – so bleibt der Kleiderschrank benutzbar.",
            "Neue Teile immer gegen drei vorhandene testen: passt es zu mindestens zweien, kommt es mit."
          ],
          "produkte": []
        }
      ]
    }''',
  };

  static const String _plan = '''{
    "sofort": [
      "Heute Abend die Reinigung umstellen: mildes Gel statt Seife.",
      "Sonnenschutz griffbereit neben die Zahnbürste legen."
    ],
    "dreissigTage": [
      "Alle 4 bis 6 Wochen einen Frisurtermin fest einplanen.",
      "Eine Woche lang die Wangenlinie des Barts konsequent gleich ziehen.",
      "Ein Overshirt in gedeckter Farbe besorgen und zu allem testen."
    ],
    "langfristig": [
      "Die Pflegeroutine auf drei feste Schritte eindampfen und dabei bleiben.",
      "Den Kleiderschrank über ein halbes Jahr auf wenige, gut kombinierbare Teile bringen."
    ]
  }''';
}
