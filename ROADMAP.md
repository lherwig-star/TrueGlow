# ROADMAP — von TrueGlow (Prototyp) zur Store-Veröffentlichung

**Stand:** 24.08.2026 · **App:** TrueGlow · **Paket:** `com.trueglow.app` · **Version:** 1.0.0+1
**Umfang:** 77 Dart-Dateien, ~13.750 Zeilen, 12 Screens, 148 Tests (Bestandsaufnahme)

> Die App hieß bis Phase 2 „GlowUp" und lief unter `com.glowup.glowup`. Die
> Bestandsaufnahme unten beschreibt diesen Stand; die Umbenennung ist in
> Abschnitt 2.0 festgehalten.

---

## Kurzfassung

Die App ist funktional erstaunlich weit: sauber geschnittene Feature-Ordner, konsequente
Trennung von Logik und UI, ein durchdachtes Fehlerkonzept, 148 grüne Tests und zwei
Design-Schemata mit geprüften Kontrasten. **Veröffentlichungsreif ist sie nicht** — und
zwar nicht wegen der Features, sondern wegen des Fundaments: Es gibt kein Backend, keine
Accounts, keine Signierung, keine Rechtstexte und keine Kaufabwicklung. Alles liegt
ausschließlich auf dem Gerät.

Die gute Nachricht vorweg: **Es ist noch nichts passiert, was sich nicht mehr heilen
ließe.** Der Analyse-Modus läuft auf Mock (`useMockData = true`), in `.env` steht ein
leerer Wert — es wurde also noch nie ein echter API-Key in ein Build gepackt. Genau
deshalb ist jetzt der billigste Moment, den Key gar nicht erst in den Client zu lassen.

**Grobe Einschätzung bis Produktion:** 6–10 Wochen nebenher, davon ~2 Wochen reine
Wartezeit für den von Google vorgeschriebenen geschlossenen Test.

---

## Legende

| Zeichen | Bedeutung |
|---|---|
| 🔴 **BLOCKER** | Ohne das gibt es keine Veröffentlichung — Google lehnt ab oder es ist rechtlich/finanziell untragbar |
| 🟡 | Wichtig, aber kein Ablehnungsgrund |
| 🟢 | Verbesserung, kann nach dem Launch kommen |

**Aufwand:** **S** = unter einem Tag · **M** = 2–5 Tage · **L** = 1–3 Wochen
(gerechnet für eine Person nebenher, inklusive Testen)

---

# Teil 1 — Bestandsaufnahme

## 1.1 Ist vs. Soll auf einen Blick

| # | Thema | Ist-Zustand | Soll für den Store | Lücke |
|---|---|---|---|---|
| 1 | **Architektur** | Flutter/Dart, Riverpod + go_router + Hive. Reine Client-App, kein Backend | Client + schlankes Backend (Proxy, Auth, Kaufprüfung) | 🔴 Backend fehlt vollständig |
| 2 | **KI-Anbindung** | Direktaufruf `generativelanguage.googleapis.com` aus der App, Key aus `.env`, **`.env` wird als Asset mitgeliefert** | Kein Key im Client; Aufruf über eigenen Proxy mit Auth, Rate-Limit, Kostendeckel | 🔴 Key wäre im APK extrahierbar |
| 3 | **Datenspeicherung** | 4 Hive-Boxen lokal, Fotos in `<AppDocs>/glowup_fotos`. Kein Sync, kein Backup-Konzept | Cloud-Speicher pro Konto, Gerätewechsel überlebt | 🔴 Neuinstallation = Totalverlust |
| 4 | **Accounts** | Keine. Kein Login, keine Nutzer-ID | Mindestens Google Sign-In + Migration der lokalen Daten | 🔴 Ohne Konto keine Kaufzuordnung |
| 5 | **Monetarisierung** | Nicht vorhanden — kein Billing-Paket, keine Paywall, keine Entitlements | Play Billing, serverseitig geprüft, Paywall, Wiederherstellung | 🔴 Wenn Geld verdient werden soll |
| 6 | **Fehlerbehandlung** | Gut für den Normalfall: 7 benannte Fehlerfälle mit Tipp, Kamera-Fallback auf Galerie, Check-in auch ohne KI abschließbar | Zusätzlich Netz-Retry, globaler Error-Handler, Offline-Verhalten | 🟡 Solide Basis, Lücken bei Netz |
| 7 | **Rechtliches** | Einwilligungsseite im Onboarding, Medizin- und Foto-Disclaimer, „Alle Daten löschen" funktioniert. Impressum/Datenschutz sind Platzhalter (Snackbar „Rechtstext folgt.") | Echte Texte als Webseite + in-App, gestufte Einwilligung, dokumentierter Widerruf | 🔴 Texte fehlen, Play verlangt DSE-URL |
| 8 | **Build & Signierung** | `release` signiert mit **Debug-Keys**, kein Minify, **Standard-Flutter-Icon**, Version ohne Prozess | Eigener Keystore, App Bundle, Minify, eigenes Icon, Versionsschema | 🔴 Play nimmt debug-signierte Builds nicht an |
| 9 | **Qualität** | 148 Tests (Unit + Widget), kein Crash-Reporting, kein Analytics, real getestet auf **einem** Gerät | Crashlytics, Gerätematrix, Integrationstest auf Gerät | 🟡 Testabdeckung gut, Feldwissen fehlt |

