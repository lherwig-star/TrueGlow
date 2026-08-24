import { fehler } from './fehler';

/** Das verwendete Vision-Modell – Gegenstueck zu `AnalysisConfig.modell`. */
export const MODELL = 'gemini-2.5-flash';

const BASIS_URL = 'https://generativelanguage.googleapis.com/v1beta';

/** Maximale Wartezeit pro Aufruf. Muss unter der Function-Zeitgrenze liegen. */
export const ZEITLIMIT_MS = 60_000;

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
    generationConfig: {
      temperature: 0.7,
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

  const inhalt = (kandidaten[0] as Record<string, unknown>).content;
  const teile =
    inhalt && typeof inhalt === 'object'
      ? (inhalt as Record<string, unknown>).parts
      : undefined;
  if (!Array.isArray(teile)) return '';

  return teile
    .map((teil) =>
      teil && typeof teil === 'object'
        ? (teil as Record<string, unknown>).text
        : undefined,
    )
    .filter((text): text is string => typeof text === 'string')
    .join('');
}
