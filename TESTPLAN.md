# Testplan Gerätematrix (Roadmap 4.4)

Bis hierher ist TrueGlow auf **einem** Gerät gelaufen: Samsung SM A525F,
6,5", 1080 × 2400, Android 13. Dort läuft der Hauptpfad automatisiert durch
(`integration_test/hauptpfad_test.dart`). Alles Übrige — kleine Displays,
Tablets, altes Android, große Systemschrift, TalkBack — ist ungeprüft.

Dieser Plan ist zum Abarbeiten gedacht. Jeder Punkt ist eine Anweisung, die
du ohne Rückfrage ausführen kannst, mit einem Kriterium daneben, das
entscheidet, ob es geklappt hat.

**Zeitbedarf:** etwa 20 Minuten je Gerät für Abschnitt 2, dazu einmalig
30 Minuten für Abschnitt 3 und 4 auf einem beliebigen Gerät.

---

## 0 · Vorbereitung

☐ **0.1 App im Demo-Modus bauen**

```bash
flutter run --dart-define=TRUEGLOW_MOCK=true
```

Der Demo-Modus braucht kein Firebase-Projekt, kostet nichts und liefert immer
dieselbe Beispiel-Analyse. Für alles außer Abschnitt 5 ist er die richtige
Wahl — auch weil die Ergebnisse dann vergleichbar sind.

☐ **0.2 Notizzettel anlegen**

Für jeden Fund: Gerät, Android-Version, Schritt, was passiert ist, Screenshot.
Ohne die Gerätekennung ist ein Fund später nicht mehr einzuordnen.

☐ **0.3 Automatischen Durchlauf laufen lassen** (spart Handarbeit)

```bash
flutter test integration_test --dart-define=TRUEGLOW_MOCK=true
```

Läuft der durch, ist der Hauptpfad auf diesem Gerät grundsätzlich in Ordnung.
Was er **nicht** prüft: Aussehen, Überläufe, Lesbarkeit, Kamera. Dafür ist
der Rest dieses Plans da.

---

## 1 · Geräte, die geprüft werden sollten

Nach abnehmender Wichtigkeit. Wenn du nur zwei zusätzliche Geräte auftreiben
kannst, nimm 1.1 und 1.2.

| # | Gerät | Warum |
|---|---|---|
| 1.1 | **Kleines Display**, ~5", 720 × 1280, Android 8–10 | Der wahrscheinlichste Ort für Überläufe. `minSdk 26` heißt Android 8 — Geräte dieser Klasse sind noch verbreitet. |
| 1.2 | **Schwache Hardware**, 2–3 GB RAM | Die Kamera mit Live-Gesichtserkennung ist der wahrscheinlichste Ort für Abstürze. |
| 1.3 | **Großes Display**, 6,7" | Zu viel Weißraum, verrutschte Anker. |
| 1.4 | **Tablet**, 10" | Die App ist auf Hochformat festgelegt (`SystemChrome.setPreferredOrientations`). Auf einem Tablet ist Querformat der Normalfall — der Punkt gehört geprüft, nicht angenommen. |
| 1.5 | **Aktuelles Android** (15/16) | Berechtigungsdialoge und der Splash haben sich zwischen den Versionen mehrfach geändert. |

> **Kein zweites Gerät zur Hand?** Der Android-Emulator deckt 1.1, 1.3, 1.4
> und 1.5 ab. Was er **nicht** ersetzt, ist 1.2: ML Kit und die
> Kamera-Pipeline verhalten sich auf echter, schwacher Hardware anders.
> Ein gebrauchtes Einsteigergerät für 40 € ist hier die bessere Investition
> als jede Emulator-Stunde.

---

## 2 · Der Durchgang, je Gerät

Immer mit frisch installierter App (`flutter run --uninstall-first`).

☐ **2.1 Onboarding**
Fünf Seiten durchklicken.
*Kriterium:* Auf keiner Seite wird etwas abgeschnitten, der „Weiter"-Knopf ist
immer erreichbar, die Einwilligungsseite lässt sich vollständig lesen und alle
drei Häkchen sind erreichbar.

☐ **2.2 Anmeldung**
„Erst ausprobieren".
*Kriterium:* Beide Knöpfe vollständig sichtbar, Text nicht umgebrochen mitten
im Wort.

☐ **2.3 Modulauswahl und Richtung**
Alle vier Zusatzmodule auswählen, bei „Deine Richtung" mehrere Chips setzen
und den Freitext füllen.
*Kriterium:* Die Chips brechen sauber um, das Textfeld schiebt sich über die
Tastatur, der Zeichenzähler stimmt.

☐ **2.4 Aufnahme-Flow**
Alle Schritte durchgehen, Fotos aus der **Galerie** wählen (Kamera kommt in
Abschnitt 3).
*Kriterium:* Die Schrittanzeige stimmt, abgelehnte Fotos zeigen einen
verständlichen Grund, „Zurück" verliert keine bereits gemachte Aufnahme.

☐ **2.5 Analyse und Report**
Analyse starten, Report vollständig durchscrollen.
*Kriterium:* Der Ladescreen läuft ohne Überlauf, „Abbrechen" ist erreichbar,
im Report ist kein Text abgeschnitten und keine Karte zerdrückt.

☐ **2.6 Plan und Serie**
Zwei Habits abhaken, App schließen, neu öffnen.
*Kriterium:* Die Haken sind noch da, die Serie steht auf 1, das Abzeichen
erscheint genau einmal.

☐ **2.7 Einstellungen**
Vollständig durchscrollen, „Rechtliches" öffnen.
*Kriterium:* Die Karte mit den Einwilligungen ist lesbar, die
Nachweiszeilen (Datum, Textstand) brechen sauber um.

☐ **2.8 Systemseitige Anzeige**
Android-Einstellungen → Apps → TrueGlow.
*Kriterium:* Name **TrueGlow**, eigenes Icon (kein Flutter-Logo), unter
Berechtigungen steht **kein Mikrofon**.

---

## 3 · Kamera auf schwacher Hardware

Der empfindlichste Teil der App. Nur auf echter Hardware sinnvoll — am besten
auf dem schwächsten Gerät, das du hast.

☐ **3.1 Sucher öffnen**
*Kriterium:* Die Vorschau steht innerhalb von zwei Sekunden. Länger heißt: Der
Ladezustand ist zwar da, aber die Wartezeit ist zu lang.

☐ **3.2 ML-Kit-Takt beobachten**
Gesicht ins Oval bringen und wieder heraus, mehrfach.
*Kriterium:* Die Hilfslinien reagieren spürbar, nicht mit Sekunden Verzug. Das
Bild ruckelt nicht sichtbar.

☐ **3.3 Erwärmung**
Sucher **drei Minuten** offen lassen.
*Kriterium:* Das Gerät wird warm, aber nicht heiß; die Vorschau bleibt flüssig;
die App stürzt nicht ab. Wenn Android die Kamera wegen Überhitzung schließt,
muss die App das abfangen und nicht abstürzen.

☐ **3.4 Ganzkörperfotos und Speicher**
Modul „Figur & Passform" wählen und beide Ganzkörperfotos mit der
**Rückkamera** aufnehmen (die liefert die größten Bilder).
*Kriterium:* Kein Absturz beim Verarbeiten. Der Qualitätscheck skaliert auf
1024 px — wenn das Gerät vorher stirbt, ist die Dekodierung des Originals das
Problem.

☐ **3.5 Speicherverlauf mitlesen** *(optional, aber aufschlussreich)*

```bash
flutter run --dart-define=TRUEGLOW_MOCK=true --profile
```

Im DevTools-Reiter *Memory* beim Aufnehmen zuschauen.
*Kriterium:* Der Verbrauch geht nach jedem Foto wieder herunter. Steigt er
Foto um Foto, wird eine Bilddatei nicht freigegeben.

☐ **3.6 Berechtigung verweigern**
App-Berechtigungen zurücksetzen, Kamera öffnen, Zugriff **ablehnen**.
*Kriterium:* Eigener Hinweisschirm mit Link in die Systemeinstellungen, und
der Weg über die Galerie bleibt offen. Keine leere schwarze Fläche.

---

## 4 · Bedienbarkeit

