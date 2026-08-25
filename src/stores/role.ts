import { computed } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore, type UserRole } from './auth'

/**
 * Helpers de RBAC (UX apenas — a segurança real é RLS no banco).
 */
export const useRoleStore = defineStore('role', () => {
  const auth = useAuthStore()

  const isDiretorGeral = computed(() => auth.profile?.role === 'diretor_geral')
  const isSecretaria = computed(() => auth.profile?.role === 'secretaria')
  const isDiretorClube = computed(() => auth.profile?.role === 'diretor_clube')
  const isLiderJogos = computed(() => auth.profile?.role === 'lider_jogos')
  const isLider = computed(() => auth.profile?.role === 'lider')

  const roleLabel = computed(() => {
    switch (auth.profile?.role) {
      case 'diretor_geral': return 'Diretor Geral'
      case 'secretaria': return 'Secretaria'
      case 'diretor_clube': return 'Diretor de Clube'
      case 'lider_jogos': return 'Líder de Jogos'
      case 'lider': return 'Líder'
      default: return ''
    }
  })

  function hasAny(roles: UserRole[]) {
    return !!auth.profile && roles.includes(auth.profile.role)
  }

  return { isDiretorGeral, isSecretaria, isDiretorClube, isLiderJogos, isLider, roleLabel, hasAny }
})
