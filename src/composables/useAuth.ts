import { storeToRefs } from 'pinia'
import { useAuthStore, type AuthUser, type Profile, type UserRole } from '@/stores/auth'

export type { AuthUser, Profile, UserRole }

/**
 * Sessão + profile do usuário logado (fachada sobre a store de auth).
 */
export function useAuth() {
  const store = useAuthStore()
  const { user, profile } = storeToRefs(store)

  async function logout() {
    await store.logout()
    const { default: router } = await import('@/router')
    await router.push('/login')
  }

  return { user, profile, loadProfile: store.loadProfile, logout }
}
