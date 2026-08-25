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
