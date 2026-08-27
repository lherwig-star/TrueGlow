import { beforeEach, describe, expect, it, vi } from 'vitest';

import {
  ausPexels,
  bilderFuer,
  cacheSchluessel,
  leseBegriffe,
  MAX_BEGRIFFE,
  MAX_TREFFER,
  pexelsSuche,
  stundenschluessel,
  type Bild,
  type Bildcache,
} from '../src/bilder';

/**
 * Die Bildersuche – DECISIONS 69.
 *
 * Alles hier laeuft ohne Netz und ohne Emulator: Der Cache ist eine
 * Schnittstelle, `fetch` wird hereingereicht. Der Grund ist derselbe wie
 * beim Auto-Ausloeser: Was nur am lebenden System zu pruefen ist, wird nicht
 * geprueft.
 */

/** Ein Foto, wie Pexels es liefert. */
function pexelsFoto(nummer: number) {
  return {
    id: nummer,
    url: `https://www.pexels.com/photo/beispiel-${nummer}/`,
    photographer: `Fotograf ${nummer}`,
    alt: `Beispiel ${nummer}`,
    src: {
      original: `https://images.pexels.com/${nummer}-original.jpg`,
      large: `https://images.pexels.com/${nummer}-large.jpg`,
      medium: `https://images.pexels.com/${nummer}-medium.jpg`,
      small: `https://images.pexels.com/${nummer}-small.jpg`,
    },
  };
}

function antwort(koerper: unknown, status = 200): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => koerper,
  } as Response;
}

/** Cache im Arbeitsspeicher, mit Zaehlern fuer die Zugriffe. */
class TestCache implements Bildcache {
  constructor(public frei = 100) {}

  readonly inhalt = new Map<string, Bild[]>();
  gelesen: string[][] = [];
  geschrieben: string[] = [];
  reserviert: number[] = [];

  async lies(begriffe: string[]) {
    this.gelesen.push(begriffe);
    const gefunden = new Map<string, Bild[]>();
    for (const b of begriffe) {
      const treffer = this.inhalt.get(b);
      if (treffer !== undefined) gefunden.set(b, treffer);
    }
    return gefunden;
  }

  async schreib(begriff: string, treffer: Bild[]) {
    this.geschrieben.push(begriff);
    this.inhalt.set(begriff, treffer);
  }

  async reserviere(anzahl: number) {
    this.reserviert.push(anzahl);
    const gewaehrt = Math.min(anzahl, this.frei);
    this.frei -= gewaehrt;
    return gewaehrt;
  }
}

describe('leseBegriffe', () => {
  it('nimmt eine Liste', () => {
    expect(
      leseBegriffe({ begriffe: ['French Crop Haircut Men', 'short beard men'] }),
    ).toEqual(['french crop haircut men', 'short beard men']);
  });

  it('nimmt auch einen einzelnen Begriff', () => {
    expect(leseBegriffe({ begriff: 'short beard men' })).toEqual([
      'short beard men',
    ]);
  });

  it('wirft Dubletten weg', () => {
    // Zwei Kapitel koennen denselben Schnitt vorschlagen. Zweimal fragen
    // hiesse zweimal beim Stundenlimit zaehlen.
    expect(
      leseBegriffe({ begriffe: ['short beard men', 'Short Beard Men'] }),
    ).toEqual(['short beard men']);
  });

  it('siebt aus, was kein Suchbegriff ist – dieselbe Regel wie im Report', () => {
    expect(
      leseBegriffe({ begriffe: ['kurzer Vollbart für Männer', 'bob haircut'] }),
    ).toEqual(['bob haircut']);
  });

  it('deckelt die Zahl', () => {
    const viele = Array.from({ length: 30 }, (_, i) => `haircut ${i}`);
    expect(leseBegriffe({ begriffe: viele })).toHaveLength(MAX_BEGRIFFE);
  });

  it('lehnt eine Anfrage ohne brauchbaren Begriff ab', () => {
    for (const daten of [
      undefined,
      {},
      { begriffe: [] },
      { begriffe: ['', '   ', 42] },
      { begriff: 'für Männer' },
    ]) {
      expect(() => leseBegriffe(daten), JSON.stringify(daten)).toThrow();
    }
  });
});

