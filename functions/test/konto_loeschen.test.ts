import { describe, expect, it } from 'vitest';

import { istUnbekannterNutzer } from '../src/konto';

/**
 * Ein Konto, das es nicht mehr gibt, ist kein Fehler (DECISIONS 93).
 *
 * Der Befund vom 01.09.2026, im Wortlaut aus dem Protokoll:
 *
 *   Unhandled error FirebaseAuthError: There is no user record corresponding
 *   to the provided identifier.
 *     errorInfo: { code: 'auth/user-not-found' }
 *     at async authKontoLoeschen (/workspace/lib/konto.js:137:5)
 *
 * Beim Nutzer kam davon nur „etwas ist schiefgelaufen" an — obwohl der
 * gewuenschte Zustand längst erreicht war.
 */
describe('Ein geloeschtes Konto noch einmal loeschen', () => {
  /** So sieht der Fehler aus, den `firebase-admin` wirklich wirft. */
  function authFehler(code: string): Error {
    const fehler = new Error('There is no user record corresponding to the '
      + 'provided identifier.') as Error & {
      errorInfo: { code: string; message: string };
      codePrefix: string;
    };
    fehler.errorInfo = { code, message: fehler.message };
    fehler.codePrefix = 'auth';
    return fehler;
  }

  it('erkennt den Fehler an seiner tatsaechlichen Form', () => {
    // `errorInfo.code`, nicht `code` – das ist die Stelle, an der eine
    // naheliegende Pruefung danebengegriffen haette.
    expect(istUnbekannterNutzer(authFehler('auth/user-not-found'))).toBe(true);
  });

  it('nimmt auch die flache Form', () => {
    expect(istUnbekannterNutzer({ code: 'auth/user-not-found' })).toBe(true);
  });

  it('laesst jeden anderen Fehler durch', () => {
    // Sonst verschluckt die Ausnahme echte Probleme: Ein Rechte- oder
    // Netzfehler waere dann eine stille, erfolgreiche Loeschung.
    for (const code of [
      'auth/internal-error',
      'auth/insufficient-permission',
      'auth/invalid-uid',
    ]) {
      expect(istUnbekannterNutzer(authFehler(code)), code).toBe(false);
    }
  });

  it('stolpert nicht ueber Unsinn', () => {
    for (const wert of [undefined, null, 'text', 42, {}, new Error('x')]) {
      expect(istUnbekannterNutzer(wert)).toBe(false);
    }
  });
});
