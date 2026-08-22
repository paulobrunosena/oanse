export default defineNuxtConfig({

  modules: ['@nuxt/ui', '@nuxt/eslint', '@nuxtjs/supabase'],
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

  icon: {
    clientBundle: {
      scan: true,
    },
  },

  supabase: {
    // url/key vêm de NUXT_PUBLIC_SUPABASE_URL / NUXT_PUBLIC_SUPABASE_KEY (.env)
    redirect: false, // redirect próprio em middleware/auth.global.ts
  },
})
