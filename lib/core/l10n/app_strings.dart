/// Zentrale Sammlung aller UI-Texte (Deutsch).
/// Bewusst als einfache Konstantenklasse gehalten, damit die Strings spaeter
/// ohne Umbau in ARB-Dateien (flutter_localizations / intl) ueberfuehrt werden
/// koennen: ein String = ein Key.
class S {
  S._();

  // --- Allgemein ---
  static const appName = 'TrueGlow';
  static const weiter = 'Weiter';
  static const zurueck = 'Zurück';
  static const abbrechen = 'Abbrechen';
  static const fertig = 'Fertig';
  static const erneutVersuchen = 'Erneut versuchen';
  static const speichern = 'Speichern';
  static const zurStartseite = 'Zur Startseite';

  // --- Onboarding ---
  static const onbWillkommenTitel = 'Willkommen bei TrueGlow';
  static const onbWillkommenText =
      'Wir erstellen dir einen persönlichen Plan für Haut, Haare, Bart und Style. '
      'Keine Bewertungen, keine Punktzahlen – nur konkrete Schritte.';
  static const onbAlterTitel = 'Wie alt bist du?';
  static const onbAlterText = 'Das hilft uns, passende Empfehlungen auszuwählen.';
  static const onbBudgetTitel = 'Wie viel möchtest du investieren?';
  static const onbBudgetText = 'Für Pflegeprodukte und Styling pro Monat.';
  static const onbZeitTitel = 'Wie viel Zeit hast du täglich?';
  static const onbZeitText = 'Dein Plan wird auf dieses Zeitbudget zugeschnitten.';
  static const onbFokusTitel = 'Worauf willst du dich konzentrieren?';
  static const onbFokusText = 'Mehrfachauswahl möglich.';
  static const onbDatenschutzTitel = 'Datenschutz & Hinweise';

  // --- Home ---
  static const homeTitel = 'TrueGlow';
  static const homeLeerTitel = 'Noch keine Analyse';
  static const homeLeerText =
      'Mach zwei Fotos und erhalte deinen persönlichen Verbesserungsplan.';
  static const homeAnalyseStarten = 'Analyse starten';
  static const homeNeueAnalyse = 'Neue Analyse';
  static const homePlanAnsehen = 'Plan ansehen';

  // --- Foto-Aufnahme ---
  static const fotoTitelFrontal = 'Frontalfoto';
  static const fotoTitelProfil = 'Seitenprofil';
  static const fotoHinweisFrontal =
      'Schau direkt in die Kamera. Neutrales Gesicht, gutes Licht, keine Kopfbedeckung.';
  static const fotoHinweisProfil =
      'Dreh den Kopf um 90° zur Seite. Ohr und Kinnlinie sollten sichtbar sein.';
  static const fotoKamera = 'Kamera';
  static const fotoGalerie = 'Galerie';
  static const fotoNeuAufnehmen = 'Neu aufnehmen';
  static const fotoAnalyseStarten = 'Analyse starten';

  // --- In-App-Kamera ---
  static const kameraAusloesen = 'Auslösen';
  static const kameraWechseln = 'Kamera wechseln';
  static const kameraSchliessen = 'Schließen';
  static const kameraStartet = 'Kamera wird gestartet...';
  static const kameraKeinGesicht = 'Positioniere dein Gesicht im Rahmen';
  static const kameraZuWeitWeg = 'Geh näher ran';
  static const kameraZuNah = 'Etwas weiter weg';
  static const kameraNichtMittig = 'Mittig positionieren';
  static const kameraPerfekt = 'Perfekt – jetzt auslösen';
  static const kameraZuDunkel = 'Mehr Licht nötig';

  // --- Ganzkörper-Sucher und Auto-Auslöser ---
  static const koerperNiemand = 'Stell dich ins Bild';
  static const koerperNichtGanz = 'Ganz ins Bild – Kopf und Füße';
  static const koerperZuWeitWeg = 'Ein paar Schritte näher';
  static const koerperZuNah = 'Ein paar Schritte zurück';
  static const koerperNichtMittig = 'Mittig hinstellen';
  static const koerperBereit = 'Steht – nicht bewegen';
  static const koerperAutoHinweis =
      'Stell dein Handy auf, tritt zurück und stell dich in den Umriss. '
      'Sobald du ganz im Bild stehst, zählt die App herunter und löst selbst '
      'aus. Du kannst auch jederzeit von Hand auslösen.';
  static const kameraKeineBerechtigungTitel = 'Kamerazugriff nötig';
  static const kameraKeineBerechtigungText =
      'TrueGlow braucht Zugriff auf die Kamera, um die Live-Vorschau mit '
      'Positionierungshilfe zu zeigen. Du kannst den Zugriff in den '
      'App-Einstellungen erlauben – oder stattdessen ein Foto aus der Galerie '
      'wählen.';
  static const kameraEinstellungenOeffnen = 'App-Einstellungen öffnen';
  static const kameraNichtVerfuegbarTitel = 'Kamera nicht verfügbar';
  static const kameraNichtVerfuegbarText =
      'Auf diesem Gerät konnte keine Kamera gestartet werden. Wähle ein Foto '
      'aus der Galerie.';

