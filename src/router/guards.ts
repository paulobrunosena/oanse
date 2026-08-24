import type { Router } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore, type UserRole } from '@/stores/auth'
import { useRoleStore } from '@/stores/role'

/**
 * Guards globais:
 * - auth: exige sessão em toda rota exceto /login e garante o profile carregado.
 * - role: restringe rotas por meta.roles (UX apenas — RLS é a barreira real).
 */
export function setupGuards(router: Router) {
  router.beforeEach(async (to) => {
    const auth = useAuthStore()

    if (!auth.user) {
      const { data } = await supabase.auth.getSession()
      auth.setUser(
        data.session?.user
          ? { sub: data.session.user.id, email: data.session.user.email ?? undefined }
          : null,
      )
    }

    if (!auth.user) {
      return to.path === '/login' ? true : { path: '/login' }
    }

    if (to.path === '/login') {
      return { path: '/' }
    }

    await auth.loadProfile()

    const role = useRoleStore()
    const roles = to.meta.roles as UserRole[] | undefined
    if (roles?.length && !role.hasAny(roles)) {
      return { path: '/' }
    }

    return true
  })
}
