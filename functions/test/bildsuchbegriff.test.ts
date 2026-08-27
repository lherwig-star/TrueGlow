import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import type { Ausrichtung } from '../src/ausrichtung';
import { nachbereiten, putzeSuchbegriff } from '../src/nachbereitung';

/**
 * Beispielbilder unter den Vorschlägen – DECISIONS 69.
 *
 * Der Suchbegriff ist das einzige Stück, das vom Modell kommt. Alles danach
 * hängt daran: Ein deutscher, ein zu langer oder ein erfundener Begriff
 * bedeutet Fotos, die nicht zum Vorschlag passen.
 */

function daten(ausrichtung: Ausrichtung = 'maennlich'): AnalysePromptDaten {
  return {
    sprache: 'de',
    ausrichtung,
    modus: 'verfeinern',
    module: ['basis', 'stilKleiderschrank'],
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [] },
    richtung: { ziele: [], freitext: '' },
  };
}

describe('Der Prompt verlangt den Suchbegriff', () => {
  it('als Feld im Schema, in beiden Modi', () => {
    for (const modus of ['verfeinern', 'entdecken'] as const) {
      const prompt = systemPrompt({ ...daten(), modus });
      expect(prompt, modus).toContain('"bildSuchbegriff"');
    }
  });

  it('immer auf Englisch – unabhängig von der Report-Sprache', () => {
    for (const sprache of ['de', 'en'] as const) {
      const prompt = systemPrompt({ ...daten(), sprache });
      expect(prompt, sprache).toContain('IMMER auf ENGLISCH');
    }
  });

  it('generisch: keine Marke, kein Prominenter', () => {
    const prompt = systemPrompt(daten());
    expect(prompt).toContain('Keine Marke');
    expect(prompt).toContain('kein Prominenter');
  });

  it('und null, wo ein Foto nichts zeigen könnte', () => {
    expect(systemPrompt(daten())).toContain('Routine: null');
  });

  it('die Beispiele sind als Muster für die FORM markiert', () => {
    // Ohne diese Markierung schreibt ein Modell sie wörtlich ab
    // (DECISIONS 36) – dann zeigte jeder Report denselben Haarschnitt.
    expect(systemPrompt(daten())).toContain('Muster für die FORM');
  });

  it('das Wort für die Person hängt an der Ausrichtung', () => {
    // Ohne dieses Wort liefert eine Fotobibliothek zu "french crop haircut"
    // überwiegend Männer – auch für eine Nutzerin.
    expect(systemPrompt(daten('maennlich'))).toContain(
      'french crop haircut men',
    );
    expect(systemPrompt(daten('weiblich'))).toContain(
      'french crop haircut women',
    );
  });

  it('bei "neutral" bleibt es weg', () => {
    const prompt = systemPrompt(daten('neutral'));
    expect(prompt).toContain('french crop haircut"');
    expect(prompt).not.toContain('french crop haircut men');
    expect(prompt).not.toContain('french crop haircut women');
    // Und es wird auch nicht darum gebeten.
    expect(prompt).not.toContain('Häng das Wort');
  });
});

describe('putzeSuchbegriff', () => {
  it('nimmt einen sauberen Begriff und schreibt ihn klein', () => {
    // Klein, weil der Begriff der Schlüssel des Server-Caches ist.
    expect(putzeSuchbegriff('French Crop Haircut Men')).toBe(
      'french crop haircut men',
    );
  });

  it('entfernt Anführungszeichen und Satzzeichen am Ende', () => {
    expect(putzeSuchbegriff('"short stubble beard men".')).toBe(
      'short stubble beard men',
    );
    expect(putzeSuchbegriff('„smart casual outfit“')).toBe(
      'smart casual outfit',
    );
  });

  it('wirft Umlaute weg', () => {
    // Ein Umlaut heißt: Die Regel "immer Englisch" wurde überlesen.
    expect(putzeSuchbegriff('kurzer Vollbart Männer')).toBeUndefined();
    expect(putzeSuchbegriff('weißes Hemd')).toBeUndefined();
  });

  it('aber deutsche Begriffe ohne Umlaut kommen durch', () => {
    // Festgehalten, weil es aussieht wie eine Lücke und keine ist: Eine
    // Spracherkennung auf zwei bis sechs Wörtern rät mehr, als sie erkennt.
    // Was hier durchkommt, findet in der Fotobibliothek nichts – und ohne
    // Treffer fällt die Bilderreihe weg.
    expect(putzeSuchbegriff('kurzer Vollbart')).toBe('kurzer vollbart');
  });

  it('wirft ganze Sätze weg', () => {
    expect(
      putzeSuchbegriff('a photo of a man with a short textured haircut'),
    ).toBeUndefined();
  });

  it('wirft Leeres und Falschgetipptes weg', () => {
    expect(putzeSuchbegriff('')).toBeUndefined();
    expect(putzeSuchbegriff('   ')).toBeUndefined();
    expect(putzeSuchbegriff(null)).toBeUndefined();
    expect(putzeSuchbegriff(42)).toBeUndefined();
    expect(putzeSuchbegriff(['a', 'b'])).toBeUndefined();
  });

  it('lässt Bindestrich, Ziffer und Kaufmanns-Und stehen', () => {
    expect(putzeSuchbegriff('mid-length bob 90s women')).toBe(
      'mid-length bob 90s women',
    );
    expect(putzeSuchbegriff('shirt & chinos outfit men')).toBe(
      'shirt & chinos outfit men',
    );
  });
});

