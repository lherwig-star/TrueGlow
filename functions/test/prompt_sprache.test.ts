import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import { PRODUKTKATEGORIEN, SEKTIONEN } from '../src/labels';
import type { Ausrichtung } from '../src/ausrichtung';
import type { Modus } from '../src/modus';
import type { Sprache } from '../src/sprache';

/**
 * Was der Prompt dem Modell woertlich vorgibt, landet woertlich im Report.
 *
 * Der Anlass steht in DECISIONS 36: Im englischen Report des weiblichen
 * Modus hiessen die Abschnitte weiter „Frisur", „Augenbrauen",
 * „Alltags-Look" und „Farben", und die Kategorie eines Produkts „Pflege" –
 * weil genau diese Woerter im deutschsprachigen Prompt standen.
 *
 * Der Waechter in `test/sprache_test.dart` auf der App-Seite konnte das nicht
 * finden: Er liest Dart-Dateien unter `lib/`. Diese Pruefung ist sein
 * Gegenstueck fuer den Prompt.
 */

function daten(
  sprache: Sprache,
  ausrichtung: Ausrichtung,
  modus: Modus = 'verfeinern',
): AnalysePromptDaten {
  return {
    sprache,
    ausrichtung,
    modus,
    module: ['basis', 'makeupAusstrahlung', 'hautFarbtyp', 'figurPassform'],
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [], zwecke: [] },
    richtung: { ziele: [], freitext: '' },
    techniken: [],
  };
}

/** Die Abschnittsnamen, so wie der Prompt sie in Anfuehrungszeichen nennt. */
function vorgegebeneTitel(prompt: string): string[] {
  const zeilen = prompt
    .split('\n')
    // Der verfeinernde Modus schreibt "... GENAU so lautet", der
    // entdeckende haengt seinen Abschnitt mit "... GENAU" an.
    .filter((z) => z.includes('"titel" GENAU'));
  const namen: string[] = [];
  for (const zeile of zeilen) {
    for (const treffer of zeile.matchAll(/"([^"]+)"/g)) {
      if (treffer[1] !== 'titel' && treffer[1] !== 'basis') {
        namen.push(treffer[1]);
      }
    }
  }
  return namen;
}

describe('Abschnittsnamen folgen der Zielsprache', () => {
  it('auf Englisch stehen englische Namen im Prompt', () => {
    const titel = vorgegebeneTitel(systemPrompt(daten('en', 'weiblich')));

    expect(titel).toContain('Hair');
    expect(titel).toContain('Eyebrows');
    expect(titel).toContain('Everyday look');
    expect(titel).toContain('Colours');
  });

  it('auf Deutsch stehen deutsche Namen im Prompt', () => {
    const titel = vorgegebeneTitel(systemPrompt(daten('de', 'weiblich')));

    expect(titel).toContain('Frisur');
    expect(titel).toContain('Augenbrauen');
    expect(titel).toContain('Alltags-Look');
    expect(titel).toContain('Farben');
  });

  it('im englischen Prompt steht kein deutscher Abschnittsname', () => {
    // Die eigentliche Pruefung: Sie faengt auch einen Namen, der spaeter
    // dazukommt und beim Uebersetzen vergessen wird.
    for (const ausrichtung of ['maennlich', 'weiblich', 'neutral'] as const) {
      // Beide Modi: Der entdeckende bringt mit "Dein neuer Look" einen
      // eigenen Abschnittsnamen mit, und der faellt sonst durch dieses Netz.
      for (const modus of ['verfeinern', 'entdecken'] as const) {
        const titel = vorgegebeneTitel(
          systemPrompt(daten('en', ausrichtung, modus)),
        );
        const deutsche: string[] = Object.values(SEKTIONEN).map((s) => s.de);

        for (const name of titel) {
          expect(
            deutsche.includes(name) &&
              !Object.values(SEKTIONEN).some((s) => s.en === name),
            `"${name}" ist der deutsche Name und steht im englischen Prompt ` +
              `(Ausrichtung ${ausrichtung}, Modus ${modus})`,
          ).toBe(false);
        }
      }
    }
  });

  it('der neue Abschnitt folgt derselben Regel', () => {
    const deutsch = vorgegebeneTitel(
      systemPrompt(daten('de', 'maennlich', 'entdecken')),
    );
    const englisch = vorgegebeneTitel(
      systemPrompt(daten('en', 'maennlich', 'entdecken')),
    );

    expect(deutsch).toContain('Dein neuer Look');
    expect(englisch).toContain('Your new look');
    expect(englisch).not.toContain('Dein neuer Look');
  });

  it('jeder Abschnittsname hat beide Sprachen und sie sind verschieden', () => {
    for (const [kennung, name] of Object.entries(SEKTIONEN)) {
      expect(name.de.length, kennung).toBeGreaterThan(0);
      expect(name.en.length, kennung).toBeGreaterThan(0);
    }
    // „Styling" hiesse in beiden Sprachen gleich – bei diesen sechs nicht.
    expect(SEKTIONEN.frisur.de).not.toBe(SEKTIONEN.frisur.en);
    expect(SEKTIONEN.farben.de).not.toBe(SEKTIONEN.farben.en);
  });
});

describe('Produktkategorien sind Kennungen', () => {
  it('der Prompt zaehlt sie auf, in beiden Sprachen dieselben', () => {
    for (const sprache of ['de', 'en'] as const) {
      const prompt = systemPrompt(daten(sprache, 'weiblich'));
      for (const kennung of PRODUKTKATEGORIEN) {
        expect(prompt, sprache).toContain(kennung);
      }
    }
  });

  it('es sind kleingeschriebene Kennungen, keine Woerter', () => {
    for (const kennung of PRODUKTKATEGORIEN) {
      expect(kennung).toBe(kennung.toLowerCase());
      expect(kennung).not.toContain(' ');
    }
  });

  it('die alten deutschen Beispiele stehen nicht mehr im Prompt', () => {
    const prompt = systemPrompt(daten('en', 'weiblich'));
    expect(prompt).not.toContain('z.B. Reinigung, Pflege, Styling, Werkzeug');
  });
});
