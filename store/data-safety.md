# Data-Safety-Formular — Ausfüllhilfe

Für **Play Console → Richtlinien → App-Inhalte → Datensicherheit**.

Jede Angabe hier ist aus dem **tatsächlichen Verhalten des Codes** abgeleitet,
nicht aus einer Absicht. Die Spalte „Woher" nennt die Stelle, an der es steht —
wenn du eine Angabe anzweifelst, schau dort nach.

> **Wichtig:** Das Formular muss zum Code passen. Ändert sich das Verhalten,
> ändert sich das Formular. Eine falsche Angabe ist ein Verstoß gegen die
> Play-Richtlinien, unabhängig davon, ob sie zu viel oder zu wenig behauptet.

---

## Vorab: die drei Sätze, aus denen alles Weitere folgt

1. **Fotos werden nicht bei uns gespeichert.** Sie liegen auf dem Gerät und
   gehen für die Dauer einer Auswertung durch unsere Cloud Function an Google
   Gemini. Danach sind sie weg — nicht in einem Speicher, nicht in einem Log.
   *Woher:* `functions/src/index.ts` (`bilder.length = 0` im `finally`),
   `functions/src/gemini.ts` (kein Logging der Bilddaten),
   `firestore.rules` (Dokumente mit `bilddaten`/`bilder` werden abgelehnt).

2. **In die Cloud geht nur, was einen Gerätewechsel überleben soll:**
   Ergebnisse, Plan, Serie, Richtung, Check-in-Historie, Einwilligungsnachweis.
   *Woher:* `lib/core/cloud/cloud_modell.dart`.

3. **Kein Tracking.** Keine Analytics, kein Crash-Reporting, keine Werbe-ID,
   kein Standort, keine Kontakte. *Woher:* `pubspec.yaml` — keines dieser
   Pakete ist eingebunden. (Crashlytics und Analytics kommen erst in Phase 4;
   dann muss dieses Formular angefasst werden.)

---

## Frage 1: Erhebt oder teilt deine App Nutzerdaten?

**Ja.**

## Frage 2: Sind alle Daten bei der Übertragung verschlüsselt?

**Ja.** Alles läuft über HTTPS bzw. die TLS-Verbindungen der Firebase-SDKs.
Es gibt keinen eigenen Endpunkt und keinen Klartext-Kanal.
*Woher:* `functions/src/gemini.ts` (https), `cloud_firestore`/`cloud_functions`
als einzige Netzwerkpfade der App.

## Frage 3: Können Nutzer die Löschung ihrer Daten verlangen?

**Ja.** Zwei Wege in der App (Daten löschen / Konto endgültig löschen) plus
ein Web-Löschpfad.
*Woher:* `lib/features/settings/ui/settings_screen.dart`,
`functions/src/konto.ts` (`recursiveDelete` über `users/{uid}`),
`SETUP.md` Abschnitt 11 (Webseite).

---

## Datentypen im Einzelnen

Für jeden Typ fragt das Formular: **erhoben?** · **geteilt?** ·
**Pflicht oder optional?** · **Zweck?** · **kurzlebig verarbeitet?**

### Personenbezogene Daten → Nutzer-IDs

| Feld | Angabe |
|---|---|
| Erhoben | **Ja** |
| Geteilt | Nein |
| Pflicht | **Erforderlich** (ohne Konto keine Analyse) |
| Zweck | App-Funktionalität, Kontoverwaltung |
| Kurzlebig | Nein |

Die Firebase-Auth-UID ist der Schlüssel jedes Dokuments.
*Woher:* `lib/features/auth/models/trueglow_nutzer.dart`,
`lib/core/cloud/cloud_speicher.dart` (`users/{uid}`).

### Personenbezogene Daten → Name, E-Mail-Adresse

| Feld | Angabe |
|---|---|
| Erhoben | **Ja** |
| Geteilt | Nein |
| Pflicht | **Optional** — nur bei Google-/Apple-Anmeldung |
| Zweck | Kontoverwaltung |
| Kurzlebig | Nein |