describe('ausPexels', () => {
  it('liest Vorschau, grosse Fassung, Fotograf und Quelle', () => {
    const bilder = ausPexels({ photos: [pexelsFoto(1)] });

    expect(bilder).toEqual([
      {
        vorschau: 'https://images.pexels.com/1-medium.jpg',
        gross: 'https://images.pexels.com/1-large.jpg',
        fotograf: 'Fotograf 1',
        quelle: 'https://www.pexels.com/photo/beispiel-1/',
        beschreibung: 'Beispiel 1',
      },
    ]);
  });

  it('nimmt höchstens vier', () => {
    const bilder = ausPexels({
      photos: Array.from({ length: 9 }, (_, i) => pexelsFoto(i)),
    });
    expect(bilder).toHaveLength(MAX_TREFFER);
  });

  it('wirft ein Bild ohne Fotograf oder Quelle weg', () => {
    // Beides verlangt die Pexels-Lizenz. Ein Bild, das sich nicht nennen
    // laesst, darf gar nicht erst in die App.
    const ohneFotograf = { ...pexelsFoto(1), photographer: '' };
    const ohneQuelle = { ...pexelsFoto(2), url: undefined };

    expect(ausPexels({ photos: [ohneFotograf, ohneQuelle] })).toEqual([]);
  });

  it('nimmt nur https', () => {
    const unsicher = {
      ...pexelsFoto(1),
      src: { medium: 'http://images.pexels.com/1.jpg' },
    };
    expect(ausPexels({ photos: [unsicher] })).toEqual([]);
  });

  it('faellt auf die kleinere Fassung zurück', () => {
    const knapp = {
      ...pexelsFoto(1),
      src: { small: 'https://images.pexels.com/1-small.jpg' },
    };
    const bild = ausPexels({ photos: [knapp] })[0];

    expect(bild.vorschau).toBe('https://images.pexels.com/1-small.jpg');
    expect(bild.gross).toBe(bild.vorschau);
  });

  it('übersteht Unsinn, ohne zu werfen', () => {
    for (const unsinn of [undefined, null, {}, { photos: 'nein' }, { photos: [null, 7] }]) {
      expect(ausPexels(unsinn), JSON.stringify(unsinn)).toEqual([]);
    }
  });
});

describe('pexelsSuche', () => {
  it('fragt Hochformat und höchstens vier Bilder an', async () => {
    const holen = vi.fn(async () => antwort({ photos: [pexelsFoto(1)] }));

    await pexelsSuche('short beard men', 'schluessel', holen as never);

    const [adresse, optionen] = holen.mock.calls[0] as unknown as [
      string,
      RequestInit,
    ];
    expect(adresse).toContain('query=short%20beard%20men');
    expect(adresse).toContain('orientation=portrait');
    expect(adresse).toContain(`per_page=${MAX_TREFFER}`);
    expect((optionen.headers as Record<string, string>).Authorization).toBe(
      'schluessel',
    );
  });

  it('liefert eine leere Liste, wenn Pexels nichts findet', async () => {
    const holen = vi.fn(async () => antwort({ photos: [] }));
    expect(await pexelsSuche('x y', 'k', holen as never)).toEqual([]);
  });

  it('liefert undefined, wenn die Anfrage scheitert', async () => {
    // Der Unterschied zu „nichts gefunden" entscheidet, ob das Ergebnis in
    // den Cache darf.
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});

    const abgelehnt = vi.fn(async () => antwort({}, 429));
    expect(await pexelsSuche('x y', 'k', abgelehnt as never)).toBeUndefined();

    const kaputt = vi.fn(async () => {
      throw new Error('Netz weg');
    });
    expect(await pexelsSuche('x y', 'k', kaputt as never)).toBeUndefined();

    warn.mockRestore();
  });
});