Einmal auf einem beliebigen Gerät, am besten einem kleinen.

☐ **4.1 Systemschrift auf 130 %**
Android-Einstellungen → Anzeige → Schriftgröße auf die größte Stufe.
Danach Abschnitt 2 noch einmal überfliegen.
*Kriterium:* Nichts wird abgeschnitten, keine gelb-schwarzen Überlaufstreifen,
Knöpfe bleiben tippbar. **Der Ladescreen und die Einwilligungsseite sind hier
die wahrscheinlichsten Kandidaten.**

☐ **4.2 Anzeigegröße auf „groß"**
Dieselbe Einstellungsseite, aber „Anzeigegröße" statt Schriftgröße — das
skaliert auch Abstände und trifft andere Stellen.

☐ **4.3 Dunkles und helles Schema**
Systemweit umschalten, App im Hintergrund lassen, zurückwechseln.
*Kriterium:* Die App folgt sofort, kein weißes Aufblitzen, der Splash beim
Kaltstart hat in beiden Schemata die richtige Farbe (Deep Teal dunkel, Mocha
hell).

☐ **4.4 Animationen reduzieren**
Entwickleroptionen → Animationsskalierungen auf **0,5x** oder **aus**.
*Kriterium:* Nichts hängt, kein Screen bleibt halb aufgebaut. Die Übergänge
zwischen Onboarding-Seiten und der Jubel-Overlay sind hier die Kandidaten.

☐ **4.5 TalkBack-Grundcheck**
Einstellungen → Bedienungshilfen → TalkBack einschalten. Dann:
Onboarding durchlaufen, ein Habit abhaken, in die Einstellungen und zurück.
*Kriterium:*
- Jeder Knopf wird vorgelesen und ist nicht nur „Schaltfläche"
- Die Häkchen sagen ihren Zustand („aktiviert" / „nicht aktiviert")
- Die Reihenfolge beim Durchwischen folgt der Leserichtung
- Man kommt aus jedem Screen wieder heraus

> TalkBack ist der Punkt, an dem am ehesten etwas fehlt — die App wurde nie
> daraufhin gebaut. Erwarte Funde und notiere sie; sie sind kein
> Veröffentlichungshindernis, aber der nächste sinnvolle Schritt danach.

☐ **4.6 Zurück-Geste**
Auf jedem Screen einmal die Wischgeste von links bzw. den Zurück-Knopf.
*Kriterium:* Nirgends verlässt man die App unerwartet, nirgends landet man in
einem Screen, aus dem der Weg zurück fehlt. Plan und Check-in fangen die Geste
ausdrücklich ab.

---

## 5 · Release-Build

Erst nachdem Abschnitt 2 bis 4 sauber sind, und mit echtem Firebase-Projekt.

☐ **5.1** Die zehn Schritte aus `SETUP.md`, Abschnitt 12.3.

Das ist der einzige Durchgang, in dem R8 aktiv ist — Fehler, die dort
auftreten, gibt es im Debug-Build nicht.

---

## 6 · Nach dem Umbau auf Anmeldung, Sprachwahl und Frauen-Modus

Diese sechs Punkte lassen sich nicht vom Rechner aus prüfen. Sie brauchen
entweder eine Abmeldung, eine echte Person vor der Kamera oder einen Blick
darauf, ob sich ein Satz gut liest.

1. **Erster Start wie ein neuer Nutzer.** In den Einstellungen ganz unten
   „Alle Daten löschen", dann App schließen und neu öffnen. Erwartet:
   Zeichen blendet auf, Schriftzug darunter, nach knapp zwei Sekunden von
   selbst der Anmelde-Bildschirm — kein Knopf zum Weitertippen. Oben rechts
   stehen DE und EN.

2. **Als Gast hinein.** „Erst mal umschauen" tippen. Erwartet: die
   Erklärseiten kommen jetzt **nach** der Anmeldung, nicht davor, und die
   letzte verlangt das Häkchen unter den Nutzungsbedingungen.

3. **Sprache auf dem Anmelde-Bildschirm.** Vor dem Anmelden auf EN tippen.
   Erwartet: Willkommenssatz, Knöpfe und Rechtstexte-Zeile wechseln sofort.
   Zurück auf DE.

4. **Geschlecht im Onboarding.** Im ersten Fragenblock „Weiblich" wählen und
   bis zur Modulauswahl durchgehen. Erwartet: „Make-up & Ausstrahlung" steht
   oben, „Bart" kommt nirgends vor.

5. **Weibliche Silhouette mit einer Frau davor.** Ganzkörper frontal und
   seitlich. Erwartet: Der Umriss passt zur Person, der Auto-Auslöser zählt
   herunter und löst aus. Die Proportionen sind gemessen, das Zusammenspiel
   mit einem echten Körper nicht.

6. **Ein echter Analyse-Durchlauf auf Englisch.** Sprache auf English,
   Analyse starten. Erwartet: Der ganze Report — Kapitel, Empfehlungen,
   Farbbeschreibungen — ist englisch und liest sich wie von einem Menschen
   geschrieben. Danach dasselbe im Frauen-Modus: Schnittempfehlungen nach
   Figurtyp, Farbpalette auch für Make-up, kein Wort über Bart.

## 7 · Der Report in beiden Sprachen und beiden Modi

**Voraussetzung: Die Cloud Functions müssen ausgerollt sein.** Ohne das läuft
auf dem Server die alte Fassung, und der Report kommt wieder auf Deutsch mit
Bart-Kapitel (siehe `DECISIONS.md` 35). Nachsehen mit:

```bash
firebase functions:list --json
```

Das Feld `source.storageSource.generation` ist ein Zeitstempel in
Mikrosekunden und muss jünger sein als der letzte Commit unter
`functions/src/`.

**Das Kontingent sind drei Analysen pro Tag** — genau so viele, wie dieser
Abschnitt braucht. Zurücksetzen geht in der Firebase-Konsole:

1. Authentication → Users → die eigene UID kopieren
2. Firestore → `users` → diese UID → `kontingent` → Dokument `analyse` löschen

Die Zähler stehen dort und werden nur serverseitig geschrieben; ein gelöschtes
Dokument zählt wieder bei null.

