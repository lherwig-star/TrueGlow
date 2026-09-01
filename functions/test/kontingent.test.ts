import { deleteApp, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { GRENZEN, reservieren, freigeben } from '../src/limit';

/**
 * Der Verbrauchszaehler – geschrieben, gelesen und wieder gelesen.
 *
 * Laeuft ueber `npm run test:rules` gegen den Firestore-Emulator. Das ist
 * hier keine Formalie: `reservieren` arbeitet in einer Transaktion, und was
 * eine Transaktion wirklich ins Dokument schreibt, laesst sich nur an einer
 * Datenbank pruefen. Ein Unit-Test mit Attrappe haette am 01.09.2026 nichts
 * gemerkt – und hat auch nichts gemerkt (DECISIONS 95).
 *
 * Geprueft wird die Kette, die der Nutzer erlebt: Ein Lauf erhoeht den
 * Zaehler, der naechste Aufruf sieht den erhoehten Stand, und beim letzten
 * ist Schluss.
 */

const ICH = 'nutzer-kontingenttest';

beforeAll(() => {
  process.env.GOOGLE_CLOUD_PROJECT ??= 'trueglow-kontingenttest';
  initializeApp({ projectId: 'trueglow-kontingenttest' });
});

afterAll(async () => {
  await Promise.all(getApps().map((app) => deleteApp(app)));
});

/** Der Zaehler, so wie ihn auch die App liest. */
async function stand(): Promise<Record<string, unknown> | undefined> {
  const doc = await getFirestore()
    .collection('users')
    .doc(ICH)
    .collection('kontingent')
    .doc('analyse')
    .get();
  return doc.data();
}

beforeEach(async () => {
  await getFirestore().recursiveDelete(
    getFirestore().collection('users').doc(ICH),
  );
});

describe('Der Verbrauchszaehler', () => {
  const jetzt = new Date('2026-09-01T10:00:00+02:00');

  it('steht vor dem ersten Lauf auf nichts', async () => {
    expect(await stand()).toBeUndefined();
  });

  it('zaehlt einen Lauf mit', async () => {
    await reservieren(ICH, 'analyse', jetzt);

    const daten = await stand();
    expect(daten?.tagZaehler).toBe(1);
    expect(daten?.monatZaehler).toBe(1);
    // Die Schluesselfelder muessen mitgeschrieben werden: Ohne sie zaehlt
    // sowohl der Server als auch die App den Stand als „nicht von heute"
    // und damit als null.
    expect(daten?.tag).toBe('2026-09-01');
    expect(daten?.monat).toBe('2026-09');
  });

  it('und der naechste Aufruf sieht den erhoehten Stand', async () => {
    await reservieren(ICH, 'analyse', jetzt);
    await reservieren(ICH, 'analyse', jetzt);

    const daten = await stand();
    expect(daten?.tagZaehler).toBe(2);
    expect(daten?.monatZaehler).toBe(2);
  });

  it('lehnt ab, wenn die Tagesgrenze erreicht ist', async () => {
    for (let i = 0; i < GRENZEN.analyse.proTag; i += 1) {
      await reservieren(ICH, 'analyse', jetzt);
    }

    await expect(reservieren(ICH, 'analyse', jetzt)).rejects.toMatchObject({
      details: { fehler: 'kontingent' },
    });

    // Und der abgelehnte Versuch hat nichts dazugezaehlt.
    expect((await stand())?.tagZaehler).toBe(GRENZEN.analyse.proTag);
  });

  it('lehnt ab, wenn die Monatsgrenze erreicht ist', async () => {
    // Ueber mehrere Tage verteilt, damit die Tagesgrenze nicht zuerst
    // greift – so, wie es im Monat wirklich zustande kommt.
    let gebucht = 0;
    for (let tag = 1; gebucht < GRENZEN.analyse.proMonat; tag += 1) {
      const zeitpunkt = new Date(
        `2026-09-${String(tag).padStart(2, '0')}T10:00:00+02:00`,
      );
      for (
        let i = 0;
        i < GRENZEN.analyse.proTag && gebucht < GRENZEN.analyse.proMonat;
        i += 1
      ) {
        await reservieren(ICH, 'analyse', zeitpunkt);
        gebucht += 1;
      }
    }

    const spaeter = new Date('2026-09-20T10:00:00+02:00');
    await expect(reservieren(ICH, 'analyse', spaeter)).rejects.toMatchObject({
      details: { fehler: 'kontingentMonat' },
    });
  });

  it('faengt am naechsten Tag wieder bei null an', async () => {
    for (let i = 0; i < GRENZEN.analyse.proTag; i += 1) {
      await reservieren(ICH, 'analyse', jetzt);
    }

    const morgen = new Date('2026-09-02T10:00:00+02:00');
    await reservieren(ICH, 'analyse', morgen);

    const daten = await stand();
    expect(daten?.tagZaehler).toBe(1);
    // Der Monat laeuft weiter – vier Laeufe insgesamt.
    expect(daten?.monatZaehler).toBe(GRENZEN.analyse.proTag + 1);
  });

  it('gibt eine Reservierung wieder her, wenn nichts verbraucht wurde',
    async () => {
      await reservieren(ICH, 'analyse', jetzt);
      await freigeben(ICH, 'analyse', jetzt);

      const daten = await stand();
      expect(daten?.tagZaehler).toBe(0);
      expect(daten?.monatZaehler).toBe(0);
    });
});
