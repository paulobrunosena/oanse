import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import JogosView from './JogosView.vue'
import { useAuthStore } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const CLUBES = [
  { id: 'c1', nome: 'Ursinhos', slug: 'ursinhos', cor: '#EF4444', ordem: 1 },
  { id: 'c2', nome: 'Faíscas', slug: 'faiscas', cor: '#EAB308', ordem: 2 },
  { id: 'c3', nome: 'Flamas', slug: 'flamas', cor: '#22C55E', ordem: 3 },
  { id: 'c4', nome: 'Tochas', slug: 'tochas', cor: '#3B82F6', ordem: 4 },
]

const EVENTOS = [
  {
    id: 'ev1',
    encontro_id: 'e1',
    nome: 'Jogos dos Flamas e Tochas',
    status: 'em_andamento',
    criado_por: 'p1',
    evento_jogos_clubes: [
      { clube_id: 'c3', clubes: { nome: 'Flamas', slug: 'flamas', cor: '#22C55E' } },
      { clube_id: 'c4', clubes: { nome: 'Tochas', slug: 'tochas', cor: '#3B82F6' } },
    ],
    evento_jogos_cores: [{ id: 'cor1', cor: 'verde', evento_jogos_cores_oansistas: [] }],
  },
  {
    id: 'ev2',
    encontro_id: 'e1',
    nome: 'Jogos dos Ursinhos e Faíscas',
    status: 'em_andamento',
    criado_por: 'p1',
    evento_jogos_clubes: [
      { clube_id: 'c1', clubes: { nome: 'Ursinhos', slug: 'ursinhos', cor: '#EF4444' } },
      { clube_id: 'c2', clubes: { nome: 'Faíscas', slug: 'faiscas', cor: '#EAB308' } },
    ],
    evento_jogos_cores: [{ id: 'cor2', cor: 'vermelho', evento_jogos_cores_oansistas: [] }],
  },
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
  EventoJogosCard: { name: 'EventoJogosCard', props: ['evento', 'oansistas'], template: '<div />' },
  RodadasJogosCard: { name: 'RodadasJogosCard', template: '<div />' },
  RankingCoresCard: { name: 'RankingCoresCard', template: '<div />' },
  Card: { name: 'Card', template: '<div><slot name="content" /></div>' },
  Button: { name: 'Button', props: ['label'], template: '<button>{{ label }}</button>' },
  Dialog: { name: 'Dialog', template: '<div />' },
  MultiSelect: { name: 'MultiSelect', template: '<div />' },
  InputText: { name: 'InputText', template: '<input />' },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
  Select: {
    name: 'Select',
    props: ['modelValue', 'options', 'optionLabel', 'optionValue'],
    emits: ['update:modelValue'],
    template: '<select :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="o in options" :key="o[optionValue]" :value="o[optionValue]">{{ o[optionLabel] }}</option></select>',
  },
}

function montar() {
  return mount(JogosView, {
    global: { stubs, plugins: [PrimeVue, ToastService] },
  })
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
      eventos_jogos: () => builder([]),
      jogos: () => builder([]),
      jogos_catalogo: () => builder([]),
    })
  })

  function perfilLiderJogos() {
    const store = useAuthStore()
    store.setUser({ sub: 'l1' })
    store.profile = { id: 'l1', nome: 'Líder de Jogos', role: 'lider_jogos', clube_id: null, ativo: true } as never
  }

  it('renderiza o título e o botão de criar evento quando não há eventos', async () => {
    perfilLiderJogos()
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Jogos do sábado')
    expect(wrapper.text()).toContain('Criar evento de jogos')
  })

  it('lista os eventos do sábado no seletor e não oferece clubes já usados', async () => {
    mocks.supabase.builderDe('eventos_jogos').data = EVENTOS
    perfilLiderJogos()
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Jogos dos Flamas e Tochas')
    expect(wrapper.text()).toContain('Jogos dos Ursinhos e Faíscas')
    expect(wrapper.text()).toContain('Todos os clubes já participaram de um evento de jogos neste sábado.')
  })

  it('só oferece no card oansistas dos clubes que participam do evento', async () => {
    mocks.supabase.builderDe('eventos_jogos').data = EVENTOS
    mocks.supabase.builderDe('oansistas').data = [
      { id: 'o1', nome: 'Criança Flamas', clube_id: 'c3', clubes: { nome: 'Flamas', cor: '#22C55E' } },
      { id: 'o2', nome: 'Criança Tochas', clube_id: 'c4', clubes: { nome: 'Tochas', cor: '#3B82F6' } },
      { id: 'o3', nome: 'Criança Ursinhos', clube_id: 'c1', clubes: { nome: 'Ursinhos', cor: '#EF4444' } },
    ]
    perfilLiderJogos()
    const wrapper = montar()
    await flushPromises()

    const card = wrapper.findComponent({ name: 'EventoJogosCard' })
    const nomes = (card.props('oansistas') as { id: string }[]).map(o => o.id).sort()
    expect(nomes).toEqual(['o1', 'o2'])
  })
})