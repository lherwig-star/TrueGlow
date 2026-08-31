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

  /// No description provided for @koerperNiemandFrei.
  ///
  /// In de, this message translates to:
  /// **'Stell dich ins Bild – oder löse von Hand aus'**
  String get koerperNiemandFrei;

  /// No description provided for @koerperNichtGanz.
  ///
  /// In de, this message translates to:
  /// **'Ganz ins Bild – mindestens bis zu den Oberschenkeln'**
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

  /// No description provided for @koerperBereit.
  ///
  /// In de, this message translates to:
  /// **'Steht – nicht bewegen'**
  String get koerperBereit;

  /// No description provided for @koerperTippAbstand.
  ///
  /// In de, this message translates to:
  /// **'Etwas weiter weg – Kopf bis Oberschenkel müssen sichtbar sein'**
  String get koerperTippAbstand;

  /// No description provided for @koerperAutoHinweis.
  ///
  /// In de, this message translates to:
  /// **'Stell dein Handy auf und tritt zurück, bis du vom Kopf bis mindestens zu den Oberschenkeln im Bild bist. Wo du stehst, ist egal, Füße sind kein Muss. Dann zählt die App herunter und löst selbst aus – von Hand geht es jederzeit auch.'**
  String get koerperAutoHinweis;

  /// No description provided for @outfitAutoHinweis.
  ///
  /// In de, this message translates to:
  /// **'Stell dein Handy auf und tritt zurück, bis du vom Kopf bis mindestens zu den Oberschenkeln im Bild bist. Dann zählt die App herunter und löst selbst aus. Liegt das Outfit ausgelegt da, springt nichts an: Dann löst du wie gewohnt von Hand aus.'**
  String get outfitAutoHinweis;

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

  /// Hinweis ueber der Modulliste, wenn das Onboarding etwas vorausgewaehlt hat.
  ///
  /// In de, this message translates to:
  /// **'Aus deinen Schwerpunkten im Onboarding schon angehakt: {module}. Du kannst das hier frei ändern.'**
  String moduleAusOnboarding(String module);

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
  /// **'Zehn Analysen pro Monat – das Kontingent ist aufgebraucht. Am Ersten des nächsten Monats füllt es sich wieder auf zehn. Dein Plan, deine Checkliste und die Check-ins, zu denen die App dich einlädt, gehen weiter – die zählen nicht mit.'**
  String get kontingentMonatsgrenzeText;

  /// Verbleibende Analysen des Tages.
  ///
  /// In de, this message translates to:
  /// **'{uebrig, plural, =1{Noch 1 von {gesamt} Analysen heute} other{Noch {uebrig} von {gesamt} Analysen heute}}'**
  String kontingentUebrig(int uebrig, int gesamt);

  /// Titelzeile des ersten Schritts einer Analyse.
  ///
  /// In de, this message translates to:
  /// **'Neue Analyse'**
  String get modusTitel;

  /// Kleine Zeile ueber der Ueberschrift.
  ///
  /// In de, this message translates to:
  /// **'Erster Schritt'**
  String get modusEyebrow;

  /// Die Frage, die auf diesem Bildschirm beantwortet wird.
  ///
  /// In de, this message translates to:
  /// **'Was soll die Analyse für dich tun?'**
  String get modusUeberschrift;

  /// Zwei Saetze darunter: was beide Modi gemeinsam haben.
  ///
  /// In de, this message translates to:
  /// **'Beides sind vollwertige Analysen mit denselben Fotos. Der Unterschied liegt darin, welche Frage wir für dich beantworten.'**
  String get modusEinleitung;

  /// Karte 1 – der bisherige Modus.
  ///
  /// In de, this message translates to:
  /// **'Meinen Look verfeinern'**
  String get modusVerfeinernTitel;

  /// Untertext von Karte 1.
  ///
  /// In de, this message translates to:
  /// **'Du magst deinen Stil? Wir holen das Beste heraus – Schnitt, Pflege und Details, die zu dem passen, was du schon hast.'**
  String get modusVerfeinernText;

  /// Kurzes Etikett am Verlaufseintrag fuer Karte 1.
  ///
  /// In de, this message translates to:
  /// **'Verfeinert'**
  String get modusVerfeinernEtikett;

  /// Karte 2 – die KI entwirft eine neue Richtung.
  ///
  /// In de, this message translates to:
  /// **'Neuen Look entdecken'**
  String get modusEntdeckenTitel;

  /// Untertext von Karte 2.
  ///
  /// In de, this message translates to:
  /// **'Lust auf Veränderung? Wir schlagen dir eine neue Richtung vor, die zu deinem Gesicht, deinem Haar und deinem Alltag passt.'**
  String get modusEntdeckenText;

  /// Kurzes Etikett am Verlaufseintrag fuer Karte 2.
  ///
  /// In de, this message translates to:
  /// **'Neuer Look'**
  String get modusEntdeckenEtikett;

  /// Knopf unten.
  ///
  /// In de, this message translates to:
  /// **'Weiter zu den Modulen'**
  String get modusWeiter;

  /// Nimmt die zwei haeufigsten Rueckfragen vorweg: Kosten und Fotos.
  ///
  /// In de, this message translates to:
  /// **'Beide Modi kosten genau einen Analyse-Lauf, und du machst in beiden dieselben Aufnahmen. Du entscheidest bei jeder Analyse neu.'**
  String get modusHinweis;

  /// Ueberschrift der Vorspann-Karte im verfeinernden Modus.
  ///
  /// In de, this message translates to:
  /// **'Dein Gesamtbild'**
  String get gesamtbildTitel;

  /// Ueberschrift der Vorspann-Karte im Modus „Neuen Look entdecken".
  ///
  /// In de, this message translates to:
  /// **'Dein neuer Look'**
  String get neuerLookTitel;

  /// No description provided for @richtungszielClean.
  ///
  /// In de, this message translates to:
  /// **'Clean & gepflegt'**
  String get richtungszielClean;

  /// No description provided for @richtungszielCleanUnter.
  ///
  /// In de, this message translates to:
  /// **'Saubere Konturen, ruhige Farben, guter Sitz'**
  String get richtungszielCleanUnter;

  /// No description provided for @richtungszielMarkant.
  ///
  /// In de, this message translates to:
  /// **'Markant & maskulin'**
  String get richtungszielMarkant;

  /// No description provided for @richtungszielMarkantUnter.
  ///
  /// In de, this message translates to:
  /// **'Klare Kanten: Kiefer, Kurzhaar, Kontur'**
  String get richtungszielMarkantUnter;

  /// No description provided for @richtungszielNatuerlich.
  ///
  /// In de, this message translates to:
  /// **'Natürlich & entspannt'**
  String get richtungszielNatuerlich;

  /// No description provided for @richtungszielNatuerlichUnter.
  ///
  /// In de, this message translates to:
  /// **'Wenig Aufwand, echter Typ'**
  String get richtungszielNatuerlichUnter;

  /// No description provided for @richtungszielWeich.
  ///
  /// In de, this message translates to:
  /// **'Weich & elegant'**
  String get richtungszielWeich;

  /// No description provided for @richtungszielWeichUnter.
  ///
  /// In de, this message translates to:
  /// **'Weiche Linien, feiner Stoff, ruhiger Auftritt'**
  String get richtungszielWeichUnter;

  /// No description provided for @richtungszielStreetwear.
  ///
  /// In de, this message translates to:
  /// **'Streetwear & lässig'**
  String get richtungszielStreetwear;

  /// No description provided for @richtungszielStreetwearUnter.
  ///
  /// In de, this message translates to:
  /// **'Entspannter Campus-Look, easy Frisur, Sneaker'**
  String get richtungszielStreetwearUnter;

  /// No description provided for @richtungszielSmart.
  ///
  /// In de, this message translates to:
  /// **'Smart & hochwertig'**
  String get richtungszielSmart;

  /// No description provided for @richtungszielSmartUnter.
  ///
  /// In de, this message translates to:
  /// **'Gepflegt-edel von Schnitt bis Schuh'**
  String get richtungszielSmartUnter;

  /// No description provided for @richtungszielSportlich.
  ///
  /// In de, this message translates to:
  /// **'Sportlich & funktional'**
  String get richtungszielSportlich;

  /// No description provided for @richtungszielSportlichUnter.
  ///
  /// In de, this message translates to:
  /// **'Kurz, praktisch, bereit für Bewegung'**
  String get richtungszielSportlichUnter;

  /// No description provided for @richtungszielKreativ.
  ///
  /// In de, this message translates to:
  /// **'Kreativ & auffällig'**
  String get richtungszielKreativ;

  /// No description provided for @richtungszielKreativUnter.
  ///
  /// In de, this message translates to:
  /// **'Mutige Farben, Statement-Teile, eigener Kopf'**
  String get richtungszielKreativUnter;

  /// Beschriftung des ersten Tabs.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get tabHeute;

  /// Beschriftung des zweiten Tabs.
  ///
  /// In de, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// Beschriftung des dritten Tabs.
  ///
  /// In de, this message translates to:
  /// **'Analyse'**
  String get tabAnalyse;

  /// Beschriftung des vierten Tabs.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get tabFortschritt;

  /// No description provided for @abschnittMorgens.
  ///
  /// In de, this message translates to:
  /// **'Morgens'**
  String get abschnittMorgens;

  /// No description provided for @abschnittTagsueber.
  ///
  /// In de, this message translates to:
  /// **'Tagsüber'**
  String get abschnittTagsueber;

  /// No description provided for @abschnittAbends.
  ///
  /// In de, this message translates to:
  /// **'Abends'**
  String get abschnittAbends;

  /// No description provided for @abschnittBeiBedarf.
  ///
  /// In de, this message translates to:
  /// **'Bei Bedarf'**
  String get abschnittBeiBedarf;

  /// Vorlesetext des Themen-Abzeichens an einer Tagesaufgabe.
  ///
  /// In de, this message translates to:
  /// **'Bereich: {thema}'**
  String abschnittThema(String thema);

  /// Wenn der Report keine Tagesaufgaben hatte.
  ///
  /// In de, this message translates to:
  /// **'Heute nichts abzuhaken'**
  String get heuteKeineAufgabenTitel;

  /// Dazu die Erklaerung.
  ///
  /// In de, this message translates to:
  /// **'Dein Report hat keine Tagesaufgaben mitgebracht. Beim nächsten Check-in passen wir den Plan an.'**
  String get heuteKeineAufgabenText;

  /// Knopf auf dem Plan-Tab.
  ///
  /// In de, this message translates to:
  /// **'Ganzen Report öffnen'**
  String get planReportOeffnen;

  /// Ueberschrift der Kontingent-Karte im Analyse-Tab.
  ///
  /// In de, this message translates to:
  /// **'Deine Analysen'**
  String get analyseTabTitel;

  /// Wenn der Kontingentstand unbekannt ist.
  ///
  /// In de, this message translates to:
  /// **'Starte eine neue Analyse oder öffne eine frühere.'**
  String get analyseTabEinleitung;

  /// Reststand des Monatskontingents.
  ///
  /// In de, this message translates to:
  /// **'{anzahl} von 10 diesen Monat übrig'**
  String kontingentMonatUebrig(int anzahl);

  /// Fussnote unter dem Foto-Album.
  ///
  /// In de, this message translates to:
  /// **'Fortschritts-Fotos bleiben auf deinem Gerät. Sie gehen an keine Cloud.'**
  String get fortschrittTabHinweis;

  /// Ueberschrift der Bilanz-Karte.
  ///
  /// In de, this message translates to:
  /// **'Deine Serie'**
  String get fortschrittSerieTitel;

  /// Beschriftung der laufenden Serie.
  ///
  /// In de, this message translates to:
  /// **'Tage am Stück'**
  String get fortschrittSerieAktuell;

  /// Beschriftung des Rekords.
  ///
  /// In de, this message translates to:
  /// **'Längste Serie'**
  String get fortschrittSerieRekord;

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
  /// **'Weiter'**
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

  /// No description provided for @ausprobierenTitel.
  ///
  /// In de, this message translates to:
  /// **'Das will ich ausprobieren'**
  String get ausprobierenTitel;

  /// No description provided for @ausprobierenEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Optional'**
  String get ausprobierenEyebrow;

  /// No description provided for @ausprobierenUeberschrift.
  ///
  /// In de, this message translates to:
  /// **'Lust, etwas Neues in deine Routine zu holen?'**
  String get ausprobierenUeberschrift;

  /// No description provided for @ausprobierenEinleitung.
  ///
  /// In de, this message translates to:
  /// **'Wähl aus, was du schon immer mal machen wolltest – wir bauen es passend in deinen Plan ein. Du kannst den Schritt auch überspringen.'**
  String get ausprobierenEinleitung;

  /// No description provided for @ausprobierenChipsText.
  ///
  /// In de, this message translates to:
  /// **'Mehrfachauswahl möglich.'**
  String get ausprobierenChipsText;

  /// No description provided for @ausprobierenWeiter.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Aufnahme'**
  String get ausprobierenWeiter;

  /// Zaehler unter den Chips im Schritt „Das will ich ausprobieren“.
  ///
  /// In de, this message translates to:
  /// **'{anzahl} ausgewählt'**
  String ausprobierenGewaehlt(int anzahl);

  /// No description provided for @ausprobierenNichts.
  ///
  /// In de, this message translates to:
  /// **'Für deine Auswahl gibt es hier nichts anzubieten.'**
  String get ausprobierenNichts;

  /// No description provided for @ergebnisNeuFuerDich.
  ///
  /// In de, this message translates to:
  /// **'Neu für dich'**
  String get ergebnisNeuFuerDich;

  /// Name einer Technik im Schritt „Das will ich ausprobieren“. Die Namen und ihre Einzeiler stehen in derselben Reihenfolge wie das Enum `Technik`.
  ///
  /// In de, this message translates to:
  /// **'Kopfhautmassage'**
  String get technikKopfhautmassage;

  /// No description provided for @technikKopfhautmassageUnter.
  ///
  /// In de, this message translates to:
  /// **'Zwei Minuten Fingerkuppen für die Durchblutung.'**
  String get technikKopfhautmassageUnter;

  /// No description provided for @technikRosmarinoel.
  ///
  /// In de, this message translates to:
  /// **'Rosmarinöl für die Kopfhaut'**
  String get technikRosmarinoel;

  /// No description provided for @technikRosmarinoelUnter.
  ///
  /// In de, this message translates to:
  /// **'Verdünnt einmassiert, über Wochen hinweg.'**
  String get technikRosmarinoelUnter;

  /// No description provided for @technikFoehnRundbuerste.
  ///
  /// In de, this message translates to:
  /// **'Föhnen mit der Rundbürste'**
  String get technikFoehnRundbuerste;

  /// No description provided for @technikFoehnRundbuersteUnter.
  ///
  /// In de, this message translates to:
  /// **'Volumen und Form, die den Tag über halten.'**
  String get technikFoehnRundbuersteUnter;

  /// No description provided for @technikHaaroelkur.
  ///
  /// In de, this message translates to:
  /// **'Haar-Ölkur über Nacht'**
  String get technikHaaroelkur;

  /// No description provided for @technikHaaroelkurUnter.
  ///
  /// In de, this message translates to:
  /// **'Öl in die Längen, morgens auswaschen.'**
  String get technikHaaroelkurUnter;

  /// No description provided for @technikSeidenkissen.
  ///
  /// In de, this message translates to:
  /// **'Seidenkissenbezug'**
  String get technikSeidenkissen;

  /// No description provided for @technikSeidenkissenUnter.
  ///
  /// In de, this message translates to:
  /// **'Weniger Reibung, weniger Bruch und Knick.'**
  String get technikSeidenkissenUnter;

  /// No description provided for @technikBartoelRoutine.
  ///
  /// In de, this message translates to:
  /// **'Bartöl & Balsam'**
  String get technikBartoelRoutine;

  /// No description provided for @technikBartoelRoutineUnter.
  ///
  /// In de, this message translates to:
  /// **'Öl für die Haut darunter, Balsam für die Form.'**
  String get technikBartoelRoutineUnter;

  /// No description provided for @technikBartbuerste.
  ///
  /// In de, this message translates to:
  /// **'Bartbürste'**
  String get technikBartbuerste;

  /// No description provided for @technikBartbuersteUnter.
  ///
  /// In de, this message translates to:
  /// **'Richtet die Haare und verteilt das Öl.'**
  String get technikBartbuersteUnter;

  /// No description provided for @technikGuaSha.
  ///
  /// In de, this message translates to:
  /// **'Gua Sha'**
  String get technikGuaSha;

  /// No description provided for @technikGuaShaUnter.
  ///
  /// In de, this message translates to:
  /// **'Stein am Gesicht entlang, immer nach außen.'**
  String get technikGuaShaUnter;

  /// No description provided for @technikGesichtsyoga.
  ///
  /// In de, this message translates to:
  /// **'Gesichtsyoga'**
  String get technikGesichtsyoga;

  /// No description provided for @technikGesichtsyogaUnter.
  ///
  /// In de, this message translates to:
  /// **'Gezielte Übungen für Wangen, Kiefer und Stirn.'**
  String get technikGesichtsyogaUnter;

  /// No description provided for @technikIceRolling.
  ///
  /// In de, this message translates to:
  /// **'Ice Rolling am Morgen'**
  String get technikIceRolling;

  /// No description provided for @technikIceRollingUnter.
  ///
  /// In de, this message translates to:
  /// **'Kälte gegen geschwollene Augen und Müdigkeit.'**
  String get technikIceRollingUnter;

  /// No description provided for @technikLymphmassage.
  ///
  /// In de, this message translates to:
  /// **'Lymph-Gesichtsmassage'**
  String get technikLymphmassage;

  /// No description provided for @technikLymphmassageUnter.
  ///
  /// In de, this message translates to:
  /// **'Sanft ausstreichen, von der Mitte zum Hals.'**
  String get technikLymphmassageUnter;

  /// No description provided for @technikSanftesPeeling.
  ///
  /// In de, this message translates to:
  /// **'Sanftes chemisches Peeling'**
  String get technikSanftesPeeling;

  /// No description provided for @technikSanftesPeelingUnter.
  ///
  /// In de, this message translates to:
  /// **'Milde Säure, langsam eingeschlichen.'**
  String get technikSanftesPeelingUnter;

  /// No description provided for @technikSheetMaske.
  ///
  /// In de, this message translates to:
  /// **'Sheet-Masken-Ritual'**
  String get technikSheetMaske;

  /// No description provided for @technikSheetMaskeUnter.
  ///
  /// In de, this message translates to:
  /// **'Zwanzig Minuten, ein fester Abend die Woche.'**
  String get technikSheetMaskeUnter;

  /// No description provided for @technikLippenpeeling.
  ///
  /// In de, this message translates to:
  /// **'Lippen-Peeling'**
  String get technikLippenpeeling;

  /// No description provided for @technikLippenpeelingUnter.
  ///
  /// In de, this message translates to:
  /// **'Sanft abtragen, danach pflegen.'**
  String get technikLippenpeelingUnter;

  /// No description provided for @technikNagelpflege.
  ///
  /// In de, this message translates to:
  /// **'Nagelpflege-Routine'**
  String get technikNagelpflege;

  /// No description provided for @technikNagelpflegeUnter.
  ///
  /// In de, this message translates to:
  /// **'Feilen, Nagelhaut, Öl – einmal die Woche.'**
  String get technikNagelpflegeUnter;

  /// No description provided for @technikAugenbrauenWimpern.
  ///
  /// In de, this message translates to:
  /// **'Augenbrauen- & Wimpernpflege'**
  String get technikAugenbrauenWimpern;

  /// No description provided for @technikAugenbrauenWimpernUnter.
  ///
  /// In de, this message translates to:
  /// **'Bürsten, Öl, Form halten statt nachziehen.'**
  String get technikAugenbrauenWimpernUnter;

  /// No description provided for @technikPinselhygiene.
  ///
  /// In de, this message translates to:
  /// **'Pinsel sauber halten'**
  String get technikPinselhygiene;

  /// No description provided for @technikPinselhygieneUnter.
  ///
  /// In de, this message translates to:
  /// **'Alle zwei Wochen waschen – die Haut dankt es.'**
  String get technikPinselhygieneUnter;

  /// No description provided for @technikLidschattenbasis.
  ///
  /// In de, this message translates to:
  /// **'Grundierung für die Lider'**
  String get technikLidschattenbasis;

  /// No description provided for @technikLidschattenbasisUnter.
  ///
  /// In de, this message translates to:
  /// **'Hält die Farbe und verhindert Absetzen in der Falte.'**
  String get technikLidschattenbasisUnter;

  /// No description provided for @technikRougePlatzierung.
  ///
  /// In de, this message translates to:
  /// **'Rouge bewusst platzieren'**
  String get technikRougePlatzierung;

  /// No description provided for @technikRougePlatzierungUnter.
  ///
  /// In de, this message translates to:
  /// **'Nach Gesichtsform statt nach Gewohnheit.'**
  String get technikRougePlatzierungUnter;

  /// No description provided for @technikOelziehen.
  ///
  /// In de, this message translates to:
  /// **'Ölziehen'**
  String get technikOelziehen;

  /// No description provided for @technikOelziehenUnter.
  ///
  /// In de, this message translates to:
  /// **'Morgens Öl im Mund bewegen, dann ausspucken.'**
  String get technikOelziehenUnter;

  /// No description provided for @technikZungenschaber.
  ///
  /// In de, this message translates to:
  /// **'Zungenschaber'**
  String get technikZungenschaber;

  /// No description provided for @technikZungenschaberUnter.
  ///
  /// In de, this message translates to:
  /// **'Ein Zug über die Zunge vor dem Putzen.'**
  String get technikZungenschaberUnter;

  /// No description provided for @technikLaechelntraining.
  ///
  /// In de, this message translates to:
  /// **'Lächeln vor dem Spiegel üben'**
  String get technikLaechelntraining;

  /// No description provided for @technikLaechelntrainingUnter.
  ///
  /// In de, this message translates to:
  /// **'Damit es auf Fotos nicht angestrengt wirkt.'**
  String get technikLaechelntrainingUnter;

  /// No description provided for @technikAufhellung.
  ///
  /// In de, this message translates to:
  /// **'Zähne aufhellen'**
  String get technikAufhellung;

  /// No description provided for @technikAufhellungUnter.
  ///
  /// In de, this message translates to:
  /// **'Nur nach Rücksprache mit der Zahnarztpraxis.'**
  String get technikAufhellungUnter;

  /// No description provided for @technikChinTuck.
  ///
  /// In de, this message translates to:
  /// **'Chin Tucks für den Nacken'**
  String get technikChinTuck;

  /// No description provided for @technikChinTuckUnter.
  ///
  /// In de, this message translates to:
  /// **'Kinn zurückziehen, gegen den Handy-Nacken.'**
  String get technikChinTuckUnter;

  /// No description provided for @technikMobilityMinuten.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Mobility-Minuten'**
  String get technikMobilityMinuten;

  /// No description provided for @technikMobilityMinutenUnter.
  ///
  /// In de, this message translates to:
  /// **'Fünf Minuten Beweglichkeit statt eines Programms.'**
  String get technikMobilityMinutenUnter;

  /// No description provided for @technikWandstand.
  ///
  /// In de, this message translates to:
  /// **'Wandstand für die Haltung'**
  String get technikWandstand;

  /// No description provided for @technikWandstandUnter.
  ///
  /// In de, this message translates to:
  /// **'Rücken an die Wand, zwei Minuten lang.'**
  String get technikWandstandUnter;

  /// No description provided for @technikKaltDuschen.
  ///
  /// In de, this message translates to:
  /// **'Kalt abduschen'**
  String get technikKaltDuschen;

  /// No description provided for @technikKaltDuschenUnter.
  ///
  /// In de, this message translates to:
  /// **'Die letzten dreißig Sekunden kalt.'**
  String get technikKaltDuschenUnter;

  /// No description provided for @technikSchlafhygiene.
  ///
  /// In de, this message translates to:
  /// **'Schlafhygiene-Routine'**
  String get technikSchlafhygiene;

  /// No description provided for @technikSchlafhygieneUnter.
  ///
  /// In de, this message translates to:
  /// **'Feste Zeiten, dunkles Zimmer, kein Bildschirm.'**
  String get technikSchlafhygieneUnter;

  /// No description provided for @technikKleiderschrankAudit.
  ///
  /// In de, this message translates to:
  /// **'Kleiderschrank-Audit'**
  String get technikKleiderschrankAudit;

  /// No description provided for @technikKleiderschrankAuditUnter.
  ///
  /// In de, this message translates to:
  /// **'Einmal alles durchgehen und ehrlich sortieren.'**
  String get technikKleiderschrankAuditUnter;

  /// No description provided for @technikCapsuleWardrobe.
  ///
  /// In de, this message translates to:
  /// **'Capsule Wardrobe'**
  String get technikCapsuleWardrobe;

  /// No description provided for @technikCapsuleWardrobeUnter.
  ///
  /// In de, this message translates to:
  /// **'Wenige Teile, die alle zueinander passen.'**
  String get technikCapsuleWardrobeUnter;

  /// No description provided for @technikSchuhpflege.
  ///
  /// In de, this message translates to:
  /// **'Schuhpflege-Ritual'**
  String get technikSchuhpflege;

  /// No description provided for @technikSchuhpflegeUnter.
  ///
  /// In de, this message translates to:
  /// **'Bürsten, pflegen, in Form bringen.'**
  String get technikSchuhpflegeUnter;

  /// No description provided for @technikAccessoireEinstieg.
  ///
  /// In de, this message translates to:
  /// **'Das erste Accessoire'**
  String get technikAccessoireEinstieg;

  /// No description provided for @technikAccessoireEinstiegUnter.
  ///
  /// In de, this message translates to:
  /// **'Ein Ring oder eine Kette, dezent angefangen.'**
  String get technikAccessoireEinstiegUnter;

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
  /// **'Mehrfachauswahl. Dieselben Richtungen wie bei „Deine Richtung“ – hier geht es nur um die Kleidung.'**
  String get stilZielText;

  /// No description provided for @stilZweck.
  ///
  /// In de, this message translates to:
  /// **'Wofür soll dein Style vor allem funktionieren?'**
  String get stilZweck;

  /// No description provided for @stilZweckText.
  ///
  /// In de, this message translates to:
  /// **'Mehrfachauswahl. Du kannst die Frage auch überspringen.'**
  String get stilZweckText;

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

  /// Die Wissens-Bibliothek in den Einstellungen.
  ///
  /// In de, this message translates to:
  /// **'Wissen'**
  String get wissenTitel;

  /// No description provided for @wissenText.
  ///
  /// In de, this message translates to:
  /// **'Kurze Erklärungen zu den Techniken, die in deinem Report und in deinem Plan vorkommen.'**
  String get wissenText;

  /// No description provided for @wissenSuche.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get wissenSuche;

  /// No description provided for @wissenLeer.
  ///
  /// In de, this message translates to:
  /// **'Dazu gibt es keinen Eintrag.'**
  String get wissenLeer;

  /// No description provided for @wissenLaedt.
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get wissenLaedt;

  /// No description provided for @wissenWasIstDas.
  ///
  /// In de, this message translates to:
  /// **'WAS IST DAS'**
  String get wissenWasIstDas;

  /// No description provided for @wissenSoGehts.
  ///
  /// In de, this message translates to:
  /// **'SO GEHT ES'**
  String get wissenSoGehts;

  /// No description provided for @wissenWieOft.
  ///
  /// In de, this message translates to:
  /// **'WIE OFT'**
  String get wissenWieOft;

  /// No description provided for @wissenWomit.
  ///
  /// In de, this message translates to:
  /// **'WOMIT'**
  String get wissenWomit;

  /// No description provided for @wissenWoraufAchten.
  ///
  /// In de, this message translates to:
  /// **'WORAUF ACHTEN'**
  String get wissenWoraufAchten;

  /// Vorlesetext des Info-Zeichens an Aufgaben und Empfehlungen.
  ///
  /// In de, this message translates to:
  /// **'Was ist {name}?'**
  String wissenWasIst(String name);

  /// No description provided for @einstellungenWissen.
  ///
  /// In de, this message translates to:
  /// **'Wissen'**
  String get einstellungenWissen;

  /// No description provided for @ergebnisTitel.
  ///
  /// In de, this message translates to:
  /// **'Deine Analyse'**
  String get ergebnisTitel;

  /// Vorspann der Echo-Zeile im Report, die die eigenen Eingaben zeigt.
  ///
  /// In de, this message translates to:
  /// **'Deine Auswahl'**
  String get ergebnisAuswahl;

  /// Fusszeile einer Bereichs-Kachel in der Report-Uebersicht.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, one{1 Empfehlung} other{{anzahl} Empfehlungen}}'**
  String ergebnisKachelEmpfehlungen(int anzahl);

  /// Ueberschrift des Zitatblocks mit dem Freitext im Zielkapitel.
  ///
  /// In de, this message translates to:
  /// **'Dein Wunsch'**
  String get ergebnisDeinWunsch;

  /// Zeile über dem Report. Datum, Kapitelzahl und Empfehlungszahl stehen bewusst zusammen in einem Satz: Als drei Bausteine im Dart-Code blieben zwei davon deutsch, während die Oberfläche schon englisch war.
  ///
  /// In de, this message translates to:
  /// **'{datum} · {modus} · {kapitel, plural, one{1 Kapitel} other{{kapitel} Kapitel}} · {empfehlungen, plural, one{1 Empfehlung} other{{empfehlungen} Empfehlungen}}'**
  String ergebnisKopf(
    String datum,
    String modus,
    int kapitel,
    int empfehlungen,
  );

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

  /// Kategorie-Pille an einem Produkt. Das Modell liefert nur die Kennung ("reinigung"), das Wort steht hier – sonst bleibt die Kategorie in der Sprache, in der der Report entstanden ist.
  ///
  /// In de, this message translates to:
  /// **'Reinigung'**
  String get produktReinigung;

  /// No description provided for @produktPflege.
  ///
  /// In de, this message translates to:
  /// **'Pflege'**
  String get produktPflege;

  /// No description provided for @produktStyling.
  ///
  /// In de, this message translates to:
  /// **'Styling'**
  String get produktStyling;

  /// No description provided for @produktWerkzeug.
  ///
  /// In de, this message translates to:
  /// **'Werkzeug'**
  String get produktWerkzeug;

  /// No description provided for @produktMakeup.
  ///
  /// In de, this message translates to:
  /// **'Make-up'**
  String get produktMakeup;

  /// No description provided for @produktKleidung.
  ///
  /// In de, this message translates to:
  /// **'Kleidung'**
  String get produktKleidung;

  /// No description provided for @produktSonstiges.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get produktSonstiges;

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

  /// Zeile unter dem Plan. Der Zeitraum steckt mit im Satz, weil er sich in anderen Sprachen nicht als Baustein anhängen lässt.
  ///
  /// In de, this message translates to:
  /// **'{tage, plural, one{Nächster Check-in in einem Tag} other{Nächster Check-in in {tage} Tagen}}'**
  String checkinNaechsterIn(int tage);

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

  /// No description provided for @einstellungenDatenExport.
  ///
  /// In de, this message translates to:
  /// **'Meine Daten herunterladen'**
  String get einstellungenDatenExport;

  /// No description provided for @einstellungenDatenExportLaeuft.
  ///
  /// In de, this message translates to:
  /// **'Deine Datei wird vorbereitet …'**
  String get einstellungenDatenExportLaeuft;

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

  /// Titel der täglichen Erinnerung. Kurz halten – Android kürzt lange Titel in der Leiste ab.
  ///
  /// In de, this message translates to:
  /// **'Dein Tagesziel'**
  String get erinnerungPushTitel;

  /// No description provided for @erinnerungPushText.
  ///
  /// In de, this message translates to:
  /// **'Heute noch nichts abgehakt – ein Haken sichert den Tag.'**
  String get erinnerungPushText;

  /// Name des Benachrichtigungs-Kanals in den Android-Einstellungen. Steht dort in der Sprache, in der er angelegt wurde – Android benennt einen bestehenden Kanal nicht um.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Erinnerung'**
  String get erinnerungKanalName;

  /// No description provided for @erinnerungKanalBeschreibung.
  ///
  /// In de, this message translates to:
  /// **'Erinnert dich abends, wenn du heute noch keine Aufgabe abgehakt hast.'**
  String get erinnerungKanalBeschreibung;

  /// No description provided for @einstellungenErinnerung.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Erinnerung'**
  String get einstellungenErinnerung;

  /// No description provided for @erinnerungAn.
  ///
  /// In de, this message translates to:
  /// **'Erinnere mich'**
  String get erinnerungAn;

  /// No description provided for @erinnerungZeit.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit'**
  String get erinnerungZeit;

  /// No description provided for @erinnerungHinweis.
  ///
  /// In de, this message translates to:
  /// **'Kommt nur, wenn du einen Plan hast und an dem Tag noch nichts abgehakt ist.'**
  String get erinnerungHinweis;

  /// No description provided for @erinnerungOhneBerechtigung.
  ///
  /// In de, this message translates to:
  /// **'Dein Handy lässt für TrueGlow gerade keine Benachrichtigungen zu. Das lässt sich in den Systemeinstellungen ändern.'**
  String get erinnerungOhneBerechtigung;

  /// No description provided for @erinnerungZeitWaehlen.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit wählen'**
  String get erinnerungZeitWaehlen;

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

  /// No description provided for @alter18bis24.
  ///
  /// In de, this message translates to:
  /// **'18–24'**
  String get alter18bis24;

  /// No description provided for @alter25bis34.
  ///
  /// In de, this message translates to:
  /// **'25–34'**
  String get alter25bis34;

  /// No description provided for @alter35bis44.
  ///
  /// In de, this message translates to:
  /// **'35–44'**
  String get alter35bis44;

  /// No description provided for @alterAb45.
  ///
  /// In de, this message translates to:
  /// **'45+'**
  String get alterAb45;

  /// No description provided for @budgetNiedrig.
  ///
  /// In de, this message translates to:
  /// **'Niedrig'**
  String get budgetNiedrig;

  /// No description provided for @budgetNiedrigText.
  ///
  /// In de, this message translates to:
  /// **'Drogerie, unter 30 € im Monat'**
  String get budgetNiedrigText;

  /// No description provided for @budgetMittel.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get budgetMittel;

  /// No description provided for @budgetMittelText.
  ///
  /// In de, this message translates to:
  /// **'30–80 € im Monat'**
  String get budgetMittelText;

  /// No description provided for @budgetHoch.
  ///
  /// In de, this message translates to:
  /// **'Hoch'**
  String get budgetHoch;

  /// No description provided for @budgetHochText.
  ///
  /// In de, this message translates to:
  /// **'über 80 € im Monat'**
  String get budgetHochText;

  /// No description provided for @zeitKurz.
  ///
  /// In de, this message translates to:
  /// **'5 Minuten'**
  String get zeitKurz;

  /// No description provided for @zeitKurzText.
  ///
  /// In de, this message translates to:
  /// **'Nur das Nötigste'**
  String get zeitKurzText;

  /// No description provided for @zeitMittel.
  ///
  /// In de, this message translates to:
  /// **'15 Minuten'**
  String get zeitMittel;

  /// No description provided for @zeitMittelText.
  ///
  /// In de, this message translates to:
  /// **'Solide Routine'**
  String get zeitMittelText;

  /// No description provided for @zeitLang.
  ///
  /// In de, this message translates to:
  /// **'30+ Minuten'**
  String get zeitLang;

  /// No description provided for @zeitLangText.
  ///
  /// In de, this message translates to:
  /// **'Volles Programm'**
  String get zeitLangText;

  /// No description provided for @fokusHaut.
  ///
  /// In de, this message translates to:
  /// **'Haut'**
  String get fokusHaut;

  /// No description provided for @fokusHaare.
  ///
  /// In de, this message translates to:
  /// **'Haare'**
  String get fokusHaare;

  /// No description provided for @fokusBart.
  ///
  /// In de, this message translates to:
  /// **'Bart'**
  String get fokusBart;

  /// No description provided for @fokusStyle.
  ///
  /// In de, this message translates to:
  /// **'Style'**
  String get fokusStyle;

  /// No description provided for @fokusFitness.
  ///
  /// In de, this message translates to:
  /// **'Fitness-Habits'**
  String get fokusFitness;

  /// No description provided for @modulBasisTitel.
  ///
  /// In de, this message translates to:
  /// **'Gesicht, Haare & Bart'**
  String get modulBasisTitel;

  /// No description provided for @modulBasisText.
  ///
  /// In de, this message translates to:
  /// **'Gesichtsform, Frisur- und Bart-Empfehlungen.'**
  String get modulBasisText;

  /// No description provided for @modulBasisCheckliste.
  ///
  /// In de, this message translates to:
  /// **'Haare & Bart'**
  String get modulBasisCheckliste;

  /// No description provided for @modulHautTitel.
  ///
  /// In de, this message translates to:
  /// **'Haut & Farbtyp'**
  String get modulHautTitel;

  /// No description provided for @modulHautText.
  ///
  /// In de, this message translates to:
  /// **'Hautbild, Unterton, Farbpalette für Kleidung.'**
  String get modulHautText;

  /// No description provided for @modulHautCheckliste.
  ///
  /// In de, this message translates to:
  /// **'Haut'**
  String get modulHautCheckliste;

  /// No description provided for @modulZaehneTitel.
  ///
  /// In de, this message translates to:
  /// **'Zähne & Lächeln'**
  String get modulZaehneTitel;

  /// No description provided for @modulZaehneText.
  ///
  /// In de, this message translates to:
  /// **'Zahnfarbe, Zahnstellung, Mimik beim Lächeln.'**
  String get modulZaehneText;

  /// No description provided for @modulZaehneCheckliste.
  ///
  /// In de, this message translates to:
  /// **'Zähne'**
  String get modulZaehneCheckliste;

  /// No description provided for @modulFigurTitel.
  ///
  /// In de, this message translates to:
  /// **'Figur & Passform'**
  String get modulFigurTitel;

  /// No description provided for @modulFigurText.
  ///
  /// In de, this message translates to:
  /// **'Silhouette, Proportionen, Schnitt-Empfehlungen.'**
  String get modulFigurText;

  /// No description provided for @modulFigurCheckliste.
  ///
  /// In de, this message translates to:
  /// **'Haltung & Figur'**
  String get modulFigurCheckliste;

  /// No description provided for @modulStilTitel.
  ///
  /// In de, this message translates to:
  /// **'Stil & Kleiderschrank'**
  String get modulStilTitel;

  /// No description provided for @modulStilText.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Outfits, Stilziel, konkrete Look-Vorschläge.'**
  String get modulStilText;

  /// No description provided for @modulStilCheckliste.
  ///
  /// In de, this message translates to:
  /// **'Stil'**
  String get modulStilCheckliste;

  /// Kapitel im Report und Karte in der Tagesliste, das aus dem Freitext bei „Deine Richtung“ entsteht.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Ziele'**
  String get modulZieleTitel;

  /// No description provided for @modulZieleText.
  ///
  /// In de, this message translates to:
  /// **'Was du dir bei „Deine Richtung“ in eigenen Worten vorgenommen hast.'**
  String get modulZieleText;

  /// No description provided for @modulZieleCheckliste.
  ///
  /// In de, this message translates to:
  /// **'Deine Ziele'**
  String get modulZieleCheckliste;

  /// No description provided for @modulBenoetigtZiele.
  ///
  /// In de, this message translates to:
  /// **'Deine Angaben bei „Deine Richtung“'**
  String get modulBenoetigtZiele;

  /// No description provided for @zweckUniSchule.
  ///
  /// In de, this message translates to:
  /// **'Uni / Schule / Ausbildung'**
  String get zweckUniSchule;

  /// No description provided for @zweckAusgehenDates.
  ///
  /// In de, this message translates to:
  /// **'Ausgehen & Dates'**
  String get zweckAusgehenDates;

  /// No description provided for @zweckArbeitNebenjob.
  ///
  /// In de, this message translates to:
  /// **'Arbeit / Nebenjob'**
  String get zweckArbeitNebenjob;

  /// No description provided for @zweckGymSport.
  ///
  /// In de, this message translates to:
  /// **'Gym & Sport'**
  String get zweckGymSport;

  /// No description provided for @kleidungsbudgetKlein.
  ///
  /// In de, this message translates to:
  /// **'Bis 50 € pro Teil'**
  String get kleidungsbudgetKlein;

  /// No description provided for @kleidungsbudgetMittel.
  ///
  /// In de, this message translates to:
  /// **'50–150 € pro Teil'**
  String get kleidungsbudgetMittel;

  /// No description provided for @kleidungsbudgetGross.
  ///
  /// In de, this message translates to:
  /// **'Über 150 € pro Teil'**
  String get kleidungsbudgetGross;

  /// No description provided for @pflegeaufwandMinimal.
  ///
  /// In de, this message translates to:
  /// **'So wenig wie möglich'**
  String get pflegeaufwandMinimal;

  /// No description provided for @pflegeaufwandMittel.
  ///
  /// In de, this message translates to:
  /// **'Etwas Aufwand ist okay'**
  String get pflegeaufwandMittel;

  /// No description provided for @pflegeaufwandHoch.
  ///
  /// In de, this message translates to:
  /// **'Ich investiere gern Zeit'**
  String get pflegeaufwandHoch;

  /// No description provided for @fotoproblemKeinGesichtTitel.
  ///
  /// In de, this message translates to:
  /// **'Kein Gesicht erkannt'**
  String get fotoproblemKeinGesichtTitel;

  /// No description provided for @fotoproblemKeinGesichtTipp.
  ///
  /// In de, this message translates to:
  /// **'Halte die Kamera so, dass dein Gesicht vollständig im Bild ist – ohne Sonnenbrille, Mütze oder Maske.'**
  String get fotoproblemKeinGesichtTipp;

  /// No description provided for @fotoproblemMehrereTitel.
  ///
  /// In de, this message translates to:
  /// **'Mehrere Gesichter im Bild'**
  String get fotoproblemMehrereTitel;

  /// No description provided for @fotoproblemMehrereTipp.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Foto darf nur dein Gesicht zu sehen sein. Such dir einen ruhigen Hintergrund ohne andere Personen.'**
  String get fotoproblemMehrereTipp;

  /// No description provided for @fotoproblemZuKleinTitel.
  ///
  /// In de, this message translates to:
  /// **'Gesicht zu klein im Bild'**
  String get fotoproblemZuKleinTitel;

  /// No description provided for @fotoproblemZuKleinTipp.
  ///
  /// In de, this message translates to:
  /// **'Geh näher an die Kamera oder halte das Handy näher an dein Gesicht, bis der Kopf den Großteil des Bildes ausfüllt.'**
  String get fotoproblemZuKleinTipp;

  /// No description provided for @fotoproblemZuDunkelTitel.
  ///
  /// In de, this message translates to:
  /// **'Foto zu dunkel'**
  String get fotoproblemZuDunkelTitel;

  /// No description provided for @fotoproblemZuDunkelTipp.
  ///
  /// In de, this message translates to:
  /// **'Stell dich an ein Fenster oder mach mehr Licht an. Gleichmäßiges Licht von vorne funktioniert am besten.'**
  String get fotoproblemZuDunkelTipp;

  /// No description provided for @fotoproblemUngueltigTitel.
  ///
  /// In de, this message translates to:
  /// **'Bild konnte nicht gelesen werden'**
  String get fotoproblemUngueltigTitel;

  /// No description provided for @fotoproblemUngueltigTipp.
  ///
  /// In de, this message translates to:
  /// **'Versuch es mit einem anderen Foto oder nimm ein neues auf.'**
  String get fotoproblemUngueltigTipp;

  /// No description provided for @fotoproblemFehlerTitel.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen'**
  String get fotoproblemFehlerTitel;

  /// No description provided for @fotoproblemFehlerTipp.
  ///
  /// In de, this message translates to:
  /// **'Bitte versuch es noch einmal.'**
  String get fotoproblemFehlerTipp;

  /// No description provided for @authAbgebrochenTitel.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung abgebrochen'**
  String get authAbgebrochenTitel;

  /// No description provided for @authAbgebrochenTipp.
  ///
  /// In de, this message translates to:
  /// **'Kein Problem – du kannst es jederzeit noch einmal versuchen.'**
  String get authAbgebrochenTipp;

  /// No description provided for @authKeinInternetTitel.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get authKeinInternetTitel;

  /// No description provided for @authKeinInternetTipp.
  ///
  /// In de, this message translates to:
  /// **'Prüf deine Internetverbindung und versuch es noch einmal.'**
  String get authKeinInternetTipp;

  /// No description provided for @authKontoVergebenTitel.
  ///
  /// In de, this message translates to:
  /// **'Konto schon in Benutzung'**
  String get authKontoVergebenTitel;

  /// No description provided for @authKontoVergebenTipp.
  ///
  /// In de, this message translates to:
  /// **'Dieses Google-Konto gehört bereits zu einem TrueGlow-Zugang. Wir haben dich damit angemeldet.'**
  String get authKontoVergebenTipp;

  /// No description provided for @authNichtVerfuegbarTitel.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung nicht möglich'**
  String get authNichtVerfuegbarTitel;

  /// No description provided for @authNichtVerfuegbarTipp.
  ///
  /// In de, this message translates to:
  /// **'Diese Anmeldeart steht auf deinem Gerät nicht zur Verfügung.'**
  String get authNichtVerfuegbarTipp;

  /// No description provided for @authUnbekanntTitel.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung fehlgeschlagen'**
  String get authUnbekanntTitel;

  /// No description provided for @authUnbekanntTipp.
  ///
  /// In de, this message translates to:
  /// **'Da ist etwas schiefgelaufen. Versuch es bitte noch einmal.'**
  String get authUnbekanntTipp;

  /// No description provided for @anbieterGoogle.
  ///
  /// In de, this message translates to:
  /// **'Google'**
  String get anbieterGoogle;

  /// No description provided for @anbieterApple.
  ///
  /// In de, this message translates to:
  /// **'Apple'**
  String get anbieterApple;

  /// No description provided for @anbieterAnonym.
  ///
  /// In de, this message translates to:
  /// **'Ohne Konto'**
  String get anbieterAnonym;

  /// No description provided for @nutzerOhneKonto.
  ///
  /// In de, this message translates to:
  /// **'Ohne Konto angemeldet'**
  String get nutzerOhneKonto;

  /// No description provided for @nutzerAngemeldet.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet'**
  String get nutzerAngemeldet;

  /// No description provided for @kontoNeuAnmeldenTitel.
  ///
  /// In de, this message translates to:
  /// **'Bitte kurz neu anmelden'**
  String get kontoNeuAnmeldenTitel;

  /// No description provided for @kontoNeuAnmeldenTipp.
  ///
  /// In de, this message translates to:
  /// **'Eine Kontolöschung lässt sich nicht rückgängig machen. Deshalb fragen wir vorher noch einmal nach deiner Anmeldung.'**
  String get kontoNeuAnmeldenTipp;

  /// No description provided for @kontoKeinInternetTitel.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get kontoKeinInternetTitel;

  /// No description provided for @kontoKeinInternetTipp.
  ///
  /// In de, this message translates to:
  /// **'Zum Löschen brauchen wir kurz Internet – sonst bliebe dein Konto in der Cloud stehen. Versuch es noch einmal, sobald du online bist.'**
  String get kontoKeinInternetTipp;

  /// No description provided for @kontoFehlgeschlagenTitel.
  ///
  /// In de, this message translates to:
  /// **'Löschen nicht möglich'**
  String get kontoFehlgeschlagenTitel;

  /// No description provided for @kontoFehlgeschlagenTipp.
  ///
  /// In de, this message translates to:
  /// **'Da ist etwas schiefgelaufen. Deine Daten sind unverändert – bitte versuch es später noch einmal.'**
  String get kontoFehlgeschlagenTipp;

  /// No description provided for @analyseKeinInternetTitel.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get analyseKeinInternetTitel;

  /// No description provided for @analyseKeinInternetTipp.
  ///
  /// In de, this message translates to:
  /// **'Prüf deine Internetverbindung und versuch es noch einmal.'**
  String get analyseKeinInternetTipp;

  /// No description provided for @analyseZeitTitel.
  ///
  /// In de, this message translates to:
  /// **'Zeitüberschreitung'**
  String get analyseZeitTitel;

  /// No description provided for @analyseZeitTipp.
  ///
  /// In de, this message translates to:
  /// **'Die Analyse hat zu lange gedauert. Versuch es bitte erneut.'**
  String get analyseZeitTipp;

  /// App Check hat den Aufruf abgelehnt – die Installation, nicht das Konto.
  ///
  /// In de, this message translates to:
  /// **'Diese Installation ist nicht freigegeben'**
  String get analyseZugangTitel;

  /// Sagt ausdruecklich, dass Warten nicht hilft.
  ///
  /// In de, this message translates to:
  /// **'Der Server hat nicht dein Konto abgelehnt, sondern diese Installation der App. Warten hilft hier nicht. Beende die App und starte sie neu — bleibt es dabei, muss die Installation freigeschaltet werden (SETUP.md, Abschnitt 4.3).'**
  String get analyseZugangTipp;

  /// No description provided for @analyseApiTitel.
  ///
  /// In de, this message translates to:
  /// **'Analyse nicht möglich'**
  String get analyseApiTitel;

  /// No description provided for @analyseApiTipp.
  ///
  /// In de, this message translates to:
  /// **'Der Analyse-Dienst antwortet gerade nicht. Bitte später noch einmal versuchen.'**
  String get analyseApiTipp;

  /// No description provided for @analyseKontingentTitel.
  ///
  /// In de, this message translates to:
  /// **'Kontingent erschöpft'**
  String get analyseKontingentTitel;

  /// No description provided for @analyseKontingentTipp.
  ///
  /// In de, this message translates to:
  /// **'Das Limit des Analyse-Dienstes ist erreicht. Versuch es später noch einmal.'**
  String get analyseKontingentTipp;

  /// No description provided for @analyseAntwortTitel.
  ///
  /// In de, this message translates to:
  /// **'Antwort nicht lesbar'**
  String get analyseAntwortTitel;

  /// No description provided for @analyseAntwortTipp.
  ///
  /// In de, this message translates to:
  /// **'Die Analyse kam unvollständig zurück. Ein erneuter Versuch hilft meistens.'**
  String get analyseAntwortTipp;

  /// No description provided for @analyseKeinSchluesselTitel.
  ///
  /// In de, this message translates to:
  /// **'Analyse-Dienst nicht eingerichtet'**
  String get analyseKeinSchluesselTitel;

  /// No description provided for @analyseKeinSchluesselTipp.
  ///
  /// In de, this message translates to:
  /// **'Der Dienst ist gerade nicht einsatzbereit. Wir kümmern uns darum – versuch es später noch einmal.'**
  String get analyseKeinSchluesselTipp;

  /// No description provided for @analyseFotosFehlenTitel.
  ///
  /// In de, this message translates to:
  /// **'Fotos fehlen'**
  String get analyseFotosFehlenTitel;

  /// No description provided for @analyseFotosFehlenTipp.
  ///
  /// In de, this message translates to:
  /// **'Für diese Auswahl fehlen noch Aufnahmen. Geh zurück und hol sie nach.'**
  String get analyseFotosFehlenTipp;

  /// No description provided for @analyseEinwilligungTitel.
  ///
  /// In de, this message translates to:
  /// **'Einwilligung fehlt'**
  String get analyseEinwilligungTitel;

  /// No description provided for @analyseEinwilligungTipp.
  ///
  /// In de, this message translates to:
  /// **'Für eine Analyse brauchen wir deine Einwilligung, deine Fotos an den KI-Dienst zu senden. Du kannst sie in den Einstellungen erteilen.'**
  String get analyseEinwilligungTipp;

  /// No description provided for @einwilligungNutzung.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen und Datenschutz'**
  String get einwilligungNutzung;

  /// No description provided for @einwilligungMindestalter.
  ///
  /// In de, this message translates to:
  /// **'Ich bin mindestens 18 Jahre alt'**
  String get einwilligungMindestalter;

  /// No description provided for @einwilligungFotoKi.
  ///
  /// In de, this message translates to:
  /// **'Analyse meiner Fotos durch den KI-Dienst'**
  String get einwilligungFotoKi;

  /// No description provided for @einwilligungDiagnose.
  ///
  /// In de, this message translates to:
  /// **'Absturzberichte und Nutzungsstatistik'**
  String get einwilligungDiagnose;

  /// No description provided for @dokumentDatenschutzTitel.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get dokumentDatenschutzTitel;

  /// No description provided for @dokumentDatenschutzText.
  ///
  /// In de, this message translates to:
  /// **'Welche Daten wir verarbeiten, wozu und wie lange.'**
  String get dokumentDatenschutzText;

  /// No description provided for @dokumentAgbTitel.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get dokumentAgbTitel;

  /// No description provided for @dokumentAgbText.
  ///
  /// In de, this message translates to:
  /// **'Die Regeln für die Nutzung von TrueGlow.'**
  String get dokumentAgbText;

  /// No description provided for @dokumentImpressumTitel.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get dokumentImpressumTitel;

  /// No description provided for @dokumentImpressumText.
  ///
  /// In de, this message translates to:
  /// **'Wer hinter der App steht und wie du uns erreichst.'**
  String get dokumentImpressumText;

  /// Ueberschrift der Abzeichen-Reihe auf der Startseite.
  ///
  /// In de, this message translates to:
  /// **'Deine Abzeichen'**
  String get abzeichenSektionTitel;

  /// No description provided for @abzeichenErsteAnalyseTitel.
  ///
  /// In de, this message translates to:
  /// **'Erste Analyse geschafft'**
  String get abzeichenErsteAnalyseTitel;

  /// No description provided for @abzeichenErsteAnalyseText.
  ///
  /// In de, this message translates to:
  /// **'Du hast deine erste Analyse abgeschlossen.'**
  String get abzeichenErsteAnalyseText;

  /// No description provided for @abzeichenDreiTitel.
  ///
  /// In de, this message translates to:
  /// **'Dranbleiben angefangen'**
  String get abzeichenDreiTitel;

  /// No description provided for @abzeichenDreiText.
  ///
  /// In de, this message translates to:
  /// **'Drei Tage am Stück etwas abgehakt.'**
  String get abzeichenDreiText;

  /// No description provided for @abzeichenSiebenTitel.
  ///
  /// In de, this message translates to:
  /// **'Erste Woche durchgezogen'**
  String get abzeichenSiebenTitel;

  /// No description provided for @abzeichenSiebenText.
  ///
  /// In de, this message translates to:
  /// **'Sieben Tage am Stück – die erste Woche steht.'**
  String get abzeichenSiebenText;

  /// No description provided for @abzeichenVierzehnTitel.
  ///
  /// In de, this message translates to:
  /// **'Zwei Wochen stark'**
  String get abzeichenVierzehnTitel;

  /// No description provided for @abzeichenVierzehnText.
  ///
  /// In de, this message translates to:
  /// **'Vierzehn Tage am Stück. Das ist schon Routine.'**
  String get abzeichenVierzehnText;

  /// No description provided for @abzeichenDreissigTitel.
  ///
  /// In de, this message translates to:
  /// **'Ein Monat dran'**
  String get abzeichenDreissigTitel;

  /// No description provided for @abzeichenDreissigText.
  ///
  /// In de, this message translates to:
  /// **'Dreißig Tage am Stück. Beeindruckend.'**
  String get abzeichenDreissigText;

  /// No description provided for @abzeichenSechzigTitel.
  ///
  /// In de, this message translates to:
  /// **'Zwei Monate durchgehalten'**
  String get abzeichenSechzigTitel;

  /// No description provided for @abzeichenSechzigText.
  ///
  /// In de, this message translates to:
  /// **'Sechzig Tage am Stück – das schaffen wenige.'**
  String get abzeichenSechzigText;

  /// No description provided for @abzeichenNeunzigTitel.
  ///
  /// In de, this message translates to:
  /// **'Ein Vierteljahr Disziplin'**
  String get abzeichenNeunzigTitel;

  /// No description provided for @abzeichenNeunzigText.
  ///
  /// In de, this message translates to:
  /// **'Neunzig Tage am Stück. Das ist jetzt dein Alltag.'**
  String get abzeichenNeunzigText;

  /// No description provided for @abzeichenAlleModuleTitel.
  ///
  /// In de, this message translates to:
  /// **'Alles freigeschaltet'**
  String get abzeichenAlleModuleTitel;

  /// No description provided for @abzeichenAlleModuleText.
  ///
  /// In de, this message translates to:
  /// **'Deine Analyse deckt alle Module ab.'**
  String get abzeichenAlleModuleText;

  /// Text im Jubel-Overlay, wenn ein Streak-Abzeichen faellt.
  ///
  /// In de, this message translates to:
  /// **'{tage} Tage durchgezogen!'**
  String abzeichenJubelTage(int tage);

  /// No description provided for @erscheinungHell.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get erscheinungHell;

  /// No description provided for @erscheinungDunkel.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get erscheinungDunkel;

  /// No description provided for @erscheinungSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get erscheinungSystem;

  /// No description provided for @aufnahmeBasisFrontalLabel.
  ///
  /// In de, this message translates to:
  /// **'Frontalfoto'**
  String get aufnahmeBasisFrontalLabel;

  /// No description provided for @aufnahmeBasisFrontalHinweis.
  ///
  /// In de, this message translates to:
  /// **'Schau direkt in die Kamera. Neutrales Gesicht, gutes Licht, keine Kopfbedeckung.'**
  String get aufnahmeBasisFrontalHinweis;

  /// No description provided for @aufnahmeProfilLinksLabel.
  ///
  /// In de, this message translates to:
  /// **'Profil links'**
  String get aufnahmeProfilLinksLabel;

  /// No description provided for @aufnahmeProfilLinksHinweis.
  ///
  /// In de, this message translates to:
  /// **'Dreh deinen Kopf nach rechts – deine linke Gesichtshälfte zeigt zur Kamera. Ohr und Kinnlinie sollten sichtbar sein.'**
  String get aufnahmeProfilLinksHinweis;

  /// No description provided for @aufnahmeProfilRechtsLabel.
  ///
  /// In de, this message translates to:
  /// **'Profil rechts'**
  String get aufnahmeProfilRechtsLabel;

  /// No description provided for @aufnahmeProfilRechtsHinweis.
  ///
  /// In de, this message translates to:
  /// **'Dreh deinen Kopf nach links – deine rechte Gesichtshälfte zeigt zur Kamera. Ohr und Kinnlinie sollten sichtbar sein.'**
  String get aufnahmeProfilRechtsHinweis;

  /// No description provided for @aufnahmeWinkelLabel.
  ///
  /// In de, this message translates to:
  /// **'45°-Winkel'**
  String get aufnahmeWinkelLabel;

  /// No description provided for @aufnahmeWinkelHinweis.
  ///
  /// In de, this message translates to:
  /// **'Dreh deinen Kopf nur halb nach rechts – etwa 45 Grad. Beide Augen bleiben dabei sichtbar.'**
  String get aufnahmeWinkelHinweis;

  /// No description provided for @aufnahmeLaechelnLabel.
  ///
  /// In de, this message translates to:
  /// **'Lächeln'**
  String get aufnahmeLaechelnLabel;

  /// No description provided for @aufnahmeLaechelnHinweis.
  ///
  /// In de, this message translates to:
  /// **'Frontal in die Kamera lächeln, sodass die Zähne gut sichtbar sind.'**
  String get aufnahmeLaechelnHinweis;

  /// No description provided for @aufnahmeGanzkoerperFrontalLabel.
  ///
  /// In de, this message translates to:
  /// **'Ganzkörper frontal'**
  String get aufnahmeGanzkoerperFrontalLabel;

  /// No description provided for @aufnahmeGanzkoerperFrontalHinweis.
  ///
  /// In de, this message translates to:
  /// **'Vom Kopf bis mindestens zu den Oberschenkeln im Bild, gerade stehen, Arme locker seitlich. Füße sind kein Muss. Eng anliegende Kleidung zeigt die Silhouette am besten.'**
  String get aufnahmeGanzkoerperFrontalHinweis;

  /// No description provided for @aufnahmeGanzkoerperSeitlichLabel.
  ///
  /// In de, this message translates to:
  /// **'Ganzkörper seitlich'**
  String get aufnahmeGanzkoerperSeitlichLabel;

  /// No description provided for @aufnahmeGanzkoerperSeitlichHinweis.
  ///
  /// In de, this message translates to:
  /// **'Dieselbe Haltung um 90 Grad gedreht – so sieht man Haltung und Proportionen von der Seite.'**
  String get aufnahmeGanzkoerperSeitlichHinweis;

  /// No description provided for @aufnahmeOutfitEinsLabel.
  ///
  /// In de, this message translates to:
  /// **'Outfit 1'**
  String get aufnahmeOutfitEinsLabel;

  /// No description provided for @aufnahmeOutfitEinsHinweis.
  ///
  /// In de, this message translates to:
  /// **'Ein Outfit, das du oft trägst – am Körper oder ausgelegt.'**
  String get aufnahmeOutfitEinsHinweis;

  /// No description provided for @aufnahmeOutfitZweiLabel.
  ///
  /// In de, this message translates to:
  /// **'Outfit 2'**
  String get aufnahmeOutfitZweiLabel;

  /// No description provided for @aufnahmeOutfitZweiHinweis.
  ///
  /// In de, this message translates to:
  /// **'Ein zweites Outfit, gern aus einem anderen Anlass.'**
  String get aufnahmeOutfitZweiHinweis;

  /// No description provided for @aufnahmeOutfitDreiLabel.
  ///
  /// In de, this message translates to:
  /// **'Outfit 3'**
  String get aufnahmeOutfitDreiLabel;

  /// No description provided for @aufnahmeOutfitDreiHinweis.
  ///
  /// In de, this message translates to:
  /// **'Optional: ein drittes Outfit. Du kannst diesen Schritt auch überspringen.'**
  String get aufnahmeOutfitDreiHinweis;

  /// No description provided for @aufnahmeHautLichtZusatz.
  ///
  /// In de, this message translates to:
  /// **'Dieses Foto wertet auch die Hautanalyse aus. Das Tageslicht aus der Checkliste zählt hier deshalb doppelt.'**
  String get aufnahmeHautLichtZusatz;

  /// No description provided for @modulBenoetigtBasis.
  ///
  /// In de, this message translates to:
  /// **'Frontal, beide Seitenprofile und 45°-Winkel.'**
  String get modulBenoetigtBasis;

  /// No description provided for @modulBenoetigtHaut.
  ///
  /// In de, this message translates to:
  /// **'Keine eigene Aufnahme – nutzt das Frontalfoto der Basis. Mach es bei indirektem Tageslicht.'**
  String get modulBenoetigtHaut;

  /// No description provided for @modulBenoetigtZaehne.
  ///
  /// In de, this message translates to:
  /// **'1 Foto lächelnd.'**
  String get modulBenoetigtZaehne;

  /// No description provided for @modulBenoetigtFigur.
  ///
  /// In de, this message translates to:
  /// **'2 Ganzkörperfotos (frontal + seitlich) sowie Körpergröße und Gewicht.'**
  String get modulBenoetigtFigur;

  /// No description provided for @modulBenoetigtStil.
  ///
  /// In de, this message translates to:
  /// **'2–3 Outfit-Fotos und ein paar kurze Fragen.'**
  String get modulBenoetigtStil;

  /// No description provided for @checkinTypAlltagTitel.
  ///
  /// In de, this message translates to:
  /// **'Alltags-Check'**
  String get checkinTypAlltagTitel;

  /// No description provided for @checkinTypAlltagIntro.
  ///
  /// In de, this message translates to:
  /// **'Eine Woche geschafft! Uns interessiert nur eins: Wie gut passen die Aufgaben in deinen Alltag?'**
  String get checkinTypAlltagIntro;

  /// No description provided for @checkinTypZwischenTitel.
  ///
  /// In de, this message translates to:
  /// **'Zwischencheck'**
  String get checkinTypZwischenTitel;

  /// No description provided for @checkinTypZwischenIntro.
  ///
  /// In de, this message translates to:
  /// **'Zwei Wochen dabei. Wir schauen kurz auf die Aufgaben, die zuletzt gehakt haben – und wie sich die ersten Tage anfühlen.'**
  String get checkinTypZwischenIntro;

  /// No description provided for @checkinTypWirkungTitel.
  ///
  /// In de, this message translates to:
  /// **'Wirkungs-Check'**
  String get checkinTypWirkungTitel;

  /// No description provided for @checkinTypWirkungIntro.
  ///
  /// In de, this message translates to:
  /// **'Ein Monat ist um. Jetzt lohnt der Blick darauf, was sich getan hat – und was wir nachschärfen.'**
  String get checkinTypWirkungIntro;

  /// No description provided for @bewertungLaeuftGut.
  ///
  /// In de, this message translates to:
  /// **'Läuft gut'**
  String get bewertungLaeuftGut;

  /// No description provided for @bewertungGehtSo.
  ///
  /// In de, this message translates to:
  /// **'Geht so'**
  String get bewertungGehtSo;

  /// No description provided for @bewertungPasstNicht.
  ///
  /// In de, this message translates to:
  /// **'Passt nicht'**
  String get bewertungPasstNicht;

  /// No description provided for @grundZeit.
  ///
  /// In de, this message translates to:
  /// **'Zu zeitaufwendig'**
  String get grundZeit;

  /// No description provided for @grundVergessen.
  ///
  /// In de, this message translates to:
  /// **'Vergesse ich'**
  String get grundVergessen;

  /// No description provided for @grundUnangenehm.
  ///
  /// In de, this message translates to:
  /// **'Unangenehm / mag ich nicht'**
  String get grundUnangenehm;

  /// No description provided for @grundTeuer.
  ///
  /// In de, this message translates to:
  /// **'Zu teuer'**
  String get grundTeuer;

  /// No description provided for @grundAnderer.
  ///
  /// In de, this message translates to:
  /// **'Anderer Grund'**
  String get grundAnderer;

  /// No description provided for @frageRoutine.
  ///
  /// In de, this message translates to:
  /// **'Wie gut läuft deine Morgenroutine?'**
  String get frageRoutine;

  /// No description provided for @frageHautGefuehl.
  ///
  /// In de, this message translates to:
  /// **'Wie fühlt sich deine Haut an?'**
  String get frageHautGefuehl;

  /// No description provided for @frageZaehneGefuehl.
  ///
  /// In de, this message translates to:
  /// **'Wie sauber fühlen sich deine Zähne an?'**
  String get frageZaehneGefuehl;

  /// No description provided for @frageHaltungGefuehl.
  ///
  /// In de, this message translates to:
  /// **'Wie bewusst nimmst du deine Haltung wahr?'**
  String get frageHaltungGefuehl;

  /// No description provided for @frageAnziehen.
  ///
  /// In de, this message translates to:
  /// **'Wie leicht fällt dir das Anziehen morgens?'**
  String get frageAnziehen;

  /// No description provided for @frageBasisErgebnis.
  ///
  /// In de, this message translates to:
  /// **'Wie haben sich Frisur und Bart entwickelt?'**
  String get frageBasisErgebnis;

  /// No description provided for @frageHautErgebnis.
  ///
  /// In de, this message translates to:
  /// **'Wie hat sich dein Hautbild entwickelt?'**
  String get frageHautErgebnis;

  /// No description provided for @frageZaehneErgebnis.
  ///
  /// In de, this message translates to:
  /// **'Wie haben sich Zähne und Lächeln entwickelt?'**
  String get frageZaehneErgebnis;

  /// No description provided for @frageHaltungErgebnis.
  ///
  /// In de, this message translates to:
  /// **'Wie hat sich deine Haltung entwickelt?'**
  String get frageHaltungErgebnis;

  /// No description provided for @frageStilErgebnis.
  ///
  /// In de, this message translates to:
  /// **'Wie gut funktionieren deine Outfits inzwischen?'**
  String get frageStilErgebnis;

  /// No description provided for @einordnungHaut.
  ///
  /// In de, this message translates to:
  /// **'Sichtbare Hautveränderungen zeigen sich meist ab Woche 4–6 – du bist auf Kurs.'**
  String get einordnungHaut;

  /// No description provided for @einordnungZaehne.
  ///
  /// In de, this message translates to:
  /// **'Verfärbungen gehen langsam zurück: Der Unterschied wird meist ab Woche 4 sichtbar – du bist auf Kurs.'**
  String get einordnungZaehne;

  /// No description provided for @einordnungHaltung.
  ///
  /// In de, this message translates to:
  /// **'Haltung ändert sich über Wochen, nicht über Tage – ab Woche 4 bis 6 fällt es auch anderen auf. Du bist auf Kurs.'**
  String get einordnungHaltung;

  /// No description provided for @einordnungStil.
  ///
  /// In de, this message translates to:
  /// **'Ein Kleiderschrank verändert sich Stück für Stück – nach vier bis sechs Wochen greift die neue Kombination von selbst.'**
  String get einordnungStil;

  /// No description provided for @einordnungBasis.
  ///
  /// In de, this message translates to:
  /// **'Haare wachsen rund einen Zentimeter im Monat – die neue Form zeigt sich ab Woche 4. Du bist auf Kurs.'**
  String get einordnungBasis;

  /// Untertitel eines Rechtsdokuments, dessen Text noch nicht hinterlegt ist.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht verfügbar'**
  String get dokumentFolgt;

  /// Zeile im Fussbereich, wenn der Text des Dokuments noch fehlt.
  ///
  /// In de, this message translates to:
  /// **'{titel} (folgt)'**
  String dokumentTitelFolgt(String titel);

  /// Beschriftung der Anmelde-Schaltflaeche, z. B. „Mit Google anmelden".
  ///
  /// In de, this message translates to:
  /// **'Mit {anbieter} anmelden'**
  String loginMitAnbieter(String anbieter);

  /// No description provided for @offlineBand.
  ///
  /// In de, this message translates to:
  /// **'Offline – Plan und Checkliste laufen weiter, Änderungen werden nachgetragen.'**
  String get offlineBand;

  /// Ausweichseite des Routers. Erscheint nur bei einem Programmierfehler.
  ///
  /// In de, this message translates to:
  /// **'Route nicht gefunden: {pfad}'**
  String routeNichtGefunden(String pfad);

  /// No description provided for @ladeGesichtsform.
  ///
  /// In de, this message translates to:
  /// **'Analysiere Gesichtsform...'**
  String get ladeGesichtsform;

  /// No description provided for @ladeHautbild.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Hautbild...'**
  String get ladeHautbild;

  /// No description provided for @ladeFrisur.
  ///
  /// In de, this message translates to:
  /// **'Vergleiche Frisur-Optionen...'**
  String get ladeFrisur;

  /// No description provided for @ladeEmpfehlungen.
  ///
  /// In de, this message translates to:
  /// **'Stelle Empfehlungen zusammen...'**
  String get ladeEmpfehlungen;

  /// No description provided for @ladePlan.
  ///
  /// In de, this message translates to:
  /// **'Erstelle deinen Plan...'**
  String get ladePlan;

  /// No description provided for @unterbrochenTitel.
  ///
  /// In de, this message translates to:
  /// **'Analyse unterbrochen'**
  String get unterbrochenTitel;

  /// No description provided for @unterbrochenText.
  ///
  /// In de, this message translates to:
  /// **'Deine letzte Analyse wurde nicht fertig — die App war zwischendurch geschlossen. Es wurde nichts gespeichert. Deine Fotos sind noch da, du kannst direkt neu starten.'**
  String get unterbrochenText;

  /// No description provided for @loginWarumKonto.
  ///
  /// In de, this message translates to:
  /// **'Damit Plan, Streak und Verlauf einen Gerätewechsel überleben, gehört alles zu einem Konto.'**
  String get loginWarumKonto;

  /// No description provided for @loginGast.
  ///
  /// In de, this message translates to:
  /// **'Erst mal umschauen'**
  String get loginGast;

  /// No description provided for @loginGastErklaerung.
  ///
  /// In de, this message translates to:
  /// **'Beim Umschauen legen wir ein Konto ohne Namen und ohne E-Mail an. Meldest du dich später mit Google an, nehmen wir deine Daten mit.'**
  String get loginGastErklaerung;

  /// No description provided for @loginFotosBleiben.
  ///
  /// In de, this message translates to:
  /// **'Deine Fotos bleiben auf dem Gerät.'**
  String get loginFotosBleiben;

  /// No description provided for @fotoWirdGeprueft.
  ///
  /// In de, this message translates to:
  /// **'Foto wird geprüft...'**
  String get fotoWirdGeprueft;

  /// No description provided for @flowNichtsAufzunehmen.
  ///
  /// In de, this message translates to:
  /// **'Für diese Auswahl gibt es nichts aufzunehmen.'**
  String get flowNichtsAufzunehmen;

  /// Fortschritt in der Kopfzeile des Aufnahme-Flows.
  ///
  /// In de, this message translates to:
  /// **'Schritt {nummer} von {gesamt}'**
  String flowSchritt(int nummer, int gesamt);

  /// No description provided for @figurBleibtLokalTitel.
  ///
  /// In de, this message translates to:
  /// **'Bleibt auf dem Gerät'**
  String get figurBleibtLokalTitel;

  /// No description provided for @figurBleibtLokalText.
  ///
  /// In de, this message translates to:
  /// **'Größe und Gewicht werden nur für die Passform-Empfehlung mitgeschickt und nicht dauerhaft beim Analyse-Dienst gespeichert.'**
  String get figurBleibtLokalText;

  /// No description provided for @fotoOptional.
  ///
  /// In de, this message translates to:
  /// **'Optional – du kannst diesen Schritt überspringen.'**
  String get fotoOptional;

  /// No description provided for @fotoSoKlapptEs.
  ///
  /// In de, this message translates to:
  /// **'So klappt das Foto'**
  String get fotoSoKlapptEs;

  /// No description provided for @fotoAutoTitel.
  ///
  /// In de, this message translates to:
  /// **'Die App löst selbst aus'**
  String get fotoAutoTitel;

  /// No description provided for @fotoGeprueft.
  ///
  /// In de, this message translates to:
  /// **'Geprüft'**
  String get fotoGeprueft;

  /// No description provided for @hinweisSchliessen.
  ///
  /// In de, this message translates to:
  /// **'Hinweis schließen'**
  String get hinweisSchliessen;

  /// No description provided for @modulHautKeinFotoTitel.
  ///
  /// In de, this message translates to:
  /// **'Kein eigenes Foto nötig'**
  String get modulHautKeinFotoTitel;

  /// No description provided for @modulHautKeinFotoText.
  ///
  /// In de, this message translates to:
  /// **'Unterton und Farbpalette lesen wir aus deinem Frontalfoto der Basis mit. Eine zusätzliche Nahaufnahme brauchst du nicht.'**
  String get modulHautKeinFotoText;

  /// No description provided for @modulHautLichtTitel.
  ///
  /// In de, this message translates to:
  /// **'Licht zählt hier doppelt'**
  String get modulHautLichtTitel;

  /// No description provided for @modulHautLichtText.
  ///
  /// In de, this message translates to:
  /// **'War dein Frontalfoto zu dunkel oder farbstichig, geh einen Schritt zurück und nimm es bei indirektem Tageslicht neu auf – warmes Kunstlicht verfälscht den Unterton.'**
  String get modulHautLichtText;

  /// Titel des Aufnahme-Flows, wenn es nichts aufzunehmen gibt.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme'**
  String get aufnahmeTitel;

  /// No description provided for @richtungBleibtLokal.
  ///
  /// In de, this message translates to:
  /// **'Bleibt auf dem Gerät'**
  String get richtungBleibtLokal;

  /// No description provided for @checkinKeiner.
  ///
  /// In de, this message translates to:
  /// **'Gerade steht kein Check-in an.'**
  String get checkinKeiner;

  /// Fortschritt im Check-in.
  ///
  /// In de, this message translates to:
  /// **'{aktuell} von {gesamt}'**
  String checkinSchrittZaehler(int aktuell, int gesamt);

  /// No description provided for @checkinUnterEinerMinute.
  ///
  /// In de, this message translates to:
  /// **'Unter einer Minute'**
  String get checkinUnterEinerMinute;

  /// No description provided for @checkinAbbrechbar.
  ///
  /// In de, this message translates to:
  /// **'Du kannst jederzeit abbrechen – dein Zwischenstand bleibt gespeichert.'**
  String get checkinAbbrechbar;

  /// No description provided for @checkinAufKurs.
  ///
  /// In de, this message translates to:
  /// **'Du bist auf Kurs'**
  String get checkinAufKurs;

  /// No description provided for @checkinPlanUnveraendert.
  ///
  /// In de, this message translates to:
  /// **'Plan unverändert lassen'**
  String get checkinPlanUnveraendert;

  /// No description provided for @checkinOhneAnpassung.
  ///
  /// In de, this message translates to:
  /// **'Ohne Anpassung abschließen'**
  String get checkinOhneAnpassung;

  /// No description provided for @vergleichHinweis.
  ///
  /// In de, this message translates to:
  /// **'Gleicher Ausschnitt, gleiches Licht – so lässt sich vergleichen, was sich wirklich verändert hat.'**
  String get vergleichHinweis;

  /// No description provided for @vergleichNurFuerDichTitel.
  ///
  /// In de, this message translates to:
  /// **'Nur für dich'**
  String get vergleichNurFuerDichTitel;

  /// No description provided for @vergleichNurFuerDichText.
  ///
  /// In de, this message translates to:
  /// **'Auch das Fortschrittsfoto bleibt auf deinem Gerät und geht nur für die Auswertung an den Analyse-Dienst.'**
  String get vergleichNurFuerDichText;

  /// No description provided for @vergleichOhneDatum.
  ///
  /// In de, this message translates to:
  /// **'ohne Datum'**
  String get vergleichOhneDatum;

  /// No description provided for @altersTitel.
  ///
  /// In de, this message translates to:
  /// **'Nur für Erwachsene'**
  String get altersTitel;

  /// No description provided for @altersWeiter.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Analyse'**
  String get altersWeiter;

  /// No description provided for @altersZurueck.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Dashboard'**
  String get altersZurueck;

  /// No description provided for @altersWarumTitel.
  ///
  /// In de, this message translates to:
  /// **'Warum wir fragen'**
  String get altersWarumTitel;

  /// No description provided for @altersWarumText.
  ///
  /// In de, this message translates to:
  /// **'Für eine Analyse verarbeitet TrueGlow Aufnahmen deines Gesichts. Solche Daten sind besonders geschützt, und eine wirksame Einwilligung dazu können nur Erwachsene selbst erteilen. Deshalb ist die App ab 18.'**
  String get altersWarumText;

  /// No description provided for @altersOhneText.
  ///
  /// In de, this message translates to:
  /// **'Ohne Bestätigung bleibt nur der Analyse-Bereich zu. Dein Plan, die Tages-Checkliste, deine Serie und die Check-ins funktionieren weiter — und deine bisherigen Reports bleiben erhalten.'**
  String get altersOhneText;

  /// No description provided for @einwilligungKurzTitel.
  ///
  /// In de, this message translates to:
  /// **'Kurz bestätigen'**
  String get einwilligungKurzTitel;

  /// No description provided for @einwilligungNachgeschaerftTitel.
  ///
  /// In de, this message translates to:
  /// **'Wir haben nachgeschärft'**
  String get einwilligungNachgeschaerftTitel;

  /// No description provided for @einwilligungNeueFassungTitel.
  ///
  /// In de, this message translates to:
  /// **'Neue Fassung der Texte'**
  String get einwilligungNeueFassungTitel;

  /// No description provided for @einwilligungNachgeschaerftText.
  ///
  /// In de, this message translates to:
  /// **'Bisher gab es ein einzelnes Häkchen für alles. Weil deine Fotos etwas anderes sind als die Nutzung der App, fragen wir beides jetzt getrennt — einmalig und danach nie wieder.'**
  String get einwilligungNachgeschaerftText;

  /// No description provided for @einwilligungNeueFassungText.
  ///
  /// In de, this message translates to:
  /// **'Unsere Rechtstexte haben sich geändert. Damit deine Zustimmung sich auf das bezieht, was tatsächlich gilt, bitten wir dich einmal um Bestätigung.'**
  String get einwilligungNeueFassungText;

  /// No description provided for @einwilligungBleibtErhalten.
  ///
  /// In de, this message translates to:
  /// **'Deine bisherigen Analysen, dein Plan und deine Serie bleiben unverändert erhalten.'**
  String get einwilligungBleibtErhalten;

  /// No description provided for @erklaerungMindestalter.
  ///
  /// In de, this message translates to:
  /// **'TrueGlow verarbeitet Aufnahmen deines Gesichts und richtet sich deshalb ausschließlich an Erwachsene. Mit dem Häkchen bestätigst du, dass du volljährig bist.'**
  String get erklaerungMindestalter;

  /// No description provided for @erklaerungNutzung.
  ///
  /// In de, this message translates to:
  /// **'Ich habe die Nutzungsbedingungen und die Datenschutzerklärung gelesen und stimme ihnen zu.'**
  String get erklaerungNutzung;

  /// No description provided for @erklaerungDiagnose.
  ///
  /// In de, this message translates to:
  /// **'Ich willige ein, dass anonyme Absturzberichte und eine sparsame Nutzungsstatistik erfasst werden. Erfasst wird nur, DASS ein Schritt erreicht wurde – keine Fotos, keine Analyse-Inhalte, keine Freitexte, keine Profilangaben.'**
  String get erklaerungDiagnose;

  /// No description provided for @erklaerungFotoKi.
  ///
  /// In de, this message translates to:
  /// **'Ich willige ein, dass meine Fotos – darunter Aufnahmen meines Gesichts – zur Auswertung an den KI-Dienst Google Gemini übermittelt werden. Die Verarbeitung findet auf Servern von Google statt, auch außerhalb der EU (Drittlandtransfer). Die Bilder werden dort nicht gespeichert und nicht protokolliert.'**
  String get erklaerungFotoKi;

  /// No description provided for @freiwilligFotoKi.
  ///
  /// In de, this message translates to:
  /// **'Freiwillig und jederzeit in den Einstellungen widerrufbar. Ohne diese Einwilligung sind keine neuen Analysen möglich – alles andere funktioniert weiter, bestehende Reports bleiben.'**
  String get freiwilligFotoKi;

  /// No description provided for @freiwilligMindestalter.
  ///
  /// In de, this message translates to:
  /// **'Ohne Bestätigung bleibt der Analyse-Bereich zu. Plan, Checklisten und Check-ins kannst du trotzdem nutzen.'**
  String get freiwilligMindestalter;

  /// No description provided for @freiwilligDiagnose.
  ///
  /// In de, this message translates to:
  /// **'Freiwillig, standardmäßig aus und jederzeit widerrufbar. Hilft uns, Abstürze zu finden, bevor sie in einer Bewertung landen.'**
  String get freiwilligDiagnose;

  /// No description provided for @datumHeute.
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get datumHeute;

  /// No description provided for @datumGestern.
  ///
  /// In de, this message translates to:
  /// **'gestern'**
  String get datumGestern;

  /// No description provided for @verlaufLoeschenTitel.
  ///
  /// In de, this message translates to:
  /// **'Analyse löschen?'**
  String get verlaufLoeschenTitel;

  /// Rueckfrage vor dem Loeschen einer Analyse.
  ///
  /// In de, this message translates to:
  /// **'Die Analyse vom {datum} wird vom Gerät entfernt.'**
  String verlaufLoeschenText(String datum);

  /// No description provided for @loeschen.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get loeschen;

  /// No description provided for @verlaufLoeschenTooltip.
  ///
  /// In de, this message translates to:
  /// **'Analyse löschen'**
  String get verlaufLoeschenTooltip;

  /// No description provided for @homeDeinPlan.
  ///
  /// In de, this message translates to:
  /// **'Dein Plan'**
  String get homeDeinPlan;

  /// Beschriftung der schmalen Schaltflaeche neben „Plan ansehen".
  ///
  /// In de, this message translates to:
  /// **'Analyse'**
  String get homeAnalyseKurz;

  /// Zeile unter dem Plan auf der Startseite.
  ///
  /// In de, this message translates to:
  /// **'{datum} erstellt'**
  String homeErstelltAm(String datum);

  /// No description provided for @legalFotosText.
  ///
  /// In de, this message translates to:
  /// **'Deine Fotos verlassen das Gerät nur für die Dauer einer Analyse und werden dabei nirgends gespeichert.'**
  String get legalFotosText;

  /// Meldung, wenn ein Rechtstext nicht geladen werden kann.
  ///
  /// In de, this message translates to:
  /// **'{titel} lässt sich gerade nicht öffnen.'**
  String legalNichtOeffenbar(String titel);

  /// No description provided for @legalStehenAusTitel.
  ///
  /// In de, this message translates to:
  /// **'Texte stehen noch aus'**
  String get legalStehenAusTitel;

  /// No description provided for @dokumentKeinTextTitel.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht verfügbar'**
  String get dokumentKeinTextTitel;

  /// No description provided for @dokumentKeinTextText.
  ///
  /// In de, this message translates to:
  /// **'Für dieses Dokument ist noch kein Text hinterlegt.'**
  String get dokumentKeinTextText;

  /// No description provided for @dokumentNichtLesbarTitel.
  ///
  /// In de, this message translates to:
  /// **'Text nicht lesbar'**
  String get dokumentNichtLesbarTitel;

  /// No description provided for @dokumentNichtLesbarText.
  ///
  /// In de, this message translates to:
  /// **'Der hinterlegte Text lässt sich nicht laden. Bitte ruf ihn über die Webseite auf.'**
  String get dokumentNichtLesbarText;

  /// No description provided for @migrationTitel.
  ///
  /// In de, this message translates to:
  /// **'Deine bisherigen Daten übernehmen?'**
  String get migrationTitel;

  /// No description provided for @migrationText.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät liegen Analysen, Plan, Streak und Check-ins aus der Zeit ohne Konto. Sollen sie zu deinem Konto gehören?\n\nDeine Fotos bleiben in jedem Fall nur auf dem Gerät.'**
  String get migrationText;

  /// No description provided for @migrationUebernehmen.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get migrationUebernehmen;

  /// No description provided for @migrationNichts.
  ///
  /// In de, this message translates to:
  /// **'Es gab nichts zu übernehmen.'**
  String get migrationNichts;

  /// Rueckmeldung nach der Uebernahme des lokalen Bestands.
  ///
  /// In de, this message translates to:
  /// **'Übernommen: {anzahl} Einträge.'**
  String migrationErfolg(int anzahl);

  /// No description provided for @migrationFehler.
  ///
  /// In de, this message translates to:
  /// **'Übernahme fehlgeschlagen. Deine Daten sind weiter auf dem Gerät – wir fragen beim nächsten Start erneut.'**
  String get migrationFehler;

  /// No description provided for @onbPunktFotos.
  ///
  /// In de, this message translates to:
  /// **'Zwei Fotos aufnehmen'**
  String get onbPunktFotos;

  /// No description provided for @onbPunktAnalyse.
  ///
  /// In de, this message translates to:
  /// **'KI-Analyse deiner Merkmale'**
  String get onbPunktAnalyse;

  /// No description provided for @onbPunktPlan.
  ///
  /// In de, this message translates to:
  /// **'Konkreter Plan mit Checkliste'**
  String get onbPunktPlan;

  /// No description provided for @onbDatenschutzText.
  ///
  /// In de, this message translates to:
  /// **'Bitte lies die folgenden Hinweise, bevor es losgeht.'**
  String get onbDatenschutzText;

  /// No description provided for @onbKeineMedizin.
  ///
  /// In de, this message translates to:
  /// **'Keine medizinische Beratung'**
  String get onbKeineMedizin;

  /// No description provided for @onbUmgangFotos.
  ///
  /// In de, this message translates to:
  /// **'Umgang mit deinen Fotos'**
  String get onbUmgangFotos;

  /// No description provided for @planLeer.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Plan vorhanden. Starte zuerst eine Analyse.'**
  String get planLeer;

  /// No description provided for @ergebnisNichtVorhanden.
  ///
  /// In de, this message translates to:
  /// **'Diese Analyse ist nicht mehr vorhanden.'**
  String get ergebnisNichtVorhanden;

  /// No description provided for @settingsKontoLoeschenFrage.
  ///
  /// In de, this message translates to:
  /// **'Konto endgültig löschen?'**
  String get settingsKontoLoeschenFrage;

  /// No description provided for @settingsDatenLoeschenFrage.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen?'**
  String get settingsDatenLoeschenFrage;

  /// No description provided for @settingsKontoLoeschenText.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto und alle Inhalte werden unwiderruflich gelöscht – auf diesem Gerät und in der Cloud. Auch deine Fotos auf dem Gerät werden entfernt.\n\nDanach kannst du dich mit diesem Konto nicht mehr anmelden.'**
  String get settingsKontoLoeschenText;

  /// No description provided for @settingsDatenLoeschenText.
  ///
  /// In de, this message translates to:
  /// **'Analysen, Plan, Fortschritt und deine Angaben werden unwiderruflich entfernt – auf diesem Gerät und in deinem Konto. Auch deine Fotos auf dem Gerät werden gelöscht.\n\nDein Konto selbst bleibt bestehen.'**
  String get settingsDatenLoeschenText;

  /// No description provided for @settingsKontoLoeschenKnopf.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get settingsKontoLoeschenKnopf;

  /// No description provided for @settingsFotoJa.
  ///
  /// In de, this message translates to:
  /// **'Analysen sind möglich. Deine Fotos gehen nur für die Dauer der Auswertung an den KI-Dienst.'**
  String get settingsFotoJa;

  /// No description provided for @settingsFotoNein.
  ///
  /// In de, this message translates to:
  /// **'Ohne Foto-Einwilligung sind keine neuen Analysen möglich. Deine bisherigen Reports, dein Plan und deine Serie bleiben erhalten.'**
  String get settingsFotoNein;

  /// Zeile in der Einwilligungs-Uebersicht.
  ///
  /// In de, this message translates to:
  /// **'{titel}: noch nicht gefragt'**
  String settingsNochNichtGefragt(String titel);

  /// No description provided for @settingsNachtraeglich.
  ///
  /// In de, this message translates to:
  /// **'nachträglich'**
  String get settingsNachtraeglich;

  /// No description provided for @settingsAnmeldungUnklar.
  ///
  /// In de, this message translates to:
  /// **'Der Anmeldezustand lässt sich gerade nicht abfragen. Deine Daten auf dem Gerät sind davon nicht betroffen.'**
  String get settingsAnmeldungUnklar;

  /// No description provided for @settingsKontoAnonym.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten hängen an diesem Gerät. Melde dich mit Google an, damit sie einen Gerätewechsel überleben – dein bisheriger Stand wird dabei übernommen.'**
  String get settingsKontoAnonym;

  /// No description provided for @settingsKontoEcht.
  ///
  /// In de, this message translates to:
  /// **'Plan, Streak und Verlauf gehören zu diesem Konto. Fotos bleiben auf dem Gerät.'**
  String get settingsKontoEcht;

  /// No description provided for @settingsVerknuepfen.
  ///
  /// In de, this message translates to:
  /// **'Mit Google verknüpfen'**
  String get settingsVerknuepfen;

  /// No description provided for @settingsVerknuepft.
  ///
  /// In de, this message translates to:
  /// **'Konto verknüpft.'**
  String get settingsVerknuepft;

  /// No description provided for @settingsAbmeldenAnonym.
  ///
  /// In de, this message translates to:
  /// **'Du bist ohne Konto angemeldet. Nach dem Abmelden kommst du an diesen Stand nicht mehr heran. Die Daten auf diesem Gerät bleiben erhalten.'**
  String get settingsAbmeldenAnonym;

  /// No description provided for @settingsAbmeldenEcht.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten bleiben in deinem Konto. Nach der nächsten Anmeldung sind sie wieder da.'**
  String get settingsAbmeldenEcht;

  /// No description provided for @settingsKonto.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get settingsKonto;

  /// No description provided for @settingsAnalyseModus.
  ///
  /// In de, this message translates to:
  /// **'Analyse-Modus'**
  String get settingsAnalyseModus;

  /// No description provided for @settingsModusDemo.
  ///
  /// In de, this message translates to:
  /// **'Es werden keine Fotos versendet. Die App zeigt eine hinterlegte Beispiel-Analyse. Umschalten beim Build über --dart-define=TRUEGLOW_MOCK.'**
  String get settingsModusDemo;

  /// Erklaerung des Live-Modus in den Einstellungen.
  ///
  /// In de, this message translates to:
  /// **'Analysen laufen über den TrueGlow-Dienst ({modell}). Deine Fotos werden für die Auswertung übertragen und dort weder gespeichert noch protokolliert.'**
  String settingsModusLive(String modell);

  /// Kurzmeldung unten am Bildschirm: Titel und Tipp eines Fehlers.
  ///
  /// In de, this message translates to:
  /// **'{titel}: {tipp}'**
  String settingsFehlerMeldung(String titel, String tipp);

  /// No description provided for @streakTage.
  ///
  /// In de, this message translates to:
  /// **'Tage am Stück'**
  String get streakTage;

  /// No description provided for @streakAllesErledigt.
  ///
  /// In de, this message translates to:
  /// **'Heute alles erledigt. Stark.'**
  String get streakAllesErledigt;

  /// No description provided for @streakKeineAufgaben.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Tagesaufgaben.'**
  String get streakKeineAufgaben;

  /// No description provided for @streakNichtsAbgehakt.
  ///
  /// In de, this message translates to:
  /// **'Heute noch nichts abgehakt – ein Haken sichert den Tag.'**
  String get streakNichtsAbgehakt;

  /// Fortschritt der Tages-Checkliste.
  ///
  /// In de, this message translates to:
  /// **'Heute {erledigt} von {gesamt} erledigt'**
  String streakHeuteErledigt(int erledigt, int gesamt);

  /// Der längste je erreichte Streak. Bleibt stehen, auch wenn die aktuelle Serie reißt.
  ///
  /// In de, this message translates to:
  /// **'{tage, plural, =1{Längste Serie: 1 Tag} other{Längste Serie: {tage} Tage}}'**
  String streakRekord(int tage);

  /// No description provided for @streakNeustart.
  ///
  /// In de, this message translates to:
  /// **'Neustart – dein längster Streak bleibt dir erhalten.'**
  String get streakNeustart;

  /// Bildschirm mit Vorher-Nachher-Vergleich und Zeitleiste der Fortschrittsfotos.
  ///
  /// In de, this message translates to:
  /// **'Deine Fortschritts-Fotos'**
  String get fotosTitel;

  /// No description provided for @fotosLeerTitel.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Foto'**
  String get fotosLeerTitel;

  /// No description provided for @fotosLeerText.
  ///
  /// In de, this message translates to:
  /// **'Beim nächsten Check-in kannst du eins aufnehmen – freiwillig und jederzeit überspringbar.'**
  String get fotosLeerText;

  /// No description provided for @fotosEinsTitel.
  ///
  /// In de, this message translates to:
  /// **'Der Anfang steht'**
  String get fotosEinsTitel;

  /// No description provided for @fotosEinsText.
  ///
  /// In de, this message translates to:
  /// **'Ab dem zweiten Foto siehst du hier den Vergleich.'**
  String get fotosEinsText;

  /// No description provided for @fotosNurHierTitel.
  ///
  /// In de, this message translates to:
  /// **'Diese Fotos bleiben auf diesem Gerät'**
  String get fotosNurHierTitel;

  /// No description provided for @fotosNurHierText.
  ///
  /// In de, this message translates to:
  /// **'Sie liegen im geschützten Speicher der App: nicht in deiner Galerie, nicht im Google-Backup, nicht auf unserem Server. Für die Analyse werden sie nicht verwendet. Beim Handywechsel oder einer Neuinstallation sind sie weg.'**
  String get fotosNurHierText;

  /// No description provided for @fotosVerstanden.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get fotosVerstanden;

  /// No description provided for @fotosVorher.
  ///
  /// In de, this message translates to:
  /// **'Vorher'**
  String get fotosVorher;

  /// No description provided for @fotosNachher.
  ///
  /// In de, this message translates to:
  /// **'Nachher'**
  String get fotosNachher;

  /// No description provided for @fotosReglerHinweis.
  ///
  /// In de, this message translates to:
  /// **'Zieh den Regler, um zu vergleichen.'**
  String get fotosReglerHinweis;

  /// No description provided for @fotosZeitleiste.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =1{1 Foto} other{{anzahl} Fotos}}'**
  String fotosZeitleiste(int anzahl);

  /// No description provided for @fotosStart.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get fotosStart;

  /// No description provided for @fotosLoeschen.
  ///
  /// In de, this message translates to:
  /// **'Dieses Foto löschen'**
  String get fotosLoeschen;

  /// No description provided for @fotosLoeschenFrage.
  ///
  /// In de, this message translates to:
  /// **'Foto löschen?'**
  String get fotosLoeschenFrage;

  /// No description provided for @fotosLoeschenText.
  ///
  /// In de, this message translates to:
  /// **'Das Bild wird vom Gerät entfernt und lässt sich nicht wiederherstellen. Deine Antworten aus dem Check-in bleiben.'**
  String get fotosLoeschenText;

  /// No description provided for @fotosStartNichtLoeschbar.
  ///
  /// In de, this message translates to:
  /// **'Das Startfoto gehört zu deiner Analyse.'**
  String get fotosStartNichtLoeschbar;

  /// No description provided for @fotosOeffnen.
  ///
  /// In de, this message translates to:
  /// **'Fortschritts-Fotos ansehen'**
  String get fotosOeffnen;

  /// No description provided for @fotosAlleAnsehen.
  ///
  /// In de, this message translates to:
  /// **'Alle Fotos ansehen'**
  String get fotosAlleAnsehen;

  /// Wöchentliche Extra-Aufgabe auf der Startseite. Rotiert aus einem festen Vorrat.
  ///
  /// In de, this message translates to:
  /// **'Challenge der Woche'**
  String get challengeTitel;

  /// No description provided for @challengeAktiveTage.
  ///
  /// In de, this message translates to:
  /// **'Sei an {ziel} Tagen aktiv – ein Haken genügt.'**
  String challengeAktiveTage(int ziel);

  /// No description provided for @challengeSerie.
  ///
  /// In de, this message translates to:
  /// **'Hake {ziel} Tage in Folge mindestens einen Punkt ab.'**
  String challengeSerie(int ziel);

  /// No description provided for @challengeVolleTage.
  ///
  /// In de, this message translates to:
  /// **'Schaffe an {ziel} Tagen deine komplette Checkliste.'**
  String challengeVolleTage(int ziel);

  /// No description provided for @challengeAufgaben.
  ///
  /// In de, this message translates to:
  /// **'Hake diese Woche {ziel} Aufgaben ab.'**
  String challengeAufgaben(int ziel);

  /// No description provided for @challengeFrueheWoche.
  ///
  /// In de, this message translates to:
  /// **'Starker Start: Montag bis Mittwoch je ein Haken.'**
  String get challengeFrueheWoche;

  /// No description provided for @challengeWochenende.
  ///
  /// In de, this message translates to:
  /// **'Auch am Wochenende: Samstag und Sonntag je ein Haken.'**
  String get challengeWochenende;

  /// No description provided for @challengeStand.
  ///
  /// In de, this message translates to:
  /// **'{stand} von {ziel}'**
  String challengeStand(int stand, int ziel);

  /// No description provided for @challengeGeschafft.
  ///
  /// In de, this message translates to:
  /// **'Geschafft!'**
  String get challengeGeschafft;

  /// No description provided for @abzeichenChallengesTitel.
  ///
  /// In de, this message translates to:
  /// **'Vier Wochen, vier Ziele'**
  String get abzeichenChallengesTitel;

  /// No description provided for @abzeichenChallengesText.
  ///
  /// In de, this message translates to:
  /// **'Vier Wochen-Challenges geschafft.'**
  String get abzeichenChallengesText;

  /// No description provided for @abzeichenNochChallenges.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =1{noch 1 Challenge} other{noch {anzahl} Challenges}}'**
  String abzeichenNochChallenges(int anzahl);

  /// Wochen-Rückblick auf der Startseite, Sonntagabend bis Montag.
  ///
  /// In de, this message translates to:
  /// **'Deine Woche'**
  String get rueckblickTitel;

  /// No description provided for @rueckblickZeitraum.
  ///
  /// In de, this message translates to:
  /// **'{von} bis {bis}'**
  String rueckblickZeitraum(String von, String bis);

  /// No description provided for @rueckblickAktiveTage.
  ///
  /// In de, this message translates to:
  /// **'{tage, plural, =1{1 von 7 Tagen aktiv} other{{tage} von 7 Tagen aktiv}}'**
  String rueckblickAktiveTage(int tage);

  /// No description provided for @rueckblickAufgaben.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =1{1 Aufgabe abgehakt} other{{anzahl} Aufgaben abgehakt}}'**
  String rueckblickAufgaben(int anzahl);

  /// No description provided for @rueckblickStaerkster.
  ///
  /// In de, this message translates to:
  /// **'Dein stärkster Bereich: {bereich}'**
  String rueckblickStaerkster(String bereich);

  /// No description provided for @rueckblickTonStark.
  ///
  /// In de, this message translates to:
  /// **'Starke Woche. Genau so wird aus Vorsatz Routine.'**
  String get rueckblickTonStark;

  /// No description provided for @rueckblickTonSolide.
  ///
  /// In de, this message translates to:
  /// **'Solide Woche. Der Grundstock steht.'**
  String get rueckblickTonSolide;

  /// No description provided for @rueckblickTonKlein.
  ///
  /// In de, this message translates to:
  /// **'Zwei Tage sind zwei mehr als keiner. Das zählt.'**
  String get rueckblickTonKlein;

  /// No description provided for @rueckblickTonLeer.
  ///
  /// In de, this message translates to:
  /// **'Neue Woche, neue Chance – ein Haken reicht für den Anfang.'**
  String get rueckblickTonLeer;

  /// No description provided for @rueckblickSchliessen.
  ///
  /// In de, this message translates to:
  /// **'Rückblick schließen'**
  String get rueckblickSchliessen;

  /// Kurzer Moment nach dem ersten Haken des Tages. Steht in der Serien-Karte und blendet sich von selbst aus.
  ///
  /// In de, this message translates to:
  /// **'Tag gesichert!'**
  String get streakTagGesichert;

  /// No description provided for @streakTagGesichertText.
  ///
  /// In de, this message translates to:
  /// **'{tage, plural, =1{Der Anfang steht – Tag 1.} other{Damit stehen {tage} Tage am Stück.}}'**
  String streakTagGesichertText(int tage);

  /// Wie viele Streak-Joker der laufende Kalendermonat noch hergibt.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =0{Diesen Monat keine Joker mehr} =1{Noch 1 Joker diesen Monat} other{Noch {anzahl} Joker diesen Monat}}'**
  String streakJokerUebrig(int anzahl);

  /// Freundlicher Hinweis, wenn für einen verpassten Tag ein Joker eingesprungen ist.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =1{Ein Joker hat deinen Streak gerettet.} other{{anzahl} Joker haben deinen Streak gerettet.}}'**
  String streakJokerGerettet(int anzahl);

  /// Tooltip an den Joker-Symbolen.
  ///
  /// In de, this message translates to:
  /// **'Joker: {gesamt} pro Monat. Verpasst du einen Tag, springt automatisch einer ein.'**
  String streakJokerErklaerung(int gesamt);

  /// Fortschritt zum Abzeichen „Alles freigeschaltet".
  ///
  /// In de, this message translates to:
  /// **'noch {anzahl}'**
  String streakNochModule(int anzahl);

  /// Fortschritt zu einem Streak-Abzeichen.
  ///
  /// In de, this message translates to:
  /// **'noch {anzahl}'**
  String streakNochTage(int anzahl);

  /// Untertitel einer Analyse im Verlauf.
  ///
  /// In de, this message translates to:
  /// **'{bereiche} Bereiche · {empfehlungen} Empfehlungen'**
  String verlaufZeile(int bereiche, int empfehlungen);

  /// Zeile unter „Dein Plan" auf der Startseite.
  ///
  /// In de, this message translates to:
  /// **'{datum} erstellt · {empfehlungen} Empfehlungen'**
  String homePlanZeile(String datum, int empfehlungen);

  /// Entwurfshinweis mit dem Pruefbericht aus Rechtstexte.fehlerbericht.
  ///
  /// In de, this message translates to:
  /// **'Die endgültigen Fassungen sind noch nicht eingetragen. Bis dahin bleiben die betroffenen Einträge gesperrt.\n\n{bericht}'**
  String legalEntwurfHinweis(String bericht);

  /// No description provided for @migrationAblehnen.
  ///
  /// In de, this message translates to:
  /// **'Nein, frisch starten'**
  String get migrationAblehnen;

  /// No description provided for @settingsEinwilligungen.
  ///
  /// In de, this message translates to:
  /// **'Einwilligungen'**
  String get settingsEinwilligungen;

  /// No description provided for @settingsWirdGeladen.
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get settingsWirdGeladen;

  /// No description provided for @settingsNichtAngemeldet.
  ///
  /// In de, this message translates to:
  /// **'Nicht angemeldet.'**
  String get settingsNichtAngemeldet;

  /// No description provided for @settingsAbmelden.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get settingsAbmelden;

  /// No description provided for @settingsAbmeldenFrage.
  ///
  /// In de, this message translates to:
  /// **'Abmelden?'**
  String get settingsAbmeldenFrage;

  /// No description provided for @settingsErteilt.
  ///
  /// In de, this message translates to:
  /// **'erteilt'**
  String get settingsErteilt;

  /// No description provided for @settingsNichtErteilt.
  ///
  /// In de, this message translates to:
  /// **'nicht erteilt'**
  String get settingsNichtErteilt;

  /// Eine Zeile des Einwilligungs-Nachweises.
  ///
  /// In de, this message translates to:
  /// **'{titel}: {stand} am {datum} (Textstand {version}, {kanal})'**
  String settingsNachweis(
    String titel,
    String stand,
    String datum,
    String version,
    String kanal,
  );

  /// No description provided for @settingsVersionUnbekannt.
  ///
  /// In de, this message translates to:
  /// **'unbekannt'**
  String get settingsVersionUnbekannt;

  /// No description provided for @settingsKanalOnboarding.
  ///
  /// In de, this message translates to:
  /// **'im Onboarding'**
  String get settingsKanalOnboarding;

  /// No description provided for @settingsKanalEinstellungen.
  ///
  /// In de, this message translates to:
  /// **'in den Einstellungen'**
  String get settingsKanalEinstellungen;

  /// No description provided for @settingsKanalNachtrag.
  ///
  /// In de, this message translates to:
  /// **'nachträglich'**
  String get settingsKanalNachtrag;

  /// Pille auf der Karte „Analyse-Modus". Fachbegriff, bleibt unuebersetzt.
  ///
  /// In de, this message translates to:
  /// **'Mock'**
  String get settingsModusMock;

  /// Pille auf der Karte „Analyse-Modus". Fachbegriff, bleibt unuebersetzt.
  ///
  /// In de, this message translates to:
  /// **'Live'**
  String get settingsModusLiveKurz;

  /// No description provided for @abzeichenErsteAnalyseOffen.
  ///
  /// In de, this message translates to:
  /// **'Starte deine erste Analyse'**
  String get abzeichenErsteAnalyseOffen;

  /// Was dem Abzeichen „Alles freigeschaltet" noch fehlt.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =1{noch 1 Modul} other{noch {anzahl} Module}}'**
  String abzeichenNochModule(int anzahl);

  /// Was einem Streak-Abzeichen noch fehlt.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =1{noch 1 Tag} other{noch {anzahl} Tage}}'**
  String abzeichenNochTage(int anzahl);

  /// No description provided for @erscheinungFolgtSystem.
  ///
  /// In de, this message translates to:
  /// **'TrueGlow folgt der Systemeinstellung deines Handys.'**
  String get erscheinungFolgtSystem;

  /// No description provided for @erscheinungFest.
  ///
  /// In de, this message translates to:
  /// **'Feste Auswahl – unabhängig von der Systemeinstellung.'**
  String get erscheinungFest;

  /// No description provided for @mockGrundOhne.
  ///
  /// In de, this message translates to:
  /// **'Passt so nicht in deinen Alltag.'**
  String get mockGrundOhne;

  /// Begruendung einer Anpassung im Demo-Modus.
  ///
  /// In de, this message translates to:
  /// **'{grund} – wir machen es dir leichter.'**
  String mockGrundMit(String grund);

  /// No description provided for @mockKeineAenderung.
  ///
  /// In de, this message translates to:
  /// **'Dein Plan bleibt, wie er ist – das läuft gut so.'**
  String get mockKeineAenderung;

  /// Zusammenfassung der Anpassungen im Demo-Modus.
  ///
  /// In de, this message translates to:
  /// **'{anzahl, plural, =1{Das passen wir an: 1 Aufgabe, die nicht in deinen Alltag gepasst hat.} other{Das passen wir an: {anzahl} Aufgaben, die nicht in deinen Alltag gepasst haben.}}'**
  String mockAenderungen(int anzahl);

  /// No description provided for @mockFazit.
  ///
  /// In de, this message translates to:
  /// **'Im Vergleich zum Startfoto wirkt die Pflege insgesamt gleichmäßiger. Bleib bei den Aufgaben, die dir leichtfallen – die zwei angepassten Punkte nehmen dir Zeit ab.'**
  String get mockFazit;

  /// No description provided for @mockVarianteZeit.
  ///
  /// In de, this message translates to:
  /// **'{habit} – nur 30 Sekunden'**
  String mockVarianteZeit(String habit);

  /// No description provided for @mockVarianteVergessen.
  ///
  /// In de, this message translates to:
  /// **'{habit} – direkt nach dem Zähneputzen'**
  String mockVarianteVergessen(String habit);

  /// No description provided for @mockVarianteUnangenehm.
  ///
  /// In de, this message translates to:
  /// **'{habit} – in der leichten Variante'**
  String mockVarianteUnangenehm(String habit);

  /// No description provided for @mockVarianteTeuer.
  ///
  /// In de, this message translates to:
  /// **'{habit} – mit günstiger Alternative'**
  String mockVarianteTeuer(String habit);

  /// No description provided for @mockVarianteAnderer.
  ///
  /// In de, this message translates to:
  /// **'{habit} – jeden zweiten Tag'**
  String mockVarianteAnderer(String habit);

  /// Willkommenssatz auf dem Anmelde-Bildschirm.
  ///
  /// In de, this message translates to:
  /// **'Dein persönlicher Plan für Haut, Haare, Bart und Style. Melde dich an – oder schau dich erst einmal um.'**
  String get loginWillkommen;

  /// Ueberschrift ueber den Verweisen auf die Rechtstexte.
  ///
  /// In de, this message translates to:
  /// **'Bevor du loslegst:'**
  String get loginRechtliches;

  /// No description provided for @geschlechtMaennlich.
  ///
  /// In de, this message translates to:
  /// **'Männlich'**
  String get geschlechtMaennlich;

  /// No description provided for @geschlechtWeiblich.
  ///
  /// In de, this message translates to:
  /// **'Weiblich'**
  String get geschlechtWeiblich;

  /// No description provided for @geschlechtDivers.
  ///
  /// In de, this message translates to:
  /// **'Divers'**
  String get geschlechtDivers;

  /// No description provided for @geschlechtKeineAngabe.
  ///
  /// In de, this message translates to:
  /// **'Keine Angabe'**
  String get geschlechtKeineAngabe;

  /// No description provided for @onbGeschlechtTitel.
  ///
  /// In de, this message translates to:
  /// **'Für wen erstellen wir den Plan?'**
  String get onbGeschlechtTitel;

  /// No description provided for @onbGeschlechtText.
  ///
  /// In de, this message translates to:
  /// **'Danach richten sich Module, Umriss-Hilfen und Empfehlungen. Du kannst es jederzeit in den Einstellungen ändern.'**
  String get onbGeschlechtText;

  /// No description provided for @einstellungenGeschlecht.
  ///
  /// In de, this message translates to:
  /// **'Ausrichtung'**
  String get einstellungenGeschlecht;

  /// No description provided for @geschlechtHinweisWeiblich.
  ///
  /// In de, this message translates to:
  /// **'Make-up & Ausstrahlung ist dabei, Bart-Empfehlungen entfallen.'**
  String get geschlechtHinweisWeiblich;

  /// No description provided for @geschlechtHinweisMaennlich.
  ///
  /// In de, this message translates to:
  /// **'Bart und Konturen gehören zur Basis, Make-up bleibt draußen.'**
  String get geschlechtHinweisMaennlich;

  /// No description provided for @geschlechtHinweisNeutral.
  ///
  /// In de, this message translates to:
  /// **'Alle Module stehen zur Wahl – Bart ebenso wie Make-up.'**
  String get geschlechtHinweisNeutral;

  /// No description provided for @geschlechtHinweisOffen.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts gewählt. Bis dahin läuft alles wie bisher.'**
  String get geschlechtHinweisOffen;

  /// No description provided for @modulMakeupTitel.
  ///
  /// In de, this message translates to:
  /// **'Make-up & Ausstrahlung'**
  String get modulMakeupTitel;

  /// No description provided for @modulMakeupText.
  ///
  /// In de, this message translates to:
  /// **'Passende Farben, Betonungen und ein Alltags-Look, der zu deinen Zügen passt.'**
  String get modulMakeupText;

  /// No description provided for @modulMakeupCheckliste.
  ///
  /// In de, this message translates to:
  /// **'Make-up'**
  String get modulMakeupCheckliste;

  /// No description provided for @modulBenoetigtMakeup.
  ///
  /// In de, this message translates to:
  /// **'Keine eigene Aufnahme – nutzt das Frontalfoto der Basis. Mach es ohne Make-up oder mit deinem Alltags-Look.'**
  String get modulBenoetigtMakeup;

  /// No description provided for @modulMakeupKeinFotoTitel.
  ///
  /// In de, this message translates to:
  /// **'Kein eigenes Foto nötig'**
  String get modulMakeupKeinFotoTitel;

  /// No description provided for @modulMakeupKeinFotoText.
  ///
  /// In de, this message translates to:
  /// **'Wir lesen Gesichtszüge und Farbwirkung aus deinem Frontalfoto mit. Ob du darauf geschminkt bist, entscheidest du – ungeschminkt zeigt die Grundlage, geschminkt deinen aktuellen Look.'**
  String get modulMakeupKeinFotoText;

  /// No description provided for @modulBasisTitelOhneBart.
  ///
  /// In de, this message translates to:
  /// **'Gesicht & Haare'**
  String get modulBasisTitelOhneBart;

  /// No description provided for @modulBasisTextOhneBart.
  ///
  /// In de, this message translates to:
  /// **'Gesichtsform und Frisur-Empfehlungen.'**
  String get modulBasisTextOhneBart;

  /// No description provided for @modulBasisCheckisteOhneBart.
  ///
  /// In de, this message translates to:
  /// **'Haare'**
  String get modulBasisCheckisteOhneBart;

  /// No description provided for @modulBenoetigtBasisOhneBart.
  ///
  /// In de, this message translates to:
  /// **'Frontal, beide Seitenprofile und 45°-Winkel.'**
  String get modulBenoetigtBasisOhneBart;

  /// No description provided for @frageMakeupGefuehl.
  ///
  /// In de, this message translates to:
  /// **'Wie sicher fühlst du dich mit deinem Look?'**
  String get frageMakeupGefuehl;

  /// No description provided for @frageMakeupErgebnis.
  ///
  /// In de, this message translates to:
  /// **'Wie gut funktioniert dein Alltags-Look inzwischen?'**
  String get frageMakeupErgebnis;

  /// No description provided for @einordnungMakeup.
  ///
  /// In de, this message translates to:
  /// **'Ein neuer Look braucht ein paar Anläufe – nach zwei bis drei Wochen sitzt der Handgriff.'**
  String get einordnungMakeup;

  /// Einleitung der Modulauswahl im weiblichen Modus, wo die Basis keinen Bart-Abschnitt hat.
  ///
  /// In de, this message translates to:
  /// **'Gesicht und Haare sind immer dabei. Alles Weitere wählst du selbst – und kannst es auch später noch ergänzen.'**
  String get moduleEinleitungOhneBart;
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
