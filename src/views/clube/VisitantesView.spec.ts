import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { h } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import VisitantesView from './VisitantesView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretora Flamas', role: 'diretor_clube', clube_id: 'c1', ativo: true } as unknown as Profile

const VISITANTES = [
  { id: 'v1', nome: 'Ana', data_nascimento: '2017-03-10', clube_id: 'c1', indicado_por: null, oansista_origem_id: null, responsavel: 'Mãe', contato: '8199', status: 'em_visitas', data_cadastro: '2026-09-01', created_at: '2026-09-01T00:00:00Z', updated_at: '2026-09-01T00:00:00Z' },
  { id: 'v2', nome: 'Bia', data_nascimento: '2016-05-02', clube_id: 'c1', indicado_por: null, oansista_origem_id: 'o9', responsavel: null, contato: null, status: 'prova_ingresso', data_cadastro: '2026-09-01', created_at: '2026-09-01T00:00:00Z', updated_at: '2026-09-01T00:00:00Z' },
  { id: 'v3', nome: 'Clara', data_nascimento: '2015-02-20', clube_id: 'c1', indicado_por: null, oansista_origem_id: null, responsavel: null, contato: null, status: 'matriculado', data_cadastro: '2026-09-01', created_at: '2026-09-01T00:00:00Z', updated_at: '2026-09-01T00:00:00Z' },
]

const CLUBES = [
  { id: 'c1', nome: 'Flamas', qtd_licoes: 8, idade_min: 9, idade_max: 10 },
  { id: 'c2', nome: 'Faíscas', qtd_licoes: 6, idade_min: 6, idade_max: 8 },
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
    props: ['label', 'icon', 'disabled', 'ariaLabel'],
    emits: ['click'],
    template: '<button :disabled="disabled" :aria-label="ariaLabel" @click="$emit(\'click\')"><slot />{{ label }}</button>',
  },
  Checkbox: {
    name: 'Checkbox',
    props: ['modelValue'],
    emits: ['update:modelValue'],
    template: '<input type="checkbox" class="cb" :checked="modelValue" @change="$emit(\'update:modelValue\', $event.target.checked)" />',
  },
  Column: {
    name: 'Column',
    props: ['data', 'field'],
    template: '<div><slot name="body" :data="data" />{{ data && field ? data[field] : "" }}</div>',
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
    props: ['visible'],
    template: '<div class="dialog" v-if="visible"><slot /><slot name="footer" /></div>',
  },
  InputText: {
    name: 'InputText',
    props: ['modelValue', 'type'],
    emits: ['update:modelValue'],
    template: '<input :type="type" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
  Select: {
    name: 'Select',
    props: ['options', 'optionLabel', 'optionValue', 'disabled'],
    template: '<select class="sel" :disabled="disabled"><option v-for="o in options" :key="o[optionValue]" :value="o[optionValue]">{{ o[optionLabel] }}</option></select>',
  },
  Tag: { name: 'Tag', props: ['value', 'severity'], template: '<span class="tag">{{ value }}</span>' },
  Tabs: { name: 'Tabs', template: '<div><slot /></div>' },
  TabList: { name: 'TabList', template: '<div><slot /></div>' },
  Tab: { name: 'Tab', props: ['value'], template: '<button><slot /></button>' },
  TabPanels: { name: 'TabPanels', template: '<div><slot /></div>' },
  TabPanel: { name: 'TabPanel', props: ['value'], template: '<div><slot /></div>' },
  VisitaTracker: { name: 'VisitaTracker', template: '<div class="visita" />' },
  ProvaIngressoCard: {
    name: 'ProvaIngressoCard',
    props: ['totalLicoes', 'licoes'],
    template: '<div class="prova" :data-total="totalLicoes" />',
  },
}

