import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useAuthStore, type Profile } from './auth'

const PERFIL = { id: 'u1', nome: 'Tia Ana', role: 'lider', clube_id: 'c1', ativo: true } as unknown as Profile

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('store de auth', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({ profiles: () => builder(PERFIL) })
  })

  describe('loadProfile', () => {
    it('limpa o profile quando não há sessão', async () => {
      const store = useAuthStore()
      store.profile = PERFIL

      await store.loadProfile()

      expect(store.profile).toBeNull()
    })

    it('carrega o profile a partir do banco', async () => {
      const store = useAuthStore()
      store.setUser({ sub: 'u1' })

      await store.loadProfile()

      expect(store.profile).toEqual(PERFIL)
      expect(mocks.supabase.builderDe('profiles').eq).toHaveBeenCalledWith('id', 'u1')
      expect(mocks.supabase.builderDe('profiles').single).toHaveBeenCalledTimes(1)
    })

    it('não consulta o banco de novo quando já carregado para o mesmo usuário', async () => {
      const store = useAuthStore()
      store.setUser({ sub: 'u1' })
      await store.loadProfile()
      const chamadas = mocks.supabase.builderDe('profiles').single.mock.calls.length

      await store.loadProfile()

      expect(mocks.supabase.builderDe('profiles').single).toHaveBeenCalledTimes(chamadas)
    })

    it('deixa o profile nulo quando o banco retorna erro', async () => {
      const store = useAuthStore()
      store.setUser({ sub: 'u1' })
      mocks.supabase.builderDe('profiles').error = new Error('sem acesso')

      await store.loadProfile()

      expect(store.profile).toBeNull()
    })
  })

  describe('logout', () => {
    it('encerra a sessão e limpa o profile', async () => {
      const store = useAuthStore()
      store.setUser({ sub: 'u1' })
      await store.loadProfile()

      await store.logout()

      expect(mocks.supabase.auth.signOut).toHaveBeenCalled()
      expect(store.profile).toBeNull()
      expect(store.user).toBeNull()
    })
  })

  describe('setUser', () => {
    it('atualiza o usuário da sessão', () => {
      const store = useAuthStore()
      store.setUser({ sub: 'u9' })
      expect(store.user?.sub).toBe('u9')
    })
  })
})
