import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { h } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import PremiosView from './PremiosView.vue'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PREMIOS = [
  { id: 'p1', nome: 'Botão vermelho 01', tipo: 'botom', descricao: null, estoque: 5, estoque_min: 2, ativo: true },
  { id: 'p2', nome: 'Distintivo do grau', tipo: 'premio', descricao: 'Grau', estoque: 1, estoque_min: 3, ativo: true },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

const confirmacao = vi.hoisted(() => ({ require: vi.fn() }))
vi.mock('primevue/useconfirm', () => ({
  useConfirm: () => confirmacao,
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
  Dialog: {
    name: 'Dialog',
    props: ['header'],
    template: '<div class="dialog"><div class="dialog-header">{{ header }}</div><slot /></div>',
  },
  InputText: { name: 'InputText', template: '<input />' },
  InputNumber: { name: 'InputNumber', template: '<div />' },
  Select: { name: 'Select', props: ['modelValue'], template: '<div />' },
  Tag: { name: 'Tag', props: ['value'], template: '<span class="p-tag">{{ value }}</span>' },
  ToggleSwitch: { name: 'ToggleSwitch', template: '<div />' },
}

describe('PremiosView', () => {
  beforeEach(() => {
    confirmacao.require.mockReset()
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({ premios: () => builder(PREMIOS) })
  })

  async function montar() {
    const wrapper = mount(PremiosView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()
    return wrapper
  }

  it('lista os prêmios do catálogo', async () => {
    const wrapper = await montar()

    expect(wrapper.text()).toContain('Catálogo de prêmios')
    expect(wrapper.text()).toContain('Botão vermelho 01')
    expect(wrapper.text()).toContain('Distintivo do grau')
  })

  it('marca apenas os prêmios com estoque igual ou abaixo do mínimo', async () => {
    const wrapper = await montar()

    const tags = wrapper.findAll('.p-tag')
    expect(tags).toHaveLength(1)
    expect(tags[0]!.text()).toBe('mínimo')
  })

  it('abre o dialog em modo criação ao clicar em "Novo prêmio"', async () => {
    const wrapper = await montar()

    expect(wrapper.find('.dialog-header').text()).toBe('Novo prêmio')

    const botoes = wrapper.findAll('button')
    const botaoNovo = botoes.find(b => b.text().includes('Novo prêmio'))
    expect(botaoNovo).toBeTruthy()
  })

  it('abre o dialog em modo edição ao clicar no lápis', async () => {
    const wrapper = await montar()

    await wrapper.find('button[aria-label="Editar"]').trigger('click')
    await flushPromises()

    expect(wrapper.find('.dialog-header').text()).toBe('Editar prêmio')
  })
})
