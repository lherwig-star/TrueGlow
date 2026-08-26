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

Bleibt das Ergebnis nach diesen beiden Abschnitten dünn, ist der nächste
Hebel ein stärkeres Modell. Was das kostet, steht in `DECISIONS.md` 40 —
kurz: rund 1,7 Cent je Analyse heute, rund 2,9 Cent mit `gemini-3.7-flash`.

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
