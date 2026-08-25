import { describe, expect, it, vi } from 'vitest';

import { melde, nachbereiten, spracheSchaetzen } from '../src/nachbereitung';
import type { Modul } from '../src/labels';

/**
 * Die Nachbereitung ist die zweite Sperre hinter dem Prompt.
 *
 * Der Anlass steht in DECISIONS 35: Am Geraet kam im weiblichen Modus ein
 * Report mit Bart-Kapitel zurueck. Die Ursache lag damals woanders – der
 * Server lief in einer alten Fassung –, aber die Lage hat gezeigt, dass eine
 * Prompt-Anweisung allein keine Zusicherung ist.
 */

function kapitel(modul: Modul, sektionen: string[], habits: string[] = []) {
  return {
    modul,
    einleitung: 'Einleitung',
    habits,
    sektionen: sektionen.map((titel) => ({
      titel,
      einschaetzung: 'Text',
      empfehlungen: ['Schritt'],
      produkte: [],
    })),
  };
}

const weiblich = {
  sprache: 'de' as const,
  ausrichtung: 'weiblich' as const,
  module: ['basis', 'makeupAusstrahlung'] as Modul[],
};

describe('Bart im weiblichen Modus', () => {
  it('faellt als Sektion heraus, auch wenn das Modell ihn liefert', () => {
    const befund = nachbereiten(
      { kapitel: [kapitel('basis', ['Frisur', 'Bart', 'Brille'])] },
      weiblich,
    );

    const sektionen = (befund.ergebnis.kapitel as any[])[0].sektionen;
    expect(sektionen.map((s: any) => s.titel)).toEqual(['Frisur', 'Brille']);
    expect(befund.entfernteSektionen).toEqual(['Bart']);
  });

  it('erkennt auch Bartpflege, Rasur und die englischen Formen', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          kapitel('basis', ['Frisur', 'Bartpflege', 'Rasur', 'Beard shaping']),
        ],
      },
      weiblich,
    );

    const sektionen = (befund.ergebnis.kapitel as any[])[0].sektionen;
    expect(sektionen.map((s: any) => s.titel)).toEqual(['Frisur']);
    expect(befund.entfernteSektionen).toHaveLength(3);
  });

  it('raeumt auch die Tagesaufgaben und den Plan', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          kapitel(
            'basis',
            ['Frisur'],
            ['Haare buersten', 'Bart täglich mit Bartöl pflegen'],
          ),
        ],
        plan: {
          sofort: ['Reinigung umstellen', 'Barttrimmer besorgen'],
          dreissigTage: ['Haarschnitt buchen'],
        },
      },
      weiblich,
    );

    const erstes = (befund.ergebnis.kapitel as any[])[0];
    expect(erstes.habits).toEqual(['Haare buersten']);
    expect(befund.entfernteHabits).toBe(1);
    expect((befund.ergebnis.plan as any).sofort).toEqual([
      'Reinigung umstellen',
    ]);
    expect((befund.ergebnis.plan as any).dreissigTage).toHaveLength(1);
  });

  it('wirft ein Kapitel weg, das nur aus Bart bestand', () => {
    const befund = nachbereiten(
      { kapitel: [kapitel('basis', ['Bart', 'Rasur'])] },
      weiblich,
    );

    expect(befund.ergebnis.kapitel).toEqual([]);
    expect(befund.fremdeKapitel).toEqual(['basis']);
  });

  it('laesst im maennlichen Modus alles stehen', () => {
    const befund = nachbereiten(
      { kapitel: [kapitel('basis', ['Frisur', 'Bart'])] },
      { sprache: 'de', ausrichtung: 'maennlich', module: ['basis'] },
    );

    const sektionen = (befund.ergebnis.kapitel as any[])[0].sektionen;
    expect(sektionen).toHaveLength(2);
    expect(befund.entfernteSektionen).toEqual([]);
  });
});

