# Projektregeln TrueGlow

Was hier steht, gilt in jeder Sitzung — unabhängig davon, was gerade
gearbeitet wird.

## Das Testgerät

**Die App wird niemals ohne ausdrückliche Zustimmung deinstalliert.**

`adb uninstall` löscht den privaten Speicher der App. Damit sind weg:

- die **Fortschritts-Fotos** — endgültig. Sie liegen bewusst nur auf dem
  Gerät (DECISIONS 48) und hängen an keiner Cloud.
- Serie, Joker, abgehakte Tage, geschaffte Challenges und der laufende
  Check-in-Entwurf, bis der Sync sie wiederherstellt.

Am 27.08.2026 ist genau das passiert: Deinstallieren war der bequeme Weg,
den Launcher zum Neuladen des Icons zu bewegen — und hat die lokalen Daten
des Nutzers mitgenommen.

**Stattdessen:** `adb install -r` behält alle Daten. Wenn eine Neuinstallation
wirklich nötig scheint (etwa weil ein Launcher ein altes Icon festhält),
**vorher fragen** und dabei nennen, was dabei verloren geht.

Ebenfalls ohne Rückfrage tabu: `adb shell pm clear`, das Löschen von Dateien
unter `/sdcard` außer den eigenen Bildschirmaufnahmen, und alles, was
Systemeinstellungen dauerhaft verstellt.

**Gerätetests macht der Nutzer selbst.** Erlaubt und erwünscht sind
Bildschirmaufnahmen für Nachweise — danach vom Gerät löschen.

## Emulator

Der Rechner hat dafür nicht die Kapazität; ein Startversuch hat ihn schon
einmal lahmgelegt. Es wird direkt mit dem angeschlossenen Gerät gearbeitet
oder gar nicht.

## Analysen kosten Geld

Jeder echte Analyse-Lauf verbraucht Kontingent (10 pro Monat) und Tokens.
Ohne ausdrücklichen Auftrag wird keiner ausgelöst. Zum Ausprobieren gibt es
den Demo-Modus:

```bash
flutter run --dart-define=TRUEGLOW_MOCK=true
```

## Wo was hingehört

- **Warum** etwas so ist: `DECISIONS.md`, fortlaufend nummeriert, Format
  „Was · Warum · Preis".
- **Wie es geprüft wird:** `TESTPLAN.md`, nummerierte Abschnitte, in
  Alltagssprache und ohne Rückfragen abarbeitbar.
- **Wie das Projekt aufgesetzt wird:** `SETUP.md`.

Nach jedem Arbeitspaket: Tests laufen lassen, Begründung in `DECISIONS.md`,
Server (falls betroffen) und App ausrollen und mit Zeitstempel bestätigen,
dass die neue Fassung wirklich oben liegt.
