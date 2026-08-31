import { deleteApp, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { datenLoeschen } from '../src/konto';

/**
 * Was das Loeschen wirklich loescht – und was ausdruecklich stehen bleibt.
 *
 * Laeuft ueber `npm run test:rules` gegen den Firestore-Emulator, weil
 * `datenLoeschen` mit dem Admin-SDK arbeitet und `recursiveDelete` sich
 * nicht sinnvoll nachbauen laesst. Der Emulator ist hier kein Beiwerk: Ohne
 * ihn waere der wichtigste Satz dieses Tests eine Behauptung.
 *
 * Der Anlass ist SECURITY_AUDIT B1: Mit dem Nutzerbaum verschwand auch der
 * Verbrauchszaehler, und damit liess sich die Monatsgrenze durch
 * wiederholtes „Alle Daten loeschen" beliebig oft zuruecksetzen.
 */

const ICH = 'nutzer-loeschtest';

beforeAll(() => {
  // Der Emulator braucht keine echten Zugangsdaten; `firebase
  // emulators:exec` setzt FIRESTORE_EMULATOR_HOST, und das Admin-SDK
  // richtet sich danach.
  process.env.GOOGLE_CLOUD_PROJECT ??= 'trueglow-loeschtest';
  initializeApp({ projectId: 'trueglow-loeschtest' });
});

afterAll(async () => {
  await Promise.all(getApps().map((app) => deleteApp(app)));
});

/** Legt einen vollen Nutzerbaum an, wie ihn ein echtes Konto hat. */
async function baumAnlegen(): Promise<void> {
  const db = getFirestore();
  const wurzel = db.collection('users').doc(ICH);

  await wurzel.set({ wert: 'kopf' });
  await wurzel.collection('daten').doc('profil').set({ wert: 'x' });
  await wurzel.collection('daten').doc('richtung').set({ wert: 'y' });
  await wurzel.collection('analysen').doc('1').set({ wert: '{}' });
  await wurzel.collection('checkins').doc('0').set({ wert: '{}' });
  await wurzel.collection('fortschritt').doc('2026-08-31').set({ erledigt: [] });
  await wurzel.collection('kontingent').doc('analyse').set({
    tag: '2026-08-31',
    tagZaehler: 3,
    monat: '2026-08',
    monatZaehler: 9,
  });
  await wurzel.collection('kontingent').doc('checkin').set({
    freiZuletzt: '2026-08-24',
  });
}

/** Wie viele Dokumente in einer Unterkollektion liegen. */
async function anzahl(sammlung: string): Promise<number> {
  const treffer = await getFirestore()
    .collection('users')
    .doc(ICH)
    .collection(sammlung)
    .get();
  return treffer.size;
}

async function kontingent(): Promise<Record<string, unknown> | undefined> {
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
  await baumAnlegen();
});

describe('Daten loeschen', () => {
  it('raeumt alle Inhalte weg', async () => {
    await datenLoeschen(ICH, { kontingentBehalten: true });

    expect(await anzahl('daten')).toBe(0);
    expect(await anzahl('analysen')).toBe(0);
    expect(await anzahl('checkins')).toBe(0);
    expect(await anzahl('fortschritt')).toBe(0);

    const kopf = await getFirestore().collection('users').doc(ICH).get();
    expect(kopf.exists).toBe(false);
  });

  it('laesst den Verbrauchszaehler stehen', async () => {
    // Der Kern des Fundes aus SECURITY_AUDIT B1.
    await datenLoeschen(ICH, { kontingentBehalten: true });

    const stand = await kontingent();
    expect(stand?.tagZaehler).toBe(3);
    expect(stand?.monatZaehler).toBe(9);
    expect(stand?.monat).toBe('2026-08');
  });

  it('behaelt auch die Check-in-Freistellung', async () => {
    await datenLoeschen(ICH, { kontingentBehalten: true });

    const doc = await getFirestore()
      .collection('users')
      .doc(ICH)
      .collection('kontingent')
      .doc('checkin')
      .get();

    expect(doc.data()?.freiZuletzt).toBe('2026-08-24');
  });

  it('bleibt wiederholbar – zweimal loeschen setzt nichts zurueck', async () => {
    await datenLoeschen(ICH, { kontingentBehalten: true });
    await datenLoeschen(ICH, { kontingentBehalten: true });
    await datenLoeschen(ICH, { kontingentBehalten: true });

    const stand = await kontingent();
    expect(stand?.monatZaehler).toBe(9);
  });

  it('nimmt den hoeheren Stand, wenn zwischendurch gebucht wurde', async () => {
    // Zwischen Sichern und Zurueckschreiben kann eine Analyse starten. Sie
    // darf nicht ueberschrieben werden – sonst waere sie gratis.
    const referenz = getFirestore()
      .collection('users')
      .doc(ICH)
      .collection('kontingent')
      .doc('analyse');

    await datenLoeschen(ICH, { kontingentBehalten: true });
    await referenz.set(
      { tag: '2026-08-31', tagZaehler: 5, monat: '2026-08', monatZaehler: 12 },
      { merge: true },
    );
    await datenLoeschen(ICH, { kontingentBehalten: true });

    const stand = await kontingent();
    expect(stand?.tagZaehler).toBe(5);
    expect(stand?.monatZaehler).toBe(12);
  });
});

describe('Konto loeschen', () => {
  it('nimmt auch den Zaehler mit', async () => {
    // Die uid ist danach fuer immer verbraucht – ein Zaehler dazu waere ein
    // Datensatz ohne Zweck.
    await datenLoeschen(ICH, { kontingentBehalten: false });

    expect(await anzahl('kontingent')).toBe(0);
    expect(await anzahl('analysen')).toBe(0);
  });
});
