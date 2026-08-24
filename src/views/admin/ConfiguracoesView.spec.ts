import { describe, expect, it, vi, beforeEach } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import InputNumber from 'primevue/inputnumber'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

import ConfiguracoesView from './ConfiguracoesView.vue'

const ITENS = [
  { chave: 'presenca', descricao: 'Presença', pontos: 10 },
  { chave: 'uniforme', descricao: 'Uniforme', pontos: 5 },
]

const CONFIG = [
  { colocacao: 1, pontos: 100 },
  { colocacao: 2, pontos: 60 },
]

const stubs = {
  Button: { name: 'Button', template: '<button><slot /></button>' },
  Card: { name: 'Card', template: '<div><slot name="title" /><slot name="content" /></div>' },
  Column: { name: 'Column', template: '<div><slot name="body" :data="{}" /></div>' },
  DataTable: {
    name: 'DataTable',
    props: ['value'],
    template: '<div class="dt"><div v-for="(row, i) in value" :key="i"><slot /></div></div>',
  },
}

describe('ConfiguracoesView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      itens_pontuacao: () => builder(ITENS),
      jogos_pontos_config: () => builder(CONFIG),
    })
  })

  it('aplica input-style com min-width:0 nos InputNumbers para evitar scroll horizontal', async () => {
    const wrapper = mount(ConfiguracoesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const inputs = wrapper.findAll('input')
    expect(inputs.length).toBeGreaterThan(0)

    for (const input of inputs) {
      const style = input.attributes('style') ?? ''
      expect(style).toContain('min-width: 0')
      expect(style).toContain('width: 3.5rem')
    }
  })
})

describe('InputNumber horizontal', () => {
  it('aplica input-style no input interno com min-width: 0 (permite encolher sem scroll)', () => {
    const wrapper = mount(InputNumber, {
      global: { plugins: [PrimeVue] },
      props: {
        modelValue: 10,
        min: 0,
        max: 100,
        step: 5,
        showButtons: true,
        buttonLayout: 'horizontal',
        incrementButtonIcon: 'pi pi-plus',
        decrementButtonIcon: 'pi pi-minus',
        inputStyle: { minWidth: '0', width: '3.5rem', textAlign: 'center' },
        class: 'w-36',
      },
    })

    const input = wrapper.find('.p-inputnumber-input')
    expect(input.exists()).toBe(true)
    const style = input.attributes('style') ?? ''
    expect(style).toContain('min-width: 0')
    expect(style).toContain('width: 3.5rem')
  })
})
