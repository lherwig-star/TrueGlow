import 'dart:convert';

/// Holt ein JSON-Objekt aus einer KI-Antwort heraus.
/// Modelle liefern trotz klarer Anweisung gern Markdown-Codefences oder einen
/// Satz davor – beides wird hier abgeraeumt.
class JsonExtractor {
  JsonExtractor._();

  /// Gibt das geparste Objekt zurueck oder null, wenn nichts Gueltiges drin ist.
  static Map<String, dynamic>? extrahiere(String antwort) {
    final text = antwort.trim();
    if (text.isEmpty) return null;

    // 1. Direkter Versuch – der Normalfall bei responseMimeType JSON.
    final direkt = _parse(text);
    if (direkt != null) return direkt;

    // 2. Codefences entfernen (```json ... ``` oder ``` ... ```).
    final ohneFences = _entferneFences(text);
    if (ohneFences != text) {
      final ausFence = _parse(ohneFences);
      if (ausFence != null) return ausFence;
    }

    // 3. Letzter Versuch: den aeussersten geschweiften Block herausschneiden.
    final block = _aeussersterBlock(ohneFences);
    if (block != null) return _parse(block);

    return null;
  }

  static Map<String, dynamic>? _parse(String text) {
    try {
      final dekodiert = jsonDecode(text);
      return dekodiert is Map ? Map<String, dynamic>.from(dekodiert) : null;
    } on FormatException {
      return null;
    }
  }

  static String _entferneFences(String text) {
    final muster = RegExp(
      r'^```(?:json|JSON)?\s*\n?([\s\S]*?)\n?```$',
      multiLine: false,
    );
    final treffer = muster.firstMatch(text.trim());
    return treffer != null ? treffer.group(1)!.trim() : text;
  }

  /// Sucht die erste oeffnende Klammer und die dazu passende schliessende.
  /// Klammern in Strings werden dabei uebersprungen.
  static String? _aeussersterBlock(String text) {
    final start = text.indexOf('{');
    if (start == -1) return null;

    var tiefe = 0;
    var imString = false;
    var maskiert = false;

    for (var i = start; i < text.length; i++) {
      final zeichen = text[i];

      if (maskiert) {
        maskiert = false;
        continue;
      }
      if (zeichen == r'\') {
        maskiert = true;
        continue;
      }
      if (zeichen == '"') {
        imString = !imString;
        continue;
      }
      if (imString) continue;

      if (zeichen == '{') tiefe++;
      if (zeichen == '}') {
        tiefe--;
        if (tiefe == 0) return text.substring(start, i + 1);
      }
    }

    return null;
  }
}
