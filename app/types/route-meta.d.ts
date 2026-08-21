import type { UserRole } from '~/composables/useAuth'

declare module 'vue-router' {
  interface RouteMeta {
    /** Perfis autorizados na rota (middleware/role.ts) */
    roles?: UserRole[]
  }
}

export {}
