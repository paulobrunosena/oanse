import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { h } from 'vue'
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
  Column: {
    name: 'Column',
    props: ['data'],
    template: '<div><slot name="body" :data="data" /></div>',
  },
  DataTable: {
    name: 'DataTable',
    props: ['value'],
    render(this: any) {
      const colunas = this.$slots.default?.() ?? []
      const linhas = (this.value ?? []).flatMap((row: Record<string, unknown>, i: number) =>
        colunas.map((col: any, j: number) =>
          h(col.type, { ...col.props, data: row, key: `${i}-${j}` }, col.children),
        ),
      )
      return h('div', { class: 'dt' }, linhas)
    },
  },
  Dialog: { name: 'Dialog', template: '<div><slot /></div>' },
  InputColor: {
    name: 'InputColor',
    props: ['modelValue', 'format'],
    emits: ['update:modelValue'],
    template: '<div class="inputcolor"><slot /></div>',
  },
  InputColorArea: { name: 'InputColorArea', template: '<div><slot /></div>' },
  InputColorAreaBackground: { name: 'InputColorAreaBackground', template: '<div />' },
  InputColorAreaHandle: { name: 'InputColorAreaHandle', template: '<div />' },
  InputColorInput: { name: 'InputColorInput', props: ['channel'], template: '<input />' },
  InputColorSlider: { name: 'InputColorSlider', template: '<div><slot /></div>' },
  InputColorSliderHandle: { name: 'InputColorSliderHandle', template: '<div />' },
  InputColorSliderTrack: { name: 'InputColorSliderTrack', template: '<div />' },
  InputColorSwatch: { name: 'InputColorSwatch', template: '<div><slot /></div>' },
  InputColorSwatchBackground: { name: 'InputColorSwatchBackground', template: '<div />' },
  InputColorTransparencyGrid: { name: 'InputColorTransparencyGrid', template: '<div />' },
  InputNumber: { name: 'InputNumber', props: ['inputStyle'], template: '<div />' },
  InputText: { name: 'InputText', template: '<input />' },
  Popover: { name: 'Popover', template: '<div><slot /></div>' },
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

  it('aplica min-w-0 e input-style nos campos do dialog para evitar scroll horizontal', async () => {
    const wrapper = mount(ClubesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    await wrapper.find('button[aria-label="Editar"]').trigger('click')
    await flushPromises()

    expect(wrapper.find('form').classes()).toContain('min-w-0')

    const grids = wrapper.findAll('div').filter(el => el.classes().includes('sm:grid-cols-2'))
    for (const g of grids) {
      expect(g.classes()).toContain('min-w-0')
      for (const filho of g.findAll(':scope > div')) {
        expect(filho.classes()).toContain('min-w-0')
      }
    }

    const inputs = wrapper.findAllComponents({ name: 'InputNumber' })
    expect(inputs).toHaveLength(3)
    for (const input of inputs) {
      expect(input.props('inputStyle')).toEqual({ minWidth: '0', width: '100%' })
      expect(input.classes()).toContain('min-w-0')
    }
  })

  it('mostra a Ordem de exibição antes da Cor no dialog', async () => {
    const wrapper = mount(ClubesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    await wrapper.find('button[aria-label="Editar"]').trigger('click')
    await flushPromises()

    const labels = wrapper.findAll('label').map(label => label.text())
    expect(labels).toContain('Ordem de exibição')
    expect(labels).toContain('Cor')
    expect(labels.indexOf('Ordem de exibição')).toBeLessThan(labels.indexOf('Cor'))
  })

  it('usa o InputColor do PrimeVue para escolher a cor (sem input nativo type=color)', async () => {
    const wrapper = mount(ClubesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    await wrapper.find('button[aria-label="Editar"]').trigger('click')
    await flushPromises()

    expect(wrapper.find('input[type="color"]').exists()).toBe(false)

    const inputColor = wrapper.findComponent({ name: 'InputColor' })
    expect(inputColor.exists()).toBe(true)
    expect(inputColor.props('format')).toBe('hex')
    expect(inputColor.props('modelValue')).toBe('#EF4444')
  })

  it('salva a cor em #RRGGBB a partir do valor do InputColor', async () => {
    const wrapper = mount(ClubesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    await wrapper.find('button[aria-label="Editar"]').trigger('click')
    await flushPromises()

    wrapper.findComponent({ name: 'InputColor' }).vm.$emit('update:modelValue', '#22c55e')
    await flushPromises()

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    const atualizacao = mocks.supabase.builderDe('clubes').update.mock.calls[0]![0]
    expect(atualizacao).toMatchObject({ cor: '#22C55E' })
  })
})