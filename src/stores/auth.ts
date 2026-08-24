import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'
import type { Database } from '@/types/database.types'

export type Profile = Database['public']['Tables']['profiles']['Row']
export type UserRole = Database['public']['Enums']['user_role']

export interface AuthUser {
  sub: string
  email?: string
}

/**
 * Sessão + profile do usuário logado.
 * O profile é buscado sob demanda (guard de autenticação) e cacheado por user id.
 */
export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser | null>(null)
  const profile = ref<Profile | null>(null)
  const loadedFor = ref<string | null>(null)

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
    user.value = null
  }

  function setUser(u: AuthUser | null) {
    user.value = u
  }

  return { user, profile, loadedFor, loadProfile, logout, setUser }
})
