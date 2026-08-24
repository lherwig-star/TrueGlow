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
| Geteilt | **Ja** |
| Pflicht | **Optional** (die Einwilligung ist getrennt und widerrufbar) |
| Zweck | App-Funktionalität |
| Kurzlebig verarbeitet | **Ja** |

> **Entschieden: „geteilt: Ja".** Play zählt eine Weitergabe an einen
> *Dienstleister*, der ausschließlich weisungsgebunden verarbeitet, formal
> nicht als „Teilen" — man könnte hier also auch „Nein" eintragen. Wir tragen
> trotzdem „Ja" ein, aus drei Gründen:
>
> 1. Die Bilder verlassen tatsächlich unsere Kontrolle und gehen an ein
>    fremdes Unternehmen, auch wenn es weisungsgebunden verarbeitet.
> 2. Es sind Gesichtsaufnahmen. Bei biometrienahen Daten ist die strengere
>    Angabe die richtige.
> 3. „Ja" ist nie ein Verstoß, „Nein" kann einer werden — wenn sich die
>    Nutzungsbedingungen der Gemini-API ändern, ohne dass wir es merken.
>
> Die Einwilligung in der App benennt den Vorgang mit denselben Worten,
> inklusive Drittlandbezug (`einwilligungs_auswahl.dart`), und die
> Datenschutzerklärung muss es ebenso tun
> (`store/rechtstexte-bausteine.md`, Abschnitt 4).

**Empfänger für das Formular:** Google LLC, als Anbieter der Gemini-API.
Verarbeitung auf Servern von Google, auch außerhalb der EU.

„Kurzlebig verarbeitet" bleibt richtig und darf zusätzlich angekreuzt werden:
Die Bilder existieren ausschließlich im Arbeitsspeicher der Function und
werden nach dem Aufruf verworfen — sie liegen in keinem Speicher und in
keinem Log.
*Woher:* `functions/src/index.ts` (`bilder.length = 0` im `finally`),
`functions/src/eingang.ts` (base64 im Aufruf, kein Upload, kein
Storage-Bucket im Projekt).

### Gesundheit und Fitness → Fitnessdaten

| Feld | Angabe |
|---|---|
| Erhoben | **Ja** |
| Geteilt | **Ja** — geht mit demselben Aufruf an Gemini |
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

## Zielgruppe: 18+ — entschieden und umgesetzt

**Die App richtet sich ausschließlich an Erwachsene.** Im Code heißt das:

- Der Altersbereich „unter 18" ist aus dem Onboarding entfernt; die Auswahl
  beginnt bei 18–24.
  *Woher:* `lib/features/onboarding/models/onboarding_profile.dart`.
- Es gibt eine ausdrückliche Altersbestätigung
  (`Einwilligungsart.mindestalter`) mit Zeitstempel, Textversion und Kanal —
  derselbe Nachweis wie bei den Einwilligungen.
  *Woher:* `lib/features/consent/models/einwilligung.dart`.
- Ohne Bestätigung bleibt der **Analyse-Flow** zu: Der Router leitet auf einen
  Hinweisscreen um, der erklärt, warum. Der Rest der App — Plan, Checkliste,
  Serie, Check-ins — funktioniert weiter.
  *Woher:* `lib/core/router/app_router.dart` (`Routes.analyseFlow`),
  `lib/features/consent/ui/alters_hinweis_screen.dart`.
- Zusätzlich prüft der `AnalysisController` vor jedem Start. Eine Umgehung
  über eine tiefe Route führt also trotzdem zu keiner Analyse.
- Bestandsnutzer laufen einmalig durch die Frage, wie schon bei der
  Einwilligungs-Migration.

**Fürs Formular:** Zielgruppe **nur Erwachsene (18+)**. Damit greift Googles
Richtlinie für Familien **nicht**.

> Warum überhaupt: Für eine Analyse verarbeitet die App Aufnahmen des
> Gesichts. Eine wirksame datenschutzrechtliche Einwilligung dazu können in
> Deutschland nur Erwachsene selbst erteilen — bei Minderjährigen bräuchte es
> die Sorgeberechtigten. Gesichtsfotos von Minderjährigen wären der heikelste
> denkbare Fall.

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
| Personenbezogene Daten werden geteilt | **Ja** | Fotos gehen an Google (Gemini), siehe Data-Safety oben |
| Käufe digitaler Güter | **Nein** — *bis Phase 3* | Danach: **Ja** |
| Werbung | **Nein** | — |

**Zielgruppe:** ausschließlich **18 und älter**. Beim Punkt „Zielgruppe und
Inhalte" nur die Altersgruppe **18+** ankreuzen — keine jüngere. Damit greift
die Familien-Richtlinie nicht, und die Angabe deckt sich mit der
Altersbestätigung in der App.

**Erwartete Einstufung:** Die inhaltlichen Antworten oben ergeben USK 0 bzw.
PEGI 3. Das ist kein Widerspruch zur Zielgruppe 18+: Die Einstufung bewertet
Inhalte, die Zielgruppe bestimmt, wem die App angeboten wird. Die App ist
inhaltlich harmlos und trotzdem nichts für Minderjährige.

**Kontakt-E-Mail:** dieselbe wie im Impressum; sie wird öffentlich angezeigt.

---

## Wann diese Datei angefasst werden muss

- **Phase 3 (Käufe):** Finanzdaten, „Käufe digitaler Güter" im IARC
- **Phase 4 (Crashlytics/Analytics):** Absturzprotokolle, Diagnosedaten,
  eventuell Geräte-IDs — und die Datenschutzerklärung dazu
- **Jede neue Cloud-Sammlung:** `lib/core/cloud/cloud_modell.dart` ist die
  vollständige Liste dessen, was das Gerät verlässt
