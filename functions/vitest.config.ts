import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Die Tests gegen den Firestore-Emulator laufen ueber ein eigenes
    // Kommando (npm run test:rules) und muessen hier ausgeschlossen sein.
    //
    // Diese Liste ist das Gegenstueck zur include-Liste in
    // vitest.rules.config.ts - beide muessen dieselben Dateien nennen. Am
    // 01.09.2026 kam dort kontingent.test.ts dazu und hier nicht: Die sieben
    // Tests liefen daraufhin auch im normalen Durchgang, wo kein Emulator
    // horcht, und scheiterten mit "delete failed". Aufgefallen ist es erst
    // am 03.09.2026, beim allerersten CI-Lauf auf GitHub - vorher gab es
    // kein Remote (DECISIONS 96).
    include: ['test/**/*.test.ts'],
    exclude: [
      'test/rules.test.ts',
      'test/loeschen.test.ts',
      'test/kontingent.test.ts',
      'node_modules/**',
    ],
    environment: 'node',
  },
});
