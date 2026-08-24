import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

/**
 * Regeltests gegen den Firestore-Emulator.
 *
 * Laufen ueber `npm run test:rules` – der Befehl startet den Emulator selbst
 * und braucht dafuer Java (siehe SETUP.md, Abschnitt 0). Sie sind deshalb aus
 * dem normalen `npm test` ausgenommen.
 */

const REGELN = readFileSync(
  resolve(__dirname, '..', '..', 'firestore.rules'),
  'utf8',
);

const ICH = 'nutzer-a';
const ANDERE = 'nutzer-b';

let umgebung: RulesTestEnvironment;

beforeAll(async () => {
  umgebung = await initializeTestEnvironment({
    projectId: 'glowup-regeltest',
    // Host und Port kommen aus FIRESTORE_EMULATOR_HOST, das
    // `firebase emulators:exec` setzt.
    firestore: { rules: REGELN },
  });
});

afterAll(async () => {
  await umgebung.cleanup();
});

beforeEach(async () => {
  await umgebung.clearFirestore();
});

function alsIch() {
  return umgebung.authenticatedContext(ICH).firestore();
}

function alsAndere() {
  return umgebung.authenticatedContext(ANDERE).firestore();
}

function ohneAnmeldung() {
  return umgebung.unauthenticatedContext().firestore();
}

const EIGENE_PFADE = [
  `users/${ICH}`,
  `users/${ICH}/daten/profil`,
  `users/${ICH}/daten/richtung`,
  `users/${ICH}/daten/streak`,
  `users/${ICH}/daten/module`,
  `users/${ICH}/daten/checkinPlan`,
  `users/${ICH}/daten/verweise`,
  `users/${ICH}/daten/migration`,
  `users/${ICH}/analysen/1755000000000`,
  `users/${ICH}/checkins/0`,
  `users/${ICH}/fortschritt/2026-08-24`,
];

describe('Security Rules', () => {
  it('erlaubt dem Konto den eigenen Baum', async () => {
    const db = alsIch();
    for (const pfad of EIGENE_PFADE) {
      await assertSucceeds(setDoc(doc(db, pfad), { wert: 'x' }));
      await assertSucceeds(getDoc(doc(db, pfad)));
    }
  });

  it('sperrt fremde Konten in jeder Sammlung', async () => {
    const fremd = alsAndere();
    for (const pfad of EIGENE_PFADE) {
      await assertFails(setDoc(doc(fremd, pfad), { wert: 'x' }));
      await assertFails(getDoc(doc(fremd, pfad)));
    }
  });

  it('sperrt nicht angemeldete Zugriffe', async () => {
    const offen = ohneAnmeldung();
    for (const pfad of EIGENE_PFADE) {
      await assertFails(setDoc(doc(offen, pfad), { wert: 'x' }));
      await assertFails(getDoc(doc(offen, pfad)));
    }
  });

  it('laesst den Kontingentzaehler lesen, aber nicht schreiben', async () => {
    // Die Cloud Function schreibt mit Admin-Rechten und umgeht die Regeln.
    await umgebung.withSecurityRulesDisabled(async (kontext) => {
      await setDoc(doc(kontext.firestore(), `users/${ICH}/kontingent/analyse`), {
        tag: '2026-08-24',
        tagZaehler: 1,
      });
    });

    const db = alsIch();
    const gelesen = await assertSucceeds(
      getDoc(doc(db, `users/${ICH}/kontingent/analyse`)),
    );
    expect(gelesen.data()?.tagZaehler).toBe(1);

    await assertFails(
      setDoc(doc(db, `users/${ICH}/kontingent/analyse`), { tagZaehler: 0 }),
    );
  });

  it('lehnt Bilddaten in Nutzerdokumenten ab', async () => {
    // Fotos bleiben auf dem Geraet. Ein Feld mit Bilddaten waere ein Fehler
    // im Client – die Regel macht ihn sofort sichtbar.
    const db = alsIch();

    await assertFails(
      setDoc(doc(db, `users/${ICH}/analysen/1`), {
        wert: '{}',
        bilddaten: 'AAAA',
      }),
    );
    await assertFails(
      setDoc(doc(db, `users/${ICH}/checkins/0`), {
        wert: '{}',
        bilder: ['AAAA'],
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, `users/${ICH}/analysen/1`), { wert: '{}' }),
    );
  });

  it('sperrt Sammlungen, die das Datenmodell nicht kennt', async () => {
    const db = alsIch();

    await assertFails(
      setDoc(doc(db, `users/${ICH}/geheim/eintrag`), { wert: 'x' }),
    );
    await assertFails(setDoc(doc(db, 'irgendwas/eintrag'), { wert: 'x' }));
  });
});
