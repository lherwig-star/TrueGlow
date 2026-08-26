import { initializeApp } from 'firebase-admin/app';
import { defineSecret } from 'firebase-functions/params';
import { onCall, type CallableRequest } from 'firebase-functions/v2/https';

import * as analysePrompt from './analyse_prompt';
import * as checkinPrompt from './checkin_prompt';
import { fehler } from './fehler';
import { frage } from './gemini';
import { extrahiere } from './json_extractor';
import { leseAnalyse, leseCheckin } from './eingang';
import { melde, nachbereiten } from './nachbereitung';
import {
  authKontoLoeschen,
  datenLoeschen,
  leseModus,
  pruefeFrischeAnmeldung,
} from './konto';
import {
  checkinFreiReservieren,
  checkinFreiZurueck,
  freigeben,
  reservieren,
  type Kontingentart,
} from './limit';

/**
 * Der Gemini-Proxy.
 *
 * Warum es diese Functions gibt: Solange der Gemini-Schluessel im Client
 * liegt, ist er aus jedem APK auslesbar und jeder Fremdverbrauch geht auf
 * unsere Rechnung. Hier laeuft er nie an einem Ort, den ein Nutzer erreichen
 * kann – er kommt aus dem Secret Manager direkt in den Prozess.
 *
 * Drei Sperren liegen vor dem Modell:
 *   1. Firebase-Auth-Token (`request.auth`) – kein Konto, kein Aufruf.
 *   2. App Check (`enforceAppCheck`) – nur echte Installationen der App.
 *   3. Kontingent pro Konto – gedeckelter Schaden, falls 1 und 2 fallen.
 *
 * Bilder laufen ausschliesslich durch den Arbeitsspeicher: Sie werden nicht
 * gespeichert, nicht weitergereicht und tauchen in keiner Log-Zeile auf.
 */

initializeApp();

const geminiKey = defineSecret('GEMINI_API_KEY');

/**
 * Gemeinsame Einstellungen beider Endpunkte.
 *
 * `maxInstances` ist ein zweiter Kostendeckel neben dem Kontingent: Selbst
 * wenn viele Konten gleichzeitig rufen, laeuft die Rechnung nicht davon.
 */
const OPTIONEN = {
  region: 'europe-west3',
  secrets: [geminiKey],
  enforceAppCheck: true,
  memory: '1GiB' as const,
  // Muss ueber dem Gemini-Zeitlimit liegen – zwei Versuche plus Aufschlag.
  // Bei 120 s je Aufruf sind das 240 s; 300 lassen Luft fuer Auf- und
  // Abbau. Der Client wartet etwas kuerzer (`AnalysisConfig.zeitlimit`),
  // damit er die Zeitueberschreitung selbst meldet, statt in einen
  // abgebrochenen Aufruf zu laufen.
  timeoutSeconds: 300,
  maxInstances: 10,
};

/** Erstellt den Report aus den Aufnahmen. */
export const analysiere = onCall(OPTIONEN, async (request) => {
  const uid = pruefeAnmeldung(request);
  const eingang = leseAnalyse(request.data);

  const system = analysePrompt.systemPrompt(eingang.prompt);
  const nutzer = analysePrompt.nutzerText(
    eingang.bildTypen,
    eingang.prompt.sprache,
    eingang.prompt.ausrichtung,
  );

  const antwort = await mitKontingent(uid, 'analyse', () =>
    frageMitNachfassen({
      system,
      nutzer,
      bilder: eingang.bilder,
      nachfassen: analysePrompt.JSON_NACHFASSEN,
      brauchbar: istAnalyseBrauchbar,
    }),
  );

  // Der Prompt sagt dem Modell, was es liefern soll – das ist eine Bitte,
  // keine Zusicherung. Was trotzdem durchkommt, faellt hier heraus, und was
  // sich nicht aussieben laesst, steht wenigstens im Protokoll.
  const befund = nachbereiten(antwort, eingang.prompt);
  melde(befund, eingang.prompt);

  return { ergebnis: befund.ergebnis };
});

/** Wertet einen Check-in aus und liefert die Planaenderungen. */
export const checkinAuswerten = onCall(OPTIONEN, async (request) => {
  const uid = pruefeAnmeldung(request);
  const eingang = leseCheckin(request.data);

  const system = checkinPrompt.systemPrompt(eingang.prompt);
  const nutzer = checkinPrompt.nutzerText(
    eingang.prompt.typ,
    eingang.prompt.mitFotos,
    eingang.prompt.sprache,
  );

  // Ein faelliger Check-in ist frei – er zaehlt gegen den eigenen
  // Check-in-Zaehler und nicht gegen die zehn Analysen des Nutzers. Ob er
  // faellig ist, entscheidet der Server (siehe `checkinFreiReservieren`).
  // Ein zusaetzlicher Check-in ausserhalb des Takts ist etwas, das der
  // Nutzer selbst startet, und geht deshalb auf sein Analyse-Kontingent.
  const freigabe = await checkinFreiReservieren(uid);
  const art: Kontingentart = freigabe.frei ? 'checkin' : 'analyse';
  if (!freigabe.frei) {
    console.info('Check-in ausserhalb des Takts – zaehlt als Analyse.');
  }

  try {
    const auswertung = await mitKontingent(uid, art, () =>
      frageMitNachfassen({
        system,
        nutzer,
        bilder: eingang.bilder,
        nachfassen: checkinPrompt.JSON_NACHFASSEN,
        brauchbar: istAuswertungBrauchbar,
      }),
    );

    return { auswertung };
  } catch (e) {
    // Dieselbe Regel wie beim Kontingent: Nur wenn nachweislich kein
    // Modellaufruf stattfand, gibt es die Freistellung zurueck. Das gilt
    // auch, wenn schon das Kontingent abgelehnt hat – dann ist gar nichts
    // passiert.
    if (ohneVerbrauch(e) || istKontingentfehler(e)) {
      await checkinFreiZurueck(uid, freigabe);
    }
    throw e;
  }
});

