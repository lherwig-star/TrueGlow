# Zustände aller Screens (Roadmap 4.2)

Jeder Screen wurde auf drei Fragen durchgesehen:

- **Laden** — Was sieht man, während etwas dauert?
- **Fehler** — Was sieht man, wenn es schiefgeht, und wie kommt man weiter?
- **Leer** — Was sieht man, wenn es nichts zu zeigen gibt?

„entfällt" heißt: Der Zustand kann auf diesem Screen nicht auftreten, und
zwar aus einem benennbaren Grund. Das ist eine Antwort, kein übersprungener
Punkt.

**Stand:** nach Phase 4.2. Die in dieser Runde ergänzten Zustände sind mit
**neu** gekennzeichnet.

---

## Vor der App

| Screen | Laden | Fehler | Leer |
|---|---|---|---|
| **Einrichtungshinweis**<br>`einrichtung_hinweis.dart` | entfällt — steht erst, wenn der Start abgeschlossen ist | *ist* der Fehlerzustand: nennt Ursache und Befehl | entfällt |
| **Onboarding**<br>`onboarding_screen.dart` | entfällt — reine Formularseiten ohne Netz | „Weiter" bleibt gesperrt, solange Pflichtangaben fehlen | entfällt |
| **Login**<br>`login_screen.dart` | Spinner im gedrückten Knopf, alle anderen gesperrt | Karte mit Titel und Tipp aus `AuthFehler`, Screen bleibt bedienbar | entfällt |
| **Einwilligung (Nachtrag)**<br>`einwilligung_screen.dart` | entfällt — nur lokaler Zustand | „Weiter" gesperrt, solange die Pflichteinwilligung fehlt | entfällt |
| **Alters-Hinweis**<br>`alters_hinweis_screen.dart` | entfällt | entfällt | *ist* der Erklärzustand, mit Ausweg zurück ins Dashboard |

## Hauptbereich

| Screen | Laden | Fehler | Leer |
|---|---|---|---|
| **Dashboard**<br>`home_screen.dart` | entfällt — liest lokal und synchron | **neu:** Karte „Analyse unterbrochen", wenn ein Lauf beim letzten Mal abbrach | „Noch keine Analyse" mit Einstieg |
| **Modulauswahl**<br>`module_selection_screen.dart` | kein Spinner — der Kontingentstand kommt nach und schiebt sich still ein, statt die Seite zu blockieren | Auswahl selbst kann nicht scheitern. **Neu:** Ist das Kontingent erschöpft, erklärt eine Karte den Grund (Tages- oder Monatsgrenze) und die Weiter-Schaltfläche ist gesperrt — der Hinweis steht **vor** der Kamera, nicht nach elf Fotos. Lässt sich der Stand nicht lesen (offline, Demo, nicht angemeldet), erscheint nichts und nichts sperrt | entfällt — die Basis ist immer gesetzt |
| **Deine Richtung**<br>`direction_screen.dart` | entfällt | entfällt | Hinweistext bei leerer Auswahl; Überspringen ist erlaubt |
| **Aufnahme-Flow**<br>`capture_flow_screen.dart` | Spinner während der Bildprüfung | Sechs benannte Foto-Probleme mit konkretem Tipp | Schrittanzeige zeigt, was noch fehlt |
| **Kamera**<br>`camera_screen.dart` | Spinner bis die Vorschau steht | Eigener Hinweisschirm: Berechtigung verweigert (mit Link in die Systemeinstellungen) oder Kamera nicht verfügbar — Galerie bleibt als Ausweg | entfällt |
| **Analyse läuft**<br>`analysis_loading_screen.dart` | *ist* der Ladezustand: rotierende Texte, Skelettkarten | Sieben `AnalysisFehler`-Fälle mit Titel, Tipp, „Erneut versuchen" und „Zurück" | entfällt |
| | **neu:** „Abbrechen" — sonst hängt der Screen bis zu drei Versuche am Netz | | |
| **Report**<br>`result_screen.dart` | entfällt — liest lokal | „Diese Analyse ist nicht mehr vorhanden" | Kapitel ohne Inhalt werden gar nicht erst gezeichnet |
| **Plan**<br>`plan_screen.dart` | entfällt | entfällt | „Noch kein Plan vorhanden. Starte zuerst eine Analyse." |
| **Verlauf**<br>`history_screen.dart` | entfällt | entfällt | `S.verlaufLeer` mit Symbol |

## Check-in

| Screen | Laden | Fehler | Leer |
|---|---|---|---|
| **Check-in**<br>`checkin_screen.dart` | Spinner während der Fortschrittsfoto-Prüfung | Fotoproblem als Hinweis; der Check-in läuft ohne Foto weiter | „Gerade steht kein Check-in an." |
| **Auswertung**<br>`checkin_abschluss.dart` | Spinner mit Statustext | `AnalysisFehler` mit „Erneut versuchen"; der Check-in lässt sich auch ohne Auswertung abschließen | entfällt |
| | **neu:** „Ohne Auswertung fortfahren" bricht das Warten ab | | |

## Einstellungen und Recht

| Screen | Laden | Fehler | Leer |
|---|---|---|---|
| **Einstellungen**<br>`settings_screen.dart` | **neu:** Konto-Karte zeigt „Wird geladen …", statt vorschnell „Nicht angemeldet" zu behaupten | **neu:** eigener Text, wenn der Anmeldezustand nicht abfragbar ist; Löschfehler als Snackbar mit Titel und Tipp | „Nicht angemeldet", wenn wirklich niemand angemeldet ist |
| **Rechtliches**<br>`legal_screen.dart` | entfällt | Snackbar, wenn sich ein Dokument nicht öffnen lässt | „Noch nicht verfügbar" je Eintrag, Eintrag ist gesperrt |
| **Rechtstext**<br>`rechtsdokument_screen.dart` | Spinner während das Markdown geladen wird | „Text nicht lesbar" mit Verweis auf die Webseite | „Für dieses Dokument ist noch kein Text hinterlegt" |

## Über allen Screens

| Element | Wann |
|---|---|
| **Offline-Band** (**neu**) | Sobald keine Netzwerkverbindung besteht. Sagt ausdrücklich, dass Plan und Checkliste weiterlaufen und Änderungen nachgetragen werden. |

---

## Was dabei aufgefallen ist

**Der Bestand war besser als erwartet.** Leerzustände gab es überall, wo sie
hingehören; das Fehlerkonzept mit `AnalysisFehler` (Titel *und* Tipp je Fall)
trug auch die neuen Fälle ohne Anpassung.

**Die echte Lücke war eine andere:** Zwei Ladezustände waren nicht
*abbrechbar*. Seit Phase 4.1 wiederholt jeder Function-Aufruf bis zu dreimal
mit wachsender Pause — bei schlechter Verbindung steht man damit deutlich
länger vor einem Spinner als vorher. Ein Ladezustand ohne Ausweg ist dann
kein Ladezustand mehr, sondern eine Sackgasse. Beide haben jetzt einen.

**Ein stiller Zustand war gar keiner:** Wurde die App mitten in einer Analyse
beendet, gab es beim nächsten Start keinerlei Spur davon — kein Ergebnis,
kein Fehler, kein Hinweis. Das ist der „hängende Zwischenzustand" aus der
Roadmap, und er war unsichtbar, weil er wie ein normaler Start aussah.

---

## Wenn ein Screen dazukommt

Drei Zeilen in dieser Tabelle, bevor der Screen fertig ist. „entfällt" ist
eine gültige Antwort — aber sie braucht einen Grund daneben.