| # | Lauf | Worauf achten |
|---|---|---|
| 1 | **Englisch, männlicher Modus.** Sprache auf English, Personalisierung auf Männlich, Basis plus ein weiteres Modul. | Jedes Wort im Report englisch — Kapitel, Empfehlungen, Produktnamen und Produktbeschreibungen. Kopfzeile ganz englisch („today · 2 chapters · N recommendations"), Kapitelzahl passt zur Modulauswahl. Bart darf vorkommen. |
| 2 | **Englisch, weiblicher Modus, mit Make-up.** Personalisierung auf Weiblich, Module Gesicht & Haare plus Make-up & Ausstrahlung. | Das Make-up-Kapitel ist da. **Kein Bart**, keine Rasur, kein Barttrimmer — weder als Abschnitt noch in den Tagesaufgaben noch im Plan. Kapitelüberschrift heißt „Face & hair", nicht „Face, hair & beard". Alles englisch. |
| 3 | **Deutsch, Gegenprobe.** Sprache auf Deutsch, sonst wie Lauf 2. | Alles deutsch, Kopfzeile „heute · 2 Kapitel · N Empfehlungen". Sonst derselbe Inhalt wie in Lauf 2. |

Kommt in Lauf 1 oder 2 trotzdem etwas Deutsches, steht das ab jetzt auch in
den Server-Logs:

```bash
firebase functions:log --only analysiere
```

Zeilen, die mit `Nachbereitung:` anfangen, sagen, was das Modell falsch
geliefert hat und was der Server herausgefiltert hat.

## 8 · Nachprüfung: Abschnittsnamen und Produktkategorien

Nachtrag zu Abschnitt 7. Der erste Durchgang hat gezeigt, dass Kapitel-
überschriften und Fließtexte englisch waren, die Überschriften der
Unterabschnitte aber deutsch blieben.

| # | Lauf | Worauf achten |
|---|---|---|
| 1 | **Englisch, weiblicher Modus, mit Make-up.** | Die Unterabschnitte heißen „Hair", „Eyebrows", „Everyday look", „Colours" — nicht „Frisur", „Augenbrauen", „Alltags-Look", „Farben". Die kleinen Pillen an den Produkten heißen „Cleansing", „Care", „Styling", „Tools", „Make-up", „Clothing" — kein „Pflege", kein „Werkzeug". |
| 2 | **Danach ohne neue Analyse** in den Einstellungen auf Deutsch umstellen und denselben Report wieder öffnen. | Kapitelüberschriften und Produkt-Pillen wechseln auf Deutsch. Abschnittsüberschriften und Fließtexte bleiben englisch — das ist so gewollt, sie sind die eigenen Worte des Modells und ließen sich nur mit einem zweiten Durchlauf übersetzen. |
| 3 | **Deutsch, Gegenprobe.** Neue Analyse auf Deutsch. | Unterabschnitte heißen wieder „Frisur", „Augenbrauen", „Alltags-Look", „Farben". |

Ein alter Report von vorher zeigt seine Produktkategorie weiter so, wie sie
damals gespeichert wurde. Das ist Absicht — dort gibt es keine Kennung, auf
die sich das abbilden ließe.

## 9 · Gewohnheits-Ziele im Report

> **Erledigt und überholt.** Dieser Abschnitt war der erste Durchgang. Er
> hat funktioniert, aber am falschen Ort: Die Aufgaben landeten unter
> „Haare & Bart". Gültig ist jetzt **Abschnitt 11** — dort steht dieselbe
> Prüfung mit dem eigenen Kapitel. Abschnitt 9 bleibt nur als Beleg stehen.

Ein Analyse-Lauf reicht für beide Punkte — er kostet nur einmal Kontingent.

**Vorbereitung:** Bei „Deine Richtung" die anklickbaren Punkte wie gewohnt
wählen und ins Freitextfeld **zwei** Sätze schreiben, einen von jeder Sorte,
zum Beispiel: *„Ich will aufhören zu rauchen und hätte gern gepflegtere
Hände."*

1. **Der Report.** Erwartet: ein Abschnitt „Dein Ziel" (auf Englisch „Your
   goal") mit Auslöser-Strategien — konkrete Situationen wie Feierabend,
   Kaffee, Stress und für jede eine Alternative. Ton unterstützend, keine
   Heilaussagen, keine Zahlen zu Krankheitsrisiken, kein erhobener
   Zeigefinger.

2. **Die Tagesliste auf der Startseite.** Erwartet: Zwischen den Aufgaben
   stehen welche, die aus deinem Freitext kommen — je eine bis drei pro
   Wunsch. Sie müssen heute abhakbar sein und eine konkrete Handlung nennen,
   nicht „weniger rauchen". Auch der Wunsch nach gepflegteren Händen muss
   auftauchen, obwohl es dafür kein Kapitel gibt.

3. **Gegenprobe ohne Kontingent.** Eine ältere Analyse aus dem Verlauf
   öffnen. Erwartet: unverändert, kein Abschnitt „Dein Ziel", keine neuen
   Aufgaben.

## 10 · Die tägliche Erinnerung

Kostet kein Kontingent. Braucht aber Geduld — oder das Verstellen der
Uhrzeit.

1. **Nach dem Update einmal die App öffnen.** Erwartet: Android fragt einmal,
   ob TrueGlow Benachrichtigungen schicken darf. Erlauben.

2. **Einstellungen → Tägliche Erinnerung.** Erwartet: Schalter steht auf an,
   Uhrzeit auf 19:00. Auf eine Zeit in zwei, drei Minuten stellen.

3. **App verlassen und warten.** Erwartet: Zur eingestellten Zeit kommt
   „Dein Tagesziel — Heute noch nichts abgehakt …". Wichtig: **vorher an dem
   Tag noch nichts abhaken**, sonst kommt sie zu Recht nicht.

4. **Eine Aufgabe abhaken, Uhrzeit erneut auf gleich stellen, warten.**
   Erwartet: Es kommt **nichts**. Das ist der eigentliche Test — die
   Erinnerung soll nur kommen, wenn der Tag noch offen ist.

5. **Sprache auf English, Uhrzeit erneut stellen** (nachdem der Tag wieder
   offen ist, also am nächsten Tag oder nach dem Entfernen des Hakens).
   Erwartet: „Your daily goal — Nothing ticked off today …".

6. **Schalter aus, Uhrzeit stellen, warten.** Erwartet: nichts.

7. **Handy neu starten, Uhrzeit vorher auf ein paar Minuten später
   stellen.** Erwartet: Die Erinnerung kommt trotzdem. Das prüft die beiden
   Manifest-Einträge, die gefehlt haben — ohne sie überlebt kein Termin einen
   Neustart.

Wenn Punkt 1 ausbleibt, weil du die Berechtigung früher schon abgelehnt
hattest: In den Einstellungen den Schalter aus- und wieder einschalten — dann
fragt die App erneut. Blockiert das System weiterhin, steht ein Hinweis unter
der Karte.

## 11 · Persönliche Ziele als eigenes Kapitel

Ein einziger Analyse-Lauf reicht für den ganzen Abschnitt. Die Punkte 2 bis 6
kosten kein weiteres Kontingent.

**Vorbereitung:** Bei „Deine Richtung" die anklickbaren Punkte wie gewohnt
wählen und ins Freitextfeld **zwei** Sätze schreiben, einen von jeder Sorte —
zum Beispiel: *„Ich will aufhören zu rauchen und hätte gern gepflegtere
Hände."* Wichtig ist, dass mindestens ein Look-Modul dabei ist, bei dem der
Fehler vorher auftrat (Basis genügt).

1. **Die Tagesliste auf der Startseite.** Erwartet: Eine eigene Karte
   **„Deine Ziele"**, ganz unten, mit einem Fähnchen als Symbol. Darin
   stehen die Aufgaben aus deinem Freitext — je eine bis drei pro Wunsch,
   heute abhakbar. Beide Wünsche müssen vorkommen, auch der nach den Händen.

2. **Die Look-Karten darüber.** Erwartet: In **keiner** anderen Karte steht
   noch eine Aufgabe aus deinem Freitext. Unter „Haare & Bart" darf nichts
   mehr vom Rauchen stehen — genau das war der Fund. Auch nicht als
   Auffangposten in der Basis.

3. **Der Report.** Erwartet: Ein Kapitel **„Persönliche Ziele"** hinter den
   Look-Kapiteln, mit einer Einleitung in deinen eigenen Worten und einem
   Abschnitt **„Dein Ziel"** mit Auslöser-Strategien (Feierabend, Kaffee,
   Stress und für jede Situation eine Alternative). Der Wunsch nach
   gepflegteren Händen bekommt einen eigenen Abschnitt mit eigener
   Überschrift. Ton unterstützend, keine Heilaussagen, keine Zahlen zu
   Krankheitsrisiken, kein erhobener Zeigefinger.

4. **Sprache umstellen, ohne neue Analyse.** Einstellungen → English, dann
   denselben Report und dieselbe Startseite wieder öffnen. Erwartet: Die
   Karte heißt **„Your goals"**, das Kapitel **„Personal goals"**. Die Texte
   darin bleiben in der Sprache, in der sie erzeugt wurden — das ist so
   gewollt (Abschnitt 7, Punkt 2).

5. **Gegenprobe ohne Kontingent.** Eine ältere Analyse aus dem Verlauf
   öffnen. Erwartet: unverändert — kein Kapitel „Persönliche Ziele", keine
   neuen Aufgaben, keine neue Karte.

6. **Gegenprobe ohne Freitext.** Falls noch Kontingent übrig ist: eine
   Analyse mit leerem Freitextfeld. Erwartet: gar keine Ziel-Karte und kein
   Ziel-Kapitel, alles wie vor dem Update. Wenn kein Kontingent mehr da ist,
   reicht Punkt 5 — die Aussage ist dieselbe.

## 12 · Sind die Empfehlungen besser geworden?

Kein eigener Analyse-Lauf nötig: Das ist derselbe Report aus Abschnitt 11.
Diese Prüfung ist die einzige im Plan, die sich nicht an einem Häkchen
entscheidet, sondern am Lesen. Nimm dir dafür fünf Minuten.

