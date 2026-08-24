import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useAuthStore, type Profile } from './auth'
import { useRoleStore } from './role'

vi.mock('@/lib/supabase', () => ({
  get supabase() { return { from: vi.fn(), auth: {} } },
}))

function perfil(role: Profile['role']): Profile {
  return { id: 'u1', nome: 'X', role, clube_id: null, ativo: true } as unknown as Profile
}

describe('store de role', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('nenhuma flag ativa e label vazio quando não há profile', () => {
    const role = useRoleStore()
    expect(role.isDiretorGeral).toBe(false)
    expect(role.isSecretaria).toBe(false)
    expect(role.isDiretorClube).toBe(false)
    expect(role.isLider).toBe(false)
    expect(role.roleLabel).toBe('')
    expect(role.hasAny(['lider', 'diretor_clube'])).toBe(false)
  })

  it('identifica diretor_geral', () => {
    useAuthStore().profile = perfil('diretor_geral')
    const role = useRoleStore()
    expect(role.isDiretorGeral).toBe(true)
    expect(role.isSecretaria).toBe(false)
    expect(role.roleLabel).toBe('Diretor Geral')
  })

  it('identifica secretaria', () => {
    useAuthStore().profile = perfil('secretaria')
    const role = useRoleStore()
    expect(role.isSecretaria).toBe(true)
    expect(role.roleLabel).toBe('Secretaria')
  })

  it('identifica diretor_clube', () => {
    useAuthStore().profile = perfil('diretor_clube')
    const role = useRoleStore()
    expect(role.isDiretorClube).toBe(true)
    expect(role.roleLabel).toBe('Diretor de Clube')
  })

  it('identifica lider', () => {
    useAuthStore().profile = perfil('lider')
    const role = useRoleStore()
    expect(role.isLider).toBe(true)
    expect(role.roleLabel).toBe('Líder')
  })

  it('hasAny retorna true apenas quando o role está na lista', () => {
    useAuthStore().profile = perfil('lider')
    const role = useRoleStore()
    expect(role.hasAny(['secretaria', 'lider'])).toBe(true)
    expect(role.hasAny(['diretor_geral', 'diretor_clube'])).toBe(false)
  })
})