## 1.2 Die Details

### 1 · Architektur

Flutter (SDK 3.47.1, Dart ^3.13.1), Zustand über Riverpod-`StateNotifier`, Navigation über
`go_router`, Persistenz über Hive. Zwölf Feature-Ordner (`analysis`, `capture`, `checkin`,
`direction`, `history`, `home`, `modules`, `onboarding`, `plan`, `result`, `settings`,
`streak`), jeweils in `logic` / `models` / `ui` getrennt. Farben und Abstände liegen
zentral in `core/theme`, Texte in `core/l10n/app_strings.dart`.

**Bewertung:** Der Schnitt ist gut und trägt den Umbau. Besonders hilfreich für Phase 1:
`AnalysisService` und `CheckinService` sind bereits Interfaces mit je einer Mock- und einer
Gemini-Implementierung. Der Wechsel auf einen Proxy ist deshalb *eine neue Implementierung*
und kein Eingriff in die UI.

**Kein Backend.** Es gibt keine Server-Komponente, keine eigene Domain, keinen
Cloud-Dienst — die App spricht ausschließlich mit Google Gemini.

### 2 · KI-Anbindung 🔴

Der Aufruf steckt in `lib/features/analysis/logic/gemini_client.dart`:
`POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`,
der Key geht als `x-goog-api-key`-Header raus (immerhin nicht als Query-Parameter). Gelesen
wird er über `flutter_dotenv` aus `.env`.

**Das Risiko im Klartext:** `.env` steht in `pubspec.yaml` unter `assets:`. Ich habe im
Build-Output nachgesehen — die Datei liegt tatsächlich in
`build/app/intermediates/flutter/debug/flutter_assets/.env`. Ein APK ist ein ZIP-Archiv;
jeder, der es herunterlädt, kann die Datei in Sekunden auslesen. Ein so abgegriffener
Gemini-Key lässt sich beliebig oft auf deine Rechnung nutzen, bis du ihn sperrst.

**Aktueller Stand — die Entwarnung:** In `.env` steht momentan ein *leerer* Wert (Datei ist
identisch mit `.env.example`), und `AnalysisConfig.useMockData` ist `true`. Es ist also
noch nie ein echter Key ausgeliefert worden, und es gibt bisher keinen einzigen echten
API-Aufruf. Zwei Konsequenzen: Der Schaden ist noch nicht eingetreten — und der echte
Antwortpfad (Parsing echter Gemini-Antworten, Timeouts, Sicherheitsfilter) wurde noch nie
gegen die Live-API erprobt.

### 3 · Datenspeicherung 🔴

| Was | Wo | Bei Neuinstallation |
|---|---|---|
| Analysen/Reports | Hive `analysen`, JSON-String pro ID | weg |
| Onboarding, Module, Aufnahmen-Index, Richtung | Hive `einstellungen` | weg |
| Abgehakte Habits, Streak, Abzeichen | Hive `fortschritt` | weg |
| Check-in-Zeitplan, Entwurf, Historie | Hive `checkins` | weg |
| Fotos (Analyse + Fortschritt) | `<AppDocs>/glowup_fotos`, JPEG max 1024 px, Qualität 80 | weg |

