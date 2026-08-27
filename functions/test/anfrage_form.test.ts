import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'vitest';

import { systemPrompt } from '../src/analyse_prompt';
import { leseAnalyse } from '../src/eingang';
import { nachbereiten } from '../src/nachbereitung';

/**
 * Die echte Anfrage der App gegen die echte Function.
 *
 * **Warum es diese Datei gibt.** Am 27.08.2026 fiel die Analyse aus, und der
 * erste Verdacht war ein Versatz zwischen App und Server – die App hatte am
 * selben Tag zwei neue Felder bekommen. Es war am Ende etwas anderes
 * (DECISIONS 59), aber die Frage liess sich nicht schnell beantworten: Die
 * Dart-Tests prueften die App, diese Tests prueften den Server, und
 * dazwischen war nichts.
 *
 * Die Nutzlast in `fixtures/` schreibt `test/anfrage_form_test.dart` – aus
 * demselben `AnalyseAnfrage.bauen`, das auch die App benutzt. Hier wird sie
 * durch den kompletten Weg geschickt: lesen, Prompt bauen, nachbereiten.
 * Faellt dabei ein Feld heraus oder heisst es anders, faellt das hier auf und
 * nicht am Geraet.
 */

function nutzlast(name: string): unknown {
  const pfad = join(__dirname, 'fixtures', `anfrage_${name}.json`);
  return JSON.parse(readFileSync(pfad, 'utf8'));
}

const FAELLE = ['entdecken_de', 'verfeinern_en'] as const;

describe('Die Nutzlast der App kommt vollstaendig an', () => {
  it('leseAnalyse nimmt sie an, ohne zu werfen', () => {
    for (const fall of FAELLE) {
      expect(() => leseAnalyse(nutzlast(fall)), fall).not.toThrow();
    }
  });

  it('jedes Feld findet seinen Platz', () => {
    const eingang = leseAnalyse(nutzlast('entdecken_de'));

    expect(eingang.prompt.sprache).toBe('de');
    expect(eingang.prompt.modus).toBe('entdecken');
    expect(eingang.prompt.ausrichtung).toBe('maennlich');
    expect(eingang.prompt.module).toEqual([
      'basis',
      'hautFarbtyp',
      'figurPassform',
      'stilKleiderschrank',
    ]);
    expect(eingang.prompt.profil.alter).toBe('a25bis34');
    expect(eingang.prompt.profil.fokus).toEqual(['haut', 'haare']);
    expect(eingang.prompt.figur.groesseCm).toBe(182);
    expect(eingang.prompt.stil.dresscode).toBe('businessCasual');
    expect(eingang.prompt.richtung.ziele).toEqual([
      'streetwearLaessig',
      'smartHochwertig',
    ]);
    expect(eingang.prompt.richtung.freitext).toContain('Bewerbungsgespräch');
    expect(eingang.bildTypen).toEqual([
      'basisFrontal',
      'basisProfilLinks',
      'figurGanzkoerperFrontal',
    ]);
    expect(eingang.bilder).toHaveLength(3);
  });

  it('die englische Fassung kommt englisch an', () => {
    const eingang = leseAnalyse(nutzlast('verfeinern_en'));

    expect(eingang.prompt.sprache).toBe('en');
    expect(eingang.prompt.modus).toBe('verfeinern');
  });

  it('nichts faellt stillschweigend heraus', () => {
    // Die eigentliche Bruchstelle: Ein Name, den die App schickt und der
    // Server nicht kennt, wird zu einer leeren Liste – ohne Fehler, ohne
    // Hinweis. Genau dafuer steht dieser Test.
    for (const fall of FAELLE) {
      const roh = nutzlast(fall) as Record<string, any>;
      const eingang = leseAnalyse(roh);

      expect(eingang.prompt.richtung.ziele.length, `${fall}: Richtung`).toBe(
        roh.richtung.ziele.length,
      );
      expect(eingang.prompt.module.length, `${fall}: Module`).toBe(
        roh.module.length,
      );
      expect(eingang.prompt.profil.fokus.length, `${fall}: Fokus`).toBe(
        roh.profil.fokus.length,
      );
      expect(eingang.bilder.length, `${fall}: Bilder`).toBe(roh.bilder.length);
    }
  });
});

