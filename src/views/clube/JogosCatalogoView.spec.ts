import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import JogosCatalogoView from './JogosCatalogoView.vue'
import { useAuthStore } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const CLUBES = [
  { id: 'c1', nome: 'Flamas', slug: 'flamas', ordem: 3 },
  { id: 'c2', nome: 'Tochas', slug: 'tochas', ordem: 4 },
]

const CATALOGO = [
  { id: 'a', clube_id: 'c1', nome: 'maratona' },
  { id: 'b', clube_id: 'c2', nome: 'bonanza' },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

const stubs = {
  Card: { name: 'Card', template: '<div><slot name="title" /><slot name="content" /></div>' },
  Button: {
    name: 'Button',
    props: ['label'],
    template: '<button @click="$emit(\'click\')">{{ label }}</button>',
  },
  InputText: {
    name: 'InputText',
    props: ['modelValue'],
    emits: ['update:modelValue'],
    template: '<input :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
  Select: { name: 'Select', props: ['modelValue'], template: '<div />' },
}

describe('JogosCatalogoView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      clubes: () => builder(CLUBES),
      jogos_catalogo: () => builder(CATALOGO),
    })
  })

  it('lista os jogos do clube selecionado', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'l1' })
    store.profile = { id: 'l1', nome: 'Líder de Jogos', role: 'lider_jogos', clube_id: null, ativo: true } as never

    const wrapper = mount(JogosCatalogoView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('Catálogo de jogos')
    expect(wrapper.text()).toContain('maratona')
  })

  it('diretor de clube vê apenas o próprio clube', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'l1' })
    store.profile = { id: 'l1', nome: 'Diretor', role: 'diretor_clube', clube_id: 'c2', ativo: true } as never

    const wrapper = mount(JogosCatalogoView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('bonanza')
    expect(wrapper.text()).not.toContain('maratona')
  })
})