Kein Sync, kein Export, kein Konto. Gerätewechsel oder Neuinstallation kosten alles —
inklusive Streak und Check-in-Historie, also genau der Daten, die emotional am meisten
wiegen. Das ist zugleich ein Support-Risiko nach einem Kauf („ich habe bezahlt und alles
ist weg").

**Nebenbefund:** `android:allowBackup` ist nicht gesetzt, gilt also als `true`. Damit können
Hive-Dateien **und Gesichtsfotos** in Googles automatisches Cloud-Backup wandern, ohne dass
die App das je erwähnt. Das gehört entweder bewusst abgeschaltet oder in der
Datenschutzerklärung sauber beschrieben.

### 4 · Accounts 🔴

Nicht vorhanden. Daran hängen: Datenmigration (Phase 1), Zuordnung von Käufen (Phase 3),
Rate-Limits pro Nutzer (sonst nicht durchsetzbar) und die von Google geforderte
Konto-Löschmöglichkeit inklusive Weblink, sobald es Konten gibt.

### 5 · Monetarisierung 🔴

Weder `in_app_purchase` noch ein Billing-SDK in `pubspec.yaml`, keine Paywall, keine
Berechtigungsprüfung. Immerhin: Die Modulstruktur (`AnalyseModul` mit Basis + vier
Zusatzmodulen) und der Weg „Analyse erweitern" sind bereits die natürliche Bruchkante für
Einmalkäufe — das Produktmodell lässt sich ohne Umbau daran aufhängen.

### 6 · Fehlerbehandlung 🟡

Was schon gut ist:

- `AnalysisFehler` mit sieben Fällen, jeder mit Titel *und* konkretem Tipp (kein Internet, Timeout, Kontingent, unlesbare Antwort, kein Key, Fotos fehlen, API-Fehler)
- Timeout 60 s pro Aufruf, ein automatischer Nachfass-Versuch bei ungültigem JSON
- Kamera ohne Berechtigung → eigener Hinweisscreen mit Link in die App-Einstellungen und Galerie als Ausweg; Kamera nicht verfügbar → ebenfalls abgefangen
- Foto-Qualitätscheck mit sechs verständlichen Problemtexten statt einer Fehlermeldung
- Check-in lässt sich abschließen, auch wenn die KI-Auswertung scheitert

Was fehlt: kein Retry mit Backoff bei Netzfehlern (nur der JSON-Nachfass), kein
Offline-Modus und keine Warteschlange, kein globaler `FlutterError.onError` /
`PlatformDispatcher.onError`, keine Rückmeldung bei Schreibfehlern in Hive.

### 7 · Rechtliches im Code 🔴

Vorhanden: Pflichtseite im Onboarding mit Medizin-Disclaimer, Foto-Hinweis und
Zustimmungs-Checkbox (`zugestimmt` wird gespeichert); Disclaimer im Report und in den
Einstellungen; „Alle Daten löschen" räumt alle vier Boxen **und** den Fotoordner.

Fehlt: Datenschutzerklärung, AGB und Impressum als echte Texte — in den Einstellungen
erscheint aktuell nur die Snackbar „Rechtstext folgt.". Es gibt keine öffentliche URL (Play
verlangt eine). Die Einwilligung ist ein einzelnes Häkchen ohne Zeitstempel, ohne
Textversion und ohne Widerrufsweg. Für die Übermittlung von Gesichtsfotos an Google als
Auftragsverarbeiter (Drittlandtransfer) gibt es keine gesonderte Einwilligung — bei
biometrienahen Daten ist das der heikelste Punkt des ganzen Projekts.