  /// Die Aufnahme selbst ist gescheitert – nicht die Prüfung danach.
  ///
  /// Beim Auto-Auslöser ist das der einzige Hinweis darauf, dass etwas
  /// schiefging: Wer mehrere Meter entfernt steht, sieht sonst nur einen
  /// Countdown, auf den nichts folgt.
  static const aufnahmeFehlgeschlagen =
      'Das Foto hat nicht geklappt – bitte noch einmal';

  // --- Modul-Auswahl ---
  static const moduleTitel = 'Analyse zusammenstellen';
  static const moduleEyebrow = 'Deine Analyse';
  static const moduleUeberschrift = 'Was sollen wir uns ansehen?';
  static const moduleEinleitung =
      'Gesicht, Haare und Bart sind immer dabei. Alles Weitere wählst du '
      'selbst – und kannst es auch später noch ergänzen.';
  static const moduleBasisBadge = 'Basis';
  static const moduleStartBasis = 'Aufnahme starten · Basis';
  static const moduleErweitern = 'Analyse erweitern';
  static const moduleErweiternText =
      'Diese Bereiche fehlen deiner Analyse noch. Deine bisherigen Fotos '
      'bleiben erhalten – es kommen nur die neuen Aufnahmen dazu.';

  // --- Vorschau nach der Aufnahme ---
  static const vorschauTitel = 'Passt das so?';
  static const vorschauUebernehmen = 'Passt';
  static const vorschauWiederholen = 'Nochmal';
  static const vorschauHinweis =
      'Erst wenn du bestätigst, wird das Foto gespeichert.';

  // --- Kontingent ---
  // Der Hinweis erscheint vor der Aufnahme, damit niemand erst fotografiert
  // und dann abgewiesen wird.
  static const kontingentTagesgrenze = 'Heute keine Analyse mehr frei';
  static const kontingentTagesgrenzeText =
      'Drei Analysen pro Tag – das Kontingent ist aufgebraucht. Ab morgen '
      'früh geht es weiter. Dein Plan, deine Checkliste und der Check-in '
      'bleiben in der Zwischenzeit nutzbar.';
  static const kontingentMonatsgrenze = 'Diesen Monat keine Analyse mehr frei';
  static const kontingentMonatsgrenzeText =
      'Dreißig Analysen pro Monat – das Kontingent ist aufgebraucht. Zum '
      'Monatswechsel füllt es sich wieder auf.';

  /// z. B. „Noch 2 von 3 Analysen heute".
  static String kontingentUebrig(int uebrig, int gesamt) =>
      'Noch $uebrig von $gesamt ${uebrig == 1 ? 'Analyse' : 'Analysen'} heute';

  // --- Deine Richtung ---
  static const richtungTitel = 'Deine Richtung';
  static const richtungEyebrow = 'Optional';
  static const richtungUeberschrift =
      'In welche Richtung soll sich dein Look entwickeln?';
  static const richtungEinleitung =
      'Sag uns, worauf du hinauswillst – die Empfehlungen richten sich dann '
      'danach aus. Du kannst den Schritt auch überspringen; dann schauen wir '
      'neutral auf deine Fotos.';
  static const richtungChipsTitel = 'Wähl aus, was passt';
  static const richtungChipsText = 'Mehrfachauswahl möglich.';
  static const richtungFreitextTitel = 'Sag es in deinen eigenen Worten';
  static const richtungFreitextPlatzhalter =
      'Beschreib, was du dir wünschst – Vorbilder, Anlässe, Unsicherheiten, '
      'No-Gos. Je konkreter, desto besser wird dein Plan.';
  static const richtungFreitextHinweis =
      'Kein Chat: Dein Text geht einmalig mit in die Analyse und bleibt sonst '
      'auf deinem Gerät.';
  static const richtungWeiter = 'Weiter zur Aufnahme';
  static const richtungSpeichern = 'Richtung übernehmen';
  static const richtungLeer = 'Noch keine Richtung angegeben.';
  static const richtungLeerText =
      'Gib der Analyse eigene Ziele mit – die Empfehlungen richten sich dann '
      'danach aus.';
  static const richtungAngeben = 'Richtung angeben';
  static const richtungAendern = 'Ändern';
  static const richtungAktualisieren = 'Plan mit neuer Richtung aktualisieren';
  static const richtungAktualisierenText =
      'Deine Richtung hat sich seit dieser Analyse geändert. Wir erstellen den '
      'Plan mit deinen vorhandenen Fotos neu – ohne neue Aufnahmen.';

