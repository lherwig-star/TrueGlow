import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Die Fehlerfaelle der App (`AnalysisFehler` in
 * `lib/features/analysis/logic/analysis_service.dart`).
 *
 * Der Name geht als `details.fehler` zum Client, der daraus wieder seinen
 * Enum-Wert macht. So bleiben die bestehenden Fehlertexte und Tipps in der UI
 * unveraendert gueltig.
 */
export type Fehlerfall =
  | 'keinInternet'
  | 'zeitueberschreitung'
  | 'apiFehler'
  | 'kontingent'
  | 'kontingentMonat'
  | 'ungueltigeAntwort'
  | 'keinApiKey'
  | 'fotosFehlen';

/**
 * Welcher gRPC-Code zu welchem Fehlerfall gehoert.
 *
 * `kontingentMonat` teilt sich den Code mit `kontingent`. Das ist Absicht:
 * Ein Client, der den neuen Namen nicht kennt, faellt auf den Code zurueck
 * und zeigt weiterhin die allgemeine Kontingentmeldung statt eines
 * Serverfehlers.
 */
const CODES: Record<Fehlerfall, FunctionsErrorCode> = {
  keinInternet: 'unavailable',
  zeitueberschreitung: 'deadline-exceeded',
  apiFehler: 'internal',
  kontingent: 'resource-exhausted',
  kontingentMonat: 'resource-exhausted',
  ungueltigeAntwort: 'internal',
  keinApiKey: 'failed-precondition',
  fotosFehlen: 'invalid-argument',
};

/**
 * Baut den Fehler fuer den Client.
 *
 * [intern] landet ausschliesslich im Function-Log, nie beim Nutzer – dort
 * stehen sonst schnell Details, die niemanden etwas angehen.
 */
export function fehler(fall: Fehlerfall, intern?: string): HttpsError {
  if (intern) {
    console.warn(`${fall}: ${intern}`);
  }
  return new HttpsError(CODES[fall], fall, { fehler: fall });
}