### 8 · Build & Signierung 🔴

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")   // ← Play lehnt das ab
    }
}
```

Weiter: kein `minifyEnabled`/`shrinkResources`, keine ProGuard-Regeln (relevant für ML Kit
und Hive), **App-Icon ist das Standard-Flutter-Logo** (verifiziert), kein adaptives Icon,
Splash mit System-Standard (im Dark Mode inzwischen Deep Teal), `versionCode`/`versionName`
kommen aus `pubspec.yaml` ohne festgelegten Prozess.

Berechtigungen sind schlank und begründbar: `CAMERA`, `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED`. Was `image_picker`, `permission_handler` und `camera` über den
Manifest-Merger zusätzlich hineinziehen, ist noch nicht geprüft.

`minSdk = 26` (wegen ML Kit), `targetSdk` = Flutter-Standard — vor dem Upload explizit
setzen und gegen die dann geltende Play-Anforderung prüfen.

iOS: Bundle-ID und beide `NSUsageDescription`-Texte sind gepflegt, aber es wurde nie
gebaut, kein Signing-Team, kein Provisioning.

### 9 · Qualität 🟡

148 Tests in 11 Dateien: JSON-Parser, Speicher, Streak-Berechnung, Kamera-Hilfslogik,
Aufnahme-Flow, Farbkontraste, Richtung, Check-ins und ein durchgehender Widget-Test vom
Dashboard bis zum angepassten Plan. Das ist für einen Prototyp weit überdurchschnittlich.

Es fehlen: Crash-Reporting, Analytics, Integrationstests auf echter Hardware
(`integration_test`), CI. Real getestet wurde bislang nur auf einem Samsung-Gerät im
Hochformat — kleine Displays, Tablets, ältere Android-Versionen, große Systemschrift und
TalkBack sind ungeprüft.

### Ergänzender Befund: keine Versionsverwaltung 🔴

Im Projekt gibt es kein `.git`. Für den Store irrelevant, für alles Folgende nicht: Phase 1
bis 3 sind tiefe Eingriffe (Backend, Auth, Billing). Ohne Historie gibt es kein Zurück und
keine Möglichkeit, einen Fehlgriff zu isolieren. `.gitignore` ist vorbereitet und schließt
`.env` bereits aus.

---

# Teil 2 — Roadmap

## Phase 0 — Arbeitsfähigkeit herstellen

*Nicht in deiner Vorlage, aber Voraussetzung für alles Weitere.*

- [x] **Git-Repository anlegen**, ersten Commit setzen, `.gitignore` prüfen (`.env` ist bereits ausgeschlossen) — **S**
- [ ] Privates Remote-Repo (GitHub/GitLab) für Backup außerhalb des Rechners — **S** — *Klickweg in `SETUP.md`, Abschnitt 8 (nur von dir ausführbar)*
- [x] 🟢 CI-Workflow: `flutter analyze` + `flutter test` bei jedem Push — **S** — *`.github/workflows/ci.yml`*
- [x] `SETUP.md` für alle manuellen Schritte, `DECISIONS.md` für Entscheidungen außerhalb der Roadmap — **S**

**Begründung:** Die nächsten Phasen ändern Kernpfade der App. Ohne Historie ist jeder
Umbau unumkehrbar. **Abhängigkeiten:** keine.

---

## Phase 1 — Sicherheit & Fundament 🔴 BLOCKER

### 1.1 Backend-Entscheidung

- [ ] Firebase-Projekt anlegen (Region `europe-west3` wegen DSGVO) — **S** — *Klickweg in `SETUP.md`, Abschnitt 1 (nur von dir ausführbar)*
- [x] FlutterFire im Projekt verdrahtet: Abhängigkeiten, google-services-Plugin, `lib/firebase_options.dart` (Platzhalter), Firebase- und App-Check-Start in `main.dart` — **S**

**Empfehlung: Firebase.** Begründung passend zum Stack: Google Sign-In ist mit Firebase
Auth in Flutter der kürzeste Weg; Cloud Functions liefern den Proxy inklusive Secret
Manager; Firestore passt zum bestehenden JSON-Speicherformat (die Modelle haben alle schon
`toJson`/`fromJson`, die Umstellung von Hive ist fast mechanisch); Crashlytics aus Phase 4
und die Play-Kaufprüfung aus Phase 3 liegen im selben Ökosystem; App Check schützt den
Proxy davor, dass jemand ihn statt des Keys missbraucht.

*Alternative Supabase:* günstiger bei viel Traffic und mit echtem Postgres, aber Auth,
Push, Crashlytics und Kaufprüfung müssten aus verschiedenen Quellen zusammengesteckt
werden. Für eine Solo-App der falsche Tausch.

*Kürzester Weg, falls du den Proxy zunächst vermeiden willst:* Firebase AI Logic
(Gemini-Aufruf aus dem Client, aber ohne Key in der App, abgesichert über App Check). Das
löst das Key-Problem, **nicht** aber Rate-Limits, Kostendeckel und das Verstecken des
Prompts. Für Phase 3 brauchst du die Function ohnehin — deshalb empfehle ich, sie gleich zu
bauen.

### 1.2 Gemini hinter einen Proxy legen 🔴

- [x] Cloud Function `analysiere` + `checkinAuswerten`: nimmt Bilder und Prompt-Parameter, ruft Gemini mit dem Key aus dem Secret Manager auf, gibt das JSON zurück — **M** — *`functions/src/index.ts`; der Prompt ist mit auf den Server gewandert und damit aus dem APK verschwunden*
- [x] App Check erzwingen, Aufruf nur mit gültigem Auth-Token — **S** — *`enforceAppCheck: true`, `request.auth` geprüft; Erzwingen in der Konsole aktivieren: `SETUP.md` 4.4*
- [x] Rate-Limit pro Nutzer (Vorschlag: 3 Analysen/Tag, 30/Monat) — **S** — *`functions/src/limit.ts`, Zähler in `users/{uid}/kontingent`*
- [ ] Budget-Alarm im Google-Cloud-Projekt — **S** — *Klickweg in `SETUP.md`, Abschnitt 5.3 (nur von dir ausführbar)*
- [x] Client: neue `AnalysisService`- und `CheckinService`-Implementierung, die die Function ruft; `GeminiClient` und `flutter_dotenv` entfallen, `.env` aus `pubspec.yaml` streichen — **S**
- [ ] Echten Antwortpfad erstmals gegen die Live-API prüfen (`useMockData = false`) — **S** — *braucht Firebase-Projekt und Gemini-Key: `SETUP.md`, Abschnitt 6*

**Begründung:** Solange der Key im Client liegt, ist jede Veröffentlichung ein
unkalkulierbares finanzielles Risiko. Der Umbau ist klein, weil die Service-Interfaces
bereits stehen. **Abhängigkeiten:** 1.1.

### 1.3 Cloud-Datenmodell 🔴

- [x] Struktur festlegen, Vorschlag: `users/{uid}` mit Unterkollektionen `analysen`, `checkins`, `fortschritt/{yyyy-mm-tt}` und Dokumenten `profil`, `richtung`, `streak` — **M** — *`lib/core/cloud/cloud_modell.dart`, dazu `module`, `checkinPlan`, `verweise` und `migration`*
- [x] Security Rules: jeder Nutzer nur auf `users/{uid}` — **S** — *`firestore.rules`, Emulator-Test `functions/test/rules.test.ts` (braucht Java, siehe `SETUP.md` 9)*
- [x] **Entscheidung Fotos:** bleiben lokal — nur Ergebnisse wandern in die Cloud; fehlende Fotos zeigt die UI als Platzhalter statt als Fehler — **S**

**Empfehlung:** Fotos bleiben auf dem Gerät; in die Cloud gehen nur Ergebnisse, Plan,
Streak und Check-in-Historie. Fotos gehen dann ausschließlich transient durch die Function
zu Gemini und werden nirgends gespeichert. Das senkt den DSGVO-Aufwand erheblich, weil
keine biometrienahen Daten dauerhaft auf deinem Server liegen. Preis: Fortschrittsfotos und
der Vorher/Nachher-Vergleich überleben einen Gerätewechsel nicht — das ist verkraftbar und
ehrlich kommunizierbar.

### 1.4 Login

- [x] Firebase Auth mit Google Sign-In, dazu anonyme Anmeldung für „erst ausprobieren" — **M** — *`AuthRepository` mit `AuthAnbieter { google, apple, anonym }`; Apple ist bereits implementiert und wartet nur auf die Freischaltung in der Konsole (`SETUP.md` 7)*
- [x] Login-Screen im bestehenden Design, Abmelden in den Einstellungen — **S** — *Konto-Karte oben in den Einstellungen, Abmelde-Dialog erklärt die Folge*

**Abhängigkeiten:** 1.1.

### 1.5 Migration der lokalen Daten

- [x] Beim ersten Login: vorhandene Hive-Daten hochladen, idempotent (kein Doppelimport), mit Dialog „Deine bisherigen Daten übernehmen?" — **M** — *`HiveMigration`; Idempotenz über Marker `daten/migration` **und** feste Dokument-IDs*
- [x] Anonymes Konto beim Google-Login zusammenführen statt verwerfen — **S** — *„Mit Google verknüpfen" in den Einstellungen, `AuthRepository.verknuepfen`*

**Begründung:** Bestehende Testnutzer (und du selbst) verlieren sonst Streak und Historie.
**Abhängigkeiten:** 1.3, 1.4.

### 1.6 Sync-Strategie

- [x] Cloud als Quelle der Wahrheit, Hive als Offline-Cache; Schreibpfade über ein Repository bündeln — **L** — *`SyncStore` erweitert den `KeyValueStore`; kein Controller musste angefasst werden. Konfliktregel: letzter Schreiber gewinnt, Zeitstempel pro Dokument; Tagesfortschritt und Check-ins werden vereinigt statt ersetzt.*

**Begründung:** Ohne klare Richtung entstehen Konflikte zwischen Gerät und Server. Der
bestehende `KeyValueStore` ist ein guter Ansatzpunkt — die Abstraktion existiert schon.
**Abhängigkeiten:** 1.3.

---

## Phase 2 — Store-Pflichten 🔴 BLOCKER

### 2.0 Umbenennung auf „TrueGlow" 🔴

*Nicht in der ursprünglichen Vorlage — nachgezogen, weil die Anwendungs-ID nach
dem ersten Play-Upload unveränderlich ist.*

- [x] Anzeigename überall: Android `android:label`, iOS `CFBundleDisplayName`/`CFBundleName`, `app_strings.dart`, Onboarding, Login, Einstellungen — **S**
- [x] Anwendungs-ID von `com.glowup.glowup` auf `com.trueglow.app`: Gradle-Namespace, `applicationId`, MainActivity-Paketpfad, iOS-Bundle-ID — **S**
- [x] Dart-Paketname `glowup` → `trueglow`, Klassen `TrueGlowApp`/`TrueGlowNutzer` — **S**
- [ ] Firebase: neue App-Registrierung, `flutterfire configure`, SHA-Fingerprints, App Check, alte Registrierung entfernen — **S** — *Klickweg in `SETUP.md`, Abschnitt 2.0 (nur von dir ausführbar)*

**Begründung:** Nach dem ersten Upload in die Play Console ist die
Anwendungs-ID für immer festgelegt — ein späterer Wechsel bedeutet eine neue
App ohne Bewertungen, ohne Installationen und ohne Käufe.

### 2.1 Rechtstexte

- [ ] Datenschutzerklärung, AGB, Impressum erstellen (Anwalt oder spezialisierter Generator) und als öffentliche URLs hosten — **M**
- [ ] In den Einstellungen verlinken (ersetzt „Rechtstext folgt.") und im Onboarding — **S**
- [ ] Inhalte, die zwingend hineingehören: Gesichtsfotos und ihr Zweck, Übermittlung an Google (Gemini) mit Drittlandbezug, Speicherdauer, Löschweg, Crash-Reporting/Analytics aus Phase 4, Kontaktadresse — **S**

### 2.2 Einwilligung nachschärfen

- [ ] Getrennte Häkchen: (a) Nutzungsbedingungen, (b) Verarbeitung von Gesichtsfotos durch den KI-Dienst — **M**
- [ ] Zeitstempel und Textversion der Einwilligung speichern — **S**
- [ ] Widerruf in den Einstellungen (inklusive Folge: keine neuen Analysen möglich) — **S**

**Begründung:** Gesichtsfotos sind biometrienah. Eine pauschale Checkbox ohne Nachweis, wem
wann wozu zugestimmt wurde, hält einer Prüfung nicht stand.

### 2.3 Löschfunktion erweitern

- [ ] Lokales Löschen (existiert) um Cloud-Daten und Konto-Löschung ergänzen — **M**
- [ ] Web-Löschpfad bereitstellen — Google verlangt das für Apps mit Konten — **S**

**Abhängigkeiten:** 1.3, 1.4.

### 2.4 Medizin-Disclaimer

- [ ] In der Store-Beschreibung wiederholen (in der App vorhanden) — **S**
- [ ] Prüfen, ob Formulierungen im Report versehentlich wie eine Diagnose klingen; der Prompt verbietet es bereits, Stichproben mit echten Antworten fahren — **S**

### 2.5 Play-Konsole vorbereiten

- [ ] Data-Safety-Formular: Fotos, Kennungen, App-Aktivität; Verschlüsselung bei Übertragung, Löschmöglichkeit — muss zur tatsächlichen Implementierung passen — **S**
- [ ] Alterseinstufung (IARC-Fragebogen), Zielgruppe, Kategorie, Kontaktdaten — **S**
- [ ] Store-Eintrag anlegen, DSE-URL hinterlegen — **S**

### 2.6 Release-Build 🔴

- [ ] Keystore erzeugen, `key.properties` **außerhalb** des Repos, Signing-Config im Gradle — **S**
- [ ] App Bundle (`flutter build appbundle --release`) statt APK — **S**
- [ ] `minifyEnabled` + `shrinkResources` aktivieren, ProGuard-Regeln für ML Kit und Hive prüfen, danach vollständigen Durchlauf auf dem Gerät testen — **M**
- [ ] `targetSdk` explizit setzen und auf die aktuelle Play-Anforderung heben — **S**
- [ ] Merged Manifest prüfen: welche Berechtigungen ziehen die Plugins mit? Unnötige per `tools:node="remove"` entfernen — **S**
- [ ] `android:allowBackup` bewusst setzen (Empfehlung: `false` oder Backup-Regel ohne Fotos) — **S**

### 2.7 Markenauftritt 🔴

- [ ] Eigenes App-Icon statt des Flutter-Logos, inklusive adaptivem Icon (Vorder-/Hintergrund) und 512×512 für den Store — **S**
- [ ] Splash in den App-Farben für beide Schemata — **S**

**Begründung:** Das Standard-Flutter-Icon ist das deutlichste Signal „unfertig" und
zieht bei der Prüfung Aufmerksamkeit auf sich.

### 2.8 Entwicklerkonto & Testpflicht 🔴 (Terminrisiko)

- [ ] Google-Play-Entwicklerkonto anlegen, 25 $ Gebühr, Identitätsprüfung durchlaufen — **S**
- [ ] Falls Privatkonto: **geschlossener Test mit mindestens 12 Testern über 14 zusammenhängende Tage** einplanen, bevor Produktion freigeschaltet wird — **S** Aufwand, **2+ Wochen** Wartezeit

**Begründung:** Diese Uhr läuft unabhängig vom Code. Wer sie erst am Ende startet,
verliert zwei Wochen. Firmenkonten sind davon ausgenommen — siehe offene Fragen.

---

## Phase 3 — Monetarisierung

**Abhängigkeiten:** komplette Phase 1 (ohne Konto keine Kaufzuordnung).

### 3.1 Produktmodell festlegen

- [ ] Preise und Produkte definieren — *siehe offene Fragen* — **S**

Naheliegend, weil die Codestruktur es hergibt: Basis-Analyse kostenlos oder als
Einstiegskauf, die vier Zusatzmodule als Einmalkäufe, Check-ins und Plan-Anpassungen im Abo.

### 3.2 Billing integrieren

- [ ] `in_app_purchase` (oder RevenueCat, wenn iOS sicher kommt) einbinden, Produkte in der Konsole anlegen — **M**
- [ ] Kaufwiederherstellung, Abo-Ablauf, Kündigung, Grace-Period und Erstattung behandeln — **M**

### 3.3 Käufe serverseitig prüfen 🔴 (wenn es Käufe gibt)

- [ ] Play Developer API in der Cloud Function; Entitlements in Firestore, nicht im Client — **M**
- [ ] Die Analyse-Function prüft das Entitlement, bevor sie Gemini ruft — **S**

**Begründung:** Eine rein clientseitige Freischaltung ist mit Standardwerkzeugen in
Minuten ausgehebelt — und jeder unberechtigte Aufruf kostet dich echtes Geld.

### 3.4 Paywall

- [ ] Paywall-Screens im bestehenden Kartendesign, an der Modulauswahl aufgehängt — **M**
- [ ] Ehrliche Darstellung: was ist enthalten, was kostet extra, keine Dark Patterns (Play prüft das) — **S**

---

## Phase 4 — Robustheit & Qualität

### 4.1 Netz und Offline

- [ ] Retry mit exponentiellem Backoff für KI-Aufrufe (3 Versuche), abbrechbar — **M**
- [ ] Globaler Offline-Hinweis; Checklisten und Plan bleiben offline nutzbar (sind sie heute schon) — **S**
- [ ] Angefangene Analyse nach App-Neustart sauber fortsetzen oder verwerfen — **M**

### 4.2 Zustände systematisch

- [ ] Alle 12 Screens auf Lade-, Fehler- und Leerzustand durchgehen — **M**

### 4.3 Crash-Reporting & Analytics

- [ ] Crashlytics einbinden, `FlutterError.onError` und `PlatformDispatcher.onError` verdrahten — **S**
- [ ] Minimale Analytics (Funnel: Onboarding → Analyse → Plan → Check-in), datensparsam, opt-in, in der DSE genannt — **M**

**Begründung:** Ohne Crash-Reporting erfährst du von Abstürzen erst über
Ein-Sterne-Bewertungen. **Abhängigkeiten:** 2.1 (muss in der DSE stehen).

### 4.4 Gerätematrix

- [ ] Klein (5", 720×1280), groß (6.7"), Tablet; Android 8 (minSdk 26) bis aktuell — **M**
- [ ] Systemschrift 130 %, Dark/Light, „Animationen reduzieren", TalkBack-Grundcheck — **S**
- [ ] Kamera-Screens auf schwacher Hardware: ML-Kit-Takt, Speicher bei Ganzkörperfotos, Erwärmung — **M**

**Begründung:** Bisher ist genau ein Gerät geprüft. Die Kamera mit Live-Gesichtserkennung
ist der wahrscheinlichste Ort für Abstürze auf schwächeren Telefonen.

### 4.5 Integrationstest

- [ ] `integration_test` für den Hauptpfad (Onboarding → Foto → Analyse → Plan → Check-in) auf echter Hardware — **M**

---

## Phase 5 — Launch

### 5.1 Store-Listing

- [ ] Kurz- und Langbeschreibung inklusive Medizin-Disclaimer — **S**
- [ ] 4–8 Screenshots (Dashboard, Modulauswahl, „Deine Richtung", Report, Plan, Check-in) — **M**
- [ ] Feature-Grafik 1024×500, Icon 512×512 — **S**
- [ ] Keine Versprechen, die die App nicht hält („garantiert bessere Haut") — Play prüft Gesundheitsaussagen streng — **S**

### 5.2 Testkaskade

- [ ] Interner Test (sofort verfügbar) → geschlossener Test (12 Tester, 14 Tage) → Produktion — **S** + Wartezeit
- [ ] Feedbackschleife der Tester einplanen — **M**

### 5.3 Kosten & Rate-Limits — siehe eigener Abschnitt unten

---

# Kostenkalkulation

**Größenordnung pro Analyse** (Gemini 2.5 Flash, Bilder mit max. 1024 px):

| Posten | Menge |
|---|---|
| Basis-Analyse: 4 Bilder à ~1.300 Tokens | ~5.200 Input-Tokens |
| System-Prompt + Kontext | ~1.500 Input-Tokens |
| Antwort (JSON-Report) | ~2.500–4.000 Output-Tokens |
| **Summe Basis** | **~7.000 In / ~3.000 Out** |
| Vollausbau (alle Module, 9–10 Bilder) | ~14.000 In / ~6.000 Out |
| Check-in mit Fotovergleich (2 Bilder) | ~4.000 In / ~800 Out |

Mit den mir bekannten Flash-Preisen landet eine Basis-Analyse bei **rund einem Cent**, der
Vollausbau bei zwei bis drei Cent. **Die aktuellen Preise musst du vor dem Launch selbst
prüfen** — sie ändern sich, und mein Wissensstand ist nicht tagesaktuell.

**Die eigentliche Erkenntnis:** Der Stückpreis ist bei jedem realistischen Verkaufspreis
unkritisch. Das Risiko liegt woanders:

1. **Missbrauch eines offenen Endpunkts** skaliert unbegrenzt — deshalb App Check und Auth
2. **Retry-Schleifen** vervielfachen Kosten unbemerkt — deshalb Versuche hart begrenzen
3. **Kein Kostendeckel** — deshalb Budget-Alarm im Cloud-Projekt und harte Rate-Limits

Vorschlag: 3 Analysen pro Tag und 30 pro Monat je Konto, serverseitig durchgesetzt. Das ist
großzügig für echte Nutzung und deckelt den Schaden.

---

# Checkliste für den Einreichungstag

- [ ] Version in `pubspec.yaml` erhöht (`versionCode` muss steigen)
- [ ] Release-Build mit eigenem Keystore signiert, als **App Bundle**
- [ ] Build mit aktiviertem Minify auf einem echten Gerät durchgespielt (nicht nur kompiliert)
- [ ] `useMockData = false` und ein echter Durchlauf gegen die Live-API bestätigt
- [ ] Keine Debug-Ausgaben mit personenbezogenen Daten (`debugPrint` durchsehen)
- [ ] DSE-, AGB- und Impressum-URLs erreichbar und in der App verlinkt
- [ ] Data-Safety-Formular deckt sich mit dem tatsächlichen Verhalten
- [ ] Alterseinstufung abgeschlossen, Zielgruppe gesetzt
- [ ] Screenshots aktuell (zeigen die Deep-Teal-Oberfläche, nicht das alte Schema)
- [ ] Konto-Löschweg in der App und im Web erreichbar
- [ ] Testkonto für die Google-Prüfer hinterlegt, falls Login Pflicht ist
- [ ] Crashlytics empfängt Ereignisse aus dem Release-Build
- [ ] Rate-Limits und Budget-Alarm im Cloud-Projekt aktiv
- [ ] Rollback-Plan: vorherige Version im Play-Konsolen-Track verfügbar

---

# Die drei Aufgaben für sofort

### 1. Git-Repository anlegen (S)

Alles Weitere sind tiefe Eingriffe. Ohne Historie ist jeder Fehlgriff endgültig, und du
kannst nicht mehr nachvollziehen, wann sich Verhalten geändert hat. Fünf Minuten Aufwand,
und `.gitignore` ist bereits richtig vorbereitet.

### 2. Backend-Entscheidung treffen und den Gemini-Proxy bauen (M)

Das ist der einzige Punkt, der später *teurer statt nur aufwendiger* wird: Sobald ein
echter Key in einem verteilten Build steckt, ist er kompromittiert und du zahlst fremden
Verbrauch. Aktuell ist noch nichts passiert — der Mock-Modus läuft, `.env` ist leer. Der
Umbau ist außerdem gerade jetzt klein, weil `AnalysisService` und `CheckinService` schon
Interfaces sind: Es kommt eine Implementierung dazu, die UI bleibt unberührt. Danach
kannst du den echten Antwortpfad endlich einmal gegen die Live-API prüfen — das steht
bisher komplett aus.

### 3. Play-Entwicklerkonto anlegen und den geschlossenen Test vorbereiten (S, aber 2+ Wochen Wartezeit)

Identitätsprüfung und die 14-Tage-Testphase mit 12 Testern laufen unabhängig von deinem
Code. Wenn du sie erst startest, wenn die App fertig ist, wartest du am Ende zwei Wochen
mit fertiger App. Fang parallel zu Phase 1 an und sammle schon jetzt Tester ein.

---

# Offene Fragen an dich

Diese Punkte lassen sich aus dem Code nicht beantworten, verändern aber die Planung
spürbar:

1. **Fotos in die Cloud oder lokal?** Meine Empfehlung ist „lokal, nur Ergebnisse
   synchronisieren" (Abschnitt 1.3). Willst du Fortschrittsfotos über einen Gerätewechsel
   hinweg erhalten, wird der Datenschutzaufwand deutlich größer.
2. **Preismodell:** Was soll was kosten — Basis kostenlos? Module einzeln? Abo mit welchem
   Preis? Ohne das lässt sich Phase 3 nicht konkretisieren.
3. **Play-Konto:** privat oder als Firma/Einzelunternehmen? Privatkonten brauchen die
   12-Tester-Regel, Firmenkonten nicht. Existiert schon ein Konto?
4. **Impressum:** Gibt es eine Firmierung/Adresse, die dort stehen kann? Wer schreibt die
   Rechtstexte — Anwalt oder Generator?
5. **Zielmärkte und Sprachen:** nur Deutschland/DACH und Deutsch? Das entscheidet über
   Übersetzungen und den rechtlichen Rahmen.
6. **iOS:** ernsthaft geplant oder „irgendwann"? Bei einem klaren Ja lohnt sich bei der
   Billing-Auswahl von Anfang an eine Abstraktion.
7. **`minSdk 26`** (Android 8) beibehalten? Das schließt sehr alte Geräte aus, ist wegen ML
   Kit aber vermutlich gesetzt.
8. **Mock-Modus:** soll er als Demo-/Screenshot-Modus erhalten bleiben oder mit dem Proxy
   verschwinden?
