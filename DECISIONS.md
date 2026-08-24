# DECISIONS — Entscheidungen, die die Roadmap offen ließ

Jede Entscheidung, die beim Umbau nötig war und in `ROADMAP.md` nicht
festgelegt ist, steht hier mit Begründung. Format: **Was · Warum · Preis**.

---

## Gesetzt durch die Vorgabe (nicht hier entschieden)

Zur Erinnerung, damit die Datei allein lesbar bleibt:

- Backend: **Firebase**, Region **`europe-west3`**
- **Fotos bleiben lokal.** In die Cloud gehen nur Ergebnisse, Plan, Streak,
  Richtung und Check-in-Historie. Bilder laufen ausschließlich transient durch
  die Cloud Function zu Gemini, werden serverseitig nicht gespeichert und nicht
  geloggt.
- **iOS kommt fest.** Alles plattformneutral halten, „Sign in with Apple" von
  Anfang an mitgeplant.
- Rate-Limit: 3 Analysen/Tag, 30/Monat, serverseitig.

---

## 1 · `lib/firebase_options.dart` liegt als Platzhalter im Repo

**Was:** Die Datei wird normalerweise von `flutterfire configure` erzeugt. Da
das ein manueller Schritt mit echtem Firebase-Projekt ist, liegt eine Fassung
mit erkennbar ungültigen Werten im Repo.

**Warum:** Ohne die Datei kompiliert das Projekt nicht, und `flutter analyze`
sowie die 148 Tests wären bis zum ersten Konsolen-Klick rot. Der Platzhalter
hält den Baum grün und wird beim `flutterfire configure` überschrieben.

**Preis:** Wer die Datei nicht ersetzt, sieht statt der App einen Hinweis mit
dem nötigen Befehl (`EinrichtungHinweisApp`) statt eines stillen Fehlschlags.
Erkannt wird der Platzhalter an seiner Projekt-ID
(`DefaultFirebaseOptions.platzhalterProjektId`, geprüft in `FirebaseStart`) –
nach `flutterfire configure` stimmt sie nicht mehr überein und die App startet
normal.

---

## 2 · `google-services.json` / `GoogleService-Info.plist` sind ausgeschlossen

**Was:** Beide Dateien stehen in `.gitignore`, `firebase_options.dart` nicht.

**Warum:** Die Vorgabe verlangt, „Firebase-Service-Dateien mit Secrets"
auszuschließen. Streng genommen enthält keine der beiden ein Geheimnis — sie
benennen aber das private Projekt und werden von `flutterfire configure` in
Sekunden neu erzeugt. `firebase_options.dart` bleibt drin, weil sonst nichts
mehr kompiliert (siehe 1).

**Preis:** Ein frischer Klon braucht einmal `flutterfire configure`. Steht in
`SETUP.md`, Abschnitt 2.

---

## 3 · Callable Functions statt HTTPS-Endpunkten

**Was:** `analysiere` und `checkinAuswerten` sind `onCall`-Funktionen
(Firebase Callable), keine `onRequest`-Endpunkte.

**Warum:** Callable-Funktionen bringen Auth-Token-Prüfung und
App-Check-Erzwingung als Bordmittel mit (`enforceAppCheck: true`). Bei einem
rohen HTTPS-Endpunkt müsste beides von Hand geprüft werden — genau die Stelle,
an der Fehler teuer werden. Außerdem gibt es dann keinen anonym erreichbaren
URL-Pfad, den jemand mit `curl` beschießen kann.

**Preis:** Der Client muss `cloud_functions` benutzen statt `http`. Für Tests
ist das kein Nachteil, weil zwischen UI und Function ohnehin ein Interface
steht (`AnalysisService`), das im Test durch eine Attrappe ersetzt wird.

---

## 4 · Bilder gehen als base64 im Request-Body

**Was:** Die Function nimmt die Bilder als base64-Strings im Callable-Payload
entgegen — so, wie sie heute schon an Gemini gehen.

**Warum:** Der Weg über einen Storage-Upload würde die Fotos zwangsläufig
persistieren (und sei es für Sekunden) — das widerspricht der Vorgabe
„serverseitig nirgends gespeichert". base64 im Body hält das Bild im
Arbeitsspeicher der Function und nirgends sonst.

**Preis:** Die Callable-Payload-Grenze liegt bei 10 MB. Die App skaliert Fotos
bereits auf max. 1024 px bei Qualität 80 (≈ 150–250 KB je Bild); bei zehn
Bildern sind das ~2,5 MB. Die Function lehnt Payloads über
`MAX_BILD_BYTES` = 8 MB mit `AnalysisFehler.apiFehler` ab, bevor Gemini
gerufen wird.

---

## 5 · `useMockData` wird zur Compile-Zeit gesetzt

