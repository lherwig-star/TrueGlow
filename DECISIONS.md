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

## 21 · Der Medizin-Disclaimer wird geprüft, nicht nur behauptet

**Was:** `tool/diagnose_pruefung.dart` hält Analyse-Antworten gegen sieben
Regeln (Diagnosewörter, benannte Krankheitsbilder, Behandlungsempfehlungen,
Bewertungszahlen, Attraktivitäts- und Gewichtsurteile, Zustandsbehauptungen).
`test/diagnose_stichprobe_test.dart` fährt sie über alle fünf
Modul-Beispielantworten, `tool/diagnose_stichprobe.dart` über echte Antworten
aus der Live-API.

**Warum:** Der Prompt verbietet all das seit jeher — geprüft war es nie. Eine
Leitplanke, die niemand nachrechnet, ist eine Absichtserklärung.

**Ergebnis der Stichprobe (Mock, 24.08.2026):** Alle fünf Modulantworten und
die vollständige Antwort über alle Module sind **ohne Befund**. Der Prompt
wurde daraufhin nicht geändert.

**Noch offen:** dieselbe Stichprobe über 3–5 **echte** Antworten. Sie braucht
ein Firebase-Projekt und einen Gemini-Key — `SETUP.md`, Abschnitt 6.5.

**Preis:** Die Regeln sind Wortlisten und finden nur, was jemand vorhergesehen
hat. Sie ersetzen kein Lesen — sie fangen die bekannten Fälle, damit das Lesen
sich auf den Rest konzentrieren kann. Zwei Regeln waren beim ersten Entwurf
still wirkungslos, weil `` in einem Regex vor „ü" keine Wortgrenze sieht;
dafür gibt es jetzt `wortmuster()` und Tests, die genau das prüfen.

---

## 22 · Der Release-Build bricht ohne Keystore ab

**Was:** Fehlt `android/key.properties`, scheitert jeder `assembleRelease` und
`bundleRelease` mit einer Meldung, die den Weg beschreibt. Es gibt keinen
Rückfall auf die Debug-Schlüssel mehr.

**Warum:** Genau dieser Rückfall stand vorher im Gradle-Skript und war in der
Bestandsaufnahme als Blocker vermerkt. Ein debug-signiertes App Bundle lehnt
Play ab — die Frage ist nur, ob der Fehler beim Bauen auffällt oder erst nach
dem Upload. Ein Build, der wortlos etwas Unbrauchbares erzeugt, ist die
schlechtere Variante.

**Preis:** `flutter run --release` funktioniert ohne Keystore nicht mehr. Für
das Ausprobieren sind Debug und Profile da; für einen echten Release-Test
braucht es ohnehin den echten Schlüssel.

---

## 23 · Was aus dem Merged Manifest fliegt — und was bleibt

**Was:** Zwei Berechtigungen werden per `tools:node="remove"` entfernt, eine
Funktionsanforderung wird entschärft.

Vollständige Herkunft, aus den Plugin-Manifesten in `.dart_tool` gelesen:

