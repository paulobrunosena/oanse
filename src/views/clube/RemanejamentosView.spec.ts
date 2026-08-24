import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import RemanejamentosView from './RemanejamentosView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretora Ursinhos', role: 'diretor_clube', clube_id: 'c1', ativo: true } as unknown as Profile

const TURMAS = [
  { id: 't1', nome: 'Turma 1', lider_id: 'l1', lider: { nome: 'Tia Ana' } },
  { id: 't2', nome: 'Turma 2', lider_id: 'l2', lider: { nome: 'Tio Beto' } },
]

const LIDERES = [
  { id: 'l1', nome: 'Tia Ana' },
  { id: 'l2', nome: 'Tio Beto' },
]

const mocks = vi.hoisted(() => ({ supabase: null as any, fetch: null as any }))
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
  Avatar: { name: 'Avatar', props: ['label'], template: '<div>{{ label }}</div>' },
  Button: { name: 'Button', props: ['icon', 'label', 'loading'], template: '<button :aria-label="label"><i :class="icon"></i></button>' },
  Card: { name: 'Card', template: '<div><slot name="content" /></div>' },
  Select: { name: 'Select', template: '<select />' },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
}

describe('RemanejamentosView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>(LIDERES)
        b.singleData = PERFIL
        return b
      },
      turmas: () => builder(TURMAS),
      remanejamentos_temporarios: () => builder([]),
      encontros: () => builder([]),
    })
  })

  it('renderiza os cartões de turma com fundo de superfície (padrão das outras telas)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    await store.loadProfile()

    const wrapper = mount(RemanejamentosView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const cartoes = wrapper.findAll('.rounded-lg.border')
    expect(cartoes).toHaveLength(2)
    for (const c of cartoes) {
      expect(c.classes()).toContain('bg-[var(--surface-card)]')
    }
  })
})