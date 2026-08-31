# Datenschutzerklärung

> **ENTWURF — noch nicht juristisch geprüft.**
> Dieser Text beschreibt die Datenflüsse der App so, wie sie im Code
> nachweisbar sind. Er ist als Arbeitsgrundlage für die anwaltliche Prüfung
> gedacht und **noch nicht verbindlich**. Vor der Veröffentlichung im Store
> muss er geprüft und die Textversion auf eine Fassung ohne „-entwurf"
> gehoben werden.

**Stand:** 31.08.2026 · **Textversion:** 1-entwurf

---

## 1 · Wer verantwortlich ist

Verantwortlich für die Verarbeitung deiner Daten im Sinne der
Datenschutz-Grundverordnung (DSGVO) ist:

> **[NAME DES VERANTWORTLICHEN]**
> [STRASSE UND HAUSNUMMER]
> [PLZ UND ORT]
> [LAND]
> E-Mail: [KONTAKT-E-MAIL]

Bei Fragen zum Datenschutz erreichst du uns unter der oben genannten
E-Mail-Adresse.

Ein Datenschutzbeauftragter ist nicht bestellt; die Voraussetzungen dafür
liegen nicht vor.

---

## 2 · Worum es in dieser App geht

TrueGlow erstellt aus Fotos, die du selbst aufnimmst, eine Einschätzung zu
Pflege und Stil und daraus einen Plan mit täglichen Aufgaben. Für die
Auswertung der Fotos wird ein KI-Dienst von Google eingesetzt.

Die App ist **Personen ab 18 Jahren** vorbehalten.

TrueGlow gibt keine medizinischen Auskünfte, stellt keine Diagnosen und
vergibt keine Bewertungszahlen.

---

## 3 · Deine Fotos — der wichtigste Punkt

Weil es die empfindlichsten Daten sind, stehen sie zuerst.

**Wo deine Fotos liegen.** Ausschließlich auf deinem Gerät, in einem
Verzeichnis, auf das nur diese App zugreifen kann. Sie werden **nicht** in
eine Cloud hochgeladen und **nicht** dauerhaft auf unseren Servern
gespeichert.

**Sie sind auch von Backups ausgenommen.** Die App ist so eingestellt, dass
Android sie nicht in das automatische Google-Backup und nicht in den
Gerätetransfer aufnimmt.

**Was bei einer Analyse passiert.** Startest du eine Analyse, werden die
dafür nötigen Fotos an unseren eigenen Server (Google Cloud Functions,
Frankfurt) geschickt und von dort unmittelbar an den KI-Dienst **Google
Gemini** weitergegeben. Auf unserem Server laufen sie nur durch den
Arbeitsspeicher: Sie werden dort nicht gespeichert, nicht in Protokolle
geschrieben und nach dem Aufruf verworfen.

**Die Verarbeitung bei Google findet auch außerhalb der Europäischen Union
statt** (Drittlandtransfer). Rechtsgrundlage dafür ist deine ausdrückliche
Einwilligung nach Art. 49 Abs. 1 lit. a DSGVO, die du vor der ersten
Aufnahme erteilst und jederzeit widerrufen kannst.

**Fortschrittsfotos** aus den Check-ins bleiben ebenfalls ausschließlich auf
deinem Gerät. Sie verlassen es nur, wenn ein Wirkungs-Check ausdrücklich
einen Vorher-Nachher-Vergleich anfordert — dann gilt für sie dasselbe wie
oben.

**Was das für dich heißt:** Deinstallierst du die App oder löschst du ihre
Daten am Gerät, sind deine Fotos endgültig weg. Wir können sie nicht
wiederherstellen, weil wir sie nie hatten.

---

## 4 · Welche Daten wir sonst verarbeiten

### 4.1 Konto

Zum Starten einer Analyse brauchst du ein Konto. Zur Wahl stehen:

- **Anmeldung mit Google**
- **Anmeldung mit Apple**
- **anonymes Konto** — ohne Namen und ohne E-Mail-Adresse