| Berechtigung | Woher | Entscheidung |
|---|---|---|
| `CAMERA` | eigenes Manifest + `camera_android_camerax` | **bleibt** — die In-App-Kamera |
| `POST_NOTIFICATIONS` | eigenes Manifest + `flutter_local_notifications` | **bleibt** — Check-in-Erinnerung |
| `RECEIVE_BOOT_COMPLETED` | eigenes Manifest | **bleibt** — geplante Erinnerungen überleben einen Neustart |
| `INTERNET` | `google_sign_in_android`, Flutter-Debug-Manifest | **bleibt** — ohne Netz keine Analyse |
| `VIBRATE` | `flutter_local_notifications` | **bleibt** — gehört zur Benachrichtigung und ist keine eigene Abfrage beim Nutzer |
| `RECORD_AUDIO` | `camera_android_camerax` | **entfernt** — die App nimmt nie Ton oder Video auf. Eine Mikrofon-Berechtigung in einer Foto-App ist der Punkt, an dem Prüfer und Nutzer stutzen |
| `WRITE_EXTERNAL_STORAGE` (max. API 28) | `camera_android_camerax` | **entfernt** — Fotos landen ausschließlich im app-eigenen Verzeichnis |
| `READ_EXTERNAL_STORAGE` | **niemand** — im Merger-Report steht dafür keine `REJECTED from [...]`-Quelle, anders als bei `WRITE_EXTERNAL_STORAGE` | **entfernt, aber aktuell wirkungslos** — historisch gewährt Android READ automatisch mit, wenn WRITE_EXTERNAL_STORAGE gehalten wird; das greift seit der WRITE-Entfernung ohnehin nicht mehr. Der Eintrag steht defensiv da, aus Symmetrie zu WRITE, falls eine künftige Abhängigkeit sie doch mitbringt |
| `com.google.android.gms.permission.AD_ID` | `play-services-measurement-api:23.2.0`, `play-services-measurement-impl:23.2.0`, `play-services-measurement-sdk-api:23.2.0`, `play-services-ads-identifier:18.0.0` (alle transitiv über `firebase_analytics`) | **entfernt** — widerspricht sonst der Data-Safety-Angabe „keine Werbe-ID" (`store/data-safety.md`, Zeile 216) |
| `android.permission.ACCESS_ADSERVICES_AD_ID` | `play-services-measurement-api:23.2.0`, `play-services-measurement-sdk-api:23.2.0` | **entfernt** — gehört zur selben Attributionsmechanik wie `AD_ID` |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION` | `play-services-measurement-api:23.2.0`, `play-services-measurement-sdk-api:23.2.0` | **entfernt** — dito |

| Funktion | Woher | Entscheidung |
|---|---|---|
| `android.hardware.camera.any` | `camera_android_camerax`, **ohne** `required`-Angabe und damit erforderlich | **auf `required="false"` gesetzt** — die App lässt sich vollständig über den Galerie-Import bedienen; sonst würde Play sie auf Geräten mit Kamera beschränken |

**Warum die Herleitung hier steht:** Das Merged Manifest entsteht erst beim
Bauen. Wer später eine Berechtigung sieht und nicht weiß, woher sie kommt,
findet die Antwort sonst nur durch Nachbauen.

**Preis:** Kommt ein Plugin dazu, ist diese Tabelle veraltet. Sie gehört
deshalb in die Release-Checkliste — dort steht sie.

**Nachtrag (Phase 4.3, 24.08.2026):** Mit Firebase Analytics kamen `AD_ID`
und die zwei AdServices-Berechtigungen ins Merged Manifest — Fund beim
Zurückverfolgen, entfernt (siehe oben). **Offen dabei aufgefallen:** Diese
Tabelle deckt nicht alle Berechtigungen ab, die inzwischen im
Release-Merger-Report stehen — `ACCESS_NETWORK_STATE` (`connectivity_plus`,
seit Phase 4.1), `WAKE_LOCK` (`firebase_analytics`), `USE_BIOMETRIC` /
`USE_FINGERPRINT` (`androidx.biometric`, transitiv über ältere
Play-Services-Kompatibilität), `com.google.android.c2dm.permission.RECEIVE`
(`firebase-iid`), `BIND_GET_INSTALL_REFERRER_SERVICE`
(`play-services-measurement`) und `READ_GSERVICES`
(`com.google.android.recaptcha`, über App Check) fehlen als Zeilen. Keine
davon widerspricht der Data-Safety-Erklärung — sie sind hier nur nicht
dokumentiert. Verdient einen eigenen Durchgang, bevor die
Einreichungstag-Checkliste („Merged Manifest gegen DECISIONS.md 23 geprüft")
das nächste Mal abgehakt wird.

**Nachprüfen nach dem nächsten Build:**
`build/app/outputs/logs/manifest-merger-release-report.txt`, oder in Android
Studio `AndroidManifest.xml` → Reiter *Merged Manifest*.

---

## 24 · Versionsschema

**Was:** `version: <SemVer>+<Buildnummer>` in `pubspec.yaml`.

- **`versionName` (links)** folgt SemVer: `MAJOR.MINOR.PATCH`.
  - PATCH: Fehlerbehebungen, nichts Neues
  - MINOR: neue Funktionen, alte bleiben
  - MAJOR: Bruch — Umbau am Datenmodell, entfernte Funktionen
- **`versionCode` (rechts)** ist eine einfach fortlaufende Zahl. Sie steigt
  bei **jedem** Upload, auch wenn nur ein Build wiederholt wird. Sie wird nie
  zurückgesetzt und hat mit dem SemVer keinen Zusammenhang.

**Warum getrennt:** Play verweigert einen Upload mit gleichem oder kleinerem
`versionCode`. Wer ihn an den SemVer koppelt (etwa `1.2.3` → `10203`), sitzt
beim ersten korrigierten Build derselben Version fest.

**Preis:** Zwei Zahlen, die man beide anfassen muss. Beide stehen in einer
Zeile in `pubspec.yaml` — vergessen kann man höchstens eine davon, und der
Upload sagt es dann sofort.

**Beispiele**

| Anlass | vorher | nachher |
|---|---|---|
| Erster Store-Upload | — | `1.0.0+1` |
| Fehler im Login behoben | `1.0.0+1` | `1.0.1+2` |
| Upload abgelehnt, korrigiert | `1.0.1+2` | `1.0.1+3` |
| Neues Analyse-Modul | `1.0.1+3` | `1.1.0+4` |

---

## 25 · Icon und Splash werden generiert, nicht gezeichnet

**Was:** `tool/marke_erzeugen.dart` hält die Geometrie des Motivs und schreibt
daraus sechs PNG-Fassungen **und** die SVG-Quelle. Die SVG-Datei im Repo ist
also ein Erzeugnis, keine Vorlage.

**Warum:** Dasselbe Motiv gibt es als Vollbild-Icon, adaptiven Vordergrund,
Store-Icon und in vier Splash-Varianten über zwei Farbwelten. Von Hand
gepflegt laufen die auseinander — und zwar unbemerkt, weil niemand acht
Dateien nebeneinanderlegt. Hier ändert man eine Zahl und bekommt alles neu.

**Motiv:** das Gesichts-Oval aus dem Kamera-Sucher (`Overlaytyp.gesichtsOval`)
mit angedeuteten Schultern, Sand auf Deep Teal. Wer die App benutzt hat,
erkennt das Icon wieder — das ist mehr wert als ein hübscheres, fremdes
Zeichen.

**Preis:** Wer das Icon später von einer Designerin überarbeiten lässt,
bekommt eine echte SVG-Datei zurück und ersetzt damit den Generator. Bis
dahin ist die Kopfzeile in der SVG-Datei die Warnung, dass Änderungen darin
verloren gehen.

---

## 26 · Zielgruppe 18+, durchgesetzt an einer Stelle

**Was:** Der Altersbereich „unter 18" ist weg, es gibt eine ausdrückliche
Altersbestätigung (`Einwilligungsart.mindestalter`) mit demselben Nachweis wie
eine Einwilligung, und ohne sie bleibt der **Analyse-Flow** zu.

**Warum die Bestätigung im Einwilligungs-Modell liegt:** Formal ist sie keine
Einwilligung, sondern eine Erklärung. Sie braucht aber genau dieselben
Nachweise — wann, zu welcher Textfassung, an welcher Stelle — und dieselbe
Migration für Bestandsnutzer. Ein zweiter Mechanismus daneben wäre doppelte
Maschinerie für dasselbe Problem.

**Warum nur der Analyse-Flow gesperrt wird und nicht die App:** Wer nicht
bestätigt, verliert nichts von dem, was er schon hat. Plan, Checkliste, Serie
und Check-ins laufen weiter, bestehende Reports bleiben. Eine App, die nach
einem nicht gesetzten Haken komplett dichtmacht, erzieht nur dazu, Haken
blind zu setzen.

**Zwei Sperren, nicht eine:** Der Router leitet auf den Hinweisscreen um, und
der `AnalysisController` prüft zusätzlich vor jedem Start. Die erste ist die
Erklärung, die zweite die Zusicherung — eine tiefe Route umgeht sie nicht.

**Preis:** Ein Screen mehr und ein Zustand mehr, den jeder Test kennen muss.
Dafür gibt es `einwilligungErteilen()` in `test/hilfen.dart`.

---

## 27 · „Gefragt und abgelehnt" wird vermerkt

**Was:** Beim Verlassen von Onboarding und Nachtrags-Screen werden alle
freiwilligen Punkte, die offen geblieben sind, als `erteilt: false`
festgehalten.

**Warum:** Ohne diesen Vermerk bliebe „wurde schon gefragt?" für immer offen —
und der Router schickte dieselbe Person bei jedem Start zurück auf den
Nachtrags-Screen. Eine Endlosschleife, die erst auffällt, wenn jemand nichts
ankreuzt.

Nebenbei ist es der ehrlichere Nachweis: Die Person hatte die Wahl und hat
sich entschieden. „Nie gefragt" behauptet etwas anderes.

**Preis:** In den Einstellungen steht dann „nicht erteilt am …" statt „noch
nicht gefragt". Das ist die zutreffendere Aussage.

---

## 28 · Fotos gelten als „geteilt", obwohl man es auch anders eintragen könnte

**Was:** Im Data-Safety-Formular wird die Übermittlung an Gemini als
Datenweitergabe deklariert, nicht als reine Auftragsverarbeitung.

**Warum:** Play zählt Weitergaben an weisungsgebundene Dienstleister formal
nicht als „Teilen" — „Nein" wäre also vertretbar. Es sind aber
Gesichtsaufnahmen, sie verlassen tatsächlich unsere Kontrolle, und die
Nutzungsbedingungen der Gemini-API können sich ändern, ohne dass wir es
merken. „Ja" ist nie ein Verstoß, „Nein" kann einer werden.

**Preis:** Die strengere Angabe steht im Store sichtbar. Sie deckt sich mit
dem, was die Einwilligung in der App ohnehin sagt — insofern kostet sie nur
Ehrlichkeit, keine Glaubwürdigkeit.

---

## 29 · Die Firebase-Pakete sind auf einen zusammenpassenden Satz festgenagelt

**Was:** `firebase_core: >=4.13.0 <4.14.0`, `firebase_auth: 6.5.7`,
`firebase_analytics: >=12.0.0 <12.5.0`, `firebase_crashlytics: ^5.2.7`. Die
übrigen Firebase-Pakete folgen daraus.

**Warum:** In `firebase_core 4.14.0` wurde `FlutterFirebaseCorePlugin` von
Java nach Kotlin überführt und das Feld `customAuthDomain` in eine andere
Klasse verschoben. `firebase_auth 6.5.7` sucht es noch am alten Ort — der
Android-Build bricht mit „Symbol nicht gefunden" ab. Die Fassung, die das
behebt (`firebase_auth 6.6.0`), scheitert ihrerseits am Kotlin-Compiler:

```
IdTokenChannelStreamHandler.kt:23:40 Type annotation class
'org.checkerframework.checker.initialization.qual.UnknownInitialization'
of the inferred type is inaccessible.
```

Beide Fehler treten **ausschließlich beim Android-Build** auf. `flutter
analyze` und die 267 Dart-Tests laufen mit jeder der Kombinationen durch —
gefunden wurden sie erst beim ersten echten Gradle-Lauf.

`firebase_analytics 12.5.0` verlangt `firebase_core ^4.14.0` und zieht damit
den kaputten Stand nach; deshalb steht auch dort eine Obergrenze.

**Preis:** Vier Pakete hängen an einer Versionsobergrenze und werden von
`flutter pub upgrade` nicht mitgenommen. Das ist Absicht — ohne die Grenzen
wäre der nächste Build zufällig kaputt.

**Wann das wieder weg kann:** Sobald eine `firebase_auth`-Fassung erscheint,
die `firebase_core ≥ 4.14` benutzt *und* sich übersetzen lässt. Prüfen mit:

```bash
flutter pub upgrade --major-versions firebase_core firebase_auth firebase_analytics firebase_crashlytics
flutter build apk --debug
```

Baut es durch, können die Obergrenzen in `pubspec.yaml` fallen. Baut es nicht,
gehört der Stand zurückgesetzt (`git checkout pubspec.yaml pubspec.lock`).

---

## 30 · Was der erste echte Android-Build zutage gefördert hat

Bis Phase 4 gab es auf dieser Maschine kein Java, also keinen Gradle-Lauf.
Alles Android-Seitige war sorgfältig geschrieben, aber ungetestet. Beim ersten
Build kamen drei Dinge heraus, die keine Analyse und kein Dart-Test hätte
finden können:

1. **Die Firebase-Versionskombination war nicht übersetzbar** (Abschnitt 29).
2. **`GeneratedPluginRegistrant.java` war veraltet** und verwies nach einem
   Paketwechsel auf Klassen, die es nicht mehr gab. `flutter clean` räumt das;
   erwähnenswert, weil der Fehler wie ein Codefehler aussieht und keiner ist.
3. **`splashHintergrund` gab es nur unter `values-night`.** `lintVital` bricht
   den Release-Build dafür ab, und zu Recht: Eine Ressource, die es nur mit
   Qualifier gibt, lässt die App in jeder anderen Konfiguration abstürzen. Die
   Farbe steht jetzt auch in `values/colors.xml` — dort mit dem hellen Wert.

**Der Punkt daraus:** Ein grüner Analyzer und grüne Tests sagen über die
Plattformseite nichts. Der Release-Build ist ein eigener Prüfschritt, und er
gehört vor die Einreichung — nicht an sie.

---

## 31 · Zweisprachigkeit: eine Oberfläche, ein Prompt, zwei Sprachen

**Die Oberfläche** liegt seit dem Umbau in `lib/l10n/app_de.arb` und
`app_en.arb` und wird von `gen-l10n` in die Klasse `L` übersetzt. Deutsch ist
die Vorlage; dort stehen die Beschreibungen, an denen sich eine Übersetzung
ausrichten kann. Eine dritte Sprache braucht genau eine weitere Datei
`app_<code>.arb` plus einen Wert im Enum `Sprache` — sonst nichts.

`l10n.yaml` setzt `untranslated-messages-file`. Eine vergessene englische
Zeile landet damit beim Bauen in `l10n_fehlend.txt` statt erst am Gerät
aufzufallen.

**Der Zugriff läuft über den Kontext** (`context.texte`) und nicht über eine
statische Klasse wie das frühere `S`. Ein Sprachwechsel muss den Baum neu
bauen; über `Localizations` passiert das von selbst, eine globale Variable
bliebe stehen, bis der jeweilige Screen zufällig aus einem anderen Grund neu
baut.

**Enum-Werte tragen keine Texte mehr.** Ein Enum-Wert ist konstant, ein
übersetzter Text hängt an der gewählten Sprache — beides in einem Feld geht
nicht. Wo bisher `Budget.mittel('Mittel', …)` stand, steht jetzt eine
Erweiterung `label(L)` direkt neben der Liste. Der Compiler besteht auf
Vollständigkeit, und beim Ergänzen eines Werts fällt sofort auf, dass auch
ein Text dazugehört.

**Der Prompt bleibt auf Deutsch, der Report nicht.** Die Leitplanken — keine
Scores, keine Diagnosen, kein Attraktivitätsurteil — gibt es nur einmal. Zwei
Übersetzungen desselben Regelwerks laufen früher oder später auseinander, und
dann gilt in einer Sprache eine Regel, die in der anderen jemand vergessen
hat. Was sich mit der Sprache ändert, ist die Ausgabevorgabe („Write every
word of your answer in ENGLISH") und die Beschriftungen in `labels.ts`. Die
Vorgabe steht bewusst zweimal im Prompt: bei den Regeln und noch einmal bei
den Feldvorgaben. Ein Modell, das eine deutschsprachige Anweisung liest,
fällt sonst gern in deren Sprache zurück.

**Der Rückfall ist Deutsch**, nicht Englisch — aber nur serverseitig. Ein
alter Client, der das Feld `sprache` noch nicht kennt, bekommt damit genau
das, was er bisher bekommen hat. Auf dem Gerät ist es umgekehrt: Alles außer
Deutsch bekommt Englisch, weil es für Französisch keine Übersetzung gibt und
ein französisches Handy auf Deutsch zu stellen die schlechtere Vermutung
wäre.

**Was bewusst auf Deutsch geblieben ist:** `debugPrint`-Zeilen und
Ausnahmetexte — die liest kein Nutzer, sondern `adb logcat`. Und der
Einrichtungs-Hinweis, der erscheint, wenn Firebase fehlt: Er läuft außerhalb
der `MaterialApp` und damit ohne Lokalisierung, und er kann ohnehin nur einen
falsch gebauten Build treffen.

**Ein fertiger Report behält seine Sprache.** Wer die App später umstellt,
bekommt den alten Bericht unverändert — er liegt als Text auf dem Gerät, und
ihn nachträglich zu übersetzen hieße, ihn neu erzeugen zu lassen. Der Hinweis
unter dem Sprachumschalter sagt das.

---

## 32 · Die Anmeldung steht vor dem Onboarding — und was das kostet

Die Reihenfolge war bis hierher: Onboarding (mit den Einwilligungen), dann
Anmeldung. Jetzt: Startanimation, Anmeldung, Onboarding.

**Warum:** Die Erklärseiten gehören zu einem Konto, nicht zu einem Gerät. Wer
die App auf einem zweiten Handy installiert, hat sie schon gesehen. Und wer
sie zum ersten Mal öffnet, will meistens zuerst wissen, ob er sich anmelden
muss.

**Was es kostet:** Die verbindliche Einwilligung (`Einwilligungsart.nutzung`)
liegt auf der letzten Onboarding-Seite und kommt damit **nach** der
Kontoanlage. Wer „Erst mal umschauen" tippt, hat ein anonymes
Firebase-Konto, bevor er den Nutzungsbedingungen zugestimmt hat.

**Warum das vertretbar ist:** Ohne die Pflichteinwilligung kommt niemand
weiter — die Weiche im Router hält jeden auf der Onboarding-Seite fest, und
deren „Weiter" bleibt ohne Häkchen gesperrt. Das Konto ist zu diesem
Zeitpunkt leer: keine Fotos, keine Analyse, kein Profil. Und die Rechtstexte
stehen als Verweise direkt auf dem Anmelde-Bildschirm, sind also vor der
Anmeldung lesbar.

**Was ausdrücklich nicht passiert ist:** Die Einwilligung wurde nicht zu
Kleingedrucktem gemacht. Sie bleibt ein Häkchen mit Zeitstempel und
Textfassung (siehe 18 und 19). Ein „Mit der Anmeldung stimmst du zu" wäre der
bequeme Weg gewesen und hätte den Nachweis wertlos gemacht.

---

## 33 · Der Frauen-Modus: vier Angaben, drei Ausrichtungen

Das Onboarding fragt nach männlich / weiblich / divers / keine Angabe. Die App
richtet sich danach aus, aber nicht in vier Varianten:

| Angabe | Ausrichtung | Was daraus folgt |
|---|---|---|
| männlich | `maennlich` | Bart in der Basis, kein Make-up-Modul, bestehende Silhouette |
| weiblich | `weiblich` | Make-up-Modul vorn, kein Bart, weibliche Silhouette, Figurtyp im Prompt |
| divers | `neutral` | alles wählbar, geschlechtsneutraler Prompt, bestehende Silhouette |
| keine Angabe | `neutral` | dito |
| *nie gefragt* (`null`) | `maennlich` | unverändertes Verhalten |

**Warum „divers" und „keine Angabe" dasselbe tun:** Es sind verschiedene
Aussagen — die eine ist eine Identität, die andere ein Nein zur Frage. Für die
App heißen beide dasselbe: lass mir alles offen. Ein eigener Modus für
„divers" hätte bedeutet, sich etwas auszudenken, wonach niemand gefragt hat.

**Warum `null` zur männlichen Ausrichtung führt:** Nicht als Aussage über
irgendjemanden, sondern weil das genau das Verhalten ist, das die App vor
dieser Frage hatte. Bestandsnutzer sollen von einem Update nichts merken, und
ein erzwungener Zusatzdialog beim ersten Start wäre die schlechtere Antwort
auf eine Frage, die sie nie gestellt bekommen haben. Wer will, ändert es in
den Einstellungen.

**Warum Bart kein eigenes Modul wurde:** Er ist ein Abschnitt der Basis. Ihn
dort im weiblichen Modus zu streichen war der kleinere Eingriff als ein
zweites Basismodul mit fast gleichem Inhalt — zwei Kapitel, die getrennt
gepflegt werden müssten und irgendwann auseinanderlaufen.

**Warum das Gesichts-Oval für alle gleich bleibt:** Gesichtsformen
unterscheiden sich zwischen Menschen mehr als zwischen Geschlechtern. Ein
zweites Oval wäre eine Aussage ohne Grundlage. Die Ganzkörper-Umrisse sind
etwas anderes: Schulter-Taille-Hüfte ist genau das, was das Ganzkörperfoto
zeigen soll, und danach richtet sich jemand beim Aufstellen aus.

**Beide Ganzkörper-Figuren stehen gleich hoch im Bild.** Das ist keine
Kosmetik. Der Umriss ist die Anweisung, wie weit man zurücktreten soll, und
der Auto-Auslöser prüft genau diese Höhe (`LiveKoerperGuide.minHoehe` /
`maxHoehe`). Stünden die Figuren verschieden hoch, hieße derselbe Umriss je
nach Modus einen anderen Abstand.

**Was den Server erreicht:** nur die Ausrichtung, nicht die Angabe. Ob jemand
„divers" oder „keine Angabe" gewählt hat, bleibt auf dem Gerät — der Prompt
braucht die Entscheidung, nicht ihre Herkunft.

---

## 34 · Der native Splash bleibt Deep Teal, auch auf einem hellen Handy

Ein nativer Splash kann nur dem Systemschema folgen — er läuft, bevor
Dart-Code existiert, und weiß deshalb nichts von der Einstellung in der App.
Die App richtet sich aber nach ihrer eigenen Wahl, und die steht im Standard
auf dunkel (`ThemeController.standard`).

Auf einem hell gestellten Handy hieß das: Mocha-Grund mit braunem Zeichen,
dann der Sprung nach Deep Teal — bei jedem Kaltstart, für jeden, der nichts
umgestellt hat. Also für den Normalfall.

Der Splash trägt jetzt in beiden Schemata Deep Teal: in `pubspec.yaml`,
in `values-v31/styles.xml` und als `@color/splashHintergrund`, das kein
Gegenstück unter `values-night/` mehr hat. Wer in den Einstellungen auf „Hell"
umstellt, sieht den Sprung dafür andersherum. Das ist die kleinere Gruppe, und
es ist ihre bewusste Entscheidung gewesen.

Die saubere Lösung wäre, die Theme-Wahl zusätzlich dorthin zu schreiben, wo
die Android-Seite sie vor dem ersten Frame lesen kann. Das ist nativer Code in
zwei Sprachen für eine halbe Sekunde Bildschirm — nicht jetzt.

## 35 · Der Server lief eine Fassung hinterher — und was daraus folgt

Der Frauen-Modus war fertig, zweisprachig war fertig, alle Tests grün. Am
Gerät kam trotzdem ein deutscher Report zurück, mit Bart-Kapitel und ohne das
gewählte Make-up-Kapitel, und die Kopfzeile zählte ein Kapitel statt zwei.

**Die Ursache lag nicht im Code auf der Platte.** Die laufende Cloud Function
war vom 24.08.2026, 22:12 UTC — nachlesbar an
`source.storageSource.generation` in `firebase functions:list --json`. Die
drei Commits, die Sprache, Ausrichtung und das Make-up-Modul auf den Server
gebracht haben, sind vom 25.08. und waren nie ausgerollt.

Damit erklärt sich jede einzelne Auffälligkeit aus derselben Quelle: Der alte
Server kennt kein Feld `sprache` (Rückfall Deutsch), kein Feld `ausrichtung`
(Rückfall männlich, also Basis mit Bart) und den Modulnamen
`makeupAusstrahlung` nicht (fällt als unbekannt heraus, bleibt ein Kapitel).
Der Client hatte alles korrekt mitgeschickt.

**Was daraus folgt, ist nicht „besser aufpassen".** Ein Deploy, der vergessen
wird, sieht aus wie ein Fehler in der App: Nichts stürzt ab, nichts wird
protokolliert, die Rückfälle greifen genau so, wie sie sollen. Sie sind für
alte *Clients* gedacht — dass sie auch einen alten *Server* verdecken, war
nicht bedacht. Drei Dinge sind deshalb dazugekommen:

1. `SETUP.md` 5.5 sagt jetzt, wie man nachsieht, was oben liegt, statt den
   Schritt als einmalig erledigt zu führen.
2. Die Nachbereitung meldet einen Report in der falschen Sprache als Fehler
   ins Protokoll. Hätte es sie gegeben, wäre der erste englische Testlauf in
   den Logs aufgeschlagen.
3. Die Modulauswahl wird serverseitig gegen die Ausrichtung geprüft, statt
   sich auf den Prompt zu verlassen.

**Warum die Nachbereitung überhaupt siebt und nicht nur meldet:** Beim Bart
ist der Schaden nicht kosmetisch. Ein Bart-Kapitel im weiblichen Modus ist
genau die Art Fehler, die jemand als Aussage über sich liest. Ein Filter auf
den Sektionstiteln ist grob, aber er kann nur zu viel entfernen, nie zu
wenig — und was er entfernt, gehört in diesem Modus ohnehin nicht dorthin.

**Warum die falsche Sprache trotzdem durchgeht:** Sie lässt sich nicht
reparieren, nur neu erzeugen — und das kostet ein zweites Mal Kontingent.
Drei Läufe pro Tag sind knapp. Lieber ein Report in der falschen Sprache und
ein Eintrag im Protokoll als gar keiner.

## 36 · Was der Prompt wörtlich nennt, schreibt das Modell wörtlich ab

Im englischen Report des weiblichen Modus stimmte fast alles: Kapitel-
überschriften englisch, Fließtexte englisch, kein Bart. Die Überschriften der
Unterabschnitte hießen trotzdem „Frisur", „Augenbrauen", „Alltags-Look",
„Farben" — und die Kategorie eines Produkts „Pflege".

**Weil genau diese Wörter im Prompt standen.** Der Prompt ist auf Deutsch
(Begründung in 31), und in der Kapitelvorgabe stand „Sektionen: Frisur
(Schnitt, Länge …), Augenbrauen (Form und Pflege …)". Für das Modell ist das
kein deutscher Satz, sondern eine Liste von Namen — und Namen übersetzt man
nicht. Im männlichen Modus fiel es nicht auf, weil die Vorgabe dort knapper
ist („Sektionen: Frisur, Bart, bei Bedarf Brillenform") und das Modell sich
eigene Überschriften ausgedacht hat.

**Die Trennlinie liegt also nicht zwischen Prompt und Report, sondern
zwischen Anweisung und Ausgabe.** Eine Anweisung darf einsprachig bleiben —
sie wird gelesen, nicht abgeschrieben. Was das Modell wörtlich übernehmen
soll, muss in der Zielsprache dastehen. Die sechs Abschnittsnamen liegen
deshalb jetzt als `SEKTIONEN` zweisprachig in `labels.ts`, und die Vorgabe
sagt ausdrücklich: `Sektionen, deren "titel" GENAU so lautet: …`.

**Die Produktkategorie ist einen Schritt weiter gegangen und gar kein Wort
mehr.** Sie kommt aus einem kleinen, festen Vorrat — Reinigung, Pflege,
Styling, Werkzeug, Make-up, Kleidung, Sonstiges. So etwas gehört als Kennung
über die Leitung und nicht als Text, genau wie `modul`. Das Wort setzt die
App aus ihrer Übersetzung.

Der Nebeneffekt ist die Antwort auf die dritte Frage aus der Rückmeldung: Ein
Report, der auf Englisch entstanden ist, zeigt seine Kategorien auf Deutsch,
sobald jemand die App umstellt — ohne neuen Modellaufruf. Ein alter Report
ohne Kennung fällt auf sein gespeichertes Wort zurück; eine leere Pille wäre
schlechter als eine deutsche.

**Was beim Sprachwechsel nicht mitwandert und warum:** die Abschnitts-
überschriften und die Fließtexte. Das sind die eigenen Worte des Modells, in
freier Formulierung. Sie ließen sich nur übersetzen, indem man sie neu
erzeugen lässt — und das kostet ein zweites Mal Kontingent, bei drei Läufen
pro Tag. Die Kapitelüberschriften wandern übrigens längst mit: Sie standen
nie im gespeicherten Report, sondern kommen aus
`AnalyseModul.kapitel(L, Ausrichtung)`.

**Warum der Wächter aus 34 das nicht gefunden hat:** Er liest Dart-Dateien
unter `lib/`. Diese Wörter standen in TypeScript unter `functions/src/` — und
schlimmer, sie standen dort völlig zu Recht, nur eben in der falschen Rolle.
Sein Gegenstück auf dem Server (`test/prompt_sprache.test.ts`) prüft deshalb
nicht den Quelltext, sondern den **erzeugten** Prompt: Im englischen Prompt
darf kein deutscher Abschnittsname stehen. Das fängt auch den Namen, der
später dazukommt und beim Übersetzen vergessen wird.

## 37 · Der Freitext gehört in die Tagesliste, nicht in die Fließtexte

Bei „Deine Richtung" gibt es anklickbare Punkte und ein Freitextfeld. Die
Punkte sind grobe Überbegriffe zum Look und bleiben, wie sie sind. Das
Freitextfeld war bisher Stimmung: Es färbte die Fließtexte ein und verschwand
dann.

Gearbeitet wird aber mit der Checkliste. Ein Wunsch, der es nicht bis dorthin
schafft, ist für den Nutzer nicht passiert. Der Prompt verlangt deshalb jetzt
aus jedem Wunsch im Freitext eine bis drei tägliche Aufgaben.

**Warum „basis" als Auffangkapitel:** „Gepflegtere Hände" passt in kein
Kapitel. Ohne einen Ort, an dem so etwas landen darf, fällt es unter den
Tisch — und zwar unsichtbar, weil niemand vermisst, was er nicht sieht. Die
Basis gibt es immer.

**Warum Gewohnheits-Ziele eine eigene Sektion bekommen:** Eine abhakbare
Aufgabe allein ist noch keine Strategie. „Nicht rauchen" hilft niemandem;
„wenn nach dem Essen das Verlangen kommt, Kaugummi statt Zigarette" ist ein
Handgriff. Die Auslöser gehören benannt, sonst steht die Aufgabe ohne
Kontext da.

**Was der Prompt ausdrücklich verbietet:** Heilaussagen, Versprechen über
gesundheitliche Wirkungen, Zahlen zu Krankheitsrisiken, jeden Hinweis
darauf, was jemand bisher falsch gemacht hat. Bei einer Abhängigkeit einmal
beiläufig, dass es fachliche Unterstützung gibt — einmal, nicht als
Refrain. Wer „aufhören zu rauchen" in ein Styling-Programm schreibt, sucht
keinen Vortrag.

**Warum das ohne Freitext nichts ändert:** Die Regeln stehen nur im Prompt,
wenn das Feld gefüllt ist. Ein leeres Feld erzeugt denselben Prompt wie
vorher, und alte gespeicherte Analysen sind ohnehin unberührt — hier ändert
sich nichts am Datenformat.

## 38 · Die Erinnerung, die es nie gab

Die tägliche Erinnerung ist eine lokale Benachrichtigung, kein Server. Beim
Einbauen kam heraus, dass die **bestehende Check-in-Erinnerung nie
funktioniert haben kann.**

`flutter_local_notifications` braucht zwei Empfänger im Manifest. Der eine
stellt die Benachrichtigung zur geplanten Zeit überhaupt zu, der andere legt
die Termine nach einem Neustart des Geräts wieder an. Das Plugin bringt sie
**nicht** selbst mit — sein Manifest enthält zwei Berechtigungen und sonst
nichts. Sie standen nirgends.

Das ist die unangenehmste Sorte Fehler: Nichts stürzt ab, nichts wird
protokolliert, `zonedSchedule` meldet Erfolg, und die Benachrichtigung kommt
einfach nicht. Ein Test liest das Manifest jetzt und besteht auf beiden
Einträgen.

**Warum sieben Termine im Voraus geplant werden.** Eine lokale
Benachrichtigung kann beim Auslösen nichts prüfen; das Gerät zeigt an, was
vorher hinterlegt wurde. Ein einziger Termin hieße: Er feuert einmal, danach
ist Ruhe, bis jemand die App öffnet — ausgerechnet bei dem, den die
Erinnerung zurückholen soll.

Der heutige Termin steht nur, wenn heute noch nichts abgehakt ist. Die
künftigen stehen ohne Bedingung, und das ist kein Kompromiss, sondern
richtig: Abhaken geht nur in der App, und jedes Abhaken plant neu. Wer morgen
abhakt, löscht damit den Termin von morgen.

**Warum sie von Anfang an eingeschaltet ist.** Die Serie lebt vom täglichen
Abhaken, und wer eine Erinnerung erst suchen muss, schaltet sie nie ein.
Aufdringlich wird es dadurch nicht: ohne Systemberechtigung passiert nichts,
ohne Plan passiert nichts, und wer heute schon abgehakt hat, hört nichts.

**Warum nur einmal gefragt wird.** Wer ablehnt, hat geantwortet. Eine zweite
Frage beim nächsten Start wäre Drängeln. Die Ablehnung schaltet die
Einstellung gleich mit ab — sonst stünde in den Einstellungen ein Schalter
auf „an", während nichts passiert, und niemand käme auf die Idee, dass es an
einer Systemeinstellung liegt. Die Karte in den Einstellungen sieht deshalb
selbst nach und sagt es, wenn das System blockiert.

**Warum die Planung ungenau ist** (`inexactAllowWhileIdle`): Genaue Alarme
brauchen seit Android 14 eine eigene Berechtigung, die Google prüft. Für eine
Erinnerung, die „irgendwann am Abend" kommen soll, ist das der falsche
Preis.

## 39 · Persönliche Ziele sind ein eigenes Kapitel

Der Freitext bei „Deine Richtung" kommt seit DECISIONS 37 in der Tagesliste
an. Der Gerätetest hat gezeigt, dass er am falschen Ort ankommt: „Bei
Rauchverlangen sofort ein Glas kaltes Wasser trinken" stand unter „Haare &
Bart".

Das war kein Fehler des Modells, sondern die Regel. Sie lautete: in das
Kapitel, das inhaltlich am besten passt — und wenn es keins gibt, in die
Basis. Für „aufhören zu rauchen" gibt es kein passendes Look-Kapitel, also
gewinnt irgendeines. Das Ergebnis liest sich zusammengewürfelt und
beschädigt das Kapitel, in dem es landet.

**Was jetzt gilt:** Alles, was aus dem Freitext entsteht — Tagesaufgaben,
die Zielsektion, die Einleitung —, gehört in ein eigenes Kapitel
`persoenlicheZiele`, angezeigt als „Persönliche Ziele" bzw. „Personal
goals". Kein anderes Kapitel nimmt Freitext-Inhalte auf, die Basis
ausdrücklich auch nicht. Die Look-Kapitel bleiben bei ihrem Thema.

**Warum ein Modul und keine neue Struktur:** Ein Kapitel ist im Client
bereits alles, was gebraucht wird — Überschrift im Report, eigene Karte in
der Tagesliste, eigene Habits, die der Check-in anpassen kann. Ein zweiter
Weg daneben hätte jede dieser Stellen doppelt gebraucht. `AnalyseModul`
bekommt deshalb einen Wert mehr.

**Warum es trotzdem kein wählbares Modul ist:** Es hängt am Freitext, nicht
an einem Haken. `AnalyseModul.bestellbar` ist die Liste ohne es, und alles,
was mit *Auswahl* zu tun hat, arbeitet auf dieser Liste: die Modul-Karten,
„Analyse erweitern", die gespeicherte Auswahl, die Nutzlast an den Server,
der Foto-Flow, das Abzeichen „alle Module". Serverseitig steht dieselbe
Grenze noch einmal in `moduleFuer()` — ein manipulierter Client soll das
Kapitel nicht bestellen können, und ein Report ohne Freitext soll es nicht
enthalten. Die Nachbereitung wirft es heraus, wenn es trotzdem kommt.

**Warum die Zahl 4 bis 7 dort nicht gilt:** Ein Wunsch ergibt eine bis drei
Aufgaben. Wer sieben verlangt, bekommt vier erfundene.

**Preis:** Ein Enum-Wert mehr, den jeder erschöpfende `switch` über
`AnalyseModul` mitnehmen muss — vier Stellen, alle mit Übersetzung.
Bestehende Reports sind unberührt: Sie haben kein solches Kapitel, und ohne
Freitext entsteht auch keins.

## 40 · Der Report soll klingen wie ein Stylist, nicht wie eine Suchmaschine

Über mehrere Analysen hinweg kamen Empfehlungen zurück, die austauschbar
waren: Gesicht waschen, eincremen, Wasser trinken. Dazu Tagesaufgaben, deren
Zeitpunkt keinen Sinn ergab — den Bart abends in Form bringen, kurz bevor
man sich hinlegt und die Form im Kissen verschwindet.

Das Modell hat die Fotos gesehen. Es musste nur dazu gebracht werden, sie zu
benutzen. Der Prompt verlangt deshalb jetzt drei Dinge, jedes prüfbar an
einer einzelnen Zeile des Reports:

- **Beobachtung.** Jede Empfehlung knüpft an ein Merkmal an, das auf den
  Fotos zu sehen ist, und benennt es. Was ohne die Fotos genauso dastünde,
  ist eine Floskel und gehört gestrichen.
- **Zeitpunkt.** Jede Tagesaufgabe hat eine Tageszeit, die zu ihrem Zweck
  passt. Der Bart am Abend steht als Musterfall im Prompt — abstrakte Regeln
  („sinnvoller Zeitpunkt") blieben folgenlos, das Beispiel nicht.
- **Tiefe.** Basics dürfen vorkommen, aber nie allein: pro Kapitel
  mindestens eine Empfehlung mit Technik, Reihenfolge, typischem Fehler oder
  einem Kniff, den ein Laie nicht kennt.

**Warum die Beispiele beschrieben und nicht zitiert sind:** DECISIONS 36 —
was der Prompt wörtlich nennt, schreibt das Modell wörtlich ab. Ein deutsches
Musterhabit stünde sonst in einem englischen Report. Der Prompt beschreibt
das schlechte Beispiel deshalb, statt es als fertigen Satz anzubieten.

**Warum flache Aufgaben gezählt und nicht entfernt werden:** Die
Nachbereitung erkennt Aufgaben, die aus nichts als einem Gemeinplatz
bestehen („Gesicht waschen"), und schreibt sie ins Protokoll. Entfernen hieße
ersatzlos entfernen — eine Checkliste mit zwei Punkten ist schlechter als
eine mit einem flachen darin. Die Zahl im Log sagt uns, ob der Prompt wirkt;
sie ist ein Zählwerk, keine Qualitätsmessung, denn sie findet nur, was
jemand vorhergesehen hat.

**Warum das Modell dasselbe bleibt:** `gemini-3.5-flash-lite` kostet 0,30 $
je Million Eingabe-Token und 2,50 $ je Million Ausgabe-Token. Eine Analyse
mit elf Fotos liegt grob bei 14 000 Eingabe- und 5 000 Ausgabe-Token, also
rund **1,7 Cent**. `gemini-3.7-flash` läge bei 0,75 $ / 3,75 $ und damit bei
rund **2,9 Cent** je Analyse — ab dem 1. Januar 2027 bei 1,50 $ / 7,50 $ und
damit rund **6 Cent**. `gemini-3.5-flash` läge sofort bei rund 6,6 Cent.
Das ist eine Verdopplung bis Vervierfachung der Modellkosten für eine
Verbesserung, die der Prompt vielleicht schon allein bringt. Erst messen,
dann zahlen.

**Warum an der Antwortlänge nichts zu holen ist:** Die `generationConfig`
setzt kein `maxOutputTokens`. Es gibt also gar keine Obergrenze, die zu
lockern wäre — die Länge des Reports hängt allein am Prompt.

**Preis:** Der System-Prompt wird um gut 20 Zeilen länger und kostet bei
jedem Aufruf entsprechend mehr Eingabe-Token. Bei 0,30 $ je Million liegt
das im Bereich von Bruchteilen eines Cents.

## 41 · Der Wechsel auf `gemini-3.7-flash`

Der neue Prompt (DECISIONS 40) allein hat die Antworten nicht tief genug
gemacht — geprüft am Gerät, Befund: immer noch zu flach. Also das stärkere
Modell obendrauf, nicht stattdessen: Sämtliche Qualitätsregeln bleiben
unverändert aktiv, und die Gemeinplatz-Zählung im Protokoll bleibt drin.
Erst damit lässt sich später sagen, ob das Modell wirklich weniger Floskeln
liefert oder nur andere.

**Was der Wechsel technisch nach sich zieht.** Der Aufruf selbst bleibt
gleich — dieselbe URL, dieselben `inline_data`-Bilder, dasselbe
`responseMimeType: application/json`. Zwei Eigenschaften des neuen Modells
sind trotzdem relevant:

- **Es denkt vor der Antwort**, ab Werk auf Stufe „medium", und bei Gemini 3
  lässt sich das nicht abschalten. Das ist gewollt — es ist der Grund für
  den Wechsel. Es kostet aber Zeit: Das Zeitlimit je Gemini-Aufruf steigt
  von 60 s auf 120 s, die Function von 180 s auf 300 s, der Client von 150 s
  auf 280 s. Die drei Zahlen hängen zusammen (zwei Versuche müssen in die
  Function passen, der Client wartet knapp kürzer) und stehen deshalb im Test
  nebeneinander.
- **Seine Gedanken stehen nicht in der Antwort**, solange man sie nicht
  ausdrücklich anfordert. `textAusAntwort` siebt sie trotzdem aus: Ein
  Gedankenabschnitt im Antworttext würde das JSON unlesbar machen, und das
  fiele erst beim Nutzer auf. Dazu kommt eine Protokollzeile, wenn das Modell
  die Antwort mit etwas anderem als `STOP` beendet — dann weiß man beim
  nächsten „nicht lesbar", woran es lag.

**Was es wirklich kostet — Korrektur zu DECISIONS 40.** Dort stand „rund 2,9
Cent je Analyse". Diese Zahl war zu niedrig: Denk-Tokens werden wie
Ausgabe-Tokens abgerechnet, und ein Modell auf Stufe „medium" erzeugt davon
einige tausend. Realistischer sind bei elf Bildern:

| | Eingabe | Ausgabe inkl. Denken | je Analyse |
|---|---|---|---|
| bisher, `gemini-3.5-flash-lite` | 0,30 $/Mio. | 2,50 $/Mio. | rund 1,7 Cent |
| jetzt, `gemini-3.7-flash` | 0,75 $/Mio. | 3,75 $/Mio. | **rund 3 bis 5 Cent** |
| ab 01.01.2027 | 1,50 $/Mio. | 7,50 $/Mio. | rund 6 bis 10 Cent |

Die Spanne kommt daher, dass niemand vorher weiß, wie lange das Modell
nachdenkt.

**Deshalb steht der Verbrauch jetzt im Protokoll.** Jeder Aufruf schreibt
eine Zeile mit Eingabe-, Ausgabe- und Denk-Tokens — reine Zahlen, kein
Inhalt. Damit lässt sich der Preis eines einzelnen Laufs ausrechnen, statt
ihn zu schätzen; die Abrechnung in der Cloud-Konsole hinkt Stunden
hinterher und zeigt nur Summen. Wo man die Zeile liest, steht im Testplan,
Abschnitt 13.

**Preis:** Eine Analyse kostet das Zwei- bis Dreifache. Das ist die
Entscheidung, die getroffen wurde — die Analyse ist das Produkt. Die
Konsequenz daraus ist DECISIONS 42.

## 42 · Zehn Analysen im Monat, Check-ins zählen nicht mit

Mit dem teureren Modell sind dreißig Analysen im Monat kein sinnvoller
Deckel mehr. Neu: **zehn** pro Nutzer und Monat, die drei pro Tag bleiben
daneben stehen.

**Warum Kalendermonat und nicht rollierend.** Der Zähler steht ohnehin schon
auf einem Monatsschlüssel `jjjj-mm` in deutscher Zeit; ein rollierendes
Fenster hätte jeden einzelnen Zeitpunkt speichern müssen. Wichtiger ist aber
die Erklärbarkeit: „Am Ersten sind wieder zehn da" versteht jeder. Bei einem
rollierenden Fenster lautet die ehrliche Auskunft „in drei Tagen wird eine
frei, in sechs die nächste" — das kann niemand im Kopf mitführen, und ein
Nutzer, der am 12. seine zehnte verbraucht hat, weiß nicht, woran er ist.
Der Preis ist bekannt: Wer am 30. anfängt, hat zwei Tage später wieder zehn.
Das ist großzügig in eine Richtung und für niemanden nachteilig.

**Warum die Check-ins nicht mitzählen.** Die App lädt selbst an Tag 7, 14, 30
und dann alle 30 Tage zum Check-in ein. Zählte jeder davon gegen die zehn,
verbrauchte die App im ersten Monat vier bis fünf davon — der Nutzer bezahlt
dann mit seinem Kontingent dafür, dass die App ihn erinnert. Die zehn
gehören ihm ganz. Der Check-in hat weiterhin seinen eigenen Zähler; er ist
ohnehin ein viel kleinerer Aufruf (zwei Bilder statt bis zu elf).

**Warum die Ausnahme serverseitig hängt und nicht am Client.** Sonst wäre sie
ein Schlupfloch: Ein manipulierter Client meldet einfach jeden Aufruf als
Check-in und hat unbegrenzt Analysen. Der Server entscheidet deshalb selbst,
ob ein Check-in fällig ist — höchstens einer alle sieben Tage, festgehalten
in `users/{uid}/kontingent/checkin` im Feld `freiZuletzt`.

**Warum sieben Tage und nicht der echte Terminplan.** Der Server könnte den
Plan des Clients nachbauen (Tag 7, 14, 30, dann alle 30). Er tut es
ausdrücklich nicht: Zwei Terminkalender driften auseinander — bei einer
Neuinstallation, bei einem Gerätewechsel, bei einer Analyse, die den Plan
verschiebt —, und dann sperrt der Server einen Check-in aus, den die App
gerade anbietet. Sieben Tage sind der dichteste Takt, den die App je
verlangt. Diese untere Schranke weist nie einen echten Check-in ab und lässt
trotzdem kein Schlupfloch.

**Was mit einem Check-in außerhalb des Takts passiert:** Er wird nicht
abgewiesen, sondern auf das Analyse-Kontingent gebucht. Das ist die ehrliche
Einordnung — außerhalb des Rhythmus ist es etwas, das der Nutzer selbst
startet. Wer noch Kontingent hat, kommt also durch; wer keines mehr hat,
bekommt dieselbe Meldung wie bei einer Analyse.

**Die Freistellung wird im Voraus gebucht**, genau wie die Reservierung
selbst — sonst könnten mehrere gleichzeitige Aufrufe alle „fällig" sehen.
Zurückgenommen wird sie nur, wenn nachweislich kein Modellaufruf stattfand:
kein Schlüssel, ein Netzfehler vor der Antwort, oder ein Kontingent, das
schon vorher abgelehnt hat. Bei einer Zeitüberschreitung nicht — dort hat
das Modell gerechnet.

**Die Meldung in der App** unterscheidet jetzt Tages- und Monatsgrenze auch
im Fehlerfall, nicht nur im Hinweis vor der Aufnahme: Der Server schickt
`kontingentMonat` statt `kontingent`. Beide teilen sich denselben gRPC-Code,
damit ein Client, der den neuen Namen nicht kennt, weiterhin die allgemeine
Kontingentmeldung zeigt statt eines Serverfehlers. Der Text sagt, wann es
wieder losgeht und dass die Check-ins weiterlaufen.

**Preis:** Ein Feld mehr im Kontingent-Dokument und ein Zweig mehr im
Check-in-Pfad. Zum Zurücksetzen beim Testen reicht weiterhin die
Firebase-Konsole — wie, steht in `SETUP.md` 6.6.

## 43 · Der Streak-Joker

Eine Serie, die beim ersten vergessenen Tag auf null fällt, bestraft genau
den, den sie tragen soll. Neu: **zwei Joker pro Kalendermonat**. Verpasst
jemand einen Tag, springt automatisch einer ein — ohne Knopf, ohne Nachfrage.

**Warum der gerettete Tag nicht mitzählt.** „Tage am Stück" sind Tage, an
denen wirklich etwas passiert ist. Ein Joker hält die Kette zusammen, aber er
erfindet keinen Tag. Zählte er mit, stünde in der App eine Zahl, die dem
Nutzer mehr erzählt, als er getan hat — und der erste, dem das auffällt, ist
er selbst.

**Warum ein Joker nie am losen Ende ausgegeben wird.** Das ist die Falle, in
die man bei so etwas läuft: Beim allerersten Start ist jeder Tag rückwärts
leer. Eine naive Rechnung setzt zwei Joker und meldet eine Serie von zwei
Tagen aus dem Nichts. Deshalb wird ein Joker erst gültig, wenn dahinter noch
ein wirklich geschaffter Tag kommt — er darf eine Lücke *überbrücken*, nicht
den Anfang erfinden. Zwei Tests decken genau diesen Fall ab.

**Warum verbrauchte Joker festgeschrieben werden.** Die Serie wird bei jedem
Laden neu aus den Tagesdaten gerechnet (das war schon vorher so und ist
richtig — sonst stimmt sie nicht, wenn die App tagelang zu war). Ohne
Festschreiben spränge derselbe Joker bei jedem Laden erneut ein, und das
Monatskontingent wäre eine Zierde. Die geretteten Tage stehen deshalb als
Liste im Speicher, direkt neben der Serie.

**Warum Kalendermonat.** Dieselbe Überlegung wie beim Analyse-Kontingent
(DECISIONS 42): „am Ersten wieder zwei" versteht jeder. Maßgeblich ist dabei
der Monat des *geretteten Tages*, nicht der von heute — eine Lücke über den
Monatswechsel zahlen deshalb beide Monate je zur Hälfte.

**Der Ton, wenn es doch reißt.** Keine dramatische Null: Steht die Serie auf
0 und gab es schon einmal eine, sagt die Karte „Neustart — dein längster
Streak bleibt dir erhalten." Der Rekord wurde ohnehin schon gespeichert; er
wird jetzt auch angezeigt, sobald er von der laufenden Serie abweicht.

**Preis:** Zwei Schlüssel mehr im Speicher und eine Serienrechnung, die man
nicht mehr in drei Zeilen liest. Dafür liegt sie jetzt als freie Funktion
ohne Speicher da und lässt sich vollständig durchspielen.

## 44 · Wenn-dann-Anker an jeder Tagesaufgabe

„Gesicht eincremen" ist ein Vorsatz. „Nach dem Zähneputzen: Gesicht
eincremen" ist ein Ablauf. Der Unterschied ist die am besten belegte Technik,
mit der aus Aufgaben Gewohnheiten werden: Die neue Handlung hängt an etwas,
das ohnehin jeden Tag passiert, und braucht deshalb keine eigene Erinnerung.

Der Prompt verlangt das jetzt für **jede** Aufgabe in `habits`, in jedem
Kapitel: erst der Auslöser, dann ein Doppelpunkt, dann die Handlung.

**Warum eine feste Liste von Ankern.** Ein Modell, das sich den Auslöser
selbst ausdenkt, landet bei „wenn du Zeit hast" oder „um 7 Uhr". Das erste
ist kein Anker, das zweite ist eine Uhrzeit, die für die Hälfte der Nutzer
falsch ist. Die Liste in `labels.ts` nennt sieben Routinen, die praktisch
jeder Alltag hergibt — und der Prompt verbietet Uhrzeiten und vage Angaben
ausdrücklich.

**Warum die Anker zweisprachig sind.** DECISIONS 36: Was der Prompt wörtlich
nennt, schreibt das Modell wörtlich ab. Stünde die Liste nur auf Deutsch,
begänne im englischen Report jede Aufgabe mit „Nach dem Zähneputzen". Ein
Test geht deshalb jeden Anker durch und besteht darauf, dass im englischen
Prompt keine einzige deutsche Fassung auftaucht. Beim Schreiben ist genau das
einmal passiert — ein Beispielsatz in der Regel selbst nannte einen deutschen
Anker.

**Warum Aufgaben aus dem Freitext eine Sonderform bekommen.** Für „aufhören
zu rauchen" ist die passende Kopplung nicht das Zähneputzen, sondern das
Verlangen. Die Form bleibt gleich (Auslöser, Doppelpunkt, Handlung), der
Auslöser darf dort eine Situation sein statt einer Routine. Das ist derselbe
Mechanismus, nur mit einem anderen Wenn.

**Warum derselbe Anker höchstens zweimal vorkommt.** Sonst hängen sieben
Aufgaben am selben Moment. Das ist keine Routine mehr, sondern ein Stau — und
der erste Tag, an dem es eng wird, kippt gleich sieben Haken.

**Die Zeichengrenze steigt von 60 auf 80.** Ein Anker vorn kostet Platz. Bei
60 Zeichen hätte das Modell entweder den Anker oder die Handlung
zusammengestrichen; beides wäre schlechter als eine Zeile, die einmal
umbricht. Die Checklisten-Zeile bricht ohnehin um. Dieselbe Zahl steht auch
im Check-in-Prompt, damit ein nachgebesserter Habit nicht plötzlich kürzer
sein muss als der, den er ersetzt.

**Preis:** Der System-Prompt wird noch einmal etwa 15 Zeilen länger, und die
Aufgaben in der Tagesliste sind länger als vorher. Das ist der Punkt der
Übung.

## 45 · Der Moment nach dem ersten Haken

Beim ersten abgehakten Punkt des Tages flackert die Flamme auf — das war
schon so. Neu ist die Bestätigung darunter: „Tag gesichert!" plus der Stand
der Serie, fünf Sekunden lang, dann blendet sie sich von selbst aus.

**Warum kein Dialog und kein Vollbild.** Dieser Moment kommt jeden Tag. Was
jeden Tag kommt und weggeklickt werden muss, ist nach einer Woche eine
Belästigung — und der Nutzer klickt es dann weg, ohne es zu lesen. Deshalb:
in der Karte, auf die er ohnehin schaut, kurz, und ohne Knopf.

Der Jubel-Dialog für Abzeichen bleibt davon unberührt. Der ist selten (acht
Mal insgesamt) und darf deshalb groß sein.

**Warum genau einmal pro Tag.** Ausgelöst wird nicht am Haken, sondern am
Übergang „heute noch nichts" → „heute gesichert". Jeder weitere Haken am
selben Tag ändert diesen Zustand nicht mehr. Ein Test hakt zweimal ab und
besteht darauf, dass der Moment nicht wiederkommt.

**Warum er nicht beim Zurückkommen erneut auftaucht.** Der Übergang wird im
Widget-Zustand gemerkt, nicht gespeichert. Wer den Bildschirm verlässt und
zurückkommt, startet ohne Vorzustand — und ein Übergang von „unbekannt" nach
„gesichert" zählt nicht. Das ist genau richtig: Gefeiert wird der Moment, in
dem es passiert, nicht der Zustand danach.

**Barrierefreiheit:** Die Bestätigung ist eine `liveRegion` — TalkBack liest
sie einmal vor, wenn sie erscheint. Bei „Bewegung reduzieren" erscheint sie
ohne Animation, aber sie erscheint.

**Preis:** Ein Timer mehr im Widget-Zustand. Die Karte ist beim Bauen um zwei
kleine Widgets gewachsen, dafür ist die Serien-Zeile jetzt ein eigenes Widget
und nicht mehr eine `build`-Methode über hundert Zeilen.

## 46 · Der Wochen-Rückblick — und warum er nicht klingelt

Sonntagabend zeigt die Startseite eine kleine Bilanz der Woche: aktive Tage,
abgehakte Aufgaben, das Kapitel mit den meisten Haken als „dein stärkster
Bereich". Alles aus den Haken gerechnet, die ohnehin lokal und in Firestore
liegen — kein Modellaufruf, keine Kosten.

**Warum ein Fenster von Sonntag 18 Uhr bis Montagnacht.** „Sonntagabend"
trifft nur, wer am Sonntagabend hineinsieht. Der Montag hängt mit dran, damit
der Rückblick nicht ausgerechnet an denen vorbeiläuft, die ihn am ehesten
brauchen: an denen, die das Wochenende über nicht in der App waren. Ab
Dienstag ist er weg — eine Bilanz, die vier Tage alt ist, interessiert
niemanden mehr.

**Warum es keine Benachrichtigung dazu gibt.** Das war ausdrücklich zur
Entscheidung gestellt, und die Antwort ist nein. Es gibt bereits zwei Kanäle:
die tägliche Erinnerung ans Abhaken und die Check-in-Erinnerung. Ein dritter
für etwas, das keine Handlung verlangt, ist Lärm — der Rückblick ist eine
Information, kein Termin. Wer die App am Sonntagabend oder Montag öffnet,
sieht ihn; wer sie nicht öffnet, hat nichts verpasst. Eine Push dafür wäre
die erste, die man abschaltet, und sie würde die Aufmerksamkeit für die
beiden Kanäle mitnehmen, die etwas wert sind.

**Der Ton ist die halbe Funktion.** Vier Stufen, alle anerkennend: ab fünf
Tagen „starke Woche", bei drei bis vier „solide", bei zwei „zwei Tage sind
zwei mehr als keiner", bei null oder eins „neue Woche, neue Chance — ein
Haken reicht für den Anfang". Kein „leider", keine Prozentzahl, kein
Vergleich mit der Vorwoche. Wer nach einer schlechten Woche eine Rechnung
präsentiert bekommt, macht die App nicht wieder auf.

**Was nicht gezeigt wird:** Ohne einen einzigen Haken fehlt die Zeile
„stärkster Bereich" ganz. „Dein stärkster Bereich: —" wäre Hohn.

**Warum der Check-in-Marker nicht als Aufgabe zählt.** Er liegt im selben
Topf wie die Haken, damit der Streak ihn ohne Sonderweg mitzählt (das war
schon so). In der Aufgabenzahl der Woche hätte er nichts zu suchen — er ist
ein gesicherter Tag, keine erledigte Tagesaufgabe.

**Warum unbekannte Aufgaben in die Summe zählen, aber auf keinen Bereich.**
Nach einer neuen Analyse steht in den zurückliegenden Tagen Text, den es im
aktuellen Report nicht mehr gibt. Diese Haken sind trotzdem passiert und
gehören in die Zahl. Sie einem Kapitel zuzuordnen ginge nur mit Raten, und
das würde den stärksten Bereich stillschweigend verschieben.

**Preis:** Ein Schlüssel mehr im Fortschritts-Speicher (welche Woche
weggeklickt wurde) und eine Karte, die an zwei von sieben Tagen auf der
Startseite steht.

## 47 · Wochen-Challenges aus einem festen Vorrat

Jede Woche eine kleine Extra-Aufgabe über die Tagesliste hinaus: „Schaffe an
2 Tagen deine komplette Checkliste", „Hake 4 Tage in Folge mindestens einen
Punkt ab". Zehn Vorlagen, aus denen wöchentlich rotiert wird. Alles daran
wird aus den vorhandenen Haken gerechnet — kein Modellaufruf, keine Kosten.

**Warum sechs Sorten und zehn Vorlagen.** Eine Vorlage ist eine Sorte plus
eine Zielzahl. So braucht jede Sorte nur **einen** Satz Text mit einer
Zahl darin, und aus sechs Sätzen entstehen zehn Wochen. Zehn einzelne
Textbausteine hätten zwanzig ARB-Einträge gekostet und wären die erste
Stelle gewesen, an der eine Übersetzung fehlt.

**Warum die Reihenfolge im Vorrat die Rotation ist.** Kein Zufall, keine
Auswahl nach Können: Ein Zufallsgenerator kann dieselbe Challenge zweimal
hintereinander ziehen, und eine Auswahl nach Können bräuchte eine Bewertung
des Nutzers — genau das, was die App an keiner Stelle tut. Die Liste
wechselt bewusst zwischen leicht und schwer, damit nicht zwei harte Wochen
aufeinandertreffen. Ein Test besteht darauf, dass keine zwei
aufeinanderfolgenden Wochen dieselbe Vorlage ziehen.

**Warum eine feste Epoche.** Die Woche wird über den Abstand zu Montag, dem
5. Januar 2026 gerechnet. Damit zeigt jedes Gerät dieselbe Challenge — ohne
Server, ohne Sync. Ein Gerät mit falsch gestelltem Datum landet vor der
Epoche; die Rechnung fängt das ab, statt einen negativen Index zu erzeugen.

**Warum einmal geschafft geschafft bleibt.** Die Challenge wird bei jedem
Haken neu gerechnet. Ohne Vermerk verschwände ein erreichtes „Geschafft!"
wieder, sobald jemand einen Haken zurücknimmt — und das wäre eine Bestrafung
für das Korrigieren eines Versehens.

**Warum eine verpasste Woche nicht vermerkt wird.** Gespeichert werden nur
die geschafften Wochen. Es gibt kein „leider verpasst" und keine Statistik
darüber, was nicht geklappt hat. Am Montag steht die nächste Challenge da,
und das ist die einzige Nachricht, die an dieser Stelle hilft.

**Das Abzeichen** heißt „Vier Wochen, vier Ziele" und fällt nach vier
geschafften Challenges. Es hängt als dritter Wert nicht am Streak, sondern an
dieser Zahl — die Abzeichen-Liste kannte diesen Fall schon (erste Analyse,
alle Module), es kam nur ein Zweig dazu.

**Preis:** Ein Schlüssel mehr im Fortschritts-Speicher und eine Karte mehr
auf der Startseite. Die Startseite wird länger; das ist der Punkt, an dem
irgendwann zu überlegen ist, ob Serie, Challenge und Rückblick
zusammenrücken.

## 48 · Fortschritts-Fotos: gespeichert nur hier, gezeigt auch dem Modell

Bisher gab es ein Fortschrittsfoto nur beim Wirkungs-Check alle dreißig Tage.
Neu: Es wird bei **jedem** Check-in angeboten (freiwillig, überspringbar),
und es gibt ein Album mit Vorher-Nachher-Vergleich und Zeitleiste.

**Warum bei jedem Check-in.** Ein Tagebuch mit einem Eintrag alle dreißig
Tage ist keins. Wer alle sieben bis vierzehn Tage ein Bild hat, sieht eine
Entwicklung; wer drei Bilder im Jahr hat, sieht drei Bilder.

**Wo die Grenze wirklich verläuft — Korrektur vom 26.08.2026.** Diese
Entscheidung stand hier zwischenzeitlich schärfer, als sie gemeint war: Die
Fotos gingen gar nicht mehr an das Modell, und der Wirkungs-Check verlor
seinen Bildvergleich. Die Anforderung lautete aber „keine Fotos **dauerhaft
auf einem Server**" — nicht „keine Fotos an die API".

Die Grenze liegt also bei **speichern**, nicht bei **anschauen**:

- **Gespeichert** werden die Bilder ausschließlich im privaten
  Dokumentverzeichnis der App (`glowup_fotos`). Nicht in der Galerie, nicht
  in Googles Backup, nirgends auf einem Server.
- **Angesehen** werden darf das Startfoto zusammen mit dem aktuellen beim
  Wirkungs-Check, damit das Zwischenfazit auf einem echten Vergleich fußt.
  Sie laufen dabei denselben Weg wie die elf Fotos der Erst-Analyse: durch
  den Arbeitsspeicher der Cloud Function, ohne abgelegt oder protokolliert
  zu werden.

**Warum nicht „direkt an die API".** Das hieße, den Gemini-Schlüssel in die
App zu legen. Er wäre damit aus jedem APK auslesbar, und jeder Fremdverbrauch
ginge auf unsere Rechnung — der Grund, aus dem der Proxy überhaupt existiert
(DECISIONS 2). Der Proxy speichert nichts; er ist genau die Stelle, an der
die Analyse-Fotos schon immer vorbeikommen.

**Warum nur der Wirkungs-Check Fotos mitschickt.** Ein Zwischenfazit gibt es
nur dort. Bei Tag 7 und Tag 14 kosteten zwei Bilder Tokens für eine Aussage,
die niemand anfordert. Die Bedingung heißt deshalb `fotosZurAuswertung` und
sitzt im Modell neben `mitFortschrittsfoto` — sie ausgerechnet an letzterem
festzumachen ginge nicht mehr, das ist seit diesem Paket überall wahr.

**Was doch in die Cloud geht: der Dateiname.** Der Check-in wird
synchronisiert, und in ihm steht der Pfad des Fotos. Das ist kein Bild,
sondern eine Zeichenkette. Auf einem zweiten Gerät zeigt das Album dort einen
Platzhalter „nicht auf diesem Gerät". Den Pfad ebenfalls herauszuhalten hätte
einen zweiten, lokalen Speicher für dieselben Daten bedeutet — der
schlechtere Tausch. In der **Nutzlast an die Function** steht er
ausdrücklich nicht; ein Test besteht darauf.

**Warum die Backup-Ausschlüsse einen Test bekommen haben.**
`allowBackup="false"`, `fullBackupContent="false"` und die vollständigen
Ausschlüsse in `datenausnahmen.xml` für Cloud-Backup **und** Gerätewechsel
gab es schon. Ohne sie wandern die Bilder über Googles automatisches Backup
in die Cloud — und niemand merkt es, weil nichts abstürzt. Das ist die Art
Zusicherung, die still bricht; sie gehört unter einen Test.

**Warum ein Schieberegler und nicht zwei Bilder nebeneinander.** Bei einem
Gesicht zählen Details, und nebeneinander ist jedes Bild nur halb so breit.
Der Regler lässt beide in voller Größe und legt sie exakt übereinander. Der
Zwei-Bilder-Vergleich im Check-in selbst bleibt daneben bestehen — dort geht
es um genau zwei Bilder, im Album um die ganze Reihe.

**Was sich löschen lässt.** Jedes Foto einzeln, mit Rückfrage. Der Check-in
dahinter bleibt stehen: Seine Antworten haben den Plan geformt und gehören
zur Geschichte. Nur das Startfoto ist nicht löschbar — es gehört zur Analyse.

**Der Hinweis kommt einmal.** Beim ersten Besuch des Albums als Dialog,
danach als Karte am Fuß des Bildschirms. Er sagt ausdrücklich, dass die
Bilder bei einem Handywechsel oder einer Neuinstallation weg sind. Das ist
die unangenehme Hälfte der Zusicherung, und sie gehört genauso deutlich dazu
wie die angenehme.

**Preis:** Ein Bildschirm und zwei Einstiege mehr. Der Wirkungs-Check kostet
weiterhin zwei Bilder an Eingabe-Tokens — dafür steht sein Fazit auf etwas
Sichtbarem statt nur auf Ankreuzfeldern.

## 49 · Ein Start statt zwei

Beim Öffnen kamen zwei Bildschirme nacheinander: der native Android-Splash
mit dem Zeichen, danach der eigene mit Zeichen **und** Schriftzug. Beide
blendeten auf, und das Zeichen sprang dabei von der Bildschirmmitte ein Stück
nach oben. Es sah aus wie zweimal starten.

Zwei Ursachen, zwei Handgriffe:

**1. Die Lücke dazwischen.** Der native Splash verschwindet, sobald Flutter
den ersten Frame malt — und das ist ein leerer Frame, bevor der eigene
Startbildschirm steht. `FlutterNativeSplash.preserve()` hält ihn fest, bis
die App gezeichnet hat; freigegeben wird er im ersten `postFrameCallback`.

Die Freigabe läuft über **eine** Funktion (`_starten`), durch die alle
Startwege gehen. Das ist wichtiger, als es aussieht: Ein `runApp`, das sie
vergisst — etwa der Einrichtungs-Hinweis ohne Firebase —, ließe den nativen
Splash für immer über der App stehen. Ein Startbildschirm, der nie weggeht,
ist der unangenehmste Fehler dieser Art, weil er wie ein Absturz aussieht.

**2. Der Sprung.** Der eigene Schirm zeigte Zeichen und Schriftzug in einer
`Column`, und die zentriert **beides zusammen** — das Zeichen saß also rund
34 dp höher als beim nativen Splash. Dazu blendete es von 0 auf 1 ein,
obwohl es längst zu sehen war.

Jetzt steht das Zeichen exakt in der Bildschirmmitte, in derselben Größe wie
zuvor, und **bewegt sich nicht**. Der Schriftzug liegt in einem `Stack`
darunter und kommt allein — eine halbe Sekunde, acht Pixel von unten.

**Die Größe ist eine gerechnete Zahl, keine geschätzte.** Ab Android 12
zeichnet das System das Symbol in eine Fläche von 240 dp; unser Motiv füllt
davon 52 % (`motivAnteil` in `tool/marke_erzeugen.dart`), also rund 125 dp.
Genau diese Zahl steht jetzt im Startbildschirm, mit dem Verweis darauf, wo
sie herkommt. Vorher stand dort 132 — nah dran, aber eben nicht gleich.

**Was auf Geräten vor Android 12 bleibt:** Dort ist das Motiv im nativen
Splash kleiner (rund 102 dp), und das Zeichen wächst beim Übergang leicht.
Das ist eine weiche Bewegung, kein Bruch. Es gleichzuziehen hieße, die
Markengrafiken neu zu erzeugen und `flutter_native_splash:create` laufen zu
lassen — das schreibt `styles.xml` neu und macht drei sorgfältig
kommentierte Dateien kaputt, für ein Detail auf Geräten, die es kaum noch
gibt.

**Preis:** `flutter_native_splash` ist von einer dev_dependency zu einer
echten Abhängigkeit geworden — es ist jetzt nicht mehr nur Generator,
sondern auch Laufzeit.

## 50 · Der Petrol-Look bekommt Tiefe und genau eine Akzentfarbe

Kein Neuaufbau, nur Optik: Aufbau, Navigation und Reihenfolge der Karten
bleiben, wie sie waren. Geändert haben sich fünf Dinge.

**1. Der Grund ist ein Verlauf.** Von Deep Teal oben zu einem fast
schwarzblauen Ton unten (`hintergrundTief`). Er liegt in `AppPage` **hinter**
dem Scaffold, damit auch die Flächen hinter AppBar und Aktionsleiste ihn
tragen — sonst hätte die Seite oben und unten je eine Kante.

Er liegt damit auf **allen** Seiten, nicht nur auf der Startseite. Das ist
Absicht: Ein Grund, der beim Wechsel von der Startseite zum Plan die Farbe
wechselt, sieht nicht nach Design aus, sondern nach Fehler. Zwei Tests halten
ihn im Zaum — er muss dunkler enden, als er anfängt, aber so dezent bleiben,
dass eine Karte an beiden Enden abhebt (unter 2,2:1 Unterschied).

**2. Karten sind Licht, kein Kasten.** Sie liegen leicht durchscheinend über
dem Verlauf (78 % im dunklen Schema, 92 % im hellen), haben eine weichere
Rundung (26 statt 20) und statt eines Schattens eine hauchdünne helle Kontur
— eine Spur Textfarbe bei 10 % Deckkraft. `rand` wäre dafür zu kräftig
gewesen und zöge eine sichtbare Linie um jede Karte. Der Schlagschatten im
hellen Schema ist ersatzlos weg: Auf einem Verlauf sieht er schmutzig aus.

**3. Gold heißt „geschafft" — und sonst nichts.** Neue Farbrolle `erreicht`,
ein warmes gedämpftes Gold. Sie steht an genau fünf Stellen: Streak-Flamme
und Streak-Zahl, gesetzte Haken, gefüllte Fortschrittssegmente,
freigeschaltete Abzeichen, Joker-Schilde. Dazu das frisch freigeschaltete
Abzeichen im Jubel-Dialog — dasselbe Abzeichen, dieselbe Farbe.

Das ist die ganze Idee: **Wenn Gold überall auftaucht, heißt es nichts
mehr.** Buttons, Titel, Karten-Icons und der „Neu ab heute"-Marker bleiben
deshalb im Sand-Ton. Und was halb fertig ist, ist nicht golden: Der
Checklisten-Zähler wechselt erst bei „4/4", die Flamme erst, wenn der Tag
steht, die Abzeichen-Bilanz erst ab dem ersten erreichten.

Beide Töne tragen kleine Schrift — die Zeile „Geschafft!" ist 12 Punkt —,
also gilt für sie dieselbe Schwelle wie für jeden Text: 4,5:1 auf jeder
Fläche, geprüft in `farbschema_test.dart`. Im hellen Schema hat das Gold
ausdrücklich **keinen** Blauanteil (`#7A5200`): Sonst wäre es vom
Mocha-Akzent kaum zu unterscheiden, und genau das darf es nicht sein. Ein
Test besteht auf dem Abstand.

