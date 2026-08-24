import { describe, expect, it } from 'vitest';

import { leseAnalyse, leseCheckin, MAX_BILD_BYTES } from '../src/eingang';
import { GRENZEN, schluessel, stand } from '../src/limit';

const BILD = 'AAAA';

function analysePayload(zusatz: Record<string, unknown> = {}) {
  return {
    module: ['basis'],
    profil: { alter: 'a25bis34', budget: 'mittel', zeit: 'kurz', fokus: ['haut'] },
    eingaben: { figur: {}, stil: { ziele: [] } },
    richtung: { ziele: [], freitext: '' },
    bilder: [{ typ: 'basisFrontal', daten: BILD }],
    ...zusatz,
  };
}

describe('leseAnalyse', () => {
  it('nimmt eine vollstaendige Payload an', () => {
    const eingang = leseAnalyse(analysePayload());

    expect(eingang.prompt.module).toEqual(['basis']);
    expect(eingang.bildTypen).toEqual(['basisFrontal']);
    expect(eingang.bilder).toEqual([BILD]);
  });

  it('ergaenzt die Basis, auch wenn der Client sie weglaesst', () => {
    const eingang = leseAnalyse(analysePayload({ module: ['zaehneLaecheln'] }));

    expect(eingang.prompt.module).toEqual(['basis', 'zaehneLaecheln']);
  });

  it('wirft fotosFehlen ohne Bilder', () => {
    expect(() => leseAnalyse(analysePayload({ bilder: [] }))).toThrowError(
      /fotosFehlen/,
    );
  });

  it('lehnt unbekannte Aufnahmetypen ab', () => {
    expect(() =>
      leseAnalyse(analysePayload({ bilder: [{ typ: 'erfunden', daten: BILD }] })),
    ).toThrowError(/fotosFehlen/);
  });

  it('lehnt zu grosse Bilddaten ab', () => {
    const riesig = 'A'.repeat(MAX_BILD_BYTES + 1);
    expect(() =>
      leseAnalyse(analysePayload({ bilder: [{ typ: 'basisFrontal', daten: riesig }] })),
    ).toThrowError(/apiFehler/);
  });

  it('kuerzt den Freitext auf die Obergrenze', () => {
    const eingang = leseAnalyse(
      analysePayload({ richtung: { ziele: [], freitext: 'x'.repeat(5000) } }),
    );

    expect(eingang.prompt.richtung.freitext.length).toBe(1000);
  });

  it('verwirft unsinnige Koerpermasse', () => {
    const eingang = leseAnalyse(
      analysePayload({
        module: ['basis', 'figurPassform'],
        eingaben: { figur: { groesseCm: 9000, gewichtKg: 78 }, stil: { ziele: [] } },
      }),
    );

    expect(eingang.prompt.figur.groesseCm).toBeUndefined();
    expect(eingang.prompt.figur.gewichtKg).toBe(78);
  });
});

describe('leseCheckin', () => {
  const payload = {
    checkin: {
      typ: 'wirkung',
      habits: [{ habit: 'Bart ölen', bewertung: 'passtNicht', grund: 'zeit', notiz: '' }],
      wirkung: [],
    },
    plan: [{ modul: 'basis', habits: ['Bart ölen'] }],
    richtung: { ziele: [], freitext: '' },
    historie: [],
    bilder: [BILD, BILD],
  };

  it('nimmt genau zwei Bilder an', () => {
    const eingang = leseCheckin(payload);

    expect(eingang.bilder).toHaveLength(2);
    expect(eingang.prompt.mitFotos).toBe(true);
  });

  it('laeuft auch ohne Bilder', () => {
    const eingang = leseCheckin({ ...payload, bilder: [] });

    expect(eingang.bilder).toHaveLength(0);
    expect(eingang.prompt.mitFotos).toBe(false);
  });

  it('lehnt eine ungerade Bildzahl ab', () => {
    expect(() => leseCheckin({ ...payload, bilder: [BILD] })).toThrowError(
      /apiFehler/,
    );
  });

  it('behaelt nur die juengsten Historieneintraege', () => {
    const historie = Array.from({ length: 40 }, (_, i) => ({
      datum: `2026-01-${String((i % 28) + 1).padStart(2, '0')}T00:00:00.000`,
      typ: 'alltag',
      probleme: [],
    }));

    const eingang = leseCheckin({ ...payload, historie });

    expect(eingang.prompt.historie).toHaveLength(24);
  });
});

describe('Kontingent', () => {
  it('kennt die Grenzen aus der Roadmap', () => {
    expect(GRENZEN.analyse).toEqual({ proTag: 3, proMonat: 30 });
  });

  it('bildet Tages- und Monatsschluessel', () => {
    const { tag, monat } = schluessel(new Date('2026-08-24T10:00:00Z'));

    expect(tag).toBe('2026-08-24');
    expect(monat).toBe('2026-08');
  });

  it('setzt den Tageszaehler zurueck, wenn der Tag gewechselt hat', () => {
    const jetzt = new Date('2026-08-24T10:00:00Z');
    const alt = { tag: '2026-08-23', tagZaehler: 3, monat: '2026-08', monatZaehler: 12 };

    expect(stand(alt, jetzt)).toEqual({ tagZaehler: 0, monatZaehler: 12 });
  });

  it('setzt beide Zaehler zurueck, wenn der Monat gewechselt hat', () => {
    const jetzt = new Date('2026-09-01T10:00:00Z');
    const alt = { tag: '2026-08-31', tagZaehler: 2, monat: '2026-08', monatZaehler: 30 };

    expect(stand(alt, jetzt)).toEqual({ tagZaehler: 0, monatZaehler: 0 });
  });

  it('behandelt fehlende und kaputte Werte als null', () => {
    expect(stand(undefined)).toEqual({ tagZaehler: 0, monatZaehler: 0 });

    const { tag, monat } = schluessel();
    expect(stand({ tag, tagZaehler: -5, monat, monatZaehler: 'viele' })).toEqual({
      tagZaehler: 0,
      monatZaehler: 0,
    });
  });
});
