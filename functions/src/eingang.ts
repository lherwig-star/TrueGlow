import { fehler } from './fehler';
import {
  AUFNAHMEN,
  istModul,
  moduleFuer,
  normalisiereRichtungsziele,
  technikenFuer,
  type Modul,
} from './labels';
import { neueMarke, saeubere } from './nutzertext';
import { leseSprache } from './sprache';
import { leseAusrichtung, type Ausrichtung } from './ausrichtung';
import { leseModus } from './modus';
import type {
  AnalysePromptDaten,
  Figurangaben,
  Profilangaben,
  Richtungsangaben,
  Stilangaben,
} from './analyse_prompt';
import type {
  CheckinPromptDaten,
  HabitRueckmeldung,
  Historieneintrag,
  Kapitelplan,
  WirkungsRueckmeldung,
} from './checkin_prompt';

/**
 * Pruefung und Normalisierung der Callable-Payloads.
 *
 * Grundhaltung: Der Client ist nicht vertrauenswuerdig. Alles, was hier nicht
 * ausdruecklich erlaubt wird, faellt weg – unbekannte Enum-Namen, ueberlange
 * Texte, zusaetzliche Felder.
 *
 * **Jeder Text, den ein Mensch selbst geschrieben hat, laeuft durch
 * [saeubere]** – der Richtungs-Freitext, die Anmerkungen im Check-in, die
 * Aufgabentexte. Das ist die eine Stelle, an der Nutzertext ins System
 * kommt, und deshalb die richtige Stelle zum Putzen. Warum das noetig ist
 * und was es genau entfernt, steht in `nutzertext.ts`; der Anlass steht in
 * SECURITY_AUDIT.md unter D1.
 */

/** Summe aller base64-Bilddaten pro Aufruf. */
export const MAX_BILD_BYTES = 8 * 1024 * 1024;

/**
 * Woran ein base64-kodiertes JPEG zu erkennen ist.
 *
 * Die ersten drei Bytes einer JPEG-Datei sind immer `FF D8 FF`. In base64
 * werden daraus die Zeichen `/9j/` – unabhaengig davon, was danach kommt.
 *
 * **Warum das geprueft wird** (SECURITY_AUDIT E1): Vorher schaute die
 * Pruefung nur auf Name, Laenge und Anzahl. Die Zeichenkette „das ist kein
 * Bild, sondern Text" kam als Foto durch, ging an Gemini und kostete dort
 * Kontingent und Tokens, bevor sie abgelehnt wurde. Ein Angriff auf Daten
 * ist das nicht, ein Kostenhebel schon.
 */
const JPEG_KENNUNG = '/9j/';

/**
 * Was in base64 ueberhaupt vorkommen darf.
 *
 * Bewusst nur ein Blick auf die ersten Zeichen und die Zeichenmenge: Eine
 * vollstaendige Dekodierung von acht Megabyte kostet Zeit und Speicher, und
 * ein Foto, das erst in der Mitte kaputtgeht, faellt ohnehin bei Gemini
 * heraus. Geprueft wird der Fall, der wirklich vorkommt – Daten, die gar
 * kein Bild sind.
 */
const BASE64 = /^[A-Za-z0-9+/=\s]+$/;

/** So viele Aufnahmetypen gibt es insgesamt. */
const MAX_BILDER_ANALYSE = Object.keys(AUFNAHMEN).length;

/** Erstfoto plus Fortschrittsfoto. */
const MAX_BILDER_CHECKIN = 2;

/**
 * Grosszuegige Obergrenzen gegen aufgeblaehte Prompts – und gegen den
 * Versuch, den Prompt mit einem sehr langen Text zu ertraenken.
 */
const MAX_FREITEXT = 1000;
const MAX_HABIT_LAENGE = 200;
const MAX_HABITS = 60;
const MAX_HISTORIE = 24;
const MAX_NOTIZ = 500;
const MAX_FRAGE = 200;

export interface AnalyseEingang {
  prompt: AnalysePromptDaten;
  /** Aufnahmetypen in Prompt-Reihenfolge. */
  bildTypen: string[];
  /** base64-JPEGs, gleiche Reihenfolge wie [bildTypen]. */
  bilder: string[];
}

export interface CheckinEingang {
  prompt: CheckinPromptDaten;
  bilder: string[];
}

// --- Analyse -----------------------------------------------------------