**4. Die Streak-Karte trägt die Serie.** Flamme von 64 auf 76 dp, Symbol von
32 auf 38, Zahl von 34 auf 44. Hinter der Flamme liegt ein Schein — weit
gestreut, 22 % Deckkraft, und nur, wenn der Tag steht. Er soll als Wärme um
die Flamme wirken, nicht als Ring; ein Leuchteffekt wäre genau das, was der
Auftrag ausschließt.

**5. Segmente statt Balken.** Ein durchgehender Balken sagt „irgendwo
dazwischen". Segmente sagen „drei von vier" — dieselbe Information, aber
abzählbar. Ein Segment je Zieleinheit; ab elf wird gebündelt, weil
fünfundzwanzig Striche nebeneinander kein Fortschritt mehr sind, sondern ein
Zaun. Gebündelt wird auf einen **Teiler** des Ziels, damit jedes Segment
gleich viel wert ist: 15 → fünf zu drei, 25 → fünf zu fünf. Ein Test geht
den ganzen Vorrat durch und besteht darauf, dass die Rechnung aufgeht.

**6. Abzeichen als Reihe.** Vorher acht Zeilen untereinander, die den halben
Bildschirm füllten und fast nur Gesperrtes zeigten. Jetzt eine waagerechte
Reihe: Erreichtes vorn im Blick, Gesperrtes grau mit kleinem Schloss, und
„noch 3 Tage" steht weiterhin darunter. Die Beschreibung ist nicht
verschwunden, sie liegt als Tooltip auf dem Abzeichen und wird von TalkBack
mitgelesen.

