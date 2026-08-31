import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['test/rules.test.ts', 'test/loeschen.test.ts'],
    environment: 'node',
    testTimeout: 20000,
    // Der Emulator vertraegt keine parallelen Suiten auf derselben Datenbank.
    fileParallelism: false,
  },
});
