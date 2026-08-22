import { defineVitestConfig } from '@nuxt/test-utils/config'

export default defineVitestConfig({
  test: {
    environment: 'nuxt',
    environmentOptions: {
      nuxt: {
        domEnvironment: 'happy-dom',
      },
    },
    globals: false,
    clearMocks: true,
    restoreMocks: true,
    include: ['app/**/*.spec.ts', 'server/**/*.spec.ts'],
    exclude: ['node_modules/**', '.nuxt/**'],
  },
})
