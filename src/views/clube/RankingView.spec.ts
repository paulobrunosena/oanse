import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import RankingView from './RankingView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretor Geral', role: 'diretor_geral', clube_id: null, ativo: true } as unknown as Profile

const CLUBES = [{ id: 'c1', nome: 'Ursinhos', ordem: 1 }]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

vi.mock('@/lib/api', () => ({
  apiFetch: async () => ({
    encontro: { id: 'e1', data: '2026-08-24', ativo: true },
    semAtividade: false,
    motivo: null,
    data: '2026-08-24',
  }),
}))

const stubs = {
  EncontroSeletor: { name: 'EncontroSeletor', template: '<div />' },
  Card: { name: 'Card', template: '<div><slot name="content" /></div>' },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
}

describe('RankingView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>([])
        b.singleData = PERFIL
        return b
      },
      clubes: () => builder(CLUBES),
      encontros: () => builder([]),
      dias_sem_oanse: () => builder([]),
    })
  })

  it('empilha o cabeçalho no mobile (título em uma linha; seletor na linha de baixo)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    await store.loadProfile()

    const wrapper = mount(RankingView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const header = wrapper.findAll('div').find(el => el.classes().includes('sm:flex-row'))
    expect(header).toBeDefined()
    expect(header!.classes()).toContain('flex-col')
    expect(header!.classes()).toContain('sm:justify-between')
    expect(header!.find('h1')?.text()).toBe('Ranking do sábado')
  })
})