Dabei sind zwei fest verdrahtete deutsche Texte herausgeflogen („Deine
Abzeichen", „Rekord: 3 Tage") — sie standen dort seit jeher und wären einem
englischen Nutzer auf Deutsch begegnet.

**7. Micro-Animationen, alle unter einer halben Sekunde.** Der Haken zoomt
beim Setzen kurz ein (220 ms) — beim Entfernen nicht, gefeiert wird das
Abhaken. Die Segmente füllen sich beim Öffnen nacheinander (40 ms Versatz,
220 ms je Segment). Die Streak-Zahl zählt einmal hoch (450 ms), gebunden an
die Zahl selbst, damit sie beim Abhaken nicht ein zweites Mal losläuft —
dafür gibt es schon die Bestätigung darunter. Jede dieser Bewegungen
respektiert „Bewegung reduzieren" und steht dann sofort.

**Preis:** Zwei Farbrollen mehr in `AppColors`, und jede neue Farbe muss ab
jetzt durch die Kontrastprüfung. Das Design lässt sich als ein Commit
zurückdrehen; der Splash-Umbau (DECISIONS 49) hängt nicht daran.

## 51 · Das Design gilt überall — und ein Test besteht darauf

Nach dem Umbau (DECISIONS 50) trug die Startseite den neuen Look, die
Unterseiten nur den Hintergrund. Auf „Analyse zusammenstellen" standen noch
die alten Auswahlhäkchen, die alten Kartenrahmen und ein Button, der daneben
alt aussah.

**Die Ursache war keine vergessene Stelle, sondern eine fehlende Rolle.** Das
Theme rechnete sich die neue hauchdünne Kartenkontur in `_bauen` selbst aus.
Jede handgebaute Karte auf einer Unterseite griff dagegen weiter zu `rand` —
und `rand` gab es ja noch, also fiel nichts auf. Die Kontur ist deshalb jetzt
eine eigene Farbrolle `kartenrand` in `AppColors`, und alle greifen dorthin.
Dasselbe gilt für den Auswahlzustand: Er hieß an zwölf Stellen
`aktiv ? farben.akzent : farben.rand`, jedes Mal einzeln ausgeschrieben.

**Gold heißt jetzt auch „ausgewählt".** Bisher stand es nur für Erreichtes.
Es steht ab sofort an jedem Zustand, den der Nutzer selbst eingeschaltet
hat: gewählte Module und ihr Häkchen, angeklickte Chips im Onboarding, im
Stil-Fragebogen und bei „Deine Richtung", die Antwortknöpfe im Check-in, das
gewählte Foto in der Zeitleiste, Checkboxen, Radios und der Umschalter in
den Einstellungen. Dazu die zurückgelegten Schritte im Foto-Flow, im
Onboarding und im Check-in — ein erledigter Schritt ist Erreichtes.

Die Regel bleibt dieselbe und wird dadurch sogar schärfer: **Gold heißt „das
ist an".** Was noch offen ist, bleibt grau; was nur ein Angebot ist — Buttons,
Titel, Icons — bleibt im Sand-Ton.

**Zwei Werte ändern sich für die ganze App**, und damit auch für die zwei
Knöpfe auf der Startseite, die sonst unangetastet bleibt: Der Umriss-Button
trägt dieselbe Kontur wie eine Karte (zwei verschiedene Randstärken
untereinander sehen nach Versehen aus), und der Button-Radius geht von 14 auf
18. Kantige Knöpfe unter sehr weichen Karten waren genau der Bruch, der auf
„Analyse zusammenstellen" auffiel. 18 statt 26: Ein Button darf fester
wirken als eine Karte, nur nicht wie aus einem anderen Programm.

**Der Test, damit es nicht wieder halb passiert.** `design_werte_test.dart`
liest den ganzen Quelltext und besteht darauf, dass außerhalb einer kurzen
Ausnahmeliste kein `Color(0x…)` und kein `Colors.rot` steht. Die Ausnahmen
tragen ihren Grund im Code, und zwei weitere Tests halten die Liste sauber:
Eine Ausnahme für eine gelöschte Datei fliegt auf, und eine Farbrolle, die
niemand mehr benutzt, ebenfalls.

**Was ausdrücklich eine feste Farbe behalten darf:** alles, was über einem
Kamerabild oder einem Foto liegt. Dort ist der Untergrund beliebig, und
Schwarz oder Weiß ist das Einzige, was in jedem Fall lesbar bleibt. Eine
Themefarbe wäre dort nicht konsequenter, sondern nur unlesbarer.

**Preis:** Eine Farbrolle mehr und ein Test, der bei jeder neuen Farbe
anspringt. Genau das ist der Sinn.

## 52 · Woran der Start-Übergang wirklich lag

DECISIONS 49 hat den Übergang für behoben erklärt. Am Gerät war er es nicht.
Diesmal wurde nicht gerechnet, sondern gemessen: Kaltstart mit
`adb shell screenrecord`, Einzelbilder mit ffmpeg, und dann das Zeichen in
beiden Phasen ausgemessen. Samsung SM A525F, 1080 × 2400 bei 420 dpi, also
2,625 px je dp.

**Befund vorher:**

| | Zeichen breit | Zeichen hoch | Mitte (y) |
|---|---|---|---|
| System-Splash | 255 px | 304 px | 1203 |
| eigener Splash | 214 px | 253 px | 1138 |

Zwei Fehler, beide sichtbar, beide von mir:

**1. Das Zeichen war ein Fünftel zu klein.** DECISIONS 49 rechnete mit einer
Symbolfläche von 240 dp — dem Wert für ein Startsymbol **mit** eigenem
Hintergrund. Die Messung ergibt 288 dp, den Wert **ohne**. Der Eintrag
`icon_background_color` stand zwar in der Konfiguration, wirkte aber nicht.
Er ist jetzt raus, und die Fläche steht als `Marke.splashFlaecheDp = 288`
neben dem Motivanteil, aus dem `tool/marke_erzeugen.dart` das PNG rechnet.
Der Startbildschirm leitet seine Größe daraus ab, statt eine eigene Zahl zu
führen. 288 × 0,52 = 149,8 dp.

**2. Das Zeichen saß 24 dp zu hoch** — die halbe Höhe der Navigationsleiste.
Der System-Splash gehört dem System und wird über den **ganzen Bildschirm**
gezeichnet. Das Fenster der App ist kleiner: Es endet über der
Navigationsleiste, weil `windowDrawsSystemBarBackgrounds` aus ist. Alles,
was die App zentriert, sitzt deshalb um deren halbe Höhe zu hoch.

Der Ausgleich kann **nicht** über `MediaQuery` kommen: `MediaQuery.size` ist
die Größe des Fensters, und die Navigationsleiste liegt außerhalb davon —
`viewPadding.bottom` ist hier 0. Die App sieht den Unterschied nur über den
Bildschirm selbst: `View.of(context).display.size` ist das ganze Panel,
`physicalSize` das Stück, das die App bekommt. Die halbe Differenz ist der
Ausgleich.

**Befund nachher:** System-Splash 1051–1355, eigener Splash 1051–1354. Ein
Pixel Unterschied auf 2400 — das Zeichen steht still.

**3. Die Farbe war das alte flache Petrol.** Auch hier hatte der Bericht
recht und ich unrecht: Der eigene Startbildschirm setzte
`backgroundColor: farben.hintergrund` und bekam den neuen Verlauf nie. Der
Start war also zweimal flaches `#173C3B`, und der Farbsprung kam eine
Sekunde später — beim Wechsel auf die Startseite.

Jetzt trägt der eigene Startbildschirm **denselben Verlauf wie jede Seite**.
Der System-Splash kann keinen: `windowSplashScreenBackground` nimmt ab
Android 12 nur eine einzelne Farbe. Er bekommt deshalb `#122C31` — die
**Mitte** des Verlaufs, also genau den Ton, den die App an der Stelle trägt,
an der das Zeichen steht.

Gemessen am Gerät, jeweils am linken Seitenrand:

| | oben | Mitte | unten |
|---|---|---|---|
| System-Splash | (17, 41, 49) | (15, 42, 48) | (16, 41, 48) |
| eigener Splash | (22, 55, 56) | (14, 40, 46) | (12, 28, 39) |
| Startseite | (21, 55, 56) | (14, 40, 46) | (12, 28, 39) |

Der Übergang vom eigenen Splash auf die Startseite ist **exakt** farbgleich —
das war die Anforderung. Beim System-Splash bleibt ein Rest: Er ist flach,
wo die App einen Verlauf hat. In der Bildmitte stimmt er auf zwei Einheiten
genau, zum Rand hin weicht er ab. Mehr gibt die Android-Splash-API nicht her,
und die Mitte ist die Stelle, auf die man schaut.

**Was der Generator überschreiben darf — und was ein Test darüber sagt.**
`dart run flutter_native_splash:create` schreibt alle vier `styles.xml` neu.
Die Handanpassung darin (`NormalTheme` zeigt `@color/splashHintergrund`
statt Weiß oder Schwarz) ist genau die Sorte Änderung, die still verloren
geht — und ihr Verlust sähe aus wie ein kurzes weißes Aufblitzen beim Start.
`splash_test.dart` besteht deshalb darauf: auf der Handanpassung in allen
vier Dateien, auf der Farbe in Konfiguration, Styles und `colors.xml`, auf
der Abwesenheit von `icon_background_color` und auf der gerechneten
Zeichengröße samt der Messung, aus der sie stammt.

**Preis:** Der Startbildschirm rechnet jetzt mit `View.of(context)` statt mit
`MediaQuery`. Das ist die ungewohntere Stelle, aber die einzige, die den
Bildschirm sieht statt nur das Fenster.

## 53 · Der harte Schnitt beim Start — Befund aus dem Video

Zum Start gab es einen zweiten Bericht vom Gerät, diesmal mit einer
Videoaufnahme. Ausgewertet wurde sie Bild für Bild (ffmpeg, 30 Bilder je
Sekunde, Farbwerte in drei Streifen über die Bildschirmhöhe).

**Was das Video zeigt.** Die Aufnahme ist mit einer zweiten Kamera vom
Bildschirm abgefilmt, nicht vom Gerät aufgezeichnet. Deshalb erscheint dort
*alles* als helles Türkis — auch die Startseite mit ihren Karten. Das
gemeldete „flache, helle Türkis" ist die Wiedergabe der Kamera, nicht die
Farbe der App.

Die konfigurierte Splash-Farbe **kommt** auf dem Gerät an. Der Beweis steckt
in denselben Bildern:

| | oben | Mitte | unten |
|---|---|---|---|
| Bild 173 (System-Splash) | (0, 130, 151) | (20, 145, 159) | (0, 139, 158) |
| Bild 177 (eigener Splash) | (0, 158, 163) | (21, 138, 152) | (0, 101, 139) |

Vorher ist die Fläche **flach**, nachher ein **Verlauf** — und die *Mitte*
bleibt dabei fast gleich (145 → 138), während oben +22 % heller und unten
−27 % dunkler wird. Genau das ist die Konstruktion aus DECISIONS 52: Der
System-Splash trägt die Mitte des Verlaufs. Läge dort noch das alte
`#173C3B`, wäre der obere Rand beim Wechsel unverändert geblieben.

**Was wirklich falsch war.** Der Wechsel selbst:

| Bild | oben/unten | Schriftzug |
|---|---|---|
| 173 | 0,90 | nichts |
| 174 | 0,94 | ansteigend |
| 175 | 1,20 | fast voll |
| 176 | 1,30 | voll |

Innerhalb von **zwei bis drei Bildern, also unter 100 ms**, springt der
Hintergrund vom flachen Ton in den Verlauf **und** der Schriftzug steht
vollständig da. Ein harter Schnitt, in dem sich zwei Dinge gleichzeitig
ändern — genau wie gemeldet.

**Warum die Einblendung des Schriftzugs unsichtbar blieb.** Sie lief, aber zur
falschen Zeit. `TweenAnimationBuilder` startet, sobald das Widget gebaut
wird — und gebaut wird es, während der native Splash noch auf dem Bildschirm
liegt. Bis der weg war, waren die 500 ms längst vorbei. Eine Animation, die
hinter einem Vorhang abläuft, hat nicht stattgefunden.

**Was jetzt passiert, in dieser Reihenfolge:**

1. **Phase 1** — der System-Splash: flacher dunkler Ton, Zeichen in der
   Mitte.
2. **Übergabe** — das erste Bild des eigenen Startbildschirms ist dasselbe
   Bild: `AppColors.startFlaeche` an beiden Enden des Verlaufs, dasselbe
   Zeichen an derselben Stelle, **kein** Schriftzug. Es gibt nichts zu sehen.
3. **Blende** — nach 200 ms Vorlauf blendet der Hintergrund über 600 ms in
   den Verlauf, und ab einem Drittel dieser Zeit glüht der Name auf: von
   durchsichtig nach deckend, von warm (dem Sand des Zeichens) nach hell (der
   Textfarbe), dabei sechs Pixel aufwärts.

**Warum 200 ms Vorlauf.** Android zieht seinen Splash mit einer eigenen
Animation weg, nachdem die App gezeichnet hat. Begänne die Blende schon dort,
lägen zwei sich verändernde Bilder übereinander. Der Vorlauf deckt das ab —
und weil beide Bilder in dieser Zeit identisch sind, verlängert er nichts,
was man wahrnimmt.

**Warum „aufglühen" und kein Schein.** Ein weicher Schatten unter dem Text
wäre ein Glow-Effekt, und die schließt der Auftrag aus. Der Eindruck entsteht
stattdessen aus der Farbe: Der Name kommt warm herein und wird hell. Das ist
eine Blende, kein Effekt — und es passt zum Namen.

**Bei „Bewegung reduzieren"** steht sofort der Endzustand. Dann ist der
Wechsel wieder hart; das ist die Einstellung, um die es geht.

**Preis:** Der Startbildschirm hat jetzt einen Animationscontroller und zwei
Timer. Und die Standzeit ist um 100 ms gewachsen, damit die Blende nicht vom
Wechsel auf die Startseite abgeschnitten wird.

## 54 · Silhouette mit Glut — das neue Zeichen

Das Personen-Zeichen bleibt, was es war: der Kopfkreis aus dem Kamera-Sucher
mit angedeuteten Schultern darunter. Neu ist die Glut in der Brustmitte.

**Der Gedanke dahinter** steht in der Vorgabe und ist die halbe Begründung:
Man glüht von innen nach außen. Gesündere Gewohnheiten verbessern einen von
innen heraus, und das sieht man außen. Deshalb sitzt die Glut nicht *neben*
der Silhouette, sondern **in** ihr — genau auf der Oberkante des
Schulterbogens, dort, wo die Brustmitte läge.

**Warum die Glut über den Linien liegt.** Sie überstrahlt den Schulterbogen
dort, wo sie am dichtesten ist. Läge sie darunter, wäre sie ein Hintergrund
und kein Licht. Das Licht kommt von innen und liegt vor dem Körper.

**Die Kurve steht in `Marke`, nicht zweimal.** Die Glut entsteht an zwei
Stellen: `tool/marke_erzeugen.dart` rechnet sie Pixel für Pixel für die
PNG-Dateien, [MarkenLogo] legt sie zur Laufzeit als Verlauf an. Zwei Kurven
wären zwei verschiedene Zeichen — ähnlich genug, dass es niemandem auffällt.
`Marke.glutDeckung` und `Marke.glutWeiss` sind deshalb Funktionen, die beide
aufrufen; der Verlauf tastet sie an sechzehn Stellen ab.

Der Exponent darin ist der Unterschied zwischen einem Schein und einem
Kreis. Zu steil, und von der weiten, sanften Streuung bleibt ein Lichtpunkt;
zu flach, und die ganze Kachel leuchtet. 1,4 traf die Vorlage; das war der
vierte Versuch, jeweils gerendert und danebengehalten.

**Die Linien sind jetzt weiches Weiß statt Sand.** So steht es in der
Vorlage, und es ist auch richtig: Sand ist der Ton für Bedienelemente, und
neben der goldenen Glut wäre er zu nah dran. Weiß und Gold sind zwei Dinge,
Sand und Gold wären eines mit zwei Namen.

**Die Kachel trägt den Verlauf der App**, nicht mehr einen flachen Ton. Damit
sieht das Icon aus wie der Grund, auf dem die App steht. Für Android heißt
das: Der adaptive Hintergrund ist ein **Bild** und keine Farbe mehr — einen
Verlauf kann `adaptive_icon_background: "#RRGGBB"` nicht.

**Der Rand ist nachgemessen, nicht geraten.** In der Vorlage nimmt der
Kopfkreis knapp ein Drittel der Kachelbreite ein, der Schulterbogen knapp die
Hälfte. Bei einem Motivanteil von 0,72 trifft unsere Geometrie beides. Vorher
stand das Motiv randlos in der Kachel und jede runde Launcher-Maske schnitt
den Schulterbogen an.

**Schutzzone.** Der adaptive Vordergrund nimmt denselben Anteil, und
`flutter_launcher_icons` setzt zusätzlich 16 % Einzug: 0,72 × 0,68 ≈ 0,49 der
Fläche. Das liegt gut innerhalb der inneren zwei Drittel, die jede Maske
stehen lässt. Die Glut reicht weiter, ist dort aber längst durchsichtig — ein
Schnitt durch etwas Unsichtbares ist keiner. Ein Test rechnet beides nach.

**Überall dasselbe Zeichen:** Homescreen (mit Kachel), System-Splash und
eigener Startbildschirm (ohne Kachel, direkt auf dem Hintergrund), In-App-Logo
auf dem Anmeldebildschirm. Alle acht Fassungen kommen aus einem Generatorlauf.

**Die Vorschau** liegt als `assets/branding/icon_vorschau.png` und wird
mitgeneriert — von Hand gepflegt zeigte sie irgendwann ein Zeichen, das es
nicht mehr gibt. Sie zeigt dasselbe Motiv dreimal: als Kachel groß, in
Homescreen-Größe und so, wie es ohne Kachel auf dem Splash steht. Der Ordner
`assets/branding/` ist bewusst **nicht** in `pubspec.yaml` als Asset
eingetragen; die Dateien sind Quellen für die Generatoren und landen nicht im
APK.

**Weiß ist keine Designfarbe.** Der Kern der Glut ist weißglühend, und das
ist Physik, keine Palette. `marken_logo.dart` steht deshalb mit genau dieser
Begründung auf der Ausnahmeliste in `design_werte_test.dart`.

**Preis:** Eine Datei mehr in `assets/branding/`, und der Generator läuft
spürbar länger — die Glut wird für jedes Pixel gerechnet, das 1152er-Bild hat
1,3 Millionen davon.

## 55 · Warum das Zeichen blinkte — und wer die Überblendung macht

Zwei Beschwerden aus derselben Aufnahme: Das Zeichen **blinkt** bei der
Übergabe, und der eigene Startbildschirm läuft **in Stufen** an. Beides ist
dieselbe Ursache, und die lag nicht in der App.

**Der Befund.** Kaltstart am Samsung SM A525F, Bildschirmaufnahme, mit
`ffmpeg -vsync 0` in Einzelbilder zerlegt, jedes Bild ausgemessen (Tinte des
Zeichens, Verlaufsstärke von oben nach unten):

| Bild | t | Zeichen | Schriftzug | Verlauf |
|---|---|---|---|---|
| 137 | 11,211 s | 6683 | 0 | 0,0 |
| 138 | 11,228 s | **0** | 0 | 0,0 |
| 139 | 11,244 s | **0** | 0 | 0,0 |
| 140 | 11,262 s | **0** | 0 | 0,0 |
| 141 | 11,281 s | 6659 | 2345 | 18,3 |

Drei Einzelbilder — rund 50 ms — mit **gar keinem Zeichen**, danach in einem
Schritt der fertige Endzustand. Das ist das Blinken, und im selben Sprung
steckt die zweite Beschwerde: Die 300-ms-Blende, die in Dart lief, ist in
Bild 141 schon fertig.

**Die Ursache.** Ab Android 12 gehört der Start-Bildschirm dem System. Es
nimmt ihn weg, sobald die App gezeichnet hat — aber der Inhalt der App wird
erst *nach* dieser Wegnahme sichtbar. In den drei Bildern dazwischen liegt
nur die leere Fläche: das Zeichen des Systems ist schon weg, das der App noch
nicht da.

Und weil die Dart-Blende startet, sobald der Startbildschirm gebaut ist —
also lange bevor er auf dem Schirm ankommt —, lief sie hinter diesem Vorhang
ab. Zweimal gemessen, zweimal war das erste sichtbare Bild der Endzustand.
Eine Animation in Flutter kann diesen Übergang grundsätzlich nicht zeigen.

**Was es nicht war:** `FlutterNativeSplash.preserve()`. Der Verdacht lag nahe
— die Funktion hält das erste gezeichnete Bild zurück —, war aber falsch:
Ohne sie blieb das Blinken, es wurde nur kürzer (drei leere Bilder statt
mehr). Sie ist trotzdem draußen, weil Android genau auf dieses Bild wartet,
um seinen Start-Bildschirm wegzunehmen. `flutter_native_splash` ist wieder
reiner Generator in `dev_dependencies`.

**Die Lösung: Die Überblendung liegt im Vorhang, nicht dahinter.**
`MainActivity` setzt einen Exit-Listener. Damit wartet das System darauf,
dass wir seinen Start-Bildschirm selbst wegnehmen — und wir blenden ihn in
300 ms weg, über dem fertigen Bild der App, das darunter schon steht. Hier
ist die Reihenfolge zwingend, und man sieht genau eine Überblendung: von der
flachen Farbe des Systems auf Verlauf, Zeichen und Schriftzug.

Der eigene Startbildschirm animiert deshalb **gar nichts** mehr. Er zeigt ab
dem ersten Bild den Endzustand. Ein Test besteht darauf, dass dort kein
`AnimationController` wieder auftaucht.

**Warum das Zeichen dabei nicht dunkler wird.** Beide Lagen zeigen dasselbe
Zeichen, gleich groß, an derselben Stelle (DECISIONS 52). Beim Überblenden
ergibt das an jeder Stelle wieder genau dieses Zeichen — es kann nicht
flackern. Das ist keine Theorie, sondern der Grund, warum die Maßarbeit aus
52 überhaupt nötig war.

**Der Nachweis** (Aufnahme vom 27.08.2026, Bilder 33–73). Gemessen wurde die
mittlere Helligkeit genau der 22.138 Pixel, die das Zeichen ausmachen:

| Abschnitt | Bilder | Tinte | Bildwechsel |
|---|---|---|---|
| System-Splash steht | 33–54 | 203,11 — unverändert | ≤ 0,04 |
| Überblendung | 55–72, 283 ms | 203,05 → 205,11, steigend | 0,40 bis 1,12 |
| eigener Schirm steht | 72–73 | 205,11 | 0,02 |

Kein Einzelbild mit dunklerem Zeichen als davor (die −0,06 in Bild 55/56 sind
0,03 % und liegen unter einer Helligkeitsstufe), kein leeres Bild, und der
größte Bildwechsel während der Blende ist 1,12 — zum Vergleich: der Wechsel
auf die Anmeldung eine Sekunde später misst 22,8.

**Grenzen.** Vor Android 12 gibt es diesen Mechanismus nicht; dort ist der
Start-Bildschirm der Fensterhintergrund und verschwindet, sobald Flutter
malt. Steht die System-Einstellung „Animationen entfernen" an, macht Android
aus der Blende einen Schnitt — genau darum bittet diese Einstellung.

**Nicht Teil der Aufgabe** und deshalb unverändert: die ersten Sekunden
flacher Farbe, bevor überhaupt etwas erscheint. Das ist Android beim Starten
des Prozesses, nicht die App. In dieser Aufnahme waren es 7,2 Sekunden
(Debug-Build).

## 56 · Zwei Modi statt einer Frage

Die Analyse konnte bisher genau eine Frage beantworten: „Wie hole ich aus
dem, was da ist, das Beste heraus?" Das ist die richtige Frage für jemanden,
der seinen Stil mag. Wer Veränderung will, bekam darauf eine Antwort, die ihn
festhielt — freundlich, konkret, und am Anliegen vorbei.

**Deshalb steht am Anfang jeder Analyse eine Entscheidung**: „Meinen Look
verfeinern" oder „Neuen Look entdecken". Zwei gleich große Karten, ein eigener
Bildschirm vor der Modulauswahl, kein Überspringen.

**Warum ein eigener Schritt und kein Schalter auf der Modulseite.** Die Frage
ist grundlegender als die Modulauswahl: Sie entscheidet nicht, *worüber* der
Report spricht, sondern *was er will*. Als Schalter zwischen den Modulkarten
hätte sie ausgesehen wie eine Einstellung und wäre überlesen worden — und ein
überlesener Standard hätte für die Hälfte der Nutzer den falschen Report
erzeugt. Für genau die Hälfte, die Veränderung sucht.

**Warum kein Überspringen.** Der Schritt „Deine Richtung" darf übersprungen
werden, weil „keine Angabe" dort eine sinnvolle Antwort ist: Dann schaut das
Modell neutral. Hier gibt es kein Neutral — jeder Report beantwortet die eine
oder die andere Frage. Also wird sie gestellt.

**Die Wahl gilt pro Analyse, nicht fürs Konto.** Sie wird zwar gespeichert,
aber nur für die Dauer eines Durchlaufs: Zwischen Moduswahl und Startknopf
liegen Module, Richtung und bis zu elf Aufnahmen, und ein Anruf dazwischen
darf die Entscheidung nicht kosten. Jeder neue Durchlauf setzt sie zurück
(`_neueAnalyse` in `home_screen.dart`) und fragt neu. Wer einmal einen neuen
Look wollte, bekommt ihn nicht stillschweigend für immer.

**Beim Erweitern zählt der Report, nicht der Flow.** Wer über „Analyse
erweitern" ein Kapitel nachbestellt oder den Plan mit neuer Richtung neu
rechnet, bekommt es im Modus *des bestehenden Reports*. Ein
Verfeinerungs-Kapitel in einem Report mit neuem Look wäre ein Fremdkörper.