/**
 * Löscht die Cloud-Daten des Kontos – wahlweise samt Konto.
 *
 * Zwei Modi, weil es zwei verschiedene Wünsche sind: „ich will neu anfangen"
 * und „ich will weg". Der zweite ist unumkehrbar und verlangt deshalb eine
 * frische Anmeldung.
 *
 * Der Secret-Zugriff wird hier nicht gebraucht; die Option bleibt trotzdem
 * dieselbe wie bei den anderen Endpunkten, damit Region, App Check und
 * Instanzgrenze an einer Stelle stehen.
 */
export const kontoLoeschen = onCall(OPTIONEN, async (request) => {
  const uid = pruefeAnmeldung(request);
  const modus = leseModus(request.data);

  if (modus === 'konto') {
    pruefeFrischeAnmeldung(request);
  }

  await datenLoeschen(uid);

  if (modus === 'konto') {
    await authKontoLoeschen(uid);
  }

  console.info(`Loeschung abgeschlossen (${modus}).`);
  return { modus };
});

// --- Bausteine ---------------------------------------------------------

function pruefeAnmeldung(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    // Callable-Funktionen pruefen App Check selbst; die Anmeldung nicht.
    throw fehler('apiFehler', 'Aufruf ohne Anmeldung');
  }
  return uid;
}

/**
 * Bucht das Kontingent, fuehrt den Aufruf aus und gibt die Buchung zurueck,
 * wenn nachweislich kein Modellaufruf zustande kam.
 */
async function mitKontingent<T>(
  uid: string,
  art: Kontingentart,
  aufruf: () => Promise<T>,
): Promise<T> {
  await reservieren(uid, art);

  try {
    return await aufruf();
  } catch (e) {
    if (ohneVerbrauch(e)) {
      await freigeben(uid, art);
    }
    throw e;
  }
}

/**
 * Ob bei diesem Fehler sicher keine Tokens verbraucht wurden.
 *
 * Nur dann darf das Kontingent zurueck. Eine Zeitueberschreitung gehoert
 * ausdruecklich nicht dazu: Dort hat das Modell gerechnet, die Antwort kam
 * nur zu spaet.
 */
function ohneVerbrauch(e: unknown): boolean {
  const details = (e as { details?: { fehler?: string } })?.details;
  return details?.fehler === 'keinApiKey' || details?.fehler === 'apiFehler';
}

/** Ob der Aufruf schon am Kontingent gescheitert ist. */
function istKontingentfehler(e: unknown): boolean {
  const fall = (e as { details?: { fehler?: string } })?.details?.fehler;
  return fall === 'kontingent' || fall === 'kontingentMonat';
}

/**
 * Ein Aufruf, bei unlesbarer Antwort genau ein zweiter mit ausdruecklichem
 * Hinweis auf valides JSON.
 *
 * Genau zwei Versuche, nicht mehr: Jede weitere Schleife vervielfacht die
 * Kosten unbemerkt – das ist der Punkt, an dem in der Roadmap "Versuche hart
 * begrenzen" steht.
 */
async function frageMitNachfassen(options: {
  system: string;
  nutzer: string;
  bilder: string[];
  nachfassen: string;
  brauchbar: (json: Record<string, unknown>) => boolean;
}): Promise<Record<string, unknown>> {
  const { system, nutzer, bilder, nachfassen, brauchbar } = options;
  const apiKey = geminiKey.value().trim();
  if (apiKey.length === 0) {
    throw fehler('keinApiKey', 'GEMINI_API_KEY ist im Secret Manager leer');
  }

  try {
    const erste = await frage({
      apiKey,
      systemPrompt: system,
      nutzerText: nutzer,
      bilder,
    });
    const gelesen = extrahiere(erste);
    if (gelesen && brauchbar(gelesen)) return gelesen;

    console.info('Erste Antwort nicht lesbar, zweiter Versuch.');

    const zweite = await frage({
      apiKey,
      systemPrompt: system,
      nutzerText: `${nutzer}\n\n${nachfassen}`,
      bilder,
    });
    const zweitesErgebnis = extrahiere(zweite);
    if (zweitesErgebnis && brauchbar(zweitesErgebnis)) return zweitesErgebnis;

    throw fehler('ungueltigeAntwort', 'Auch der zweite Versuch war unlesbar');
  } finally {
    // Die Bilder haben ihren Zweck erfuellt. Das Leeren ist vor allem eine
    // Zusicherung an den Leser: Ab hier existiert kein Bezug mehr auf die
    // Bilddaten, sie koennen sofort eingesammelt werden.
    bilder.length = 0;
  }
}

/** Grobpruefung: Hat die Antwort ueberhaupt Kapitel? */
function istAnalyseBrauchbar(json: Record<string, unknown>): boolean {
  return Array.isArray(json.kapitel) && json.kapitel.length > 0;
}

/**
 * Grobpruefung des Check-ins – Gegenstueck zu `CheckinAuswertung.istLeer`.
 * Eine Antwort ohne jeden Inhalt ist so unbrauchbar wie gar keine.
 */
function istAuswertungBrauchbar(json: Record<string, unknown>): boolean {
  const anpassungen = Array.isArray(json.anpassungen)
    ? json.anpassungen.length
    : 0;
  const text = (wert: unknown) =>
    typeof wert === 'string' && wert.trim().length > 0;

  return anpassungen > 0 || text(json.zusammenfassung) || text(json.fazit);
}