export function leseAnalyse(roh: unknown): AnalyseEingang {
  const daten = objekt(roh);

  const ausrichtung = leseAusrichtung(daten.ausrichtung);
  const module = leseModule(daten.module, ausrichtung);
  const { typen, bilder } = leseAnalyseBilder(daten.bilder);

  return {
    prompt: {
      sprache: leseSprache(daten.sprache),
      // Die Marke des Datenblocks entsteht hier, einmal pro Anfrage.
      marke: neueMarke(),
      ausrichtung,
      modus: leseModus(daten.modus),
      module,
      profil: leseProfil(daten.profil),
      figur: leseFigur(daten.eingaben),
      stil: leseStil(daten.eingaben),
      richtung: leseRichtung(daten.richtung),
      // Gefiltert wie auf dem Bildschirm: nur Techniken zu den bestellten
      // Kapiteln und nur solche, die es in dieser Ausrichtung gibt. Ein
      // alter oder veraenderter Client kommt damit nicht weiter als die
      // App selbst (DECISIONS 79).
      techniken: technikenFuer(daten.techniken, module, ausrichtung),
    },
    bildTypen: typen,
    bilder,
  };
}

function leseModule(roh: unknown, ausrichtung: Ausrichtung): Modul[] {
  const namen = Array.isArray(roh) ? roh.filter(istModul) : [];
  // Die Basis ist nicht verhandelbar – genau wie in AnalyseModul.ausNamen.
  const gewaehlt = new Set<Modul>(['basis', ...namen]);
  // Und die Ausrichtung entscheidet, was es ueberhaupt geben kann. Ein
  // Client, der im maennlichen Modus ein Make-up-Kapitel bestellt, bekommt
  // keins – hier faellt es weg, nicht erst im Prompt.
  return moduleFuer(ausrichtung).filter((m) => gewaehlt.has(m));
}

function leseAnalyseBilder(roh: unknown): { typen: string[]; bilder: string[] } {
  if (!Array.isArray(roh) || roh.length === 0) {
    throw fehler('fotosFehlen', 'Aufruf ohne Bilder');
  }
  if (roh.length > MAX_BILDER_ANALYSE) {
    throw fehler('apiFehler', `Zu viele Bilder: ${roh.length}`);
  }

  const typen: string[] = [];
  const bilder: string[] = [];
  let bytes = 0;

  for (const eintrag of roh) {
    const bild = objekt(eintrag);
    const typ = bild.typ;
    if (typeof typ !== 'string' || !(typ in AUFNAHMEN)) {
      throw fehler('fotosFehlen', `Unbekannter Aufnahmetyp: ${typ}`);
    }
    const daten = bild.daten;
    if (typeof daten !== 'string' || daten.length === 0) {
      throw fehler('fotosFehlen', `Leeres Bild fuer ${typ}`);
    }
    if (!istJpeg(daten)) {
      throw fehler('fotosFehlen', `Kein JPEG fuer ${typ}`);
    }

    bytes += daten.length;
    if (bytes > MAX_BILD_BYTES) {
      throw fehler('apiFehler', 'Bilddaten ueberschreiten die Obergrenze');
    }

    typen.push(typ);
    bilder.push(daten);
  }

  return { typen, bilder };
}

function leseProfil(roh: unknown): Profilangaben {
  const profil = objektOderLeer(roh);
  return {
    alter: text(profil.alter),
    budget: text(profil.budget),
    zeit: text(profil.zeit),
    fokus: namensliste(profil.fokus),
  };
}

function leseFigur(roh: unknown): Figurangaben {
  const figur = objektOderLeer(objektOderLeer(roh).figur);
  return {
    groesseCm: ganzzahl(figur.groesseCm, 80, 260),
    gewichtKg: ganzzahl(figur.gewichtKg, 25, 400),
  };
}

