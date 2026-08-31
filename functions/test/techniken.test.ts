import { describe, expect, it, vi } from 'vitest';

import * as analyse from '../src/analyse_prompt';
import { leseAnalyse } from '../src/eingang';
import {
  TECHNIK,
  technikenFuer,
  techniklabels,
  type Techniknamen,
} from '../src/labels';
import { melde, nachbereiten } from '../src/nachbereitung';
import type { Sprache } from '../src/sprache';
import type { Ausrichtung } from '../src/ausrichtung';
import type { Modus } from '../src/modus';
import type { Modul } from '../src/labels';

/**
 * „Das will ich ausprobieren" auf der Serverseite – DECISIONS 79 und 80.
 *
 * Drei Zusagen werden geprueft: Der Server laesst nur durch, was zu dieser
 * Analyse passt; der Prompt nennt Takt und Vertraeglichkeit aus der Tabelle
 * statt aus dem Sprachgefuehl des Modells; und die Nachbereitung laesst
 * keine „Neu fuer dich"-Marke stehen, die der Nutzer nie angetippt hat.
 */

function daten(options: {
  techniken?: Techniknamen[];
  module?: Modul[];
  sprache?: Sprache;
  ausrichtung?: Ausrichtung;
  modus?: Modus;
} = {}): analyse.AnalysePromptDaten {
  return {
    sprache: options.sprache ?? 'de',
    ausrichtung: options.ausrichtung ?? 'maennlich',
    modus: options.modus ?? 'verfeinern',
    module: options.module ?? ['basis', 'hautFarbtyp'],
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [], zwecke: [] },
    richtung: { ziele: [], freitext: '' },
    techniken: options.techniken ?? [],
  };
}

const BILD = { typ: 'basisFrontal', daten: 'AAAA' };

describe('Der Katalog spiegelt die App', () => {
  it('jede Technik haengt an einem Kapitel, das es gibt', () => {
    const module = new Set<string>([
      'basis',
      'hautFarbtyp',
      'makeupAusstrahlung',
      'zaehneLaecheln',
      'figurPassform',
      'stilKleiderschrank',
    ]);

    for (const [name, technik] of Object.entries(TECHNIK)) {
      expect(module.has(technik.modul), name).toBe(true);
    }
  });

  it('keine Technik jenseits der Sicherheitsgrenze', () => {
    // Dieselbe Liste wie im Dart-Test: nichts Invasives, nichts
    // Medizinisches, kein Looksmaxxing mit Verletzungsrisiko
    // (DECISIONS 79). Der Test faengt den Fall ab, dass jemand spaeter
    // „nur schnell" einen Eintrag ergaenzt.
    const verboten = [
      'dermaroller',
      'microneedling',
      'needling',
      'mewing',
      'mastic',
      'kaugummi',
      'kautraining',
      'fasten',
      'diät',
      'tretinoin',
      'retinol',
      'botox',
      'filler',
    ];

    for (const [name, technik] of Object.entries(TECHNIK)) {
      const felder = [
        name,
        technik.label.de,
        technik.label.en,
        technik.takt.de,
        technik.takt.en,
      ].join(' ').toLowerCase();

      for (const wort of verboten) {
        expect(felder.includes(wort), `${name} / ${wort}`).toBe(false);
      }
    }
  });

  it('jede Technik hat Takt und Vertraeglichkeit in beiden Sprachen', () => {
    for (const [name, technik] of Object.entries(TECHNIK)) {
      for (const sprache of ['de', 'en'] as const) {
        expect(technik.label[sprache].length, name).toBeGreaterThan(2);
        expect(technik.takt[sprache].length, name).toBeGreaterThan(2);
        expect(technik.hinweis[sprache].length, name).toBeGreaterThan(10);
      }
    }
  });
});

describe('technikenFuer siebt aus', () => {
  it('nur Techniken zu bestellten Kapiteln', () => {
    const gewaehlt = technikenFuer(
      ['kopfhautmassage', 'guaSha'],
      ['basis'],
      'maennlich',
    );

    expect(gewaehlt).toEqual(['kopfhautmassage']);
  });

  it('nur Techniken, die es in dieser Ausrichtung gibt', () => {
    const module: Modul[] = ['basis', 'hautFarbtyp'];
    const alle = ['bartbuerste', 'nagelpflege'];

    expect(technikenFuer(alle, module, 'maennlich')).toEqual(['bartbuerste']);
    expect(technikenFuer(alle, module, 'weiblich')).toEqual(['nagelpflege']);
    // „divers" und „keine Angabe" lassen nichts weg.
    expect(technikenFuer(alle, module, 'neutral')).toEqual([
      'bartbuerste',
      'nagelpflege',
    ]);
  });

  it('erfundene Namen und Unsinn fallen weg', () => {
    expect(
      technikenFuer(
        ['mewing', 'guaSha', 42, null, { name: 'guaSha' }],
        ['hautFarbtyp'],
        'maennlich',
      ),
    ).toEqual(['guaSha']);
    expect(technikenFuer('guaSha', ['hautFarbtyp'], 'maennlich')).toEqual([]);
  });

  it('die Reihenfolge ist die der Tabelle, nicht die der Anfrage', () => {
    expect(
      technikenFuer(
        ['guaSha', 'kopfhautmassage'],
        ['basis', 'hautFarbtyp'],
        'maennlich',
      ),
    ).toEqual(['kopfhautmassage', 'guaSha']);
  });
});

