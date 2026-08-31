import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

import { TECHNIK, type Techniknamen } from '../src/labels';
import { SPRACHEN, type Sprache } from '../src/sprache';

/**
 * Die Klammer zwischen Server und Wissens-Bibliothek (DECISIONS 88).
 *
 * Der Report nennt eine Technik mit dem Namen aus `TECHNIK` – die App erkennt
 * sie im Text wieder und blendet daneben das Info-Zeichen ein. Diese Kette
 * hat genau eine schwache Stelle: Weicht der Name in der Bibliothek von dem
 * im Katalog ab, bleibt das Zeichen aus. Nichts stürzt ab, nichts wird rot,
 * es fehlt nur still.
 *
 * Deshalb steht die Prüfung hier und nicht nur in der App: Wer einen Namen in
 * `labels.ts` ändert, bekommt es beim nächsten `npm test` gesagt.
 */

interface Eintrag {
  id: string;
  titel: string;
  synonyme: string[];
  wasIstDas: string;
  schritte: string[];
  wieOft: string;
  womit: string;
  woraufAchten: string;
}

function bibliothek(sprache: Sprache): Eintrag[] {
  // Vom Test-Ordner aus zwei Ebenen hoch in die App: Die Bibliothek gehoert
  // der App, geprueft wird sie hier, weil hier die Namen entstehen.
  const pfad = join(__dirname, '..', '..', 'assets', 'wissen',
    `wissen_${sprache}.json`);
  return JSON.parse(readFileSync(pfad, 'utf8')) as Eintrag[];
}

const namen = Object.keys(TECHNIK) as Techniknamen[];

describe('Wissens-Bibliothek', () => {
  for (const sprache of SPRACHEN) {
    describe(sprache, () => {
      const eintraege = bibliothek(sprache);
      const nachId = new Map(eintraege.map((e) => [e.id, e]));

      it('kennt jede Technik aus dem Katalog', () => {
        const fehlend = namen.filter((name) => !nachId.has(name));
        expect(fehlend).toEqual([]);
      });

      it('nennt sie genau so, wie der Report sie nennen wird', () => {
        // Der entscheidende Punkt: Der Prompt gibt das Label aus `TECHNIK`
        // vor, die App sucht im fertigen Text danach. Steht es weder als
        // Titel noch als Schreibvariante in der Bibliothek, findet die App
        // nichts.
        for (const name of namen) {
          const eintrag = nachId.get(name);
          const alle = [eintrag?.titel, ...(eintrag?.synonyme ?? [])];
          expect(alle, name).toContain(TECHNIK[name].label[sprache]);
        }
      });

      it('hat zu jedem Eintrag alle fünf Angaben', () => {
        for (const eintrag of eintraege) {
          for (const feld of [
            'titel',
            'wasIstDas',
            'wieOft',
            'womit',
            'woraufAchten',
          ] as const) {
            expect(eintrag[feld]?.trim(), `${eintrag.id}.${feld}`)
              .not.toBe('');
          }
          // Drei bis fuenf Schritte: weniger ist keine Anleitung, mehr liest
          // in einem Bottom-Sheet niemand.
          expect(eintrag.schritte.length, eintrag.id)
            .toBeGreaterThanOrEqual(3);
          expect(eintrag.schritte.length, eintrag.id).toBeLessThanOrEqual(5);
        }
      });

      it('verspricht nichts Invasives und nichts Medizinisches', () => {
        // Dieselbe Grenze wie im Katalog (DECISIONS 79). Sie darf nicht
        // dadurch aufweichen, dass eine Erklaerung „wenn du weitergehen
        // willst" ergaenzt.
        const verboten = [
          /dermaroll/i,
          /microneedl/i,
          /mikroneedl/i,
          /\bmewing\b/i,
          /mastic gum/i,
        ];
        for (const eintrag of eintraege) {
          const text = [
            eintrag.wasIstDas,
            ...eintrag.schritte,
            eintrag.wieOft,
            eintrag.womit,
          ].join(' ');
          for (const muster of verboten) {
            expect(muster.test(text), `${eintrag.id} ${muster}`).toBe(false);
          }
        }
      });

      it('nennt keine Marken, sondern Gattungen', () => {
        // „Womit" soll eine Produktgattung nennen. Eine Marke waere eine
        // Empfehlung, die niemand geprueft hat – und der erste Schritt zu
        // einer Werbeflaeche.
        const marken = /\b(Nivea|L'Or|Cerave|CeraVe|Garnier|Dove|Beiersdorf)/;
        for (const eintrag of eintraege) {
          expect(marken.test(eintrag.womit), eintrag.id).toBe(false);
        }
      });
    });
  }

  it('führt beide Sprachen mit denselben Kennungen', () => {
    // Sonst faellt eine Sprache still auf „kein Eintrag" zurueck.
    const de = bibliothek('de').map((e) => e.id);
    const en = bibliothek('en').map((e) => e.id);
    expect(en).toEqual(de);
  });

  it('hat keine doppelten Kennungen', () => {
    const ids = bibliothek('de').map((e) => e.id);
    expect(new Set(ids).size).toBe(ids.length);
  });
});
