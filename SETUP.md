# SETUP — was du außerhalb des Codes erledigen musst

Diese Datei listet **alle manuellen Schritte**, die nicht im Code stehen können:
Konsolen-Klicks, Secrets, Fingerprints, Freischaltungen. Sie wird bei jedem
Arbeitspaket mitgepflegt.

**Konvention in dieser Datei**

- `☐` offen · `☑` erledigt (hak ab, wenn du es gemacht hast)
- Klickpfade stehen als `Menü → Untermenü → Schaltfläche`
- Alle CLI-Befehle laufen im Projektordner (`C:\Users\idont\Desktop\Face Analyse`),
  sofern nichts anderes dabeisteht

**Feste Projektwerte**

| Wert | Inhalt |
|---|---|
| Android-Paketname | `com.glowup.glowup` |
| iOS-Bundle-ID | `com.glowup.glowup` |
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
3. Name: `glowup` (die Projekt-ID darunter merken, z. B. `glowup-1a2b3`)
4. Google Analytics: **aus** — wird erst in Phase 4 gebraucht und muss vorher
   in der Datenschutzerklärung stehen
5. **Projekt erstellen**

☐ **1.2 Abrechnungskonto verknüpfen (Blaze-Tarif)**

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

☐ **2.1 `flutterfire configure` ausführen**

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

☐ **2.2 Kontrolle**

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

☐ **3.1 Debug-Fingerprint auslesen**

```bash
keytool -list -v -alias androiddebugkey -keystore "$USERPROFILE/.android/debug.keystore" -storepass android -keypass android
```

In PowerShell:

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Aus der Ausgabe die Zeilen `SHA1:` und `SHA256:` kopieren.

☐ **3.2 In Firebase eintragen**

1. Firebase-Konsole → Zahnrad → **Projekteinstellungen** → Reiter **Allgemein**
2. Karte **Deine Apps** → die Android-App `com.glowup.glowup`
3. **Fingerabdruck hinzufügen** → SHA-1 einfügen → Speichern
4. Dasselbe noch einmal mit SHA-256

☐ **3.3 `google-services.json` neu herunterladen**

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

☐ **4.1 Android registrieren (Play Integrity)**

1. Firebase-Konsole → **Build → App Check** → Reiter **Apps**
2. Android-App aufklappen → **Play Integrity** → **Speichern**

> Play Integrity funktioniert nur bei Builds, die über Google Play verteilt
> werden. Für lokale Debug-Builds nimmst du den Debug-Provider (4.3).

☐ **4.2 iOS registrieren (App Attest)** — erst wenn iOS gebaut wird, siehe Abschnitt 7

☐ **4.3 Debug-Token für die Entwicklung eintragen**

1. App im Debug-Modus einmal starten: `flutter run`
2. In der Konsolenausgabe nach einer Zeile suchen, die so aussieht:
   `Enter this debug secret into the allow list in the Firebase Console ...`
   gefolgt von einer UUID
3. Firebase-Konsole → **App Check** → Reiter **Apps** → Android-App →
   Dreipunkt-Menü → **Debug-Tokens verwalten** → **Debug-Token hinzufügen**
4. UUID einfügen, Name z. B. `Laptop Debug`, **Speichern**

☐ **4.4 Erzwingen einschalten — erst zum Schluss**

1. Firebase-Konsole → **App Check** → Reiter **APIs**
2. **Cloud Functions** → **Erzwingen**
3. Ebenso für **Cloud Firestore**

> Erst einschalten, wenn ein echter Durchlauf mit Debug-Token funktioniert hat
> (Abschnitt 6). Vorher sperrst du dich selbst aus.

---

## 5 · Gemini-Key, Cloud Functions, Budget

☐ **5.1 Gemini-API-Key erzeugen**

1. <https://aistudio.google.com/apikey> öffnen
2. **API-Schlüssel erstellen** → *im bestehenden Firebase-Projekt* (dann läuft
   die Abrechnung über dasselbe Cloud-Projekt)
3. Schlüssel kopieren — er wird gleich in den Secret Manager gelegt und danach
   **nirgends sonst** gespeichert

> Der Schlüssel gehört **nicht** in `.env`, nicht in den Code und nicht in
> `firebase.json`. Die App bekommt ihn nie zu sehen.

☐ **5.2 Key als Secret hinterlegen**

```bash
firebase functions:secrets:set GEMINI_API_KEY --project DEINE-PROJEKT-ID
```

Der Befehl fragt den Wert interaktiv ab (Eingabe wird nicht angezeigt) und legt
ihn im Google Secret Manager an. Prüfen:

```bash
firebase functions:secrets:access GEMINI_API_KEY --project DEINE-PROJEKT-ID
```

☐ **5.3 Budget-Alarm einrichten — nicht überspringen**

1. <https://console.cloud.google.com/billing> → Rechnungskonto wählen
2. Links **Budgets und Benachrichtigungen** → **Budget erstellen**
3. Name: `GlowUp Monatsbudget`
4. Bereich: **Projekt** → das Firebase-Projekt auswählen
5. Betrag: z. B. **10 €** pro Monat (bei 3 Analysen/Tag pro Konto liegt der
   reale Verbrauch weit darunter — der Alarm ist gegen Missbrauch und Fehler)