**Was:** Aus `static const bool useMockData = true` wird
`bool.fromEnvironment('TRUEGLOW_MOCK')` — Standard **false**, einschaltbar per
`--dart-define=TRUEGLOW_MOCK=true`.

**Warum:** Die Roadmap will den Mock als Demo-/Screenshot-Modus behalten, im
Release aber `false`. Eine `const`-Umgebungsvariable erfüllt beides und kann
nicht versehentlich im Release aktiv bleiben, weil sie explizit gesetzt werden
muss. Als `const` bleibt außerdem der Tree-Shaking-Vorteil erhalten.

**Preis:** Der Schalter lässt sich zur Laufzeit nicht umlegen. Für einen
Screenshot-Modus in den Einstellungen wäre ein zusätzlicher Laufzeit-Schalter
nötig — das ist bewusst nicht Teil dieser Phase.

---

## 6 · Dienste in Tests über Provider-Overrides

**Was:** `analysisServiceProvider` und `checkinServiceProvider` wählen weiter
über `AnalysisConfig.useMockData`. Weil der Standard jetzt `false` ist, setzen
die Widget-Tests die Attrappen ausdrücklich per Override
(`dienstOverrides()` in `test/hilfen.dart`).

**Warum:** Ein Test, der zufällig grün ist, weil ein globaler Schalter gerade
richtig steht, ist kein Test. Der Override macht sichtbar, was der Test
benutzt.

**Preis:** Jeder neue Widget-Test muss die Overrides mitgeben. Dafür gibt es
`testOverrides()` als Sammelfunktion.

---

## 7 · Auth hinter einem eigenen Interface

**Was:** Zwischen UI und `firebase_auth` liegt `AuthRepository` mit dem Enum
`AuthAnbieter { google, apple, anonym }`. Die Firebase-Fassung heißt
`FirebaseAuthRepository`, für Tests gibt es `FakeAuthRepository`.

**Warum:** Zwei Gründe. Erstens die Vorgabe „Sign in with Apple ist später nur
ein weiterer Provider" — mit dem Enum ist das ein zusätzlicher `case` und eine
zusätzliche Schaltfläche, kein Umbau. Zweitens laufen die bestehenden
Widget-Tests ohne Firebase-Initialisierung weiter, weil sie die Attrappe
einhängen.

**Preis:** Eine Indirektionsschicht mehr. Sie ist schmal (fünf Methoden) und
zahlt sich beim Apple-Login und in jedem Test aus.

---

## 8 · Anmeldung ist Pflicht, aber anonym reicht

**Was:** Nach dem Onboarding führt der Router auf `/login`. Dort gibt es
„Mit Google anmelden" und „Erst ausprobieren" (anonym). Ohne eine der beiden
geht es nicht weiter.

**Warum:** Die Cloud Function verlangt ein gültiges Auth-Token — ohne Konto
gäbe es also gar keine Analyse. Ein anonymes Konto kostet den Nutzer nichts
und wird beim späteren Google-Login per Account-Linking übernommen, statt
verworfen zu werden.

**Preis:** Ein Bildschirm mehr im Erstkontakt. Der Rest der App bleibt
unverändert.

---

## 9 · Konfliktregel: letzter Schreiber gewinnt, pro Dokument

**Was:** Jedes synchronisierte Dokument trägt `aktualisiertAm`
(ISO-8601, UTC). Beim Zusammenführen gewinnt der jüngere Zeitstempel. Bei
exakt gleichem Zeitstempel gewinnt die Cloud.