1. **Der Bart-Test.** Geh die Tagesliste durch und such nach Aufgaben, deren
   Zeitpunkt keinen Sinn ergibt — etwas abends tun, das über Nacht wieder
   verschwindet, oder morgens etwas, das erst über Nacht wirken soll.
   Erwartet: keine einzige. Das war der Auslöser für die Änderung.

2. **Der Suchmaschinen-Test.** Nimm dir pro Kapitel die Empfehlungen vor und
   frag bei jeder: *Hätte das auch dann dagestanden, wenn er meine Fotos nie
   gesehen hätte?* Erwartet: In jedem Kapitel steht mindestens **eine**
   Empfehlung, bei der die Antwort klar Nein ist — weil sie ein Merkmal
   benennt (Wuchsrichtung der Haare, eine Stelle, an der der Bart dünner
   ist, die Form des Gesichts) oder einen Handgriff erklärt, den man nicht
   auf der ersten Suchergebnisseite findet.

3. **Der Wiederholungs-Test.** Erwartet: Keine Empfehlung und keine Aufgabe
   taucht in zwei Kapiteln in anderer Formulierung wieder auf.

4. **Notieren, was durchgerutscht ist.** Schreib die Zeilen auf, die den
   Test nicht bestehen, mit dem Kapitel dazu. Der Server zählt flache
   Aufgaben selbst mit und schreibt sie ins Protokoll — deine Notiz und das
   Protokoll zusammen sagen, ob es am Prompt liegt oder am Modell.

   Ins Protokoll sehen (optional, am Rechner):

   ```bash
   firebase functions:log --only analysiere --project trueglow-b2c1c
   ```

   Zeilen mit „ohne Bezug zu den Fotos" sind die gezählten flachen
   Aufgaben; „Kapitel persoenlicheZiele fehlt" hieße, dass der Freitext
   nirgends angekommen ist.

> **Nachtrag vom 26.08.2026:** Das Ergebnis war dünn — deshalb läuft die
> Analyse seitdem auf `gemini-3.7-flash`. Die Prüfungen oben bleiben genau
> so gültig; sie sind jetzt der Maßstab für das neue Modell. Wie du es
> zusammen mit dem Monatskontingent prüfst, steht in Abschnitt 13.

## 13 · Das neue Modell und das Monatskontingent

Dieser Abschnitt kostet **zwei** Analyse-Läufe, mehr nicht. Alles Übrige
prüfst du am Zähler und an der Uhr.

**Vorbereitung:** Kontingent zurücksetzen, damit du sauber zählen kannst —
wie das geht, steht in `SETUP.md` 6.6. Kurz: In der Firebase-Konsole unter
`users/<deine uid>/kontingent` das Dokument `analyse` löschen und im
Dokument `checkin` das Feld `freiZuletzt` löschen.

1. **Läuft das neue Modell überhaupt?** Eine ganz normale Analyse starten.
   Erwartet: Sie kommt durch. Sie darf spürbar länger dauern als bisher —
   das Modell denkt vor der Antwort. Bricht sie mit „Zeitüberschreitung" ab,
   ist das ein Blocker; notier dann, wie lange du gewartet hast.

2. **Steht das Modell in den Einstellungen?** Einstellungen aufrufen.
   Erwartet: `gemini-3.7-flash`. Steht dort noch `gemini-3.5-flash-lite`,
   läuft eine alte App-Fassung.

3. **Ist der Report besser geworden?** Denselben Report mit Abschnitt 12
   durchgehen — Bart-Test, Suchmaschinen-Test, Wiederholungs-Test. Das ist
   der eigentliche Zweck des Wechsels. Notier, was durchgerutscht ist.

4. **Was hat der Lauf gekostet?** Optional, am Rechner. Drei Stellen, je
   nachdem, was du wissen willst:

   - **Aufrufe und Fehlerquote** der Gemini-API:
     <https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/metrics?project=trueglow-b2c1c>
   - **Tokens je Schlüssel**, inklusive der Denk-Tokens:
     <https://aistudio.google.com/usage>
   - **Euro**, im Abrechnungsbericht des Projekts:
     <https://console.cloud.google.com/billing?project=trueglow-b2c1c> →
     „Berichte", dort nach Dienst filtern (`Generative Language API`).

   **Am schnellsten geht es über das Protokoll der Function.** Seit dem
   26.08.2026 schreibt jeder Aufruf eine Zeile wie „Verbrauch
   gemini-3.7-flash: Eingabe 13800, Ausgabe 4200, davon Denken 3100". Reine
   Zahlen, kein Analysetext:

   ```bash
   firebase functions:log --only analysiere --project trueglow-b2c1c
   ```

   Rechnung dazu: Eingabe × 0,75 $ / 1 Mio. plus (Ausgabe + Denken) ×
   3,75 $ / 1 Mio. Interessant ist die Zahl der Denk-Tokens — davon hängt
   ab, ob wir bei 3 oder bei 5 Cent je Analyse liegen (`DECISIONS.md` 41).
   Die Abrechnung in der Konsole hinkt ein paar Stunden hinterher; die
   Token-Zahlen stehen sofort da.

5. **Der Zähler in der App.** Modul-Auswahl öffnen. Erwartet: „Noch 2 von 3
   Analysen heute". Der Monatszähler steht dort nicht — er meldet sich erst,
   wenn er greift.

6. **Die Monatsgrenze.** Ohne zehn Analysen zu verbrauchen: In der
   Firebase-Konsole im Dokument `users/<uid>/kontingent/analyse` das Feld
   `monatZaehler` auf **10** setzen und sicherstellen, dass `monat` auf dem
   laufenden Monat steht (`2026-08`). Dann die App neu öffnen und die
   Modul-Auswahl aufrufen. Erwartet: Die Karte **„Diesen Monat keine Analyse
   mehr frei"** mit dem Hinweis, dass am Ersten wieder zehn da sind und dass
   die Check-ins weiterlaufen. Der Startknopf ist grau.

7. **Dasselbe auf Englisch.** Einstellungen → English, zurück zur
   Modul-Auswahl. Erwartet: „No analyses left this month", derselbe Sinn,
   kein deutsches Wort darin.

8. **Der Check-in geht trotzdem.** Mit weiterhin vollem Monatszähler (also
   gesperrter Analyse) einen fälligen Check-in durchführen. Erwartet: Er
   läuft durch und ändert den Plan. Genau das ist der Punkt der ganzen
   Änderung — die App darf dich nicht mit deinem eigenen Kontingent
   erinnern.

   Ist gerade keiner fällig, lässt er sich vorziehen: Im Dokument
   `users/<uid>/kontingent/checkin` das Feld `freiZuletzt` löschen und in der
   App den Check-in aus der Karte auf der Startseite starten.

9. **Der zweite Check-in am selben Tag ist nicht frei.** Direkt nach Punkt 8
   noch einen Check-in starten, ohne irgendetwas zurückzusetzen. Erwartet:
   Er läuft ebenfalls durch — geht aber diesmal auf das Analyse-Kontingent.
   Nachzusehen im Dokument `analyse`: `monatZaehler` ist um eins gestiegen.
   Bei gesperrtem Monat (Punkt 6) kommt stattdessen die Kontingent-Meldung.
   Beides ist richtig: Der freie Check-in gilt einmal pro Woche, nicht
   beliebig oft.

10. **Zurücksetzen nicht vergessen.** Nach dem Test das Dokument `analyse`
    wieder löschen, sonst bleibt dein Zähler auf 10 stehen.

## 14 · Der Streak-Joker

Kostet kein Kontingent und keinen Analyse-Lauf. Am schnellsten geht es im
Demo-Modus (`flutter run --dart-define=TRUEGLOW_MOCK=true`), weil dort sofort
ein Plan mit Tagesaufgaben dasteht.

1. **Der Vorrat ist sichtbar.** Startseite öffnen. Erwartet: Rechts an der
   Serien-Karte stehen **zwei kleine Schilde** und darunter „2/2". Lange
   drauftippen zeigt den Hinweis „Joker: 2 pro Monat …".

2. **Eine Aufgabe abhaken.** Erwartet: Die Flamme leuchtet auf, die Serie
   steht auf 1, die Schilde bleiben bei 2/2. Ein Joker wird für heute nie
   verbraucht — der Tag ist ja noch offen.

