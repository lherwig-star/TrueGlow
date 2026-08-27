import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import { ANKER, ankerListe } from '../src/labels';
import type { Sprache } from '../src/sprache';

/**
 * Der Wenn-dann-Anker an jeder Tagesaufgabe.
 *
 * "Gesicht eincremen" ist ein Vorsatz. "Nach dem Zaehneputzen: Gesicht
 * eincremen" ist ein Ablauf – und genau das ist die Technik, mit der aus
 * Aufgaben Gewohnheiten werden (DECISIONS 44).
 *
 * Der teuerste Fehler waere hier ein deutscher Anker im englischen Report:
 * Das Modell schreibt woertlich ab, was der Prompt woertlich nennt
 * (DECISIONS 36). Der letzte Block prueft genau das.
 */

function daten(sprache: Sprache, freitext = ''): AnalysePromptDaten {
  return {
    sprache,
    ausrichtung: 'maennlich',
    modus: 'verfeinern',
    module: ['basis'],
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [], zwecke: [] },
    richtung: { ziele: [], freitext },
  };
}

describe('Der Prompt verlangt den Anker', () => {
  const prompt = systemPrompt(daten('de'));

  it('nennt die Regel fuer jede Aufgabe in jedem Kapitel', () => {
    expect(prompt).toContain('Wenn-dann-Anker');
    expect(prompt).toContain('gilt für JEDE Aufgabe in "habits"');
  });

  it('gibt die Form vor: Auslöser, Doppelpunkt, Handlung', () => {
    expect(prompt).toContain('einen Doppelpunkt, dann die Handlung');
  });

  it('verbietet Uhrzeiten und vage Angaben', () => {
    expect(prompt).toContain('Niemals eine Uhrzeit');
    expect(prompt).toContain('regelmäßig');
  });

  it('begrenzt, wie oft derselbe Anker vorkommt', () => {
    // Sieben Aufgaben nach dem Zaehneputzen sind keine Routine.
    expect(prompt).toContain('höchstens zweimal im ganzen Report');
  });

  it('ersetzt die Zeitpunkt-Regel nicht, sondern erfuellt sie', () => {
    expect(prompt).toContain('ZEITPUNKT');
    expect(prompt).toContain('ersetzt die Zeitpunkt-Regel nicht');
  });

  it('laesst Platz fuer den Anker in der Zeichengrenze', () => {
    // 60 Zeichen reichten nicht mehr, sobald vorn ein Anker steht.
    expect(prompt).toContain('jeder unter 80 Zeichen');
  });

  it('gilt auch fuer die Aufgaben aus dem Freitext', () => {
    const mitZiel = systemPrompt(daten('de', 'aufhören zu rauchen'));

    expect(mitZiel).toContain('Der Wenn-dann-Anker gilt auch hier');
    expect(mitZiel).toContain('Auslöser stattdessen die');
  });
});

describe('Die Anker stehen in der Zielsprache', () => {
  it('deutsch im deutschen Prompt', () => {
    const prompt = systemPrompt(daten('de'));

    expect(prompt).toContain('"nach dem Zähneputzen"');
    expect(prompt).toContain('"vor dem Schlafengehen"');
  });

  it('englisch im englischen Prompt', () => {
    const prompt = systemPrompt(daten('en'));

    expect(prompt).toContain('"after brushing your teeth"');
    expect(prompt).toContain('"before bed"');
  });

  it('kein einziger deutscher Anker im englischen Prompt', () => {
    // Der Fehler, den DECISIONS 36 beschreibt – hier fuer die Anker.
    const prompt = systemPrompt(daten('en', 'quit smoking'));

    for (const eintrag of ANKER) {
      expect(prompt, eintrag.de).not.toContain(eintrag.de);
    }
  });

  it('jeder Anker liegt in beiden Sprachen vor', () => {
    for (const eintrag of ANKER) {
      expect(eintrag.de.trim().length).toBeGreaterThan(0);
      expect(eintrag.en.trim().length).toBeGreaterThan(0);
      expect(eintrag.de).not.toBe(eintrag.en);
    }
  });

  it('die Liste kommt in Anfuehrungszeichen, damit sie abgeschrieben wird', () => {
    expect(ankerListe('de')).toContain('"nach dem Aufstehen"');
    expect(ankerListe('en')).toContain('"after getting up"');
  });
});
