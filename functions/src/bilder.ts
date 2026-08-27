import { createHash } from 'node:crypto';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

import { fehler } from './fehler';
import { putzeSuchbegriff } from './nachbereitung';

/**
 * Beispielbilder zu den Vorschlaegen im Report – DECISIONS 69.
 *
 * Quelle ist Pexels: kostenlos, mit einer Lizenz, die die Nutzung erlaubt,
 * und mit einer API, die keine Bilddateien durch unseren Server schickt –
 * die App laedt sie spaeter direkt. Hier laufen nur URLs und Namen.
 *
 * Warum das ueberhaupt ueber den Server geht und nicht direkt aus der App:
 * Der Pexels-Schluessel waere in einem APK auslesbar, und der Verbrauch
 * ginge auf unser Konto. Es ist dasselbe Argument wie beim Gemini-Proxy.
 *
 * Zwei Bremsen liegen vor der Fotobibliothek:
 *   1. Ein Cache in Firestore. Derselbe Suchbegriff wird hoechstens einmal
 *      in [CACHE_TAGE] Tagen wirklich gesucht – und "textured crop haircut
 *      men" schlaegt das Modell vielen Nutzern vor.
 *   2. Ein Zaehler pro Stunde. Pexels erlaubt im kostenlosen Tarif 200
 *      Anfragen je Stunde; darueber antwortet es gar nicht mehr. Der Zaehler
 *      hoert vorher auf zu fragen, statt in die Sperre zu laufen.
 *
 * Was in beiden Faellen passiert, wenn nichts mehr geht: Die Bilderreihe
 * fehlt. Der Report ist davon unberuehrt.
 */

/** Bis zu vier Bilder je Vorschlag – mehr passt in keine Reihe. */
export const MAX_TREFFER = 4;

/**
 * Wie viele Suchbegriffe ein Aufruf mitbringen darf.
 *
 * Ein Kapitel hat hoechstens fuenf Sektionen; zwoelf lassen Luft, falls die
 * App spaeter zwei Kapitel auf einmal laedt, und deckeln zugleich, was ein
 * einzelner Aufruf an Pexels-Anfragen ausloesen kann.
 */
export const MAX_BEGRIFFE = 12;

/** Wie lange ein Treffer im Cache gilt. */
export const CACHE_TAGE = 30;

/**
 * Unsere eigene Obergrenze je Stunde.
 *
 * Deutlich unter den 200, die Pexels erlaubt: Der Zaehler laeuft ueber alle
 * Instanzen und kennt keine Anfrage, die gerade unterwegs ist. Der Abstand
 * ist der Puffer dafuer.
 */
export const PEXELS_PRO_STUNDE = 150;

/** Laenger als das wartet niemand auf ein Beispielbild. */
const PEXELS_ZEITLIMIT_MS = 8000;

const CACHE_SAMMLUNG = 'bildcache';
const ZAEHLER_SAMMLUNG = 'bildkontingent';

/** Ein Foto, so wie die App es braucht. */
export interface Bild {
  /** Kleine Fassung fuer die Reihe unter dem Vorschlag. */
  vorschau: string;
  /** Groessere Fassung fuer die Vollbildansicht. */
  gross: string;
  /** Der Fotograf – wird im Vollbild genannt (Pexels-Lizenz). */
  fotograf: string;
  /** Die Seite bei Pexels, auf die die Nennung verlinkt. */
  quelle: string;
  /** Die Bildbeschreibung von Pexels, fuer die Sprachausgabe. */
  beschreibung: string;
}

/**
 * Liest die Suchbegriffe aus der Anfrage.
 *
 * Nimmt `begriffe: string[]` und ebenso ein einzelnes `begriff: string` –
 * die App fragt kapitelweise, ein einzelner Begriff ist aber der Normalfall
 * beim Nachladen einer einzelnen Sektion.
 *
 * Es gilt genau dieselbe Regel wie bei der Nachbereitung der Analyse: Was
 * `putzeSuchbegriff` nicht durchlaesst, geht auch hier nicht an Pexels. Das
 * ist keine doppelte Pruefung aus Vorsicht, sondern die Stelle, an der ein
 * fremder Aufrufer sonst beliebige Zeichenketten in unsere Fotobibliothek
 * schoebe.
 */
