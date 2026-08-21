import type { UserRole } from '~/composables/useAuth'

/**
 * RBAC de rota: use com `definePageMeta({ roles: [...] })`.
 * UX apenas — a segurança real é RLS no banco.
 */
export default defineNuxtRouteMiddleware((to) => {
  const roles = to.meta.roles as UserRole[] | undefined
  if (!roles || roles.length === 0) return

  const { hasAny } = useRole()
  if (!hasAny(roles)) {
    throw createError({
      statusCode: 403,
      statusMessage: 'Você não tem permissão para acessar esta página.',
    })
  }
})
