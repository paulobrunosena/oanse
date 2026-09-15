import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { h } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import PendenciasView from './PendenciasView.vue'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const LINHA = {
  id: 'pp1',
  status: 'pendente',
  data_geracao: '2026-09-15T10:00:00Z',
  data_entrega: null,
  oansistas: { nome: 'Ana' },
  premios: { nome: 'Botão vermelho 01', tipo: 'botom' },
  clubes: { nome: 'Faíscas' },
}

const CLUBES = [
  { id: 'c1', nome: 'Ursinhos' },
  { id: 'c2', nome: 'Faíscas' },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

const confirmacao = vi.hoisted(() => ({ require: vi.fn() }))
vi.mock('primevue/useconfirm', () => ({
  useConfirm: () => confirmacao,
}))

const api = vi.hoisted(() => ({ apiFetch: vi.fn(() => Promise.resolve({})) }))
vi.mock('@/lib/api', () => ({
  apiFetch: api.apiFetch,
}))

const alerta = vi.hoisted(() => ({ tocarSomAlerta: vi.fn() }))
vi.mock('@/utils/alerta', () => ({
  tocarSomAlerta: alerta.tocarSomAlerta,
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
  Select: { name: 'Select', props: ['modelValue'], template: '<div />' },
  Tag: { name: 'Tag', props: ['value'], template: '<span class="p-tag">{{ value }}</span>' },
}

describe('PendenciasView', () => {
  const canal = {
    on: vi.fn((_event: string, _filter: object, _cb: (payload: { eventType: string, new: Record<string, unknown> }) => void) => canal),
    subscribe: vi.fn(() => canal),
  }

  beforeEach(() => {
    confirmacao.require.mockReset()
    api.apiFetch.mockReset()
    api.apiFetch.mockResolvedValue({})
    alerta.tocarSomAlerta.mockClear()
    canal.on.mockClear()
    canal.subscribe.mockClear()
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      premios_pendentes: () => builder([LINHA]),
      clubes: () => builder(CLUBES),
    })
    mocks.supabase.channel = vi.fn(() => canal)
    mocks.supabase.removeChannel = vi.fn(() => Promise.resolve())
  })

  async function montar() {
    const wrapper = mount(PendenciasView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()
    return wrapper
  }

  function handlerRealtime() {
    return canal.on.mock.calls[0]![2]
  }

  it('lista as pendências com oansista, prêmio e clube', async () => {
    const wrapper = await montar()

    expect(wrapper.text()).toContain('Pendências de premiação')
    expect(wrapper.text()).toContain('Ana')
    expect(wrapper.text()).toContain('Botão vermelho 01')
    expect(wrapper.text()).toContain('Faíscas')
  })

  it('carrega apenas as pendentes por padrão', async () => {
    await montar()

    expect(mocks.supabase.builderDe('premios_pendentes').eq).toHaveBeenCalledWith('status', 'pendente')
  })

  it('carrega os clubes para o filtro', async () => {
    await montar()

    expect(mocks.supabase.from).toHaveBeenCalledWith('clubes')
  })

  it('notifica (som) quando chega uma nova pendência', async () => {
    await montar()

    handlerRealtime()({ eventType: 'INSERT', new: { status: 'pendente' } })
    await flushPromises()

    expect(alerta.tocarSomAlerta).toHaveBeenCalledTimes(1)
  })

  it('não notifica em atualizações de status', async () => {
    await montar()

    handlerRealtime()({ eventType: 'UPDATE', new: { status: 'entregue' } })
    await flushPromises()

    expect(alerta.tocarSomAlerta).not.toHaveBeenCalled()
  })

  it('entrega o prêmio via API ao confirmar', async () => {
    const wrapper = await montar()

    await wrapper.find('button').trigger('click')
    await flushPromises()

    const config = confirmacao.require.mock.calls[0]![0] as { accept: () => Promise<void> }
    await config.accept()
    await flushPromises()

    expect(api.apiFetch).toHaveBeenCalledWith('/api/premios/pp1/entregar', { method: 'POST' })
  })
})