**Der Modus hängt am Ergebnis** und nicht nur am Controller — aus demselben
Grund wie die Richtung (DECISIONS 39): Im Verlauf muss ablesbar bleiben,
welche Frage ein Report beantwortet hat. Deshalb trägt **jeder** Eintrag ein
Etikett, auch der verfeinernde. Nur den neuen zu kennzeichnen hieße, den
anderen zur Norm zu erklären — und ein Eintrag ohne Etikett wäre zweideutig:
alter Report oder verfeinert?

**Der Rückfall ist überall `verfeinern`**, an vier Stellen unabhängig
voneinander: gespeicherter Report ohne Feld, unbekannter Name, Client ohne
das Feld, Server ohne Modus in der Nutzlast. Wer den Modus nicht kennt,
bekommt genau das, was er bisher bekommen hat.

**Preis:** Ein Bildschirm mehr im Flow — vier Schritte statt drei, bevor die
erste Aufnahme kommt. Das ist der Preis dafür, dass die Frage nicht
untergeht.

## 57 · Was „Neuen Look entdecken" vom Modell verlangt

Der Modus aus DECISIONS 56 ist erst dann etwas wert, wenn die Antwort anders
aussieht. „Schlag etwas Neues vor" allein beantwortet ein Modell mit „probier
doch mal einen frischeren Schnitt" — und das ist nichts.

**Der Auftrag wird ausgetauscht, nicht ergänzt.** Der Satz „Deine Aufgabe:
eine konstruktive, motivierende Einschätzung …" ist im entdeckenden Modus
weg. An seiner Stelle steht der Entwurfsauftrag. Ein Prompt, der beides
verlangt, bekommt beides halb.

**Acht Regeln, jede prüfbar an einer einzelnen Zeile des Reports:**

| Regel | Wogegen sie geschrieben ist |
|---|---|
| NAME | „Etwas Kürzeres" statt „Textured Crop" |
| BEGRÜNDUNG AM GESICHT | ein Trendtipp, der für jeden gilt |
| MACHBAR | eine Frisur, die der Haartyp nicht hergibt |
| BEIM FRISEUR SAGEN | ein Vorschlag, den man im Salon nicht erklären kann |
| SICHTBAR ANDERS | derselbe Look mit anderen Worten |
| WAS BLEIBT | „neu" als „alles anders" |
| TON | ein Report, der erst sagt, was falsch war |
| STANDARD-VORSCHLÄGE VERBOTEN | die Antwort, die für alle passt |

Die Beispiele sind **beschrieben** und nicht als fertiger Satz zitiert — was
der Prompt wörtlich nennt, schreibt das Modell wörtlich ab (DECISIONS 36).
Frisurnamen sind die Ausnahme: „Textured Crop" heißt auf Englisch genauso.

**Der Report bekommt einen Vorspann.** `neuerLook` steht als erstes Feld im
Schema und als erste Karte im Report — noch vor „Deine Richtung". Die Kapitel
darunter sind die Umsetzung dieser Richtung; wer den Vorspann überspringt,
liest den Rest als lose Tipps. Fehlt das Feld, fällt die Karte weg statt leer
dazustehen: Ein Report ohne Vorspann ist unvollständig, nicht kaputt.

**Jedes Look-Kapitel bekommt eine eigene Vorschlags-Sektion an erster
Stelle**, mit dem festen Titel „Dein neuer Look" / „Your new look" aus
`SEKTIONEN`. Deshalb steigt die erlaubte Zahl der Sektionen in diesem Modus
von 2–4 auf 3–5: Die Basis hat schon Frisur, Bart und Brillenform, und die
Vorgabe hätte sonst mit ihrer eigenen Obergrenze kollidiert.

**Das Zielkapitel bleibt außen vor.** Es gehört allein dem Freitext
(DECISIONS 39). Ein Frisurvorschlag darin wäre genau die Vermischung, die
dort abgeschafft wurde — auch im neuen Look ist „aufhören zu rauchen" kein
Look-Thema.

**Plan und Tagesaufgaben hängen am neuen Look.** Ohne eigene Regel dafür kam
ein Plan zurück, der den alten Look pflegt: Der Vorschlag steht oben, und
darunter steht „Bart abends in Form bringen" für einen Bart, der abrasiert
werden soll. Dazu gehört auch, eine nötige Übergangszeit offen zu benennen —
eine verschwiegene Übergangszeit ist der häufigste Grund, warum jemand nach
zwei Wochen aufgibt.

**Der verfeinernde Modus bleibt Wort für Wort derselbe.** Ein Test besteht
darauf. Ohne diese Zusage ließe sich bei einer schlechteren Antwort nie
sagen, ob es am neuen Modus liegt oder am Umbau.

**Alle Leitplanken gelten weiter** — keine Scores, kein
Attraktivitätsurteil, keine Diagnosen, die Wenn-dann-Anker, der
Qualitätsblock. Der neue Modus ist ein anderer Auftrag, keine Ausnahme von
den Regeln. Auch das steht als Test da.

**Der Demo-Modus bekommt ein zweites vollständiges Beispiel.** Das ist
Fleißarbeit — sechs Kapitel, ein eigener Plan, ein eigener Vorspann —, aber
die Alternative wäre gewesen, den neuen Modus nur mit echtem Kontingent
ansehen zu können. Dann wäre die Oberfläche erst geprüft worden, nachdem sie
Geld kostet.

**Preis:** Der Prompt wird im entdeckenden Modus rund ein Drittel länger.
Das kostet Eingabe-Tokens bei jedem Lauf dieses Modus.

## 58 · Stilrichtungen, die 16- bis 25-Jährige auch so nennen

Die alte Auswahl bei „Deine Richtung" hieß: Maskuliner, Weicher, Markanter,
Gepflegter, Seriöser, Jünger wirken, Reifer wirken, Natürlicher, Auffälliger,
Sportlicher. Zwei Probleme daran.

**Sie beschrieb Wirkungen, keine Stile.** „Seriöser wirken" ist ein Ziel für
ein Vorstellungsgespräch, keine Richtung, die man morgens vor dem Schrank
wählt. Und für die Zielgruppe war die Liste zu brav: Jugendliche Stile kamen
überhaupt nicht vor. Wer Baggy-Hosen und Oversize trägt, fand sich in zehn
Optionen kein einziges Mal wieder.

**Neu sind acht Stile, jeder mit drei bis sechs Wörtern Untertext:**
Clean & gepflegt · Markant & maskulin · Natürlich & entspannt · Weich &
elegant · Streetwear & lässig · Smart & hochwertig · Sportlich & funktional ·
Kreativ & auffällig.

Das Paket schlug sieben vor. Der achte ist „Weich & elegant" und steht da,
weil sonst die alte Option „Weicher / Sanfter" keinen Nachfolger gehabt
hätte — und die Liste damit nur noch eine Richtung für alle gehabt hätte, die
es nicht kantig mögen.

**Der Untertext ist kein Schmuck.** „Smart & hochwertig" ist ohne
Modewissen eine leere Hülle; mit „Polo, Strick, klare Silhouetten" weiß man,
worauf man tippt. Dafür wird aus dem runden Chip eine kleine Karte: Zwei
Zeilen in einer Pille zu stapeln sieht aus wie ein Fehler, und die Rundung
frisst die Ecken der zweiten Zeile. `AuswahlChip` schaltet die Form deshalb
um, sobald ein Untertext da ist — der Stil-Fragebogen bleibt rund.

**Alte Werte werden überführt, nicht weggeworfen.** Jeder der zehn alten
Namen zeigt auf seinen nächsten Nachbarn, und das an **zwei** Stellen:
`Richtungsziel.ausName` liest die gespeicherte Auswahl auf dem Gerät um, und
`normalisiereRichtungsziele` fängt auf dem Server den anderen Fall ab — eine
App-Fassung, die noch nicht aktualisiert wurde und weiter die alten Namen
schickt. Ohne die zweite Stelle wäre deren Richtung stillschweigend aus dem
Prompt gefallen: Der Nutzer hätte etwas gewählt, das nirgends ankommt.

Zwei Zuordnungen sind ehrliche Näherungen und keine Übersetzungen: `juenger`
wird zu „Streetwear & lässig" — die jugendliche Richtung, die diese Liste
überhaupt erst eingeführt hat — und `reifer` zu „Smart & hochwertig". Beides
ist das Nächstgelegene, nicht dasselbe. Wer das anders sieht, ändert es mit
zwei Tipps. Und weil „Seriöser" und „Reifer" beide auf demselben Nachfolger
landen, werden aus zwei alten Haken ein neuer statt zwei gleicher.

**Die Wahl wird jetzt übersetzt statt nur genannt.** Vorher stand im Prompt
eine Zeile „Gewählte Richtung: Markanter" und die Bitte, die Empfehlungen
daran auszurichten. Für ein Modell ist das eine Stimmung, keine Vorgabe — am
fertigen Report war nicht zu erkennen, ob jemand „Streetwear" oder „Smart"
angetippt hatte. `RICHTUNGSVORGABE` sagt es deshalb aus: Zu jeder Richtung
steht im Prompt, was sie für **Frisur, Bart und Kleidung** konkret heißt, in
beiden Sprachen. Ein Test besteht darauf, dass jede der drei in jedem Eintrag
vorkommt.

Dazu zwei Regeln: Die Richtung ist eine Vorgabe und keine Stimmung — ein
Report, dem man die Wahl nicht ansieht, hat sie ignoriert. Und bei mehreren
Richtungen wird verbunden, nicht gemittelt; wo zwei sich widersprechen, muss
das Modell sich sichtbar entscheiden und sagen, warum.

**Ohne Auswahl bleibt der Prompt Wort für Wort derselbe.** Sonst kostete die
neue Zeile Tokens für nichts.

**Was hier bewusst nicht angefasst wurde:** die Stilziele im Fragebogen des
Moduls „Stil & Kleiderschrank" (`STILZIEL`: klassisch, minimalistisch,
sportlich, smart casual, kreativ, rockig). Sie überschneiden sich jetzt
teilweise mit dieser Liste. Das Paket hat sie nicht genannt, und ein zweiter
Umbau am selben Tag wäre schwer zu prüfen gewesen — der Punkt gehört auf die
Liste für später.

**Preis:** Der Prompt wächst pro gewählter Richtung um rund drei Zeilen. Wer
alle acht antippt, verlängert ihn spürbar — das ist der Preis dafür, dass die
Wahl im Report ankommt.

## 59 · Der Analyse-Ausfall vom 27.08.2026 — App Check, nicht der neue Code

Zwei Stunden nach dem Ausrollen der drei Functions brach eine echte Analyse
mit „Analyse nicht möglich — Der Analyse-Dienst antwortet gerade nicht" ab.
Der Verdacht lag beim frischen Server-Code oder an den zwei neuen Feldern
(Modus, neue Stilrichtungen). **Beides war falsch.**

**Der Befund.** Im Protokoll der Function, um 13:47:07 UTC — das ist 15:47
Ortszeit, die gemeldete Minute:

```
Failed to validate AppCheck token. FirebaseAppCheckError: Decoding App Check
token failed. Make sure you passed the entire string JWT which represents the
Firebase App Check token.
Callable request verification failed: AppCheck token was rejected.
{"verifications":{"auth":"VALID","app":"INVALID"}}
```

`auth: VALID` neben `app: INVALID` ist die ganze Diagnose: **Das Konto war in
Ordnung, die Installation nicht.** Der Aufruf wurde im Callable-Rahmen
abgewiesen — bevor eine einzige Zeile des neuen Codes lief. Kein Prompt wurde
gebaut, kein Feld gelesen, kein Modell gefragt.

Drei Versuche stehen im Protokoll (13:47:07, 13:47:13, 13:52:37), alle mit
derselben Zeile. Danach nichts mehr.

**Die Ursache.** Im Debug-Build läuft der App-Check-Debug-Provider. Sein
Geheimnis liegt im privaten Speicher der App. Die Deinstallation am
27.08.2026 gegen 01:00 Uhr — dieselbe, die die Fortschritts-Fotos gekostet
hat und die zu `CLAUDE.md` geführt hat — hat diesen Speicher geleert. Beim
nächsten Start erzeugte der Provider ein neues Token
(`eadf101d-b147-4c54-b4d8-befc62166f66`), und das stand nicht auf der
Freigabeliste in der Firebase-Konsole.

Der Deploy um 13:43 Uhr war Zufall: Es war schlicht der erste
Analyse-Versuch nach der Deinstallation.

Dass genau das passieren kann, stand seit dem 25.08.2026 in `SETUP.md` 4.3 —
damals war es schon einmal passiert. Zweimal derselbe Fehler ist keiner mehr,
sondern eine Konstruktionsschwäche.

**Was daraus folgt.**

**Die Meldung sagt jetzt die Wahrheit.** „Der Analyse-Dienst antwortet gerade
nicht. Bitte später noch einmal versuchen." war das Gegenteil dessen, was
vorlag: Der Dienst antwortete sofort, dauerhaft und mit Nein. Genau dieser
Satz hat die Suche in Richtung Server geschickt. `unauthenticated` und
`permission-denied` bekommen deshalb einen eigenen Fall
`AnalysisFehler.zugangAbgelehnt` mit dem Titel „Diese Installation ist nicht
freigegeben" und einem Tipp, der ausdrücklich sagt, dass Warten nicht hilft.
Vorher lief das unter „unauthenticated deckt beides ab" — ein Kommentar, der
die Verwechslung beschrieb, statt sie zu beheben.

**Ein Test hält App und Server aneinander.** Die Frage „liegt es an einem
Versatz zwischen App und Server?" ließ sich nicht in einer Minute
beantworten, weil kein Test die beiden Seiten zusammenbrachte: Die
Dart-Tests prüften die App, die TypeScript-Tests prüften den Server, und
dazwischen war nichts. Jetzt schreibt `test/anfrage_form_test.dart` die
**echte** Nutzlast aus demselben `AnalyseAnfrage.bauen`, das auch die App
benutzt, nach `functions/test/fixtures/`, und
`functions/test/anfrage_form.test.ts` schickt sie durch `leseAnalyse`, den
Prompt und die Nachbereitung. Ein umbenanntes oder verlorenes Feld fällt im
Testlauf auf statt am Gerät.

Der Test hat übrigens nebenbei bewiesen, dass es **keinen** Versatz gab: Die
Nutzlast vom 27.08. läuft vollständig durch.

**App Check bleibt erzwungen.** Der schnellste Weg zurück wäre gewesen,
`enforceAppCheck` abzuschalten. Das wäre der teuerste: Ohne diese Tür kann
jeder mit einem abgegriffenen Auth-Token Gemini auf unsere Rechnung rufen.
Ein Test besteht auf `enforceAppCheck: true`.

**Ein abgelehnter Aufruf kostet kein Kontingent** — das war schon so und
bleibt so. App Check greift im Callable-Rahmen, `reservieren` steht
ausschließlich in `mitKontingent` und damit mitten im Rumpf. Ein zweiter
Test hält diese Reihenfolge fest. Im Protokoll des 27.08. steht dazu passend
keine einzige Kontingent-Zeile.

**Die Dokumentation nennt die Falle beim Namen.** `SETUP.md` 4.3 listet jetzt
auf, was das Token tötet (`adb uninstall`, `pm clear`,
`--uninstall-first`, „App-Daten löschen"), woran man es im Protokoll und in
der App erkennt, und den Einzeiler, der das neue Token ausliest. `CLAUDE.md`
führt das Token in der Liste dessen, was eine Deinstallation kostet — neben
den Fortschritts-Fotos.

**Preis:** Nichts an Laufzeit. Ein Fehlerfall mehr in der Aufzählung, zwei
Fixture-Dateien im Repo und ein Testlauf, der die Nutzlast mitschreibt.

**Was ausdrücklich offen bleibt:** Das Debug-Token muss weiterhin von Hand in
der Konsole eingetragen werden. Es gibt keinen Weg, es aus dem Projekt heraus
festzunageln, ohne nativen Code in den Debug-Build zu ziehen. Solange das so
ist, ist die Regel aus `CLAUDE.md` — nicht deinstallieren — auch die
Absicherung dieser Stelle.

## 60 · Die Schwerpunkte aus dem Onboarding tun endlich etwas

**Was die Auswahl bisher bewirkt hat — die ehrliche Antwort:** genau eine
Zeile im Analyse-Prompt.

```
- Gewünschte Schwerpunkte: Haut, Haare
…
Gewichte die genannten Schwerpunkte stärker, ignoriere die übrigen Bereiche
aber nicht völlig.
```

Sonst nichts. Nicht die Modulauswahl, nicht der Check-in, nicht der Plan,
nicht die Tagesaufgaben, nichts in der Oberfläche nach dem Onboarding. Die
Frage war also nicht wirkungslos — aber ihre Wirkung war unsichtbar, und zwei
Bildschirme später fragte die Modulauswahl dasselbe noch einmal, nur
ausführlicher. Wer „Haut" angekreuzt hatte, musste „Haut & Farbtyp" trotzdem
von Hand anhaken.

**Verdrahtet statt gelöscht.** Jeder Schwerpunkt kennt jetzt sein Modul, und
ein neuer Durchlauf startet mit diesen Modulen vorausgewählt:

| Schwerpunkt | Modul |
|---|---|
| Haut | Haut & Farbtyp |
| Style | Stil & Kleiderschrank |
| Fitness-Habits | Figur & Passform |
| Haare | — (Teil der Basis) |
| Bart | — (Teil der Basis) |

Haare und Bart wählen nichts vor, weil die Basis ohnehin immer dabei ist.
Ihre Wirkung bleibt die Gewichtung im Prompt — und die ist dort echt: Die
Basis hat einen Frisur- und einen Bart-Abschnitt.

**Fitness-Habits → Figur & Passform** ist die einzige Zuordnung, die eine
Begründung braucht. Das Kapitel heißt nach der Passform, aber sein Inhalt ist
der Körper: Proportionen, Haltung, und in der Tagesliste Aufgaben wie der
Brustöffner im Türrahmen. Wer „Fitness-Habits" ankreuzt, meint genau die.
Ein eigenes Fitness-Kapitel gibt es nicht und soll es nicht geben — die App
ist kein Trainingsplan, und ein Kapitel ohne Foto wäre eins ohne Grundlage.

**Vorausgewählt heißt nicht festgelegt.** Der nächste Bildschirm ist die
Modulauswahl, dort lässt sich jeder Haken mit einem Tipp wieder entfernen.
Damit das nicht wie Magie wirkt, steht über der Liste ein Satz: „Aus deinen
Schwerpunkten im Onboarding schon angehakt: … Du kannst das hier frei
ändern." Er wird **gerechnet, nicht gemerkt** — er stimmt also auch dann
noch, wenn inzwischen abgewählt wurde.

Das ist nicht kostenlos: Eine Vorauswahl kann Aufnahmen nach sich ziehen.
„Stil & Kleiderschrank" will Outfit-Fotos, „Figur & Passform" Ganzkörper.
Deshalb der Hinweis und deshalb die Reihenfolge — erst sehen, was
vorausgewählt ist, dann in die Kamera.

**Die Gewichtung nennt jetzt eine Zahl statt eines Adverbs.** „Gewichte
stärker" ist für ein Modell eine Stimmung; am fertigen Report war nicht zu
erkennen, ob überhaupt etwas angekreuzt war. Neu:

> Die genannten Schwerpunkte sind eine Vorgabe, keine Stimmung: In dem
> Kapitel, zu dem ein Schwerpunkt gehört, steht mindestens eine Empfehlung
> mehr als in den übrigen und mindestens eine Tagesaufgabe, die genau auf
> diesen Schwerpunkt zielt.

Das ist an einer einzelnen Zeile des Reports nachzuzählen. Dazu zwei
Absicherungen: Ein Schwerpunkt, dessen Kapitel gar nicht bestellt wurde,
fällt weg — er erfindet kein Kapitel und wandert in kein fremdes hinein
(dieselbe Grenze wie beim Zielkapitel, DECISIONS 39). Und die übrigen
Bereiche werden nicht dünner, sie bekommen nur nicht das Zusätzliche.

**Ohne jeden Schwerpunkt** steht jetzt ausdrücklich „Behandle alle
angeforderten Kapitel gleich gewichtet." — vorher stand dort nichts, und das
Modell durfte sich selbst einen Schwerpunkt aussuchen.

**Nichts wurde aus dem Onboarding entfernt.** Das Paket stellte es für den
Fall frei, dass ein Schwerpunkt nirgendwo mehr eine ehrliche Wirkung hat.
Nach der Verdrahtung hat jeder eine: drei wählen ein Modul vor, zwei
gewichten die Basis.

**Preis:** Ein Satz mehr auf der Modulseite, und der Flow beginnt für Nutzer
mit vielen Schwerpunkten mit mehr Aufnahmen als vorher. Beides ist mit einem
Tipp zu ändern.

## 61 · Acht Chips, ein Raster

Die acht neuen Stilrichtungen (DECISIONS 58) standen in einem `Wrap` als
Pillen — jede so breit wie ihr Text. Bei acht unterschiedlich langen
Beschriftungen ergibt das kein Raster, sondern Streugut: zwei in der ersten
Zeile, eine in der zweiten, eine einzelne rechts außen. Am Gerät sah das aus
wie ein Fehler, und auf Englisch wurde es schlimmer, weil die Texte dort
länger sind.

**Jetzt eine Zeile pro Richtung, über die volle Breite** — wie die
Modul-Karten, die daneben ohnehin schon so aussehen. Links Titel und
Untertext bündig untereinander, rechts ein Haken.

**Warum nicht zwei Spalten**, die das Paket ebenfalls anbot: Bei 320 dp
Gerätebreite bleiben je Spalte rund 140 dp. „Sportlich & funktional" mit
„Athletisch, praktisch, robust" bricht dort auf drei Zeilen um, auf Englisch
auf vier — und dann sind die Kacheln wieder unterschiedlich hoch. Volle
Breite kann per Konstruktion nicht ausfransen: Jede Zeile ist gleich breit,
und kein Text kann die Spalte verlassen. Der Preis ist Höhe, und die kostet
in einer Liste, durch die man ohnehin scrollt, am wenigsten.

**Die Form steht im Widget, nicht am Aufrufer.** `AuswahlChip` bekommt
`vollBreite`; ohne das Flag bleibt es die runde Pille, die der
Stil-Fragebogen und der Check-in benutzen. Ein zweites Chip-Widget wäre beim
nächsten Feinschliff sofort auseinandergelaufen — derselbe Grund, aus dem es
dieses Widget überhaupt zentral gibt.

**Der Haken statt nur der Farbe.** Bei voller Breite ist rechts Platz, und
ein Haken sagt „mehreres geht" deutlicher als ein Farbwechsel. Er ist eckig —
der runde Punkt bleibt der Moduswahl vorbehalten, wo genau eines gilt
(DECISIONS 56). Und er ändert die Breite nicht: Sonst ruckelte die ganze
Liste beim Antippen.

**Ein Test besteht auf dem Raster.** Bei 320, 400 und 480 dp, auf Deutsch und
auf Englisch, mit und ohne Auswahl: alle acht exakt gleich breit, alle an
derselben linken Kante, Titel und Untertext bündig, kein Überlauf. Das ist
die Eigenschaft, die das alte Bild ausschließt — und sie lässt sich messen,
statt sie anzusehen.

**Preis:** Die Liste ist höher als vorher. Wer alle acht sehen will, scrollt.

## 62 · Der helle Modus wird das Geschwister des dunklen

Der helle Modus war noch „Mocha Light": flaches Beige, Kaffeebraun als
Akzent. Neben dem überarbeiteten Dunkelmodus sah er nicht aus wie derselbe
Look bei Tag, sondern wie eine andere App.

**Jetzt teilen sich beide die Farbfamilie.** Das dunkle Petrol, das im
Dunkelmodus die Fläche trägt, ist im hellen die Tinte und die Buttonfarbe;
das Gold steht an genau denselben Stellen. Kein Braun mehr, nirgends — ein
Test zählt die Rollen durch und besteht darauf, dass in keiner mehr Rot über
Blau liegt (Warnung und Gold ausgenommen, die müssen warm sein).

| Rolle | hell | Herkunft |
|---|---|---|
| hintergrund → hintergrundTief | `#F7F9F8` → `#E0E9E7` | Vorgabe |
| flaeche (Karten) | `#FCFEFD` | Vorgabe |
| flaecheHoch | `#EDF3F2` | abgeleitet |
| textPrimaer | `#10262E` | Vorgabe |
| akzent (Buttons) | `#143C4A` | Vorgabe |
| aufAkzent | `#F5F8F7` | Vorgabe |
| akzentZwei / erfolg | `#2E6E85` | abgeleitet |
| textSekundaer | `#43606A` | abgeleitet |
| rand | `#B7CBC8` | abgeleitet |
| warnung | `#A8442A` | abgeleitet |
| kartenrand | Petrol bei 10 % | Vorgabe |

**Karten sind heller als der Hintergrund, nicht dunkler.** Im Dunkelmodus
hebt sich eine Fläche nach oben ab; auf hellem Grund muss sie das auch, sonst
wirkt sie wie ein Loch. Die Vertiefung liegt entsprechend eine Spur unter der
Karte — gleiche Logik, gespiegelte Werte.

### Das Gold braucht zwei Werte

Der Vorschlag nannte Text-Gold `#B27F26` und Füll-Gold `#C58F31`. **Als Text
trägt `#B27F26` nicht:** Es erreicht 3,3:1 auf dem Hintergrund und 3,5:1 auf
der Karte, gefordert sind 4,5:1 — und das Gold trägt in dieser App
tatsächlich kleine Schrift (die 12-Punkt-Zeile „Geschafft!" auf der
Challenge-Karte, 13 Punkt in der Streak-Karte). Auf dunklem Grund fiel das
nie auf, weil dort derselbe Ton beides kann.

Statt die Schwelle zu senken, bekommt das Gold **zwei Rollen mit je eigener
Schwelle**:

- `erreicht` — Text und Icons, `#865F1B`, ≥ 4,5:1 auf allen vier Flächen.
- `erreichtFlaeche` — gefüllte Haken, Fortschrittssegmente, Schrittpunkte,
  `#B27F26`, also **genau der vorgeschlagene Ton**, ≥ 3:1 auf Karte und
  Vertiefung. Das ist die Schwelle für grafische Elemente, und das sind sie.

Damit ist das Gold, das man auf dem Vergleichsbild sieht — Ringe, Balken,
Abzeichen, Haken — exakt der vorgeschlagene Wert. Nur die kleine Schrift
darin ist eine Spur tiefer.

Dazu kommt `aufErreicht`: was auf der goldenen Fläche liegt. Hell ist das die
Tinte (`#10262E`, 4,2:1 auf dem Gold); `aufAkzent` wäre dort fast weiß und
nicht zu sehen.

### Was beide Modi berührt hat

Das Paket verlangt, gemeinsame Stellen zu benennen statt still zu ändern.
Es sind drei, und alle drei sind im Dunkelmodus **folgenlos**:

1. **Zwei neue Farbrollen** (`erreichtFlaeche`, `aufErreicht`). Im
   Dunkelmodus tragen sie exakt die Werte, die dort vorher schon galten
   (`#E8BE6E` und `#173C3B`) — gerendert wird Pixel für Pixel dasselbe.
2. **Die Aufrufstellen der Füllungen** wechseln auf die neue Rolle: die
   Haken in Auswahl-Chip und Modul-Karte, die Fortschrittssegmente in
   Aufnahme- und Check-in-Strecke, die Punkte im Onboarding, sowie
   Checkbox, Radio und Segment-Button im Theme. Dunkel lösen sie sich auf
   dieselbe Farbe auf wie zuvor.
3. **Eine Zusicherung im Kamera-Test** stand als „Buttontext *ist* der
   Hintergrundton". Hell weicht er jetzt um zwei Stufen ab (`#F5F8F7` statt
   `#F7F9F8`) — das ist die Vorgabe aus dem Vergleichsbild und mit bloßem
   Auge nicht zu unterscheiden. Der Test sagt jetzt „praktisch derselbe
   Ton" (Toleranz 4 von 255); eine Fremdfarbe fällt weiterhin durch, und im
   Dunkelmodus sind die Werte weiter exakt gleich.

