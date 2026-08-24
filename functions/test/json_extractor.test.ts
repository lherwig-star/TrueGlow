import { describe, expect, it } from 'vitest';

import { extrahiere } from '../src/json_extractor';

/**
 * Dieselben Faelle wie in `test/analysis_parsing_test.dart`. Der Lesepfad ist
 * mit dem Modellaufruf auf den Server gewandert; die Zusicherungen bleiben.
 */
describe('extrahiere', () => {
  it('liest reines JSON', () => {
    expect(extrahiere('{"a": 1}')).toEqual({ a: 1 });
  });

  it('entfernt Markdown-Codefences', () => {
    expect(extrahiere('```json\n{"a": 1}\n```')).toEqual({ a: 1 });
  });

  it('entfernt Codefences ohne Sprachangabe', () => {
    expect(extrahiere('```\n{"a": 1}\n```')).toEqual({ a: 1 });
  });

  it('schneidet Fliesstext vor und nach dem Objekt weg', () => {
    const json = extrahiere('Klar, hier ist deine Analyse:\n{"a": 1}\nViel Erfolg!');
    expect(json).toEqual({ a: 1 });
  });

  it('kommt mit geschweiften Klammern in Strings klar', () => {
    const json = extrahiere('Antwort: {"text": "eine } Klammer", "b": 2} Ende');
    expect(json?.text).toBe('eine } Klammer');
    expect(json?.b).toBe(2);
  });

  it('gibt null zurueck, wenn gar kein JSON drin ist', () => {
    expect(extrahiere('Tut mir leid, das geht nicht.')).toBeNull();
    expect(extrahiere('')).toBeNull();
  });

  it('gibt null bei kaputtem JSON zurueck', () => {
    expect(extrahiere('{"a": }')).toBeNull();
  });

  it('gibt null bei einer JSON-Liste zurueck', () => {
    // Der Report ist immer ein Objekt – eine Liste waere unbrauchbar.
    expect(extrahiere('[1, 2, 3]')).toBeNull();
  });
});