describe('Der Weg durch leseAnalyse', () => {
  it('nimmt die Namen an und siebt dabei aus', () => {
    const eingang = leseAnalyse({
      sprache: 'de',
      ausrichtung: 'maennlich',
      module: ['hautFarbtyp'],
      techniken: ['guaSha', 'nagelpflege', 'oelziehen', 'erfunden'],
      bilder: [BILD],
    });

    // nagelpflege gibt es im maennlichen Modus nicht, oelziehen gehoert zu
    // einem Kapitel, das gar nicht bestellt wurde.
    expect(eingang.prompt.techniken).toEqual(['guaSha']);
  });

  it('ohne Feld bleibt die Liste leer', () => {
    const eingang = leseAnalyse({
      sprache: 'de',
      ausrichtung: 'maennlich',
      module: ['hautFarbtyp'],
      bilder: [BILD],
    });

    expect(eingang.prompt.techniken).toEqual([]);
  });
});

describe('Der Prompt', () => {
  it('bleibt ohne Auswahl Wort fuer Wort derselbe', () => {
    // Sonst liesse sich nie sagen, ob eine Aenderung an der Antwort von der
    // Auswahl kommt oder von etwas anderem.
    const ohne = analyse.systemPrompt(daten());

    expect(ohne).not.toContain('Das will ich ausprobieren');
    expect(ohne).not.toContain('"neu"');
  });

  it('nennt jede gewaehlte Technik mit Takt und Vertraeglichkeit', () => {
    const prompt = analyse.systemPrompt(
      daten({ techniken: ['kopfhautmassage', 'guaSha'] }),
    );

    expect(prompt).toContain('Das will ich ausprobieren');
    expect(prompt).toContain('"Gua Sha" (Kapitel "hautFarbtyp")');
    expect(prompt).toContain(TECHNIK.guaSha.takt.de);
    expect(prompt).toContain(TECHNIK.guaSha.hinweis.de);
    expect(prompt).toContain(TECHNIK.kopfhautmassage.takt.de);
  });

  it('verlangt sie und laesst kein Weglassen zu', () => {
    const prompt = analyse.systemPrompt(daten({ techniken: ['guaSha'] }));

    expect(prompt).toContain('MUSS im Report vorkommen');
    expect(prompt).toContain('Keine einzige darf fehlen');
    // Und die Marke im Report.
    expect(prompt).toContain('"neu": ["Name einer ausprobierten Technik');
  });

  it('nennt die Sicherheitsgrenze ausdruecklich', () => {
    for (const techniken of [[], ['guaSha'] as Techniknamen[]]) {
      const prompt = analyse.systemPrompt(daten({ techniken }));
      for (const wort of ['Dermaroller', 'Mewing', 'Diät-Regime']) {
        expect(prompt, `${techniken.length} / ${wort}`).toContain(wort);
      }
    }
  });

  it('macht aus einem Wochentakt keine Tagesaufgabe', () => {
    const woechentlich = analyse.systemPrompt(daten({ techniken: ['guaSha'] }));
    const taeglich = analyse.systemPrompt(
      daten({ techniken: ['kopfhautmassage'], module: ['basis'] }),
    );

    // Bewusst der ganze Satz und nicht nur „KEINE Tagesaufgabe": Der
    // Prompt sagt weiter unten ohnehin, dass "plan" keine Tagesaufgaben
    // enthaelt – ein kuerzeres Stueck traefe auch das.
    expect(woechentlich).toContain('ist die Aufgabe KEINE Tagesaufgabe');
    expect(woechentlich).toContain('"Zweimal die Woche"');
    // Bei lauter taeglichen Techniken waere die Regel eine Einladung, sich
    // eine Wochenaufgabe auszudenken.
    expect(taeglich).not.toContain('ist die Aufgabe KEINE Tagesaufgabe');
  });

  it('schreibt Namen, Takt und Hinweis in der Zielsprache', () => {
    const englisch = analyse.systemPrompt(
      daten({ techniken: ['guaSha'], sprache: 'en' }),
    );

    expect(englisch).toContain('"Gua sha"');
    expect(englisch).toContain(TECHNIK.guaSha.takt.en);
    expect(englisch).toContain('"Twice a week"');
    expect(englisch).not.toContain(TECHNIK.guaSha.hinweis.de);
  });

  it('verlangt Tiefe auch ohne jede Auswahl', () => {
    const prompt = analyse.systemPrompt(daten());

    expect(prompt).toContain('Mehr als die Basics');
    expect(prompt).toContain('mindestens EIN Vorschlag');
    // Beispiele je bestelltem Kapitel, in der Zielsprache – und
    // ausdruecklich als Muster fuer das Niveau markiert (DECISIONS 36).
    expect(prompt).toContain('basis: "Kopfhautmassage"');
    expect(prompt).toContain('hautFarbtyp: "Gua Sha"');
    expect(prompt).toContain('nicht für den Inhalt');
  });

  it('nennt als Beispiel nur Kapitel, die es im Report gibt', () => {
    const prompt = analyse.systemPrompt(daten({ module: ['basis'] }));

    expect(prompt).toContain('basis: "Kopfhautmassage"');
    expect(prompt).not.toContain('hautFarbtyp: ');
  });
});