**Ein Test friert den Dunkelmodus ein.** Alle vierzehn Werte stehen dort als
Zahl abgeschrieben, nicht als Verweis auf `AppColors.dunkel` — sonst prüfte
er sich an sich selbst und ginge jede Änderung stillschweigend mit. Dazu die
abgeleitete Startfläche `#122C31`, an der der native Splash hängt
(DECISIONS 53).

**Nur Farben.** Layout, Rundungen, Abstände und Micro-Animationen sind
unverändert — in beiden Modi.

**Umgesetzt über die Rollen, nicht über Einzelstellen.** Alle Bildschirme
holen ihre Farben über `context.farben`; der bestehende Test gegen fest
verdrahtete Farbwerte greift unverändert. Deshalb reicht das Ändern einer
einzigen Konstante, und deshalb sind Album, Rückblick, Fehlerseiten und
Dialoge automatisch mit dabei.

**Was nicht übernommen wurde:** Die Legende des Vergleichsbildes nennt für
den Dunkelmodus `#E8B556`. Die App behält `#E8BE6E` — der Dunkelmodus wird
nicht angefasst, und das gilt auch für einen Wert, der nur in der Legende
eines Vorschlags steht.

**Preis:** Zwei Farbrollen mehr, die jedes künftige Schema mitliefern muss.

## 63 · Heller Modus V2: Creme, Teal und Amber

Die erste Überarbeitung (DECISIONS 62) machte den hellen Modus zum
Geschwister des dunklen — aber in kühlem Grau-Grün, und das gefiel nicht.
**Die Struktur bleibt vollständig, nur die Werte werden ersetzt:** dieselben
Rollen an denselben Stellen, die zwei Amber-Rollen mit ihren eigenen
Schwellen, der Test gegen fest verdrahtete Farbwerte, der eingefrorene
Dunkelmodus.

Jetzt ist der helle Modus **durchgehend warm**.

| Rolle | V2 | Herkunft |
|---|---|---|
| hintergrund → hintergrundTief | `#FDF5EE` → `#F6E8D9` | Vorgabe / abgeleitet |
| flaeche (Karten) | `#FEFAF7` | Vorgabe |
| flaecheHoch | `#F9EFE4` | abgeleitet |
| akzent (Teal) | `#025D70` | Vorgabe |
| aufAkzent | `#FEFAF7` (Karten-Weiß) | Vorgabe |
| textPrimaer | `#12383F` | Vorgabe |
| textSekundaer | `#4F6468` | abgeleitet |
| akzentZwei / erfolg | `#0E6D82` | abgeleitet |
| rand | `#DFC7AC` | abgeleitet |
| warnung | `#A8442A` | abgeleitet |
| erreicht (Ocker) | `#8F5500` | Vorgabe, nachgedunkelt |
| erreichtFlaeche (Amber) | `#E59305` | Vorgabe |
| aufErreicht | `#12383F` | abgeleitet |
| erreichtLeer | `#FDE9D2` | Vorgabe |
| erreichtChip | `#F5DEB9` | Vorgabe |
| kartenrand | Tinte bei 10 % | wie dunkel |

### Die Messungen

Alle Textfarben auf allen vier Flächen (Hintergrund, Verlaufsende, Karte,
Vertiefung):

| | min | Schwelle |
|---|---|---|
| Tinte `#12383F` | 10,5:1 | 4,5 |
| Teal `#025D70` | 6,2:1 | 4,5 |
| Sekundärtext `#4F6468` | 5,2:1 | 4,5 |
| Warnung `#A8442A` | 5,0:1 | 4,5 |
| Ocker `#8F5500` | 5,0:1 | 4,5 |
| Karten-Weiß auf Teal | 7,2:1 | 4,5 |
| Ocker auf dem Zähler-Chip | 4,6:1 | 4,5 |

**Der Ocker ist um eine Nuance nachgedunkelt.** Die Vorgabe nannte `#955900`;
das hält die 4,5:1 auf allen vier Flächen, kommt aber auf dem Zähler-Chip
`#F5DEB9` nur auf **4,3:1** — und genau dort steht Ocker-Text. `#8F5500`
bringt ihn auf 4,6:1. Das PDF sah das ausdrücklich vor.

### Wo das Amber die Schwelle nicht hält — und warum es trotzdem bleibt

Das Amber `#E59305` erreicht gegen die helle Karte **2,4:1** und gegen den
Creme-Amber daneben **2,1:1**. Die WCAG verlangt für grafische Elemente 3:1.
Dunkler wäre es kein Amber mehr, und das Amber ist der Punkt.

Es bleibt, weil der Zustand nie an der Fläche allein hängt: Im Haken steht
ein Haken, am Zähler eine Zahl, an der Challenge die Angabe „1 von 4", an der
Serie die Zahl der Tage. Die Fläche ist Wiedererkennung, nicht die
Information. Der Test sagt das jetzt ausdrücklich, statt eine 3:1-Schwelle zu
behaupten, die hier nicht gilt — wer die Zeile liest, weiß, dass es eine
Entscheidung war und kein Versehen.

**Was auf dem Amber liegt, ist die Tinte** (`#12383F`, 5,1:1). Das
Referenzbild zeigt dort weiße Haken; Weiß auf Amber kommt auf 2,5:1 und wäre
selbst als Haken zu schwach.

### Zwei neue Tönungsrollen

Die warmen Flächen aus dem Bild standen bisher als Rechnung im Widget:

- `erreichtLeer` — die ungefüllte Gegenseite im Challenge-Balken. Vorher
  `textSekundaer` bei 18 %, was hell ein kühles Grau ergeben hätte; jetzt
  `#FDE9D2`.
- `erreichtChip` — die Fläche des Zählers „2/5". Vorher `erreicht` bei 14 %,
  was hell zu blass geraten wäre; jetzt `#F5DEB9`.

**Im Dunkelmodus tragen beide exakt die Zahlen, die dort vorher gerechnet
wurden** (`0x2EBCCCC8` und `0x24E8BE6E`). Ein Test vergleicht sie mit
genau diesen Rechnungen — aus dem Aufräumen wird so keine Änderung.

Der Kreis hinter der Flamme brauchte keine eigene Rolle: Er entsteht weiter
aus dem Amber bei 16 % und ergibt auf der Karte `#FAEAD0` — der Vorgabe
`#FDECD6` bis auf wenige Stufen gleich.

### Was beide Modi berührt hat

Drei Stellen, alle im Dunkelmodus folgenlos:

1. **Die zwei neuen Rollen** — dunkel wertgleich mit dem, was vorher
   gerechnet wurde.
2. **Flamme und Joker-Schilde** wechseln von `erreicht` auf
   `erreichtFlaeche`. Dunkel sind beide Rollen derselbe Ton — Pixel für
   Pixel dasselbe.
3. **Die Zusicherung im Kamera-Test** hieß seit DECISIONS 62 „Buttontext ist
   praktisch der Hintergrundton". Hell ist er jetzt das **Karten-Weiß** —
   Vorgabe. Der Test sagt deshalb: `aufAkzent` ist der Hintergrund **oder**
   die Kartenfarbe seines Schemas. Dunkel bleibt es der Hintergrund; eine
   Fremdfarbe fällt weiterhin durch.

**Der Einfrier-Test ist unverändert grün.** Alle vierzehn Dunkelwerte stehen
weiter als abgeschriebene Zahl.

### Was aus dem Referenzbild NICHT übernommen wurde

- **Die Tab-Leiste am unteren Rand.** Ausdrücklich ausgeschlossen; die
  Navigation bleibt, wie sie ist.
- **Das zweite, teal eingefärbte Segment** im Challenge-Balken. Im Bild ist
  es ein Gestaltungseinfall, in der Vorgabe steht er nicht — gefüllt ist
  Amber, ungefüllt Creme-Amber.
- **Weiße Haken auf Amber** — siehe oben, Kontrast.
- **Ein amberner Zähler bei „2/5".** Der Chip färbt sich erst, wenn die Liste
  steht: Ein halb voller Zähler ist kein Erreichtes (DECISIONS 50). Das Bild
  zeigt ihn amber, die Regel ist älter und bleibt.

**Preis:** Zwei Farbrollen mehr. Layout, Rundungen und Animationen sind in
beiden Modi unverändert — es haben sich ausschließlich Farbwerte bewegt.

## 64 · Ocker ist Schrift, Amber ist alles Sichtbare

Nach der Umstellung auf Creme, Teal und Amber (DECISIONS 63) trugen alle
kleinen Erreicht-Elemente das dunkle Ocker `#8F5500`: Haken, Joker-Schilde,
gewählte Radio-Punkte, Abzeichen, Auswahlrahmen. Auf hellem Grund wirkt das
schlammig statt golden — und es war mein Fehler: Ich hatte die Text-Rolle
überall dort stehen lassen, wo vorher ein einziges Gold beides konnte.

**Die Regel ist jetzt hart und ohne Ausnahme:**

| Rolle | wo |
|---|---|
| `erreicht` `#8F5500` | **ausschließlich** in einem `TextStyle` |
| `erreichtFlaeche` `#E59305` | jede Fläche, jeder Rahmen, jedes Symbol |

Umgestellt wurden 31 Stellen in 16 Dateien: die Haken in Chip und
Modul-Karte samt Rahmen, die Joker-Schilde, der Radio-Punkt der Moduswahl,
die Radio-Symbole in Onboarding und Stil-Fragebogen, die Auswahlrahmen von
Karten, Chips und Check-in-Listen, der Haken am geprüften Foto, die Karte
„Dein neuer Look", der Jubel samt Konfetti, die Glut im Markenzeichen und die
Abzeichen. Übrig geblieben sind elf Stellen — alle elf `color:` in einem
`TextStyle`.

**Der Haken ist jetzt Karten-Weiß** (`#FEFAF7`), wie im Referenzbild. Einen
Commit lang stand dort die Tinte, weil sie 5,1:1 erreicht — das ergab
dunkles Braun auf Orange, also genau den Look, der weg sollte.

Das Karten-Weiß kommt auf dem Amber auf **2,5:1** und hält damit keine
Schwelle, weder die 4,5:1 für Text noch die 3:1 für grafische Elemente. Das
ist eine ausdrückliche Entscheidung: Der Haken ist Zierrat. Was er anzeigt,
steht immer auch woanders — die erledigte Aufgabe ist durchgestrichen, der
Zähler nennt „2/5", die Challenge „1 von 4". **Ein Test hält die Zahl fest**,
mitsamt der Begründung, damit sie niemand für ein Versehen hält und niemand
sie unbemerkt verschlechtert.

**Ein Test hält auch die Regel selbst.** Er liest den Quelltext, weil sich
das anders nicht prüfen lässt: Eine Farbe im Widgetbaum sagt nicht mehr,
wofür sie gedacht war. Drei Prüfungen:

1. `farben.erreicht` steht nur innerhalb eines `TextStyle`.
2. `farben.erreichtFlaeche` steht in keinem `TextStyle` — Amber-Text käme
   auf 2,4:1.
3. Keine Datei außer der Palette schreibt eine der vier Amber-Zahlen von
   Hand hin.

Der Test hat sich beim ersten Lauf sofort bezahlt gemacht: Er fand den
Zähler „1/9" über den Abzeichen, den ich versehentlich mit umgestellt hatte.

**Abzeichen** brauchten keine eigene Behandlung. Sie rechnen ihren Kreis und
den Zierring aus derselben Farbe (16 % und 70 %); mit dem Amber ergibt das
auf der Karte einen warmen Creme-Amber-Kreis mit Amber-Icon — die
`#FDECD6`-Familie aus der Vorgabe. Gesperrte bleiben neutral grau mit Schloss.

### Der Dunkelmodus

Alle 31 Stellen wechseln von `erreicht` auf `erreichtFlaeche` — und **dunkel
sind beide Rollen derselbe Ton** `#E8BE6E`. Es rendert Pixel für Pixel
dasselbe. Der Einfrier-Test mit den vierzehn abgeschriebenen Werten ist
unverändert grün.

### Was nicht umgesetzt wurde