Verarbeitet werden dabei eine von Firebase vergebene Kennnummer, der
Zeitpunkt der Anmeldung und — je nach gewähltem Verfahren — deine
E-Mail-Adresse und dein Anzeigename. **Passwörter gibt es nicht**; die App
bietet keine Anmeldung mit E-Mail und Passwort an.

*Rechtsgrundlage: Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO).*

### 4.2 Deine Angaben und Ergebnisse

In deinem Konto werden gespeichert:

| Was | Beispiel |
|---|---|
| Angaben aus dem Einstieg | Altersbereich, Budget, Zeit pro Tag, Schwerpunkte, Angabe zum Geschlecht |
| Deine Richtung | gewählte Stilrichtungen und dein Freitext an den Coach |
| Modulauswahl und Zusatzangaben | Körpergröße, Gewicht, Stil-Fragebogen |
| Deine Analysen | die fertigen Reports als Text |
| Deine Check-ins | deine Antworten und die daraus abgeleiteten Planänderungen |
| Dein Fortschritt | welche Aufgaben du an welchem Tag abgehakt hast, Serie, Joker |
| Nachweis der Einwilligung | wann und in welcher Textversion du zugestimmt hast |
| Verbrauchszähler | wie viele Analysen du an einem Tag bzw. Monat gestartet hast |

**Wo:** in Google Firestore, Region **europe-west3 (Frankfurt)**.
Bilddaten sind dort technisch ausgeschlossen — ein Dokument mit einem
Bildfeld wird von den Zugriffsregeln abgelehnt.

**Wer darf darauf zugreifen:** ausschließlich dein eigenes Konto. Die
Zugriffsregeln sind so gesetzt, dass ein anderes Konto weder lesen noch
schreiben kann; das wird bei jeder Änderung automatisch getestet.

*Rechtsgrundlage: Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO).*

### 4.3 Absturzberichte und Nutzungsstatistik — nur mit deiner Zustimmung

Wenn du zustimmst, verwenden wir:

- **Firebase Crashlytics** für Absturzberichte (technische Angaben zum
  Gerät und zur Stelle im Programm, an der es gescheitert ist),
- **Firebase Analytics** für eine kleine Zahl von Ereignissen.

Die Ereignisliste ist abschließend und enthält **keine Parameter** — es wird
nur festgehalten, *dass* ein Schritt erreicht wurde:

`onboarding_abgeschlossen`, `anmeldung_abgeschlossen`, `analyse_gestartet`,
`analyse_fertig`, `plan_geoeffnet`, `checkin_gestartet`,
`checkin_abgeschlossen`.

Es werden dabei **keine** Inhalte deiner Analyse, keine Freitexte, keine
Profilangaben und keine Fotos übertragen. Die **Werbe-ID des Geräts wird
ausdrücklich nicht verwendet**; sie ist in der App abgeschaltet.

Stimmst du nicht zu, wird gar nicht erst erhoben — nicht „erhoben und nicht
gesendet".

*Rechtsgrundlage: Einwilligung (Art. 6 Abs. 1 lit. a DSGVO), jederzeit in den
Einstellungen widerrufbar.*

### 4.4 Technische Protokolle

Unsere Server schreiben Protokolle, um Fehler zu finden. Darin stehen
Zeitpunkt, Art des Aufrufs, Fehlermeldungen und die Zahl der verbrauchten
Rechenschritte. **Fotos, E-Mail-Adressen, Namen und deine Freitexte stehen
dort nicht.** In einzelnen Zeilen kann die Kennnummer deines Kontos
auftauchen.

Die Protokolle werden nach **30 Tagen** automatisch gelöscht.

*Rechtsgrundlage: berechtigtes Interesse am sicheren Betrieb
(Art. 6 Abs. 1 lit. f DSGVO).*

---

## 5 · Wen wir einsetzen

| Dienst | Wofür | Wo |
|---|---|---|
| **Google Firebase** (Auth, Firestore, Cloud Functions, App Check) | Konto, Speicherung, Serverfunktionen | Frankfurt (europe-west3) |
| **Google Gemini** | Auswertung der Fotos | Server von Google, auch außerhalb der EU |
| **Firebase Crashlytics / Analytics** | Absturzberichte, Statistik | nur mit Einwilligung |

