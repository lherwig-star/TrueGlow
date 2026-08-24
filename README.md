# GlowUp

Self-Improvement-App für Android (Flutter). Der Nutzer fotografiert sein Gesicht
(frontal + Seitenprofil), eine Vision-KI analysiert die Fotos und erstellt einen
personalisierten, konstruktiven Verbesserungsplan für Hautpflege, Frisur, Bart,
Styling und Habits.

**Keine Attraktivitäts-Scores, keine Ratings** – nur konkrete, umsetzbare Tipps.

---

## Setup

1. **Flutter installieren** (Version 3.47 oder neuer, Channel `stable`)
   → https://docs.flutter.dev/get-started/install
   Prüfen mit:

   ```bash
   flutter doctor
   ```

2. **Abhängigkeiten holen**

   ```bash
   flutter pub get
   ```

3. **`.env` anlegen** – die Datei ist bereits vorhanden (aus `.env.example`
   kopiert) und steht in `.gitignore`. Für echte API-Calls den Key eintragen:

   ```
   GEMINI_API_KEY=dein_key_hier
   ```

   Key gibt es kostenlos im [Google AI Studio](https://aistudio.google.com/apikey).

4. **App starten**

   ```bash
   flutter run
   ```

> **Ohne API-Key testen:** Der `AnalysisService` läuft standardmäßig im
> Mock-Modus (`useMockData = true`). Es wird kein API-Call gemacht, stattdessen
> kommt nach 2 Sekunden eine fest hinterlegte Beispiel-Antwort zurück. Die
> komplette App ist damit ohne Key und ohne Kosten durchspielbar.

---

## Architektur-Überblick

```
lib/
├─ main.dart                    App-Einstieg: .env laden, Hive öffnen, App starten
├─ core/
│  ├─ theme/app_colors.dart     Farbrollen beider Schemata (ThemeExtension)
│  ├─ theme/app_theme.dart      Themes hell/dunkel, Radien, Abstände, Typografie
│  ├─ theme/theme_controller.dart  Auswahl Hell/Dunkel/System, lokal gespeichert
│  ├─ l10n/app_strings.dart     Alle UI-Texte zentral (Vorstufe zu ARB)
│  ├─ router/app_router.dart    go_router: Routen + Onboarding-Redirect
│  ├─ storage/                  Hive-Setup und KeyValueStore-Abstraktion
│  ├─ utils/datum.dart          Deutsche Datumsformate ohne intl
│  └─ widgets/                  Wiederverwendbare Bausteine (AppPage, SectionCard)
└─ features/
   ├─ onboarding/               Fragen, Datenschutz-Zustimmung
   ├─ home/                     Dashboard
   ├─ modules/                  Analyse-Module: Auswahl, Zusatzangaben
   ├─ streak/                   Tages-Serie, Abzeichen, Jubel-Moment
   ├─ capture/                  In-App-Kamera, Aufnahme-Flow + Qualitätscheck
   ├─ analysis/                 Ladezustand während des API-Calls
   ├─ result/                   Analyse-Ergebnis in Sektionen
   ├─ plan/                     Step-by-Step-Plan + Tages-Checkliste
   ├─ history/                  Vergangene Analysen
   └─ settings/                 Erscheinungsbild, Angaben ändern, Daten löschen
```

Jedes Feature ist in `ui/` (Widgets), `logic/` (Controller, Services) und
`models/` (Datenklassen) getrennt.

**Technische Eckpunkte**

| Thema            | Entscheidung                                          |
| ---------------- | ----------------------------------------------------- |
| State Management | Riverpod (`flutter_riverpod`)                         |
| Navigation       | `go_router`, Routen als Konstanten in `Routes`         |
| Lokale Daten     | Hive (Analysen, Plan, Checklisten-Fortschritt)         |
| Foto-Check       | Google ML Kit Face Detection, **on-device**            |
| Vision-KI        | austauschbarer Provider, Standard: Google Gemini       |
| Backend          | keins – Version 1 läuft vollständig lokal              |
| Min. Android     | API-Level 26                                           |

---

## Foto-Qualitätscheck

Jede Aufnahme läuft **vor** dem API-Call durch den Check (on-device, ohne
Netzwerk). Die Schwellwerte stehen in
`lib/features/capture/logic/image_quality_service.dart` und
`lib/features/capture/models/aufnahme_typ.dart`:

Wie streng geprüft wird, hängt an der Aufnahme – der alte Pauschal-Check
(„genau ein Gesicht auf 25 % der Fläche") hätte Ganzkörper- und Outfit-Fotos
immer abgelehnt. Die Profile stehen in `Pruefprofil`:

| Profil          | Gesicht      | Mindestfläche | Gilt für                       |
| --------------- | ------------ | ------------- | ------------------------------ |
| `gesichtNah`    | Pflicht      | 25 %          | Frontal, Nahaufnahme, Lächeln  |
| `gesichtWeit`   | optional     | 8 %           | Profile links/rechts, 45°      |
| `ganzkoerper`   | nein         | –             | Ganzkörper frontal/seitlich    |
| `frei`          | nein         | –             | Outfit-Fotos                   |

Bei Profil und 45°-Winkel ist die Gesichtserkennung bei abgewandtem Kopf
unzuverlässig – deshalb kein Pflichtfeld. Wird doch ein Gesicht gefunden, muss
es grob die richtige Größe haben.

Unabhängig vom Profil gilt für jede Aufnahme:

| Prüfung             | Schwellwert                     | Konstante             |
| ------------------- | ------------------------------- | --------------------- |
| Bild lesbar         | Dekodierung erfolgreich         | –                     |
| Bild hell genug     | mittlere Helligkeit ≥ 55/255    | `minHelligkeit`       |
| Upload-Größe        | max. 1024 px, JPEG Qualität 80  | `maxKantenlaenge`     |

Schlägt eine Prüfung fehl, zeigt die App Titel **und** konkreten Tipp
(`PhotoProblem`) statt einer technischen Fehlermeldung. Erst wenn beide Fotos
bestanden haben, lässt sich die Analyse starten.

Dekodieren, Helligkeitsmessung und Komprimierung laufen in einem eigenen
Isolate (`compute`), damit die UI nicht einfriert. Die EXIF-Drehung wird beim
Komprimieren fest ins Bild gerechnet.

---

## Analyse-Module

Vor der Aufnahme stellt der Nutzer zusammen, was analysiert werden soll. Die
Basis ist gesetzt, alles andere ist wählbar und lässt sich später ergänzen.

| Modul                  | Aufnahmen und Eingaben                                   |
| ---------------------- | -------------------------------------------------------- |
| Gesicht, Haare & Bart  | Frontal, Profil links, Profil rechts, 45°-Winkel (Basis) |
| Haut & Farbtyp         | 1 Nahaufnahme bei Tageslicht                              |
| Zähne & Lächeln        | 1 Foto lächelnd                                           |
| Figur & Passform       | 2 Ganzkörperfotos + Körpergröße und Gewicht               |
| Stil & Kleiderschrank  | 2–3 Outfit-Fotos + kurzer Fragebogen                      |

**Dynamischer Flow**: `baueAufnahmeFlow()` in
`lib/features/capture/logic/aufnahme_flow.dart` baut aus der Auswahl die
Schrittliste – Lichtcheckliste, Modul-Hinweise, Fotos, Formulare. Die
Fortschrittsanzeige („Schritt 3 von 7") zählt genau diese Schritte, passt sich
also der Auswahl an. Optionale Aufnahmen (das dritte Outfit) blockieren den
Flow nicht.

**Nachträglich erweitern**: Auf dem Ergebnis-Screen listet „Analyse erweitern"
die noch offenen Module. Ein Tipp startet nur deren Aufnahmen – die Basis-Fotos
sind gespeichert und gehen als Kontext mit an das Modell, ohne neu aufgenommen
zu werden. Das Ergebnis wird über `AnalysisResult.mitKapitel()` eingehängt:
bestehende Kapitel bleiben unverändert, der Plan wird ohne Dubletten ergänzt.

**Report und Checklisten**: Ein Kapitel pro Modul, in Modul-Reihenfolge. Nicht
gewählte Module tauchen nicht auf. Die täglichen Checklisten-Punkte hängen am
**Kapitel**, nicht am Plan (`Kapitel.habits`) – dadurch kann per Konstruktion
keine Aufgabe eines nicht gewählten Moduls in der Checkliste landen. Startseite
und Plan zeigen entsprechend eine Karte pro Kapitel (`ChecklisteKarte`), jede
mit 4–7 abhakbaren Punkten. Mehr gewählte Module bedeuten damit immer mehr
Checklisten-Inhalt, nie weniger. Analysen aus der Zeit vor den Modulen haben `sektionen` noch
auf oberster Ebene – die werden beim Lesen als Basis-Kapitel interpretiert,
damit gespeicherte Verläufe nicht kaputtgehen.

---

## Streak & Abzeichen

Eine Gamification-Ebene über den Tages-Checklisten (`lib/features/streak/`).

**Streak**: Ein Tag zählt als geschafft, sobald mindestens eine Aufgabe
abgehakt ist – umschaltbar über die Konstante `StreakRepository.tagesziel`
(`Tagesziel.eineAufgabe` / `alleAufgaben`). Die Serie wird bewusst **immer neu
aus den Tagesdaten abgeleitet** statt nur fortgeschrieben: damit stimmt sie
auch, wenn die App tagelang zu war, und der Reset passiert schon beim Laden
statt erst beim nächsten Abhaken. Persistiert werden aktueller Streak, Rekord
und letzter geschaffter Tag; der Rekord überlebt jedes Zurücksetzen und steht
in der Abzeichen-Sektion als „Rekord: X Tage".

Ein noch leerer heutiger Tag reißt die Serie nicht ab – erst ein komplett
verpasster Tag setzt sie auf 0. Tageswechsel um Mitternacht lokaler Zeit.

**Anzeige**: Flamme plus Zahl oben auf Startseite und Plan. Solange heute
nichts abgehakt ist, bleibt die Flamme gedimmt; beim ersten Haken des Tages
flackert sie kurz auf.

**Abzeichen**: Sechs Streak-Meilensteine (3/7/14/30/60/90 Tage) plus „Erste
Analyse geschafft" und „Alles freigeschaltet". Beim Erreichen erscheint einmalig
ein Jubel-Overlay mit Konfetti; welche Abzeichen schon gefeiert wurden, steht im
gespeicherten Stand.

**Reduced Motion**: Ist die Systemeinstellung aktiv
(`MediaQuery.disableAnimationsOf`), entfallen Konfetti und Flammen-Puls – der
Jubel blendet dann statisch ein.

---

## In-App-Kamera mit Positionierungshilfe

Die Aufnahme läuft nicht mehr über die System-Kamera, sondern über eine eigene
Vollbild-Vorschau (`lib/features/capture/ui/camera_screen.dart`). Über dem
Livebild liegt die Hilfslinie – je nach Aufnahme ein Kopf-Oval, eine
Seitenkopf-Kontur (nach links oder rechts gespiegelt) oder ein
Ganzkörper-Rahmen.

Die Overlay-Typen sind nach der **Nasenrichtung** benannt, nicht nach dem
Profilnamen: Die Frontkamera-Vorschau spiegelt, deshalb gehört zum *linken*
Profil (linke Gesichtshälfte zur Kamera, Kopf dreht nach rechts) eine nach
rechts zeigende Nase. Die Profil-Kontur trägt eine spitz herausstehende Nase
und einen C-förmigen Ohrbogen **innerhalb** der Silhouette – Nase außen, Ohr
innen macht die Blickrichtung eindeutig. Dazu kommt ein durchgezogener
Drehpfeil über dem Kopf (bewusst nicht gestrichelt, sonst zerfällt die
Pfeilspitze optisch).

Das Kopf-Oval hat ein Breite-zu-Höhe-Verhältnis von **0,72** und richtet seine
Breite an der Höhe aus, nicht an der Bildbreite – sonst wird es auf schmalen
Geräten langgezogen. Der Mittelpunkt sitzt bei 42 % der Bildhöhe: oben bleibt
Platz für die Anleitung, unten für Hals und Schultern. Die Schulterlinien sind
am Oval verankert und wachsen mit.

Rund viermal pro Sekunde geht ein Vorschau-Frame durch ML Kit. Auf Android
liefert das `camera`-Plugin die Frames direkt als **NV21**, das ML Kit ohne
Umbau liest; die Bildgröße in den Metadaten ist die des *aufgerichteten*
Bildes, weil ML Kit die Gesichtsboxen in genau diesem System zurückgibt.

Die Bewertung selbst steckt in `logic/live_face_guide.dart` und arbeitet nur
mit Rechtecken – ohne Kamera und ohne ML Kit testbar:

| Situation                        | Rückmeldung                        |
| -------------------------------- | ---------------------------------- |
| kein Gesicht                      | „Positioniere dein Gesicht im Rahmen" |
| Fläche < 28 %                     | „Geh näher ran"                    |
| Fläche > 62 %                     | „Etwas weiter weg"                 |
| Mitte > 18 % daneben              | „Mittig positionieren"             |
| alles im Rahmen                   | „Perfekt – jetzt auslösen"         |

Die Untergrenze liegt bewusst **über** den 25 % des finalen Qualitätschecks,
damit ein „Perfekt" den Check danach auch besteht.

Der Auslöser ist immer drückbar – die Live-Erkennung hilft nur beim
Positionieren, entschieden wird weiterhin im Qualitätscheck. Ohne
Kameraberechtigung zeigt der Screen einen Hinweis mit Button in die
App-Einstellungen; der Galerie-Import bleibt in beiden Fällen offen.

---

## Farbschemata

Zwei gleichwertige Schemata, umschaltbar unter *Einstellungen →
Erscheinungsbild* (Hell / Dunkel / System, Standard dunkel):

| Rolle             | Dunkel „Champagne & Charcoal" | Hell „Mocha Light" |
| ----------------- | ----------------------------- | ------------------ |
| Hintergrund        | `#181512`                     | `#F7F2E9`          |
| Karten             | `#242019`                     | `#EFE7D8`          |
| Primär-Akzent      | `#D6C7A9`                     | `#6B4F3A`          |
| Sekundär-Akzent    | `#B08D57`                     | `#A8794F`          |
| Text primär        | `#F5F0E6`                     | `#2B241C`          |
| Warnung            | `#C96F4A`                     | `#B85C3A`          |

Alle Farben liegen als `ThemeExtension` in `core/theme/app_colors.dart` und
werden über `context.farben` gelesen – in keinem Widget steht ein Farbwert.
Die Auswahl wird in derselben Hive-Box gespeichert wie die übrigen
Einstellungen und wirkt ohne Neustart.

---

## Analyse-Pipeline

`lib/features/analysis/logic/`:

| Datei                        | Aufgabe                                             |
| ---------------------------- | --------------------------------------------------- |
| `analysis_service.dart`      | Interface, `AnalysisConfig`, Fehlerfälle             |
| `analysis_prompt.dart`       | System-Prompt inkl. Schema und Leitplanken           |
| `gemini_analysis_service.dart` | HTTP-Aufruf, Retry, Fehler-Mapping                 |
| `mock_analysis_service.dart` | Fest hinterlegte Beispiel-Antwort                    |
| `json_extractor.dart`        | JSON aus der Modellantwort herausschälen             |
| `analysis_controller.dart`   | Fotos + Profil → Service → lokale Speicherung        |

**Robustheit gegen unsaubere Antworten**: Der `JsonExtractor` versucht drei
Wege – direktes Parsen, Markdown-Codefences entfernen, den äußersten
`{...}`-Block herausschneiden (Klammern in Strings werden dabei übersprungen).
Scheitert das oder ist die Antwort inhaltlich unvollständig, geht **ein**
Retry raus mit dem Zusatz „antworte nur mit validem JSON".

**Fehlerbehandlung**: Timeout, kein Internet, HTTP 429, HTTP 401/403 und
sonstige API-Fehler werden auf `AnalysisFehler` abgebildet – jeder Fall mit
eigenem Titel und Handlungstipp im Ladescreen, plus Retry-Button.

Der API-Key geht als `x-goog-api-key`-Header raus, nicht als Query-Parameter,
damit er nicht in Logs oder Proxy-Historien landet.

---

## Vision-Modell wechseln

Der `AnalysisService` ist gegen ein Interface programmiert, das Modell und
Provider stecken in Konstanten. Zum Wechseln:

1. In `AnalysisConfig` die Konstante `modell` anpassen
   (z. B. ein anderes Gemini-Modell).
2. Für einen komplett anderen Anbieter: eine neue Implementierung des
   `AnalysisService`-Interfaces anlegen und in `analysisServiceProvider`
   eintragen. Das JSON-Antwortschema bleibt unverändert – die UI muss nicht
   angefasst werden.
3. Passenden API-Key in `.env` hinterlegen und `useMockData` auf `false`
   setzen. Die Einstellungen zeigen an, welcher Modus gerade aktiv ist.

---

## Lokale Speicherung

Drei Hive-Boxen, alle Inhalte als JSON-String (keine generierten TypeAdapter,
kein `build_runner`):

| Box             | Inhalt                                            |
| --------------- | ------------------------------------------------- |
| `analysen`      | Analysen, Schlüssel ist die Analyse-ID            |
| `einstellungen` | Onboarding-Antworten, Verweis auf letzte Analyse  |
| `fortschritt`   | Abgehakte Habits pro Tag (`yyyy-mm-tt`)           |

Der Zugriff läuft über `KeyValueStore` statt direkt über `Box`. Das ist kein
Selbstzweck: Hive schreibt echte Dateien, und unter der gefakten Uhr in
Widget-Tests kommt so ein Schreibvorgang nie zurück – der Test hängt. Über die
Abstraktion bekommen Widget-Tests einen `MemoryStore`, während die
Hive-Implementierung in normalen Unit-Tests gegen echte Dateien geprüft wird.

**Streak**: Ein Tag zählt, sobald mindestens ein Habit abgehakt ist. Ein noch
leerer heutiger Vormittag beendet die Serie nicht – gezählt wird dann ab
gestern.

---

## Datenschutz

- Fotos werden ausschließlich für die Analyse an den KI-Dienst gesendet und dort
  nicht dauerhaft gespeichert.
- Alle Analysen, Pläne und Fortschritte liegen lokal auf dem Gerät.
- In den Einstellungen können sämtliche Daten unwiderruflich gelöscht werden (DSGVO).
- Die App ersetzt keine medizinische Beratung; bei Hautproblemen wird auf
  dermatologische Praxen verwiesen.

---

## Entwicklungsstand

- [x] **Schritt 1** – Projektgerüst, Theme, Navigation, alle Screens
- [x] **Schritt 2** – Foto-Flow inkl. ML-Kit-Qualitätscheck
- [x] **Schritt 3** – `AnalysisService` mit JSON-Schema und Fehlerbehandlung
- [x] **Schritt 4** – Ergebnis- und Plan-Screens mit lokaler Speicherung
- [x] **Schritt 5** – Verlauf, Einstellungen, Feinschliff

## Tests

```bash
flutter test
```

36 Tests, aufgeteilt in:

| Datei                      | Deckt ab                                          |
| -------------------------- | ------------------------------------------------- |
| `analysis_parsing_test`    | JSON-Extraktion, defensives Parsen, Mock-Service   |
| `storage_test`             | Repositories, Streak-Logik, Onboarding-Persistenz  |
| `capture_flow_test`        | Foto-Schrittlogik, Fehlerkarte                     |
| `widget_test`              | Onboarding-Durchlauf bis zum Dashboard             |
| `ende_zu_ende_test`        | Analyse → Speicherung → Dashboard → Checkliste     |

Widget-Tests setzen ein Handy-Viewport (`handyGroesse` in `test/hilfen.dart`) –
im Standard-Testfenster (800×600) liegt der 3:4-Sucher außerhalb der ListView
und alles darunter wird gar nicht erst gebaut.