export function leseBegriffe(roh: unknown): string[] {
  const daten = (roh ?? {}) as { begriffe?: unknown; begriff?: unknown };
  const eingang = Array.isArray(daten.begriffe)
    ? daten.begriffe
    : typeof daten.begriff === 'string'
      ? [daten.begriff]
      : [];

  const sauber: string[] = [];
  for (const eintrag of eingang) {
    const begriff = putzeSuchbegriff(eintrag);
    if (begriff === undefined) continue;
    if (sauber.includes(begriff)) continue;
    sauber.push(begriff);
    if (sauber.length === MAX_BEGRIFFE) break;
  }

  if (sauber.length === 0) {
    throw fehler('ungueltigeAnfrage', 'Bildersuche ohne brauchbaren Begriff');
  }
  return sauber;
}

/**
 * Was der Server zwischen sich und Pexels legt.
 *
 * Als Schnittstelle, damit die Ablauflogik in gewoehnlichen Tests laeuft –
 * ohne Emulator, ohne Netz. Die Firestore-Fassung steht weiter unten.
 */
export interface Bildcache {
  /** Was schon bekannt ist. Fehlende Begriffe fehlen in der Map. */
  lies(begriffe: string[]): Promise<Map<string, Bild[]>>;
  /** Merkt sich ein Ergebnis – auch ein leeres. */
  schreib(begriff: string, treffer: Bild[]): Promise<void>;
  /** Wie viele der [anzahl] Anfragen diese Stunde noch erlaubt. */
  reserviere(anzahl: number): Promise<number>;
}

/**
 * Holt die Bilder zu allen Begriffen – aus dem Cache, sonst von Pexels.
 *
 * Ein Begriff, zu dem nichts zurueckkommt, fehlt in der Antwort. Die App
 * laesst die Reihe dann weg; ein Platzhalter "keine Bilder gefunden" waere
 * eine Fehlermeldung fuer etwas, das kein Fehler ist.
 */
export async function bilderFuer(
  begriffe: string[],
  apiKey: string,
  cache: Bildcache,
  holen: typeof fetch = fetch,
): Promise<Record<string, Bild[]>> {
  const ergebnis: Record<string, Bild[]> = {};
  const offen: string[] = [];

  const bekannt = await cache.lies(begriffe);
  for (const begriff of begriffe) {
    const treffer = bekannt.get(begriff);
    if (treffer === undefined) offen.push(begriff);
    else ergebnis[begriff] = treffer;
  }

  if (offen.length === 0) return ergebnis;

  const erlaubt = await cache.reserviere(offen.length);
  if (erlaubt < offen.length) {
    console.warn(
      `Bildersuche: Stundenlimit erreicht, ${offen.length - erlaubt} ` +
        'Begriffe bleiben diesmal ohne Bilder',
    );
  }

  await Promise.all(
    offen.slice(0, erlaubt).map(async (begriff) => {
      const treffer = await pexelsSuche(begriff, apiKey, holen);
      // `undefined` heisst: Die Anfrage ist gescheitert. Das darf nicht in
      // den Cache – sonst gilt ein Netzaussetzer dreissig Tage lang als
      // "zu diesem Begriff gibt es keine Bilder".
      if (treffer === undefined) return;
      ergebnis[begriff] = treffer;
      await cache.schreib(begriff, treffer);
    }),
  );

  return ergebnis;
}

/**
 * Eine Suche bei Pexels.
 *
 * Liefert `undefined`, wenn die Anfrage gescheitert ist, und eine – auch
 * leere – Liste, wenn Pexels geantwortet hat. Der Unterschied entscheidet
 * darueber, ob das Ergebnis in den Cache darf.
 */
export async function pexelsSuche(
  begriff: string,
  apiKey: string,
  holen: typeof fetch = fetch,
): Promise<Bild[] | undefined> {
  // Hochformat: Ein Haarschnitt, ein Bart und ein Outfit sind stehende
  // Motive, und die Reihe in der App ist hochkant.
  const adresse =
    'https://api.pexels.com/v1/search' +
    `?query=${encodeURIComponent(begriff)}` +
    `&per_page=${MAX_TREFFER}&orientation=portrait`;

  try {
    const antwort = await holen(adresse, {
      headers: { Authorization: apiKey },
      signal: AbortSignal.timeout(PEXELS_ZEITLIMIT_MS),
    });

    if (!antwort.ok) {
      console.warn(
        `Bildersuche: Pexels antwortete ${antwort.status} auf "${begriff}"`,
      );
      return undefined;
    }

    return ausPexels(await antwort.json());
  } catch (e) {
    console.warn(`Bildersuche: Pexels nicht erreichbar ("${begriff}"): ${e}`);
    return undefined;
  }
}

/**
 * Liest die Antwort von Pexels.
 *
 * Defensiv wie der Analyse-Parser: Ein fehlendes Feld fuehrt nicht zum
 * Absturz, sondern dazu, dass genau dieses Bild wegfaellt. Ohne Fotograf
 * oder ohne Quellseite darf keins durch – beides verlangt die Lizenz.
 */
