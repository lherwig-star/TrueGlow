import { getFirestore, FieldValue } from 'firebase-admin/firestore';

import { fehler } from './fehler';

/**
 * Serverseitiges Kontingent pro Konto.
 *
 * Zwei Zaehler, beide in `users/{uid}/kontingent/{art}`. Sie stehen bewusst
 * im Nutzerbaum und nicht in einer eigenen Sammlung: So gilt dieselbe
 * Loeschregel wie fuer alle uebrigen Nutzerdaten. Die Security Rules
 * verbieten dem Client jeden Schreibzugriff darauf – gezaehlt wird
 * ausschliesslich hier, mit Admin-Rechten.
 */

export type Kontingentart = 'analyse' | 'checkin';

interface Grenze {
  proTag: number;
  proMonat: number;
}

/**
 * Die Analyse-Grenzen kommen aus der Roadmap. Der Check-in bekommt einen
 * eigenen, groesseren Zaehler: Er ist ein deutlich kleinerer Aufruf (zwei
 * Bilder statt bis zu elf) und faellt planmaessig hoechstens alle sieben Tage
 * an. Wuerde er aus demselben Topf zaehlen, koennten drei Analysen an einem
 * Tag den faelligen Check-in blockieren.
 */
export const GRENZEN: Record<Kontingentart, Grenze> = {
  analyse: { proTag: 3, proMonat: 30 },
  checkin: { proTag: 5, proMonat: 40 },
};

/** Tages- und Monatsschluessel in deutscher Zeit. */
export function schluessel(jetzt: Date = new Date()): {
  tag: string;
  monat: string;
} {
  // `sv-SE` liefert das ISO-Format jjjj-mm-tt ohne eigenes Zusammenstueckeln.
  const tag = new Intl.DateTimeFormat('sv-SE', {
    timeZone: 'Europe/Berlin',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(jetzt);

  return { tag, monat: tag.substring(0, 7) };
}

/** Der aktuelle Stand eines Zaehlers, bereits auf heute normalisiert. */
export function stand(
  daten: Record<string, unknown> | undefined,
  jetzt: Date = new Date(),
): { tagZaehler: number; monatZaehler: number } {
  const { tag, monat } = schluessel(jetzt);
  const zahl = (wert: unknown) =>
    typeof wert === 'number' && Number.isFinite(wert) && wert > 0
      ? Math.floor(wert)
      : 0;

  return {
    tagZaehler: daten?.tag === tag ? zahl(daten?.tagZaehler) : 0,
    monatZaehler: daten?.monat === monat ? zahl(daten?.monatZaehler) : 0,
  };
}

/**
 * Bucht einen Aufruf, bevor Gemini gerufen wird.
 *
 * Reserviert wird im Voraus und nicht im Nachhinein: Wer den Aufruf mitten
 * im Lauf abbricht, soll ihn trotzdem bezahlt haben – sonst laesst sich das
 * Limit durch Abbrechen umgehen.
 *
 * Wirft `kontingent`, wenn Tages- oder Monatsgrenze erreicht ist.
 */
export async function reservieren(
  uid: string,
  art: Kontingentart,
  jetzt: Date = new Date(),
): Promise<void> {
  const grenze = GRENZEN[art];
  const referenz = getFirestore()
    .collection('users')
    .doc(uid)
    .collection('kontingent')
    .doc(art);

  const { tag, monat } = schluessel(jetzt);

  await getFirestore().runTransaction(async (transaktion) => {
    const doc = await transaktion.get(referenz);
    const aktuell = stand(doc.data(), jetzt);

    if (aktuell.tagZaehler >= grenze.proTag) {
      throw fehler('kontingent', `Tagesgrenze ${art} erreicht (${uid})`);
    }
    if (aktuell.monatZaehler >= grenze.proMonat) {
      throw fehler('kontingent', `Monatsgrenze ${art} erreicht (${uid})`);
    }

    transaktion.set(referenz, {
      tag,
      tagZaehler: aktuell.tagZaehler + 1,
      monat,
      monatZaehler: aktuell.monatZaehler + 1,
      aktualisiertAm: FieldValue.serverTimestamp(),
    });
  });
}

/**
 * Gibt eine Reservierung wieder frei.
 *
 * Nur fuer Faelle, in denen nachweislich kein Gemini-Aufruf stattgefunden hat
 * (fehlender oder abgelehnter Schluessel, Netzwerkfehler vor der Antwort).
 * Bei Zeitueberschreitung oder unlesbarer Antwort wird **nicht** freigegeben –
 * dort sind die Tokens bereits verbraucht.
 */
export async function freigeben(
  uid: string,
  art: Kontingentart,
  jetzt: Date = new Date(),
): Promise<void> {
  const referenz = getFirestore()
    .collection('users')
    .doc(uid)
    .collection('kontingent')
    .doc(art);

  try {
    await getFirestore().runTransaction(async (transaktion) => {
      const doc = await transaktion.get(referenz);
      const aktuell = stand(doc.data(), jetzt);
      if (aktuell.tagZaehler === 0 && aktuell.monatZaehler === 0) return;

      transaktion.set(
        referenz,
        {
          tagZaehler: Math.max(0, aktuell.tagZaehler - 1),
          monatZaehler: Math.max(0, aktuell.monatZaehler - 1),
          aktualisiertAm: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });
  } catch (e) {
    // Eine nicht zurueckgenommene Reservierung ist aergerlich, aber kein
    // Grund, den eigentlichen Fehler zu ueberdecken.
    console.warn(`Kontingent konnte nicht freigegeben werden: ${e}`);
  }
}