  // --- Aufnahme-Flow ---
  static const flowUeberspringen = 'Überspringen';
  static const flowAbbrechen = 'Flow abbrechen?';
  static const flowAbbrechenText =
      'Deine bisherigen Aufnahmen bleiben gespeichert. Du kannst später dort '
      'weitermachen, wo du aufgehört hast.';
  static const flowWeitermachen = 'Weitermachen';
  static const lichtTitel = 'Kurz vorab';
  static const lichtText =
      'Drei Dinge machen den größten Unterschied für eine brauchbare Analyse:';
  static const lichtTageslicht = 'Tageslicht';
  static const lichtTageslichtText =
      'Stell dich ans Fenster. Indirektes Tageslicht von vorne, kein '
      'Gegenlicht, keine bunte Deckenlampe.';
  static const lichtKeinFilter = 'Kein Filter';
  static const lichtKeinFilterText =
      'Schalte Beauty-Modus, Filter und Weichzeichner in der Kamera aus – '
      'sonst analysieren wir die Bearbeitung statt dich.';
  static const lichtRuhigeHand = 'Ruhige Hand';
  static const lichtRuhigeHandText =
      'Handy mit beiden Händen halten oder anlehnen. Unscharfe Fotos kosten '
      'am meisten Genauigkeit.';
  static const lichtStarten = 'Los geht es';

  // --- Figur & Passform ---
  static const figurFormularTitel = 'Deine Maße';
  static const figurFormularText =
      'Größe und Gewicht helfen, Schnitte und Passformen realistisch '
      'einzuschätzen. Beides bleibt auf deinem Gerät.';
  static const figurGroesse = 'Körpergröße';
  static const figurGewicht = 'Gewicht';
  static const figurGroesseFehler = 'Bitte eine Größe zwischen 120 und 230 cm.';
  static const figurGewichtFehler = 'Bitte ein Gewicht zwischen 35 und 250 kg.';

  // --- Stil & Kleiderschrank ---
  static const stilFragebogenTitel = 'Dein Stil';
  static const stilFragebogenText =
      'Vier kurze Fragen, damit die Vorschläge zu deinem Alltag passen.';
  static const stilZiel = 'Wohin soll es gehen?';
  static const stilZielText = 'Mehrfachauswahl möglich.';
  static const stilDresscode = 'Was verlangt dein Alltag?';
  static const stilBudget = 'Was gibst du pro Kleidungsstück aus?';
  static const stilPflege = 'Wie viel Aufwand ist okay?';

  // --- Analyse ---
  static const analyseTitel = 'Analyse läuft';
  static const analyseHinweis = 'Das dauert etwa 20 Sekunden. Bitte nicht schließen.';

  // --- Ergebnis ---
  static const ergebnisTitel = 'Deine Analyse';
  static const ergebnisGesichtsform = 'Gesichtsform';
  static const ergebnisPlanErstellen = 'Plan erstellen';
  static const ergebnisEmpfehlungen = 'Empfehlungen';
  static const ergebnisProdukte = 'Produkte';

  // --- Plan ---
  static const planTitel = 'Dein Plan';
  static const planSofort = 'Sofort umsetzbar';
  static const planDreissigTage = 'Erste 30 Tage';
  static const planLangfristig = 'Langfristig';
  static const planStreak = 'Tage in Folge';
  static const planFertigZurStartseite = 'Fertig – zur Startseite';

