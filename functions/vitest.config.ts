import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Die Rules-Tests brauchen den Firestore-Emulator und laufen deshalb
    // ueber ein eigenes Kommando (npm run test:rules).
    include: ['test/**/*.test.ts'],
    exclude: [
      'test/rules.test.ts',
      'test/loeschen.test.ts',
      'node_modules/**',
    ],
    environment: 'node',
  },
});