**Der Umschalter in den Einstellungen bleibt teal.** Er ist der einzige
Punkt aus der Liste, den ich nicht umgestellt habe: Er zieht seine Farbe aus
`colorScheme.primary`, also aus `akzent`. Ein eigenes `switchTheme` mit
`erreichtFlaeche` würde ihn hell amber machen — **und dunkel von Sand
`#D8C6AA` auf Gold `#E8BE6E**, also sichtbar. Das steht gegen die Regel, die
über diesem Paket steht.

Bemerkenswert ist der Befund trotzdem: Nach DECISIONS 51 ist Gold die Farbe
für „jeden Zustand, den der Nutzer selbst eingeschaltet hat" — ein
Umschalter ist genau das. Dass er im Dunkelmodus Sand trägt, ist eine alte
Unstimmigkeit, keine Entscheidung. Wer sie aufräumen will, braucht ein Paket,
das die Änderung am Dunkelmodus ausdrücklich erlaubt.

**Preis:** Keiner an Laufzeit. Ein Test mehr, der Quelltext liest — der
langsamste der Sammlung, mit rund einer Zehntelsekunde.

## 65 · Vier Tabs statt einer sehr langen Startseite

Die Startseite war eine einzige Liste: Serie, Challenge, Plan-Zusammenfassung,
alle Checklisten, Abzeichen — und ganz unten der Knopf für eine neue Analyse.
**Die Kernfunktion stand am Seitenende**, und wer nur abhaken wollte, scrollte
an allem anderen vorbei.

**Jeder Tab beantwortet jetzt eine Frage:**

| Tab | Frage | Inhalt |
|---|---|---|
| Heute | Was mache ich jetzt? | Serie, Challenge, die vollständige Tagesliste |
| Plan | Was steht drin? | Zusammenfassung, nächster Check-in, die drei Phasen |
| Analyse | Neu vermessen | Kontingent, Start, Verlauf |
| Fortschritt | Was habe ich geschafft? | Rückblick, Bilanz, Abzeichen, Foto-Album |

Daraus folgt die Regel, an der sich jede künftige Karte messen lassen muss:
**Kein Inhalt existiert doppelt.** Wer eine Karte auf zwei Tabs stellt, hat
die Frage nicht beantwortet, sondern verdoppelt. Ein Test geht alle vier Tabs
durch und zählt: Jede der sechs großen Karten steht auf genau einem.

**Nur Umzug, kein Umbau.** Die Karten selbst sind unverändert; zwei wurden
lediglich aus ihren alten Bildschirmen herausgelöst, weil sie dort privat
waren: die Phasen-Karte aus `plan_screen.dart` und die Verlaufs-Karte aus
`history_screen.dart`. Beide Bildschirme gibt es nicht mehr — ihr Inhalt sind
jetzt Tabs.

**Zwei Karten wurden neu geschrieben, und zwar bewusst:**

- Die **Bilanz** im Fortschritt-Tab (laufende Serie und Rekord als zwei
  Zahlen). Die Streak-Karte selbst bleibt auf „Heute": Sie fordert zum
  Abhaken auf und gehört dorthin, wo abgehakt wird. Im Fortschritt-Tab
  stünde sie als Aufforderung am falschen Ort — dort geht es ums Zurückblicken.
- Der **Kontingent-Stand** im Analyse-Tab. Er stand bisher klein auf der
  Modulauswahl, also einen Schritt zu spät: Wer wissen will, ob heute noch
  ein Lauf frei ist, fragt das vor dem Start.

### Die Leiste

Handgebaut statt `NavigationBar`: Material 3 legt hinter das aktive Symbol
eine gefüllte Pille in `secondaryContainer`, und die gibt es in diesem
Farbsystem nicht. Nachgerüstet wäre es mehr Code als die Leiste selbst — und
eine zweite Stelle, an der Farben entstehen.

Sie trägt den Kartenton des jeweiligen Modus mit einer feinen Kontur nach
oben. Der aktive Tab bekommt das Symbol in der Flächen-Farbe und die
Beschriftung in der Schrift-Farbe — dieselbe Trennung wie überall
(DECISIONS 64). Zusätzlich ist das aktive Symbol gefüllt und das inaktive ein
Umriss: der Unterschied ist auch ohne Farbe zu sehen.

**Der Punkt am „Heute"-Tab** steht, solange heute noch keine Aufgabe abgehakt
ist. Zwei Dinge daran waren nicht selbstverständlich:

- **Er ist im Akzentton, nicht im Amber.** Auf dem aktiven Tab ist das Symbol
  selbst schon amber; ein amberner Punkt darauf war schlicht unsichtbar. Und
  inhaltlich stimmt es auch besser: Der Punkt sagt „hier ist noch etwas
  offen" — das ist kein Erreichtes.
- **Er zählt nur echte Tagesaufgaben.** Im selben Satz steht auch die Marke
  eines erledigten Check-ins, und die ist kein Haken. Dieselbe Rechnung wie
  in der Streak-Karte, damit Punkt und Kartentext nicht auseinanderlaufen.

Am Gerät fiel dabei ein dritter Punkt auf: Der Punkt lag zunächst außerhalb
der `Stack`-Grenzen und wurde abgeschnitten — im Widget-Baum war er da, auf
dem Bildschirm nicht. Der Test prüft deshalb jetzt die **gezeichnete Fläche**
und nicht nur, dass das Widget existiert.

### Die Wege dorthin

Die Pfade `/plan` und `/history` bleiben, obwohl es die Bildschirme nicht mehr
gibt: Benachrichtigungen, der Check-in und ältere Wege zeigen darauf. Sie
setzen den Tab und leiten auf `/` weiter, statt eine zweite Hülle
aufzumachen — nur so gibt es genau **eine**, und die behält ihre vier
Scroll-Positionen.

Das **Verlaufs-Symbol oben rechts** öffnet keinen eigenen Bildschirm mehr,
sondern springt in den Analyse-Tab. Eine zweite Liste derselben Einträge wäre
genau die Doppelung, die die Regel oben verbietet.

Nach einem abgeschlossenen **Check-in** landet man auf „Heute" und nicht auf
dem Tab, von dem der Check-in kam: Was er geändert hat, sind die
Tagesaufgaben.

**Die Zurück-Taste** führt aus einem anderen Tab erst nach „Heute" und erst
von dort aus der App. Ohne das wäre ein Tabwechsel eine Einbahnstraße — die
Leiste kennt keinen Verlauf, die Taste schon.

**Preis:** Eine Hülle mehr und vier Dateien statt zweier Bildschirme. Dafür
ist die längste Liste der App nur noch so lang wie die Tagesaufgaben.

## 66 · Der Dunkelmodus ist der Standard — und das steht jetzt fest

Die App soll dunkel starten, unabhängig davon, wie das Handy eingestellt ist.
**Das war schon so.** `ThemeController.standard` steht seit dem Umbau des
Erscheinungsbilds auf `dunkel`, und `_lade` fällt auf ihn zurück, sobald
nichts oder Unlesbares gespeichert ist. Auch der native Splash war bereits
festgenagelt: Die Farbe `splashHintergrund` hat bewusst **kein** Gegenstück
unter `values-night/`, und alle vier Style-Dateien nennen denselben Ton.

Was fehlte, war der **Nachweis**. Ohne ihn kann eine einzelne Zeile den
Standard still auf „Wie das System" zurückdrehen, und aufgefallen wäre es
erst auf einem hell gestellten Handy — vermutlich beim Nutzer, nicht bei uns.
Deshalb hält ein Test jetzt fünf Dinge fest:

1. Ohne eigene Wahl ist es `dunkel`, nicht `system`.
2. Auch ein kaputter Eintrag (alter Wert, halber Sync, `null`) landet dort.
3. Eine getroffene Wahl übersteht den Neustart — auch „Wie das System",
   das ist eine bewusste Option und kein Unfall.
4. Erst „Alle Daten löschen" bringt den Standard zurück.
5. Der native Start-Bildschirm trägt in **allen vier** Style-Dateien
   denselben Ton, und `values-night/colors.xml` existiert nicht. Sonst
   startet ein hell gestelltes Handy hell und springt beim ersten
   Flutter-Frame ins Dunkle — genau der Sprung, den DECISIONS 53 abgeschafft
   hat.

**Eine echte Änderung gab es doch:** Die Auswahl in den Einstellungen zeigt
`Erscheinungsbild.values` der Reihe nach, und die Reihe begann mit „Hell".
Was voreingestellt ist, soll auch zuerst stehen — die Reihenfolge ist jetzt
Dunkel, Hell, Wie das System. Gespeichert wird der `name` und nicht der
Index; für alles, was schon auf einem Gerät liegt, ist das Umsortieren
folgenlos.

**Preis:** Keiner. Ein Test mehr und eine umsortierte Aufzählung.

## 67 · Das Gesamtbild oben, die Namen erst im Kapitel

Befund vom Gerät, in **beiden** Modi: Die Karte ganz oben zählte bereits die
konkreten Vorschläge auf — den Schnitt mit Namen, den Bartstil, die
Kleidungsstücke — und die Kapitel darunter wiederholten exakt dasselbe. Der
Report las sich wie zweimal derselbe Text.

**Jede Information hat jetzt genau ein Zuhause:**

| | Gesamtbild oben | Kapitel |
|---|---|---|
| Was | Wirkung und Zusammenspiel | der Vorschlag mit Namen |
| Wie lang | 2–4 Sätze | so lang wie nötig |
| Namen | **keine** | hier zum ersten Mal |

### Ein Feld für beide Modi

Bis hierher gab es das Vorspann-Feld nur im entdeckenden Modus (`neuerLook`).
Jetzt heißt es `gesamtbild` und existiert in beiden — im verfeinernden
beschreibt es, was am jetzigen Look trägt und wohin die Verfeinerung zielt.
Die Karte trägt je Modus eine eigene Überschrift, weil sie etwas anderes
beschreibt: „Dein neuer Look" bzw. „Dein Gesamtbild".

**Alte Reports behalten ihren Vorspann.** Beim Lesen wird `gesamtbild`
bevorzugt und auf `neuerLook` zurückgefallen — ein Report von gestern steht
also nicht plötzlich ohne Einstieg da.

### Die Regel im Prompt

Sie steht in beiden Prompt-Zweigen, mit je einem Positiv- und einem
Negativbeispiel, in beiden Sprachen. Das Negativbeispiel ist absichtlich
genau das, was vorher wirklich herauskam:

> FALSCH: „Ein Textured Crop mit mittelhohem Fade, dazu ein Vollbart auf
> 6 mm und ein Overshirt in Oliv."

Die Beispiele sind ausdrücklich als **Muster für die Form** markiert, mit der
Aufforderung, keinen ihrer Sätze zu übernehmen. Ohne diese Markierung
schreibt ein Modell sie wörtlich ab (DECISIONS 36) — und dann stünde in jedem
Report derselbe Satz. Die Beispiele beschreiben deshalb auch bewusst eine
andere Person als die, die gerade analysiert wird.

Dazu die Gegenrichtung, ohne die die Doppelung nur wandert: **Die Kapitel
steigen direkt mit ihrem Vorschlag ein** und fassen das Gesamtbild nicht noch
einmal zusammen.

### Die maschinelle Absicherung

Bei freiem Text lässt sich das nicht erzwingen; die Hauptarbeit leistet der
Prompt. Die Nachbereitung erkennt aber den offensichtlichen Fall: **Ein Name,
der in einem Kapitel steht und wörtlich schon im Gesamtbild vorkommt.**

Gesucht werden Eigennamen — zwei oder drei großgeschriebene Wörter
hintereinander, mitten im Satz. Das trifft „Textured Crop", „Modern Mullet"
oder „Smart Casual" und verfehlt „kürzere Seiten": Eine Umschreibung ist
keine Doppelung im Sinne der Regel, sondern höchstens eine Unschönheit.
**Satzanfänge fallen heraus** — im Deutschen steht dort jedes Wort groß, und
„Deine Kieferlinie" wäre sonst ein Treffer, der die Meldung wertlos machte.

Gefundenes wird **nur protokolliert, nicht repariert**: Ein Name lässt sich
aus einem Fließtext nicht herausschneiden, ohne den Satz zu zerstören. Die
Zahl sagt uns, ob die Prompt-Regel wirkt.

### Der Demo-Modus

Beide Beispielantworten haben die neue Struktur — das entdeckende Gesamtbild
nennt keinen Schnittnamen mehr, das verfeinernde ist neu dazugekommen. Damit
lässt sich die Oberfläche in beiden Modi ohne Kontingent prüfen.

**Preis:** Ein Feld mehr im Schema des verfeinernden Modus und rund 20 Zeilen
Prompt in jedem Lauf. Das kostet Eingabe-Tokens — und spart dem Leser einen
Text, den er zweimal liest.

## 68 · Auch die Outfit-Fotos lösen selbst aus

Dasselbe Problem wie bei den Ganzkörperfotos, ein Modul weiter: Für ein
Outfit-Foto stellt man das Handy ab und tritt mehrere Meter zurück. Von dort
ist der Auslöser nicht erreichbar. Bisher lösten nur die beiden Figur-Fotos
selbst aus — bei den drei Outfit-Fotos musste man zurücklaufen, tippen und
wieder hinlaufen, oder jemanden bitten.

**Gleiche Lösung, gleiche Bauteile.** Die drei Aufnahmen bekommen
`autoAusloeser: true`. Damit läuft dieselbe Kette wie bei der Figur:
Posenerkennung → `LiveKoerperGuide` → `AutoAusloeser` → Countdown → Auslösen.
An der Logik selbst wurde nichts geändert, sie ist Zeile für Zeile dieselbe.

### Warum die Haltungsregeln passen

Der Guide verlangt Kopf **und** Füße im Bild, 55–94 % der Bildhöhe und mittig
stehend. Das ist für ein Outfit-Foto nicht bloß zulässig, sondern genau
richtig: Ein Outfit beurteilt man von der Schulter bis zum Schuh. Wer
angeschnitten oder zu weit weg steht, liefert ein Bild, aus dem die Analyse
über Passform und Proportion nichts sagen kann.

### Der Unterschied: Hier ist eine Person freiwillig

Das Outfit darf **ausgelegt** sein oder auf dem Bügel hängen — so steht es im
Hinweis des Schritts, und `Pruefprofil.frei` lässt es zu. Ein Auto-Auslöser,
der eine Person verlangt, würde diesen Weg verbauen.

Er tut es nicht, und zwar von selbst: Ohne Person erkennt ML Kit keine Pose,
der Guide meldet „niemand", der Countdown startet gar nicht erst — und der
Auslöser ist wie immer druckbar. Der Ring um ihn markiert nur die Haltung, er
sperrt nichts. **Der Automatismus ist hier ein Angebot, keine Bedingung.**

Damit das auch so *klingt*, tragen zwei Texte eine zweite Fassung:

| | Ganzkörper | Outfit |
|---|---|---|
| Erklärung im Schritt | „…stell dich in den **Umriss**" | „…**mittig ins Bild**", plus: liegt das Outfit da, löst du von Hand aus |
| Sucher, niemand im Bild | „Stell dich ins Bild" | „Stell dich ins Bild – **oder löse von Hand aus**" |

Der erste Unterschied ist kein Stil, sondern eine Tatsache: Die Outfit-Fotos
haben keine Silhouette (`Overlaytyp.keins`). „Stell dich in den Umriss"
schickte den Nutzer dort nach etwas suchen, was nicht da ist. Alle übrigen
Hinweise — „ganz ins Bild", „ein paar Schritte zurück", „steht" — bleiben
wortgleich; die Haltungsregeln sind identisch, also darf die Anweisung es
auch sein.

### Kein Umriss dazu

Naheliegend wäre gewesen, den Outfit-Fotos die Ganzkörper-Silhouette zu geben
— sie zielt genau in die Mitte dessen, was der Guide akzeptiert. Dagegen
spricht der ausgelegte Fall: Ein Körperumriss über einem Hemd auf dem Bett
ist eine Anweisung, die dort niemand befolgen kann. Das freie Bild bleibt
frei.

### Was dabei wegfiel

Seit dieser Änderung hat **jede** Aufnahme eine Erkennung — Gesicht oder
Pose. Die stumme Anleitungskarte im Sucher, die nur bei den Outfit-Fotos zu
sehen war, hatte damit keinen Fall mehr und ist entfernt. Ihr Text steht
unverändert eine Ebene höher unter „So klappt das Foto". Ein Test hält fest,
dass es keine Aufnahme ohne Bildstrom mehr gibt: Wer eine hinzufügt, muss den
Sucher wieder um eine Fassung ohne Statuszeile ergänzen.

**Preis:** Auf den drei Outfit-Schritten läuft jetzt die Posenerkennung mit —
etwa vier Bilder je Sekunde, dieselbe Taktung wie bei der Figur. Das kostet
Rechenzeit und Wärme auf schwachen Geräten, in einem Schritt, der bisher
ganz ohne auskam. Dafür entfällt der Weg zum Handy und zurück, drei Mal.

## 69 · Beispielbilder unter den Vorschlägen

„Ein Textured Crop mit mittelhohem Fade" ist für jemanden, der das noch nie
gesehen hat, kein Bild im Kopf, sondern eine Vokabel. Der Report beschreibt
mit Worten, was man ansehen müsste. Unter jedem konkreten Vorschlag steht
jetzt eine Reihe echter Fotos — antippbar, zum Vergrößern.

**Echte Fotos, keine erzeugten.** Quelle ist **Pexels**: kostenlos, mit
freier Lizenz, ohne Kreditkarte. Ausdrücklich **keine** KI-Bildgenerierung —
ein erzeugtes Gesicht mit dem vorgeschlagenen Schnitt wäre eine Behauptung
darüber, wie der Nutzer damit aussieht. Und ausdrücklich keine allgemeine
Bildersuche: Deren Ergebnisse sind rechtlich nicht geklärt.

### Drei Teile, drei Commits

**1 · Der Suchbegriff kommt vom Modell.** Jede Sektion trägt ein Feld
`bildSuchbegriff` — zwei bis sechs englische Wörter, wie man sie in ein
Suchfeld tippt.

Warum das Modell und nicht die App: Der Sektionstitel („Frisur") taugt nicht
als Suchbegriff, der Empfehlungstext ist zu lang, und aus beidem einen zu
bauen hieße, den Vorschlag auf dem Client noch einmal zu verstehen. Das
Modell weiß bereits, was es vorschlägt.

Die Regeln im Prompt:

| Regel | Warum |
|---|---|
| immer Englisch | Eine internationale Fotobibliothek findet zu „kurzer Vollbart" nichts |
| generisch, keine Marke, kein Prominenter | sonst steht die App für eine Empfehlung, die sie nicht gibt |
| „men" / „women" je nach Ausrichtung | ohne das Wort liefert Pexels zu „french crop haircut" überwiegend Männer — auch für eine Nutzerin |
| bei Stil das ganze Ensemble | ein einzelnes Kleidungsstück ist kein Look |
| `null`, wo ein Foto nichts zeigt | eine Pflegeroutine, eine Haltungsübung |

Die Beispiele im Prompt sind wie beim Gesamtbild als **Muster für die FORM**
markiert (DECISIONS 36). Ohne diese Markierung schriebe das Modell sie
wörtlich ab, und jeder Report zeigte Fotos desselben Haarschnitts.

**2 · Die Suche läuft über den Server.** Neue Function `bilderSuchen`. Der
Pexels-Schlüssel liegt im Secret Manager — dasselbe Argument wie beim
Gemini-Proxy: In einem APK wäre er auslesbar und der Verbrauch ginge auf
unser Konto. Anleitung in SETUP.md 5.7.

Die Function zählt **nicht** gegen das Analyse-Kontingent. Einen fertigen
Report anzusehen darf keine Analyse kosten.

**3 · Die Reihe in der App.** Unter jedem Vorschlag, ganz unten: erst lesen,
was empfohlen wird, dann sehen, wie es aussieht. Antippen öffnet ein
Vollbild mit Wischen, Fotografennamen und Link zurück zu Pexels.

### Die wichtigste Eigenschaft: Sie verschwindet

Kein Netz, kein Treffer, kein Schlüssel, ein Serverfehler, ein altes
Report-Dokument ohne Suchbegriffe — **die Reihe fehlt einfach.** Keine
Fehlermeldung, keine leere Fläche, keine Lücke im Layout.

Das ist keine Bequemlichkeit, sondern die richtige Reaktion: Der Report ist
ohne Bilder vollständig. Eine Fehlermeldung würde etwas als kaputt melden,
das der Nutzer nie bestellt hat. Nur während des Ladens stehen Platzhalter —
damit die Karte nicht springt, sobald die Bilder da sind.

### Zwei Bremsen vor der Fotobibliothek

Pexels erlaubt im kostenlosen Tarif **200 Anfragen je Stunde**, 20 000 im
Monat.

1. **Ein Cache in Firestore, 30 Tage.** „textured crop haircut men" schlägt
   das Modell vielen Nutzern vor — gesucht wird er trotzdem nur einmal im
   Monat. Gespeichert werden ausschließlich URLs, Fotografennamen und ein
   Zeitstempel; **keine Bilddateien**. Die Sammlung gehört keinem Konto und
   ist für jeden Client gesperrt.
2. **Ein Zähler je Stunde, Grenze 150.** Der Server hört von sich aus auf zu
   fragen, statt in die Sperre bei 200 zu laufen. Der Abstand ist der Puffer
   für Anfragen, die gerade unterwegs sind.

**Der Unterschied zwischen „nichts gefunden" und „Anfrage gescheitert" ist
der Kern des Caches.** Nur das erste wird gemerkt. Sonst gälte ein
Netzaussetzer dreißig Tage lang als „zu diesem Begriff gibt es keine
Bilder".

### Die Lizenz

Die Pexels-Lizenz erlaubt die Nutzung; die Nennung des Fotografen mit Link
zur Quelle ist erwünscht. Sie steht fest am unteren Rand des Vollbilds.

**Ein Bild ohne Fotografennamen oder ohne Quellseite kommt gar nicht erst
durch** — zweimal geprüft, auf dem Server und noch einmal beim Lesen in der
App. Die Regel steht damit auch an der Stelle, an der sie angezeigt wird.
Nur `https`.

### Was der Demo-Modus zeigt — und was nicht

Im Demo-Modus läuft kein Firebase (`main.dart`), also gibt es dort keine
Bildersuche. Statt die Reihe wegzulassen, liefert `DemoBilderDienst` drei
Einträge **ohne Bilddatei**: Die Reihe steht da, lässt sich antippen,
durchwischen, und die Nennung ist zu sehen — nur die Fotos selbst sind
gezeichnete Platzhalter.

**Damit ist ausdrücklich nicht bewiesen, dass ein echtes Foto lädt und
sitzt.** Das braucht einen Report vom Server. Der Alternativweg wären
mitgelieferte Beispielfotos im APK gewesen; dagegen sprach, dass sie in
jedem Release mitreisen, obwohl sie nur im Demo-Modus vorkommen.

### Was das kostet

**Bei Gemini:** Die Regel im Prompt sind 1 241 Zeichen, rund 350
Eingabe-Tokens je Lauf. Dazu je Sektion ein kurzes Feld — bei einem vollen
Report mit dreißig Sektionen etwa 240 Ausgabe-Tokens. Bei den derzeit für
Flash üblichen Preisen liegt das zusammen **deutlich unter 0,1 Cent pro
Analyse**; die Zahl ist eine Schätzung, weil die Preisliste sich ändert. Die
Größenordnung ändert sich dadurch nicht: Es ist ein Bruchteil dessen, was
die elf Bilder einer Analyse kosten. Die Verbrauchszeile im Protokoll zeigt
den tatsächlichen Wert.

**Bei Pexels:** nichts, der Tarif ist kostenlos.

**Bei Firestore:** ein Dokument je Suchbegriff und eines je Stunde. Beides
im Bereich weniger Kilobyte.

**Wenn das Pexels-Limit erreicht wird:** Die betroffenen Bilderreihen
fehlen, alles andere bleibt unberührt. Im Protokoll steht
`Bildersuche: Stundenlimit erreicht`.

### Die Grenze, die bleibt

Der Zeichenfilter für Suchbegriffe fängt Umlaute — „kurzer Vollbart" ohne
Umlaut kommt durch. Das ist festgehalten und kein Versehen: Eine
Spracherkennung auf sechs Wörtern rät mehr, als sie erkennt, und ein
fälschlich verworfener Begriff kostet eine Bilderreihe, die es hätte geben
können. Was durchkommt, findet in einer internationalen Fotobibliothek
nichts — und ohne Treffer fällt die Reihe ohnehin weg.

**Preis:** Ein Feld mehr im Schema, eine Function mehr, eine Sammlung mehr
in Firestore, ein weiterer Schlüssel, der gepflegt werden muss. Und ein
Report, der beim Scrollen Bilder nachlädt, statt sofort fertig dazustehen.

## 70 · „Heute" folgt dem Tag, nicht dem Kapitel

Befund vom Gerät: Innerhalb eines Kapitels sprangen die Aufgaben wild durch
den Tag. „Haare & Bart" las sich als

> nach dem Aufstehen → nach dem Duschen → nach dem Zähneputzen → vor dem
> Schlafengehen → **nach dem Frühstück**

Wer die Liste von oben nach unten abarbeitet, landet nach dem Zubettgehen
wieder beim Frühstück. Die Sortierung nach Thema ist beim Nachlesen richtig
und beim Abhaken falsch.

**Der Heute-Tab gruppiert jetzt nach Tagesabschnitt:** „Morgens",
„Tagsüber", „Abends", „Bei Bedarf" — in dieser Reihenfolge, leere Abschnitte
fallen weg.

### Sortiert wird nach dem Anker, den es längst gibt

Seit DECISIONS 44 trägt jede Tagesaufgabe einen Wenn-dann-Anker: „Nach dem
Aufstehen: Gesicht waschen". Der Anker sagt, *wann* etwas passiert — also
kann er die Liste auch ordnen. Es musste dafür nichts Neues in den Report.

Die Zuordnung steht an genau **einer** Stelle
(`lib/features/plan/logic/tagesabschnitt.dart`), und die Reihenfolge in der
Tabelle ist zugleich die Reihenfolge innerhalb des Abschnitts:

| Abschnitt | Anker, in dieser Reihenfolge |
|---|---|
| Morgens | nach dem Aufstehen · beim Duschen · nach dem Duschen · nach dem Frühstück · nach dem Zähneputzen |
| Abends | nach dem Abendessen · vor dem Schlafengehen |

Beide Sprachen stehen nebeneinander, weil der Anker in der Sprache im Report
steht, in der er entstanden ist. Wer die App danach umstellt, behält seine
alten Aufgaben — und die müssen weiter einsortiert werden.

**„Nach dem Zähneputzen" steht morgens**, obwohl auch abends Zähne geputzt
werden. Den Anker gibt es nur einmal; morgens ist er der letzte Griff vor dem
Haus, der Punkt, an dem „Haare richten" sitzt. Abends gibt es dafür „vor dem
Schlafengehen".

### Drei Fälle, drei Antworten

| Was in der Aufgabe steht | Wohin sie geht |
|---|---|
| ein bekannter Anker | sein Abschnitt, an seiner Stelle |
| ein unbekannter Anker („Bei Rauchverlangen: …") | **Bei Bedarf** |
| gar kein Anker (Report von vor DECISIONS 44) | **Tagsüber** |

Der mittlere Fall ist kein Fehler: Der Prompt lässt für die Aufgaben aus dem
Freitext ausdrücklich eine *Situation* als Auslöser zu, und die hat keine
Tageszeit. Der untere ist die Rückfalls-Sicherheit — alte Aufgaben
verschwinden nicht, sie stehen in der Mitte des Tages.

Ein Anker ist höchstens 45 Zeichen lang. Ohne diese Schranke läse
„Zähne putzen, und zwar wirklich sehr gründlich und ohne Eile: zwei Minuten"
als unbekannter Anker und landete bei Bedarf.

### Das Thema bleibt sichtbar

Die Überschrift nennt jetzt die Tageszeit, also muss das Thema woanders
stehen: als **kleines Symbol am Ende der Zeile** — das Icon des Kapitels, in
der Sekundärfarbe, nicht antippbar. Für die Sprachausgabe trägt es den Namen
des Bereichs; ein Symbol allein ist für einen Screenreader nichts.

### Was ausdrücklich gleich bleibt

- **Die Streak-Logik.** Erster Haken sichert den Tag, Serie, Joker,
  Challenge, der „Tag gesichert!"-Moment — nichts davon wurde angefasst. Der
  Fortschritt hängt weiterhin am Aufgabentext, nicht an ihrer Position.
- **Die Herkunft.** Eine Aufgabe kann per Konstruktion nur aus einem Kapitel
  des Reports kommen und damit nur aus einem gewählten Modul. Die
  Gruppierung ordnet um, sie holt nichts dazu.
- **Der Plan-Tab.** Er behält seine thematische Gliederung. Thema dort,
  Tagesablauf hier — nichts doppelt sich.
- **Der volle Aufgabentext samt Anker.** Er bleibt stehen. Unter „Morgens"
  ist „Nach dem Aufstehen:" nicht überflüssig, sondern die Gewohnheit selbst
  (DECISIONS 44) — und die einzige Stelle, an der die Reihenfolge nachprüfbar
  ist.

### Zwei Fallen, die im Test stehen

**Dart sortiert nicht stabil.** Ohne einen mitgeführten Laufindex tauschen
gleichrangige Aufgaben bei jedem Bauen die Plätze — eine Liste, die beim
Scrollen die Reihenfolge wechselt, ist unbenutzbar. Ein Test baut dieselbe
Liste sechsmal und vergleicht.

**Ein Anker, den niemand einsortiert, verschwindet nicht — er landet still
bei Bedarf.** Deshalb steht die Ankerliste im Test noch einmal abgeschrieben:
Kommt in `functions/src/labels.ts` einer dazu, schlägt der Test fehl, statt
dass es niemandem auffällt.

### Der Demo-Modus

Beide Beispielantworten wurden umgeschrieben, damit dort **alle vier
Abschnitte und alle sieben Anker** vorkommen — samt einer situativen Aufgabe
und einer ganz ohne Anker. Der verfeinernde Beispiel-Report trug noch
Aufgaben aus der Zeit vor DECISIONS 44 („Haare morgens mit Paste in Form
bringen"); ohne Anker wäre die neue Sortierung dort gar nicht zu sehen
gewesen.

**Preis:** Der Heute-Tab und der Report sind nicht mehr gleich sortiert. Wer
im Report eine Aufgabe sieht und sie in der Tagesliste sucht, muss wissen,
zu welcher Tageszeit sie gehört. Dafür ist die Liste einmal von oben nach
unten abarbeitbar.

## 71 · Die Rückkamera startet auch wirklich

Befund vom Gerät: Bei den beiden Ganzkörper-Aufnahmen und den drei
Outfit-Fotos kam die **Selfie-Kamera** hoch. Man stellt das Handy ab, tritt
drei Meter zurück — und der Sucher schaut in die falsche Richtung.

Merkwürdig daran: `AufnahmeTyp.rueckkamera` steht dort seit jeher auf `true`,
und der Kamerabildschirm liest es auch aus. Der Fehler lag eine Zeile
weiter:

```dart
final beschreibung = _kameras.firstWhere(
  (k) => k.lensDirection == _richtung,
  orElse: () => _kameras.first,       // <- der stille Ausgang
);
```

**`orElse` nimmt die erste Kamera der Liste — und die ist auf vielen Geräten
die vordere.** Findet die Suche die gewünschte Richtung nicht, landet man
also garantiert im Gegenteil. Ein Gerät, das seine Rückkamera nicht als
`back`, sondern als `external` meldet — das gibt es —, fällt damit exakt in
den beobachteten Fehler.

### Die Wahl steht jetzt an einer prüfbaren Stelle

`waehleKamera()` in `lib/features/capture/logic/kamerawahl.dart`, in drei
Stufen:

1. **Exakter Treffer** — der Normalfall, unabhängig von der Reihenfolge, in
   der das Gerät seine Kameras aufzählt.
2. **Kein Treffer:** die erste Kamera, die **nicht das Gegenteil** ist. Wer
   nach hinten gefragt hat, bekommt lieber eine Kamera unbekannter Bauart
   als die Selfie-Kamera — die zeigt garantiert das Falsche.
3. **Nur das Gegenteil vorhanden** (ein Tablet ohne Rückkamera): dann ist
   eine Kamera besser als keine. Der Wechsel-Knopf steht daneben.

Am Gerät ließ sich das nur mit dem Gerät prüfen; als gewöhnliche Funktion
lässt es sich mit jeder denkbaren Kameraliste prüfen. Genau das tun die
Tests.

### Und eine Zeile im Protokoll

Weicht die gewählte Kamera von der gewünschten ab, steht das jetzt im
Protokoll — mit der gewünschten Richtung, der genommenen und allem, was das
Gerät anbietet:

```
TrueGlow/Aufnahme: Kamera back nicht vorhanden, nehme external
(vorhanden: front, external)
```

**Ehrlich gesagt:** Ob genau das die Ursache am Testgerät war, ist damit
nicht bewiesen — reproduzieren ließ es sich am Schreibtisch nicht. Die
Zeile ist der Ersatz für den Beweis: Tritt es wieder auf, sagt sie in einem
Satz, warum. Kommt sie nicht, war es diese Stelle.

Der Wechsel-Knopf zur Frontkamera bleibt unverändert verfügbar. Ein Test
hält fest, dass genau die fünf Aufnahmen mit der Rückkamera starten, für die
man zurücktritt — und dass das dieselben fünf sind, die selbst auslösen
(DECISIONS 68). Kein Zufall, sondern derselbe Grund: Wer drei Meter entfernt
steht, erreicht weder den Auslöser noch die richtige Linse.

**Preis:** Eine Datei mehr für eine Entscheidung, die vorher in eine Zeile
passte. Dafür ist es die einzige Zeile im Aufnahme-Pfad, die stillschweigend
etwas anderes tat als das, was danebenstand.

## 72 · Der Stil-Fragebogen: eine Liste, eine Frage weniger

Die letzte Seite des Fragebogens stammte aus einer Zeit, in der die App noch
niemandem zwischen 16 und 25 gehörte. In DECISIONS 58 stand sie schon als
offener Punkt; hier wird er abgeräumt.

### „Wohin soll's gehen?" — dieselbe Liste wie bei „Deine Richtung"

Die alte Auswahl (klassisch, minimalistisch, sportlich, smart casual,
kreativ, rockig) beschrieb **dieselbe Sache ein zweites Mal**. Zwei Listen
sind zwei Pflegestellen — und im Prompt zwei Angaben, die sich widersprechen
können: „Streetwear & lässig" bei der Richtung, „Klassisch" beim Stil, und
das Modell muss sich etwas aussuchen.

`Stilziel` als eigenes Enum gibt es deshalb nicht mehr. Der Fragebogen nimmt
`Richtungsziel` — **eine gemeinsame Liste im Code**, auf dem Client wie auf
dem Server (`STILZIEL` in `labels.ts` ist ersatzlos weg, `RICHTUNGSZIEL`
trägt beides).

**Vorbelegt, nicht bevormundet:** Ist bei „Deine Richtung" schon etwas
gewählt, steht es hier markiert — und lässt sich ändern. Wichtig dabei:
Vorbelegt heißt *gespeichert*, nicht nur *angezeigt*. Zeigte der Fragebogen
die Richtung nur an, wäre der erste Tipp auf einen markierten Chip ein
Abwählen von etwas, das nie gespeichert war — und beim nächsten Bauen wäre
er wieder da. Das Übernehmen passiert deshalb einmal nach dem ersten Bild,
nicht während des Bauens.

Die Richtung selbst bleibt davon unberührt: Sie gilt für den ganzen Look,
der Fragebogen nur für die Kleidung.

### „Was verlangt dein Alltag?" wird kleiner und jünger

| vorher (Dresscode, eine Antwort) | jetzt (Zweck, Mehrfachauswahl) |
|---|---|
| Büro / formell | Uni / Schule / Ausbildung |
| Business Casual | Ausgehen & Dates |
| **Handwerk / Arbeitskleidung** | Arbeit / Nebenjob |
| Homeoffice | Gym & Sport |
| **Uniform / Dienstkleidung** | |
| Keine Vorgaben | |

Die beiden fetten Zeilen fallen **ersatzlos** weg: Wer Arbeitskleidung
gestellt bekommt, hat daran nichts zu entscheiden. Die Frage ist jetzt
**überspringbar** — `istVollstaendig` zählt sie nicht mit.

### Der Schwerpunkt liegt auf Ausgehen und Dates

Unabhängig von der Antwort steht im Prompt des Stil-Kapitels jetzt: Outfits
zum Ausgehen und für Dates sind der Schwerpunkt, der Alltag ist
**Nebenbedingung** — die Vorschläge dürfen ihn nicht unmöglich machen, aber
sie richten sich nicht nach ihm. Dafür wird dieser Report gelesen.

Die Zweck-Angabe verschiebt also nicht den Schwerpunkt, sondern nur das,
worauf zusätzlich Rücksicht genommen wird. Das steht ausdrücklich im Prompt,
sonst zieht ein „Arbeit / Nebenjob" die Vorschläge doch wieder ins Büro.

### Nichts darf brechen

Beides wird an **zwei** Stellen überführt — auf dem Client beim Lesen und
auf dem Server beim Empfangen. Der zweite Weg ist für eine App-Fassung, die
noch nicht aktualisiert wurde und weiter alte Namen schickt (dasselbe
Muster wie DECISIONS 58).

| alt | neu |
|---|---|
| klassisch, smartCasual | Smart & hochwertig |
| minimalistisch | Clean & gepflegt |
| sportlich | Sportlich & funktional |
| kreativ | Kreativ & auffällig |
| rockig | Markant & maskulin |
| Büro, Business Casual | Arbeit / Nebenjob |
| Handwerk, Uniform, Homeoffice, keine Vorgaben | *leer* |

Zwei alte Werte landen auf demselben neuen — eine Menge nimmt das ohne
Dublette hin. Bei den vier letzten Dresscodes ist **leer** die ehrlichere
Antwort als eine geratene: Es gibt keinen nächstliegenden Zweck, und die
Frage darf ohnehin offen bleiben.

Budget und Pflegeaufwand sind unverändert.

**Preis:** Der Fragebogen heißt weiter „Vier kurze Fragen" und ist es auch —
aber eine davon ist eine andere geworden. Wer den alten Dresscode
beantwortet hatte, findet unter „Wofür soll dein Style funktionieren?"
entweder „Arbeit / Nebenjob" oder gar nichts vor. Das ist gewollt: Die alte
Antwort war für die neue Frage nur teilweise eine.

## 73 · Die Rückkamera startete schon — der Beleg

Der Verdacht aus dem letzten Paket lautete: Die Ganzkörper-Aufnahme startet
weiterhin vorn, der `orElse`-Fix aus DECISIONS 71 hat nichts gebracht. Statt
einer dritten Vermutung steht hier die Messung am angeschlossenen Gerät
(Galaxy A52, 28.08.2026, 19:07–19:11).

### Was das Gerät sagt

Die App schreibt beim Kamerastart jetzt **immer** eine Zeile — nicht mehr
nur bei einer Abweichung. Das ist die eigentliche Änderung dieses Commits:
Die alte Zeile schwieg im Normalfall, und Schweigen lässt sich nicht von
„nicht passiert" unterscheiden.

```
TrueGlow/Aufnahme: figurGanzkoerperFrontal: wuenscht back, nimmt back (0;
  vorhanden: 0/back, 1/front, 2/back, 3/front)