Wer „Erst ausprobieren" wählt, hinterlässt weder Namen noch Adresse.
*Woher:* `lib/features/auth/logic/firebase_auth_repository.dart`
(`displayName`, `email` aus dem Firebase-Konto).

### Fotos und Videos → Fotos

| Feld | Angabe |
|---|---|
| Erhoben | **Ja** |
| Geteilt | *siehe Kasten unten* |
| Pflicht | **Optional** (die Einwilligung ist getrennt und widerrufbar) |
| Zweck | App-Funktionalität |
| Kurzlebig verarbeitet | **Ja** |

> **Die Stelle, an der du selbst entscheiden musst.** Play zählt eine
> Weitergabe an einen **Dienstleister**, der ausschließlich für dich
> verarbeitet, nicht als „Teilen". Google Gemini wird hier über unsere eigene
> Cloud Function und mit einem eigenen Schlüssel gerufen, verarbeitet die
> Bilder nur für diesen Aufruf und speichert sie nicht — das spricht für
> „Dienstleister", also **geteilt: Nein**.
>
> Prüf das trotzdem gegen die aktuelle Play-Definition und gegen die
> Nutzungsbedingungen der Gemini-API, bevor du es so einträgst. Wenn du
> unsicher bist, ist „geteilt: Ja" die konservative Angabe — sie ist nie ein
> Verstoß, nur eine strengere Aussage.

„Kurzlebig verarbeitet" darfst du ankreuzen, weil die Bilder ausschließlich im
Arbeitsspeicher der Function existieren und nach dem Aufruf verworfen werden.
*Woher:* `functions/src/index.ts`, `functions/src/eingang.ts`
(base64 im Aufruf, kein Upload, kein Storage-Bucket im Projekt).

### Gesundheit und Fitness → Fitnessdaten

| Feld | Angabe |
|---|---|
| Erhoben | **Ja** |
| Geteilt | wie bei Fotos |
| Pflicht | **Optional** — nur im Modul „Figur & Passform" |
| Zweck | App-Funktionalität |
| Kurzlebig | Nein (Körpermaße liegen im Konto) |

Körpergröße und Gewicht, freiwillig eingegeben.
*Woher:* `lib/features/modules/models/modul_eingaben.dart` (`FigurAngaben`),
`lib/core/cloud/cloud_modell.dart` (`daten/module`).

> Ob Play das als „Gesundheitsdaten" oder „Fitnessdaten" führt, hängt an der
> Kategorienbeschreibung im Formular. Zwei Zahlen ohne medizinischen Kontext
> sind Fitnessdaten — die App macht ausdrücklich keine Gesundheitsaussagen
> (`store/listing-de.md`).

### App-Aktivität → Andere Aktionen in der App

| Feld | Angabe |
|---|---|
| Erhoben | **Ja** |
| Geteilt | Nein |
| Pflicht | **Erforderlich** |
| Zweck | App-Funktionalität |
| Kurzlebig | Nein |

Abgehakte Tagesaufgaben, Check-in-Antworten, Serie, gewählte Module und die
persönliche Richtung inklusive Freitext.
*Woher:* `lib/core/cloud/cloud_modell.dart` (`fortschritt/{tag}`,
`checkins/{id}`, `daten/richtung`, `daten/streak`).

> Der Freitext bei „Deine Richtung" ist ein freies Eingabefeld. Er geht mit in
> den Prompt und liegt im Konto. Wer dort etwas Persönliches hineinschreibt,
> speichert es damit — das gehört in die Datenschutzerklärung.
> *Woher:* `lib/features/direction/models/richtung.dart`.

---

## Was ausdrücklich NICHT angekreuzt wird

| Kategorie | Warum nicht |
|---|---|
| Standort | Keine Berechtigung, kein Paket |
| Kontakte, Kalender, SMS | dito |
| Finanzdaten | Keine Käufe (kommt erst mit Phase 3) |
| Werbe-ID / Marketing | Keine Werbung, kein Tracking |
| Absturzprotokolle, Diagnosedaten | Crashlytics ist **noch nicht** eingebunden |
| Audio, Dateien, Dokumente | Werden nicht gelesen |
| Nachrichten | Es gibt keine |

