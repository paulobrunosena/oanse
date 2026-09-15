import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { h } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import RelatorioPremiacoesView from './RelatorioPremiacoesView.vue'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const LINHA = {
  id: 'fp1',
  data_recebimento: '2026-09-10',
  oansistas: { nome: 'Ana', clubes: { nome: 'Faíscas' } },
  folha_blocos: { premio_nome: 'Botão vermelho 01' },
}

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

const stubs = {
  Button: {
    name: 'Button',
    props: ['label'],
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
  InputText: { name: 'InputText', template: '<input />' },
}

describe('RelatorioPremiacoesView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({ folha_premio_progresso: () => builder([LINHA]) })
  })

  it('lista as premiações do período com oansista, prêmio e clube', async () => {
    const wrapper = mount(RelatorioPremiacoesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('Relatório de premiações')
    expect(wrapper.text()).toContain('Ana')
    expect(wrapper.text()).toContain('Botão vermelho 01')
    expect(wrapper.text()).toContain('Faíscas')
  })

  it('carrega filtrando pelo período informado nos campos', async () => {
    mount(RelatorioPremiacoesView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const b = mocks.supabase.builderDe('folha_premio_progresso')
    expect(b.gte).toHaveBeenCalled()
    expect(b.lte).toHaveBeenCalled()
  })
})