3. **Einen Tag überspringen.** Das Handy einen Tag vorstellen (Einstellungen
   → Datum & Uhrzeit, automatische Zeit aus), die App öffnen und **nichts**
   abhaken. Wieder einen Tag vorstellen und dann eine Aufgabe abhaken.
   Erwartet: Die Serie steht auf **2**, nicht auf 1 — der übersprungene Tag
   wurde überbrückt. Auf der Karte steht „Ein Joker hat deinen Streak
   gerettet.", und die Schilde stehen auf **1/2**.

4. **Der Hinweis kommt nur einmal.** App verlassen und neu öffnen. Erwartet:
   Der Satz „Ein Joker hat deinen Streak gerettet." ist weg, die Schilde
   stehen weiter auf 1/2, die Serie bleibt bei 2.

5. **Der zweite Joker.** Punkt 3 noch einmal. Erwartet: Serie 3, Schilde
   0/2, Hinweis wieder da.

6. **Der dritte verpasste Tag reißt die Serie.** Punkt 3 ein drittes Mal.
   Erwartet: Die Serie steht auf **1** (nur der heutige Tag), und auf der
   Karte steht **nicht** „0 Tage" mit einem Vorwurf, sondern die Serie
   beginnt neu. Darunter steht „Längste Serie: 3 Tage".

7. **Der Neustart-Ton.** Datum einen Tag weiter, App öffnen und **nichts**
   abhaken. Erwartet: Die Serie steht auf 0 und die Karte sagt „Neustart —
   dein längster Streak bleibt dir erhalten." Kein „leider", kein
   Ausrufezeichen, keine rote Farbe.

8. **Monatswechsel füllt auf.** Das Datum auf den 1. des nächsten Monats
   stellen und die App öffnen. Erwartet: Die Schilde stehen wieder auf
   **2/2**.

9. **Englisch.** Einstellungen → English, Startseite. Erwartet: „A joker
   saved your streak.", „Longest streak: 3 days", „Fresh start — your longest
   streak stays with you." Kein deutsches Wort.

> **Danach das Datum wieder auf automatisch stellen.** Die abgehakten Tage
> aus dem Test bleiben gespeichert; wenn dich das stört, in den Einstellungen
> „Alle Daten löschen".

## 15 · Wenn-dann-Anker in den Tagesaufgaben

**Der einzige Abschnitt in diesem Paket, der einen Analyse-Lauf kostet.** Ein
Lauf reicht für alles hier.

**Vorbereitung:** Eine normale Analyse starten. Am aussagekräftigsten mit
mehreren Modulen und einem Freitext bei „Deine Richtung" — dann lässt sich
Punkt 4 gleich mitprüfen.

1. **Die Form.** Tagesliste auf der Startseite öffnen. Erwartet: **Jede**
   Aufgabe nennt zuerst einen Auslöser, dann einen Doppelpunkt, dann die
   Handlung — etwa „Nach dem Zähneputzen: …" oder „Vor dem Schlafengehen:
   …". Eine Aufgabe ohne Doppelpunkt ist ein Fund.

2. **Die Auslöser sind Routinen, keine Uhrzeiten.** Erwartet: Kein „um 7
   Uhr", kein „regelmäßig", kein „täglich", kein „wenn du Zeit hast". Solche
   Formulierungen sind der Fund, den diese Änderung verhindern soll.

3. **Kein Stau an einem Anker.** Alle Aufgaben durchzählen. Erwartet:
   Derselbe Auslöser steht höchstens zweimal im ganzen Plan. Fünf Aufgaben
   nach dem Zähneputzen wären ein Fund.

4. **Der Auslöser passt zum Zweck.** Erwartet: Was über Nacht wirken soll
   (Pflege mit Einwirkzeit), hängt an einem Abend-Anker; was den Tag über
   halten soll (Styling), an einem Morgen-Anker. Das ist der Bart-Test aus
   Abschnitt 12 in neuer Form.

5. **Auch die persönlichen Ziele haben einen Anker.** Nur wenn du einen
   Freitext geschrieben hast. Erwartet: In der Karte „Deine Ziele" steht der
   Auslöser als Situation — „Bei Rauchverlangen: …", „Nach dem Essen: …" —
   und nicht als Alltagsroutine. Beides ist richtig, solange die Form stimmt.

6. **Englisch, ohne neuen Lauf.** Das geht **nicht** ohne zweiten Lauf: Die
   Aufgabentexte sind die Worte des Modells und werden nicht nachträglich
   übersetzt (Abschnitt 7, Punkt 2). Wenn du noch Kontingent übrig hast:
   Sprache auf English stellen, eine neue Analyse laufen lassen. Erwartet:
   „After brushing your teeth: …", „Before bed: …" — **kein** deutscher Anker
   im englischen Plan. Das ist der teuerste Fehler dieser Änderung; wenn du
   nur einen Lauf übrig hast, mach ihn auf Englisch.

7. **Die Zeilen laufen nicht über.** Erwartet: Längere Aufgaben brechen in
   der Checkliste sauber auf zwei Zeilen um, nichts ist abgeschnitten. Prüf
   das auch mit großer Systemschrift (Abschnitt 4).

## 16 · Der Moment nach dem ersten Haken

Kein Kontingent, kein Analyse-Lauf. Im Demo-Modus in einer Minute geprüft.

1. **Vor dem ersten Haken.** Startseite öffnen. Erwartet: Die Flamme ist
   gedimmt, unter der Zahl steht „Heute noch nichts abgehakt …". Keine
   Bestätigung.

2. **Ersten Punkt abhaken.** Erwartet: Die Flamme flackert kurz auf, und
   direkt darunter erscheint ein grüner Streifen: **„Tag gesichert!"** mit
   dem Stand der Serie darunter. Kein Vollbild, kein Knopf, nichts zum
   Wegklicken.

3. **Warten.** Erwartet: Nach etwa fünf Sekunden blendet sich der Streifen
   von selbst aus. Die Karte rückt dabei ruhig zusammen, sie springt nicht.

4. **Zweiten Punkt abhaken.** Erwartet: **Nichts** passiert — kein zweiter
   Streifen. Gefeiert wird der Tag, nicht jeder Haken.

5. **Bildschirm wechseln und zurück.** Zum Plan und zurück zur Startseite.
   Erwartet: Der Streifen kommt nicht erneut.

6. **Haken wieder entfernen und neu setzen.** Erwartet: Der Streifen kommt
   wieder — der Tag war zwischendurch offen. Das ist gewollt und lässt sich
   nur von Hand herbeiführen.

7. **Mit „Bewegung reduzieren".** In den Android-Einstellungen unter
   Bedienungshilfen „Animationen entfernen" einschalten, App neu starten,
   abhaken. Erwartet: Der Streifen ist da, erscheint aber ohne Bewegung.

8. **Mit TalkBack.** Erwartet: Beim Erscheinen wird „Tag gesichert!"
   einmal vorgelesen, ohne dass man hinnavigieren muss.

9. **Englisch.** Erwartet: „Day secured!" und „That makes 2 days in a row."

## 17 · Der Wochen-Rückblick

Kein Kontingent, kein Analyse-Lauf. Braucht aber das Verstellen des Datums.

1. **Vorbereitung: eine Woche füllen.** Im Demo-Modus an drei bis vier Tagen
   der laufenden Woche Haken setzen — Datum jeweils einen Tag vorstellen,
   abhaken, weiterstellen. Merk dir, in welchem Kapitel du am meisten
   abgehakt hast.

2. **Vor Sonntagabend.** Datum auf einen Samstag stellen, App öffnen.
   Erwartet: **Keine** Rückblick-Karte.

3. **Sonntag, 17 Uhr.** Erwartet: Immer noch keine Karte.

