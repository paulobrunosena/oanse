import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import Components from 'unplugin-vue-components/vite'
import { PrimeVueResolver } from '@primevue/auto-import-resolver'

export default defineConfig({
  plugins: [
    vue(),
    tailwindcss(),
    Components({
      resolvers: [PrimeVueResolver()],
      dirs: [],
      dts: 'src/components.d.ts',
    }),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    // Pré-transforma as telas/componentes no start do dev server para o Vite
    // descobrir (e pré-otimizar) as deps do PrimeVue que o unplugin-vue-components
    // injeta no transform. Sem isso, a primeira navegação para cada tela pode
    // disparar "optimized dependencies changed. reloading" no meio do clique —
    // o reload cancela a navegação e a tela só abre no 2º clique.
    warmup: {
      clientFiles: [
        './src/views/**/*.vue',
        './src/layouts/**/*.vue',
        './src/components/**/*.vue',
      ],
    },
    proxy: {
      // Backend local (server/index.ts, h3) — ver server/README.md
      '/api': 'http://localhost:8787',
    },
  },
})