  // --- Check-ins ---
  static const checkinTitel = 'Check-in';
  static const checkinKarteTitel = 'Kurzer Check-in';
  static const checkinKarteText =
      'Dauert unter einer Minute und macht deinen Plan passgenauer.';
  static const checkinKarteFortsetzen = 'Angefangen – weitermachen';
  static const checkinStarten = 'Check-in starten';
  static const checkinFortsetzen = 'Weitermachen';
  static const checkinSpaeter = 'Später';
  static const checkinNaechster = 'Nächster Check-in';
  static const checkinPushTitel = 'Kurzer Check-in';
  static const checkinPushText = 'Dauert unter einer Minute.';
  static const checkinHabitsTitel = 'Wie gut passen die Aufgaben?';
  static const checkinHabitsText =
      'Ein Tipp pro Aufgabe – es geht nur um deinen Alltag, nicht um '
      'Ergebnisse.';
  static const checkinHabitsErneut =
      'Nur die Aufgaben, die zuletzt gehakt haben.';
  static const checkinGrundTitel = 'Was passt nicht?';
  static const checkinGrundFreitext = 'Magst du kurz sagen, was los ist?';
  static const checkinWirkungTitelFrueh = 'Wie fühlt es sich an?';
  static const checkinWirkungTextFrueh =
      'Nur die schnellen Dinge – alles andere braucht noch etwas Zeit.';
  static const checkinWirkungTitelSpaet = 'Was hat sich getan?';
  static const checkinWirkungTextSpaet =
      'Ein Monat ist genug Zeit für erste sichtbare Unterschiede.';
  static const checkinWirkungNotiz = 'Anmerkung (optional)';
  static const checkinHinweisTitel = 'Kurz zur Einordnung';
  static const checkinFotoTitel = 'Fortschrittsfoto';
  static const checkinFotoText =
      'Optional: ein Foto unter denselben Bedingungen wie beim Start – '
      'Tageslicht, kein Filter, gleicher Bildausschnitt.';
  static const checkinFotoAufnehmen = 'Foto aufnehmen';
  static const checkinFotoNeu = 'Neu aufnehmen';
  static const checkinFotoOhne = 'Ohne Foto weiter';
  static const checkinVergleichTitel = 'Vorher / Nachher';
  static const checkinVergleichVorher = 'Start';
  static const checkinVergleichNachher = 'Heute';

  /// Fotos bleiben auf dem Geraet – nach einem Geraetewechsel fehlen sie
  /// deshalb. Das ist ein erklaerter Normalzustand, kein Fehler.
  static const fotoNichtAufDiesemGeraet =
      'Foto auf diesem Gerät nicht verfügbar';
  static const checkinAuswertungLaeuft = 'Wir schauen uns deine Antworten an…';
  static const checkinFazitTitel = 'Zwischenfazit';
  static const checkinAenderungenTitel = 'Das passen wir an';
  static const checkinKeineAenderung =
      'Dein Plan bleibt so, wie er ist – das läuft gut.';
  static const checkinBestaetigen = 'Änderungen übernehmen';
  static const checkinAbschliessen = 'Check-in abschließen';
  static const checkinAbbrechenTitel = 'Check-in später fortsetzen?';
  static const checkinAbbrechenText =
      'Deine bisherigen Antworten bleiben gespeichert. Du kannst jederzeit '
      'dort weitermachen, wo du aufgehört hast.';
  static const checkinVerlassen = 'Später fortsetzen';
  static const checkinDankeTitel = 'Danke dir!';
  static const checkinDankeText =
      'Dein Plan ist aktualisiert. Angepasste Aufgaben sind in der Checkliste '
      'markiert.';

  // --- Verlauf & Einstellungen ---
  static const verlaufTitel = 'Verlauf';
  static const verlaufLeer = 'Noch keine Analysen vorhanden.';
  static const einstellungenTitel = 'Einstellungen';
  static const einstellungenAngaben = 'Meine Angaben ändern';
  static const einstellungenErscheinungsbild = 'Erscheinungsbild';
  static const einstellungenDatenLoeschen = 'Daten löschen, Konto behalten';
  static const einstellungenKontoLoeschen = 'Konto endgültig löschen';
  static const einstellungenImpressum = 'Impressum';
  static const einstellungenRechtliches = 'Rechtliches';
  static const einstellungenDatenschutz = 'Datenschutzerklärung';

  // --- Disclaimer ---
  static const disclaimerMedizin =
      'TrueGlow ersetzt keine medizinische Beratung. Bei Hautproblemen wende dich an eine '
      'dermatologische Praxis.';
  static const disclaimerFotos =
      'Deine Fotos werden ausschließlich zur Analyse an den KI-Dienst gesendet und dort '
      'nicht dauerhaft gespeichert. Auf deinem Gerät bleiben sie lokal.';
  static const disclaimerZustimmung = 'Ich habe die Hinweise gelesen und stimme zu.';
}