function leseStil(roh: unknown): Stilangaben {
  const stil = objektOderLeer(objektOderLeer(roh).stil);

  // Der frueher einzeln geschickte Dresscode. Eine App-Fassung, die noch
  // nicht aktualisiert ist, schickt ihn weiter -- Buero und Business Casual
  // werden zu "Arbeit / Nebenjob", der Rest hat keine naechstliegende
  // Entsprechung und faellt weg (DECISIONS 72).
  const alterDresscode = text(stil.dresscode);
  const ausDresscode =
    alterDresscode === 'buero' || alterDresscode === 'businessCasual'
      ? ['arbeitNebenjob']
      : [];

  return {
    // Dieselbe Ueberfuehrung wie bei der Richtung: Die Stilziele sind jetzt
    // Richtungsziele, und die alten Namen stehen in derselben Tabelle.
    ziele: normalisiereRichtungsziele(namensliste(stil.ziele)),
    zwecke: [...new Set([...namensliste(stil.zwecke), ...ausDresscode])],
    budget: text(stil.budget),
    pflegeaufwand: text(stil.pflegeaufwand),
  };
}

export function leseRichtung(roh: unknown): Richtungsangaben {
  const richtung = objektOderLeer(roh);
  return {
    // Alte Namen werden hier ueberfuehrt, nicht weggeworfen: Eine App, die
    // noch nicht aktualisiert wurde, schickt weiterhin `markanter` – und
    // deren Nutzer soll seine Richtung trotzdem im Report wiederfinden
    // (DECISIONS 58).
    ziele: normalisiereRichtungsziele(namensliste(richtung.ziele)),
    // Das einzige mehrzeilige Feld: Es ist als Nachricht an den Coach
    // gedacht, und Absaetze gehoeren dazu.
    freitext: saeubere(richtung.freitext, {
      max: MAX_FREITEXT,
      mehrzeilig: true,
    }),
  };
}

// --- Check-in ----------------------------------------------------------

export function leseCheckin(roh: unknown): CheckinEingang {
  const daten = objekt(roh);
  const checkin = objekt(daten.checkin);

  const typ = text(checkin.typ);
  if (typ === undefined) {
    throw fehler('apiFehler', 'Check-in ohne Typ');
  }

  const bilder = leseCheckinBilder(daten.bilder);

  return {
    prompt: {
      sprache: leseSprache(daten.sprache),
      marke: neueMarke(),
      ausrichtung: leseAusrichtung(daten.ausrichtung),
      typ,
      habits: leseHabits(checkin.habits),
      wirkung: leseWirkung(checkin.wirkung),
      plan: lesePlan(daten.plan),
      richtung: leseRichtung(daten.richtung),
      historie: leseHistorie(daten.historie),
      // Der Prompt spricht nur dann von Fotos, wenn auch wirklich zwei da sind.
      mitFotos: bilder.length === MAX_BILDER_CHECKIN,
    },
    bilder,
  };
}

function leseCheckinBilder(roh: unknown): string[] {
  if (!Array.isArray(roh) || roh.length === 0) return [];
  if (roh.length !== MAX_BILDER_CHECKIN) {
    // Der Vergleich braucht genau zwei Bilder; alles andere waere ein
    // Programmierfehler im Client.
    throw fehler('apiFehler', `Check-in mit ${roh.length} Bildern`);
  }

  let bytes = 0;
  const bilder: string[] = [];
  for (const eintrag of roh) {
    if (typeof eintrag !== 'string' || eintrag.length === 0) {
      throw fehler('apiFehler', 'Leeres Bild im Check-in');
    }
    bytes += eintrag.length;
    if (bytes > MAX_BILD_BYTES) {
      throw fehler('apiFehler', 'Bilddaten ueberschreiten die Obergrenze');
    }
    bilder.push(eintrag);
  }
  return bilder;
}

function leseHabits(roh: unknown): HabitRueckmeldung[] {
  if (!Array.isArray(roh)) return [];

  const gelesen: HabitRueckmeldung[] = [];
  for (const eintrag of roh.slice(0, MAX_HABITS)) {
    const feedback = objektOderLeer(eintrag);
    const habit = einzeilig(feedback.habit, MAX_HABIT_LAENGE);
    const bewertung = text(feedback.bewertung);
    if (habit.length === 0 || bewertung === undefined) continue;

    gelesen.push({
      habit,
      bewertung,
      grund: text(feedback.grund),
      notiz: einzeilig(feedback.notiz, MAX_NOTIZ),
    });
  }
  return gelesen;
}

function leseWirkung(roh: unknown): WirkungsRueckmeldung[] {
  if (!Array.isArray(roh)) return [];

  const gelesen: WirkungsRueckmeldung[] = [];
  for (const eintrag of roh.slice(0, MAX_HABITS)) {
    const w = objektOderLeer(eintrag);
    const frage = einzeilig(w.frage, MAX_FRAGE);
    const antwort = text(w.antwort);
    if (frage.length === 0 || antwort === undefined) continue;

    gelesen.push({ frage, antwort, notiz: einzeilig(w.notiz, MAX_NOTIZ) });
  }
  return gelesen;
}

