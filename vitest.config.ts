import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  test: {
    environment: 'happy-dom',
    globals: false,
    clearMocks: true,
    restoreMocks: true,
    include: ['src/**/*.spec.ts', 'server/**/*.spec.ts', 'tests/**/*.spec.ts'],
    exclude: ['node_modules/**', 'dist/**'],
  },
})
