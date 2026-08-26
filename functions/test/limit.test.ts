import { describe, expect, it } from 'vitest';

import {
  CHECKIN_ABSTAND_TAGE,
  GRENZEN,
  schluessel,
  stand,
  tageZwischen,
} from '../src/limit';
import { MODELL, ZEITLIMIT_MS } from '../src/gemini';

/**
 * Das Kontingent, soweit es sich ohne Firestore pruefen laesst.
 *
 * Die Buchung selbst ist eine Transaktion und braucht den Emulator; was hier
 * steht, sind die Regeln davor: die Zahlen, die Normalisierung auf Tag und
 * Monat, und der Abstand, ab dem ein Check-in wieder frei ist.
 */

describe('Die Grenzen', () => {
  it('sind zehn Analysen im Monat und drei am Tag', () => {
    // Gegenstueck zu KontingentStand in `lib/features/analysis/logic/
    // kontingent.dart`. Laufen die Zahlen auseinander, zeigt die App etwas
    // anderes an, als der Server entscheidet.
    expect(GRENZEN.analyse).toEqual({ proTag: 3, proMonat: 10 });
  });

  it('lassen den Check-in in seinem eigenen Topf', () => {
    // Sonst koennten drei Analysen an einem Tag den faelligen Check-in
    // blockieren – und seit der Monatsgrenze waere er nach zehn Analysen
    // fuer den Rest des Monats tot.
    expect(GRENZEN.checkin.proMonat).toBeGreaterThan(GRENZEN.analyse.proMonat);
  });
});

describe('Der Abstand zwischen zwei freien Check-ins', () => {
  it('ist sieben Tage – der dichteste Takt, den die App verlangt', () => {
    expect(CHECKIN_ABSTAND_TAGE).toBe(7);
  });

  it('zaehlt ganze Tage zwischen zwei Tagesschluesseln', () => {
    expect(tageZwischen('2026-08-19', '2026-08-26')).toBe(7);
    expect(tageZwischen('2026-08-20', '2026-08-26')).toBe(6);
    expect(tageZwischen('2026-08-26', '2026-08-26')).toBe(0);
  });

  it('rechnet ueber Monats- und Jahresgrenzen', () => {
    expect(tageZwischen('2026-07-30', '2026-08-06')).toBe(7);
    expect(tageZwischen('2026-12-28', '2027-01-04')).toBe(7);
  });

  it('rechnet ueber die Sommerzeitumstellung richtig', () => {
    // Ende Oktober hat ein Tag 25 Stunden. Ueber UTC gerechnet faellt das
    // nicht ins Gewicht – ueber lokale Zeitstempel waere es ein Tag zu
    // wenig gewesen.
    expect(tageZwischen('2026-10-22', '2026-10-29')).toBe(7);
  });

  it('haelt einen unlesbaren Stand fuer faellig, nicht fuer gesperrt', () => {
    // Lieber ein freier Check-in zu viel als ein Nutzer, den ein kaputtes
    // Feld dauerhaft aussperrt.
    expect(tageZwischen('kaputt', '2026-08-26')).toBeGreaterThan(
      CHECKIN_ABSTAND_TAGE,
    );
  });
});

describe('Tages- und Monatsschluessel', () => {
  it('stehen in deutscher Zeit', () => {
    // 31.07. um 23:00 UTC ist in Berlin schon der 1. August – der
    // Monatszaehler springt also mit der deutschen Mitternacht.
    const { tag, monat } = schluessel(new Date('2026-07-31T23:00:00Z'));

    expect(tag).toBe('2026-08-01');
    expect(monat).toBe('2026-08');
  });

  it('setzen einen Zaehler aus dem Vormonat auf 0', () => {
    const jetzt = new Date('2026-08-26T10:00:00Z');
    const alt = stand(
      { tag: '2026-07-31', tagZaehler: 3, monat: '2026-07', monatZaehler: 10 },
      jetzt,
    );

    expect(alt).toEqual({ tagZaehler: 0, monatZaehler: 0 });
  });

  it('lassen den Monatszaehler ueber den Tageswechsel stehen', () => {
    const jetzt = new Date('2026-08-26T10:00:00Z');
    const alt = stand(
      { tag: '2026-08-25', tagZaehler: 3, monat: '2026-08', monatZaehler: 4 },
      jetzt,
    );

    expect(alt).toEqual({ tagZaehler: 0, monatZaehler: 4 });
  });
});

describe('Der Modellwechsel', () => {
  it('laeuft auf gemini-3.7-flash', () => {
    expect(MODELL).toBe('gemini-3.7-flash');
  });

  it('gibt dem denkenden Modell mehr Zeit, aber nicht mehr als die Function',
    () => {
      // Zwei Versuche muessen in die Function passen (`timeoutSeconds: 300`),
      // und der Client wartet 280 s. Beides bricht, wenn hier jemand nach
      // oben dreht, ohne die anderen beiden Zahlen anzufassen.
      expect(ZEITLIMIT_MS).toBe(120_000);
      expect(ZEITLIMIT_MS * 2).toBeLessThan(300_000);
    });
});
