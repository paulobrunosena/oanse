import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import JogosView from './JogosView.vue'
import { useAuthStore } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const CLUBES = [
  { id: 'c1', nome: 'Flamas', slug: 'flamas', cor: '#22C55E', ordem: 3 },
  { id: 'c2', nome: 'Tochas', slug: 'tochas', cor: '#3B82F6', ordem: 4 },
]

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
  EventoJogosCard: { name: 'EventoJogosCard', template: '<div />' },
  RodadasJogosCard: { name: 'RodadasJogosCard', template: '<div />' },
  RankingCoresCard: { name: 'RankingCoresCard', template: '<div />' },
  Card: { name: 'Card', template: '<div><slot name="content" /></div>' },
  Button: { name: 'Button', props: ['label'], template: '<button>{{ label }}</button>' },
  Dialog: { name: 'Dialog', template: '<div />' },
  MultiSelect: { name: 'MultiSelect', template: '<div />' },
  InputText: { name: 'InputText', template: '<input />' },
}

describe('JogosView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      clubes: () => builder(CLUBES),
      jogos_pontos_config: () => builder([]),
      oansistas: () => builder([]),
      encontros: () => builder([{ id: 'e1', data: '2026-08-24', ativo: true }]),
      dias_sem_oanse: () => builder([]),
      eventos_jogos: () => builder(null),
      jogos: () => builder([]),
      jogos_catalogo: () => builder([]),
    })
  })

  it('renderiza o título e o botão de criar evento quando não há evento', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'l1' })
    store.profile = { id: 'l1', nome: 'Líder de Jogos', role: 'lider_jogos', clube_id: null, ativo: true } as never

    const wrapper = mount(JogosView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('Jogos do sábado')
    expect(wrapper.text()).toContain('Criar evento de jogos')
  })
})