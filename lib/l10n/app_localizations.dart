import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Produktname. Wird in keiner Sprache uebersetzt.
  ///
  /// In de, this message translates to:
  /// **'TrueGlow'**
  String get appName;

  /// No description provided for @weiter.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get weiter;

  /// No description provided for @zurueck.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get zurueck;

  /// No description provided for @abbrechen.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get abbrechen;

  /// No description provided for @fertig.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get fertig;

  /// No description provided for @erneutVersuchen.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get erneutVersuchen;

  /// No description provided for @speichern.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get speichern;

  /// No description provided for @zurStartseite.
  ///
  /// In de, this message translates to:
  /// **'Zur Startseite'**
  String get zurStartseite;

  /// No description provided for @onbWillkommenTitel.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei TrueGlow'**
  String get onbWillkommenTitel;

  /// No description provided for @onbWillkommenText.
  ///
  /// In de, this message translates to:
  /// **'Wir erstellen dir einen persönlichen Plan für Haut, Haare, Bart und Style. Keine Bewertungen, keine Punktzahlen – nur konkrete Schritte.'**
  String get onbWillkommenText;

  /// No description provided for @onbAlterTitel.
  ///
  /// In de, this message translates to:
  /// **'Wie alt bist du?'**
  String get onbAlterTitel;

  /// No description provided for @onbAlterText.
  ///
  /// In de, this message translates to:
  /// **'Das hilft uns, passende Empfehlungen auszuwählen.'**
  String get onbAlterText;

  /// No description provided for @onbBudgetTitel.
  ///
  /// In de, this message translates to:
  /// **'Wie viel möchtest du investieren?'**
  String get onbBudgetTitel;

  /// No description provided for @onbBudgetText.
  ///
  /// In de, this message translates to:
  /// **'Für Pflegeprodukte und Styling pro Monat.'**
  String get onbBudgetText;

  /// No description provided for @onbZeitTitel.
  ///
  /// In de, this message translates to:
  /// **'Wie viel Zeit hast du täglich?'**
  String get onbZeitTitel;

  /// No description provided for @onbZeitText.
  ///
  /// In de, this message translates to:
  /// **'Dein Plan wird auf dieses Zeitbudget zugeschnitten.'**
  String get onbZeitText;

  /// No description provided for @onbFokusTitel.
  ///
  /// In de, this message translates to:
  /// **'Worauf willst du dich konzentrieren?'**
  String get onbFokusTitel;

  /// No description provided for @onbFokusText.
  ///
  /// In de, this message translates to:
  /// **'Mehrfachauswahl möglich.'**
  String get onbFokusText;

  /// No description provided for @onbDatenschutzTitel.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Hinweise'**
  String get onbDatenschutzTitel;

  /// No description provided for @homeLeerTitel.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Analyse'**
  String get homeLeerTitel;

  /// No description provided for @homeLeerText.
  ///
  /// In de, this message translates to:
  /// **'Mach zwei Fotos und erhalte deinen persönlichen Verbesserungsplan.'**
  String get homeLeerText;

  /// No description provided for @homeAnalyseStarten.
  ///
  /// In de, this message translates to:
  /// **'Analyse starten'**
  String get homeAnalyseStarten;

  /// No description provided for @homeNeueAnalyse.
  ///
  /// In de, this message translates to:
  /// **'Neue Analyse'**
  String get homeNeueAnalyse;

  /// No description provided for @homePlanAnsehen.
  ///
  /// In de, this message translates to:
  /// **'Plan ansehen'**
  String get homePlanAnsehen;

  /// No description provided for @fotoTitelFrontal.
  ///
  /// In de, this message translates to:
  /// **'Frontalfoto'**
  String get fotoTitelFrontal;

  /// No description provided for @fotoTitelProfil.
  ///
  /// In de, this message translates to:
  /// **'Seitenprofil'**
  String get fotoTitelProfil;

  /// No description provided for @fotoHinweisFrontal.
  ///
  /// In de, this message translates to:
  /// **'Schau direkt in die Kamera. Neutrales Gesicht, gutes Licht, keine Kopfbedeckung.'**
  String get fotoHinweisFrontal;

  /// No description provided for @fotoHinweisProfil.
  ///
  /// In de, this message translates to:
  /// **'Dreh den Kopf um 90° zur Seite. Ohr und Kinnlinie sollten sichtbar sein.'**
  String get fotoHinweisProfil;

  /// No description provided for @fotoKamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get fotoKamera;

  /// No description provided for @fotoGalerie.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get fotoGalerie;

  /// No description provided for @fotoNeuAufnehmen.
  ///
  /// In de, this message translates to:
  /// **'Neu aufnehmen'**
  String get fotoNeuAufnehmen;

  /// No description provided for @fotoAnalyseStarten.
  ///
  /// In de, this message translates to:
  /// **'Analyse starten'**
  String get fotoAnalyseStarten;

  /// No description provided for @kameraAusloesen.
  ///
  /// In de, this message translates to:
  /// **'Auslösen'**
  String get kameraAusloesen;

  /// No description provided for @kameraWechseln.
  ///
  /// In de, this message translates to:
  /// **'Kamera wechseln'**
  String get kameraWechseln;

  /// No description provided for @kameraSchliessen.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get kameraSchliessen;

  /// No description provided for @kameraStartet.
  ///
  /// In de, this message translates to:
  /// **'Kamera wird gestartet...'**
  String get kameraStartet;

  /// No description provided for @kameraKeinGesicht.
  ///
  /// In de, this message translates to:
  /// **'Positioniere dein Gesicht im Rahmen'**
  String get kameraKeinGesicht;

  /// No description provided for @kameraZuWeitWeg.
  ///
  /// In de, this message translates to:
  /// **'Geh näher ran'**
  String get kameraZuWeitWeg;

  /// No description provided for @kameraZuNah.
  ///
  /// In de, this message translates to:
  /// **'Etwas weiter weg'**
  String get kameraZuNah;

  /// No description provided for @kameraNichtMittig.
  ///
  /// In de, this message translates to:
  /// **'Mittig positionieren'**
  String get kameraNichtMittig;

  /// No description provided for @kameraPerfekt.
  ///
  /// In de, this message translates to:
  /// **'Perfekt – jetzt auslösen'**
  String get kameraPerfekt;

  /// No description provided for @kameraZuDunkel.
  ///
  /// In de, this message translates to:
  /// **'Mehr Licht nötig'**
  String get kameraZuDunkel;

  /// No description provided for @koerperNiemand.
  ///
  /// In de, this message translates to:
  /// **'Stell dich ins Bild'**
  String get koerperNiemand;

  /// No description provided for @koerperNichtGanz.
  ///
  /// In de, this message translates to:
  /// **'Ganz ins Bild – Kopf und Füße'**
  String get koerperNichtGanz;

  /// No description provided for @koerperZuWeitWeg.
  ///
  /// In de, this message translates to:
  /// **'Ein paar Schritte näher'**
  String get koerperZuWeitWeg;

  /// No description provided for @koerperZuNah.
  ///
  /// In de, this message translates to:
  /// **'Ein paar Schritte zurück'**
  String get koerperZuNah;

  /// No description provided for @koerperNichtMittig.
  ///
  /// In de, this message translates to:
  /// **'Mittig hinstellen'**
  String get koerperNichtMittig;

  /// No description provided for @koerperBereit.
  ///
  /// In de, this message translates to:
  /// **'Steht – nicht bewegen'**
  String get koerperBereit;

  /// No description provided for @koerperAutoHinweis.
  ///
  /// In de, this message translates to:
  /// **'Stell dein Handy auf, tritt zurück und stell dich in den Umriss. Sobald du ganz im Bild stehst, zählt die App herunter und löst selbst aus. Du kannst auch jederzeit von Hand auslösen.'**
  String get koerperAutoHinweis;

  /// No description provided for @kameraKeineBerechtigungTitel.
  ///
  /// In de, this message translates to:
  /// **'Kamerazugriff nötig'**
  String get kameraKeineBerechtigungTitel;

  /// No description provided for @kameraKeineBerechtigungText.
  ///
  /// In de, this message translates to:
  /// **'TrueGlow braucht Zugriff auf die Kamera, um die Live-Vorschau mit Positionierungshilfe zu zeigen. Du kannst den Zugriff in den App-Einstellungen erlauben – oder stattdessen ein Foto aus der Galerie wählen.'**
  String get kameraKeineBerechtigungText;

  /// No description provided for @kameraEinstellungenOeffnen.
  ///
  /// In de, this message translates to:
  /// **'App-Einstellungen öffnen'**
  String get kameraEinstellungenOeffnen;

  /// No description provided for @kameraNichtVerfuegbarTitel.
  ///
  /// In de, this message translates to:
  /// **'Kamera nicht verfügbar'**
  String get kameraNichtVerfuegbarTitel;

  /// No description provided for @kameraNichtVerfuegbarText.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät konnte keine Kamera gestartet werden. Wähle ein Foto aus der Galerie.'**
  String get kameraNichtVerfuegbarText;

  /// Die Aufnahme selbst ist gescheitert, nicht die Pruefung danach. Beim Auto-Ausloeser der einzige Hinweis darauf, dass etwas schiefging.
  ///
  /// In de, this message translates to:
  /// **'Das Foto hat nicht geklappt – bitte noch einmal'**
  String get aufnahmeFehlgeschlagen;

  /// No description provided for @moduleTitel.
  ///
  /// In de, this message translates to:
  /// **'Analyse zusammenstellen'**
  String get moduleTitel;

  /// No description provided for @moduleEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Deine Analyse'**
  String get moduleEyebrow;

  /// No description provided for @moduleUeberschrift.
  ///
  /// In de, this message translates to:
  /// **'Was sollen wir uns ansehen?'**
  String get moduleUeberschrift;

  /// No description provided for @moduleEinleitung.
  ///
  /// In de, this message translates to:
  /// **'Gesicht, Haare und Bart sind immer dabei. Alles Weitere wählst du selbst – und kannst es auch später noch ergänzen.'**
  String get moduleEinleitung;

  /// No description provided for @moduleBasisBadge.
  ///
  /// In de, this message translates to:
  /// **'Basis'**
  String get moduleBasisBadge;

  /// No description provided for @moduleStartBasis.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme starten · Basis'**
  String get moduleStartBasis;

  /// No description provided for @moduleErweitern.
  ///
  /// In de, this message translates to:
  /// **'Analyse erweitern'**
  String get moduleErweitern;

  /// No description provided for @moduleErweiternText.
  ///
  /// In de, this message translates to:
  /// **'Diese Bereiche fehlen deiner Analyse noch. Deine bisherigen Fotos bleiben erhalten – es kommen nur die neuen Aufnahmen dazu.'**
  String get moduleErweiternText;

  /// No description provided for @vorschauTitel.
  ///
  /// In de, this message translates to:
  /// **'Passt das so?'**
  String get vorschauTitel;

  /// No description provided for @vorschauUebernehmen.
  ///
  /// In de, this message translates to:
  /// **'Passt'**
  String get vorschauUebernehmen;

  /// No description provided for @vorschauWiederholen.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get vorschauWiederholen;

  /// No description provided for @vorschauHinweis.
  ///
  /// In de, this message translates to:
  /// **'Erst wenn du bestätigst, wird das Foto gespeichert.'**
  String get vorschauHinweis;

  /// No description provided for @kontingentTagesgrenze.
  ///
  /// In de, this message translates to:
  /// **'Heute keine Analyse mehr frei'**
  String get kontingentTagesgrenze;

  /// No description provided for @kontingentTagesgrenzeText.
  ///
  /// In de, this message translates to:
  /// **'Drei Analysen pro Tag – das Kontingent ist aufgebraucht. Ab morgen früh geht es weiter. Dein Plan, deine Checkliste und der Check-in bleiben in der Zwischenzeit nutzbar.'**
  String get kontingentTagesgrenzeText;

  /// No description provided for @kontingentMonatsgrenze.
  ///
  /// In de, this message translates to:
  /// **'Diesen Monat keine Analyse mehr frei'**
  String get kontingentMonatsgrenze;

  /// No description provided for @kontingentMonatsgrenzeText.
  ///
  /// In de, this message translates to:
  /// **'Dreißig Analysen pro Monat – das Kontingent ist aufgebraucht. Zum Monatswechsel füllt es sich wieder auf.'**
  String get kontingentMonatsgrenzeText;

  /// Verbleibende Analysen des Tages.
  ///
  /// In de, this message translates to:
  /// **'{uebrig, plural, =1{Noch 1 von {gesamt} Analysen heute} other{Noch {uebrig} von {gesamt} Analysen heute}}'**
  String kontingentUebrig(int uebrig, int gesamt);

  /// No description provided for @richtungTitel.
  ///
  /// In de, this message translates to:
  /// **'Deine Richtung'**
  String get richtungTitel;

  /// No description provided for @richtungEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Optional'**
  String get richtungEyebrow;

  /// No description provided for @richtungUeberschrift.
  ///
  /// In de, this message translates to:
  /// **'In welche Richtung soll sich dein Look entwickeln?'**
  String get richtungUeberschrift;

  /// No description provided for @richtungEinleitung.
  ///
  /// In de, this message translates to:
  /// **'Sag uns, worauf du hinauswillst – die Empfehlungen richten sich dann danach aus. Du kannst den Schritt auch überspringen; dann schauen wir neutral auf deine Fotos.'**
  String get richtungEinleitung;

  /// No description provided for @richtungChipsTitel.
  ///
  /// In de, this message translates to:
  /// **'Wähl aus, was passt'**
  String get richtungChipsTitel;

  /// No description provided for @richtungChipsText.
  ///
  /// In de, this message translates to:
  /// **'Mehrfachauswahl möglich.'**
  String get richtungChipsText;

  /// No description provided for @richtungFreitextTitel.
  ///
  /// In de, this message translates to:
  /// **'Sag es in deinen eigenen Worten'**
  String get richtungFreitextTitel;

  /// No description provided for @richtungFreitextPlatzhalter.
  ///
  /// In de, this message translates to:
  /// **'Beschreib, was du dir wünschst – Vorbilder, Anlässe, Unsicherheiten, No-Gos. Je konkreter, desto besser wird dein Plan.'**
  String get richtungFreitextPlatzhalter;

  /// No description provided for @richtungFreitextHinweis.
  ///
  /// In de, this message translates to:
  /// **'Kein Chat: Dein Text geht einmalig mit in die Analyse und bleibt sonst auf deinem Gerät.'**
  String get richtungFreitextHinweis;

  /// No description provided for @richtungWeiter.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Aufnahme'**
  String get richtungWeiter;

  /// No description provided for @richtungSpeichern.
  ///
  /// In de, this message translates to:
  /// **'Richtung übernehmen'**
  String get richtungSpeichern;

  /// No description provided for @richtungLeer.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Richtung angegeben.'**
  String get richtungLeer;

  /// No description provided for @richtungLeerText.
  ///
  /// In de, this message translates to:
  /// **'Gib der Analyse eigene Ziele mit – die Empfehlungen richten sich dann danach aus.'**
  String get richtungLeerText;

  /// No description provided for @richtungAngeben.
  ///
  /// In de, this message translates to:
  /// **'Richtung angeben'**
  String get richtungAngeben;

  /// No description provided for @richtungAendern.
  ///
  /// In de, this message translates to:
  /// **'Ändern'**
  String get richtungAendern;

  /// No description provided for @richtungAktualisieren.
  ///
  /// In de, this message translates to:
  /// **'Plan mit neuer Richtung aktualisieren'**
  String get richtungAktualisieren;

  /// No description provided for @richtungAktualisierenText.
  ///
  /// In de, this message translates to:
  /// **'Deine Richtung hat sich seit dieser Analyse geändert. Wir erstellen den Plan mit deinen vorhandenen Fotos neu – ohne neue Aufnahmen.'**
  String get richtungAktualisierenText;

  /// No description provided for @flowUeberspringen.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get flowUeberspringen;

  /// No description provided for @flowAbbrechen.
  ///
  /// In de, this message translates to:
  /// **'Flow abbrechen?'**
  String get flowAbbrechen;

  /// No description provided for @flowAbbrechenText.
  ///
  /// In de, this message translates to:
  /// **'Deine bisherigen Aufnahmen bleiben gespeichert. Du kannst später dort weitermachen, wo du aufgehört hast.'**
  String get flowAbbrechenText;

  /// No description provided for @flowWeitermachen.
  ///
  /// In de, this message translates to:
  /// **'Weitermachen'**
  String get flowWeitermachen;

  /// No description provided for @lichtTitel.
  ///
  /// In de, this message translates to:
  /// **'Kurz vorab'**
  String get lichtTitel;

  /// No description provided for @lichtText.
  ///
  /// In de, this message translates to:
  /// **'Drei Dinge machen den größten Unterschied für eine brauchbare Analyse:'**
  String get lichtText;

  /// No description provided for @lichtTageslicht.
  ///
  /// In de, this message translates to:
  /// **'Tageslicht'**
  String get lichtTageslicht;

  /// No description provided for @lichtTageslichtText.
  ///
  /// In de, this message translates to:
  /// **'Stell dich ans Fenster. Indirektes Tageslicht von vorne, kein Gegenlicht, keine bunte Deckenlampe.'**
  String get lichtTageslichtText;

  /// No description provided for @lichtKeinFilter.
  ///
  /// In de, this message translates to:
  /// **'Kein Filter'**
  String get lichtKeinFilter;

  /// No description provided for @lichtKeinFilterText.
  ///
  /// In de, this message translates to:
  /// **'Schalte Beauty-Modus, Filter und Weichzeichner in der Kamera aus – sonst analysieren wir die Bearbeitung statt dich.'**
  String get lichtKeinFilterText;

  /// No description provided for @lichtRuhigeHand.
  ///
  /// In de, this message translates to:
  /// **'Ruhige Hand'**
  String get lichtRuhigeHand;

  /// No description provided for @lichtRuhigeHandText.
  ///
  /// In de, this message translates to:
  /// **'Handy mit beiden Händen halten oder anlehnen. Unscharfe Fotos kosten am meisten Genauigkeit.'**
  String get lichtRuhigeHandText;

  /// No description provided for @lichtStarten.
  ///
  /// In de, this message translates to:
  /// **'Los geht es'**
  String get lichtStarten;

  /// No description provided for @figurFormularTitel.
  ///
  /// In de, this message translates to:
  /// **'Deine Maße'**
  String get figurFormularTitel;

  /// No description provided for @figurFormularText.
  ///
  /// In de, this message translates to:
  /// **'Größe und Gewicht helfen, Schnitte und Passformen realistisch einzuschätzen. Beides bleibt auf deinem Gerät.'**
  String get figurFormularText;

  /// No description provided for @figurGroesse.
  ///
  /// In de, this message translates to:
  /// **'Körpergröße'**
  String get figurGroesse;

  /// No description provided for @figurGewicht.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get figurGewicht;

  /// No description provided for @figurGroesseFehler.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Größe zwischen 120 und 230 cm.'**
  String get figurGroesseFehler;

  /// No description provided for @figurGewichtFehler.
  ///
  /// In de, this message translates to:
  /// **'Bitte ein Gewicht zwischen 35 und 250 kg.'**
  String get figurGewichtFehler;

  /// No description provided for @stilFragebogenTitel.
  ///
  /// In de, this message translates to:
  /// **'Dein Stil'**
  String get stilFragebogenTitel;

  /// No description provided for @stilFragebogenText.
  ///
  /// In de, this message translates to:
  /// **'Vier kurze Fragen, damit die Vorschläge zu deinem Alltag passen.'**
  String get stilFragebogenText;

  /// No description provided for @stilZiel.
  ///
  /// In de, this message translates to:
  /// **'Wohin soll es gehen?'**
  String get stilZiel;

  /// No description provided for @stilZielText.
  ///
  /// In de, this message translates to:
  /// **'Mehrfachauswahl möglich.'**
  String get stilZielText;

  /// No description provided for @stilDresscode.
  ///
  /// In de, this message translates to:
  /// **'Was verlangt dein Alltag?'**
  String get stilDresscode;

  /// No description provided for @stilBudget.
  ///
  /// In de, this message translates to:
  /// **'Was gibst du pro Kleidungsstück aus?'**
  String get stilBudget;

  /// No description provided for @stilPflege.
  ///
  /// In de, this message translates to:
  /// **'Wie viel Aufwand ist okay?'**
  String get stilPflege;

  /// No description provided for @analyseTitel.
  ///
  /// In de, this message translates to:
  /// **'Analyse läuft'**
  String get analyseTitel;

  /// No description provided for @analyseHinweis.
  ///
  /// In de, this message translates to:
  /// **'Das dauert etwa 20 Sekunden. Bitte nicht schließen.'**
  String get analyseHinweis;

  /// No description provided for @ergebnisTitel.
  ///
  /// In de, this message translates to:
  /// **'Deine Analyse'**
  String get ergebnisTitel;

  /// No description provided for @ergebnisGesichtsform.
  ///
  /// In de, this message translates to:
  /// **'Gesichtsform'**
  String get ergebnisGesichtsform;

  /// No description provided for @ergebnisPlanErstellen.
  ///
  /// In de, this message translates to:
  /// **'Plan erstellen'**
  String get ergebnisPlanErstellen;

  /// No description provided for @ergebnisEmpfehlungen.
  ///
  /// In de, this message translates to:
  /// **'Empfehlungen'**
  String get ergebnisEmpfehlungen;

  /// No description provided for @ergebnisProdukte.
  ///
  /// In de, this message translates to:
  /// **'Produkte'**
  String get ergebnisProdukte;

  /// No description provided for @planTitel.
  ///
  /// In de, this message translates to:
  /// **'Dein Plan'**
  String get planTitel;

  /// No description provided for @planSofort.
  ///
  /// In de, this message translates to:
  /// **'Sofort umsetzbar'**
  String get planSofort;

  /// No description provided for @planDreissigTage.
  ///
  /// In de, this message translates to:
  /// **'Erste 30 Tage'**
  String get planDreissigTage;

  /// No description provided for @planLangfristig.
  ///
  /// In de, this message translates to:
  /// **'Langfristig'**
  String get planLangfristig;

  /// No description provided for @planStreak.
  ///
  /// In de, this message translates to:
  /// **'Tage in Folge'**
  String get planStreak;

  /// No description provided for @planFertigZurStartseite.
  ///
  /// In de, this message translates to:
  /// **'Fertig – zur Startseite'**
  String get planFertigZurStartseite;

  /// No description provided for @checkinTitel.
  ///
  /// In de, this message translates to:
  /// **'Check-in'**
  String get checkinTitel;

  /// No description provided for @checkinKarteTitel.
  ///
  /// In de, this message translates to:
  /// **'Kurzer Check-in'**
  String get checkinKarteTitel;

  /// No description provided for @checkinKarteText.
  ///
  /// In de, this message translates to:
  /// **'Dauert unter einer Minute und macht deinen Plan passgenauer.'**
  String get checkinKarteText;

  /// No description provided for @checkinKarteFortsetzen.
  ///
  /// In de, this message translates to:
  /// **'Angefangen – weitermachen'**
  String get checkinKarteFortsetzen;

  /// No description provided for @checkinStarten.
  ///
  /// In de, this message translates to:
  /// **'Check-in starten'**
  String get checkinStarten;

  /// No description provided for @checkinFortsetzen.
  ///
  /// In de, this message translates to:
  /// **'Weitermachen'**
  String get checkinFortsetzen;

  /// No description provided for @checkinSpaeter.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get checkinSpaeter;

  /// No description provided for @checkinNaechster.
  ///
  /// In de, this message translates to:
  /// **'Nächster Check-in'**
  String get checkinNaechster;

  /// No description provided for @checkinPushTitel.
  ///
  /// In de, this message translates to:
  /// **'Kurzer Check-in'**
  String get checkinPushTitel;

  /// No description provided for @checkinPushText.
  ///
  /// In de, this message translates to:
  /// **'Dauert unter einer Minute.'**
  String get checkinPushText;

  /// No description provided for @checkinHabitsTitel.
  ///
  /// In de, this message translates to:
  /// **'Wie gut passen die Aufgaben?'**
  String get checkinHabitsTitel;

  /// No description provided for @checkinHabitsText.
  ///
  /// In de, this message translates to:
  /// **'Ein Tipp pro Aufgabe – es geht nur um deinen Alltag, nicht um Ergebnisse.'**
  String get checkinHabitsText;

  /// No description provided for @checkinHabitsErneut.
  ///
  /// In de, this message translates to:
  /// **'Nur die Aufgaben, die zuletzt gehakt haben.'**
  String get checkinHabitsErneut;

  /// No description provided for @checkinGrundTitel.
  ///
  /// In de, this message translates to:
  /// **'Was passt nicht?'**
  String get checkinGrundTitel;

  /// No description provided for @checkinGrundFreitext.
  ///
  /// In de, this message translates to:
  /// **'Magst du kurz sagen, was los ist?'**
  String get checkinGrundFreitext;

  /// No description provided for @checkinWirkungTitelFrueh.
  ///
  /// In de, this message translates to:
  /// **'Wie fühlt es sich an?'**
  String get checkinWirkungTitelFrueh;

  /// No description provided for @checkinWirkungTextFrueh.
  ///
  /// In de, this message translates to:
  /// **'Nur die schnellen Dinge – alles andere braucht noch etwas Zeit.'**
  String get checkinWirkungTextFrueh;

  /// No description provided for @checkinWirkungTitelSpaet.
  ///
  /// In de, this message translates to:
  /// **'Was hat sich getan?'**
  String get checkinWirkungTitelSpaet;

  /// No description provided for @checkinWirkungTextSpaet.
  ///
  /// In de, this message translates to:
  /// **'Ein Monat ist genug Zeit für erste sichtbare Unterschiede.'**
  String get checkinWirkungTextSpaet;

  /// No description provided for @checkinWirkungNotiz.
  ///
  /// In de, this message translates to:
  /// **'Anmerkung (optional)'**
  String get checkinWirkungNotiz;

  /// No description provided for @checkinHinweisTitel.
  ///
  /// In de, this message translates to:
  /// **'Kurz zur Einordnung'**
  String get checkinHinweisTitel;

  /// No description provided for @checkinFotoTitel.
  ///
  /// In de, this message translates to:
  /// **'Fortschrittsfoto'**
  String get checkinFotoTitel;

  /// No description provided for @checkinFotoText.
  ///
  /// In de, this message translates to:
  /// **'Optional: ein Foto unter denselben Bedingungen wie beim Start – Tageslicht, kein Filter, gleicher Bildausschnitt.'**
  String get checkinFotoText;

  /// No description provided for @checkinFotoAufnehmen.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get checkinFotoAufnehmen;

  /// No description provided for @checkinFotoNeu.
  ///
  /// In de, this message translates to:
  /// **'Neu aufnehmen'**
  String get checkinFotoNeu;

  /// No description provided for @checkinFotoOhne.
  ///
  /// In de, this message translates to:
  /// **'Ohne Foto weiter'**
  String get checkinFotoOhne;

  /// No description provided for @checkinVergleichTitel.
  ///
  /// In de, this message translates to:
  /// **'Vorher / Nachher'**
  String get checkinVergleichTitel;

  /// No description provided for @checkinVergleichVorher.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get checkinVergleichVorher;

  /// No description provided for @checkinVergleichNachher.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get checkinVergleichNachher;

  /// Fotos bleiben auf dem Geraet. Nach einem Geraetewechsel fehlen sie – erklaerter Normalzustand, kein Fehler.
  ///
  /// In de, this message translates to:
  /// **'Foto auf diesem Gerät nicht verfügbar'**
  String get fotoNichtAufDiesemGeraet;

  /// No description provided for @checkinAuswertungLaeuft.
  ///
  /// In de, this message translates to:
  /// **'Wir schauen uns deine Antworten an…'**
  String get checkinAuswertungLaeuft;

  /// No description provided for @checkinFazitTitel.
  ///
  /// In de, this message translates to:
  /// **'Zwischenfazit'**
  String get checkinFazitTitel;

  /// No description provided for @checkinAenderungenTitel.
  ///
  /// In de, this message translates to:
  /// **'Das passen wir an'**
  String get checkinAenderungenTitel;

  /// No description provided for @checkinKeineAenderung.
  ///
  /// In de, this message translates to:
  /// **'Dein Plan bleibt so, wie er ist – das läuft gut.'**
  String get checkinKeineAenderung;

  /// No description provided for @checkinBestaetigen.
  ///
  /// In de, this message translates to:
  /// **'Änderungen übernehmen'**
  String get checkinBestaetigen;

  /// No description provided for @checkinAbschliessen.
  ///
  /// In de, this message translates to:
  /// **'Check-in abschließen'**
  String get checkinAbschliessen;

  /// No description provided for @checkinAbbrechenTitel.
  ///
  /// In de, this message translates to:
  /// **'Check-in später fortsetzen?'**
  String get checkinAbbrechenTitel;

  /// No description provided for @checkinAbbrechenText.
  ///
  /// In de, this message translates to:
  /// **'Deine bisherigen Antworten bleiben gespeichert. Du kannst jederzeit dort weitermachen, wo du aufgehört hast.'**
  String get checkinAbbrechenText;

  /// No description provided for @checkinVerlassen.
  ///
  /// In de, this message translates to:
  /// **'Später fortsetzen'**
  String get checkinVerlassen;

  /// No description provided for @checkinDankeTitel.
  ///
  /// In de, this message translates to:
  /// **'Danke dir!'**
  String get checkinDankeTitel;

  /// No description provided for @checkinDankeText.
  ///
  /// In de, this message translates to:
  /// **'Dein Plan ist aktualisiert. Angepasste Aufgaben sind in der Checkliste markiert.'**
  String get checkinDankeText;

  /// No description provided for @verlaufTitel.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get verlaufTitel;

  /// No description provided for @verlaufLeer.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Analysen vorhanden.'**
  String get verlaufLeer;

  /// No description provided for @einstellungenTitel.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get einstellungenTitel;

  /// No description provided for @einstellungenAngaben.
  ///
  /// In de, this message translates to:
  /// **'Meine Angaben ändern'**
  String get einstellungenAngaben;

  /// No description provided for @einstellungenErscheinungsbild.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get einstellungenErscheinungsbild;

  /// No description provided for @einstellungenDatenLoeschen.
  ///
  /// In de, this message translates to:
  /// **'Daten löschen, Konto behalten'**
  String get einstellungenDatenLoeschen;

  /// No description provided for @einstellungenKontoLoeschen.
  ///
  /// In de, this message translates to:
  /// **'Konto endgültig löschen'**
  String get einstellungenKontoLoeschen;

  /// No description provided for @einstellungenImpressum.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get einstellungenImpressum;

  /// No description provided for @einstellungenRechtliches.
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get einstellungenRechtliches;

  /// No description provided for @einstellungenDatenschutz.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get einstellungenDatenschutz;

  /// No description provided for @disclaimerMedizin.
  ///
  /// In de, this message translates to:
  /// **'TrueGlow ersetzt keine medizinische Beratung. Bei Hautproblemen wende dich an eine dermatologische Praxis.'**
  String get disclaimerMedizin;

  /// No description provided for @disclaimerFotos.
  ///
  /// In de, this message translates to:
  /// **'Deine Fotos werden ausschließlich zur Analyse an den KI-Dienst gesendet und dort nicht dauerhaft gespeichert. Auf deinem Gerät bleiben sie lokal.'**
  String get disclaimerFotos;

  /// No description provided for @disclaimerZustimmung.
  ///
  /// In de, this message translates to:
  /// **'Ich habe die Hinweise gelesen und stimme zu.'**
  String get disclaimerZustimmung;

  /// Name des Android-Benachrichtigungskanals. Steht so in den Systemeinstellungen des Geraets.
  ///
  /// In de, this message translates to:
  /// **'Check-in-Erinnerungen'**
  String get pushKanalName;

  /// Beschreibung des Android-Benachrichtigungskanals.
  ///
  /// In de, this message translates to:
  /// **'Erinnert dich, wenn ein kurzer Check-in ansteht.'**
  String get pushKanalBeschreibung;

  /// No description provided for @einstellungenSprache.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get einstellungenSprache;

  /// Steht unter dem Sprachumschalter, solange der Nutzer nichts gewaehlt hat.
  ///
  /// In de, this message translates to:
  /// **'TrueGlow folgt der Spracheinstellung deines Handys.'**
  String get spracheFolgtGeraet;

  /// Steht unter dem Sprachumschalter, sobald der Nutzer gewaehlt hat.
  ///
  /// In de, this message translates to:
  /// **'Feste Auswahl – unabhängig von der Systemeinstellung.'**
  String get spracheFest;

  /// Erklaert, dass die Sprache nicht nur die Oberflaeche betrifft.
  ///
  /// In de, this message translates to:
  /// **'Auch deine Analyse wird in dieser Sprache geschrieben. Bereits erstellte Berichte bleiben in der Sprache, in der sie entstanden sind.'**
  String get spracheReportHinweis;

  /// Vorlesehinweis fuer den Umschalter auf dem Anmelde-Bildschirm.
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get spracheWaehlen;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return LDe();
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
