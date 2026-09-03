import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // ACHTUNG: Jede Datei hier muss auch in der exclude-Liste von
    // vitest.config.ts stehen, sonst laeuft sie zusaetzlich im normalen
    // Durchgang und scheitert dort ohne Emulator (DECISIONS 97).
    include: [
      'test/rules.test.ts',
      'test/loeschen.test.ts',
      'test/kontingent.test.ts',
    ],
    environment: 'node',
    testTimeout: 20000,
    // Der Emulator vertraegt keine parallelen Suiten auf derselben Datenbank.
    fileParallelism: false,
  },
});
