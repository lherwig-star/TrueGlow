import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { HttpsError } from 'firebase-functions/v2/https';

/**
 * Löschen von Daten und Konto.
 *
 * Warum das serverseitig passiert: Der Client kann `users/{uid}` nicht
 * vollständig leeren. Firestore löscht Unterkollektionen nicht mit, und der
 * Client kennt sie nur, soweit sein Datenmodell reicht — ein später
 * hinzugekommener Zweig bliebe unbemerkt liegen. `recursiveDelete` räumt den
 * kompletten Teilbaum, inklusive der Kontingentzähler, die der Client gar
 * nicht schreiben darf.
 */

export type Loeschmodus = 'daten' | 'konto';

/**
 * Wie frisch die Anmeldung für eine Kontolöschung sein muss.
 *
 * Ein Firebase-ID-Token gilt eine Stunde. Ohne diese Prüfung könnte ein
 * abgegriffenes Token ein Konto löschen — bei einer unumkehrbaren Aktion ist
 * das zu viel Spielraum. Der Client fängt den Fehler ab und meldet sich neu an.
 */
const MAX_ANMELDEALTER_SEK = 5 * 60;

export function leseModus(roh: unknown): Loeschmodus {
  const modus = (roh as { modus?: unknown })?.modus;
  if (modus === 'konto') return 'konto';
  if (modus === 'daten') return 'daten';
  throw new HttpsError('invalid-argument', 'unbekannterModus', {
    fehler: 'unbekannterModus',
  });
}

/**
 * Prüft, ob die Anmeldung frisch genug für eine Kontolöschung ist.
 *
 * Anonyme Konten sind ausgenommen: Es gibt keine Zugangsdaten, mit denen sich
 * jemand erneut anmelden könnte — ein „Neu anmelden" würde ein **neues**
 * Konto erzeugen und das alte unlöschbar zurücklassen. Solche Konten leben
 * ohnehin nur auf dem Gerät.
 */
export function pruefeFrischeAnmeldung(request: CallableRequest): void {
  const token = request.auth?.token as
    | { auth_time?: number; firebase?: { sign_in_provider?: string } }
    | undefined;

  if (token?.firebase?.sign_in_provider === 'anonymous') return;

  const anmeldung = token?.auth_time;
  if (typeof anmeldung !== 'number') {
    throw neuAnmelden('Token ohne auth_time');
  }

  const alter = Date.now() / 1000 - anmeldung;
  if (alter > MAX_ANMELDEALTER_SEK) {
    throw neuAnmelden(`Anmeldung ist ${Math.round(alter)} s alt`);
  }
}

function neuAnmelden(grund: string): HttpsError {
  console.info(`Kontolöschung verlangt frische Anmeldung: ${grund}`);
  return new HttpsError('failed-precondition', 'neuAnmelden', {
    fehler: 'neuAnmelden',
  });
}

/**
 * Löscht den kompletten Nutzerbaum.
 *
 * `recursiveDelete` arbeitet in Stapeln und ist damit nicht transaktional —
 * es ist aber vollständig und nimmt Unterkollektionen mit, was der Client
 * nicht kann. Bricht es ab, bleibt ein Rest stehen; ein zweiter Aufruf räumt
 * ihn weg, weil die Aktion idempotent ist.
 */
export async function datenLoeschen(uid: string): Promise<void> {
  const db = getFirestore();
  await db.recursiveDelete(db.collection('users').doc(uid));
}

/** Löscht das Auth-Konto. Danach ist die uid für immer verbraucht. */
export async function authKontoLoeschen(uid: string): Promise<void> {
  await getAuth().deleteUser(uid);
}
