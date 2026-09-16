import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { h } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import RelatorioFrequenciaView from './RelatorioFrequenciaView.vue'
import { clienteSupabase } from '../../../tests/helpers/supabase'

const LINHA = {
  oansista_id: 'o1',
  oansista_nome: 'Ana',
  clube_nome: 'Faíscas',
  turma_nome: 'Turma 1',
  presencas: 4,
  faltas: 1,
  total_encontros: 5,
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

describe('RelatorioFrequenciaView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase()
    mocks.supabase.rpc.mockResolvedValue({ data: [LINHA], error: null })
  })

  it('lista a frequência do período com oansista, clube, turma e percentual', async () => {
    const wrapper = mount(RelatorioFrequenciaView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('Relatório de frequência')
    expect(wrapper.text()).toContain('Ana')
    expect(wrapper.text()).toContain('Faíscas')
    expect(wrapper.text()).toContain('Turma 1')
    expect(wrapper.text()).toContain('80%')
  })

  it('carrega filtrando pelo período informado nos campos', async () => {
    mount(RelatorioFrequenciaView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_frequencia_acumulada', {
      p_de: expect.any(String),
      p_ate: expect.any(String),
    })
  })
})
