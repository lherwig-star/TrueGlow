import { describe, expect, it } from 'vitest';

import { systemPrompt, type AnalysePromptDaten } from '../src/analyse_prompt';
import { leseAnalyse } from '../src/eingang';
import { leseModus, type Modus } from '../src/modus';
import type { Modul } from '../src/labels';
import type { Sprache } from '../src/sprache';

/**
 * Der Modus „Neuen Look entdecken" – was er am Prompt aendert und was nicht.
 *
 * Der Anlass steht in DECISIONS 57: Die Analyse konnte nur den Ist-Zustand
 * verbessern. Wer Veraenderung wollte, bekam eine Antwort, die ihn festhielt.
 *
 * Zwei Sorten Test stehen hier. Die erste prueft, dass der verfeinernde
 * Modus **Wort fuer Wort** derselbe bleibt – sonst laesst sich nie sagen, ob
 * eine schlechtere Antwort vom neuen Modus kommt oder vom Umbau. Die zweite
 * prueft, dass im entdeckenden Modus die Forderungen wirklich im Prompt
 * stehen. Ob die Antwort dann gut ist, zeigt erst der Geraetetest.
 */

function daten(
  modus: Modus,
  sprache: Sprache = 'de',
  module: Modul[] = ['basis', 'stilKleiderschrank'],
  freitext = '',
): AnalysePromptDaten {
  return {
    sprache,
    ausrichtung: 'maennlich',
    modus,
    module,
    profil: { fokus: [] },
    figur: {},
    stil: { ziele: [], zwecke: [] },
    richtung: { ziele: [], freitext },
    techniken: [],
  };
}

describe('leseModus', () => {
  it('nimmt die beiden bekannten Namen', () => {
    expect(leseModus('verfeinern')).toBe('verfeinern');
    expect(leseModus('entdecken')).toBe('entdecken');
  });

  it('faellt sonst auf das bisherige Verhalten zurueck', () => {
    // Ein alter Client schickt das Feld gar nicht. Er soll denselben Report
    // bekommen wie vorher – nicht einen neuen Look, den niemand bestellt hat.
    for (const roh of [undefined, null, '', 'ENTDECKEN', 42, {}, ['entdecken']]) {
      expect(leseModus(roh), JSON.stringify(roh)).toBe('verfeinern');
    }
  });

  it('kommt aus der Nutzlast bis in die Prompt-Daten', () => {
    const eingang = leseAnalyse({
      sprache: 'de',
      ausrichtung: 'maennlich',
      modus: 'entdecken',
      module: ['basis'],
      bilder: [{ typ: 'basisFrontal', daten: '/9j/abc' }],
    });

    expect(eingang.prompt.modus).toBe('entdecken');
  });

  it('und ohne Feld steht dort verfeinern', () => {
    const eingang = leseAnalyse({
      sprache: 'de',
      ausrichtung: 'maennlich',
      module: ['basis'],
      bilder: [{ typ: 'basisFrontal', daten: '/9j/abc' }],
    });

    expect(eingang.prompt.modus).toBe('verfeinern');
  });
});

describe('Der verfeinernde Modus bleibt, was er war', () => {
  it('nichts aus dem neuen Modus steht in seinem Prompt', () => {
    const prompt = systemPrompt(daten('verfeinern'));

    expect(prompt).not.toContain('neuerLook');
    expect(prompt).not.toContain('Dein neuer Look');
    expect(prompt).not.toContain('NEUEN Look');
    expect(prompt).not.toContain('Regeln für den neuen Look');
    // Der alte Auftragssatz steht unveraendert da.
    expect(prompt).toContain(
      'Deine Aufgabe: eine konstruktive, motivierende Einschätzung',
    );
  });

  it('sein Schema hat seit DECISIONS 67 ebenfalls das Gesamtbild', () => {
    // Es ist das einzige Feld, das der verfeinernde Modus dazubekommen
    // hat – und es traegt dort denselben Namen wie im entdeckenden.
    const prompt = systemPrompt(daten('verfeinern'));
    expect(prompt).toContain('{\n  "gesamtbild": ');
    expect(prompt).not.toContain('"neuerLook"');
  });
});

