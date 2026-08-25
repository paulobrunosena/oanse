import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import ChamadaView from './ChamadaView.vue'
import { useAuthStore } from '@/stores/auth'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'

const OANSISTAS = [
  { id: 'o1', nome: 'Ana', turma_id: 't1', status: 'ativo' },
  { id: 'o2', nome: 'Beto', turma_id: 't1', status: 'ativo' },
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
  Card: { name: 'Card', template: '<div><slot name="content" /></div>' },
  Avatar: { name: 'Avatar', props: ['label'], template: '<span>{{ label }}</span>' },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
  ToggleSwitch: { name: 'ToggleSwitch', props: ['modelValue'], template: '<input type="checkbox" />' },
}

describe('ChamadaView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      encontros: () => builder([]),
      turmas: () => builder({ id: 't1', nome: 'Turma 1' }),
      oansistas: () => builder(OANSISTAS),
      presencas: () => builder([]),
    })
  })

  it('renderiza as linhas da chamada com fundo de superfície (padrão das outras telas)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'l1' })

    const wrapper = mount(ChamadaView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const linhas = wrapper.findAll('li')
    expect(linhas).toHaveLength(2)
    for (const l of linhas) {
      expect(l.classes()).toContain('bg-[var(--surface-card)]')
    }
  })
})