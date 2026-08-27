import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import type { Modus } from '../src/modus';
import { nachbereiten } from '../src/nachbereitung';
import type { Sprache } from '../src/sprache';

/**
 * Das Gesamtbild oben, die Namen erst in den Kapiteln – DECISIONS 67.
 *
 * Der Anlass: In beiden Modi zählte die Karte ganz oben bereits die
 * konkreten Vorschläge auf, und die Kapitel darunter wiederholten dasselbe.
 */

function daten(
  modus: Modus,
  sprache: Sprache = 'de',
): AnalysePromptDaten {
  return {
    sprache,
    ausrichtung: 'maennlich',
    modus,
    module: ['basis', 'stilKleiderschrank'],
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [], zwecke: [] },
    richtung: { ziele: [], freitext: '' },
  };
}

describe('Beide Modi haben ein Gesamtbild', () => {
  it('und es steht in beiden im Schema', () => {
    for (const modus of ['verfeinern', 'entdecken'] as const) {
      const prompt = systemPrompt(daten(modus));
      expect(prompt, modus).toContain('"gesamtbild"');
      // Das Feld steht ganz oben, vor den Kapiteln.
      expect(prompt.indexOf('"gesamtbild"'), modus).toBeLessThan(
        prompt.indexOf('"kapitel": ['),
      );
    }
  });

  it('der alte Feldname kommt nicht mehr vor', () => {
    for (const modus of ['verfeinern', 'entdecken'] as const) {
      expect(systemPrompt(daten(modus)), modus).not.toContain('"neuerLook"');
    }
  });
});

describe('Die Regel steht im Prompt', () => {
  it('mit dem ausdrücklichen Verbot konkreter Namen', () => {
    for (const modus of ['verfeinern', 'entdecken'] as const) {
      const prompt = systemPrompt(daten(modus));
      expect(prompt, modus).toContain('KEINE konkreten Einzelvorschläge');
      expect(prompt, modus).toContain('Kein Schnittname');
      expect(prompt, modus).toContain('zum ersten\n  Mal im jeweiligen Kapitel');
    }
  });

  it('und mit der Gegenrichtung: Kapitel wiederholen nichts', () => {
    for (const modus of ['verfeinern', 'entdecken'] as const) {
      expect(systemPrompt(daten(modus)), modus).toContain(
        'fassen das Gesamtbild nicht noch einmal zusammen',
      );
    }
  });

  it('je ein Positiv- und ein Negativbeispiel pro Modus', () => {
    for (const modus of ['verfeinern', 'entdecken'] as const) {
      const prompt = systemPrompt(daten(modus));
      expect(prompt, modus).toContain('RICHTIG: "');
      expect(prompt, modus).toContain('FALSCH:  "');
      // Und die Warnung davor, sie abzuschreiben (DECISIONS 36).
      expect(prompt, modus).toContain('Muster für die FORM');
    }
  });

  it('die Beispiele unterscheiden sich je Modus', () => {
    const e = systemPrompt(daten('entdecken'));
    const v = systemPrompt(daten('verfeinern'));

    expect(e).toContain('Die Richtung geht weg vom Unauffälligen');
    expect(v).toContain('Deine Grundlage trägt bereits');
    expect(e).not.toContain('Deine Grundlage trägt bereits');
    expect(v).not.toContain('Die Richtung geht weg vom Unauffälligen');
  });

  it('und sie stehen in der Zielsprache', () => {
    for (const modus of ['verfeinern', 'entdecken'] as const) {
      const englisch = systemPrompt(daten(modus, 'en'));
      expect(englisch, modus).toContain('The ');
      // Kein deutsches Beispiel im englischen Prompt.
      expect(englisch, modus).not.toContain('Die Richtung geht weg');
      expect(englisch, modus).not.toContain('Deine Grundlage trägt');
    }
  });
});

describe('Die Nachbereitung erkennt den offensichtlichen Fall', () => {
  const vorgabe = {
    sprache: 'de' as const,
    ausrichtung: 'maennlich' as const,
    module: ['basis' as const],
  };

  function report(gesamtbild: string, imKapitel: string) {
    return {
      gesamtbild,
      kapitel: [
        {
          modul: 'basis',
          einleitung: 'Ovale Grundform.',
          habits: [],
          sektionen: [
            {
              titel: 'Dein neuer Look',
              einschaetzung: imKapitel,
              empfehlungen: [],
              produkte: [],
            },
          ],
        },
      ],
      plan: {},
    };
  }

  it('ein Name, der oben und unten steht', () => {
    const befund = nachbereiten(
      report(
        'Ein Textured Crop bringt oben Struktur.',
        'Vorschlag: ein Textured Crop mit mittelhohem Fade.',
      ),
      vorgabe,
    );

    expect(befund.doppelteNamen).toEqual(['Textured Crop']);
  });

  it('aber keinen, der nur im Kapitel steht', () => {
    const befund = nachbereiten(
      report(
        'Die Richtung geht zu klaren Kanten und mehr Ruhe.',
        'Vorschlag: ein Textured Crop mit mittelhohem Fade.',
      ),
      vorgabe,
    );

    expect(befund.doppelteNamen).toEqual([]);
  });

  it('und kein Wort am Satzanfang', () => {
    // Im Deutschen steht dort jedes Wort gross – „Deine Kieferlinie" waere
    // sonst ein Treffer und die Meldung waere wertlos.
    const befund = nachbereiten(
      report(
        'Deine Kieferlinie traegt das gut.',
        'Deine Kieferlinie ist der Grund fuer diesen Vorschlag.',
      ),
      vorgabe,
    );

    expect(befund.doppelteNamen).toEqual([]);
  });

  it('ohne Gesamtbild gibt es nichts zu melden', () => {
    const befund = nachbereiten(
      report('', 'Vorschlag: ein Textured Crop.'),
      vorgabe,
    );

    expect(befund.doppelteNamen).toEqual([]);
  });

  it('das Gesamtbild ueberlebt die Nachbereitung', () => {
    const befund = nachbereiten(
      report('Die Richtung geht zu klaren Kanten.', 'Ein Crop.'),
      vorgabe,
    );

    expect(befund.ergebnis.gesamtbild).toBe(
      'Die Richtung geht zu klaren Kanten.',
    );
  });
});