describe('Der entdeckende Modus', () => {
  const prompt = systemPrompt(daten('entdecken'));

  it('bekommt einen anderen Auftrag', () => {
    expect(prompt).toContain('Entwirf dieser Person einen NEUEN Look');
    expect(prompt).not.toContain(
      'Deine Aufgabe: eine konstruktive, motivierende Einschätzung',
    );
  });

  it('verlangt einen Namen statt einer Richtungsangabe', () => {
    // „Probier doch mal was Frischeres" ist die Antwort, gegen die diese
    // Regel geschrieben ist.
    expect(prompt).toContain('- NAME:');
    // „Textured Crop" steht im Prompt ueber einen Zeilenumbruch verteilt –
    // deshalb ein Name aus derselben Liste, der auf eine Zeile passt.
    expect(prompt).toContain('Modern Mullet');
    expect(prompt).toContain('"Etwas Kürzeres"');
  });

  it('verlangt die Begruendung am sichtbaren Merkmal', () => {
    expect(prompt).toContain('- BEGRÜNDUNG AM GESICHT:');
    expect(prompt).toContain('Trendtipp');
  });

  it('verbietet, was der Haartyp nicht hergibt', () => {
    // Wortwoertlich im Paket gefordert: unsinnige oder nicht umsetzbare
    // Vorschlaege sind ausgeschlossen.
    expect(prompt).toContain('- MACHBAR:');
    expect(prompt).toContain('Feines Haar trägt keine');
  });

  it('verlangt den Satz fuer den Friseur', () => {
    expect(prompt).toContain('- BEIM FRISEUR SAGEN:');
  });

  it('verlangt sichtbare Veraenderung – und nennt, was bleibt', () => {
    expect(prompt).toContain('- SICHTBAR ANDERS:');
    expect(prompt).toContain('- WAS BLEIBT:');
  });

  it('verbietet den abwertenden Ton', () => {
    expect(prompt).toContain('nie abwertend über das jetzige');
  });

  it('verbietet den Standard-Vorschlag fuer alle', () => {
    expect(prompt).toContain('STANDARD-VORSCHLÄGE SIND VERBOTEN');
  });

  it('setzt das Gesamtbild als erstes Feld ins Schema', () => {
    // Ganz oben, weil der Report von oben nach unten gelesen wird.
    expect(prompt).toContain('{\n  "gesamtbild": ');
    expect(prompt.indexOf('"gesamtbild"')).toBeLessThan(
      prompt.indexOf('"kapitel": ['),
    );
  });

  it('gibt jedem Look-Kapitel eine eigene Vorschlags-Sektion', () => {
    const zeilen = prompt
      .split('\n')
      .filter((z) => z.includes('"Dein neuer Look"'));

    // Eine je bestelltem Kapitel – hier basis und stilKleiderschrank.
    expect(zeilen).toHaveLength(2);
    expect(prompt).toContain('an ERSTER Stelle');
  });

  it('laesst das Zielkapitel in Ruhe', () => {
    // Es gehoert allein dem Freitext (DECISIONS 39). Ein Frisurvorschlag
    // darin waere genau die Vermischung, die dort abgeschafft wurde.
    const mitZiel = systemPrompt(
      daten('entdecken', 'de', ['basis'], 'Ich will aufhören zu rauchen.'),
    );

    const zeile = mitZiel
      .split('\n')
      .find((z) => z.startsWith('- "persoenlicheZiele"'));

    expect(zeile).toBeDefined();
    expect(zeile).not.toContain('Dein neuer Look');
  });

  it('haengt Plan und Tagesaufgaben an den neuen Look', () => {
    // Sonst kommt ein Plan zurueck, der den alten Look pflegt: „Bart abends
    // in Form bringen" fuer einen Bart, der abrasiert werden soll.
    expect(prompt).toContain(
      'Plan und Tagesaufgaben gehören zum NEUEN Look, nicht zum alten',
    );
    expect(prompt).toContain('Übergangszeit');
  });

  it('macht Platz fuer die zusaetzliche Sektion', () => {
    // Ohne das kollidiert die Vorgabe mit der Obergrenze: Basis hat schon
    // Frisur, Bart und Brillenform.
    expect(prompt).toContain('- "sektionen": 3 bis 5 pro Kapitel.');
    expect(systemPrompt(daten('verfeinern'))).toContain(
      '- "sektionen": 2 bis 4 pro Kapitel.',
    );
  });

  it('behaelt alle Leitplanken des verfeinernden Modus', () => {
    // Der neue Modus ist ein anderer Auftrag, keine Ausnahme von den Regeln.
    for (const regel of [
      'Vergib KEINE Bewertungszahlen',
      'Bewerte nicht die Attraktivität',
      'Stelle KEINE medizinischen Diagnosen',
      'Bleib bei dem, was auf den Fotos wirklich zu sehen ist',
      'Qualität der Empfehlungen',
      'Wenn-dann-Anker',
    ]) {
      expect(prompt, regel).toContain(regel);
    }
  });

  it('schreibt auf Englisch englisch', () => {
    const englisch = systemPrompt(daten('entdecken', 'en'));

    expect(englisch).toContain('Your new look');
    expect(englisch).not.toContain('"Dein neuer Look"');
  });
});
