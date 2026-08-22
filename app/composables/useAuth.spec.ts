import { beforeEach, describe, expect, it } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useAuth, type Profile } from './useAuth'

const PERFIL = { id: 'u1', nome: 'Tia Ana', role: 'lider', clube_id: 'c1', ativo: true } as unknown as Profile

let user = { value: { sub: 'u1' } as { sub: string } | null }
let supabase = clienteSupabase()

mockNuxtImport('useSupabaseUser', () => () => user)
mockNuxtImport('useSupabaseClient', () => () => supabase)
mockNuxtImport('navigateTo', () => (path: string) => path)

describe('useAuth', () => {
  let auth: ReturnType<typeof useAuth>

  beforeEach(async () => {
    user = { value: { sub: 'u1' } }
    supabase = clienteSupabase({ profiles: () => builder(PERFIL) })
    auth = useAuth()
    // Reseta o estado via o próprio composable (sem sessão => profile/loadedFor nulos)
    user.value = null
    await auth.loadProfile()
    user.value = { sub: 'u1' }
  })

  describe('loadProfile', () => {
    it('limpa o profile quando não há sessão', async () => {
      user.value = null
      auth.profile.value = PERFIL

      await auth.loadProfile()

      expect(auth.profile.value).toBeNull()
    })

    it('carrega o profile a partir do banco', async () => {
      await auth.loadProfile()

      expect(auth.profile.value).toEqual(PERFIL)
      expect(supabase.builderDe('profiles').eq).toHaveBeenCalledWith('id', 'u1')
      expect(supabase.builderDe('profiles').single).toHaveBeenCalledTimes(1)
    })

    it('não consulta o banco de novo quando já carregado para o mesmo usuário', async () => {
      await auth.loadProfile()
      const chamadas = supabase.builderDe('profiles').single.mock.calls.length

      await auth.loadProfile()

      expect(supabase.builderDe('profiles').single).toHaveBeenCalledTimes(chamadas)
    })

    it('deixa o profile nulo quando o banco retorna erro', async () => {
      supabase.builderDe('profiles').error = new Error('sem acesso')

      await auth.loadProfile()

      expect(auth.profile.value).toBeNull()
    })
  })

  describe('logout', () => {
    it('encerra a sessão e limpa o profile', async () => {
      await auth.loadProfile()
      auth.profile.value = PERFIL

      await auth.logout()

      expect(supabase.auth.signOut).toHaveBeenCalled()
      expect(auth.profile.value).toBeNull()
    })
  })
})
