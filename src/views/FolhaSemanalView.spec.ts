import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import FolhaSemanalView from './FolhaSemanalView.vue'
import { useAuthStore } from '@/stores/auth'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'

const OANSISTAS = [
  { id: 'o1', nome: 'Ana', turma_id: 't1', status: 'ativo' },
  { id: 'o2', nome: 'Beto', turma_id: 't1', status: 'ativo' },
]

const PRESENCAS = [
  { id: 'p1', encontro_id: 'e1', oansista_id: 'o1', presente: true },
  { id: 'p2', encontro_id: 'e1', oansista_id: 'o2', presente: false },
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
  EncontroRetroativo: { name: 'EncontroRetroativo', template: '<div />' },
  FolhaSemanalRow: { name: 'FolhaSemanalRow', template: '<div class="folha-row" />' },
  Card: { name: 'Card', template: '<div><slot name="content" /></div>' },
  Avatar: { name: 'Avatar', props: ['label'], template: '<span>{{ label }}</span>' },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
}

describe('FolhaSemanalView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      encontros: () => builder([]),
      turmas: () => builder({ id: 't1', nome: 'Turma 1' }),
      oansistas: () => builder(OANSISTAS),
      presencas: () => builder(PRESENCAS),
      itens_pontuacao: () => builder([]),
      folhas_semanais: () => builder([]),
    })
  })

  it('renderiza o cartão do ausente com fundo de superfície (padrão das outras telas)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'l1' })

    const wrapper = mount(FolhaSemanalView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.findAll('.folha-row')).toHaveLength(1)

    const ausente = wrapper.find('.border-dashed')
    expect(ausente.exists()).toBe(true)
    expect(ausente.classes()).toContain('bg-[var(--surface-card)]')
  })

  it('empilha o cabeçalho no mobile (título em uma linha; seletor e contador na linha de baixo)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'l1' })

    const wrapper = mount(FolhaSemanalView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const header = wrapper.findAll('div').find(el => el.classes().includes('sm:flex-row'))
    expect(header).toBeDefined()
    expect(header!.classes()).toContain('flex-col')
    expect(header!.classes()).toContain('sm:justify-between')
    expect(header!.find('h1')?.text()).toBe('Folha Semanal')
  })
})