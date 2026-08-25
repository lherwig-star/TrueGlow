# SETUP — was du außerhalb des Codes erledigen musst

Diese Datei listet **alle manuellen Schritte**, die nicht im Code stehen können:
Konsolen-Klicks, Secrets, Fingerprints, Freischaltungen. Sie wird bei jedem
Arbeitspaket mitgepflegt.

**Konvention in dieser Datei**

- `☐` offen · `☑` erledigt (hak ab, wenn du es gemacht hast)
- Klickpfade stehen als `Menü → Untermenü → Schaltfläche`
- Alle CLI-Befehle laufen im Projektordner (`C:\Users\idont\Desktop\Face Analyse`),
  sofern nichts anderes dabeisteht

> ## ⚠️ Wenn du die Firebase-Konsole schon eingerichtet hast: hier anfangen
>
> Die App heißt seit Phase 2 **TrueGlow**, und die Anwendungs-ID hat sich von
> `com.glowup.glowup` auf **`com.trueglow.app`** geändert. Eine bereits
> registrierte App mit der alten ID passt nicht mehr — **Abschnitt 2.0 ist
> dann der erste Punkt, den du nachziehst.** Erst danach stimmen
> `google-services.json`, App Check und Google Sign-In wieder.
>
> Wenn du noch gar nichts eingerichtet hast: Abschnitt 2.0 überspringen und
> normal bei Abschnitt 0 beginnen — dort steht überall schon die neue ID.

**Feste Projektwerte**

| Wert | Inhalt |
|---|---|
| Android-Paketname | `com.trueglow.app` |
| iOS-Bundle-ID | `com.trueglow.app` |
| Firebase-Region (Functions, Firestore) | `europe-west3` (Frankfurt) |
| Gemini-Modell | `gemini-2.5-flash` |
| Secret-Name des Gemini-Keys | `GEMINI_API_KEY` |
| Rate-Limit pro Konto | 3 Analysen/Tag, 30/Monat |

---

## 0 · Werkzeuge auf dem Rechner

Einmalig. Ohne diese drei Werkzeuge lassen sich die folgenden Schritte nicht
ausführen.

☐ **Node.js ≥ 20** — vorhanden (`node --version` → v24.19.0). Nichts zu tun.

☐ **Firebase CLI installieren**

```bash
npm install -g firebase-tools
```

Danach anmelden (öffnet den Browser):

```bash
firebase login
```

☐ **FlutterFire CLI installieren**

```bash
dart pub global activate flutterfire_cli
```

Falls `flutterfire` danach nicht gefunden wird, muss
`%LOCALAPPDATA%\Pub\Cache\bin` in die `PATH`-Variable.

☐ **Java 17+ für die Firestore-Emulatoren** (nur für die Rules-Tests nötig)

```bash
java -version
```

Fehlt Java: Temurin 17 von <https://adoptium.net> installieren.

---

## 1 · Firebase-Projekt anlegen

☐ **1.1 Projekt erstellen**

1. <https://console.firebase.google.com> öffnen
2. **Projekt hinzufügen**
3. Name: `trueglow` (die Projekt-ID darunter merken, z. B. `trueglow-1a2b3`)
4. Google Analytics: **aus** — wird erst in Phase 4 gebraucht und muss vorher
   in der Datenschutzerklärung stehen
5. **Projekt erstellen**

☑ **1.2 Abrechnungskonto verknüpfen (Blaze-Tarif)** — aktiv für
`trueglow-b2c1c` (geprüft am 24.08.2026)

Cloud Functions der 2. Generation laufen **nicht** im kostenlosen Spark-Tarif.

1. Firebase-Konsole → Zahnrad → **Nutzung und Abrechnung** → **Details und Einstellungen**
2. **Tarif ändern** → **Blaze** → Zahlungskonto anlegen oder auswählen

Der Budget-Alarm dazu steht in Schritt 5.3 — **bitte nicht überspringen.**

☐ **1.3 Firestore anlegen — Region ist unumkehrbar**

1. Firebase-Konsole → **Build → Firestore Database** → **Datenbank erstellen**
2. Modus: **Im Produktionsmodus starten** (die Regeln liefert das Repo)
3. Standort: **`europe-west3 (Frankfurt)`**
4. **Erstellen**

> Der Standort einer Firestore-Datenbank lässt sich später **nicht** ändern.
> Wenn hier `nam5` oder `eur3` stehen bleibt, muss das ganze Projekt neu
> aufgesetzt werden.

☐ **1.4 Authentifizierung einschalten**

1. Firebase-Konsole → **Build → Authentication** → **Jetzt starten**
2. Reiter **Sign-in method**
3. **Anonym** → aktivieren → Speichern
4. **Google** → aktivieren → Projekt-Support-E-Mail auswählen → Speichern
5. *(später, für iOS)* **Apple** → aktivieren — siehe Abschnitt 7

☐ **1.5 App Check vorbereiten**

1. Firebase-Konsole → **Build → App Check**
2. Noch nichts registrieren — die Apps tauchen hier erst nach Schritt 2 auf.
   Weiter mit Abschnitt 4.

---

## 2 · Apps registrieren und FlutterFire verbinden

### 2.0 Nur falls du schon mit `com.glowup.glowup` begonnen hast

Die Anwendungs-ID ist nach dem ersten Play-Upload **unveränderlich** — deshalb
wurde sie jetzt umgestellt, solange es noch nichts kostet. Ein Firebase-Projekt
kann problemlos mehrere Apps enthalten; du registrierst also die neue dazu und
räumst die alte weg.

☑ **2.0.1 Neue Android-App registrieren** — erledigt über die CLI
(`firebase apps:create android`), App-ID
`1:732767304100:android:6ebbf8d8b1d52711b7e931`

1. Firebase-Konsole → Zahnrad → **Projekteinstellungen** → Reiter **Allgemein**
2. Karte **Deine Apps** → **App hinzufügen** → Android
3. Paketname: **`com.trueglow.app`**, Spitzname: `TrueGlow Android`
4. **App registrieren** — die angebotene `google-services.json` kannst du
   überspringen, `flutterfire configure` holt sie gleich selbst

☑ **2.0.2 Neue iOS-App registrieren** (auch wenn iOS erst später kommt) —
erledigt, App-ID `1:732767304100:ios:ea3e3e17f2595ecdb7e931`

Gleicher Weg, Bundle-ID **`com.trueglow.app`**.

☑ **2.0.3 `flutterfire configure` erneut ausführen**

```bash
flutterfire configure --project=DEINE-PROJEKT-ID --platforms=android,ios --out=lib/firebase_options.dart
```

Wähle in der Auswahlliste die **neuen** Apps. Danach liegen frische
`android/app/google-services.json` und `ios/Runner/GoogleService-Info.plist`
im Projekt und `lib/firebase_options.dart` zeigt auf die neue App-ID.

☑ **2.0.4 SHA-Fingerprints neu eintragen** — erledigt, siehe Abschnitt 3

Fingerprints hängen an der **App-Registrierung**, nicht am Projekt — die alten
gelten für die neue App nicht. Abschnitt 3 noch einmal durchlaufen, danach
`google-services.json` erneut herunterladen.