**Warum:** So steht es in der Roadmap („Konfliktregel einfach halten").
Feinere Verfahren (Merge pro Feld, CRDTs) wären für Streak, Plan und
Check-in-Historie deutlich zu viel Maschinerie.

**Preis:** Wer dieselbe Aufgabe auf zwei Geräten offline unterschiedlich
abhakt, verliert die ältere Änderung. Für den Tagesfortschritt ist das
verkraftbar; die Historie selbst wird nie überschrieben, sondern nur ergänzt.

---

## 10 · Der Tagesfortschritt wird pro Tag zusammengeführt, nicht überschrieben

**Was:** Ausnahme von Regel 9: In `fortschritt/{yyyy-mm-tt}` werden die
abgehakten Aufgaben beider Seiten **vereinigt**, nicht ersetzt.

**Warum:** „Letzter Schreiber gewinnt" würde hier bedeuten, dass ein Gerät,
das morgens offline drei Haken gesetzt hat, sie beim Sync verliert, weil das
andere Gerät später einen einzigen Haken gesetzt hat. Ein Haken ist ein
additives Ereignis — das Zusammenführen ist die richtige Semantik und kostet
keine Komplexität.

**Preis:** Ein bewusst entfernter Haken kann durch ein anderes Gerät wieder
auftauchen. Das ist der seltenere und harmlosere Fall.

---

## 11 · Fehlende Fotos sind ein Normalzustand, kein Fehler

**Was:** Analyse-Dokumente speichern nur Dateinamen, keine Bilddaten. Fehlt
die Datei (neues Gerät), zeigt die UI einen Platzhalter „Foto auf diesem Gerät
nicht verfügbar" statt eines Fehlers.

**Warum:** Direkte Folge aus „Fotos bleiben lokal". Der Vorher/Nachher-
Vergleich überlebt keinen Gerätewechsel — das ist die bewusst gewählte
Gegenleistung für den geringeren DSGVO-Aufwand.

**Preis:** Der Vergleich fehlt nach einem Gerätewechsel dauerhaft. Er lässt
sich nicht nachträglich herstellen.

---

## 12 · Migration läuft über einen Marker, nicht über einen Vergleich

**Was:** Nach erfolgreicher Migration steht `migration/hive` im Nutzerdokument
mit Zeitstempel und Version. Ein zweiter Lauf bricht sofort ab.

**Warum:** Idempotenz ist gefordert. Ein feldweiser Vergleich wäre teuer
(viele Lesezugriffe) und trotzdem nicht sicher — der Marker ist eindeutig.
Zusätzlich schreiben alle Migrationsschritte mit festen Dokument-IDs, sodass
selbst ein Abbruch mitten drin beim Wiederholen nichts doppelt.

**Preis:** Wer nach der Migration lokal weiterarbeitet und dann noch einmal
migrieren will, muss den Marker löschen. Dafür gibt es keinen UI-Weg — bewusst,
weil der reguläre Weg der Sync ist.

---

## 13 · Der Sync haengt am `KeyValueStore`, nicht an den Controllern

**Was:** `SyncStore` implementiert `KeyValueStore`, schreibt lokal und zieht
die Cloud nach. `storeProvider` liefert ihn; kein Controller wurde angefasst.

**Warum:** Die Roadmap sagt „Schreibpfade über Repositories bündeln (am
bestehenden `KeyValueStore` ansetzen)". Alle zwoelf Controller schreiben seit
jeher durch diese eine Schnittstelle. Sie zu erweitern bringt Plan,
Checklisten, Streak, Richtung und Historie in einem Schritt in die Cloud – und
laesst die 148 bestehenden Tests unberuehrt, weil sie den Store ohnehin durch
`MemoryStore` ersetzen.

**Preis:** Die Abbildung zwischen flachen Hive-Schluesseln und dem
Cloud-Datenmodell muss irgendwo stehen; sie steht in `CloudModell` und
`CloudUebersetzung`. Wer einen neuen Schluessel einfuehrt, muss ihn dort
eintragen, sonst bleibt er lokal.

---

## 14 · Schreiben wartet nicht auf die Cloud

**Was:** `put` schreibt lokal und feuert den Cloud-Schreibvorgang ohne `await`
ab. Fehler landen im Log, nicht in der UI.

**Warum:** Firestore nimmt Schreibvorgaenge auch offline entgegen und schickt
sie nach, sobald wieder Netz da ist – genau das verlangt die Roadmap. Das
zurueckgegebene Future wird allerdings erst erfuellt, wenn der Server
bestaetigt hat. Wuerde die UI darauf warten, haengte jeder Haken in der
Checkliste am Netz. Damit spart der Umbau zugleich ein Paket für die
Netzerkennung.

**Preis:** Ein dauerhaft fehlschlagender Schreibvorgang faellt nur im Log auf.
Ein sichtbarer Sync-Status waere ein eigener Punkt – er gehoert zu Phase 4.2
(„Zustände systematisch"), nicht hierher.

---

## 15 · Keine Grabsteine fuer geloeschte Dokumente

**Was:** Loeschen wirkt lokal und in der Cloud, aber es wird kein Marker
hinterlassen.

**Warum:** Grabsteine bedeuten ein zweites Datenmodell (was ist geloescht, seit
wann, wann darf der Marker weg) – deutlich mehr Maschinerie, als „letzter
Schreiber gewinnt" verspricht.

**Preis:** Wer auf Gerät A eine Analyse loescht, waehrend Gerät B offline ist,
bekommt sie von Gerät B beim naechsten Abgleich zurueck. Der Fall setzt zwei
Geraete und eine Loeschung voraus; „Alle Daten löschen" ist davon nicht
betroffen, weil es beide Seiten in einem Zug raeumt.

---

## 16 · Was beim Umbenennen bewusst „glowup" geblieben ist

**Was:** Der Fotoordner auf dem Gerät heißt weiterhin
`<AppDocs>/glowup_fotos` (`image_quality_service.dart`).

**Warum:** Der Ordnername steht in jedem gespeicherten Foto-Pfad — in der
Aufnahmen-Liste, in den Check-in-Einträgen und seit Phase 1.5 auch in den
Cloud-Dokumenten. Ein Umbenennen hieße, alle bestehenden Pfade zu migrieren
und dabei genau die Fotos zu riskieren, die nirgends sonst existieren. Der
Ordner ist für niemanden sichtbar außer einem Dateimanager mit Root-Rechten.

**Preis:** Eine Inkonsistenz im Code, die einen Kommentar braucht. Sie steht
an genau einer Stelle.

**Umbenannt wurde dagegen alles, was der Compiler prüft:** Dart-Paketname
(`glowup` → `trueglow`), `TrueGlowApp`, `TrueGlowNutzer`, der Build-Schalter
`TRUEGLOW_MOCK`, der Kotlin-Paketpfad und beide Bundle-IDs. Ein Tippfehler
dabei ist kein stiller Fehler, sondern ein roter Analyzer.

---

## 17 · Die Anwendungs-ID wurde vor dem ersten Upload gewechselt

**Was:** `com.glowup.glowup` → `com.trueglow.app`.

**Warum:** Nach dem ersten Upload in die Play Console ist die Anwendungs-ID
unveränderlich. Ein späterer Wechsel bedeutet eine neue App ohne Bewertungen,
ohne Installationen, ohne Käufe. Jetzt kostet er einen Nachmittag.

**Preis:** Die Firebase-App-Registrierung muss neu angelegt werden — App
Check, SHA-Fingerprints und `google-services.json` hängen daran. Firestore,
Auth-Konten, Secrets und die Functions hängen dagegen am Projekt und bleiben
unberührt. Der Ablauf steht in `SETUP.md`, Abschnitt 2.0.

---

## 18 · Zwei Einwilligungen, nur eine davon Pflicht

**Was:** `nutzung` (Nutzungsbedingungen/DSE) ist Pflicht und blockiert die
App. `fotoKi` (Verarbeitung von Gesichtsfotos durch Gemini) ist freiwillig und
blockiert nur neue Analysen.

**Warum:** Eine Einwilligung, ohne die nichts geht, ist keine freiwillige — und
genau die Freiwilligkeit ist bei biometrienahen Daten der Punkt, an dem eine
Prüfung ansetzt. Wer die Fotoverarbeitung ablehnt, behält Plan, Checklisten,
Streak, Check-ins und alle bisherigen Reports.

**Preis:** Zwei Zustände mehr in der UI und ein Gate im `AnalysisController`.
Der Check-in läuft ohne Einwilligung ohne Bildvergleich weiter, statt zu
scheitern — die Rückmeldung zum Plan ist das Wesentliche.

---

## 19 · Eine Einwilligung gilt nur für die Textfassung, der sie galt

**Was:** Jeder Nachweis trägt die Version aus `Rechtstexte.version`. Stimmt sie
nicht mehr mit der aktuellen überein, gilt die Einwilligung als nicht erteilt
und die App fragt einmalig nach (`/einwilligung`).

**Warum:** Sonst hätte jemand formal etwas anderem zugestimmt als dem, was
gilt. Dieselbe Mechanik trägt die Migration der alten Sammel-Checkbox: Sie
hinterlässt gar keinen Nachweis, fällt also durch dieselbe Prüfung.

**Preis:** Jede inhaltliche Textänderung kostet alle Nutzer einen Dialog.
Deshalb ist die Version bewusst grobkörnig — Tippfehler in den Texten
rechtfertigen keine neue Nummer.

---

## 20 · Der alte `zugestimmt`-Haken bleibt als Vermerk stehen

**Was:** `OnboardingProfile.zugestimmt` wird weiterhin gesetzt, ist aber kein
Nachweis mehr.

**Warum:** Er ist das einzige Erkennungsmerkmal für Bestandsnutzer: „hat
zugestimmt, aber ohne Nachweis" (`ausAlterZustimmungProvider`). Daran hängt
der freundlichere Text auf dem Nachtrags-Screen — sonst bekämen langjährige
Nutzer dieselbe Ansprache wie bei einer Textänderung.

**Preis:** Ein Feld, das aussieht, als würde es etwas entscheiden, es aber
nicht mehr tut. Es ist im Modell als Vermerk gekennzeichnet.

---

## Mock vs. Live

*(Wird nach dem ersten echten Durchlauf gefüllt — siehe `SETUP.md`,
Abschnitt 6.3. Der Durchlauf braucht ein Firebase-Projekt und einen
Gemini-Key und kann deshalb nur von dir ausgeführt werden.)*

| Beobachtung | Mock | Live | Konsequenz |
|---|---|---|---|
| *noch offen* | | | |
