# Bausteine für die Rechtstexte

Was in Datenschutzerklärung, Nutzungsbedingungen und Impressum stehen **muss**,
damit die Texte zu dem passen, was die App tatsächlich tut.

Das hier ist **kein Rechtstext.** Es ist die Zuarbeit für deinen Generator oder
deine Anwältin: Jeder Abschnitt beschreibt einen Sachverhalt und nennt die
Stelle im Code, an der er nachprüfbar ist. Wo eine Formulierung nah am
Endtext liegt, steht sie als Zitatblock — auch die ist ein Vorschlag, kein
geprüfter Text.

> **Nach jeder Änderung an den Texten:** `Rechtstexte.version` in
> `lib/features/legal/logic/rechtstexte.dart` erhöhen. Die App holt dann von
> allen Nutzern eine neue Einwilligung ein — genau das ist der Zweck.

---

## 1 · Verantwortlicher und Kontakt

Gehört ins Impressum und an den Anfang der Datenschutzerklärung.

- Name bzw. Firmierung, Anschrift, E-Mail
- bei Einzelunternehmen: der bürgerliche Name, keine Fantasiebezeichnung
- Umsatzsteuer-ID, falls vorhanden

**Offen:** Diese Angaben kennt nur du. Sie hängen an der Entscheidung
Privatperson vs. Firma (ROADMAP 2.8).

---

## 2 · Zielgruppe: ab 18

> TrueGlow richtet sich ausschließlich an Personen ab 18 Jahren. Für eine
> Analyse verarbeitet die App Aufnahmen deines Gesichts; eine wirksame
> Einwilligung dazu können nur Erwachsene selbst erteilen. Vor der ersten
> Analyse bestätigst du deshalb ausdrücklich, volljährig zu sein. Ohne diese
> Bestätigung bleibt der Analyse-Bereich gesperrt.

*Woher:* `lib/features/consent/models/einwilligung.dart`
(`Einwilligungsart.mindestalter`), `lib/core/router/app_router.dart`
(`Routes.analyseFlow`).

---

## 3 · Welche Daten verarbeitet werden

| Was | Wo es liegt | Wie lange |
|---|---|---|
| Fotos (Gesicht, Ganzkörper, Outfits) | **nur auf dem Gerät** | bis du sie löschst oder die App deinstallierst |
| Analyse-Ergebnisse, Plan, Serie, Check-in-Antworten | Firestore, Region `europe-west3` (Frankfurt) | bis zur Löschung des Kontos |
| Onboarding-Antworten (Altersbereich, Budget, Zeit, Schwerpunkte) | Firestore | dito |
| Körpergröße und Gewicht | Firestore | dito, nur wenn das Modul „Figur & Passform" genutzt wird |
| Freitext bei „Deine Richtung" | Firestore | dito |
| Einwilligungsnachweis (Zeitpunkt, Textversion, Kanal) | Firestore | dito |
| Konto: Firebase-UID; bei Google-Anmeldung zusätzlich Name und E-Mail | Firebase Auth | bis zur Kontolöschung |
| Verweise auf Fotodateien (Dateinamen, keine Bilddaten) | Firestore | dito |

*Woher:* `lib/core/cloud/cloud_modell.dart` — die vollständige und einzige
Liste dessen, was das Gerät verlässt.

> Wichtig für die Formulierung: **Bilddaten liegen nie in unserer Cloud.**
> Gespeichert werden nur Dateinamen. Auf einem neuen Gerät fehlen die Fotos
> deshalb — die App zeigt dort einen Platzhalter.

---

## 4 · Übermittlung an Google (Gemini) — der wichtigste Abschnitt

Der heikelste Punkt des ganzen Projekts. Er braucht eine eigene, ausdrückliche
Einwilligung, und die Datenschutzerklärung muss ihn vollständig beschreiben.

> Für die Analyse übermitteln wir deine Fotos an den KI-Dienst Google Gemini.
> Die Übermittlung erfolgt über unseren eigenen Server (Google Cloud
> Functions, Region Frankfurt); die Bilder werden dort nicht gespeichert und
> nicht protokolliert. Die Verarbeitung durch Google findet auf Servern von
> Google statt, auch außerhalb der Europäischen Union
> (**Drittlandtransfer**). Google speichert die Bilder für diesen Vorgang
> nicht dauerhaft.
>
> Rechtsgrundlage ist deine ausdrückliche Einwilligung nach Art. 6 Abs. 1
> lit. a und Art. 49 Abs. 1 lit. a DSGVO. Da Aufnahmen deines Gesichts
> betroffen sind, holen wir diese Einwilligung getrennt von der übrigen
> Zustimmung ein. Du kannst sie jederzeit in den Einstellungen widerrufen.
> Nach einem Widerruf sind keine neuen Analysen mehr möglich; bereits
> erstellte Reports bleiben erhalten.

**Was der Text zusätzlich enthalten muss:**

- die Nennung von **Google LLC** als Empfänger
- der Hinweis, dass der Widerruf die Rechtmäßigkeit der bis dahin erfolgten
  Verarbeitung nicht berührt
- eine Aussage zur Grundlage des Drittlandtransfers (Angemessenheitsbeschluss
  bzw. Standardvertragsklauseln — **prüfen lassen**, das ist der Punkt, an
  dem ein Generator gern zu pauschal wird)