describe('Kapitel, die niemand bestellt hat', () => {
  it('fallen heraus', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          kapitel('basis', ['Frisur']),
          kapitel('zaehneLaecheln', ['Zahnfarbe']),
        ],
      },
      { sprache: 'de', ausrichtung: 'neutral', module: ['basis'] },
    );

    expect((befund.ergebnis.kapitel as any[]).map((k) => k.modul)).toEqual([
      'basis',
    ]);
    expect(befund.fremdeKapitel).toEqual(['zaehneLaecheln']);
  });

  it('das gilt auch fuer Make-up im maennlichen Modus', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          kapitel('basis', ['Frisur']),
          kapitel('makeupAusstrahlung', ['Alltags-Look']),
        ],
      },
      { sprache: 'de', ausrichtung: 'maennlich', module: ['basis'] },
    );

    expect(befund.fremdeKapitel).toEqual(['makeupAusstrahlung']);
  });

  it('das angeforderte Make-up-Kapitel bleibt aber stehen', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          kapitel('basis', ['Frisur']),
          kapitel('makeupAusstrahlung', ['Alltags-Look', 'Farben']),
        ],
      },
      weiblich,
    );

    expect((befund.ergebnis.kapitel as any[]).map((k) => k.modul)).toEqual([
      'basis',
      'makeupAusstrahlung',
    ]);
    expect(befund.fremdeKapitel).toEqual([]);
  });
});

describe('Spracherkennung', () => {
  // Bewusst so lang wie ein echter Kapitelabsatz: Die Erkennung braucht
  // eine Mindestmenge an Funktionswoertern, bevor sie etwas behauptet.
  const deutsch =
    'Dein Gesicht hat eine ovale Form und wirkt ruhig. Die Seiten sind ' +
    'kuerzer als das Deckhaar, und das passt zu dieser Form. Nicht jeder ' +
    'Schnitt ist dafuer geeignet, aber dieser schon. Wichtig ist, dass die ' +
    'Laengen oben bleiben und du sie nicht zu frueh nachschneiden laesst. ' +
    'Auch der Scheitel darf bleiben, wo er ist – eine Verlagerung wird ' +
    'schon nach einer Woche wieder herauswachsen.';
  const englisch =
    'Your face has an oval shape and reads as calm. The sides are shorter ' +
    'than the top, and that works for this shape. Not every cut is right ' +
    'for you, but this one is. What matters is that the length stays on ' +
    'top and that you do not have it cut back too early. The parting can ' +
    'stay where it is – moving it will grow out within a week.';

  it('erkennt Deutsch und Englisch', () => {
    expect(spracheSchaetzen(deutsch)).toBe('de');
    expect(spracheSchaetzen(englisch)).toBe('en');
  });

  it('schweigt bei zu kurzen Proben', () => {
    expect(spracheSchaetzen('Frisur')).toBeUndefined();
    expect(spracheSchaetzen('')).toBeUndefined();
  });

  it('meldet einen deutschen Report, der englisch sein sollte', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          {
            modul: 'basis',
            einleitung: deutsch,
            habits: [],
            sektionen: [{ titel: 'Frisur', einschaetzung: deutsch }],
          },
        ],
      },
      { sprache: 'en', ausrichtung: 'neutral', module: ['basis'] },
    );

    expect(befund.falscheSprache).toBe('de');
  });

  it('schweigt, wenn die Sprache stimmt', () => {
    const befund = nachbereiten(
      {
        kapitel: [
          {
            modul: 'basis',
            einleitung: englisch,
            habits: [],
            sektionen: [{ titel: 'Hair', einschaetzung: englisch }],
          },
        ],
      },
      { sprache: 'en', ausrichtung: 'neutral', module: ['basis'] },
    );

    expect(befund.falscheSprache).toBeUndefined();
  });

  it('laesst den Report trotzdem durch – Kontingent ist verbraucht', () => {
    const fehler = vi.spyOn(console, 'error').mockImplementation(() => {});

    const befund = nachbereiten(
      {
        kapitel: [
          {
            modul: 'basis',
            einleitung: deutsch,
            habits: [],
            sektionen: [{ titel: 'Frisur', einschaetzung: deutsch }],
          },
        ],
      },
      { sprache: 'en', ausrichtung: 'neutral', module: ['basis'] },
    );
    melde(befund, { sprache: 'en' });

    expect(befund.ergebnis.kapitel).toHaveLength(1);
    expect(fehler).toHaveBeenCalledOnce();
    fehler.mockRestore();
  });
});