describe('Der ganze Weg bis zum Prompt', () => {
  it('der Prompt entsteht und traegt die Angaben', () => {
    const eingang = leseAnalyse(nutzlast('entdecken_de'));
    const prompt = systemPrompt(eingang.prompt);

    // Der Modus.
    expect(prompt).toContain('Entwirf dieser Person einen NEUEN Look');
    // Die Richtungen, beide, mit ihrer konkreten Vorgabe.
    expect(prompt).toContain('Streetwear & lässig');
    expect(prompt).toContain('Smart & hochwertig');
    expect(prompt).toContain('Was diese Richtung konkret bedeutet:');
    // Der Freitext als Zitat.
    expect(prompt).toContain('Bewerbungsgespräch');
    // Die Angaben aus dem Onboarding und den Modulen.
    expect(prompt).toContain('25–34');
    expect(prompt).toContain('182 cm');
    expect(prompt).toContain('Business Casual');
    // Und das Zielkapitel, weil ein Freitext da ist.
    expect(prompt).toContain('"persoenlicheZiele"');
  });

  it('die Nachbereitung laeuft mit denselben Vorgaben durch', () => {
    const eingang = leseAnalyse(nutzlast('entdecken_de'));

    const antwort = {
      neuerLook: 'Oben Struktur, an den Seiten kurz.',
      kapitel: [
        {
          modul: 'basis',
          einleitung: 'Ovale Grundform.',
          habits: ['Nach dem Duschen: Paste einarbeiten'],
          sektionen: [
            {
              titel: 'Dein neuer Look',
              einschaetzung: 'Textured Crop mit mittelhohem Fade.',
              empfehlungen: ['Termin machen'],
              produkte: [],
            },
          ],
        },
      ],
      plan: { sofort: ['Heute'], dreissigTage: [], langfristig: [] },
    };

    const befund = nachbereiten(antwort, eingang.prompt);

    expect(befund.fremdeKapitel).toEqual([]);
    expect(befund.falscheSprache).toBeUndefined();
    // Der Vorspann ueberlebt die Nachbereitung – er ist der Einstieg des
    // Reports und darf nicht unterwegs verloren gehen.
    expect(befund.ergebnis.neuerLook).toBe('Oben Struktur, an den Seiten kurz.');
  });
});

describe('Die Tuer vor der Function', () => {
  const quelle = readFileSync(join(__dirname, '..', 'src', 'index.ts'), 'utf8');

  it('App Check bleibt erzwungen', () => {
    // Am 27.08.2026 hat genau diese Pruefung die Analyse gestoppt, und der
    // schnellste Weg zurueck waere gewesen, sie abzuschalten. Das waere der
    // teuerste: Ohne App Check kann jeder mit einem abgegriffenen
    // Auth-Token Gemini auf unsere Rechnung rufen (DECISIONS 59).
    expect(quelle).toContain('enforceAppCheck: true');
    expect(quelle).not.toContain('enforceAppCheck: false');
  });

  it('das Kontingent wird erst im Rumpf gebucht', () => {
    // Deshalb kostet ein abgelehnter Aufruf nichts: App Check laeuft im
    // Callable-Rahmen, bevor der Rumpf ueberhaupt beginnt – und `reservieren`
    // steht ausschliesslich in `mitKontingent`, also mitten im Rumpf.
    const stellen = quelle.split('reservieren(uid').length - 1;
    expect(stellen).toBe(1);
    expect(quelle).toContain('async function mitKontingent');

    const inMitKontingent = quelle
      .slice(quelle.indexOf('async function mitKontingent'))
      .includes('await reservieren(uid, art);');
    expect(inMitKontingent).toBe(true);
  });
});