describe('Die Nachbereitung der Marken', () => {
  function antwort(neu: unknown) {
    return {
      kapitel: [
        {
          modul: 'hautFarbtyp',
          sektionen: [{ titel: 'Haut', neu }],
        },
      ],
    };
  }

  const vorgabe = {
    sprache: 'de' as const,
    ausrichtung: 'maennlich' as const,
    module: ['hautFarbtyp'] as Modul[],
    techniken: ['guaSha'] as Techniknamen[],
  };

  it('laesst eine gewaehlte Technik stehen', () => {
    const befund = nachbereiten(antwort(['Gua Sha']), vorgabe);
    const sektion = (befund.ergebnis.kapitel as any[])[0].sektionen[0];

    expect(sektion.neu).toEqual(['Gua Sha']);
    expect(befund.fehlendeTechniken).toEqual([]);
    expect(befund.erfundeneMarken).toEqual([]);
  });

  it('fuehrt eine abweichende Schreibweise zurueck', () => {
    // Das Modell schreibt „gua sha" statt „Gua Sha" – die App erkennt den
    // Namen sonst nicht wieder.
    const befund = nachbereiten(antwort(['  gua   sha ']), vorgabe);
    const sektion = (befund.ergebnis.kapitel as any[])[0].sektionen[0];

    expect(sektion.neu).toEqual(['Gua Sha']);
  });

  it('wirft erfundene Marken weg', () => {
    const befund = nachbereiten(
      antwort(['Gua Sha', 'Dermaroller', 42]),
      vorgabe,
    );
    const sektion = (befund.ergebnis.kapitel as any[])[0].sektionen[0];

    expect(sektion.neu).toEqual(['Gua Sha']);
    expect(befund.erfundeneMarken).toEqual(['Dermaroller', '42']);
  });

  it('entfernt das Feld, wenn nichts uebrig bleibt', () => {
    const befund = nachbereiten(antwort(['Mewing']), vorgabe);
    const sektion = (befund.ergebnis.kapitel as any[])[0].sektionen[0];

    expect('neu' in sektion).toBe(false);
  });

  it('meldet eine gewaehlte Technik, die nirgends steht', () => {
    const befund = nachbereiten(antwort(undefined), vorgabe);

    expect(befund.fehlendeTechniken).toEqual(['Gua Sha']);
  });

  it('ohne Auswahl faellt jede Marke weg', () => {
    const befund = nachbereiten(antwort(['Gua Sha']), {
      ...vorgabe,
      techniken: [],
    });
    const sektion = (befund.ergebnis.kapitel as any[])[0].sektionen[0];

    expect('neu' in sektion).toBe(false);
    expect(befund.fehlendeTechniken).toEqual([]);
  });

  it('schreibt beide Funde ins Protokoll', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});

    melde(
      {
        ergebnis: {},
        fremdeKapitel: [],
        entfernteSektionen: [],
        entfernteHabits: 0,
        floskeln: [],
        zielkapitelFehlt: false,
        doppelteNamen: [],
        erfundeneMarken: ['Dermaroller'],
        fehlendeTechniken: ['Gua Sha'],
      },
      { sprache: 'de' },
    );

    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('erfundene'),
    );
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('fehlen im Report'),
    );
    warn.mockRestore();
  });
});

describe('techniklabels', () => {
  it('liefert die Anzeigenamen in der Zielsprache', () => {
    expect(techniklabels(['guaSha', 'oelziehen'], 'de')).toEqual([
      'Gua Sha',
      'Ölziehen',
    ]);
    expect(techniklabels(['guaSha', 'oelziehen'], 'en')).toEqual([
      'Gua sha',
      'Oil pulling',
    ]);
  });
});