export function ausPexels(roh: unknown): Bild[] {
  const daten = (roh ?? {}) as { photos?: unknown };
  if (!Array.isArray(daten.photos)) return [];

  const bilder: Bild[] = [];
  for (const eintrag of daten.photos) {
    const foto = (eintrag ?? {}) as {
      url?: unknown;
      photographer?: unknown;
      alt?: unknown;
      src?: Record<string, unknown>;
    };
    const quellen = foto.src ?? {};

    const vorschau = adresse(quellen.medium) || adresse(quellen.small);
    const gross =
      adresse(quellen.large) || adresse(quellen.original) || vorschau;
    const quelle = adresse(foto.url);
    const fotograf = typeof foto.photographer === 'string'
      ? foto.photographer.trim()
      : '';

    if (vorschau === '' || quelle === '' || fotograf === '') continue;

    bilder.push({
      vorschau,
      gross,
      fotograf,
      quelle,
      beschreibung: typeof foto.alt === 'string' ? foto.alt.trim() : '',
    });
    if (bilder.length === MAX_TREFFER) break;
  }

  return bilder;
}

/** Nur https – ein http-Bild laedt die App gar nicht erst. */
function adresse(roh: unknown): string {
  return typeof roh === 'string' && roh.startsWith('https://')
    ? roh
    : '';
}

/** Der Dokumentname zu einem Begriff. */
export function cacheSchluessel(begriff: string): string {
  // Gehasht, weil ein Begriff Zeichen enthalten darf, die Firestore in
  // Dokumentnamen nicht mag. Der Begriff selbst steht im Dokument, damit der
  // Cache von Hand lesbar bleibt.
  return createHash('sha1').update(begriff).digest('hex');
}

/**
 * Der Cache in Firestore.
 *
 * Gespeichert werden ausschliesslich URLs und Namen – keine Bilddateien.
 * Die Sammlung liegt bewusst ausserhalb von `users/`: Sie gehoert keinem
 * Konto, wird von allen geteilt und darf deshalb auch bei einer
 * Kontoloeschung stehen bleiben. Die Security Rules sperren sie fuer jeden
 * Client; geschrieben wird nur hier, mit Admin-Rechten.
 */
export function firestoreCache(jetzt: () => Date = () => new Date()): Bildcache {
  const db = getFirestore();

  return {
    async lies(begriffe) {
      const gefunden = new Map<string, Bild[]>();
      if (begriffe.length === 0) return gefunden;

      const dokumente = await db.getAll(
        ...begriffe.map((b) =>
          db.collection(CACHE_SAMMLUNG).doc(cacheSchluessel(b)),
        ),
      );
      const grenze = jetzt().getTime() - CACHE_TAGE * 24 * 60 * 60 * 1000;

      for (const dokument of dokumente) {
        const daten = dokument.data();
        if (daten === undefined) continue;

        const gefundenAm = daten.gefundenAm;
        if (!(gefundenAm instanceof Timestamp)) continue;
        if (gefundenAm.toMillis() < grenze) continue;
        if (typeof daten.begriff !== 'string') continue;

        gefunden.set(
          daten.begriff,
          Array.isArray(daten.treffer) ? (daten.treffer as Bild[]) : [],
        );
      }

      return gefunden;
    },

    async schreib(begriff, treffer) {
      await db
        .collection(CACHE_SAMMLUNG)
        .doc(cacheSchluessel(begriff))
        .set({
          begriff,
          treffer,
          gefundenAm: Timestamp.fromDate(jetzt()),
        });
    },

    async reserviere(anzahl) {
      const dokument = db
        .collection(ZAEHLER_SAMMLUNG)
        .doc(stundenschluessel(jetzt()));

      // In einer Transaktion, weil mehrere Instanzen gleichzeitig zaehlen.
      // Ein Zaehler, der Anfragen verliert, waere genau der Grund, aus dem
      // es ihn gibt.
      return db.runTransaction(async (t) => {
        const stand = await t.get(dokument);
        const bisher = typeof stand.data()?.anfragen === 'number'
          ? (stand.data()!.anfragen as number)
          : 0;

        const gewaehrt = Math.max(
          0,
          Math.min(anzahl, PEXELS_PRO_STUNDE - bisher),
        );
        if (gewaehrt > 0) {
          t.set(dokument, { anfragen: bisher + gewaehrt }, { merge: true });
        }
        return gewaehrt;
      });
    },
  };
}

/** Ein Dokument je Stunde, in UTC – der Zaehler ist keine Anzeige. */
export function stundenschluessel(jetzt: Date): string {
  return jetzt.toISOString().slice(0, 13);
}