*Woher:* `functions/src/gemini.ts`, `functions/src/index.ts`,
`lib/features/consent/ui/einwilligungs_auswahl.dart` (der Wortlaut in der App
muss zu dem in der DSE passen).

---

## 5 · Rechtsgrundlagen im Überblick

| Verarbeitung | Grundlage |
|---|---|
| Konto und Synchronisierung | Vertragserfüllung, Art. 6 Abs. 1 lit. b |
| Übermittlung der Fotos an Gemini | **Einwilligung**, Art. 6 Abs. 1 lit. a + Art. 49 Abs. 1 lit. a |
| Absturzberichte und Nutzungsstatistik | **Einwilligung**, Art. 6 Abs. 1 lit. a — standardmäßig aus |
| Check-in-Erinnerungen (lokale Benachrichtigung) | Vertragserfüllung; verlässt das Gerät nicht |

---

## 6 · Absturzberichte und Nutzungsstatistik

> Wenn du zustimmst, erfassen wir Absturzberichte (Firebase Crashlytics) und
> eine sehr sparsame Nutzungsstatistik (Firebase Analytics). Beides ist
> standardmäßig **aus** und lässt sich in den Einstellungen jederzeit an- und
> abschalten.
>
> Absturzberichte enthalten technische Angaben zum Gerät, zur App-Version und
> zur Fehlerstelle im Programm. Die Nutzungsstatistik erfasst ausschließlich,
> **dass** ein Schritt erreicht wurde — etwa „Onboarding abgeschlossen" oder
> „Analyse gestartet". Sie enthält keine Inhalte: keine Fotos, keine
> Analyse-Ergebnisse, keine Freitexte und keine Angaben aus deinem Profil.

*Woher:* `lib/core/diagnose/` — die Liste der erfassten Ereignisse steht in
`diagnose_ereignis.dart` und ist vollständig.

---

## 7 · Löschung

> Du kannst deine Daten jederzeit selbst löschen:
>
> - **Einstellungen → Daten löschen, Konto behalten:** entfernt alle Inhalte
>   auf dem Gerät und in der Cloud, das Konto bleibt bestehen.
> - **Einstellungen → Konto endgültig löschen:** entfernt zusätzlich das
>   Konto. Danach ist keine Anmeldung mehr möglich.
> - **Ohne die App:** über die Seite [Löschseite-URL eintragen].
>
> Deine Fotos liegen ausschließlich auf deinem Gerät und werden in beiden
> Fällen mitgelöscht; beim Deinstallieren der App verschwinden sie ohnehin.

*Woher:* `functions/src/konto.ts`, `SETUP.md` Abschnitt 11.

---

## 8 · Keine medizinische Beratung

Gehört in die Nutzungsbedingungen **und** in die Store-Beschreibung.

> TrueGlow ist eine Styling- und Grooming-App. Sie stellt keine Diagnosen,
> erkennt keine Krankheiten und ersetzt keine ärztliche oder zahnärztliche
> Beratung. Die Empfehlungen sind Vorschläge zum Ausprobieren. Wenn dir an
> Haut, Haaren oder Zähnen etwas auffällt, das abgeklärt gehört, wende dich
> an eine Fachpraxis.
>
> Wir versprechen kein bestimmtes Ergebnis und keinen bestimmten Zeitraum.

*Woher:* `S.disclaimerMedizin`, `functions/src/analyse_prompt.ts` (die Regeln,
die das Modell binden), `tool/diagnose_pruefung.dart` (die Prüfung darauf).

---

## 9 · Was die App ausdrücklich NICHT tut

Ein kurzer Absatz dazu ist Gold wert — er beantwortet die Fragen, die sonst
per E-Mail kommen.

> - Wir laden deine Fotos nicht in unsere Cloud.
> - Wir geben keine Daten zu Werbezwecken weiter und binden keine Werbung ein.
> - Wir erfassen deinen Standort nicht, lesen keine Kontakte und keine
>   Dateien.
> - Es gibt keine Profile, keine Feeds und keinen Austausch zwischen Nutzern.
>   Jedes Konto sieht ausschließlich seine eigenen Daten.

*Woher:* `pubspec.yaml` (keines der entsprechenden Pakete),
`firestore.rules` (Zugriff nur auf `users/{request.auth.uid}`).

---

## 10 · Betroffenenrechte

Standardbausteine, die jeder Generator liefert — aber prüf, dass die
Kontaktadresse dieselbe ist wie im Impressum: Auskunft, Berichtigung,
Löschung, Einschränkung, Datenübertragbarkeit, Widerspruch, Widerruf
erteilter Einwilligungen, Beschwerde bei einer Aufsichtsbehörde.

---

## Checkliste vor dem Einsetzen

- [ ] Verantwortlicher und Kontakt eingetragen (Abschnitt 1)
- [ ] Zielgruppe 18+ erwähnt (2)
- [ ] Datentabelle vollständig, mit Region Frankfurt (3)
- [ ] Gemini-Abschnitt mit Drittlandbezug, Rechtsgrundlage und Widerruf (4)
- [ ] Absturzberichte und Statistik als Einwilligung beschrieben (6)
- [ ] Löschwege inklusive Web-URL (7)
- [ ] Medizin-Disclaimer in den Nutzungsbedingungen (8)
- [ ] URLs in `rechtstexte.dart` eingetragen und `version` erhöht
- [ ] `dart run tool/rechtstexte_pruefen.dart` läuft durch
