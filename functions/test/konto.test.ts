import { describe, expect, it } from 'vitest';

import { leseModus, pruefeFrischeAnmeldung } from '../src/konto';

/** Baut eine Anfrage mit dem Token, das Firebase mitliefert. */
function anfrage(options: {
  authTime?: number;
  anbieter?: string;
}): Parameters<typeof pruefeFrischeAnmeldung>[0] {
  return {
    auth: {
      uid: 'u1',
      token: {
        auth_time: options.authTime,
        firebase: { sign_in_provider: options.anbieter ?? 'google.com' },
      },
    },
  } as unknown as Parameters<typeof pruefeFrischeAnmeldung>[0];
}

const jetzt = () => Math.floor(Date.now() / 1000);

describe('leseModus', () => {
  it('kennt beide Modi', () => {
    expect(leseModus({ modus: 'daten' })).toBe('daten');
    expect(leseModus({ modus: 'konto' })).toBe('konto');
  });

  it('lehnt alles andere ab', () => {
    // Ein Tippfehler im Client darf nicht versehentlich ein Konto loeschen.
    expect(() => leseModus({ modus: 'alles' })).toThrowError(
      /unbekannterModus/,
    );
    expect(() => leseModus({})).toThrowError(/unbekannterModus/);
    expect(() => leseModus(null)).toThrowError(/unbekannterModus/);
  });
});

describe('pruefeFrischeAnmeldung', () => {
  it('laesst eine frische Anmeldung durch', () => {
    expect(() => pruefeFrischeAnmeldung(anfrage({ authTime: jetzt() }))).not.toThrow();
  });

  it('verlangt bei einer alten Anmeldung eine neue', () => {
    // Ein ID-Token gilt eine Stunde – fuer eine unumkehrbare Loeschung ist
    // das zu viel Spielraum.
    expect(() =>
      pruefeFrischeAnmeldung(anfrage({ authTime: jetzt() - 3600 })),
    ).toThrowError(/neuAnmelden/);
  });

  it('verlangt bei fehlendem Zeitstempel eine neue', () => {
    expect(() => pruefeFrischeAnmeldung(anfrage({}))).toThrowError(
      /neuAnmelden/,
    );
  });

  it('nimmt anonyme Konten aus', () => {
    // Sie haben keine Zugangsdaten – ein "neu anmelden" wuerde ein neues
    // Konto erzeugen und das alte unloeschbar zuruecklassen.
    expect(() =>
      pruefeFrischeAnmeldung(
        anfrage({ authTime: jetzt() - 86_400, anbieter: 'anonymous' }),
      ),
    ).not.toThrow();
  });
});
