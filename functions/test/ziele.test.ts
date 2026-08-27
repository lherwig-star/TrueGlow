import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import { SEKTIONEN, ZIELKAPITEL } from '../src/labels';
import type { Ausrichtung } from '../src/ausrichtung';
import type { Sprache } from '../src/sprache';

/**
 * Was der Nutzer bei "Deine Richtung" frei hineinschreibt, soll in der
 * Tagesliste ankommen und nicht nur in den Fließtexten.
 *
 * Begruendung in DECISIONS 37: Gearbeitet wird mit der Checkliste. Ein
 * Wunsch, der es nicht bis dorthin schafft, ist fuer den Nutzer nicht
 * passiert.
 *
 * Seit DECISIONS 39 bekommt der Freitext dafuer ein eigenes Kapitel. Am
 * Geraet war zu sehen, warum: "Bei Rauchverlangen ein Glas Wasser trinken"
 * stand unter "Haare & Bart", weil das Modell dort das beste passende
 * Kapitel sah. Es gab keins.
 */

function daten(options: {
  sprache?: Sprache;
  ausrichtung?: Ausrichtung;
  freitext?: string;
  ziele?: string[];
}): AnalysePromptDaten {
  return {
    sprache: options.sprache ?? 'de',
    ausrichtung: options.ausrichtung ?? 'maennlich',
    modus: 'verfeinern',
    module: ['basis'],
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [] },
    richtung: { ziele: options.ziele ?? [], freitext: options.freitext ?? '' },
  };
}

describe('Freitext steuert die Tagesaufgaben', () => {
  it('ohne Freitext steht keine einzige Freitextregel im Prompt', () => {
    // Alte Analysen und alle, die das Feld leer lassen, sollen einen Prompt
    // bekommen, der sich nicht veraendert hat.
    const prompt = systemPrompt(daten({}));

    expect(prompt).not.toContain('Der Freitext ist der wichtigste Teil');
    expect(prompt).not.toContain(SEKTIONEN.ziel.de);
    expect(prompt).not.toContain(SEKTIONEN.ziel.en);
  });

  it('auch dann nicht, wenn nur Chips gewaehlt sind', () => {
    // Die anklickbaren Punkte sind grobe Ueberbegriffe zum Look. Sie
    // rechtfertigen keine eigene Zielsektion.
    const prompt = systemPrompt(daten({ ziele: ['markanter'] }));

    expect(prompt).not.toContain('Der Freitext ist der wichtigste Teil');
  });

  it('mit Freitext verlangt der Prompt Aufgaben daraus', () => {
    const prompt = systemPrompt(daten({ freitext: 'Ich will aufhören zu rauchen' }));

    expect(prompt).toContain('Der Freitext ist der wichtigste Teil');
    expect(prompt).toContain('"habits"');
    expect(prompt).toContain('heute abhakbar');
  });

  it('verlangt Ausloeser-Strategien bei Gewohnheiten', () => {
    const prompt = systemPrompt(daten({ freitext: 'weniger rauchen' }));

    expect(prompt).toContain('Auslöser-Strategien');
    expect(prompt).toContain('Feierabend');
  });

  it('verbietet Heilaussagen und den erhobenen Zeigefinger', () => {
    const prompt = systemPrompt(daten({ freitext: 'aufhören zu rauchen' }));

    expect(prompt).toContain('KEINE Heilaussagen');
    expect(prompt).toContain('erhobener Zeigefinger');
    expect(prompt).toContain('fachliche Unterstützung');
  });
});

describe('Der Freitext bekommt ein eigenes Kapitel', () => {
  it('ohne Freitext gibt es das Kapitel nicht', () => {
    const prompt = systemPrompt(daten({}));

    expect(prompt).not.toContain(ZIELKAPITEL);
  });

  it('Chips allein erzeugen es auch nicht', () => {
    const prompt = systemPrompt(daten({ ziele: ['markanter', 'gepflegter'] }));

    expect(prompt).not.toContain(ZIELKAPITEL);
  });

  it('mit Freitext wird es als Kapitel angefordert', () => {
    const prompt = systemPrompt(daten({ freitext: 'aufhören zu rauchen' }));

    expect(prompt).toContain(`- "${ZIELKAPITEL}" – Persönliche Ziele`);
  });

  it('steht hinter den Look-Kapiteln', () => {
    const prompt = systemPrompt(daten({ freitext: 'aufhören zu rauchen' }));

    expect(prompt.indexOf(`- "${ZIELKAPITEL}" – Persönliche Ziele`))
      .toBeGreaterThan(prompt.indexOf('- "basis" – Gesicht'));
  });

  it('verbietet Freitext-Aufgaben in jedem anderen Kapitel', () => {
    // Der eigentliche Fund am Geraet: Die Aufgaben landeten unter
    // "Haare & Bart". Auch die Basis ist kein Auffangort mehr.
    const prompt = systemPrompt(daten({ freitext: 'gepflegtere Hände' }));

    expect(prompt).toContain('AUSSCHLIESSLICH');
    expect(prompt).toContain('auch "basis" nicht');
  });

  it('nimmt das Zielkapitel von der Regel "4 bis 7 Aufgaben" aus', () => {
    // Ein einziger Wunsch ergibt eine bis drei Aufgaben. Sieben waeren
    // erfunden.
    const prompt = systemPrompt(daten({ freitext: 'mehr Wasser trinken' }));

    expect(prompt).toContain('Einzige Ausnahme von der Zahl 4 bis 7');
  });

  it('nennt einen Ort fuer Wuensche ohne eigenes Kapitel', () => {
    // "Gepflegtere Haende" passt in kein Look-Kapitel. Ohne einen Ort faellt
    // der Wunsch unter den Tisch – unsichtbar, weil niemand vermisst, was er
    // nicht sieht.
    const prompt = systemPrompt(daten({ freitext: 'gepflegtere Hände' }));

    expect(prompt).toContain('gepflegtere Hände');
    expect(prompt).toContain('eine eigene Sektion');
  });
});

describe('Die Zielsektion folgt der Zielsprache', () => {
  it('heisst auf Deutsch "Dein Ziel" und auf Englisch "Your goal"', () => {
    expect(systemPrompt(daten({ sprache: 'de', freitext: 'mehr Wasser' })))
      .toContain('GENAU "Dein Ziel"');
    expect(systemPrompt(daten({ sprache: 'en', freitext: 'drink more water' })))
      .toContain('GENAU "Your goal"');
  });

  it('im englischen Prompt steht der deutsche Name nirgends', () => {
    const prompt = systemPrompt(daten({ sprache: 'en', freitext: 'quit smoking' }));

    expect(prompt).not.toContain(SEKTIONEN.ziel.de);
  });

  it('gilt in allen drei Ausrichtungen', () => {
    for (const ausrichtung of ['maennlich', 'weiblich', 'neutral'] as const) {
      const prompt = systemPrompt(
        daten({ sprache: 'en', ausrichtung, freitext: 'quit smoking' }),
      );

      expect(prompt, ausrichtung).toContain('GENAU "Your goal"');
      expect(prompt, ausrichtung).not.toContain(SEKTIONEN.ziel.de);
    }
  });
});