4. **Sonntag, 19 Uhr.** Erwartet: Zwischen Check-in-Karte und Serie steht
   **„Deine Woche"** mit dem Zeitraum Montag bis Sonntag, den aktiven Tagen
   („4 von 7 Tagen aktiv"), der Zahl der Aufgaben und „Dein stärkster
   Bereich: …". Der Bereich muss zu dem passen, den du dir gemerkt hast.

5. **Der Ton passt zur Woche.** Bei 5 bis 7 aktiven Tagen: „Starke Woche…".
   Bei 3 bis 4: „Solide Woche…". Bei 2: „Zwei Tage sind zwei mehr als
   keiner." Bei 0 oder 1: „Neue Woche, neue Chance – ein Haken reicht für den
   Anfang." Erwartet in **allen** Fällen: kein „leider", kein Vorwurf, keine
   Prozentzahl.

6. **Die leere Woche.** In den Einstellungen alle Daten löschen, neue
   Analyse im Demo-Modus, Datum auf Sonntagabend. Erwartet: „0 von 7 Tagen
   aktiv", „0 Aufgaben abgehakt", **keine** Zeile „Dein stärkster Bereich",
   und der Einladungs-Ton.

7. **Montag.** Datum auf Montag stellen. Erwartet: Die Karte steht noch da
   und zeigt **dieselbe** Woche wie am Sonntag — nicht die neue.

8. **Dienstag.** Erwartet: Die Karte ist weg.

9. **Wegklicken.** Zurück auf Sonntagabend, Karte über das X schließen.
   Erwartet: Sie ist weg und kommt auch nach einem Neustart der App nicht
   wieder. Erst der nächste Sonntag bringt den nächsten Rückblick.

10. **Keine Benachrichtigung.** Erwartet: Zum Rückblick kommt **keine**
    Push. Das ist Absicht — Begründung in `DECISIONS.md` 46.

11. **Englisch.** Erwartet: „Your week", „active on 4 of 7 days", „Your
    strongest area: …", „Solid week. The groundwork is there."

## 18 · Die Wochen-Challenge

Kein Kontingent, kein Analyse-Lauf. Braucht das Verstellen des Datums.

1. **Die Karte ist da.** Startseite im Demo-Modus öffnen. Erwartet: Unter
   der Serien-Karte steht **„Challenge der Woche"** mit einem Satz, einem
   Balken und dem Stand rechts oben („0 von 3").

2. **Der Balken bewegt sich.** Einen Punkt abhaken. Erwartet: Der Stand
   steigt, der Balken wächst. Bei einer Challenge, die volle Tage verlangt,
   springt er erst, wenn die komplette Liste steht.

3. **Geschafft.** Die Challenge der Woche erfüllen (notfalls über das
   Datum: einen Tag vorstellen, abhaken, wiederholen). Erwartet: Rechts oben
   steht **„Geschafft!"** mit grünem Haken, der Balken ist voll.

4. **Ein Haken zurück nimmt sie nicht weg.** Einen Punkt wieder abwählen.
   Erwartet: „Geschafft!" bleibt stehen. Was einmal erreicht war, bleibt
   erreicht.

5. **Nächste Woche, andere Challenge.** Datum eine Woche vorstellen.
   Erwartet: Ein **anderer** Challenge-Text, Stand wieder bei 0. Kein
   „leider verpasst", kein Hinweis auf die alte Woche.

6. **Der Vorrat wiederholt sich nicht so schnell.** Das Datum zehnmal um je
   eine Woche vorstellen und die Texte mitschreiben. Erwartet: zehn
   verschiedene Challenges, danach fängt es wieder von vorn an.

7. **Das Abzeichen.** Vier Challenges schaffen (am schnellsten über das
   Datum, mit der jeweils leichtesten). Erwartet: In der Abzeichen-Liste
   steht **„Vier Wochen, vier Ziele"** als erreicht. Vorher steht darunter
   „noch 2 Challenges" oder Ähnliches.

8. **Englisch.** Erwartet: „This week's challenge", „Be active on 3 days —
   one tick is enough.", „2 of 3", „Done!", „Four weeks, four goals".

9. **Ohne Plan.** In den Einstellungen alle Daten löschen, App öffnen.
   Erwartet: Ohne Analyse gibt es keine Startseite mit Karten — die Challenge
   erscheint erst mit dem ersten Plan.

## 19 · Fortschritts-Fotos

Kein Kontingent. Braucht einen fälligen Check-in — der lässt sich über das
Datum herbeiführen (Handy um acht Tage vorstellen, App öffnen).

1. **Das Foto kommt bei jedem Check-in.** Den ersten Check-in (Tag 7,
   „Alltags-Check") durchlaufen. Erwartet: Nach den Bewertungen kommt ein
   Schritt **„Fortschrittsfoto"** mit dem Knopf zum Aufnehmen und darunter
   „Ohne Foto weiter". Früher gab es diesen Schritt erst am
   Tag 30.

2. **Überspringen geht.** Ohne Foto auf „Weiter". Erwartet: Der Check-in
   läuft normal zu Ende.

3. **Ein Foto aufnehmen.** Nächsten Check-in fällig machen, diesmal ein Foto
   aufnehmen. Erwartet: Beim **ersten** Foto überhaupt erscheint einmalig
   ein Hinweis-Dialog **„Diese Fotos bleiben auf diesem Gerät"**. Er nennt
   ausdrücklich: nicht in der Galerie, nicht im Google-Backup, nicht auf dem
   Server — und dass sie beim Handywechsel weg sind.

4. **Nicht in der Galerie.** Die Galerie-App öffnen und nachsehen. Erwartet:
   Das Foto taucht dort **nicht** auf. Das ist der wichtigste Punkt dieses
   Abschnitts.

5. **Der Einstieg.** Auf den Plan-Bildschirm gehen. Erwartet: Unter der
   Serien-Karte steht **„Deine Fortschritts-Fotos"** mit einer Miniatur und
   der Zahl der Fotos. Antippen führt ins Album.

6. **Mit einem Foto.** Erwartet: Das Bild groß, darunter „Der Anfang steht —
   ab dem zweiten Foto siehst du hier den Vergleich."

7. **Ab dem zweiten Foto.** Noch einen Check-in mit Foto machen. Erwartet:
   Oben ein **Schieberegler**; links das ältere, rechts das neuere Bild, in
   den Ecken „VORHER" und „NACHHER", darunter beide Daten. Der Regler
   schiebt die Trennlinie sauber durch.

8. **Die Zeitleiste.** Erwartet: Darunter eine waagerechte Reihe aller Fotos
   mit Datum, ältestes links, das erste beschriftet mit **„Start"**. Ein
   Antippen wählt aus, welches rechts im Vergleich steht — der Rahmen wird
   farbig.

9. **Löschen.** Ein Foto in der Zeitleiste **lange drücken**. Erwartet: Die
   Rückfrage „Foto löschen?" mit dem Hinweis, dass die Check-in-Antworten
   bleiben. Nach dem Bestätigen ist das Bild weg — aus der Zeitleiste und
   von der Platte.

10. **Das Startfoto ist geschützt.** Das erste Foto lange drücken. Erwartet:
    **Keine** Rückfrage, es passiert nichts. Es gehört zur Analyse.

11. **Der Bildvergleich beim Wirkungs-Check.** Am Tag 30 einen Check-in mit
    Foto abschließen. Erwartet: Das Zwischenfazit nimmt erkennbar auf den
    **Vergleich mit dem Startfoto** Bezug — „im Vergleich zu deinem ersten
    Foto wirkt …". Dafür gehen Start- und aktuelles Foto durch unsere Cloud
    Function an das Modell; gespeichert wird dort keins (`DECISIONS.md` 48).

12. **Die anderen Check-ins schicken nichts.** Am Tag 7 und Tag 14 mit Foto
    abschließen. Erwartet: Der Check-in passt den Plan an, es gibt aber
    **kein** Zwischenfazit — und damit auch keinen Grund, Bilder zu
    schicken. Das Foto steht trotzdem im Album.

13. **Ohne Foto-Einwilligung.** In den Einstellungen die Einwilligung zur
    Foto-Analyse zurückziehen und einen Wirkungs-Check abschließen.
    Erwartet: Der Check-in läuft durch und passt den Plan an, das
    Zwischenfazit fällt weg oder kommt ohne Bildbezug. Kein Fehler, kein
    Abbruch.

14. **Englisch.** Erwartet: „Your progress photos", „Before"/„After", „Drag
    the slider to compare.", „These photos stay on this device", „Delete
    photo?".

> **Was dieser Abschnitt nicht prüfen kann:** dass die Bilder nicht in
> Googles Backup wandern. Das entscheidet sich im Manifest, und dort besteht
> seit diesem Paket ein Test darauf (`fortschritts_fotos_test.dart`).

## 20 · Der Start und die neue Optik

Kein Kontingent, kein Analyse-Lauf. Im Demo-Modus in zehn Minuten
durchgesehen. Dieser Abschnitt entscheidet sich am Hinsehen, nicht an einem
Häkchen — nimm dir die Zeit dafür.

### Der Start

1. **Kaltstart.** App über den Task-Manager komplett schließen, dann vom
   Startbildschirm öffnen. Erwartet: **Ein** durchgehender Start — das
   Zeichen erscheint, bleibt an derselben Stelle stehen, und der Schriftzug
   „TrueGlow" kommt darunter dazu. Kein zweites Aufblenden, kein Sprung des
   Zeichens nach oben, kein weißes oder schwarzes Aufblitzen dazwischen.

2. **Mehrfach hintereinander.** Punkt 1 fünfmal wiederholen. Erwartet:
   jedes Mal gleich. Ein Ruck, der nur beim ersten Start nach der
   Installation auftritt, ist trotzdem ein Fund — notier ihn.

3. **Flugmodus an.** Erwartet: Der Start dauert länger (Firebase wartet),
   sieht aber genauso aus. Der Startbildschirm darf nicht hängen bleiben.

### Die Optik

4. **Der Hintergrund.** Startseite ganz nach oben und ganz nach unten
   scrollen. Erwartet: Oben Deep Teal, unten spürbar tiefer, fast
   schwarzblau. Der Übergang ist weich — man soll ihn spüren, nicht als
   Farbverlauf erkennen. Kein Streifen, keine Kante.

5. **Auf anderen Seiten.** Zum Plan, zum Verlauf, in die Einstellungen.
   Erwartet: derselbe Verlauf. Er gilt auf allen Seiten — Absicht, damit der
   Grund beim Wechseln nicht springt.

6. **Die Karten.** Erwartet: eine Spur heller als der Grund, weich
   abgerundet, mit einer sehr dünnen hellen Linie am Rand. **Kein**
   Schlagschatten. Der Verlauf schimmert leicht durch.

7. **Das Gold — wo es steht.** Erwartet, und nur dort:
   - die Streak-Flamme und die große Zahl, **sobald heute etwas abgehakt ist**
   - die zwei Joker-Schilde
   - gesetzte Haken in den Checklisten
   - gefüllte Segmente der Challenge
   - freigeschaltete Abzeichen

8. **Das Gold — wo es nicht stehen darf.** Erwartet: Buttons, Überschriften,
   die kleinen Icons in den Kartentiteln und der „Neu ab heute"-Marker
   bleiben im bisherigen Sandton. Findest du Gold an einer anderen Stelle als
   in Punkt 7, ist das ein Fund.

9. **Gold heißt fertig, nicht halb fertig.** Vor dem ersten Haken des Tages:
   Erwartet: Flamme **grau**, Checklisten-Zähler grau. Nach dem ersten
   Haken: Flamme golden. Erst wenn eine Checkliste **komplett** abgehakt ist,
   wird ihr Zähler („4/4") golden.

10. **Die Streak-Karte.** Erwartet: Die Flamme ist deutlich größer als
    vorher, hinter ihr liegt ein weicher Schein — nur bei gesichertem Tag.
    Die Zahl ist deutlich größer und fett. Der Schein darf nicht als Ring
    oder harte Kante zu sehen sein.

11. **Die Challenge-Karte.** Erwartet: Statt eines Balkens mehrere Segmente.
    Bei „Sei an 3 Tagen aktiv" sind es drei, bei „4 Tage in Folge" vier. Bei
    „15 Aufgaben" sind es fünf — jedes steht dann für drei Aufgaben. Gefüllte
    Segmente golden, leere blass.

12. **Die Abzeichen.** Erwartet: eine waagerechte Reihe zum Wischen.
    Freigeschaltete golden, gesperrte grau mit kleinem Schloss unten rechts,
    darunter weiterhin „noch 3 Tage" bzw. „noch 2 Module". Langes Drücken auf
    ein Abzeichen zeigt seine Beschreibung.

### Die Bewegungen

13. **Haken setzen.** Erwartet: Der Haken zoomt einmal kurz auf und wieder
    zurück. Unter einer halben Sekunde. Beim **Entfernen** passiert nichts —
    gefeiert wird das Abhaken.

14. **Seite öffnen.** Startseite verlassen und zurückkommen. Erwartet: Die
    Challenge-Segmente füllen sich von links nach rechts nacheinander, die
    Streak-Zahl zählt einmal kurz hoch. Beides ist nach einem Wimpernschlag
    vorbei.

15. **Nichts blinkt dauerhaft.** Die Startseite eine Minute offen liegen
    lassen und hinsehen. Erwartet: völlige Ruhe. Nichts pulsiert, nichts
    flackert, nichts läuft im Kreis.

16. **Mit „Bewegung reduzieren".** Android-Einstellungen → Bedienungshilfen →
    „Animationen entfernen". App neu starten. Erwartet: Alles steht sofort
    da — Zahl, Segmente, Haken. Nichts fehlt, nichts ist unsichtbar.

### Gegenproben

17. **Helles Schema.** Einstellungen → Hell. Erwartet: Der Verlauf ist auch
    dort da, nur viel dezenter. Das Gold ist ein dunkles Amber und deutlich
    vom Mocha-Braun der Buttons zu unterscheiden. Alle Texte bleiben lesbar.

18. **Große Systemschrift.** Schriftgröße auf das Maximum. Erwartet: Die
    Abzeichen-Reihe und die Segmente laufen nicht über; Abzeichen-Titel
    dürfen abgeschnitten werden (zwei Zeilen mit „…"), nichts anderes.

19. **TalkBack.** Erwartet: Der Fortschritt der Challenge wird als „3 von 4"
    vorgelesen, die Abzeichen-Beschreibungen werden mitgelesen. Die
    Bewegungen ändern daran nichts.

> **Wenn das Design nicht gefällt:** Es hängt an genau einem Commit
> („Design: …"). Der Splash-Umbau steckt in einem eigenen davor und bleibt
> stehen, wenn das Design zurückgedreht wird.

## 21 · Der Start und die Farben auf den Unterseiten

Kein Kontingent, kein Analyse-Lauf. Zwei getrennte Teile, passend zu den
zwei Commits.

### A · Die Farben auf den Unterseiten

1. **Analyse zusammenstellen.** Startseite → „Neue Analyse". Erwartet: Die
   Modul-Karten sehen aus wie die Karten der Startseite — leicht
   durchscheinend, weich gerundet, mit einer sehr dünnen hellen Linie am
   Rand. Kein kräftiger Rahmen, kein Schatten.

2. **Ein Modul antippen.** Erwartet: Der Rahmen der Karte und das Häkchen
   rechts werden **golden**, die Karte hinterlegt sich ganz leicht golden.
   Vorher war beides sandfarben.

3. **Der Knopf unten.** Erwartet: „Basis + 2 Module" ist weiterhin
   sandfarben — er ist ein Angebot, kein Erreichtes. Seine Ecken sind aber
   etwas weicher als vorher, damit er unter den runden Karten nicht kantig
   wirkt.

4. **Deine Richtung.** Erwartet: Die anklickbaren Punkte werden im
   ausgewählten Zustand golden (Rahmen und Schrift), nicht ausgewählt bleiben
   sie ruhig.

5. **Der Foto-Flow.** Erwartet: Die Punktereihe oben färbt die
   zurückgelegten Schritte golden. Ein bereits aufgenommenes Foto bekommt
   einen goldenen Rahmen und den goldenen Haken „Foto geprüft"; der gerade
   offene Schritt bleibt sandfarben.

6. **Der Check-in.** Erwartet: Die Antwortknöpfe („Läuft gut" / „Geht so" /
   „Passt nicht") werden im gewählten Zustand golden, ebenso die
   Wirkungsfragen und die Schritt-Punkte oben.

7. **Das Foto-Album.** Erwartet: Das gewählte Bild in der Zeitleiste hat
   einen goldenen Rahmen und ein goldenes Datum.

8. **Einstellungen.** Erwartet: Der Umschalter „Hell / Dunkel / System"
   hinterlegt die aktive Wahl golden. Schalter und Checkboxen ebenfalls.

9. **Onboarding.** (Nur wenn du alle Daten löschst.) Erwartet: gewählte
   Antworten golden, die Punktereihe unten ebenso.

10. **Nichts anderes ist golden.** Geh die Bildschirme noch einmal durch.
    Erwartet: Überschriften, die kleinen Icons in den Kartentiteln, Knöpfe
    und Hinweistexte sind **nicht** golden. Findest du Gold an einer Stelle,
    die weder „ausgewählt" noch „erledigt" bedeutet, ist das ein Fund.

11. **Helles Schema.** Einstellungen → Hell, dann Punkte 1 bis 9 im
    Schnelldurchlauf. Erwartet: dasselbe Bild in dunklem Amber statt hellem
    Gold, alle Texte lesbar.

### B · Der Start

12. **Kaltstart.** App über den Task-Manager schließen, vom Startbildschirm
    öffnen. Erwartet: **Ein** durchgehender Start. Das Zeichen erscheint,
    bleibt an genau derselben Stelle und in genau derselben Größe stehen, und
    der Schriftzug „TrueGlow" kommt darunter dazu. Kein Springen, kein
    Größenwechsel, kein zweites Aufblenden.

13. **Die Farbe.** Erwartet: Der Start ist von Anfang an dunkel — nicht das
    frühere flache Türkis. Sobald der eigene Startbildschirm übernimmt,
    bekommt der Hintergrund seine Tiefe (oben etwas heller, unten dunkler).
    Am Zeichen selbst ändert sich die Farbe nicht.

14. **Der Wechsel auf die Startseite.** Erwartet: **Kein** Farbsprung. Der
    Hintergrund ist derselbe, es kommen nur die Karten dazu.

15. **Mehrfach hintereinander.** Punkt 12 fünfmal wiederholen. Erwartet:
    jedes Mal gleich.

16. **Mit Gesten-Navigation.** In den Android-Einstellungen von den drei
    Tasten auf Wischgesten umstellen und Punkt 12 wiederholen. Erwartet:
    Das Zeichen steht weiterhin still. (Der Ausgleich rechnet mit der
    tatsächlichen Höhe der Navigationsleiste; bei Gesten ist sie kleiner.)

17. **Im hellen Systemschema.** Handy auf helles Design stellen, Punkt 12.
    Erwartet: Der Start bleibt dunkel — das ist Absicht, die App startet in
    ihrem eigenen dunklen Schema.

18. **Flugmodus.** Erwartet: Der Start dauert länger, sieht aber genauso
    aus, und bleibt nicht hängen.

> **Wenn etwas nicht stimmt:** Beide Teile hängen an je einem Commit
> („Design auf den Unterseiten…" und „Start: gemessen statt geschätzt"). Jeder
> lässt sich einzeln zurückdrehen, ohne den anderen mitzunehmen.

## 22 · Der Start ohne Schnitt

Kein Kontingent, kein Analyse-Lauf. Am besten mit einer Bildschirmaufnahme —
was hier zu sehen sein soll, dauert eine halbe Sekunde.

1. **Kaltstart.** App über den Task-Manager schließen, vom Startbildschirm
   öffnen. Erwartet, in dieser Reihenfolge:
   - Zuerst steht das Zeichen auf einer **gleichmäßig dunklen** Fläche.
   - Dann **bleibt es stehen**, während der Hintergrund weich Tiefe bekommt:
     oben etwas heller, unten dunkler.
   - Kurz danach **glüht der Name auf** — er kommt warm herein und wird hell.
   - Kein Bild, in dem sich mehrere Dinge gleichzeitig schlagartig ändern.

2. **Der frühere Fund.** Erwartet: **Nicht** mehr der harte Schnitt, bei dem
   Hintergrund und Schriftzug in einem Bild zusammen umspringen.

3. **Der Wechsel auf die Startseite.** Erwartet: kein Farbsprung. Der
   Hintergrund ist derselbe, es kommen nur die Karten dazu.

4. **Mehrfach hintereinander.** Punkt 1 fünfmal wiederholen. Erwartet: jedes
   Mal gleich, auch beim allerersten Start nach dem Update.

5. **Mit „Bewegung reduzieren".** Android-Einstellungen → Bedienungshilfen →
   „Animationen entfernen". Erwartet: Das Bild steht sofort fertig da,
   inklusive Name. Der Wechsel ist dann hart — das ist genau die Einstellung,
   die darum bittet.

6. **Mit Gesten-Navigation statt drei Tasten.** Erwartet: Das Zeichen steht
   weiterhin still; die App rechnet die Höhe der Navigationsleiste selbst aus.

7. **Flugmodus.** Erwartet: Der Start dauert länger — er wartet auf
   Firebase —, sieht aber genauso aus und bleibt nicht hängen.

> **Wenn du selbst nachmessen willst:** Bildschirmaufnahme machen, dann
> Einzelbilder herausziehen. Zwischen zwei aufeinanderfolgenden Bildern darf
> kein Sprung liegen.
>
> ```bash
> ffmpeg -i aufnahme.mp4 -q:v 2 bild_%04d.png
> ```

## 23 · Das neue Zeichen

Kein Kontingent, kein Analyse-Lauf.

**Vergleichsbild:** `assets/branding/icon_vorschau.png` — dasselbe Motiv
dreimal: als Kachel groß, in Homescreen-Größe und ohne Kachel, so wie es auf
dem Splash steht. Halt es neben deine Vorlage.

1. **Auf dem Homescreen.** App deinstallieren und neu installieren (sonst
   hält der Launcher das alte Icon fest). Erwartet: dunkle Kachel mit dem
   Petrol-Verlauf, feine helle Linien für Kopf und Schultern, in der
   Brustmitte ein warmer Glutkern, der weit und weich nach außen streut.
   Kein harter Kreis, keine Strahlen, kein Text.

2. **Die Launcher-Maske.** Erwartet: Nichts ist angeschnitten — weder der
   Schulterbogen noch der Kopfkreis, egal ob dein Launcher rund, eckig oder
   als Tropfen zuschneidet. Falls dein Launcher eine Icon-Form einstellen
   lässt, probier zwei verschiedene.

3. **In der Icon-Reihe.** Erwartet: Das Zeichen ist auch klein noch zu
   erkennen und hebt sich neben bunten Icons durch die Glut ab.

4. **Beim Start.** App öffnen. Erwartet: **Dasselbe** Zeichen wie auf dem
   Homescreen, nur ohne Kachel — Linien und Glut direkt auf dem dunklen
   Hintergrund. Weder größer noch kleiner als bisher, weder verschoben.

5. **Auf dem Anmeldebildschirm.** (Nur nach „Alle Daten löschen" oder
   Abmelden.) Erwartet: dasselbe Zeichen, klein, über den Anmeldeknöpfen.

6. **Im hellen Schema.** Einstellungen → Hell, dann zum Anmeldebildschirm.
   Erwartet: Die Linien sind dunkel statt weiß, die Glut ein dunkles Amber.
   Erkennbar bleibt es.

7. **Monochrom (Themed Icons).** Falls dein Launcher „themenbasierte
   Symbole" anbietet: Erwartet: Die Silhouette bleibt erkennbar. Die Glut
   fällt dort weg — ein Monochrom-Icon hat nur eine Farbe, das ist so
   vorgesehen.

## Was mit Funden passiert

| Fund | Reaktion |
|---|---|
| Absturz | Blocker. Vor der Einreichung beheben. |
| Abgeschnittener Text, Überlauf | Blocker, wenn dadurch etwas unbedienbar wird — sonst vor dem Launch. |
| TalkBack liest etwas nicht vor | Kein Blocker, aber notieren und danach angehen. |
| Kamera ruckelt auf schwacher Hardware | Notieren mit Gerätemodell. Wenn es auf zwei von drei Geräten auftritt, ist es ein Blocker. |
| Etwas sieht nur unschön aus | Sammeln, nach dem Launch angehen. |

Jeder Blocker gehört als offener Punkt in `ROADMAP.md`, bevor er in
Vergessenheit gerät.
