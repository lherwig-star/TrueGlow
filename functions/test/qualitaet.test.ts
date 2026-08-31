import { describe, expect, it, vi } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import { istFloskel, melde, nachbereiten } from '../src/nachbereitung';
import { ZIELKAPITEL, type Modul } from '../src/labels';

/**
 * Die Antwortqualitaet, soweit sie sich pruefen laesst.
 *
 * Der Anlass steht in DECISIONS 40: Ueber mehrere Analysen hinweg kamen
 * Empfehlungen zurueck, die auch ohne die Fotos richtig gewesen waeren, und
 * Tagesaufgaben, deren Zeitpunkt keinen Sinn ergab – den Bart am Abend in
 * Form zu bringen, kurz bevor man sich hinlegt.
 *
 * Pruefen laesst sich davon zweierlei: dass die Forderungen ueberhaupt im
 * Prompt stehen, und dass die Zaehlung flacher Aufgaben das Richtige zaehlt.
 * Ob die Antwort dann besser ist, zeigt erst der Geraetetest.
 */

function daten(freitext = ''): AnalysePromptDaten {
  return {
    sprache: 'de',
    ausrichtung: 'maennlich',
    modus: 'verfeinern',
    module: ['basis', 'hautFarbtyp'],
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [], zwecke: [] },
    richtung: { ziele: [], freitext },
    techniken: [],
  };
}

describe('Der Prompt verlangt Qualitaet, nicht nur Inhalt', () => {
  const prompt = systemPrompt(daten());

  it('verlangt zu jeder Empfehlung ein beobachtetes Merkmal', () => {
    expect(prompt).toContain('BEOBACHTUNG');
    expect(prompt).toContain('Haarstruktur');
    expect(prompt).toContain('Floskel');
  });

  it('verlangt einen Zeitpunkt, der zum Zweck passt', () => {
    expect(prompt).toContain('ZEITPUNKT');
    expect(prompt).toContain('Was bringt sie zu genau dieser Tageszeit?');
  });

  it('nennt den Bart am Abend als Musterfall einer sinnlosen Aufgabe', () => {
    // Das Negativbeispiel aus dem Geraetetest. Es steht im Prompt, weil eine
    // abstrakte Regel ("sinnvoller Zeitpunkt") folgenlos blieb.
    expect(prompt).toContain('Bart am Abend in Form bringt');
    expect(prompt).toContain('danach wird geschlafen');
  });

  it('verlangt pro Kapitel mindestens einen Tipp ueber die Basics hinaus', () => {
    expect(prompt).toContain('TIEFE');
    expect(prompt).toContain('In JEDEM Kapitel steht mindestens eine');
    expect(prompt).toContain('erste Seite einer Suchmaschine');
  });

  it('nennt kein fertiges Musterhabit, das abgeschrieben werden koennte', () => {
    // DECISIONS 36: Was der Prompt woertlich nennt, schreibt das Modell
    // woertlich ab. Ein deutscher Beispielsatz stuende sonst in einem
    // englischen Report – die Beispiele sind deshalb beschrieben.
    const englisch = systemPrompt({ ...daten(), sprache: 'en' });

    expect(englisch).not.toContain('Bart morgens');
    expect(englisch).not.toContain('"Gesicht waschen"');
  });

  it('steht in jedem Prompt, auch ohne Ziele', () => {
    // Die Qualitaetsregeln haengen an nichts – sie gelten immer.
    expect(prompt).toContain('Qualität der Empfehlungen');
    expect(systemPrompt({ ...daten(), sprache: 'en' })).toContain(
      'Qualität der Empfehlungen',
    );
  });
});

