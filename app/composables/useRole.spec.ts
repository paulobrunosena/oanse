import { computed } from 'vue'
import { beforeEach, describe, expect, it } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { useRole } from './useRole'
import type { UserRole } from './useAuth'

let perfil: { role: UserRole } | null = null

mockNuxtImport('useAuth', () => () => ({
  profile: computed(() => perfil),
}))

describe('useRole', () => {
  beforeEach(() => {
    perfil = null
  })

  it('nenhuma flag ativa e label vazio quando não há profile', () => {
    const role = useRole()
    expect(role.isDiretorGeral.value).toBe(false)
    expect(role.isSecretaria.value).toBe(false)
    expect(role.isDiretorClube.value).toBe(false)
    expect(role.isLider.value).toBe(false)
    expect(role.roleLabel.value).toBe('')
    expect(role.hasAny(['lider', 'diretor_clube'])).toBe(false)
  })

  it('identifica diretor_geral', () => {
    perfil = { role: 'diretor_geral' }
    const role = useRole()
    expect(role.isDiretorGeral.value).toBe(true)
    expect(role.isSecretaria.value).toBe(false)
    expect(role.roleLabel.value).toBe('Diretor Geral')
  })

  it('identifica secretaria', () => {
    perfil = { role: 'secretaria' }
    const role = useRole()
    expect(role.isSecretaria.value).toBe(true)
    expect(role.roleLabel.value).toBe('Secretaria')
  })

  it('identifica diretor_clube', () => {
    perfil = { role: 'diretor_clube' }
    const role = useRole()
    expect(role.isDiretorClube.value).toBe(true)
    expect(role.roleLabel.value).toBe('Diretor de Clube')
  })

  it('identifica lider', () => {
    perfil = { role: 'lider' }
    const role = useRole()
    expect(role.isLider.value).toBe(true)
    expect(role.roleLabel.value).toBe('Líder')
  })

  it('hasAny retorna true apenas quando o role está na lista', () => {
    perfil = { role: 'lider' }
    const role = useRole()
    expect(role.hasAny(['secretaria', 'lider'])).toBe(true)
    expect(role.hasAny(['diretor_geral', 'diretor_clube'])).toBe(false)
  })
})
