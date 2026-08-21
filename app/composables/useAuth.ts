import type { Database } from '~/types/database.types'

export type Profile = Database['public']['Tables']['profiles']['Row']
export type UserRole = Database['public']['Enums']['user_role']

/**
 * Sessão + profile do usuário logado.
 * O profile é buscado sob demanda (middleware auth) e cacheado por user id.
 */
export function useAuth() {
  const user = useSupabaseUser()
  const supabase = useSupabaseClient<Database>()
  const profile = useState<Profile | null>('auth:profile', () => null)
  const loadedFor = useState<string | null>('auth:profile-loaded-for', () => null)

  async function loadProfile() {
    const userId = user.value?.sub
    if (!userId) {
      profile.value = null
      loadedFor.value = null
      return
    }
    if (loadedFor.value === userId && profile.value) return

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()

    profile.value = error ? null : data
    loadedFor.value = userId
  }

  async function logout() {
    await supabase.auth.signOut()
    profile.value = null
    loadedFor.value = null
    await navigateTo('/login')
  }

  return { user, profile, loadProfile, logout }
}
