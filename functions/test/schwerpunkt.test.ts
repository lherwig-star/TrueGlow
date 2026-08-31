import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import type { Modul } from '../src/labels';

/**
 * Die Schwerpunkte aus dem Onboarding – DECISIONS 60.
 *
 * Bis dahin wirkten sie nur über eine Zeile („gewichte stärker"), und am
 * fertigen Report war nicht zu erkennen, ob jemand überhaupt etwas
 * angekreuzt hatte. Hier steht, was der Prompt jetzt verlangt: eine Zahl
 * statt eines Adverbs – und die Kapitelgrenze bleibt trotzdem stehen.
 */

function daten(
  fokus: string[],
  module: Modul[] = ['basis', 'hautFarbtyp'],
): AnalysePromptDaten {
  return {
    sprache: 'de',
    ausrichtung: 'maennlich',
    modus: 'verfeinern',
    module,
    profil: { fokus },
    figur: {},
    stil: { ziele: [], zwecke: [] },
    richtung: { ziele: [], freitext: '' },
    techniken: [],
  };
}

describe('Mit Schwerpunkten', () => {
  const prompt = systemPrompt(daten(['haut', 'haare']));

  it('stehen sie namentlich im Prompt', () => {
    expect(prompt).toContain('Gewünschte Schwerpunkte: Haut, Haare');
  });

  it('und der Prompt sagt, was das zaehlbar heisst', () => {
    // „Staerker gewichten" ist ein Adverb. Nachzaehlen laesst sich nur eine
    // Zahl.
    expect(prompt).toContain('sind eine Vorgabe, keine Stimmung');
    expect(prompt).toContain('mindestens eine Empfehlung mehr');
    expect(prompt).toContain('mindestens eine Tagesaufgabe');
  });

  it('die Kapitelgrenze bleibt stehen', () => {
    // Ein Schwerpunkt verschiebt Gewicht innerhalb der bestellten Kapitel.
    // Er erfindet keins und traegt nichts in ein fremdes hinein – das ist
    // dieselbe Grenze wie beim Zielkapitel (DECISIONS 39).
    expect(prompt).toContain('erfinde dafür kein');
    expect(prompt).toContain('in kein fremdes hinein');
  });

  it('und die uebrigen Bereiche werden nicht duenner', () => {
    expect(prompt).toContain('werden dadurch nicht dünner');
  });

  it('auf Englisch bleibt der Prompt englisch', () => {
    const englisch = systemPrompt({ ...daten(['haut']), sprache: 'en' });

    expect(englisch).toContain('Gewünschte Schwerpunkte: skin');
    expect(englisch).toContain('Every text field in ENGLISH.');
  });
});

describe('Ohne Schwerpunkte', () => {
  it('steht keine Schwerpunkt-Zeile im Prompt', () => {
    const prompt = systemPrompt(daten([]));

    expect(prompt).not.toContain('Gewünschte Schwerpunkte');
    expect(prompt).not.toContain('sind eine Vorgabe, keine Stimmung');
  });

  it('sondern die ausdrueckliche Gleichbehandlung', () => {
    // Ohne diese Zeile stuende dort gar nichts, und das Modell duerfte sich
    // selbst einen Schwerpunkt aussuchen.
    expect(systemPrompt(daten([]))).toContain(
      'Behandle alle angeforderten Kapitel gleich gewichtet.',
    );
  });
});

describe('Ein Schwerpunkt ohne Kapitel', () => {
  it('faellt weg, statt sich ein Kapitel zu suchen', () => {
    // „Fitness-Habits" waehlt „Figur & Passform" vor. Waehlt der Nutzer das
    // Modul wieder ab, bleibt der Schwerpunkt im Prompt stehen – und der
    // Prompt sagt ausdruecklich, was dann damit zu passieren hat.
    const prompt = systemPrompt(daten(['fitness'], ['basis']));

    expect(prompt).toContain('Gewünschte Schwerpunkte: Fitness-Habits');
    expect(prompt).toContain(
      'Gehört ein Schwerpunkt zu keinem der angeforderten Kapitel, lass ihn '
        + 'weg',
    );
    // Nicht als Kapitel: Der Name kommt im Prompt nur noch als Beispiel in
    // der Habit-Regel vor, nicht als bestelltes Kapitel.
    expect(prompt).not.toContain('- "figurPassform" – Figur & Passform');
  });
});