TrueGlow/Aufnahme: figurGanzkoerperSeitlich: wuenscht back, nimmt back (0; …)
TrueGlow/Aufnahme: stilOutfitEins:           wuenscht back, nimmt back (0; …)
TrueGlow/Aufnahme: basisFrontal:             wuenscht front, nimmt front (1; …)
```

Dazu unabhängig davon das Systemprotokoll von Android:

```
CameraManagerGlobal: Camera 0 facing CAMERA_FACING_BACK state now
  CAMERA_STATE_OPEN for client com.trueglow.app
```

**Die Rückkamera wird angefordert und sie wird geöffnet.** Das Gerät bietet
vier Linsen an (0/back, 1/front, 2/back, 3/front); die Auswahl nimmt 0/back.
Die Gesichts-Aufnahme nimmt 1/front — auch das ist richtig, dort schaut man
ins Display.

Ein Bildschirmfoto des offenen Suchers („Ganzkörper seitlich") zeigt
dasselbe: Bei flach auf dem Tisch liegendem Handy ist das Bild schwarz und
der Hinweis lautet „Mehr Licht nötig" — die nach unten zeigende Rückkamera.
Die Frontkamera hätte die Zimmerdecke gezeigt.

### Es gibt also nichts zu reparieren — und einen wahrscheinlichen Grund

Ein Ganzkörperfoto macht man allein **vor dem Spiegel**. Die Rückkamera
zeigt dort das Spiegelbild — also einen selbst, formatfüllend, so wie es
eine Selfie-Kamera täte. Auf dem Bildschirm ist beides nicht zu
unterscheiden, und der naheliegende Schluss ist der falsche.

Das ist keine Ausrede: Es ist die einzige Erklärung, die mit allen drei
Messungen verträglich ist. Wer es prüfen will, hält die Hand vor die
**Rückseite** des Handys — wird das Bild dunkel, läuft die richtige Linse
(TESTPLAN 35).

### Was `waehleKamera` aus DECISIONS 71 damit ist

Nicht der Fix, für den es gedacht war, aber auch nicht falsch: Die Funktion
verhindert weiterhin, dass ein Gerät ohne `back`-Linse in der Selfie-Kamera
landet. Sie bleibt, samt Tests. Nur die Begründung in DECISIONS 71 stimmt so
nicht — der `orElse`-Zweig griff auf diesem Gerät nie, weil es eine
`back`-Linse gibt.

**Preis:** Eine Protokollzeile bei jedem Kamerastart statt nur im
Ausnahmefall. Ein paar Byte im Logcat gegen eine Frage, die zweimal einen
halben Arbeitstag gekostet hat.

## Mock vs. Live

Erhoben am 24.08.2026 über drei echte Analysen gegen `gemini-2.5-flash`
(Module `basis`, `zaehneLaecheln`, `hautFarbtyp`, `figurPassform`, sieben
Kapitel insgesamt). Die Antworten liegen nicht im Repo — sie enthalten echte
Analysetexte. Nachstellen:

```bash
adb exec-out run-as com.trueglow.app cat app_flutter/analysen.hive > tool/stichprobe/analysen.hive
dart run tool/analysen_exportieren.dart tool/stichprobe
dart run tool/diagnose_stichprobe.dart tool/stichprobe/analyse_*.json
```

| Beobachtung | Mock | Live | Konsequenz |
|---|---|---|---|
| Antwort lesbar beim ersten Versuch | immer | 3 von 3 | Der Nachfass-Pfad (`index.ts`, „Erste Antwort nicht lesbar") wurde kein einziges Mal betreten. Er bleibt trotzdem — eine Stichprobe von drei sagt nichts über den Ausnahmefall. |
| Antwort abgeschnitten | nie | nie | 2.796 bis 4.657 Zeichen, jede Struktur vollständig geschlossen. Kein Hinweis auf ein Token-Limit. |
| Sicherheitsfilter | entfällt | kein Treffer | Keine Blockade, keine leere Antwort — trotz Gesichts- und Ganzkörperfotos. |
| Diagnose-Vokabular (`tool/diagnose_stichprobe.dart`) | sauber | sauber | 3 von 3 ohne Befund. Der Prompt hält, was `analyse_prompt.ts` verspricht. Nachschärfen nicht nötig. |
| `habits` pro Kapitel | immer 4 | 6 × 4, **1 × 3** | Der Prompt verlangt „4 bis 7 pro Kapitel" (`analyse_prompt.ts`). Einmal kamen nur 3. Kein Fehlerfall — die App zeigt einfach eine kürzere Liste —, aber der Beleg, dass Mengenangaben im Prompt Wünsche sind und keine Garantien. Nichts darf davon abhängen, dass genau *n* Einträge ankommen. |
| `plan.taeglicheHabits` | leer | leer (3 von 3) | **Totes Feld.** Siehe unten. |

### Auto-Auslöser für die Ganzkörperfotos

Ohne ihn ist das Ganzkörperfoto allein nicht zu machen: Man stellt das Handy
ab, tritt drei Meter zurück — und kommt an den Auslöser nicht mehr heran.

**Warum ML Kit Pose Detection und nicht die Gesichtserkennung:** Aus drei
Metern ist ein Gesicht wenige Pixel groß und wird unzuverlässig gefunden.
Entscheidend ist ohnehin etwas anderes — ob *Kopf und Füße* im Bild sind. Genau
das liefert die Posenerkennung, und nichts anderes tut es.

`google_mlkit_pose_detection: ^0.16.1` teilt sich `google_mlkit_commons ^0.13.0`
mit der schon eingebundenen Gesichtserkennung. Hätten die beiden verschiedene
Fassungen gebraucht, wäre das ein Grund gewesen, es anders zu lösen.

**Die Ablauflogik liegt außerhalb der Kamera** (`auto_ausloeser.dart`,
`live_koerper_guide.dart`) und bekommt die Uhrzeit von außen hereingereicht.
Das ist keine Stilfrage: Ein Auto-Auslöser, der zur falschen Zeit schießt,
fällt am Gerät erst auf, wenn man drei Meter entfernt steht und nichts sieht.
So läuft der gesamte Ablauf in gewöhnlichen Tests, in denen die Zeit gesetzt
wird.

Vier Entscheidungen, die im Code nicht selbsterklärend sind:

1. **Nachsicht von 700 ms bei Haltungsverlust.** Die Posenerkennung flackert;
   ein einzelner Frame ohne sicheren Knöchel genügt. Ohne diese Toleranz
   bricht der Countdown ständig ab und kommt nie durch. Wer ruhig steht, soll
   nicht dafür bestraft werden, dass das Modell kurz zweifelt.
2. **Landmarks unter 50 % Güte zählen nicht.** ML Kit rät die Lage verdeckter
   Punkte, und ein geratener Knöchel ließe den Auslöser zu früh anspringen.
3. **Beide Knöchel müssen sicher sein.** Steht nur einer im Bild, ist die
   Person angeschnitten oder verdreht — in beiden Fällen taugt das Foto nicht.
4. **Vollständigkeit wird vor Größe geprüft.** Wer angeschnitten ist, soll
   „Ganz ins Bild — Kopf und Füße" lesen und nicht „Ein paar Schritte zurück".
   Das eine sagt, was zu tun ist, das andere lässt raten.

Der manuelle Auslöser bleibt jederzeit bedienbar — auch während des
Countdowns.

**Zum Ton:** Der Countdown ist aus drei Metern kaum abzulesen, deshalb ein
Signalton je Sekunde und ein höherer, längerer im Moment der Aufnahme. Dafür
kam `audioplayers` dazu.

Er läuft über den **Benachrichtigungs-Kanal**, nicht über Medien. Damit gilt
für ihn dieselbe Regel wie für eine Nachricht: Im Lautlos-Modus schweigt er,
ohne dass die App den Klingelzustand abfragen muss. Eine eigene Abfrage
bräuchte ein weiteres Plugin und wäre auf jedem Hersteller-Android anders
falsch. `mixWithOthers` ist gesetzt — drei kurze Töne rechtfertigen es nicht,
laufende Musik abzuwürgen.

Die Töne sind **generiert**, nicht aufgenommen: `tool/toene_erzeugen.dart`
schreibt zwei WAVs. Wie beim Markenauftritt stehen die Werte damit im Code und
nicht in einer Binärdatei, die niemand mehr ändern kann. Die Ein- und
Ausblendung über je fünf Millisekunden ist nicht Kosmetik — ein hart
abgeschnittener Sinus knackt hörbar, und dreimal hintereinander klingt das nach
kaputtem Lautsprecher.

**„Animationen reduzieren" wird respektiert:** Der Puls der Ziffer entfällt,
die Ziffer selbst bleibt vollständig. Die Bewegung ist Zierde, die Zahl ist die
Information.

### Vorschau vor dem Qualitätscheck, nicht danach

Nach dem Auslösen zeigt die Kamera das Bild mit „Passt" und „Nochmal". Erst
„Passt" schickt es durch den Check und in den Aufnahmen-Index.

**Die Reihenfolge ist der Punkt.** Naheliegend wäre gewesen, erst zu prüfen und
die Vorschau nur für bestandene Fotos zu zeigen. Genau das wäre falsch: Der
Check misst Helligkeit, Gesichtsgröße und Gesichtszahl — nicht, ob die Augen
zu sind, ob verwackelt wurde oder ob der Ausschnitt taugt. Das sieht ein Mensch
in einer halben Sekunde und keine Prüfung zuverlässig. Die Vorschau ist das
menschliche Urteil, der Check das maschinelle; das menschliche kommt zuerst.

Bei Ganzkörperfotos aus drei Metern Abstand ist es ohnehin der einzige Moment,
in dem sich das Ergebnis überhaupt beurteilen lässt.

Verworfene Aufnahmen werden gelöscht. Ohne das sammelt jeder Versuch ein
Vollbild-JPEG im Cache an — bei einem Auto-Auslöser, der auch mal danebentrifft,
summiert sich das schnell.

Der Galerie-Import bekommt **keine** Vorschau: Dort hat man das Bild im
Auswahldialog bereits gesehen.

### Kein Schärfe-Check

Naheliegende Ergänzung zu den Live-Hinweisen, bewusst nicht gebaut.

Die App hat **nie** auf Schärfe geprüft — die sechs Problemtexte sind kein
Gesicht, mehrere Gesichter, zu klein, zu dunkel, ungültige Datei,
fehlgeschlagen. Ein Unschärfemaß (etwa Laplace-Varianz) wäre neu zu bauen, und
es ist heikler als es klingt: Der Schwellwert hängt an Motiv, Auflösung und
Rauschen. Zu streng lehnt er brauchbare Fotos ab, zu lax fängt er nichts.
Falsche Ablehnungen sind hier der teurere Fehler — sie blockieren jemanden vor
einer Analyse, die er bezahlen will.

**Verwackelte Fotos fängt stattdessen die Vorschau ab:** Der Nutzer sieht das
Bild und tippt „Nochmal". Ein Mensch erkennt Unschärfe sofort und ohne
Schwellwert-Diskussion.

Nachrüstbar, falls sich Unschärfe im Testbetrieb als reales Problem zeigt —
dann mit Messwerten aus echten Fotos statt mit geratenen Grenzen. Der Ort wäre
`ImageQualityService.pruefeUndVerarbeite`, direkt neben der Helligkeitsprüfung.

### Live-Hinweise nur für vorhandene Prüfungen

Der Sucher meldete bisher nur die Position (kein Gesicht, zu weit weg, zu nah,
nicht mittig). Dazu kommt jetzt **„Mehr Licht nötig"** — die einzige weitere
Ablehnung des finalen Checks, die sich vorher sehen lässt.

Beide messen dasselbe: mittlere Luminanz auf 0–255. Der Check rechnet sie aus
dem dekodierten JPEG, die Vorschau aus der Y-Ebene des Kamerabildes — das *ist*
der Luminanzkanal, die Werte sind direkt vergleichbar. Auf iOS (BGRA) wird sie
aus den Farbkanälen gewichtet.

Zwei Feinheiten:

1. **Der Live-Schwellwert liegt zehn Punkte über dem Ablehnungswert.** Wer
   knapp über der Grenze fotografiert, kommt durch, steht aber am Rand. Der
   Hinweis kommt früher, damit man Licht nachlegen kann, statt ein Foto zu
   machen, das anschließend verworfen wird.
2. **Dunkelheit geht vor „kein Gesicht".** Bei zu wenig Licht findet ML Kit
   oft gar nichts; „niemand im Bild" wäre dann irreführend, das Licht ist die
   Ursache.

Gemessen wird nur jedes 16. Pixel. Ein Mittelwert braucht keine
Vollständigkeit, und vier Frames pro Sekunde in voller Auflösung wären auf
schwachen Geräten spürbar.

### Miniaturen-Leiste im Aufnahme-Flow

Über dem Inhalt liegen jetzt zwei Anzeigen, und das ist Absicht: Der dünne
Balken zählt **Schritte** (auch Lichtcheck und Formulare), die Miniaturen
zeigen **Inhalt** — was tatsächlich schon im Kasten ist. Bei bis zu zehn
Aufnahmen fällt ein misslungenes Foto sonst erst am Ende auf.

Ein Antippen springt zu dem Schritt; neu aufgenommen wird dort mit dem
vorhandenen „Neu aufnehmen". Ein zweiter Weg zur selben Sache wäre eine
Fehlerquelle mehr.

Die Miniaturen laden mit `cacheWidth: 140`. Zehn Vollbilder à 1024 px im
Speicher wären auf schwachen Geräten der schnellste Weg in den Absturz.

### Ganzkörper-Silhouette statt Kasten

Der Umriss für die Ganzkörperfotos war ein Oval plus abgerundetes Rechteck.
Ein Kasten sagt „irgendwo hier rein", eine Silhouette sagt „so weit weg und so
ausgerichtet" — und genau darum geht es, wenn jemand das Handy aufstellt und
mehrere Meter zurücktritt.

Frontal und seitlich teilten sich außerdem **denselben** Overlaytyp. Das
seitliche Foto zeigte also eine frontale Figur; wer sich danach ausrichtete,
stand falsch. Jetzt gibt es `ganzkoerperFrontal` und `ganzkoerperSeitlich`.

Drei Dinge, die beim Zeichnen nicht offensichtlich waren und in dieser
Reihenfolge auffielen:

1. **Arme gehören nicht in die Rumpfkontur.** Im ersten Entwurf lief der
   Umriss von der Schulter am Arm hinunter, um die Hand und innen wieder
   hinauf. Die Glättung zog Schulter und Arm daraufhin zu einem Ballon
   zusammen, die Taille verschwand darin, und die Arminnenseiten schwebten als
   Tropfen im Körper. Arme sind jetzt eigene Konturen.
2. **Der Abstand zwischen Arm und Brustkorb ist Absicht.** Liegen beide
   Konturen zu dicht beieinander, kreuzen sie sich an der Schulter und aus der
   Figur wird ein Knoten.
3. **Ein Mensch im Profil ist etwa ein Sechstel so tief wie hoch.** Der erste
   Entwurf war deutlich schmaler und las sich als Strich. Im Profil fehlt
   bewusst der Arm: Er läge genau über der Rumpfkontur — als einzelne Linie
   sieht er aus wie ein Strichfehler, als Kontur verdeckt er die Rückenlinie.
   Und die ist der Grund, warum dieses zweite Foto überhaupt verlangt wird.

**Zur Glättung:** Die Kontur entsteht als quadratische Beziers *durch die
Mittelpunkte* zwischen den Stützpunkten — die Stützpunkte selbst sind
Kontrollpunkte. Das rundet Ecken zuverlässig, erreicht aber einzelne Spitzen
nie. Die Zehenspitze steht deshalb **zweimal** in der Punktliste: Bei zwei
identischen Punkten fällt der Anker auf den Punkt, und die Spitze kommt
heraus. Ohne diesen Kniff wird aus dem Fuß ein Haken.

> **Werkzeug für die Sichtprüfung:** Ob eine Kontur wie ein Mensch aussieht,
> sagt kein Test. Zum Nachsehen rendert man das Overlay in einem Widget-Test
> über `RepaintBoundary.toImage()` in eine PNG.
>
> **`toImage()` muss dabei in `tester.runAsync(...)` stehen.** Sonst hängt der
> Test rund neun Minuten und endet mit „did not complete": Die Rasterung
> braucht den echten Event-Loop, und in der Fake-Async-Zone des Widget-Tests
> wird ihr Future nie fertig. Mit `runAsync` dauert derselbe Lauf eine
> Sekunde.

### Hautton ohne eigenes Foto

Die Nahaufnahme des Moduls „Haut & Farbtyp" ist entfallen. Unterton und
Farbpalette liest das Modell aus dem **Frontalfoto der Basis** mit.

Elf Aufnahmen sind viel verlangt, und die Hautton-Nahaufnahme zeigte
dasselbe Gesicht im selben Licht wie das Frontalfoto — nur näher. Ein Foto
weniger senkt die Abbruchquote im Flow und spart Tokens pro Analyse.

Drei Stellen hängen daran:

1. **Der Prompt** (`functions/src/analyse_prompt.ts`) sagt für dieses Kapitel
   jetzt ausdrücklich, dass es keine eigene Aufnahme gibt und der Unterton aus
   dem Frontalfoto kommt — mit der Anweisung, bei zu wenig Licht oder
   Auflösung offen zu sagen, dass das Hautbild nicht beurteilbar ist, statt zu
   raten. Ohne diesen Zusatz erfindet ein Modell die fehlende Nahaufnahme.
2. **Der Lichthinweis** wandert nicht komplett mit. Die Licht-Checkliste
   (`licht_checkliste.dart`) nennt Tageslicht und „kein Filter" bereits
   wortgleich und läuft ohnehin vor dem ersten Foto. Am Frontalfoto steht
   deshalb nur die *Verknüpfung* — dass dieses Foto nun auch die Hautanalyse
   trägt. Denselben Text zweimal zu zeigen liest sich wie eine neue
   Anforderung und wird überlesen.
3. **Die Hinweisseite des Moduls bleibt**, dreht aber ihren Zweck um. Sie
   steht nach den Basis-Fotos (die Flow-Reihenfolge folgt der Deklaration in
   `AnalyseModul`), Ratschläge zur Aufnahme kämen dort zu spät. Sie erklärt
   jetzt, dass kein eigenes Foto nötig ist, und bietet den Rückweg an, falls
   das Frontalfoto zu dunkel geriet. Ohne sie käme ein gewähltes Modul im Flow
   gar nicht vor — und das sieht aus, als hätte die Auswahl nicht gegriffen.

**Alte Clients brechen hart.** `leseAnalyse` (`functions/src/eingang.ts`)
lehnt unbekannte Aufnahmetypen mit `fotosFehlen` ab, statt sie zu ignorieren.
Eine App-Version, die noch `hautNahaufnahme` schickt, bekommt also eine
Fehlermeldung und keine Analyse. Das ist vertretbar, **solange die App nicht
veröffentlicht ist** — die Allowlist ist die richtige Sicherheitshaltung. Ab
dem ersten Store-Release wäre derselbe Schritt ein Breaking Change und
bräuchte eine Übergangsfrist, in der der alte Name noch angenommen und
verworfen wird.

### Der 45°-Winkel bleibt

Beim Ausdünnen der Aufnahmen naheliegend mitzustreichen — bewusst nicht
getan. Frontal und Profil zeigen Kieferlinie und Wangenknochen jeweils nur in
der Projektion, in der sie am wenigsten aussagen: frontal verschwindet die
Tiefe, im Profil die Breite. Der halbgedrehte Kopf ist die einzige Ansicht,
in der beides zugleich sichtbar ist — und Kieferlinie und Wangenknochen sind
genau das, worauf das Basis-Kapitel seine Frisur- und Bartempfehlungen
stützt. Die Nahaufnahme war redundant, dieser Winkel ist es nicht.

### Kontingent-Hinweis vor der Aufnahme

Aufgefallen beim Rate-Limit-Test (`SETUP.md` 6.4): Wer das Tageskontingent
aufgebraucht hat, merkt es erst **nach** dem kompletten Fotoweg. Elf Aufnahmen,
Wartezeit, dann „Kontingent erschöpft". Die Sperre ist richtig — der Zeitpunkt
war es nicht.

Der Hinweis steht jetzt auf der Modul-Auswahl, also vor der Kamera
(`lib/features/modules/ui/module_selection_screen.dart`). Bei erschöpftem
Kontingent ist zusätzlich die Weiter-Schaltfläche gesperrt.

Am Gerät bestätigt (24.08.2026, SM A525F, kurz vor Mitternacht mit
aufgebrauchtem Tageskontingent): Die Karte „Heute keine Analyse mehr frei"
stand auf „Analyse zusammenstellen", der Weiter-Knopf war ausgegraut. Die
Sperre greift also vor dem Fotoweg, nicht danach.

**Warum das ohne neue Cloud Function geht:** Die Security Rules erlauben dem
Client das *Lesen* von `users/{uid}/kontingent/{art}` und verbieten jedes
Schreiben — der Kommentar in `firestore.rules` nennt genau diesen Zweck. Der
Stand war also von Anfang an vorgesehen, er wurde nur nie angezeigt.

Drei Entscheidungen dabei, die zusammengehören:

1. **Der Server bleibt maßgeblich.** `KontingentStand` ist ein Hinweis. Die
   Sperre sitzt weiterhin in `functions/src/limit.ts` und wird vor jedem
   Gemini-Aufruf ausgewertet. Ein Client, der lügt, gewinnt nichts.
2. **Unbekannt ist nicht erschöpft.** Ohne Anmeldung, im Demo-Modus, offline
   oder bei einem Lesefehler liefert der Provider `null` — dann erscheint kein
   Hinweis und nichts wird gesperrt. Der umgekehrte Fehler wäre der teurere:
   jemanden aussperren, der noch Kontingent hat.
3. **Die Grenzen stehen doppelt** (`proTag = 3`, `proMonat = 30`), einmal hier
   und einmal in `limit.ts`. Das Zählerdokument enthält die Grenze nicht, und
   eine eigene Function für zwei Zahlen wäre teurer als dieser Absatz. Laufen
   sie auseinander, stimmt der *Hinweis* nicht mehr — die *Sperre* schon.

Die Normalisierung auf „heute" spiegelt `stand()` serverseitig: Ein Zähler,
dessen Tages- bzw. Monatsschlüssel nicht mehr der aktuelle ist, zählt als 0.
Ohne diese Regel würde die App nach drei Analysen dauerhaft sperren, weil der
Server den Zähler nicht zurücksetzt, sondern den Schlüssel vergleicht.
`test/kontingent_test.dart` hält genau das fest.

**Bekannte Ungenauigkeit:** Der Client bildet den Tagesschlüssel aus der
lokalen Gerätezeit, der Server rechnet in `Europe/Berlin`. Auf einem Gerät in
einer anderen Zeitzone kann der Hinweis um Mitternacht herum um einen Tag
danebenliegen.

Das `timezone`-Paket ist zwar ohnehin eingebunden — für die
Check-in-Erinnerungen —, benutzt dort aber ausschließlich `tz.UTC`, und
`initializeTimeZones()` wird nirgends aufgerufen. Die Zeitzonendatenbank ist
also nicht geladen. Für `Europe/Berlin` müsste sie beim Start in den Speicher:
viel Aufwand für einen Hinweis, über den ohnehin der Server entscheidet.

---

### Das tote Feld `plan.taeglicheHabits`

Aufgefallen beim Vergleich, und es ist keine Mock-Live-Abweichung, sondern
etwas Grundsätzlicheres: Das Feld wird

- vom Prompt **nie angefordert** (`functions/src/analyse_prompt.ts` kennt es
  nicht),
- vom Mock **nie geliefert** (`_plan` hat nur `sofort`, `dreissigTage`,
  `langfristig`),
- von der Oberfläche **nie gelesen** — kein einziger Treffer außerhalb von
  `lib/features/analysis/models/analysis_result.dart`.

Trotzdem wird es geparst, gespeichert, synchronisiert und beim Zusammenführen
zweier Ergebnisse gemergt. Es ist also Code, der aussieht, als trüge er etwas,
und der in Wahrheit immer `[]` durchreicht.

Nicht zu verwechseln mit `kapitel[].habits` — das ist das echte Feld: Der
Prompt fordert es an, die Checkliste (`plan/ui/widgets/checkliste_karte.dart`)
und der Check-in (`checkin/logic/`) bauen darauf auf. Die tägliche Aufgabenliste
funktioniert vollständig, sie hängt nur an einer anderen Stelle als der Name
`taeglicheHabits` vermuten lässt.

**Entscheidung:** Das Feld gehört entfernt statt gefüllt. Eine zweite Quelle
für Habits neben `kapitel[].habits` würde die Frage aufwerfen, welche gilt —
und die Check-in-Logik ordnet Habits ihrem Modul zu
(`checkin_service.dart:153`), was bei modul-losen Plan-Habits nicht ginge. Der
Ausbau ist nicht dringend, aber er sollte vor der Einreichung passieren,
solange das Datenformat noch keine veröffentlichte Version hat.