**Berechtigungen der App:** `CAMERA`, `POST_NOTIFICATIONS`,
`RECEIVE_BOOT_COMPLETED` — die vollständige Liste inklusive dessen, was die
Plugins mitbringen, steht in `DECISIONS.md`, Abschnitt 23.

---

## Ein Punkt, den du vor dem Ausfüllen klären musst

**Die App bietet im Onboarding den Altersbereich „unter 18" an.**
*Woher:* `lib/features/onboarding/models/onboarding_profile.dart`.

Das hat drei Folgen, die zusammenhängen:

1. **Zielgruppe im IARC-Fragebogen.** Wählst du eine Zielgruppe unter 18,
   greift Googles Richtlinie für Familien mit deutlich strengeren Auflagen —
   unter anderem bei der Verarbeitung biometrienaher Daten.
2. **Einwilligung.** Eine datenschutzrechtliche Einwilligung von
   Minderjährigen ist in Deutschland ohne Zustimmung der Sorgeberechtigten
   nicht wirksam.
3. **Gesichtsfotos von Minderjährigen** sind der heikelste denkbare Fall.

**Empfehlung:** Zielgruppe auf **18+** setzen und den Altersbereich „unter 18"
aus dem Onboarding entfernen oder mit einem klaren Hinweis versehen, dass die
App ab 18 ist. Das ist eine Produktentscheidung — deshalb steht sie hier als
Frage und nicht als erledigter Haken.

---

# IARC-Fragebogen (Alterseinstufung) — Kurzhilfe

**Play Console → Richtlinien → App-Inhalte → Altersfreigabe.**

Kategorie wählen: **Referenz, Nachrichten oder Lernen** (die App gibt
Empfehlungen; sie ist kein Spiel und kein soziales Netzwerk).

| Frage | Antwort | Warum |
|---|---|---|
| Gewalt jeder Art | **Nein** | — |
| Sexualität, Nacktheit | **Nein** | Die Fotos sind Portrait-, Ganzkörper- und Outfit-Aufnahmen; die App fordert nichts anderes an und bewertet keine Attraktivität |
| Schimpfwörter, grobe Sprache | **Nein** | — |
| Drogen, Alkohol, Tabak | **Nein** | — |
| Glücksspiel (echt oder simuliert) | **Nein** | — |
| Angst, Horror | **Nein** | — |
| Nutzergenerierte Inhalte, die andere sehen | **Nein** | Es gibt keine Freigabe, keine Feeds, keine Profile — jedes Konto sieht nur sich selbst (`firestore.rules`) |
| Kommunikation zwischen Nutzern | **Nein** | Es gibt keine |
| Standortweitergabe | **Nein** | — |
| Personenbezogene Daten werden geteilt | **Nein** | siehe Data-Safety oben |
| Käufe digitaler Güter | **Nein** — *bis Phase 3* | Danach: **Ja** |
| Werbung | **Nein** | — |

**Erwartete Einstufung:** USK 0 bzw. PEGI 3 — vorbehaltlich der
Zielgruppen-Entscheidung oben. Setzt du die Zielgruppe auf 18+, ändert das die
Einstufung nicht, wohl aber die geltenden Richtlinien.

**Kontakt-E-Mail:** dieselbe wie im Impressum; sie wird öffentlich angezeigt.

---

## Wann diese Datei angefasst werden muss

- **Phase 3 (Käufe):** Finanzdaten, „Käufe digitaler Güter" im IARC
- **Phase 4 (Crashlytics/Analytics):** Absturzprotokolle, Diagnosedaten,
  eventuell Geräte-IDs — und die Datenschutzerklärung dazu
- **Jede neue Cloud-Sammlung:** `lib/core/cloud/cloud_modell.dart` ist die
  vollständige Liste dessen, was das Gerät verlässt