describe('bilderFuer', () => {
  let warn: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
  });

  it('fragt Pexels und merkt sich das Ergebnis', async () => {
    const cache = new TestCache();
    const holen = vi.fn(async () => antwort({ photos: [pexelsFoto(1)] }));

    const treffer = await bilderFuer(
      ['short beard men'],
      'k',
      cache,
      holen as never,
    );

    expect(treffer['short beard men']).toHaveLength(1);
    expect(cache.geschrieben).toEqual(['short beard men']);
    expect(holen).toHaveBeenCalledTimes(1);
  });

  it('fragt nicht noch einmal, was im Cache steht', async () => {
    // Der eigentliche Zweck des Caches: "textured crop haircut men" schlägt
    // das Modell vielen Nutzern vor.
    const cache = new TestCache();
    cache.inhalt.set('short beard men', []);
    const holen = vi.fn(async () => antwort({ photos: [pexelsFoto(1)] }));

    await bilderFuer(['short beard men'], 'k', cache, holen as never);

    expect(holen).not.toHaveBeenCalled();
    expect(cache.reserviert).toEqual([]);
  });

  it('merkt sich auch, dass es nichts gibt', async () => {
    // Sonst läuft ein Begriff ohne Treffer bei jedem Öffnen des Reports
    // erneut gegen das Stundenlimit.
    const cache = new TestCache();
    const holen = vi.fn(async () => antwort({ photos: [] }));

    await bilderFuer(['no such thing'], 'k', cache, holen as never);

    expect(cache.inhalt.get('no such thing')).toEqual([]);
  });

  it('merkt sich einen Fehlschlag NICHT', async () => {
    // Ein Netzaussetzer darf nicht dreißig Tage lang als "gibt es nicht"
    // gelten.
    const cache = new TestCache();
    const holen = vi.fn(async () => antwort({}, 500));

    const treffer = await bilderFuer(['short beard men'], 'k', cache, holen as never);

    expect(treffer).toEqual({});
    expect(cache.geschrieben).toEqual([]);
  });

  it('hört auf zu fragen, wenn die Stunde voll ist', async () => {
    const cache = new TestCache(1);
    const holen = vi.fn(async () => antwort({ photos: [pexelsFoto(1)] }));

    const treffer = await bilderFuer(
      ['aaa bbb', 'ccc ddd', 'eee fff'],
      'k',
      cache,
      holen as never,
    );

    expect(holen).toHaveBeenCalledTimes(1);
    expect(Object.keys(treffer)).toHaveLength(1);
    expect(warn).toHaveBeenCalled();
  });

  it('mischt Cache und frische Suche', async () => {
    const cache = new TestCache();
    cache.inhalt.set('aaa bbb', []);
    const holen = vi.fn(async () => antwort({ photos: [pexelsFoto(1)] }));

    const treffer = await bilderFuer(
      ['aaa bbb', 'ccc ddd'],
      'k',
      cache,
      holen as never,
    );

    expect(holen).toHaveBeenCalledTimes(1);
    expect(cache.reserviert).toEqual([1]);
    expect(treffer['aaa bbb']).toEqual([]);
    expect(treffer['ccc ddd']).toHaveLength(1);
  });
});

describe('Die Schlüssel', () => {
  it('sind für denselben Begriff dieselben', () => {
    expect(cacheSchluessel('short beard men')).toBe(
      cacheSchluessel('short beard men'),
    );
    expect(cacheSchluessel('short beard men')).not.toBe(
      cacheSchluessel('long beard men'),
    );
  });

  it('taugen als Firestore-Dokumentname', () => {
    // Ein Begriff darf Zeichen enthalten, die Firestore in Namen nicht mag.
    expect(cacheSchluessel("shirt & chinos men's")).toMatch(/^[0-9a-f]{40}$/);
  });

  it('der Zähler bekommt ein Dokument je Stunde', () => {
    expect(stundenschluessel(new Date('2026-08-27T22:41:00Z'))).toBe(
      '2026-08-27T22',
    );
    expect(stundenschluessel(new Date('2026-08-27T23:00:00Z'))).not.toBe(
      stundenschluessel(new Date('2026-08-27T22:59:59Z')),
    );
  });
});
