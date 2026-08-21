import type { UserRole } from './useAuth'

/**
 * Helpers de RBAC (UX apenas — a segurança real é RLS no banco).
 */
export function useRole() {
  const { profile } = useAuth()

  const isDiretorGeral = computed(() => profile.value?.role === 'diretor_geral')
  const isSecretaria = computed(() => profile.value?.role === 'secretaria')
  const isDiretorClube = computed(() => profile.value?.role === 'diretor_clube')
  const isLider = computed(() => profile.value?.role === 'lider')

  const roleLabel = computed(() => {
    switch (profile.value?.role) {
      case 'diretor_geral': return 'Diretor Geral'
      case 'secretaria': return 'Secretaria'
      case 'diretor_clube': return 'Diretor de Clube'
      case 'lider': return 'Líder'
      default: return ''
    }
  })

  function hasAny(roles: UserRole[]) {
    return !!profile.value && roles.includes(profile.value.role)
  }

  return { isDiretorGeral, isSecretaria, isDiretorClube, isLider, roleLabel, hasAny }
}
