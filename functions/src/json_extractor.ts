/**
 * Holt ein JSON-Objekt aus einer Modellantwort heraus.
 *
 * Portierung von `lib/features/analysis/logic/json_extractor.dart` – der
 * Lesepfad wandert mit der Antwort auf den Server, damit der Client eine
 * bereits geparste Struktur bekommt.
 */
export function extrahiere(antwort: string): Record<string, unknown> | null {
  const text = antwort.trim();
  if (text.length === 0) return null;

  // 1. Direkter Versuch – der Normalfall bei responseMimeType JSON.
  const direkt = parse(text);
  if (direkt) return direkt;

  // 2. Codefences entfernen (```json … ``` oder ``` … ```).
  const ohneFences = entferneFences(text);
  if (ohneFences !== text) {
    const ausFence = parse(ohneFences);
    if (ausFence) return ausFence;
  }

  // 3. Letzter Versuch: den aeussersten geschweiften Block herausschneiden.
  const block = aeussersterBlock(ohneFences);
  return block ? parse(block) : null;
}

function parse(text: string): Record<string, unknown> | null {
  try {
    const dekodiert = JSON.parse(text);
    return dekodiert !== null && typeof dekodiert === 'object' && !Array.isArray(dekodiert)
      ? (dekodiert as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}

function entferneFences(text: string): string {
  const muster = /^```(?:json|JSON)?\s*\n?([\s\S]*?)\n?```$/;
  const treffer = muster.exec(text.trim());
  return treffer ? treffer[1].trim() : text;
}

/**
 * Sucht die erste oeffnende Klammer und die dazu passende schliessende.
 * Klammern in Strings werden dabei uebersprungen.
 */
function aeussersterBlock(text: string): string | null {
  const start = text.indexOf('{');
  if (start === -1) return null;

  let tiefe = 0;
  let imString = false;
  let maskiert = false;

  for (let i = start; i < text.length; i++) {
    const zeichen = text[i];

    if (maskiert) {
      maskiert = false;
      continue;
    }
    if (zeichen === '\\') {
      maskiert = true;
      continue;
    }
    if (zeichen === '"') {
      imString = !imString;
      continue;
    }
    if (imString) continue;

    if (zeichen === '{') tiefe++;
    if (zeichen === '}') {
      tiefe--;
      if (tiefe === 0) return text.substring(start, i + 1);
    }
  }

  return null;
}
