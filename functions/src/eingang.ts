import { fehler } from './fehler';
import { AUFNAHMEN, istModul, moduleFuer, type Modul } from './labels';
import { leseSprache } from './sprache';
import { leseAusrichtung, type Ausrichtung } from './ausrichtung';
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
 * Texte, zusaetzliche Felder. In den Prompt gelangt am Ende nur ein einziges
 * freies Textfeld (der Richtungs-Freitext), und das wird dort als Zitat
 * eingerahmt.
 */

/** Summe aller base64-Bilddaten pro Aufruf. */
export const MAX_BILD_BYTES = 8 * 1024 * 1024;

/** So viele Aufnahmetypen gibt es insgesamt. */
const MAX_BILDER_ANALYSE = Object.keys(AUFNAHMEN).length;

/**
 * Der Check-in nimmt **keine** Bilder mehr an.
 *
 * Fruehner gingen Erstfoto und Fortschrittsfoto an das Modell, damit es ein
 * Zwischenfazit aus dem Vergleich schreiben konnte. Seit DECISIONS 48 bleibt
 * das Fortschrittsfoto auf dem Geraet: Es ist ein Tagebuch fuer den Nutzer,
 * kein Material fuer die Auswertung.
 *
 * Der Server verlaesst sich dafuer nicht auf den Client. Was hier ankommt,
 * faellt heraus – ein alter oder manipulierter Client kann kein Bild mehr
 * ins Modell schmuggeln. Das Zwischenfazit gibt es weiterhin; es entsteht
 * jetzt aus den Antworten und der Historie.
 */
export const MAX_BILDER_CHECKIN = 0;

/** Grosszuegige Obergrenzen gegen aufgeblaehte Prompts. */
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
      ausrichtung,
      module,
      profil: leseProfil(daten.profil),
      figur: leseFigur(daten.eingaben),
      stil: leseStil(daten.eingaben),
      richtung: leseRichtung(daten.richtung),
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
  return {
    ziele: namensliste(stil.ziele),
    dresscode: text(stil.dresscode),
    budget: text(stil.budget),
    pflegeaufwand: text(stil.pflegeaufwand),
  };
}

export function leseRichtung(roh: unknown): Richtungsangaben {
  const richtung = objektOderLeer(roh);
  return {
    ziele: namensliste(richtung.ziele),
    freitext: gekuerzt(richtung.freitext, MAX_FREITEXT),
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
      ausrichtung: leseAusrichtung(daten.ausrichtung),
      typ,
      habits: leseHabits(checkin.habits),
      wirkung: leseWirkung(checkin.wirkung),
      plan: lesePlan(daten.plan),
      richtung: leseRichtung(daten.richtung),
      historie: leseHistorie(daten.historie),
      // Es gibt keine Fotos mehr im Check-in – der Prompt spricht deshalb
      // auch nicht mehr von welchen.
      mitFotos: false,
    },
    bilder,
  };
}

function leseCheckinBilder(roh: unknown): string[] {
  if (!Array.isArray(roh) || roh.length === 0) return [];

  // Abgewiesen wird nicht, verworfen schon: Ein Client, der noch Bilder
  // mitschickt, soll seinen Check-in bekommen – nur eben ohne sie.
  console.warn(
    `Check-in mit ${roh.length} Bildern aufgerufen. Fortschrittsfotos ` +
      'gehen nicht mehr an das Modell und werden verworfen.',
  );
  return [];
}

function leseHabits(roh: unknown): HabitRueckmeldung[] {
  if (!Array.isArray(roh)) return [];

  const gelesen: HabitRueckmeldung[] = [];
  for (const eintrag of roh.slice(0, MAX_HABITS)) {
    const feedback = objektOderLeer(eintrag);
    const habit = gekuerzt(feedback.habit, MAX_HABIT_LAENGE);
    const bewertung = text(feedback.bewertung);
    if (habit.length === 0 || bewertung === undefined) continue;

    gelesen.push({
      habit,
      bewertung,
      grund: text(feedback.grund),
      notiz: gekuerzt(feedback.notiz, MAX_NOTIZ),
    });
  }
  return gelesen;
}

function leseWirkung(roh: unknown): WirkungsRueckmeldung[] {
  if (!Array.isArray(roh)) return [];

  const gelesen: WirkungsRueckmeldung[] = [];
  for (const eintrag of roh.slice(0, MAX_HABITS)) {
    const w = objektOderLeer(eintrag);
    const frage = gekuerzt(w.frage, MAX_FRAGE);
    const antwort = text(w.antwort);
    if (frage.length === 0 || antwort === undefined) continue;

    gelesen.push({ frage, antwort, notiz: gekuerzt(w.notiz, MAX_NOTIZ) });
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
          .map((h: unknown) => gekuerzt(h, MAX_HABIT_LAENGE))
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
        const habit = gekuerzt(problem.habit, MAX_HABIT_LAENGE);
        if (habit.length === 0) continue;
        probleme.push({ habit, grund: text(problem.grund) });
      }
    }

    eintraege.push({ datum: text(h.datum) ?? '', typ, probleme });
  }
  return eintraege;
}

// --- Bausteine ---------------------------------------------------------

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

function gekuerzt(roh: unknown, max: number): string {
  if (typeof roh !== 'string') return '';
  const wert = roh.trim();
  return wert.length <= max ? wert : wert.substring(0, max);
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
