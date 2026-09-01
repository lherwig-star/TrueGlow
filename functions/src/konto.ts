import { getAuth } from 'firebase-admin/auth';
import {
  getFirestore,
  type CollectionReference,
  type DocumentData,
} from 'firebase-admin/firestore';
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
 *
 * **[kontingentBehalten] ist die eine Ausnahme davon** — und der Grund steht
 * in SECURITY_AUDIT B1: Bis dahin verschwand mit dem Nutzerbaum auch der
 * Verbrauchszähler, und damit ließ sich die Monatsgrenze durch wiederholtes
 * "Alle Daten löschen" beliebig oft zurücksetzen. Zehn Analysen, löschen,
 * zehn weitere — auf unsere Rechnung.
 *
 * Beim Löschen des **Kontos** wird nichts behalten: Die uid ist danach für
 * immer verbraucht, ein Zähler dazu wäre ein Datensatz ohne Zweck.
 */
export async function datenLoeschen(
  uid: string,
  options: { kontingentBehalten: boolean },
): Promise<void> {
  const db = getFirestore();
  const wurzel = db.collection('users').doc(uid);
  const zaehler = wurzel.collection('kontingent');

  const gesichert = options.kontingentBehalten
    ? await kontingentLesen(zaehler)
    : [];

  await db.recursiveDelete(wurzel);

  for (const [id, daten] of gesichert) {
    await kontingentZurueck(zaehler.doc(id), daten);
  }
}

/** Der Stand aller Zähler, bevor gelöscht wird. */
async function kontingentLesen(
  sammlung: CollectionReference,
): Promise<[string, DocumentData][]> {
  const treffer = await sammlung.get();
  return treffer.docs.map((d) => [d.id, d.data()]);
}

/**
 * Schreibt einen gesicherten Zählerstand zurück.
 *
 * In einer Transaktion und mit dem jeweils **höheren** Wert: Zwischen dem
 * Sichern und dem Zurückschreiben kann eine Analyse gestartet worden sein.
 * Sie würde sonst überschrieben — und wäre damit gratis.
 */
async function kontingentZurueck(
  referenz: FirebaseFirestore.DocumentReference,
  gesichert: DocumentData,
): Promise<void> {
  await getFirestore().runTransaction(async (transaktion) => {
    const jetzt = (await transaktion.get(referenz)).data() ?? {};

    const hoeher = (feld: string, schluesselfeld: string) => {
      // Nur vergleichbar, wenn beide denselben Tag bzw. Monat meinen.
      if (jetzt[schluesselfeld] !== gesichert[schluesselfeld]) {
        return jetzt[feld] ?? gesichert[feld];
      }
      return Math.max(zahl(jetzt[feld]), zahl(gesichert[feld]));
    };

    transaktion.set(
      referenz,
      {
        ...gesichert,
        ...jetzt,
        tagZaehler: hoeher('tagZaehler', 'tag'),
        monatZaehler: hoeher('monatZaehler', 'monat'),
      },
      { merge: true },
    );
  });
}

function zahl(wert: unknown): number {
  return typeof wert === 'number' && Number.isFinite(wert) ? wert : 0;
}

/**
 * Löscht das Auth-Konto. Danach ist die uid für immer verbraucht.
 *
 * **Vorher werden die Sitzungen widerrufen** (SECURITY_AUDIT H). Ein
 * Firebase-ID-Token gilt eine Stunde und wird beim Löschen des Kontos nicht
 * von selbst ungültig — wer unmittelbar davor ein frisches Token hatte,
 * könnte damit noch eine Weile Analysen starten. `revokeRefreshTokens`
 * schließt den Spalt für alles, was danach ein neues Token bräuchte.
 *
 * Der Widerruf steht in einem eigenen `try`: Scheitert er, ist das
 * ärgerlich, aber kein Grund, das Löschen selbst abzubrechen — das wäre die
 * schlechtere von zwei Hälften.
 *
 * **Ein Konto, das es nicht mehr gibt, ist kein Fehler** (DECISIONS 93). Am
 * 01.09.2026 hat genau das den zweiten Versuch zerschossen: Der erste Lauf
 * war durchgegangen (`Loeschung abgeschlossen (konto)`), die App war danach
 * an anderer Stelle stehen geblieben, und der zweite Aufruf traf auf
 *
 *     FirebaseAuthError: There is no user record corresponding to the
 *     provided identifier.  (auth/user-not-found)
 *
 * Das flog als „Unhandled error" durch und kam beim Nutzer als
 * „etwas ist schiefgelaufen" an — obwohl der gewünschte Zustand längst
 * erreicht war. Löschen ist überall sonst in dieser Datei idempotent; hier
 * war es die eine Stelle, die es nicht war.
 */
export async function authKontoLoeschen(uid: string): Promise<void> {
  try {
    await getAuth().revokeRefreshTokens(uid);
  } catch (e) {
    if (!istUnbekannterNutzer(e)) console.warn(`Sitzungen nicht widerrufen: ${e}`);
  }

  try {
    await getAuth().deleteUser(uid);
  } catch (e) {
    if (!istUnbekannterNutzer(e)) throw e;
    console.info('Konto war bereits geloescht – nichts mehr zu tun.');
  }
}

/**
 * Ob der Fehler bedeutet: Zu dieser Kennung gibt es kein Konto (mehr).
 *
 * Exportiert, damit sich die Form des Fehlers pruefen laesst, ohne die
 * Auth-Verwaltung anzufassen: `firebase-admin` legt den Code unter
 * `errorInfo.code` ab, nicht unter `code` – wer nur `e.code` liest, sieht
 * `undefined` und wirft weiter.
 */
export function istUnbekannterNutzer(fehler: unknown): boolean {
  const code = (fehler as { errorInfo?: { code?: string }; code?: string })
    ?.errorInfo?.code ?? (fehler as { code?: string })?.code;
  return code === 'auth/user-not-found';
}
