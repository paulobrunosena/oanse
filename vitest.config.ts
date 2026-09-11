import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import Components from 'unplugin-vue-components/vite'
import { PrimeVueResolver } from '@primevue/auto-import-resolver'

export default defineConfig({
  plugins: [
    vue(),
    Components({
      resolvers: [PrimeVueResolver()],
      dirs: [],
      dts: false,
    }),
  ],
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
