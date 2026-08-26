import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import ClubesView from './ClubesView.vue'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const CLUBES = [
  { id: 'c1', nome: 'Ursinhos', slug: 'ursinhos', cor: '#EF4444', idade_min: 4, idade_max: 5, ordem: 1 },
  { id: 'c2', nome: 'Faíscas', slug: 'faiscas', cor: '#EAB308', idade_min: 6, idade_max: 7, ordem: 2 },
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
  InputNumber: { name: 'InputNumber', template: '<div />' },
  InputText: { name: 'InputText', template: '<input />' },
}

describe('ClubesView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({ clubes: () => builder(CLUBES) })
  })

  it('envolve a DataTable em um container com rolagem horizontal (overflow-x-auto)', async () => {
    const wrapper = mount(ClubesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.find('.overflow-x-auto').exists()).toBe(true)
  })

  it('colapsa os grids do dialog de edição para 1 coluna no mobile (grid-cols-1 sm:grid-cols-2)', async () => {
    const wrapper = mount(ClubesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    await wrapper.find('button[aria-label="Editar"]').trigger('click')
    await flushPromises()

    const grids = wrapper.findAll('div').filter(el => el.classes().includes('sm:grid-cols-2'))
    expect(grids).toHaveLength(2)
    for (const g of grids) {
      expect(g.classes()).toContain('grid-cols-1')
    }
  })
})