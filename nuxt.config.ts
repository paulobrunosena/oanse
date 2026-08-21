export default defineNuxtConfig({

  modules: ['@nuxt/ui', '@nuxt/eslint'],
  devtools: { enabled: true },

  app: {
    head: {
      title: 'Oanse — Ministério Infantil',
      htmlAttrs: { lang: 'pt-BR' },
    },
  },

  css: ['~/assets/css/main.css'],
  compatibilityDate: '2026-08-01',

  eslint: {
    config: {
      stylistic: true,
    },
  },
})
