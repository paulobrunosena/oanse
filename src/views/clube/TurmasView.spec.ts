import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import TurmasView from './TurmasView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretora Ursinhos', role: 'diretor_clube', clube_id: 'c1', ativo: true } as unknown as Profile

const TURMAS = [
  { id: 't1', nome: 'Turma 1', lider_id: 'l1', clube_id: 'c1', ativo: true, lider: { nome: 'Tia Ana' }, oansistas: [{ count: 8 }] },
  { id: 't2', nome: 'Turma 2', lider_id: 'l2', clube_id: 'c1', ativo: true, lider: { nome: 'Tio Beto' }, oansistas: [{ count: 6 }] },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

const stubs = {
  Button: {
    name: 'Button',
    props: ['label'],
    emits: ['click'],
    template: '<button @click="$emit(\'click\')">{{ label }}</button>',
  },
  Column: { name: 'Column', template: '<div><slot name="body" :data="{}" /></div>' },
  DataTable: {
    name: 'DataTable',
    props: ['value'],
    template: '<div class="dt"><div v-for="(row, i) in value" :key="i"><slot /></div></div>',
  },
  Dialog: { name: 'Dialog', template: '<div><slot /></div>' },
  InputText: { name: 'InputText', template: '<input />' },
  Select: { name: 'Select', template: '<div />' },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
}

describe('TurmasView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>([])
        b.singleData = PERFIL
        return b
      },
      turmas: () => builder(TURMAS),
    })
  })

  it('envolve a DataTable em um container com rolagem horizontal (overflow-x-auto)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    await store.loadProfile()

    const wrapper = mount(TurmasView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.find('.overflow-x-auto').exists()).toBe(true)
  })

  it('permite quebra de linha no cabeçalho (flex-wrap) para não estourar no mobile', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    await store.loadProfile()

    const wrapper = mount(TurmasView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const header = wrapper.findAll('div').find(el => el.classes().includes('flex-wrap'))
    expect(header).toBeDefined()
    expect(header!.classes()).toContain('justify-between')
    expect(header!.find('h1')?.text()).toBe('Turmas')
  })
})