☐ **2.0.5 App Check neu einrichten**

Auch App Check hängt an der App-Registrierung: Play Integrity für die neue
Android-App aktivieren und ein **neues** Debug-Token eintragen (Abschnitt 4).
Das alte Debug-Token gilt nicht weiter.

☑ **2.0.6 Alte App-Registrierung entfernen** — entfällt: im Projekt
`trueglow-b2c1c` war nie eine App mit der alten ID registriert, es gab also
nichts zu entfernen.

1. **Projekteinstellungen → Allgemein → Deine Apps** → alte App
   `com.glowup.glowup`
2. **App entfernen** → bestätigen

> Firestore-Daten, Auth-Konten, Secrets und die Cloud Functions hängen am
> **Projekt**, nicht an der App-Registrierung. Sie bleiben also unberührt.
> Nur wenn du dich vorher schon mit einem Testkonto angemeldet hast, meldet
> dich die App nach dem Wechsel einmal neu an.

---

☑ **2.1 `flutterfire configure` ausführen** — mit Projekt `trueglow-b2c1c`
gelaufen; `lib/firebase_options.dart` und `android/app/google-services.json`
enthalten jetzt die echten Werte.

> **Windows-Hinweis:** `flutterfire configure` legt
> `ios/Runner/GoogleService-Info.plist` nur auf einem Mac an, weil es die Datei
> dort gleich ins Xcode-Target hängt. Sie wurde hier ersatzweise mit
> `firebase apps:sdkconfig IOS <App-ID> --out ios/Runner/GoogleService-Info.plist`
> geholt; das Einhängen ins Xcode-Target bleibt Schritt 7.5.

> `flutterfire configure` schreibt `firebase.json` einzeilig zurück und ergänzt
> darin einen `flutter`-Block. Der Inhalt bleibt gleich — die Datei wurde nur
> wieder lesbar formatiert.

```bash
flutterfire configure --project=DEINE-PROJEKT-ID --platforms=android,ios --out=lib/firebase_options.dart
```

Der Befehl

- registriert die Android- und die iOS-App im Firebase-Projekt,
- legt `android/app/google-services.json` und
  `ios/Runner/GoogleService-Info.plist` ab,
- **überschreibt** `lib/firebase_options.dart`.

> Im Repo liegt eine Platzhalter-Fassung von `lib/firebase_options.dart` mit
> ungültigen Werten, damit das Projekt vor diesem Schritt kompiliert. Nach
> `flutterfire configure` enthält die Datei die echten Projekt-IDs. Das sind
> **keine Geheimnisse** (sie stecken ohnehin in jedem Release-Build), die
> Datei bleibt deshalb im Repo. `google-services.json` und
> `GoogleService-Info.plist` sind über `.gitignore` ausgeschlossen — bei einem
> frischen Klon musst du `flutterfire configure` also erneut laufen lassen.

> **Lokaler Platzhalter:** Im Arbeitsverzeichnis liegt bereits eine
> `android/app/google-services.json` mit erfundenen Werten. Sie existiert nur,
> damit sich die App ohne Firebase-Projekt bauen und im Demo-Modus auf einem
> Geraet ausprobieren laesst — die Datei ist über `.gitignore` ausgeschlossen
> und wird von `flutterfire configure` überschrieben. **Ersetze sie**, bevor
> du gegen echtes Firebase baust; solange `lib/firebase_options.dart` noch den
> Platzhalter enthält, zeigt die App ohnehin den Einrichtungshinweis.