function lesePlan(roh: unknown): Kapitelplan[] {
  if (!Array.isArray(roh)) return [];
  const kapitel: Kapitelplan[] = [];
  for (const eintrag of roh) {
    const k = objektOderLeer(eintrag);
    if (!istModul(k.modul)) continue;
    const habits = Array.isArray(k.habits)
      ? k.habits
          .slice(0, MAX_HABITS)
          .map((h: unknown) => einzeilig(h, MAX_HABIT_LAENGE))
          .filter((h: string) => h.length > 0)
      : [];
    kapitel.push({ modul: k.modul, habits });
  }
  return kapitel;
}

function leseHistorie(roh: unknown): Historieneintrag[] {
  if (!Array.isArray(roh)) return [];
  const eintraege: Historieneintrag[] = [];
  // Nur die juengsten Eintraege – die Historie waechst sonst unbegrenzt in
  // den Prompt hinein.
  for (const eintrag of roh.slice(-MAX_HISTORIE)) {
    const h = objektOderLeer(eintrag);
    const typ = text(h.typ);
    if (typ === undefined) continue;

    const probleme: { habit: string; grund?: string }[] = [];
    if (Array.isArray(h.probleme)) {
      for (const p of h.probleme.slice(0, MAX_HABITS)) {
        const problem = objektOderLeer(p);
        const habit = einzeilig(problem.habit, MAX_HABIT_LAENGE);
        if (habit.length === 0) continue;
        probleme.push({ habit, grund: text(problem.grund) });
      }
    }

    // Das Datum wird nur formatiert und nie ausgewertet – gesaeubert
    // gehoert es trotzdem, es kommt aus derselben Anfrage.
    eintraege.push({ datum: einzeilig(h.datum, 40), typ, probleme });
  }
  return eintraege;
}

// --- Bausteine ---------------------------------------------------------

/** Ob diese Zeichenkette wirklich ein base64-kodiertes JPEG ist. */
export function istJpeg(daten: string): boolean {
  if (!daten.startsWith(JPEG_KENNUNG)) return false;
  // Nur der Anfang wird auf die Zeichenmenge geprueft – das genuegt, um
  // Text von base64 zu unterscheiden, und kostet nichts.
  return BASE64.test(daten.substring(0, 256));
}

function objekt(roh: unknown): Record<string, unknown> {
  if (roh === null || typeof roh !== 'object' || Array.isArray(roh)) {
    throw fehler('apiFehler', 'Payload ist kein Objekt');
  }
  return roh as Record<string, unknown>;
}

function objektOderLeer(roh: unknown): Record<string, unknown> {
  return roh !== null && typeof roh === 'object' && !Array.isArray(roh)
    ? (roh as Record<string, unknown>)
    : {};
}

/** Nicht-leerer String oder undefined – fuer Enum-Namen. */
function text(roh: unknown): string | undefined {
  if (typeof roh !== 'string') return undefined;
  const wert = roh.trim();
  return wert.length === 0 ? undefined : wert;
}

/**
 * Ein einzeiliges Nutzertextfeld.
 *
 * Anmerkungen und Aufgabentexte stehen im Prompt mitten in einer Zeile, in
 * Anfuehrungszeichen. Ein Zeilenumbruch oder ein Anfuehrungszeichen darin
 * waere kein Inhalt, sondern der Versuch, eine eigene Zeile zu schreiben –
 * [saeubere] nimmt beides heraus.
 */
function einzeilig(roh: unknown, max: number): string {
  return saeubere(roh, { max });
}

function namensliste(roh: unknown): string[] {
  if (!Array.isArray(roh)) return [];
  return roh.filter((n): n is string => typeof n === 'string').slice(0, 50);
}

function ganzzahl(roh: unknown, min: number, max: number): number | undefined {
  const zahl =
    typeof roh === 'number'
      ? Math.round(roh)
      : typeof roh === 'string'
        ? Number.parseInt(roh, 10)
        : Number.NaN;
  if (!Number.isFinite(zahl) || zahl < min || zahl > max) return undefined;
  return zahl;
}
