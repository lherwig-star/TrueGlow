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
