# Store-Eintrag (Deutsch) — Entwurf

Vorlage für die Play Console (**Store-Präsenz → Haupt-Store-Eintrag**).
Alles hier ist Entwurf: durchlesen, anpassen, dann übernehmen.

**Grundregel für jede Zeile:** Play prüft Gesundheitsaussagen streng. Kein
Versprechen, das die App nicht hält — kein „garantiert bessere Haut", kein
„in 30 Tagen zum neuen Ich". Was die App tut, ist Vorschläge machen.

---

## App-Name

```
TrueGlow
```

*(30 Zeichen Grenze — 8 belegt.)*

## Kurzbeschreibung

*Grenze: 80 Zeichen. Diese Zeile steht in der Suchergebnisliste.*

```
Styling-Tipps aus deinen Fotos: konkreter Plan statt Bewertungsspiel.
```

*(69 Zeichen.)*

**Alternativen, falls die erste nicht gefällt:**

```
Dein persönlicher Grooming-Plan – aus deinen Fotos, ohne Punkte und Noten.
```

```
Aus deinen Fotos wird ein Plan: Haare, Haut, Stil. Ohne Bewertungsspiel.
```

---

## Vollständige Beschreibung

*Grenze: 4000 Zeichen. Die ersten drei Zeilen entscheiden, ob jemand
weiterliest.*

```
TrueGlow schaut sich deine Fotos an und macht daraus einen Plan, den du
tatsächlich umsetzen kannst. Keine Punktzahl, kein Ranking, kein Vergleich mit
anderen – sondern konkrete Schritte für Haare, Bart, Haut, Zähne, Figur und
Stil.

SO LÄUFT ES AB

1. Ein paar kurze Fragen: Alter, Budget, wie viel Zeit du täglich hast.
2. Fotos aufnehmen – die App führt dich Schritt für Schritt durch Licht,
   Winkel und Ausschnitt.
3. Du bekommst einen Report mit Einschätzung und Empfehlungen, gegliedert
   nach Bereichen.
4. Daraus wird eine Tages-Checkliste. Abhaken, dranbleiben, Serie aufbauen.
5. Nach 7, 14 und 30 Tagen fragt die App nach: Was passt in deinen Alltag,
   was nicht? Der Plan wird angepasst – nicht neu geschrieben.

WAS DU AUSWÄHLEN KANNST

• Gesicht, Haare & Bart – Gesichtsform, Frisur, Bartkontur
• Haut & Farbtyp – Hautbild, Unterton, passende Farbpalette
• Zähne & Lächeln – Zahnfarbe, Pflege, Mimik
• Figur & Passform – Proportionen, Schnitte, Haltung
• Stil & Kleiderschrank – deine Outfits im Abgleich mit deinem Stilziel

DEINE RICHTUNG ZÄHLT

Du sagst, wohin es gehen soll – markanter, gepflegter, seriöser, natürlicher.
Die Empfehlungen richten sich danach, statt dir ein fremdes Ideal
vorzusetzen.

DEINE FOTOS BLEIBEN BEI DIR

Deine Bilder werden auf deinem Gerät gespeichert und nicht in unsere Cloud
hochgeladen. Für die Auswertung gehen sie einmalig an einen KI-Dienst
(Google Gemini) und werden dort weder gespeichert noch protokolliert. Diese
Verarbeitung findet auch außerhalb der EU statt – du willigst dafür getrennt
ein und kannst die Einwilligung jederzeit in den Einstellungen widerrufen.
Ohne sie funktioniert die App weiter, nur eben ohne neue Analysen.

In die Cloud gehen ausschließlich dein Plan, deine Serie und deine
Check-in-Antworten – damit sie einen Gerätewechsel überleben. Dein Konto
kannst du jederzeit in der App vollständig löschen.

WICHTIG: KEINE MEDIZINISCHE BERATUNG

TrueGlow ist eine Styling- und Grooming-App. Sie stellt keine Diagnosen,
erkennt keine Krankheiten und ersetzt keine ärztliche Beratung. Wenn dir an
Haut, Haaren oder Zähnen etwas auffällt, das abgeklärt gehört, wende dich
bitte an eine dermatologische oder zahnärztliche Praxis. Empfehlungen der App
sind Vorschläge zum Ausprobieren – keine Behandlung und kein Heilversprechen.

Ergebnisse hängen von vielen Dingen ab, die eine App nicht kennt. TrueGlow
verspricht dir kein bestimmtes Aussehen und keinen bestimmten Zeitraum.
```

*(rund 2.400 Zeichen — Platz für Ergänzungen bleibt.)*

---

## Was NICHT hineingehört

Zur Erinnerung beim Umschreiben — jeder dieser Sätze wäre ein Ablehnungsgrund
oder zumindest eine Rückfrage:

| Nicht schreiben | Warum |
|---|---|
| „garantiert bessere Haut" | Heilversprechen |
| „erkennt Hautprobleme" | klingt nach Diagnose |
| „in 30 Tagen attraktiver" | Ergebnis- und Attraktivitätsversprechen |
| „medizinisch geprüft" | unbelegte Autorität |
| „KI-Analyse deiner Schönheit" | Attraktivitätsbewertung |
| „behandelt Akne" | Krankheitsbild plus Behandlung |

Der Prüfer dafür liegt im Repo: `tool/diagnose_stichprobe.dart` prüft
Analyse-Antworten gegen dieselben Muster.

---

## Weitere Felder in der Konsole

| Feld | Vorschlag |
|---|---|
| Kategorie | Beauty |
| Tags | Beauty, Lifestyle, Selbstpflege |
| Kontakt-E-Mail | *einzutragen* |
| Website | *dieselbe Domain wie die Rechtstexte* |
| Datenschutzerklärung | *URL aus `SETUP.md`, Abschnitt 10* |

## Grafiken

Noch zu erstellen (Phase 5.1):

- 4–8 Screenshots im Hochformat, mindestens 1080 × 1920:
  Dashboard, Modulauswahl, „Deine Richtung", Report, Plan, Check-in
- Feature-Grafik 1024 × 500
- App-Icon 512 × 512 — wird aus `assets/branding/app_icon.svg` erzeugt,
  siehe `SETUP.md`, Abschnitt 12

> Die Screenshots müssen den aktuellen Stand zeigen. Für einen Durchlauf ohne
> Backend und ohne Kosten:
> `flutter run --dart-define=TRUEGLOW_MOCK=true`