describe('Die Nachbereitung räumt die Begriffe auf', () => {
  const vorgabe = {
    sprache: 'de' as const,
    ausrichtung: 'maennlich' as const,
    module: ['basis' as const],
  };

  function report(...begriffe: unknown[]) {
    return {
      gesamtbild: 'Die Richtung geht zu klaren Kanten.',
      kapitel: [
        {
          modul: 'basis',
          einleitung: 'Ovale Grundform.',
          habits: [] as string[],
          sektionen: begriffe.map((b, i) => ({
            titel: `Sektion ${i + 1}`,
            bildSuchbegriff: b,
            einschaetzung: 'Text.',
            empfehlungen: [] as string[],
            produkte: [] as unknown[],
          })) as unknown[],
        },
      ],
      plan: {},
    };
  }

  function sektionen(befund: { ergebnis: Record<string, unknown> }) {
    const kapitel = befund.ergebnis.kapitel as Record<string, unknown>[];
    return kapitel[0].sektionen as Record<string, unknown>[];
  }

  it('behält den guten und wirft den schlechten weg', () => {
    const befund = nachbereiten(
      report('Textured Crop Haircut Men', 'kurzer Vollbart für Männer'),
      vorgabe,
    );

    expect(sektionen(befund)[0].bildSuchbegriff).toBe(
      'textured crop haircut men',
    );
    expect(sektionen(befund)[1]).not.toHaveProperty('bildSuchbegriff');
    expect(befund.verworfeneSuchbegriffe).toEqual([
      'kurzer Vollbart für Männer',
    ]);
  });

  it('null ist kein Fund, sondern die vorgesehene Antwort', () => {
    // "Hier hilft kein Foto" ist ausdrücklich erlaubt – eine Pflegeroutine
    // lässt sich nicht abbilden.
    const befund = nachbereiten(report(null), vorgabe);

    expect(sektionen(befund)[0]).not.toHaveProperty('bildSuchbegriff');
    expect(befund.verworfeneSuchbegriffe).toEqual([]);
  });

  it('ein fehlendes Feld bleibt fehlend', () => {
    const roh = report();
    roh.kapitel[0].sektionen.push({
      titel: 'Ohne',
      einschaetzung: 'Text.',
      empfehlungen: [],
      produkte: [],
    });

    const befund = nachbereiten(roh, vorgabe);
    expect(sektionen(befund)[0]).not.toHaveProperty('bildSuchbegriff');
    expect(befund.verworfeneSuchbegriffe).toEqual([]);
  });

  it('auch im weiblichen Modus, wo Sektionen entfernt werden', () => {
    // Der Bart-Zweig baut die Kapitel selbst neu zusammen. Ohne einen
    // eigenen Durchgang für die Begriffe blieben sie dort ungeputzt.
    const roh = {
      gesamtbild: 'Klarheit.',
      kapitel: [
        {
          modul: 'basis',
          einleitung: 'Text.',
          habits: [],
          sektionen: [
            {
              titel: 'Bart',
              bildSuchbegriff: 'Vollbart Männer',
              einschaetzung: 'Text.',
              empfehlungen: [],
              produkte: [],
            },
            {
              titel: 'Frisur',
              bildSuchbegriff: 'Long Bob Haircut Women',
              einschaetzung: 'Text.',
              empfehlungen: [],
              produkte: [],
            },
          ],
        },
      ],
      plan: {},
    };

    const befund = nachbereiten(roh, { ...vorgabe, ausrichtung: 'weiblich' });
    const uebrig = sektionen(befund);

    expect(uebrig).toHaveLength(1);
    expect(uebrig[0].bildSuchbegriff).toBe('long bob haircut women');
    // Der Begriff der entfernten Bart-Sektion wird nicht mehr gemeldet –
    // sie ist ja gar nicht mehr da.
    expect(befund.verworfeneSuchbegriffe).toEqual([]);
  });
});
