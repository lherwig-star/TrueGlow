import { getFirestore } from 'firebase-admin/firestore';

import { MODELL } from './gemini';

/**
 * Die Datenauskunft nach Art. 15 und 20 DSGVO.
 *
 * **Warum das serverseitig passiert.** Aus demselben Grund wie das Loeschen
 * (`konto.ts`): Der Client kennt seinen Teilbaum nur, soweit sein
 * Datenmodell reicht. Ein spaeter hinzugekommener Zweig fehlte in der
 * Auskunft, ohne dass es jemandem auffiele – und eine Auskunft, die etwas
 * verschweigt, ist keine.
 *
 * **Was nicht drin ist und warum:** die Fotos. Sie liegen ausschliesslich auf
 * dem Geraet und waren nie auf dem Server; der Export sagt das ausdruecklich,
 * statt sie stillschweigend wegzulassen.
 */

/** Die Sammlungen unter `users/{uid}`, die dem Nutzer gehoeren. */
const SAMMLUNGEN = [
  'daten',
  'analysen',
  'checkins',
  'fortschritt',
  'kontingent',
] as const;

/**
 * Obergrenze je Sammlung.
 *
 * Ein Konto hat zehn Analysen im Monat und einen Fortschrittseintrag pro
 * Tag – 2000 sind weit ueber allem, was regulaer entsteht, und deckeln
 * zugleich, was ein einzelner Aufruf aus der Datenbank zieht.
 */
const MAX_DOKUMENTE = 2000;

export interface Datenauskunft {
  /** Was diese Datei ist – in beiden Sprachen, direkt im Dokument. */
  hinweis: Record<string, string>;
  erstelltAm: string;
  konto: { id: string };
  daten: Record<string, unknown[]>;
}

/**
 * Sammelt alles, was zu diesem Konto gespeichert ist.
 *
 * [uid] kommt ausschliesslich aus dem Login-Token des Aufrufers – es gibt
 * keinen Weg, die Auskunft eines fremden Kontos anzufordern.
 */
export async function datenauskunft(uid: string): Promise<Datenauskunft> {
  const db = getFirestore();
  const wurzel = db.collection('users').doc(uid);

  const daten: Record<string, unknown[]> = {};

  const kopf = await wurzel.get();
  daten.konto = kopf.exists ? [{ id: kopf.id, ...kopf.data() }] : [];

  for (const name of SAMMLUNGEN) {
    const treffer = await wurzel.collection(name).limit(MAX_DOKUMENTE).get();
    daten[name] = treffer.docs.map((d) => ({ id: d.id, ...d.data() }));
  }

  return {
    hinweis: {
      de:
        'Das ist die vollständige Kopie der Daten, die zu deinem TrueGlow-' +
        'Konto auf dem Server gespeichert sind (DSGVO Art. 15 und 20). ' +
        'Deine Fotos sind NICHT enthalten: Sie liegen ausschließlich auf ' +
        'deinem Gerät und waren nie auf unserem Server. Die Analysen wurden ' +
        `mit dem Modell ${MODELL} erstellt.`,
      en:
        'This is the complete copy of the data stored for your TrueGlow ' +
        'account on the server (GDPR Art. 15 and 20). Your photos are NOT ' +
        'included: they exist only on your device and were never on our ' +
        `server. The analyses were produced with the model ${MODELL}.`,
    },
    erstelltAm: new Date().toISOString(),
    konto: { id: uid },
    daten,
  };
}