6. Schwellen: 50 %, 90 %, 100 % — jeweils **E-Mail an Rechnungsadministratoren**
7. **Fertig**

☐ **5.4 Nötige APIs freischalten**

Beim ersten Deploy fragt die CLI danach; man kann es auch vorziehen:

```bash
gcloud services enable secretmanager.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com generativelanguage.googleapis.com --project DEINE-PROJEKT-ID
```

Ohne `gcloud` geht es auch per Klick über
<https://console.cloud.google.com/apis/library>.

☐ **5.5 Functions deployen**

```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions --project DEINE-PROJEKT-ID
```

Erwartete Ausgabe: zwei Funktionen `analysiere` und `checkinAuswerten` in
`europe-west3`.

☐ **5.6 Firestore-Regeln und -Indizes deployen**

```bash
firebase deploy --only firestore:rules,firestore:indexes --project DEINE-PROJEKT-ID
```

---

## 6 · Erster echter Durchlauf gegen die Live-API

Dieser Schritt steht ausdrücklich in der Roadmap („Echten Antwortpfad erstmals
gegen die Live-API prüfen") und kann **nur von dir** ausgeführt werden — er
braucht das Firebase-Projekt, den Key und ein Gerät mit Kamera.

☐ **6.1 App mit echtem Backend starten**

```bash
flutter run --dart-define=GLOWUP_MOCK=false
```

`GLOWUP_MOCK` ist standardmäßig `false`; der Schalter existiert, um den
Demo-/Screenshot-Modus gezielt einzuschalten (`--dart-define=GLOWUP_MOCK=true`).

☐ **6.2 Ablauf durchspielen**

1. Onboarding → Login („Erst ausprobieren" reicht) → Fotos → Analyse starten
2. In der Firebase-Konsole → **Functions → Protokolle** mitlesen
3. Prüfen: **keine** Bildinhalte in den Logs, nur Zähler und Fehlercodes

☐ **6.3 Abweichungen notieren**

Unterschiede zwischen Mock- und Realantwort in `DECISIONS.md` festhalten
(Abschnitt „Mock vs. Live"). Interessant sind vor allem: fehlende Felder,
abgeschnittene Antworten, Sicherheitsfilter, Antwortdauer.

☐ **6.4 Rate-Limit prüfen**

Vier Analysen an einem Tag starten — die vierte muss mit „Kontingent
erschöpft" abgelehnt werden, **ohne** dass ein Gemini-Aufruf stattfindet
(im Log sichtbar).

---

## 7 · iOS (kommt fest, Vorbereitung jetzt)

☐ **7.1 Apple-Developer-Programm** (99 $/Jahr) — <https://developer.apple.com/programs/>

☐ **7.2 Bundle-ID `com.glowup.glowup`** im Apple-Developer-Portal registrieren,
Capabilities **Sign in with Apple** und **App Attest** aktivieren

☐ **7.3 Sign in with Apple in Firebase aktivieren**

1. Firebase-Konsole → **Authentication → Sign-in method → Apple** → aktivieren
2. Services-ID, Team-ID, Key-ID und den `.p8`-Schlüssel aus dem
   Apple-Developer-Portal eintragen

> **Pflicht von Apple:** Sobald die iOS-App Google Sign-In anbietet, muss sie
> auch „Sign in with Apple" anbieten. Der Code ist darauf vorbereitet — es
> kommt nur ein weiterer Eintrag in `AuthAnbieter` dazu, kein Umbau.

☐ **7.4 Xcode-Projekt**: Signing-Team setzen, Capability
**Sign in with Apple** hinzufügen, `GoogleService-Info.plist` ins Runner-Target
ziehen

☐ **7.5 URL-Schema für Google Sign-In**: den Wert `REVERSED_CLIENT_ID` aus
`GoogleService-Info.plist` in `ios/Runner/Info.plist` unter `CFBundleURLTypes`
eintragen (macht `flutterfire configure` nicht automatisch)

---

## 8 · Backup außerhalb des Rechners (Phase 0)

☐ **8.1 Privates Remote-Repo anlegen**

GitHub → **New repository** → Name `glowup` → **Private** → *ohne* README
anlegen. Danach:

```bash
git remote add origin https://github.com/DEIN-KONTO/glowup.git
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

## Offen, sobald es soweit ist

Diese Punkte gehören zu späteren Phasen und stehen hier nur als Merkposten:

- Play-Entwicklerkonto anlegen (25 $) und geschlossenen Test starten — die
  14-Tage-Uhr läuft unabhängig vom Code, siehe ROADMAP 2.8
- Datenschutzerklärung, AGB, Impressum als öffentliche URLs (ROADMAP 2.1)
- Eigener Keystore und `android/key.properties` (ROADMAP 2.6)
- Web-Löschpfad für Konten (ROADMAP 2.3)
