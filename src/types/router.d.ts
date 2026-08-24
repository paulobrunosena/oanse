import type { UserRole } from '@/stores/auth'

declare module 'vue-router' {
  interface RouteMeta {
    /** Perfis autorizados na rota (guard de role — UX apenas, RLS é a barreira) */
    roles?: UserRole[]
  }
}

export {}