Anbieter ist jeweils Google Ireland Limited bzw. Google LLC. Für die
Verarbeitung außerhalb der EU stützen wir uns auf deine Einwilligung sowie
auf die von Google verwendeten Standardvertragsklauseln.

**Es gibt keine Werbenetzwerke, kein Tracking über Apps hinweg und keinen
Verkauf von Daten.**

---

## 6 · Wie lange wir speichern

- **Fotos:** bis du sie löschst — sie liegen nur auf deinem Gerät.
- **Kontodaten, Analysen, Check-ins, Fortschritt:** bis du sie löschst oder
  dein Konto auflöst.
- **Nachweis der Einwilligung:** solange das Konto besteht.
- **Verbrauchszähler:** rollierend; sie werden monatlich zurückgesetzt und
  bleiben nach einer Datenlöschung bewusst bestehen (siehe Abschnitt 8).
- **Server-Protokolle:** 30 Tage.

---

## 7 · Deine Rechte

Dir stehen zu:

- **Auskunft** (Art. 15 DSGVO) — in der App unter *Einstellungen → Meine
  Daten herunterladen*. Du bekommst eine lesbare Datei mit allem, was zu
  deinem Konto gespeichert ist.
- **Datenübertragbarkeit** (Art. 20 DSGVO) — dieselbe Datei ist ein
  maschinenlesbares JSON.
- **Berichtigung** (Art. 16 DSGVO) — deine Angaben lassen sich in der App
  ändern.
- **Löschung** (Art. 17 DSGVO) — in der App unter *Einstellungen*, wahlweise
  nur die Inhalte oder das ganze Konto.
- **Einschränkung und Widerspruch** (Art. 18, 21 DSGVO).
- **Widerruf jeder Einwilligung** (Art. 7 Abs. 3 DSGVO) — in den
  Einstellungen. Der Widerruf gilt ab sofort; was vorher rechtmäßig
  verarbeitet wurde, bleibt davon unberührt.
- **Beschwerde bei einer Aufsichtsbehörde** (Art. 77 DSGVO).

---

## 8 · Was beim Löschen passiert

**„Alle Daten löschen"** entfernt auf dem Server deinen kompletten
Datenbereich: Profil, Richtung, Module, Analysen, Check-ins, Fortschritt.
Das Konto bleibt bestehen.

**„Konto löschen"** entfernt zusätzlich das Konto selbst. Danach ist eine
Anmeldung mit denselben Zugangsdaten ein **neues** Konto. Weil dieser Schritt
nicht rückgängig zu machen ist, verlangt er eine frische Anmeldung.

**Fotos** liegen auf deinem Gerät und werden dort gelöscht — über die App
oder indem du die App entfernst.

**Eine Ausnahme, und wir nennen sie ausdrücklich:** Der Zähler, wie viele
Analysen du in diesem Monat gestartet hast, bleibt erhalten. Er enthält
nichts über dich außer zwei Zahlen und einem Datum — keine Inhalte, keine
Angaben, kein Ergebnis. Er bleibt, weil er sonst durch wiederholtes Löschen
zurückgesetzt werden könnte und die Begrenzung, die uns vor unbegrenzten
Kosten schützt, damit wirkungslos wäre.

*Rechtsgrundlage für diese Ausnahme: berechtigtes Interesse an der
Missbrauchsvermeidung (Art. 6 Abs. 1 lit. f DSGVO).*

---

## 9 · Sicherheit

- Der Zugriff auf deine Daten ist auf dein Konto beschränkt; die Regeln dazu
  werden automatisch getestet.
- Jeder Serveraufruf ist doppelt abgesichert: durch dein Konto **und** durch
  eine Prüfung, dass der Aufruf aus einer echten Installation der App kommt.
- Der Schlüssel für den KI-Dienst liegt ausschließlich auf dem Server und ist
  in der App nicht enthalten.
- Alle Verbindungen sind verschlüsselt.

---

## 10 · Änderungen dieser Erklärung

Ändert sich etwas Wesentliches, erhöhen wir die Textversion. Die App fragt
dann erneut nach deiner Zustimmung, bevor du weiterarbeitest.
