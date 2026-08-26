import { fehler } from './fehler';

/**
 * Das verwendete Vision-Modell – Gegenstueck zu `AnalysisConfig.modell`.
 *
 * Seit dem 26.08.2026 `gemini-3.7-flash` statt `gemini-3.5-flash-lite`. Der
 * neue Prompt allein hat die Antworten nicht tief genug gemacht; die Kosten
 * sind bekannt und abgewogen (DECISIONS 41).
 *
 * Zwei Eigenschaften des neuen Modells sind fuer diese Datei wichtig:
 *
 *  - Es **denkt** vor der Antwort, ab Werk auf Stufe "medium". Das kostet
 *    Zeit (deshalb das groessere Zeitlimit) und Tokens, die wie
 *    Ausgabe-Tokens abgerechnet werden. Abschalten laesst es sich bei
 *    Gemini 3 nicht, und wir wollen es auch nicht – es ist der Grund fuer
 *    den Wechsel.
 *  - Seine Gedanken stehen **nicht** in der Antwort, solange man sie nicht
 *    ausdruecklich anfordert. `textAusAntwort` siebt sie trotzdem aus: Ein
 *    Gedankenabschnitt im Antworttext wuerde das JSON unlesbar machen, und
 *    das faellt erst beim Nutzer auf.
 */
export const MODELL = 'gemini-3.7-flash';

const BASIS_URL = 'https://generativelanguage.googleapis.com/v1beta';

/**
 * Maximale Wartezeit pro Aufruf. Muss unter der Function-Zeitgrenze liegen.
 *
 * 120 s statt der frueheren 60 s: Ein denkendes Modell antwortet auf elf
 * Bilder spuerbar langsamer. Die Rechnung dahinter steht in `index.ts` bei
 * `timeoutSeconds` – zwei Versuche muessen hineinpassen.
 */
export const ZEITLIMIT_MS = 120_000;

/**
 * Ein Aufruf gegen die Gemini-API. Liefert den reinen Antworttext des Modells.
 *
 * Bewusst ohne jedes Wissen ueber Analyse oder Check-in – beide schicken
 * System-Prompt, Nutzertext und optional Bilder. Das ist derselbe
 * Request-Aufbau wie bisher in `gemini_client.dart`, nur eben serverseitig
 * und mit dem Schluessel aus dem Secret Manager.
 *
 * [bilder] sind base64-kodierte JPEGs in der Reihenfolge, in der sie im
 * Nutzertext benannt werden. Sie werden nach dem Aufruf nicht festgehalten
 * und tauchen in keiner Log-Ausgabe auf.
 */
export async function frage(options: {
  apiKey: string;
  systemPrompt: string;
  nutzerText: string;
  bilder?: string[];
}): Promise<string> {
  const { apiKey, systemPrompt, nutzerText } = options;
  const bilder = options.bilder ?? [];

  const url = `${BASIS_URL}/models/${MODELL}:generateContent`;

  const body = JSON.stringify({
    systemInstruction: { parts: [{ text: systemPrompt }] },
    contents: [
      {
        role: 'user',
        parts: [
          { text: nutzerText },
          ...bilder.map((bild) => ({
            inline_data: { mime_type: 'image/jpeg', data: bild },
          })),
        ],
      },
    ],
    // Bewusst nur das Antwortformat: Die Sampling-Parameter (temperature,
    // topP, topK) sind bei den aktuellen Modellen abgekuendigt und werden
    // ignoriert oder abgelehnt. Die Steuerung liegt vollstaendig im Prompt.
    generationConfig: {
      responseMimeType: 'application/json',
    },
  });

  const abbruch = new AbortController();
  const wecker = setTimeout(() => abbruch.abort(), ZEITLIMIT_MS);

  let antwort: Response;
  try {
    antwort = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // Als Header, nicht als Query-Parameter: so landet der Schluessel
        // nicht in Zugriffslogs oder Proxy-Historien.
        'x-goog-api-key': apiKey,
      },
      body,
      signal: abbruch.signal,
    });
  } catch (e) {
    if (e instanceof Error && e.name === 'AbortError') {
      throw fehler('zeitueberschreitung', 'Gemini hat nicht rechtzeitig geantwortet');
    }
    throw fehler('apiFehler', `Netzwerkfehler zu Gemini: ${e}`);
  } finally {
    clearTimeout(wecker);
  }

  if (antwort.status === 429) {
    throw fehler('kontingent', 'Gemini meldet HTTP 429');
  }
  if (antwort.status === 401 || antwort.status === 403) {
    // Serverseitiges Konfigurationsproblem: Der Schluessel im Secret Manager
    // fehlt, ist abgelaufen oder darf das Modell nicht nutzen.
    throw fehler('keinApiKey', `Gemini lehnt den Schluessel ab (HTTP ${antwort.status})`);
  }
  if (!antwort.ok) {
    throw fehler('apiFehler', `Gemini antwortet mit HTTP ${antwort.status}`);
  }

  return textAusAntwort(await antwort.text());
}

/** Schaelt den Modelltext aus der Gemini-Antwortstruktur. */
function textAusAntwort(rohtext: string): string {
  let json: unknown;
  try {
    json = JSON.parse(rohtext);
  } catch {
    return '';
  }

  if (json === null || typeof json !== 'object') return '';
  const wurzel = json as Record<string, unknown>;

  const kandidaten = wurzel.candidates;
  if (!Array.isArray(kandidaten) || kandidaten.length === 0) {
    // Kommt vor, wenn der Sicherheitsfilter greift.
    throw fehler('ungueltigeAntwort', 'Gemini liefert keine Kandidaten');
  }

  const kandidat = kandidaten[0] as Record<string, unknown>;

  // Ein abgeschnittener Report kommt als unlesbares JSON zurueck und kostet
  // dann einen zweiten Versuch. Der Grund steht nur hier – ohne diese Zeile
  // sieht man im Protokoll bloss "nicht lesbar".
  const ende = kandidat.finishReason;
  if (typeof ende === 'string' && ende !== 'STOP') {
    console.warn(`Gemini beendet die Antwort mit "${ende}"`);
  }

  const inhalt = kandidat.content;
  const teile =
    inhalt && typeof inhalt === 'object'
      ? (inhalt as Record<string, unknown>).parts
      : undefined;
  if (!Array.isArray(teile)) return '';

  return teile
    .filter((teil) => {
      // Gedankenabschnitte sind kein Antworttext. Sie kommen nur, wenn man
      // sie anfordert – wir tun es nicht, und falls sich das je aendert,
      // soll das JSON trotzdem lesbar bleiben.
      const t = teil as Record<string, unknown> | null;
      return !(t && typeof t === 'object' && t.thought === true);
    })
    .map((teil) =>
      teil && typeof teil === 'object'
        ? (teil as Record<string, unknown>).text
        : undefined,
    )
    .filter((text): text is string => typeof text === 'string')
    .join('');
}
