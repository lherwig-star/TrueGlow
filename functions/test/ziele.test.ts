import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import { SEKTIONEN } from '../src/labels';
import type { Ausrichtung } from '../src/ausrichtung';
import type { Sprache } from '../src/sprache';

/**
 * Was der Nutzer bei "Deine Richtung" frei hineinschreibt, soll in der
 * Tagesliste ankommen und nicht nur in den Fließtexten.
 *
 * Begruendung in DECISIONS 37: Gearbeitet wird mit der Checkliste. Ein
 * Wunsch, der es nicht bis dorthin schafft, ist fuer den Nutzer nicht
 * passiert.
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

  it('nennt "basis" als Auffangkapitel', () => {
    // Ein Wunsch wie "gepflegtere Haende" passt in kein Kapitel. Ohne
    // Auffangort faellt er unter den Tisch.
    const prompt = systemPrompt(daten({ freitext: 'gepflegtere Hände' }));

    expect(prompt).toContain('"basis"');
    expect(prompt).toContain('gibt es\n  keins');
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

describe('Die Zielsektion folgt der Zielsprache', () => {
  it('heisst auf Deutsch "Dein Ziel" und auf Englisch "Your goal"', () => {
    expect(systemPrompt(daten({ sprache: 'de', freitext: 'mehr Wasser' })))
      .toContain('GENAU "Dein Ziel" lautet');
    expect(systemPrompt(daten({ sprache: 'en', freitext: 'drink more water' })))
      .toContain('GENAU "Your goal" lautet');
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

      expect(prompt, ausrichtung).toContain('GENAU "Your goal" lautet');
      expect(prompt, ausrichtung).not.toContain(SEKTIONEN.ziel.de);
    }
  });
});
