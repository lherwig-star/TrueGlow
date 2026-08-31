import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../../core/l10n/sprache.dart';
import '../../../core/l10n/texte.dart';
import '../../../core/netz/wiederholung.dart';
import '../../capture/models/aufnahme_typ.dart';
import '../../ausprobieren/models/technik.dart';
import '../../direction/models/richtung.dart';
import '../../modules/models/analyse_modul.dart';
import '../../modules/models/modul_eingaben.dart';
import '../../onboarding/models/onboarding_profile.dart';
import '../models/analyse_modus.dart';
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
    // Der Modus dagegen aendert die Antwort: Es gibt zwei hinterlegte
    // Beispiele, eines je Modus. Ohne das waere der neue Look ohne
    // Kontingent nicht anzusehen.
    AnalyseModus modus = AnalyseModus.standard,
    // Und die Auswahl aus „Das will ich ausprobieren" wirkt ebenfalls: Sie
    // wird in die hinterlegte Antwort eingesetzt (siehe [mitTechniken]).
    // Ohne das liesse sich der ganze Schritt nur mit echtem Kontingent
    // ansehen – und genau dafuer gibt es den Demo-Modus.
    Set<Technik> techniken = const {},
    Abbruch? abbruch,
  }) async {
    await Future<void>.delayed(AnalysisConfig.mockDauer);
    if (abbruch?.istAusgeloest ?? false) throw const AbbruchException();

    // Wie im Echtbetrieb: Das Zielkapitel entsteht aus dem Freitext und
    // nur daraus. Ohne diese Zeile liesse sich der siebte Bereich – und
    // damit die Kachel-Zeile mit ungerader Anzahl – nur mit echtem
    // Kontingent ansehen (DECISIONS 89).
    final json = JsonExtractor.extrahiere(antwortFuer(
      module,
      modus: modus,
      mitZielen: richtung.freitext.trim().isNotEmpty,
    ));
    if (json == null) {
      throw const AnalysisException(AnalysisFehler.ungueltigeAntwort);
    }

    return AnalysisResult.vonApi(
      mitTechniken(json, techniken),
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      erstelltAm: DateTime.now(),
      richtung: richtung,
      modus: modus,
    );
  }

  /// Setzt die gewaehlten Techniken in die hinterlegte Antwort ein.
  ///
  /// Was ein echtes Modell tun soll, macht hier eine Schleife: je Technik
  /// eine Empfehlung mit Anleitung in der ersten Sektion ihres Kapitels, die
  /// Marke „Neu für dich" daneben und eine Aufgabe in der Tagesliste. Ohne
  /// das waere der ganze Schritt „Das will ich ausprobieren" nur mit echtem
  /// Kontingent anzusehen.
  ///
  /// **Was der Demo-Modus damit nicht beweist:** dass ein echtes Modell die
  /// Technik wirklich mit den Fotos verbindet. Das entscheidet der Prompt
  /// (DECISIONS 80), und das braucht einen Lauf gegen den Server.
  ///
  /// Der Takt wechselt bewusst ab: Die erste Technik bekommt eine
  /// Wochenaufgabe, die naechste eine Tagesaufgabe, dann wieder eine
  /// Wochenaufgabe. So sind im Demo-Modus beide Formen zu sehen und beide
  /// Abschnitte der Tagesliste belegt. Welchen Takt eine Technik wirklich
  /// hat, steht in der Tabelle auf dem Server und nicht hier — der
  /// Demo-Modus zeigt die Form, nicht die Fachaussage.
  static Map<String, dynamic> mitTechniken(
    Map<String, dynamic> json,
    Set<Technik> techniken,
  ) {
    if (techniken.isEmpty) return json;

    // Die Beispielantwort liegt nur auf Deutsch vor – die Namen deshalb
    // auch.
    final texte = lookupL(const Locale('de'));
    final kapitel = [
      for (final eintrag in (json['kapitel'] as List? ?? const []))
        if (eintrag is Map) Map<String, dynamic>.from(eintrag),
    ];

    var lauf = 0;
    for (final technik in Technik.sortiert(techniken)) {
      final ziel = kapitel
          .where((k) => k['modul'] == technik.modul.name)
          .firstOrNull;
      // Eine Technik ohne ihr Kapitel kann es regulaer nicht geben – der
      // Bildschirm bietet sie dann gar nicht an. Sie hier stillschweigend
      // zu ueberspringen ist trotzdem richtiger als ein Absturz im
      // Demo-Modus.
      if (ziel == null) continue;

      final sektionen = [
        for (final eintrag in (ziel['sektionen'] as List? ?? const []))
          if (eintrag is Map) Map<String, dynamic>.from(eintrag),
      ];
      if (sektionen.isEmpty) continue;

      final name = technik.label(texte);
      final erste = sektionen.first;
      erste['empfehlungen'] = [
        ...(erste['empfehlungen'] as List? ?? const []),
        '$name: ${technik.untertext(texte)} Fang klein an und bleib dabei – '
            'die Wirkung kommt über Wochen, nicht über einen Abend.',
      ];
      erste['neu'] = [
        ...(erste['neu'] as List? ?? const []),
        name,
      ];
      ziel['sektionen'] = sektionen;

      final woechentlich = lauf.isEven;
      ziel['habits'] = [
        ...(ziel['habits'] as List? ?? const []),
        woechentlich
            ? 'Zweimal die Woche: $name einbauen'
            : 'Nach dem Duschen: $name',
      ];
      lauf += 1;
    }

    return {...json, 'kapitel': kapitel};
  }

  /// Baut die Beispielantwort aus den Kapiteln der gewaehlten Module.
  ///
  /// Absichtlich mit Codefence, weil echte Modelle die auch dann liefern, wenn
  /// man ausdruecklich darum bittet, es zu lassen.
  ///
  /// Es gibt zwei vollstaendige Beispiele, eines je [AnalyseModus]. Ein
  /// gemeinsames haette den Demo-Modus zur halben Wahrheit gemacht: Der
  /// entdeckende Report sieht anders aus – er hat einen Vorspann, und in
  /// jedem Kapitel steht der Vorschlag vor der Pflege.
  static String antwortFuer(
    Set<AnalyseModul> module, {
    AnalyseModus modus = AnalyseModus.standard,
    bool mitZielen = false,
  }) {
    final entdecken = modus.istEntdecken;
    final quelle = entdecken ? _kapitelEntdecken : _kapitel;
    final kapitel = [
      for (final m in AnalyseModul.bestellbar)
        if (module.contains(m)) quelle[m]!,
      // Das Zielkapitel ist nicht bestellbar – es haengt am Freitext.
      if (mitZielen) _kapitelZiele,
    ].join(',\n');
    // Beide Modi bekommen ihren Vorspann – seit DECISIONS 67 gibt es das
    // Feld nicht mehr nur beim entdeckenden.
    final vorspann = entdecken ? _gesamtbildEntdecken : _gesamtbildVerfeinern;
    final plan = entdecken ? _planEntdecken : _plan;

    return '```json\n{\n  "gesamtbild": $vorspann,\n  "kapitel": [\n$kapitel\n  ],\n'
        '  "plan": $plan\n}\n```';
  }

  /// Vollstaendige Beispielantwort ueber alle Module – die Grundlage der
  /// Parser-Tests.
  static String get beispielAntwort =>
      antwortFuer(AnalyseModul.bestellbar.toSet());

  /// Dasselbe fuer den entdeckenden Modus.
  static String get beispielAntwortEntdecken => antwortFuer(
        AnalyseModul.bestellbar.toSet(),
        modus: AnalyseModus.entdecken,
      );

  /// Das Kapitel aus dem Freitext bei „Deine Richtung".
  ///
  /// Es steht ausserhalb der beiden Karten, weil es in beiden Modi
  /// dasselbe tut: Es nimmt auf, was jemand in eigenen Worten gesagt hat.
  /// Der Beispieltext bleibt deshalb allgemein genug, um zu jedem Wunsch zu
  /// passen – ein Demo-Report kann nicht wissen, was dort steht.
  static const String _kapitelZiele = '''
    {
      "modul": "persoenlicheZiele",
      "einleitung": "Was du dir selbst vorgenommen hast – aus deinen eigenen Worten. Dieses Kapitel gehört nur dir: Es taucht auf, weil du etwas geschrieben hast, und verschwindet, wenn du das Feld leer lässt.",
      "habits": [
        "Nach dem Aufstehen: einen Schluck Wasser trinken, bevor der Tag anfängt",
        "Vor dem Schlafengehen: kurz notieren, was heute daran gut lief"
      ],
      "sektionen": [
        {
          "titel": "Dein Vorhaben",
          "einschaetzung": "Ein Vorhaben hält selten an der Absicht, sondern an der Gelegenheit. Deshalb hängt hier jeder Schritt an etwas, das ohnehin jeden Tag passiert.",
          "empfehlungen": [
            "Fang kleiner an, als du dir zutraust – die erste Woche entscheidet nicht über das Ergebnis, sondern über die Gewohnheit.",
            "Knüpf den Vorsatz an eine feste Stelle im Tag statt an eine Uhrzeit.",
            "Rechne mit Tagen, an denen es nicht klappt, und plan sie ein statt sie zu vermeiden."
          ],
          "produkte": []
        }
      ]
    }''';

  static const Map<AnalyseModul, String> _kapitel = {
    AnalyseModul.basis: '''
    {
      "modul": "basis",
      "einleitung": "Ovale Grundform mit klarer Kieferlinie und leicht höherer Stirn. Diese Form ist unkompliziert: fast jede Frisur funktioniert, solange oben etwas Volumen bleibt und die Seiten nicht zu breit werden.",
      "habits": [
        "Nach dem Aufstehen: Deckhaar mit den Fingern nach vorn richten",
        "Beim Duschen: Kopfhaut eine halbe Minute mit den Fingerkuppen massieren",
        "Nach dem Duschen: Paste ins handtuchtrockene Haar einarbeiten",
        "Nach dem Zähneputzen: Bartkontur an Wange und Hals kontrollieren",
        "Vor dem Schlafengehen: Bartöl in Bart und Haut einarbeiten"
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
              "kategorie": "styling",
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
              "kategorie": "pflege",
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
        "Nach dem Aufstehen: Gesicht mit mildem Gel reinigen",
        "Nach dem Duschen: Creme auf die noch feuchte Haut auftragen",
        "Nach dem Frühstück: Sonnenschutz LSF 30 auf Stirn, Schläfen und Ohren",
        "Vor dem Schlafengehen: Gesicht reinigen und nachcremen"
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
              "kategorie": "reinigung",
              "beschreibung": "Morgens und abends eine haselnussgroße Menge auf die feuchte Haut, 30 Sekunden einmassieren, lauwarm abspülen.",
              "affiliateUrl": null
            },
            {
              "name": "Leichte Feuchtigkeitscreme (ölfrei)",
              "kategorie": "pflege",
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
    AnalyseModul.makeupAusstrahlung: '''
    {
      "modul": "makeupAusstrahlung",
      "einleitung": "Klare Augenpartie, mitteldichte Brauen, gleichmäßiger Teint mit warmem Unterton. Das ist eine gute Ausgangslage für einen Alltags-Look, der wenige Handgriffe braucht und trotzdem wirkt.",
      "habits": [
        "Nach dem Aufstehen: Brauen nach oben außen in Form bürsten",
        "Nach dem Duschen: Getönte Tagescreme dünn auftragen",
        "Nach dem Frühstück: Wimpern nur am Oberlid tuschen",
        "Vor dem Schlafengehen: Alles gründlich abnehmen"
      ],
      "sektionen": [
        {
          "titel": "Alltags-Look",
          "einschaetzung": "Der Teint ist ruhig genug, dass eine leichte Deckung reicht. Volle Foundation würde die eigene Struktur eher zudecken als betonen.",
          "empfehlungen": [
            "Getönte Tagescreme dünn auftragen und nur dort abdecken, wo es nötig ist.",
            "Brauen mit einer Bürste in Form bringen und mit einem Gel fixieren – Farbe braucht es kaum.",
            "Wimperntusche nur am Oberlid, das öffnet den Blick ohne harte Kontur."
          ],
          "produkte": [
            {
              "name": "Getönte Tagescreme",
              "kategorie": "makeup",
              "beschreibung": "Mit den Fingern von der Mitte nach außen verteilen. Ein Ton, der am Kiefer verschwindet, ist der richtige.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Farben, die tragen",
          "einschaetzung": "Zum warmen Unterton passen weiche, erdige Töne besser als kühle Beeren. Auf den Lippen wirkt ein Ton, der zwei Nuancen kräftiger ist als die eigene Lippenfarbe, am natürlichsten.",
          "empfehlungen": [
            "Auf den Lidern mit Terracotta, warmem Taupe und Champagner arbeiten.",
            "Für die Lippen ein warmes Rosenholz statt Pink oder Blaurot.",
            "Rouge sparsam auf die Wangenmitte, nicht in die Wangenknochen ziehen."
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
        "Nach dem Aufstehen: Zwei Minuten putzen, mit Timer",
        "Nach dem Frühstück: Nach dem Kaffee mit Wasser nachspülen",
        "Nach dem Abendessen: Interdentalbürste durchziehen",
        "Vor dem Schlafengehen: Zahnseide durch alle Zwischenräume ziehen"
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
              "kategorie": "werkzeug",
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
        "Nach dem Aufstehen: Eine Minute mit dem Rücken zur Wand stellen",
        "Wenn die Schultern nach vorn kippen: 30 Sekunden Brustöffner im Türrahmen",
        "Bildschirm auf Augenhöhe prüfen",
        "Nach dem Abendessen: Nacken fünf Minuten lockern"
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
      "einleitung": "Die gezeigten Outfits sind funktional und zurückhaltend. Zur angegebenen Stilrichtung fehlt vor allem Struktur in der obersten Schicht.",
      "habits": [
        "Beim Ankleiden: Passform der Schulternaht am Spiegel prüfen",
        "Schuhe nach dem Tragen auslüften",
        "Nach dem Abendessen: Ein Teil im Schrank kritisch prüfen",
        "Vor dem Schlafengehen: Outfit für morgen rauslegen"
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
              "kategorie": "kleidung",
              "beschreibung": "Als dritte Schicht über T-Shirt oder Hemd. Gedeckte Farbe, damit es zu allem passt.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Alltagstauglichkeit",
          "einschaetzung": "Beide Outfits sind pflegeleicht und alltagstauglich. Das ist eine gute Grundlage, um gezielt zu ergänzen statt neu anzufangen.",
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
  // --- Modus "Neuen Look entdecken" -------------------------------------
  //
  // Ein zweites, vollstaendiges Beispiel. Dieselbe gedachte Person wie oben,
  // aber ein anderer Auftrag: Statt den vorhandenen Look zu polieren, steht
  // hier ein Vorschlag mit Namen, Begruendung am Gesicht und einem Satz fuer
  // den Friseur – genau das, was der Prompt in diesem Modus verlangt
  // (DECISIONS 57).
  //
  // Warum das die Muehe wert ist: Ohne dieses Beispiel liesse sich der neue
  // Modus nur mit echtem Kontingent ansehen, und die Oberflaeche dafuer waere
  // nie geprueft worden, bevor sie Geld kostet.

  /// Das Gesamtbild des entdeckenden Modus – Wirkung, keine Namen.
  ///
  /// Der Schnittname, der Bartstil und die Kleidungsstuecke fallen im Report
  /// zum ersten Mal in ihrem Kapitel (DECISIONS 67).
  static const String _gesamtbildEntdecken =
      '"Die Richtung geht weg vom gleichmäßig Mittellangen hin zu einem '
      'klaren Gegensatz: oben Struktur, an den Seiten Ruhe. Dazu eine '
      'Garderobe, die auf wenige, sichtbar gute Stücke setzt statt auf '
      'viele funktionale. Zusammen wirkt das wacher und erwachsener – und '
      'kostet dich morgens keine Minute mehr als heute."';

  /// Und das des verfeinernden.
  static const String _gesamtbildVerfeinern =
      '"Deine Grundlage trägt schon: klare Proportionen, ein ruhiger '
      'Gesamteindruck und ein Haar, das mitmacht. Die Verfeinerung setzt '
      'deshalb an den Kanten an – sauberer, wo es heute unentschieden '
      'wirkt, und ein wenig mehr Halt dort, wo der Tag ihn wegnimmt. Es '
      'geht nicht darum, anders auszusehen, sondern deutlicher wie du."';

  static const Map<AnalyseModul, String> _kapitelEntdecken = {
    AnalyseModul.basis: '''
    {
      "modul": "basis",
      "einleitung": "Ovale Grundform mit klarer Kieferlinie und leicht höherer Stirn. Genau diese Kombination trägt einen deutlichen Längenkontrast zwischen oben und den Seiten – etwas, das dein jetziger Schnitt nicht nutzt.",
      "habits": [
        "Nach dem Duschen: Haar antrocknen und Paste einarbeiten",
        "Nach dem Aufstehen: Deckhaar mit den Fingern nach vorn richten",
        "Beim Duschen: Kopfhaut eine halbe Minute massieren",
        "Nach dem Zähneputzen: Bartkontur am Hals kontrollieren",
        "Vor dem Schlafengehen: Bartöl in Bart und Haut einarbeiten"
      ],
      "sektionen": [
        {
          "titel": "Dein neuer Look",
          "einschaetzung": "Vorschlag: ein Textured Crop mit mittelhohem Fade. Dein Haar ist kräftig und leicht wellig – genau die Struktur, die dieser Schnitt oben braucht und an den Seiten nicht mitschleppen muss. Weil deine Stirn etwas höher ist, bleibt die Fransenkante vorn stehen, statt nach hinten zu gehen.",
          "empfehlungen": [
            "Sag im Salon: 'Textured Crop, oben etwa 5 cm, Seiten mit mittelhohem Fade auf 6 mm auslaufend, Fransen vorn stehen lassen.'",
            "Leg den Termin in eine Woche ohne wichtige Anlässe – die ersten Tage sitzt jeder neue Schnitt anders.",
            "Bring ein Foto mit. Ein Name allein wird in jedem Salon etwas anders verstanden."
          ],
          "produkte": []
        },
        {
          "titel": "Frisur",
          "einschaetzung": "Der neue Schnitt braucht weniger Styling als der jetzige, aber ein anderes: Es geht um Textur, nicht um Halt. Ein glänzendes Gel würde genau die Struktur zukleben, die den Schnitt ausmacht.",
          "empfehlungen": [
            "Matte Paste ins handtuchtrockene Haar, von hinten nach vorn durchfahren, nicht kämmen.",
            "Alle 3 bis 4 Wochen nachschneiden lassen – ein Fade wächst schneller aus der Form heraus als ein gleichmäßiger Schnitt.",
            "In der Übergangszeit, bis die Seiten kurz sind, die Haare hinter die Ohren streichen statt sie zu glätten."
          ],
          "produkte": [
            {
              "name": "Matte Stylingpaste mit mittlerem Halt",
              "kategorie": "styling",
              "beschreibung": "Haselnussgroße Menge in den Handflächen verreiben, ins feuchte Haar geben, mit den Fingerspitzen aufrichten.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Bart",
          "einschaetzung": "Der Bartwuchs ist an den Wangen lichter als am Kinn. Ein kurzer Vollbart auf gleichmäßiger Länge nutzt das aus, statt dagegen zu arbeiten: Auf 6 mm fällt der Dichteunterschied kaum noch auf.",
          "empfehlungen": [
            "Vollbart auf 6 mm trimmen, Wangenlinie knapp unterhalb des höchsten Wuchses gerade ziehen.",
            "Die Halslinie zwei Finger über dem Adamsapfel setzen, nicht am Kiefer – das ist der häufigste Fehler und macht das Gesicht kürzer.",
            "Was bleibt: Deine Kinnpartie ist gut ausgeprägt. Der Bart wird deshalb nicht länger, nur sauberer."
          ],
          "produkte": [
            {
              "name": "Trimmer mit festen Aufsätzen",
              "kategorie": "werkzeug",
              "beschreibung": "6-mm-Aufsatz für die Fläche, ohne Aufsatz für die Kontur an Wange und Hals.",
              "affiliateUrl": null
            }
          ]
        }
      ]
    }''',
    AnalyseModul.hautFarbtyp: '''
    {
      "modul": "hautFarbtyp",
      "einleitung": "Mischhaut mit warmem, leicht goldenem Unterton. Für den neuen Look ist das die gute Nachricht: Die Farbrichtung, die zum Vorschlag passt, ist auch die, die deiner Haut steht.",
      "habits": [
        "Nach dem Aufstehen: Gesicht mit mildem Gel reinigen",
        "Nach dem Duschen: Creme auf die noch feuchte Haut auftragen",
        "Nach dem Frühstück: Sonnenschutz auf Stirn, Schläfen und Ohren",
        "Vor dem Schlafengehen: Gesicht reinigen und Bartpartie mitpflegen"
      ],
      "sektionen": [
        {
          "titel": "Dein neuer Look",
          "einschaetzung": "Vorschlag: eine warme, gedeckte Farbfamilie als Grundlage – Oliv, Camel, Rostbraun, Ecru. Dein Unterton hat einen Goldstich, und diese Töne nehmen ihn auf, statt gegen ihn zu arbeiten. Das ist die Farbseite des neuen Looks: Der Schnitt gibt die Form, die Farbe gibt den Ton.",
          "empfehlungen": [
            "Nimm beim nächsten Einkauf ein Teil in Oliv und eines in Camel mit und halte beide vor dem Spiegel ans Gesicht.",
            "Ersetz reines Weiß direkt am Hals durch Ecru oder Off-White – der harte Kontrast lässt dich heute müder wirken, als du bist.",
            "Was bleibt: Dein gedecktes Marineblau. Es ist warm genug und braucht keinen Ersatz."
          ],
          "produkte": []
        },
        {
          "titel": "Hautbild",
          "einschaetzung": "Um die Nase sind ein paar vergrößerte Poren zu sehen, sonst ist das Hautbild ruhig. Der kürzere Schnitt legt Stirn und Schläfen stärker frei – dort lohnt die Routine ab jetzt mehr als vorher.",
          "empfehlungen": [
            "Morgens und abends mit einem milden, pH-neutralen Gel waschen statt mit Seife.",
            "Die Feuchtigkeitscreme bis über die Stirn und den Haaransatz ziehen, nicht nur auf Wangen und Nase.",
            "Täglich Sonnenschutz mit LSF 30 – bei kurzen Seiten bekommen Schläfen und Ohren deutlich mehr Sonne ab."
          ],
          "produkte": [
            {
              "name": "Mildes Reinigungsgel",
              "kategorie": "reinigung",
              "beschreibung": "Haselnussgroße Menge auf die feuchte Haut, 30 Sekunden einmassieren, lauwarm abspülen.",
              "affiliateUrl": null
            }
          ]
        }
      ]
    }''',
    AnalyseModul.makeupAusstrahlung: '''
    {
      "modul": "makeupAusstrahlung",
      "einleitung": "Klare Augenpartie, mitteldichte Brauen, gleichmäßiger Teint mit warmem Unterton. Zum neuen Look passt weniger Produkt, nicht mehr: Der Schnitt übernimmt die Betonung, die vorher das Make-up leisten musste.",
      "habits": [
        "Nach dem Aufstehen: Brauen in Form bürsten und fixieren",
        "Nach dem Duschen: Getönte Tagescreme dünn auftragen",
        "Nach dem Frühstück: Wimpern nur am Oberlid tuschen",
        "Vor dem Schlafengehen: Alles gründlich abnehmen"
      ],
      "sektionen": [
        {
          "titel": "Dein neuer Look",
          "einschaetzung": "Vorschlag: ein reduzierter Alltags-Look mit betonten Brauen und offenem Blick – und sonst fast nichts. Deine Augenpartie ist klar, die Brauen sind von Natur aus dicht genug, um die Form allein zu tragen. Mit dem kürzeren Schnitt bekommt das Gesicht ohnehin mehr Kontur; volle Deckung wirkte jetzt wie eine zweite Schicht.",
          "empfehlungen": [
            "Brauen mit einer Bürste nach oben außen in Form bringen und mit klarem Gel fixieren – das ist der ganze Schritt.",
            "Getönte Tagescreme statt Foundation, und nur dort abdecken, wo es wirklich nötig ist.",
            "Was bleibt: Dein Verzicht auf harte Konturen. Der war schon richtig und passt jetzt noch besser."
          ],
          "produkte": [
            {
              "name": "Klares Augenbrauengel",
              "kategorie": "makeup",
              "beschreibung": "Mit dem Bürstchen von innen nach außen und leicht nach oben durchziehen.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Farben",
          "einschaetzung": "Zum warmen Unterton passen weiche, erdige Töne besser als kühle Beeren – dieselbe Farbfamilie wie beim Rest des neuen Looks.",
          "empfehlungen": [
            "Auf den Lidern mit Terracotta, warmem Taupe und Champagner arbeiten.",
            "Für die Lippen ein warmes Rosenholz, zwei Nuancen kräftiger als die eigene Lippenfarbe.",
            "Rouge sparsam auf die Wangenmitte, nicht in die Wangenknochen ziehen."
          ],
          "produkte": []
        }
      ]
    }''',
    AnalyseModul.zaehneLaecheln: '''
    {
      "modul": "zaehneLaecheln",
      "einleitung": "Das Lächeln wirkt offen und symmetrisch, die Zahnfarbe liegt im natürlichen Bereich mit leichtem Gelbstich. Mit kürzeren Seiten und klarer Bartkontur rückt die untere Gesichtshälfte stärker in den Blick.",
      "habits": [
        "Vor dem Schlafengehen: Zahnseide durch alle Zwischenräume ziehen",
        "Nach dem Frühstück: Nach dem Kaffee mit Wasser nachspülen",
        "Nach dem Aufstehen: Zwei Minuten putzen, mit Timer",
        "Nach dem Abendessen: Interdentalbürste durchziehen"
      ],
      "sektionen": [
        {
          "titel": "Dein neuer Look",
          "einschaetzung": "Vorschlag: keine Aufhellung, sondern eine saubere Ausgangsfarbe. Deine Verfärbungen sitzen an den Zwischenräumen der Schneidezähne und sind oberflächlich – eine professionelle Reinigung bringt dort mehr als jedes Bleaching. Das passt zum Rest des Vorschlags: klarer, nicht künstlicher.",
          "empfehlungen": [
            "Einen Termin zur professionellen Zahnreinigung machen, am besten vor dem Frisurtermin.",
            "Danach zwei Wochen konsequent Interdentalbürsten benutzen – dort kommt die Verfärbung zuerst zurück.",
            "Was bleibt: Dein Lächeln erreicht die Augen. Daran ist nichts zu verbessern."
          ],
          "produkte": [
            {
              "name": "Interdentalbürsten im Set",
              "kategorie": "werkzeug",
              "beschreibung": "Abends vor dem Zähneputzen, verschiedene Größen ausprobieren und die passende behalten.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "Mimik",
          "einschaetzung": "Auf dem Foto ist die Kinnpartie leicht angespannt. Mit der neuen Bartkontur fällt das eher auf als vorher, weil die Kieferlinie sichtbarer wird.",
          "empfehlungen": [
            "Vor Fotos einmal bewusst ausatmen und den Kiefer lockern.",
            "Kinn minimal nach vorn und leicht nach unten – das definiert die Kieferlinie, ohne angestrengt zu wirken."
          ],
          "produkte": []
        }
      ]
    }''',
    AnalyseModul.figurPassform: '''
    {
      "modul": "figurPassform",
      "einleitung": "Gleichmäßig verteilte Proportionen mit leicht breiteren Schultern als Hüfte. Das ist die Figur, mit der die klaren Silhouetten des neuen Looks am einfachsten funktionieren – sie brauchen genau diese Schulterlinie.",
      "habits": [
        "Nach dem Aufstehen: 30 Sekunden Brustöffner im Türrahmen",
        "Wenn die Schultern nach vorn kippen: kurz aufrichten",
        "Nach dem Abendessen: Nacken fünf Minuten lockern",
        "Vor dem Schlafengehen: Outfit für morgen auf Passform prüfen"
      ],
      "sektionen": [
        {
          "titel": "Dein neuer Look",
          "einschaetzung": "Vorschlag: strukturierte Oberteile mit exakt sitzender Schulternaht statt weit geschnittener Hemden. Deine Schultern sind breiter als die Hüfte – ein Schnitt, der diese Linie aufnimmt, gibt der Silhouette dieselbe Klarheit, die der neue Haarschnitt oben setzt. Weite Hemden nehmen genau diese Linie wieder heraus.",
          "empfehlungen": [
            "Beim Anprobieren zuerst die Schulternaht prüfen: Sie muss auf dem Schulterknochen enden, nicht darüber hinaus.",
            "Ein Overshirt oder eine leichte, ungefütterte Jacke als dritte Schicht – sie trägt die neue Silhouette.",
            "Was bleibt: Deine geraden Hosen mit leichtem Taper. Die passen unverändert zum neuen Look."
          ],
          "produkte": []
        },
        {
          "titel": "Haltung",
          "einschaetzung": "Im Seitenprofil sind die Schultern leicht nach vorn gerollt – typisch für Schreibtischarbeit. Bei strukturierten Oberteilen fällt das deutlicher auf als bei weiten.",
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
      "einleitung": "Die gezeigten Outfits sind funktional und zurückhaltend – eine gute Grundlage, aber ohne erkennbare Richtung. Genau da setzt der Vorschlag an.",
      "habits": [
        "Vor dem Schlafengehen: Outfit für morgen rauslegen",
        "Nach dem Abendessen: Ein Teil im Schrank kritisch prüfen",
        "Schuhe vom Vortag auslüften",
        "Nach dem Duschen: Passform am Spiegel kurz kontrollieren"
      ],
      "sektionen": [
        {
          "titel": "Dein neuer Look",
          "einschaetzung": "Vorschlag: Smart & hochwertig – wenige, gut sitzende Teile in gedeckten Farben statt vieler funktionaler. Konkret: Strickpullover mit Rundhals, Overshirt aus Baumwolltwill, gerade Hose, schlichte Ledersneaker. Deine Schulterlinie und der neue Schnitt tragen diese Richtung, ohne dass sie steif wirkt.",
          "empfehlungen": [
            "Fang mit einem Overshirt in Oliv oder Camel an – es passt über beide Outfits, die du heute schon trägst.",
            "Ein Strickpullover in Ecru ersetzt drei T-Shirts und hebt den ganzen Look eine Stufe.",
            "Ledersneaker in einem ruhigen Ton statt Laufschuhen im Alltag. Das ist der einzelne Wechsel mit der größten Wirkung.",
            "Was bleibt: Deine neutralen Farben und die saubere Passform. Beides ist schon die halbe Miete."
          ],
          "produkte": [
            {
              "name": "Overshirt aus Baumwolltwill",
              "kategorie": "kleidung",
              "beschreibung": "Als dritte Schicht über T-Shirt oder Strick. Gedeckte Farbe, damit es zu allem passt.",
              "affiliateUrl": null
            },
            {
              "name": "Strickpullover mit Rundhals",
              "kategorie": "kleidung",
              "beschreibung": "Ecru oder Camel, feine Struktur. Über dem T-Shirt oder direkt auf der Haut.",
              "affiliateUrl": null
            }
          ]
        },
        {
          "titel": "So kommst du dahin",
          "einschaetzung": "Der Wechsel läuft über wenige Käufe, nicht über einen neuen Kleiderschrank. Drei Teile reichen, um die Richtung sichtbar zu machen.",
          "empfehlungen": [
            "Erst ergänzen, dann aussortieren – so bleibt der Schrank die ganze Zeit benutzbar.",
            "Neue Teile immer gegen drei vorhandene testen: passt es zu mindestens zweien, kommt es mit.",
            "Nimm dir für die drei Teile zwei Monate Zeit statt eines Wochenendes. Alles auf einmal fühlt sich verkleidet an."
          ],
          "produkte": []
        }
      ]
    }''',
  };

  static const String _planEntdecken = '''{
    "sofort": [
      "Heute einen Frisurtermin ausmachen und den Satz für den Salon aufschreiben.",
      "Ein Foto eines Textured Crop im Handy speichern und zum Termin mitnehmen."
    ],
    "dreissigTage": [
      "Nach dem Schnitt zwei Wochen lang jeden Morgen mit der Paste üben, bis der Griff sitzt.",
      "Den Bart auf 6 mm bringen und die Halslinie einmal sauber neu setzen.",
      "Ein Overshirt in Oliv oder Camel besorgen und zu beiden bestehenden Outfits testen."
    ],
    "langfristig": [
      "Den Schnitt alle 3 bis 4 Wochen nachschneiden lassen – die Form lebt vom Fade.",
      "Den Kleiderschrank über ein halbes Jahr auf wenige, gut kombinierbare Teile in warmen Farben bringen.",
      "Die Pflegeroutine bei drei festen Schritten halten, auch wenn der Look sich ändert."
    ]
  }''';
}