function nascimentoComIdade(anos: number): string {
  const d = new Date()
  d.setFullYear(d.getFullYear() - anos)
  d.setDate(d.getDate() - 1)
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const dia = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${m}-${dia}`
}

async function montar() {
  const store = useAuthStore()
  store.setUser({ sub: 'u1' })
  await store.loadProfile()

  const wrapper = mount(VisitantesView, {
    global: { stubs, plugins: [PrimeVue, ToastService] },
  })
  await flushPromises()
  return wrapper
}

describe('VisitantesView', () => {
  beforeEach(() => {
    confirmacao.require.mockReset()
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>([])
        b.singleData = PERFIL
        return b
      },
      visitantes: () => builder(VISITANTES),
      visitas: () => builder([]),
      prova_ingresso_licoes: () => builder([]),
      oansistas: () => builder([]),
      turmas: () => builder([]),
      clubes: () => builder(CLUBES),
    })
  })

  it('esconde visitantes matriculados por padrão e mostra ao ativar o toggle', async () => {
    const wrapper = await montar()

    expect(wrapper.text()).toContain('Ana')
    expect(wrapper.text()).toContain('Bia')
    expect(wrapper.text()).not.toContain('Clara')

    await wrapper.find('input.cb').setValue(true)
    await flushPromises()

    expect(wrapper.text()).toContain('Clara')
  })

  it('não oferece "matriculado" no seletor de situação', async () => {
    const wrapper = await montar()

    const botaoNovo = wrapper.findAll('button').find(b => b.text() === 'Novo visitante')
    await botaoNovo!.trigger('click')
    await flushPromises()

    const opcoes = wrapper.findAll('select.sel option').map(o => o.text())
    expect(opcoes).toContain('Em visitas')
    expect(opcoes).toContain('Prova de ingresso')
    expect(opcoes).toContain('Desistente')
    expect(opcoes).not.toContain('Matriculado')
  })

  it('marca o visitante vindo de transferência de clube', async () => {
    const wrapper = await montar()

    const tags = wrapper.findAll('span.tag').map(t => t.text())
    expect(tags).toContain('Transferência')
  })

  it('desabilita o seletor de situação ao editar um visitante matriculado', async () => {
    const wrapper = await montar()

    await wrapper.find('input.cb').setValue(true)
    await flushPromises()

    const olhos = wrapper.findAll('button[aria-label="Ver detalhes"]')
    await olhos[2]!.trigger('click')
    await flushPromises()

    const editar = wrapper.findAll('button[aria-label="Editar"]')[0]
    await editar!.trigger('click')
    await flushPromises()

    const selects = wrapper.findAll('select.sel')
    expect(selects[1]!.attributes('disabled')).toBeDefined()
  })

  it('mantém o seletor de situação habilitado ao editar um visitante em visitas', async () => {
    const wrapper = await montar()

    const olhos = wrapper.findAll('button[aria-label="Ver detalhes"]')
    await olhos[0]!.trigger('click')
    await flushPromises()

    const editar = wrapper.findAll('button[aria-label="Editar"]')[0]
    await editar!.trigger('click')
    await flushPromises()

    const selects = wrapper.findAll('select.sel')
    expect(selects[1]!.attributes('disabled')).toBeUndefined()
  })

  it('mostra aviso e bloqueia o salvamento de criança nascida neste ano', async () => {
    const wrapper = await montar()

    const botaoNovo = wrapper.findAll('button').find(b => b.text() === 'Novo visitante')
    await botaoNovo!.trigger('click')
    await flushPromises()

    await wrapper.find('form input').setValue('Ana')
    await wrapper.find('form input[type="date"]').setValue(`${new Date().getFullYear()}-01-01`)
    await flushPromises()

    expect(wrapper.text()).toContain('nasceu neste ano')

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(confirmacao.require).not.toHaveBeenCalled()
    expect(mocks.supabase.builderDe('visitantes').insert).not.toHaveBeenCalled()
  })

  it('pede confirmação quando a idade corresponde a outro clube', async () => {
    const wrapper = await montar()

    const botaoNovo = wrapper.findAll('button').find(b => b.text() === 'Novo visitante')
    await botaoNovo!.trigger('click')
    await flushPromises()

    await wrapper.find('form input').setValue('Ana')
    await wrapper.find('form input[type="date"]').setValue(nascimentoComIdade(7))
    await flushPromises()

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(confirmacao.require).toHaveBeenCalledTimes(1)
    const cfg = confirmacao.require.mock.calls[0]![0]!
    expect(cfg.message).toContain('Faíscas')
    expect(cfg.message).toContain('Flamas')

    await cfg.accept()
    await flushPromises()
    expect(mocks.supabase.builderDe('visitantes').insert).toHaveBeenCalled()
  })
})