☑ **2.2 Kontrolle** — `flutter pub get` und `flutter analyze` laufen sauber
(„No issues found!").

```bash
ls android/app/google-services.json ios/Runner/GoogleService-Info.plist
flutter pub get
flutter analyze
```

---

## 3 · SHA-1 / SHA-256 für Google Sign-In (Android)

Google Sign-In auf Android funktioniert **nur**, wenn der Fingerprint des
signierenden Keystores in Firebase hinterlegt ist. Für die Entwicklung ist das
der Debug-Keystore.

☑ **3.1 Debug-Fingerprint auslesen**

```bash
keytool -list -v -alias androiddebugkey -keystore "$USERPROFILE/.android/debug.keystore" -storepass android -keypass android
```

In PowerShell:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Aus der Ausgabe die Zeilen `SHA1:` und `SHA256:` kopieren.

☑ **3.2 In Firebase eintragen** — beide Debug-Fingerprints sind eingetragen.
Statt der Klickstrecke ging es über die CLI:

```bash
firebase apps:android:sha:create <ANDROID-APP-ID> <SHA-HASH> --project trueglow-b2c1c
firebase apps:android:sha:list   <ANDROID-APP-ID>            --project trueglow-b2c1c
```

Der Klickweg tut dasselbe:

1. Firebase-Konsole → Zahnrad → **Projekteinstellungen** → Reiter **Allgemein**
2. Karte **Deine Apps** → die Android-App `com.trueglow.app`
3. **Fingerabdruck hinzufügen** → SHA-1 einfügen → Speichern
4. Dasselbe noch einmal mit SHA-256

> **Windows-Eigenheit:** `apps:android:sha:create` und einige andere
> `firebase`-Befehle enden auf diesem Rechner mit
> `Assertion failed: !(handle->flags & UV_HANDLE_CLOSING)` und Exit-Code 9,
> **obwohl der Befehl durchgelaufen ist** (das `√` davor zeigt es). Das ist ein
> Absturz beim Beenden des CLI-Prozesses, kein Fehler der Aktion. Ergebnis
> immer mit dem passenden `:list`-Befehl nachprüfen statt dem Exit-Code zu
> glauben.

☑ **3.3 `google-services.json` neu herunterladen** — die Fingerprints wurden
**vor** `flutterfire configure` eingetragen, die erzeugte Datei enthält sie
also bereits (zwei `oauth_client`-Einträge). Ein erneuter Download entfällt.

Nach dem Eintragen eines Fingerprints ändert sich die Datei.

1. Gleiche Seite → bei der Android-App auf **google-services.json**
2. Datei nach `android/app/google-services.json` legen (vorhandene ersetzen)

☐ **3.4 Später: Fingerprint des Release-Keystores**

Sobald in Phase 2.6 der eigene Keystore existiert, dessen SHA-1 **zusätzlich**
eintragen — sonst schlägt Google Sign-In im Play-Release fehl. Zusätzlich den
SHA-1 der **Play App Signing**-Schlüssel aus der Play Console
(**Release → Setup → App-Integrität**) eintragen.

---

## 4 · App Check

App Check sorgt dafür, dass die Cloud Functions nur von echten Installationen
deiner App gerufen werden können — nicht per `curl` mit einem geklauten Token.

☑ **4.1 Android registrieren (Play Integrity)** — aktiv für `com.trueglow.app`

1. Firebase-Konsole → **Build → App Check** → Reiter **Apps**
2. Android-App aufklappen → **Play Integrity** → **Speichern**

> Play Integrity funktioniert nur bei Builds, die über Google Play verteilt
> werden. Für lokale Debug-Builds nimmst du den Debug-Provider (4.3).

☐ **4.2 iOS registrieren (App Attest)** — erst wenn iOS gebaut wird, siehe Abschnitt 7

☑ **4.3 Debug-Token für die Entwicklung eintragen** — zuletzt am 25.08.2026
neu eingetragen (Gerät SM A525F). Der ältere Eintrag `Samsung A52` galt nach
einer Neuinstallation nicht mehr und kann weg.

1. App im Debug-Modus einmal starten: `flutter run`
2. In der Konsolenausgabe nach einer Zeile suchen, die so aussieht:
   `Enter this debug secret into the allow list in the Firebase Console ...`
   gefolgt von einer UUID

> ## Wenn die Zeile in der `flutter run`-Ausgabe fehlt
>
> Der Debug-Provider gibt das Token erst aus, wenn zum **ersten Mal ein
> App-Check-Token angefordert** wird — nicht schon beim `activate()`. Steht die
> App nur im Onboarding, ist noch nichts passiert und die Zeile fehlt.
>
> Sie steht aber im Geräteprotokoll. Direkt auslesen:
>
> ```powershell
> & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -d | Select-String "DebugAppCheckProvider"
> ```
>
> Das Token gilt **pro Installation**: Nach `flutter run --uninstall-first`
> oder einer Neuinstallation ist es ein anderes und muss neu eingetragen
> werden.
>
> ## Woran ein abgelaufenes Token zu erkennen ist
>
> Seit 4.4 erzwungen wird, ist das kein Schönheitsfehler mehr: Ein nicht
> eingetragenes Token sperrt die Cloud-Sicherung **und** die Analyse aus —
> die Cloud Function setzt `enforceAppCheck: true`. Im Logcat steht dann:
>
> ```
> Failed to exchange debug token (…)
> Firestore: PERMISSION_DENIED – Missing or insufficient permissions
> ```
>
> Der Fototeil läuft davon unberührt weiter, der ist rein lokal. Die
> Verwechslungsgefahr ist also groß: Die App wirkt gesund, bis eine echte
> Analyse gestartet wird.
3. Firebase-Konsole → **App Check** → Reiter **Apps** → Android-App →
   Dreipunkt-Menü → **Debug-Tokens verwalten** → **Debug-Token hinzufügen**
4. UUID einfügen, Name z. B. `Laptop Debug`, **Speichern**

☑ **4.4 Erzwingen einschalten — erst zum Schluss** — erledigt am 24.08.2026,
Kontroll-Durchlauf danach erfolgreich

1. Firebase-Konsole → **App Check** → Reiter **APIs**
2. **Cloud Firestore** → **Erzwingen**
3. *(Cloud Functions steht dort nicht — siehe Kasten)*

> Erst einschalten, wenn ein echter Durchlauf mit Debug-Token funktioniert hat
> (Abschnitt 6). Vorher sperrst du dich selbst aus.

> ## Cloud Functions taucht in der APIs-Liste nicht auf
>
> Hier stand früher, man solle auch **Cloud Functions** auf „Erzwingen"
> stellen. Diese Zeile gibt es in der Liste nicht: Functions der 2. Generation
> laufen auf Cloud Run und werden nicht über den App-Check-Reiter erzwungen.
>
> Das ist kein fehlender Schutz. Beide Endpunkte tragen
> **`enforceAppCheck: true`** in `functions/src/index.ts` — die Erzwingung
> steckt also im Code und war von der ersten Zeile an aktiv. Der Live-Durchlauf
> hat das bestätigt (`"app":"VALID"` im Log, Abschnitt 6.2).
>
> **Google Identity for iOS** bleibt bewusst *nicht* erzwungen, bis die
> iOS-App existiert (Abschnitt 7). Vorher gäbe es nichts, was ein gültiges
> Token liefern könnte.

---

## 5 · Gemini-Key, Cloud Functions, Budget

☑ **5.1 Gemini-API-Key erzeugen**

1. <https://aistudio.google.com/apikey> öffnen
2. **API-Schlüssel erstellen** → *im bestehenden Firebase-Projekt* (dann läuft
   die Abrechnung über dasselbe Cloud-Projekt)
3. Schlüssel kopieren — er wird gleich in den Secret Manager gelegt und danach
   **nirgends sonst** gespeichert

> Der Schlüssel gehört **nicht** in `.env`, nicht in den Code und nicht in
> `firebase.json`. Die App bekommt ihn nie zu sehen.

> ## Schlüsselformat: `AQ.` statt `AIza`
>
> Google hat das Format der Gemini-Schlüssel umgestellt. Neu im AI Studio
> erzeugte Schlüssel („Auth keys") beginnen mit **`AQ.Ab`** und sind länger als
> die alten. Das frühere Format („Standard keys", `AIza…`, 39 Zeichen) wird
> **ab September 2026 nicht mehr angenommen**.
>
> Ein Schlüssel, der mit `AQ.` anfängt, ist also **richtig** — nicht abgeschnitten
> und nicht der falsche Wert. Der hier verwendete Schlüssel hat dieses Format.
>
> **Deshalb wird das Format nirgends geprüft.** `functions/src/index.ts` testet
> den Wert aus dem Secret Manager nur auf *nicht leer* — und das soll so
> bleiben. Eine Prüfung auf `AIza…` würde heute jeden neuen Schlüssel ablehnen.
> Falls du irgendwo eine Formatprüfung ergänzen willst: nicht am Präfix
> festmachen.
>
> Die Zeichenketten `AIzaSy…` in `lib/firebase_options.dart` sind etwas
> anderes — das sind Firebase-Client-Schlüssel, die weiterhin dieses Format
> haben. Sie haben mit dem Gemini-Schlüssel nichts zu tun.

☑ **5.2 Key als Secret hinterlegen** — liegt als
`projects/732767304100/secrets/GEMINI_API_KEY/versions/1` im Secret Manager

```bash
firebase functions:secrets:set GEMINI_API_KEY --project DEINE-PROJEKT-ID
```

Der Befehl fragt den Wert interaktiv ab (Eingabe wird nicht angezeigt) und legt
ihn im Google Secret Manager an. Prüfen:

```bash
firebase functions:secrets:access GEMINI_API_KEY --project DEINE-PROJEKT-ID
```

> ## ⚠️ Windows: die versteckte Eingabe nimmt keinen eingefügten Text an
>
> Im klassischen `Windows PowerShell`-Fenster (conhost) kommt bei der versteckten
> Abfrage `Enter a value for GEMINI_API_KEY:` **nichts** an — weder über
> Strg+V noch über Rechtsklick noch über *Alt+Leertaste → Bearbeiten →
> Einfügen*. Der Befehl bricht dann ab mit:
>
> ```
> HTTP Error: 400, Secret Payload cannot be empty
> ```
>
> Der Ausweg ist `--data-file`, das die Abfrage ganz überspringt. Diese eine
> Zeile nimmt den Schlüssel aus der Zwischenablage, legt ihn ab und räumt die
> Zwischendatei sofort wieder weg:
>
> ```powershell
> Get-Clipboard | Set-Content -NoNewline "$env:TEMP\gk.txt" -Encoding ascii; firebase functions:secrets:set GEMINI_API_KEY --data-file="$env:TEMP\gk.txt" --project trueglow-b2c1c; Remove-Item "$env:TEMP\gk.txt"
> ```
>
> Reihenfolge beachten: **erst** diese Zeile ins Fenster einfügen, **dann** im
> AI Studio den Schlüssel kopieren, **dann** Enter. Sonst überschreibt das
> Kopieren der Befehlszeile den Schlüssel in der Zwischenablage.
>
> `-NoNewline` ist nicht optional — ein angehängter Zeilenumbruch landet sonst
> mit im Secret und der Schlüssel wird von Google abgelehnt.

> **Prüfen, ohne den Schlüssel anzuzeigen:** `secrets:access` schreibt den
> Klartext in die Konsole. Wer nur wissen will, *ob* etwas Plausibles
> drinsteht, fängt die Ausgabe in einer Variablen auf:
>
> ```powershell
> $k = (firebase functions:secrets:access GEMINI_API_KEY --project trueglow-b2c1c) -join ''
> "Laenge: $($k.Trim().Length)"
> ```

☑ **5.3 Budget-Alarm einrichten — nicht überspringen** — abgedeckt durch das
von Google automatisch angelegte Budget **„Firebase Project trueglow-b2c1c"**:
25 € pro Monat, Benachrichtigung bei 50 / 90 / 100 %. Kein zweites Budget
angelegt. Der unten genannte Betrag von 10 € war ein Vorschlag, keine
Anforderung — entscheidend ist, dass überhaupt ein Alarm greift.

> Ergänzend läuft der Gemini-Zugriff über ein aufgeladenes
> AI-Studio-Guthaben (25 €), der Schlüssel steht auf **Preisstufe 1**.

1. <https://console.cloud.google.com/billing> → Rechnungskonto wählen
2. Links **Budgets und Benachrichtigungen** → **Budget erstellen**
3. Name: `TrueGlow Monatsbudget`
4. Bereich: **Projekt** → das Firebase-Projekt auswählen
5. Betrag: z. B. **10 €** pro Monat (bei 3 Analysen/Tag pro Konto liegt der
   reale Verbrauch weit darunter — der Alarm ist gegen Missbrauch und Fehler)
6. Schwellen: 50 %, 90 %, 100 % — jeweils **E-Mail an Rechnungsadministratoren**
7. **Fertig**

☑ **5.4 Nötige APIs freischalten** — vom ersten Deploy automatisch erledigt.
Freigeschaltet wurden: `cloudfunctions`, `cloudbuild`, `artifactregistry`,
`run`, `eventarc`, `pubsub`, `firebaseextensions`; `secretmanager`,
`storage`, `pubsub` und `firestore` waren bereits an. `gcloud` ist auf diesem
Rechner **nicht** installiert und wurde auch nicht gebraucht.

Beim ersten Deploy fragt die CLI danach; man kann es auch vorziehen:

```bash
gcloud services enable secretmanager.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com generativelanguage.googleapis.com --project DEINE-PROJEKT-ID
```

Ohne `gcloud` geht es auch per Klick über
<https://console.cloud.google.com/apis/library>.

☑ **5.5 Functions deployen** — erledigt

```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions --project DEINE-PROJEKT-ID
```

Erwartete Ausgabe: **drei** Funktionen in `europe-west3` — `analysiere`,
`checkinAuswerten` und `kontoLoeschen`, alle `callable`, Node.js 22, 1 GiB.
Mit `firebase functions:list` nachprüfbar.

> ## Stolperstein 1: `npm install` bricht mit `ERESOLVE` ab
>
> `@firebase/rules-unit-testing@^5` verlangt `firebase@^12`, in
> `functions/package.json` stand aber `firebase@^11.10.0`. Beides sind reine
> devDependencies für die Rules-Tests (Abschnitt 9) und stecken **nicht** in
> der ausgelieferten Function. Behoben durch Anheben auf `firebase@^12.0.0`.
> Nicht mit `--force` oder `--legacy-peer-deps` darüberbügeln — dann brechen
> die Rules-Tests.

> ## Stolperstein 2: `Cannot determine backend specification. Timeout after 10000`
>
> Der erste Deploy scheitert auf diesem Rechner mit:
>
> ```
> Error: User code failed to load. Cannot determine backend specification.
> Timeout after 10000.
> ```
>
> Das ist **kein** Codefehler. Die CLI startet die gebauten Functions kurz, um
> herauszufinden, was deployt werden soll, und gibt dem nur 10 Sekunden —
> unter Windows zu knapp. Gegenprobe, ob wirklich alles in Ordnung ist:
>
> ```powershell
> node -e "require('./functions/lib/index.js'); console.log('MODUL GELADEN OK')"
> ```
>
> Kommt dort `MODUL GELADEN OK`, hilft schlicht mehr Zeit:
>
> ```powershell
> $env:FUNCTIONS_DISCOVERY_TIMEOUT='180'; firebase deploy --only functions --project trueglow-b2c1c
> ```

> ## Stolperstein 3: Exit-Code 1 trotz erfolgreichem Deploy
>
> Nach dem eigentlichen Deploy meldet die CLI:
>
> ```
> Error: Functions successfully deployed but could not set up cleanup policy
> ```
>
> Die Functions **stehen dann bereits** („Successful create operation"). Ohne
> Aufräumregel sammeln sich nur die Container-Abbilder jedes Deploys in der
> Artifact Registry an und verursachen langsam Speicherkosten. Einmalig setzen:
>
> ```bash
> firebase functions:artifacts:setpolicy --location europe-west3 --days 3 --force --project trueglow-b2c1c
> ```
>
> Gelöscht werden ausschließlich alte Build-Abbilder — nie Code, Daten oder
> laufende Functions. Ist gesetzt (3 Tage).

☑ **5.6 Firestore-Regeln und -Indizes deployen** — erledigt, Regeln kompiliert
und veröffentlicht, Indizes angelegt

```bash
firebase deploy --only firestore:rules,firestore:indexes --project DEINE-PROJEKT-ID
```

---

## 6 · Erster echter Durchlauf gegen die Live-API

Dieser Schritt steht ausdrücklich in der Roadmap („Echten Antwortpfad erstmals
gegen die Live-API prüfen") und kann **nur von dir** ausgeführt werden — er
braucht das Firebase-Projekt, den Key und ein Gerät mit Kamera.

☑ **6.1 App mit echtem Backend starten** — am 24.08.2026 auf einem Samsung
SM A525F (Android 13) gelaufen. `flutter run` genügt: `TRUEGLOW_MOCK` ist
`bool.fromEnvironment` und damit ohne Angabe `false`.

```bash
flutter run --dart-define=TRUEGLOW_MOCK=false
```

`TRUEGLOW_MOCK` ist standardmäßig `false`; der Schalter existiert, um den
Demo-/Screenshot-Modus gezielt einzuschalten (`--dart-define=TRUEGLOW_MOCK=true`).

☑ **6.2 Ablauf durchspielen** — durchgelaufen, Report erschienen, keine
Fehlermeldung.

1. Onboarding → Login („Erst ausprobieren" reicht) → Fotos → Analyse starten
2. In der Firebase-Konsole → **Functions → Protokolle** mitlesen
3. Prüfen: **keine** Bildinhalte in den Logs, nur Zähler und Fehlercodes

Bestätigt wurde:

- `{"verifications":{"auth":"VALID","app":"VALID"}}` — App Check **und**
  Auth-Token wurden serverseitig akzeptiert.
- Kein Treffer für `data:image`, `base64` oder `bilder` in den Protokollen.
  Die zwei langen Base64-Ketten im Log sind `source_token`-Felder aus den
  Deploy-Audit-Einträgen, keine Bilddaten.

> **Bei Erfolg steht fast nichts im Log** — und das ist Absicht, kein Fehler.
> Die Function protokolliert nur in Ausnahmefällen (`functions/src/fehler.ts`,
> der zweite Versuch in `index.ts`, die Kontingent- und Löschmeldungen). Ein
> leeres Protokoll nach einer erfolgreichen Analyse ist das erwartete Bild.
>
> Zum Mitlesen von der Kommandozeile:
>
> ```bash
> firebase functions:log --only analysiere --lines 100 --project trueglow-b2c1c
> ```

☑ **6.3 Abweichungen notieren** — Tabelle in `DECISIONS.md`, Abschnitt
„Mock vs. Live", ist gefüllt

Unterschiede zwischen Mock- und Realantwort in `DECISIONS.md` festhalten
(Abschnitt „Mock vs. Live"). Interessant sind vor allem: fehlende Felder,
abgeschnittene Antworten, Sicherheitsfilter, Antwortdauer.

Kurzfassung des Befunds: nichts abgeschnitten, kein Sicherheitsfilter, kein
Nachfass-Versuch nötig. Zwei Auffälligkeiten — einmal lieferte ein Kapitel nur
3 statt der geforderten 4–7 Habits, und `plan.taeglicheHabits` ist ein totes
Feld, das niemand anfordert, füllt oder liest.

☑ **6.4 Rate-Limit prüfen** — bestanden am 24.08.2026

Vier Analysen an einem Tag starten — die vierte muss mit „Kontingent
erschöpft" abgelehnt werden, **ohne** dass ein Gemini-Aufruf stattfindet
(im Log sichtbar).

Beobachtet: Analysen um 20:49, 20:59 und 21:03 liefen durch, die vierte um
21:05 wurde abgelehnt mit

```
W analysiere: kontingent: Tagesgrenze analyse erreicht (<uid>)
```

Zwischen `Callable request verification passed` (21:05:02.878) und der
Ablehnung (21:05:02.937) liegen **59 ms**. Ein Gemini-Aufruf braucht mehrere
Sekunden — die Sperre greift also nachweislich **vor** dem Modellaufruf, nicht
erst danach. Das ist der eigentliche Punkt des Tests: Der Zähler schützt vor
Kosten, nicht nur vor Nutzung.

> **Beiläufige Beobachtung:** Die Kontingent-Warnung enthält die **uid** des
> Kontos. Für Function-Logs ist das vertretbar und beim Nachstellen von
> Quota-Problemen nützlich — es ist kein Bildinhalt und kein Analysetext. Nicht
> zu verwechseln mit der schärferen Regel für Crashlytics (Abschnitt 14.6), wo
> uid und E-Mail nicht vorkommen dürfen.

☑ **6.5 Stichprobe: Klingt etwas wie eine Diagnose?** — 3 von 3 ohne Befund
(24.08.2026). Prompt muss nicht nachgeschärft werden.

> ## ⚠️ Korrektur: Die Antworten stehen **nicht** in den Function-Logs
>
> Hier stand früher, man solle das Antwortobjekt aus den Function-Logs
> kopieren. Das geht nicht — und soll auch nicht gehen: Die Function
> protokolliert die Antwort bewusst nirgends (siehe 6.2). Die Logs zu
> erweitern wäre genau der falsche Weg, denn dann läge der Analysetext eines
> Nutzers im Cloud-Logging.
>
> **Richtige Quelle ist das Gerät.** Die App legt jede Analyse lokal als
> JSON-String in einer Hive-Box ab (`lib/core/storage/hive_service.dart`,
> bewusst ohne TypeAdapter). Dieselben Daten stehen zwar auch in Firestore
> unter `users/{uid}/analysen/{analyseId}` — aber die Firebase-Konsole kann
> einzelne Dokumente **nicht** als JSON exportieren, das wäre Abtipparbeit.
>
> Mit angestecktem Gerät (Debug-Build, USB-Debugging an):
>
> ```bash
> adb exec-out run-as com.trueglow.app cat app_flutter/analysen.hive > tool/stichprobe/analysen.hive
> dart run tool/analysen_exportieren.dart tool/stichprobe
> ```
>
> Daraus fällt je Analyse eine `analyse_<id>.json`.
>
> `adb exec-out` statt `adb shell`: Letzteres wandelt Zeilenenden um und
> beschädigt die Binärdatei. Der Umweg über `/sdcard` funktioniert nicht —
> `run-as` darf dort seit Android 11 nicht schreiben.
>
> `tool/stichprobe/` ist über `.gitignore` ausgeschlossen: Da liegen echte
> Analysetexte.

Das Antwortobjekt von 3–5 echten Analysen je als `.json` speichern und
prüfen:

```bash
dart run tool/diagnose_stichprobe.dart antwort1.json antwort2.json antwort3.json
```

Das Skript hält die Antworten gegen dieselben Regeln wie der Testfall über die
Mock-Antworten: Diagnosewörter, benannte Krankheitsbilder,
Behandlungsempfehlungen, Bewertungszahlen, Attraktivitäts- und
Gewichtsurteile. Findet es etwas, gehört der Prompt nachgeschärft
(`functions/src/analyse_prompt.ts`) und das Ergebnis in `DECISIONS.md`,
Abschnitt 21.

---

## 7 · iOS (kommt fest, Vorbereitung jetzt)

☐ **7.1 Apple-Developer-Programm** (99 $/Jahr) — <https://developer.apple.com/programs/>

☐ **7.2 Bundle-ID `com.trueglow.app`** im Apple-Developer-Portal registrieren,
Capabilities **Sign in with Apple** und **App Attest** aktivieren

☐ **7.3 Sign in with Apple in Firebase aktivieren**

1. Firebase-Konsole → **Authentication → Sign-in method → Apple** → aktivieren
2. Services-ID, Team-ID, Key-ID und den `.p8`-Schlüssel aus dem
   Apple-Developer-Portal eintragen

> **Pflicht von Apple:** Sobald die iOS-App Google Sign-In anbietet, muss sie
> auch „Sign in with Apple" anbieten. Der Code ist darauf vorbereitet — es
> kommt nur ein weiterer Eintrag in `AuthAnbieter` dazu, kein Umbau.

☐ **7.4 Mindest-iOS-Version**: Firebase verlangt iOS 15 oder neuer. In
`ios/Podfile` `platform :ios, '15.0'` setzen (die Datei entsteht beim ersten
`flutter build ios`) und im Xcode-Target dasselbe eintragen.

☐ **7.5 Xcode-Projekt**: Signing-Team setzen, Capability
**Sign in with Apple** hinzufügen, `GoogleService-Info.plist` ins Runner-Target
ziehen

☐ **7.6 URL-Schema für Google Sign-In**: den Wert `REVERSED_CLIENT_ID` aus
`GoogleService-Info.plist` in `ios/Runner/Info.plist` unter `CFBundleURLTypes`
eintragen (macht `flutterfire configure` nicht automatisch)

---

## 8 · Backup außerhalb des Rechners (Phase 0)

☐ **8.1 Privates Remote-Repo anlegen**

GitHub → **New repository** → Name `trueglow` → **Private** → *ohne* README
anlegen. Danach:

```bash
git remote add origin https://github.com/DEIN-KONTO/trueglow.git
git push -u origin main
```

> Das Repo enthält keine Secrets: `.env`, Keystore, `key.properties`,
> `google-services.json` und Service-Account-Dateien sind ausgeschlossen.

---

## 9 · Emulator für die Rules-Tests (optional, aber empfohlen)

Die Security Rules werden gegen den Firestore-Emulator getestet. Der Test
liegt unter `functions/test/rules.test.ts`.

```bash
cd functions
npm install
npm run test:rules
```

Der Befehl startet den Emulator selbst (`firebase emulators:exec`). Er braucht
Java (siehe Abschnitt 0).

---

## 10 · Rechtstexte eintragen (Phase 2.1)

Die App bringt die Struktur schon mit — es fehlen nur die Texte. Eingetragen
wird an **genau einer Stelle**:
`lib/features/legal/logic/rechtstexte.dart`.

☐ **10.1 Texte erzeugen und veröffentlichen**

Datenschutzerklärung, Nutzungsbedingungen und Impressum aus deinem Generator
holen und unter drei öffentlichen Adressen ablegen (eigene Domain, GitHub
Pages, Notion — Hauptsache ohne Login erreichbar).

> **Play verlangt zwingend eine öffentliche URL zur Datenschutzerklärung.**
> Sie wird im Store-Eintrag hinterlegt und von der Prüfung aufgerufen. Ein
> Text, der nur in der App liegt, reicht nicht.

**Was inhaltlich hineingehört, steht in `store/rechtstexte-bausteine.md`** —
Abschnitt für Abschnitt, jeweils mit der Stelle im Code, an der der
Sachverhalt nachprüfbar ist. Gib die Datei deinem Generator oder deiner
Anwältin mit; sie beantwortet die Fragen, die dort sonst gestellt werden.

☐ **10.2 Adressen im Code eintragen**

In `rechtstexte.dart` die auskommentierten Zeilen ausfüllen:

```dart
Rechtsdokument.datenschutz: Rechtsquelle(
  url: 'https://deine-domain.de/datenschutz',
),
```

☐ **10.3 Optional: Texte zusätzlich in die App legen**

Für den Offline-Fall die Markdown-Fassungen unter `assets/rechtstexte/`
ablegen, in `pubspec.yaml` unter `assets:` eintragen und in `rechtstexte.dart`
zusätzlich als `asset:` referenzieren. Die App öffnet dann bevorzugt die
Webseite und fällt auf den mitgelieferten Text zurück, wenn kein Netz da ist.

☐ **10.4 Textversion erhöhen**

```dart
static const String version = '1';
```

Das `-entwurf` muss weg — daran erkennt die App, dass die Texte verbindlich
sind. Die Versionsnummer wird bei jeder Einwilligung mitgespeichert; erhöhst
du sie später, holt die App die Einwilligung erneut ein.

☐ **10.5 Prüfen**

```bash
dart run tool/rechtstexte_pruefen.dart
```

Das Skript endet mit Fehlercode, solange etwas fehlt. Es gehört vor jeden
Release-Build.

---

## 11 · Web-Löschpfad für Konten (Phase 2.3)

Google verlangt für Apps mit Konten einen Löschweg, der **ohne die App**
erreichbar ist — jemand, der die App schon deinstalliert hat, muss sein Konto
trotzdem loswerden können. Eine einfache Webseite genügt; die URL wird in der
Play Console unter **Richtlinien → App-Inhalte → Datenlöschung** hinterlegt.

☐ **11.1 Seite anlegen**

Irgendwo unter derselben Domain wie die Rechtstexte, z. B.
`https://deine-domain.de/konto-loeschen`. Vorlage zum Übernehmen:

---

> # Konto und Daten löschen
>
> Du kannst dein TrueGlow-Konto jederzeit selbst löschen — entweder in der App
> oder per E-Mail.
>
> ## In der App
>
> 1. TrueGlow öffnen
> 2. **Einstellungen** (Zahnrad unten rechts)
> 3. **Konto endgültig löschen** antippen und bestätigen
>
> Willst du nur neu anfangen, aber dein Konto behalten, wähle stattdessen
> **Daten löschen, Konto behalten**.
>
> ## Ohne die App
>
> Schreib eine E-Mail an **loeschung@deine-domain.de** von der Adresse, mit
> der du dich angemeldet hast. Wir löschen dein Konto innerhalb von 30 Tagen
> und bestätigen dir das per E-Mail.
>
> Hast du dich ohne Konto angemeldet („Erst ausprobieren"), gibt es keine
> Adresse, über die wir dich zuordnen können — diese Daten hängen
> ausschließlich an deinem Gerät und verschwinden, sobald du die App
> deinstallierst.
>
> ## Was gelöscht wird
>
> - dein Konto (Anmeldung über Google bzw. Apple)
> - alle Analysen, dein Plan, deine Serie und deine Check-in-Historie
>
> ## Was ohnehin nie bei uns lag
>
> Deine Fotos. Sie bleiben auf deinem Gerät und gehen nur für die Dauer einer
> Auswertung an den KI-Dienst, der sie nicht speichert. Beim Deinstallieren
> der App verschwinden sie mit.
>
> ## Aufbewahrung
>
> Nach der Löschung bleibt nichts erhalten. Ausgenommen sind Abrechnungs-
> unterlagen, sofern es Käufe gab — die müssen wir gesetzlich zehn Jahre
> aufbewahren.

---

☐ **11.2 Adresse einrichten**

Eine E-Mail-Adresse für Löschanfragen anlegen (Weiterleitung genügt) und in
der Vorlage eintragen.

☐ **11.3 In der Play Console hinterlegen**

**Richtlinien → App-Inhalte → Datenlöschung** → URL eintragen und angeben,
dass die Löschung auch in der App möglich ist.

☐ **11.4 In der Datenschutzerklärung verlinken**

Der Löschweg gehört auch in die DSE (Abschnitt 10).

---

## 12 · Release-Build (Phase 2.6)

### 12.1 Keystore erzeugen — einmalig, und dann für immer

☐ **Schlüssel anlegen**

```bash
keytool -genkey -v -keystore trueglow-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias trueglow
```

Leg die Datei **außerhalb des Projektordners** ab, etwa unter
`C:/Users/DEIN-NAME/schluessel/`. Im Repo hat sie nichts zu suchen.

> ## ⚠️ Keystore und Passwörter sichern
>
> **Verlierst du diese Datei oder das Passwort, kannst du deine App nie wieder
> aktualisieren.** Das kann niemand reparieren, Google auch nicht. Eine neue
> App mit neuer ID wäre der einzige Ausweg — ohne Bewertungen, ohne
> Installationen, ohne Käufe.
>
> Mach jetzt zwei Kopien an zwei verschiedenen Orten (Passwortmanager,
> verschlüsselter Cloud-Speicher, USB-Stick im Schrank). Die Passwörter
> gehören in den Passwortmanager, nicht in eine Textdatei daneben.
>
> Wenn du in der Play Console **Play App Signing** aktivierst — und das
> solltest du —, verwahrt Google zusätzlich den Signaturschlüssel. Der
> Upload-Schlüssel hier bleibt trotzdem deiner, und ohne ihn kommt kein
> Update mehr in die Konsole.

☐ **`android/key.properties` anlegen**

`android/key.properties.example` kopieren und ausfüllen:

```properties
storeFile=C:/Users/DEIN-NAME/schluessel/trueglow-release.jks
storePassword=dein-store-passwort
keyAlias=trueglow
keyPassword=dein-key-passwort
```

Schrägstriche auch unter Windows. Die Datei ist über `.gitignore`
ausgeschlossen — prüf das einmal mit `git status`, bevor du committest.

☐ **SHA-1 des Release-Keystores in Firebase eintragen**

```bash
keytool -list -v -keystore trueglow-release.jks -alias trueglow
```

SHA-1 und SHA-256 in die Firebase-App eintragen (Abschnitt 3.2), sonst
schlägt Google Sign-In im Release fehl. Sobald Play App Signing aktiv ist,
zusätzlich den dort angezeigten Fingerprint eintragen
(**Play Console → Release → Setup → App-Integrität**).

### 12.2 App Bundle bauen

☐ **Vorher: Rechtstexte prüfen**

```bash
dart run tool/rechtstexte_pruefen.dart
```

☐ **Bauen**

```bash
flutter build appbundle --release
```

Das Ergebnis liegt unter `build/app/outputs/bundle/release/app-release.aab`.

> Fehlt `key.properties`, bricht der Build mit einer Erklärung ab. Das ist
> Absicht: Ein debug-signiertes Bundle lehnt Play ohnehin ab, und der Fehler
> soll hier auffallen statt erst nach dem Upload.

☐ **`targetSdk` gegen die Play-Anforderung prüfen**

Im Projekt steht `targetSdk = 36` (`android/app/build.gradle.kts`). Play
verlangt beim Upload einen Mindestwert, der **jedes Jahr steigt**. Steht in
der Console eine höhere Zahl, hier anheben, neu bauen und Abschnitt 12.3
komplett wiederholen — ein höheres `targetSdk` ändert Systemverhalten.

### 12.3 Vollständiger Durchlauf im Release-Build

Nicht optional. `minifyEnabled` entfernt Code, den R8 für unbenutzt hält —
was über Reflexion gefunden wird, sieht R8 nicht. Solche Fehler treten
**ausschließlich** im Release auf, und ein erfolgreicher Compile sagt darüber
nichts.

☐ Build auf ein echtes Gerät bringen:

```bash
flutter build apk --release
flutter install --release
```

*(Für den Test genügt das APK; hochgeladen wird das App Bundle.)*

☐ Diesen Weg einmal komplett gehen und auf Abstürze achten:

1. App frisch installieren, Onboarding durchlaufen, **beide** Einwilligungen
2. Mit Google anmelden — prüft Signatur-Fingerprint und App Check
3. Kamera öffnen, Live-Gesichtserkennung im Sucher beobachten — prüft ML Kit
   unter R8, der wahrscheinlichste Ausfall
4. Ein Foto aus der Galerie importieren
5. Analyse starten und Report öffnen — prüft Cloud Function und Firestore
   ⚠️ **Nicht mit einem seitlich installierten APK.** Siehe Kasten unten.
6. Habit abhaken, App schließen, neu öffnen: Haken noch da? — prüft Hive
7. Check-in-Erinnerung: Gerät neu starten, Benachrichtigung kommt trotzdem —
   prüft `RECEIVE_BOOT_COMPLETED` und den Receiver unter R8
8. Einstellungen → Rechtliches → ein Dokument öffnen — prüft `url_launcher`
9. Einstellungen → Daten löschen, Konto behalten
10. Neu anmelden, Einstellungen → Konto endgültig löschen

> ## ⚠️ App Check im Release: Schritt 5 geht nur über einen Play-Track
>
> Im Release-Build läuft App Check über **Play Integrity**
> (`lib/core/firebase/firebase_start.dart`). Play Integrity erkennt nur
> Installationen, die **über Google Play** kamen. Ein per `flutter install
> --release` oder `adb install` aufgespieltes APK bekommt deshalb kein
> gültiges App-Check-Token — und die Cloud Function lehnt den Aufruf ab.
>
> Das gilt **unabhängig von Abschnitt 4.4**: Die Functions tragen
> `enforceAppCheck: true` fest im Code (`functions/src/index.ts`), die
> Konsolen-Einstellung ist nur eine zweite Schicht davor.
>
> Der Debug-Provider aus 4.3 hilft hier nicht — der läuft nur unter
> `kDebugMode`, und ein Release-Build ist genau das nicht.
>
> **Konsequenz für den Testplan:** Die Punkte 1, 2, 4 und 6–10 lassen sich mit
> dem seitlich installierten APK prüfen. **Punkt 5 (Analyse) und alles, was
> Firestore schreibt, gehören in einen echten Play-Track** — geschlossener
> oder interner Test, siehe ROADMAP 2.8. Plane das mit ein, statt am Gerät zu
> suchen, warum die Analyse „im Release plötzlich kaputt" ist.
>
> Der ML-Kit-Test unter R8 (Punkt 3) ist davon nicht betroffen und bleibt der
> wichtigste Grund, das APK trotzdem lokal zu testen.

☐ Bei einem Absturz den Stacktrace lesbar machen:

```bash
flutter symbolize -i absturz.txt -d build/app/outputs/symbols
```

Die R8-Mapping-Datei liegt unter
`build/app/outputs/mapping/release/mapping.txt`. **Heb sie zu jedem
veröffentlichten Build auf** — ohne sie ist kein Absturzbericht lesbar.

### 12.4 Version setzen

Schema und Regeln stehen in `DECISIONS.md`, Abschnitt 24. Kurz:
`version: 1.0.0+1` in `pubspec.yaml` — links SemVer, rechts eine fortlaufende
Zahl, die **bei jedem Upload steigen muss**, auch bei einem korrigierten
Build derselben Version.

---

## 13 · Markenauftritt neu erzeugen (Phase 2.7)

Icon und Splash sind fertig im Repo — dieser Abschnitt braucht dich nur, wenn
du das Motiv oder die Farben änderst.

Die Grafiken werden **generiert**, nicht gezeichnet. Die Geometrie steht an
genau einer Stelle: `tool/marke_erzeugen.dart`. Von dort fallen sechs
Fassungen heraus, dazu die SVG-Quelle.

☐ **13.1 Nach einer Änderung neu erzeugen**

```bash
dart run tool/marke_erzeugen.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Der erste Befehl schreibt `assets/branding/`, die beiden anderen verteilen
das Ergebnis nach `android/app/src/main/res/` und
`ios/Runner/Assets.xcassets/`.

> `flutter_native_splash:create` überschreibt `values-night/styles.xml` und
> setzt dort `windowBackground` zurück. Danach prüfen, ob im dunklen
> `LaunchTheme` weiterhin `@drawable/launch_background` steht — sonst startet
> die App im Dark Mode auf der hellen Fläche.

☐ **13.2 Was wohin gehört**

| Datei | Verwendung |
|---|---|
| `app_icon.png` (1024) | iOS-Icon, klassisches Android-Icon |
| `app_icon_vordergrund.png` | adaptives Icon (Vorder- und Monochrom-Ebene) |
| `store_icon_512.png` | **Play-Konsole, Store-Eintrag** |
| `splash_hell.png` / `splash_dunkel.png` | Splash bis Android 11 und iOS |
| `splash_android12_*.png` | Splash-API ab Android 12 |
| `app_icon.svg` | Quelle zum Weiterbearbeiten — **wird mitgeneriert**, Änderungen darin gehen beim nächsten Lauf verloren |

☐ **13.3 Feature-Grafik 1024 × 500**

Die verlangt Play zusätzlich, und sie ist Gestaltungsarbeit, keine Ableitung
aus dem Icon. Kommt mit dem Store-Eintrag (Phase 5.1).

☐ **13.4 Auf dem Gerät ansehen**

Icons und Splash zeigen sich erst nach einer Neuinstallation — Android
speichert das Launcher-Icon zwischen.

```bash
flutter run --uninstall-first
```

Ansehen: Icon im Launcher (rund, eckig und als Tropfen, je nach Gerät),
Splash beim Kaltstart in beiden Systemschemata.

---

## 14 · Crashlytics und Analytics freischalten (Phase 4.3)

Der Code ist fertig und standardmäßig **aus** — er springt erst an, wenn
jemand in den Einstellungen zustimmt. In der Firebase-Konsole müssen die
beiden Dienste trotzdem einmal eingeschaltet werden, sonst kommt nichts an.

☐ **14.1 Crashlytics einschalten**

1. Firebase-Konsole → **Release und Monitoring → Crashlytics**
2. **Crashlytics aktivieren** — die Einrichtungsschritte der Konsole kannst du
   überspringen, das SDK ist schon eingebunden
3. Die Konsole wartet auf den ersten Bericht (Schritt 14.4)

☐ **14.2 Analytics einschalten**

Google Analytics war beim Anlegen des Projekts bewusst aus (Abschnitt 1.1),
weil es vorher in der Datenschutzerklärung stehen musste. Jetzt steht es dort:

1. Firebase-Konsole → Zahnrad → **Projekteinstellungen** → Reiter
   **Integrationen**
2. **Google Analytics** → **Aktivieren** → Konto auswählen oder anlegen
3. Datenaufbewahrung prüfen: **Analytics-Konsole → Verwaltung →
   Datenaufbewahrung**. Der Standard sind 2 Monate; mehr braucht ein Funnel
   nicht, und weniger Aufbewahrung ist die datensparsamere Antwort.

☐ **14.3 `google-services.json` neu herunterladen**

Analytics ergänzt Werte in der Datei. Ohne den neuen Stand meldet die App
nichts.

1. **Projekteinstellungen → Allgemein → Deine Apps → google-services.json**
2. Nach `android/app/google-services.json` legen

☐ **14.4 Prüfen, dass wirklich nur mit Einwilligung gesendet wird**

Das ist der Punkt, der zählt — die Zusage steht in der Datenschutzerklärung.

1. App frisch installieren, Onboarding durchlaufen, **„Absturzberichte und
   Nutzungsstatistik" nicht ankreuzen**
2. Ein paar Schritte gehen: Analyse starten, Plan öffnen
3. Firebase-Konsole → **Analytics → Echtzeit**: Es darf **nichts** erscheinen
4. Jetzt in den Einstellungen zustimmen, dieselben Schritte wiederholen
5. Jetzt müssen die Ereignisse in der Echtzeit-Ansicht auftauchen

> Analytics-Ereignisse brauchen bis zu einer Minute. Die Echtzeit-Ansicht ist
> der schnellste Weg; die normalen Berichte kommen erst am Folgetag.

☐ **14.5 Einen echten Absturzbericht erzeugen**

Crashlytics zeigt erst etwas, wenn ein Absturz **hochgeladen** wurde — und das
passiert beim nächsten App-Start, nicht sofort.

1. Mit erteilter Einwilligung: einen Absturz auslösen. Am einfachsten über die
   Dart-Konsole während `flutter run`:
   `FirebaseCrashlytics.instance.crash()` — oder testweise vorübergehend einen
   Knopf damit belegen.
2. App neu starten
3. Firebase-Konsole → **Crashlytics**: Der Bericht erscheint nach wenigen
   Minuten

☐ **14.6 Kontrollieren, dass keine Kennungen im Bericht stehen**

Öffne den Bericht und such nach deiner uid und deiner E-Mail-Adresse. Beides
darf nicht vorkommen: Fehlermeldungen laufen vorher durch `bereinige()`
(`lib/core/diagnose/bereinigung.dart`).

Findest du doch etwas, gehört das Muster in diese Datei — und ein Testfall in
`test/diagnose_test.dart` dazu.

☐ **14.7 Nach dem Release-Build: Mapping-Datei**

Der Crashlytics-Gradle-Plugin lädt die R8-Mapping-Datei automatisch hoch
(`mappingFileUploadEnabled = true`). Nach dem ersten Release-Build in der
Crashlytics-Konsole prüfen, ob die Stacktraces lesbare Klassennamen zeigen.
Tun sie das nicht, ist der Upload nicht gelaufen — dann hilft die Datei unter
`build/app/outputs/mapping/release/mapping.txt`, die du ohnehin archivierst
(Abschnitt 12.3).

---

## Offen, sobald es soweit ist

Diese Punkte gehören zu späteren Phasen und stehen hier nur als Merkposten:

- Play-Entwicklerkonto anlegen (25 $) und geschlossenen Test starten — die
  14-Tage-Uhr läuft unabhängig vom Code, siehe ROADMAP 2.8
- Datenschutzerklärung, AGB, Impressum als öffentliche URLs (ROADMAP 2.1)
- Eigener Keystore und `android/key.properties` (ROADMAP 2.6)
- Web-Löschpfad für Konten (ROADMAP 2.3)