describe('Flache Tagesaufgaben werden erkannt', () => {
  it('erkennt den blossen Gemeinplatz', () => {
    for (const habit of [
      'Gesicht waschen',
      'Wasser trinken',
      'Mehr Wasser trinken',
      'Eincremen',
      'Zähne putzen',
      'Wash your face',
      'Drink more water',
      'Get enough sleep',
    ]) {
      expect(istFloskel(habit), habit).toBe(true);
    }
  });

  it('laesst alles stehen, was einen Zusatz mitbringt', () => {
    // Der Unterschied zwischen Floskel und Aufgabe ist genau dieser Zusatz:
    // Zeitpunkt, Technik oder Zweck.
    for (const habit of [
      'Morgens vor dem Rasieren mit lauwarmem Wasser waschen',
      'Nach dem Duschen die trockenen Stellen an der Kinnlinie eincremen',
      'Ein Glas Wasser trinken, wenn das Rauchverlangen kommt',
      'Brush teeth before the morning shower, not after',
    ]) {
      expect(istFloskel(habit), habit).toBe(false);
    }
  });

  it('zaehlt sie im Befund, entfernt sie aber nicht', () => {
    // Entfernen hiesse: ersatzlos. Eine Checkliste mit zwei Punkten ist
    // schlechter als eine mit einem flachen darin.
    const befund = nachbereiten(
      {
        kapitel: [
          {
            modul: 'basis',
            einleitung: 'Text',
            habits: ['Gesicht waschen', 'Scheitel morgens nach links föhnen'],
            sektionen: [{ titel: 'Frisur' }],
          },
        ],
      },
      { sprache: 'de', ausrichtung: 'maennlich', module: ['basis'] },
    );

    expect(befund.floskeln).toEqual(['Gesicht waschen']);
    expect((befund.ergebnis.kapitel as any[])[0].habits).toHaveLength(2);
  });

  it('schreibt sie ins Protokoll', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});

    melde(
      {
        ergebnis: {},
        fremdeKapitel: [],
        entfernteSektionen: [],
        entfernteHabits: 0,
        floskeln: ['Wasser trinken'],
        zielkapitelFehlt: false,
        doppelteNamen: [],
        erfundeneMarken: [],
        fehlendeTechniken: [],
      },
      { sprache: 'de' },
    );

    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('ohne Bezug zu den Fotos'),
    );
    warn.mockRestore();
  });
});

describe('Das Zielkapitel in der Nachbereitung', () => {
  const module = ['basis'] as Modul[];

  function zielkapitel() {
    return {
      modul: ZIELKAPITEL,
      einleitung: 'Du willst aufhören zu rauchen.',
      habits: ['Bei Verlangen ein Glas kaltes Wasser trinken'],
      sektionen: [{ titel: 'Dein Ziel' }],
    };
  }

  it('bleibt stehen, wenn ein Freitext vorlag', () => {
    const befund = nachbereiten(
      { kapitel: [zielkapitel()] },
      {
        sprache: 'de',
        ausrichtung: 'maennlich',
        module,
        richtung: { freitext: 'aufhören zu rauchen' },
      },
    );

    expect(befund.fremdeKapitel).toEqual([]);
    expect(befund.ergebnis.kapitel).toHaveLength(1);
  });

  it('faellt heraus, wenn gar kein Freitext vorlag', () => {
    // Ohne Freitext hat es niemand angefordert – dann ist es ein erfundenes
    // Kapitel wie jedes andere.
    const befund = nachbereiten(
      { kapitel: [zielkapitel()] },
      { sprache: 'de', ausrichtung: 'maennlich', module },
    );

    expect(befund.fremdeKapitel).toEqual([ZIELKAPITEL]);
    expect(befund.ergebnis.kapitel).toHaveLength(0);
  });

  it('meldet, wenn es trotz Freitext fehlt', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          {
            modul: 'basis',
            einleitung: 'Text',
            habits: [],
            sektionen: [{ titel: 'Frisur' }],
          },
        ],
      },
      {
        sprache: 'de',
        ausrichtung: 'maennlich',
        module,
        richtung: { freitext: 'aufhören zu rauchen' },
      },
    );

    expect(befund.zielkapitelFehlt).toBe(true);
  });

  it('meldet nichts, wenn es gar keinen geben sollte', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          {
            modul: 'basis',
            einleitung: 'Text',
            habits: [],
            sektionen: [{ titel: 'Frisur' }],
          },
        ],
      },
      { sprache: 'de', ausrichtung: 'maennlich', module },
    );

    expect(befund.zielkapitelFehlt).toBe(false);
  });
});
