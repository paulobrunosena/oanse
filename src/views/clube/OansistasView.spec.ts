import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { h } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import OansistasView from './OansistasView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretora Ursinhos', role: 'diretor_clube', clube_id: 'c1', ativo: true } as unknown as Profile

function nascimentoComIdade(anos: number): string {
  const d = new Date()
  d.setFullYear(d.getFullYear() - anos)
  d.setDate(d.getDate() - 1)
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const dia = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${m}-${dia}`
}

const OANSISTAS = [
  { id: 'o1', nome: 'Ana', data_nascimento: nascimentoComIdade(8), turma_id: 't1', clube_id: 'c1', status: 'ativo', turma: { nome: 'Turma 1' } },
  { id: 'o2', nome: 'Beto', data_nascimento: nascimentoComIdade(9), turma_id: null, clube_id: 'c1', status: 'ativo', turma: null },
  { id: 'o3', nome: 'Caio', data_nascimento: nascimentoComIdade(6), turma_id: null, clube_id: 'c1', status: 'transferido', turma: null },
]

const TURMAS = [
  { id: 't1', nome: 'Turma 1', ativo: true, clube_id: 'c1' },
  { id: 't2', nome: 'Turma 2', ativo: true, clube_id: 'c1' },
]

const CLUBES = [
  { id: 'c1', nome: 'Ursinhos', idade_min: 4, idade_max: 5 },
  { id: 'c2', nome: 'Flamas', idade_min: 9, idade_max: 10 },
  { id: 'c3', nome: 'Faíscas', idade_min: 6, idade_max: 8 },
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
    props: ['label', 'icon', 'ariaLabel', 'loading', 'disabled'],
    emits: ['click'],
    template: '<button :aria-label="ariaLabel" :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
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
    props: ['options', 'optionLabel', 'optionValue', 'modelValue'],
    emits: ['update:modelValue'],
    template: '<select class="sel" :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="o in options" :key="o[optionValue]" :value="o[optionValue]">{{ o[optionLabel] }}</option></select>',
  },
  Tag: { name: 'Tag', props: ['value', 'severity'], template: '<span class="tag">{{ value }}</span>' },
  Textarea: { name: 'Textarea', template: '<textarea />' },
}

async function montarComPerfil() {
  const store = useAuthStore()
  store.setUser({ sub: 'u1' })
  await store.loadProfile()

  const wrapper = mount(OansistasView, {
    global: { stubs, plugins: [PrimeVue, ToastService] },
  })
  await flushPromises()
  return wrapper
}

describe('OansistasView', () => {
  beforeEach(() => {
    confirmacao.require.mockReset()
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>([])
        b.singleData = PERFIL
        return b
      },
      oansistas: () => builder(OANSISTAS),
      turmas: () => builder(TURMAS),
      clubes: () => builder(CLUBES),
    })
  })

  it('envolve a DataTable em um container com rolagem horizontal (overflow-x-auto)', async () => {
    const wrapper = await montarComPerfil()
    expect(wrapper.find('.overflow-x-auto').exists()).toBe(true)
  })

  it('permite quebra de linha no cabeçalho (flex-wrap) para não estourar no mobile', async () => {
    const wrapper = await montarComPerfil()

    const header = wrapper.findAll('div').find(el => el.classes().includes('flex-wrap'))
    expect(header).toBeDefined()
    expect(header!.classes()).toContain('justify-between')
    expect(header!.find('h1')?.text()).toBe('Oansistas')
  })

  it('colapsa os grids do formulário para 1 coluna no mobile (grid-cols-1 sm:grid-cols-2)', async () => {
    const wrapper = await montarComPerfil()

    const botaoNovo = wrapper.findAll('button').find(b => b.text() === 'Novo')
    await botaoNovo!.trigger('click')
    await flushPromises()

    const grids = wrapper.findAll('div').filter(el => el.classes().includes('sm:grid-cols-2'))
    expect(grids).toHaveLength(2)
    for (const g of grids) {
      expect(g.classes()).toContain('grid-cols-1')
    }
  })

  it('oculta inativos/transferidos por padrão e mostra ao ativar o toggle', async () => {
    const wrapper = await montarComPerfil()

    expect(wrapper.text()).toContain('Ana')
    expect(wrapper.text()).not.toContain('Caio')

    await wrapper.find('input.cb').setValue(true)
    await flushPromises()

    expect(wrapper.text()).toContain('Caio')
  })

  it('mostra o rótulo "Transferido" para oansista em processo de transferência', async () => {
    const wrapper = await montarComPerfil()
    await wrapper.find('input.cb').setValue(true)
    await flushPromises()

    const tags = wrapper.findAll('span.tag').map(t => t.text())
    expect(tags).toContain('Transferido')
  })

  it('chama a RPC de transferência de clube ao confirmar o dialog', async () => {
    const wrapper = await montarComPerfil()

    const botaoTransferir = wrapper.findAll('button').find(b => b.attributes('aria-label') === 'Mudar de clube')
    await botaoTransferir!.trigger('click')
    await flushPromises()

    await wrapper.find('select.sel').setValue('c3')
    await flushPromises()

    const confirmar = wrapper.findAll('button').find(b => b.text() === 'Transferir')
    await confirmar!.trigger('click')
    await flushPromises()

    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_transferir_clube', {
      p_oansista_id: 'o1',
      p_clube_destino_id: 'c3',
      p_motivo: undefined,
    })
  })

  it('pede confirmação ao transferir para clube de idade incompatível', async () => {
    const wrapper = await montarComPerfil()

    const botaoTransferir = wrapper.findAll('button').find(b => b.attributes('aria-label') === 'Mudar de clube')
    await botaoTransferir!.trigger('click')
    await flushPromises()

    await wrapper.find('select.sel').setValue('c2')
    await flushPromises()

    const confirmar = wrapper.findAll('button').find(b => b.text() === 'Transferir')
    await confirmar!.trigger('click')
    await flushPromises()

    expect(confirmacao.require).toHaveBeenCalledTimes(1)
    const cfg = confirmacao.require.mock.calls[0]![0]!
    expect(cfg.message).toContain('Faíscas')
    expect(cfg.message).toContain('Flamas')
    expect(mocks.supabase.rpc).not.toHaveBeenCalled()

    await cfg.accept()
    await flushPromises()
    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_transferir_clube', {
      p_oansista_id: 'o1',
      p_clube_destino_id: 'c2',
      p_motivo: undefined,
    })
  })

  it('mostra o botão Progredir de clube e transfere ao confirmar', async () => {
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>([])
        b.singleData = PERFIL
        return b
      },
      oansistas: () => builder([
        { id: 'o1', nome: 'Ana', data_nascimento: nascimentoComIdade(8), turma_id: null, clube_id: 'c1', status: 'ativo', turma: null },
      ]),
      turmas: () => builder([]),
      clubes: () => builder(CLUBES),
    })
    const wrapper = await montarComPerfil()

    const btn = wrapper.findAll('button').find(b => b.attributes('aria-label') === 'Progredir de clube')
    expect(btn).toBeDefined()
    await btn!.trigger('click')
    await flushPromises()

    expect(confirmacao.require).toHaveBeenCalledTimes(1)
    const cfg = confirmacao.require.mock.calls[0]![0]!
    expect(cfg.message).toContain('Faíscas')

    await cfg.accept()
    await flushPromises()
    expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_transferir_clube', {
      p_oansista_id: 'o1',
      p_clube_destino_id: 'c3',
      p_motivo: 'Progressão de faixa etária',
    })
  })

  it('não mostra Progredir quando a criança ainda está na faixa do clube', async () => {
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>([])
        b.singleData = PERFIL
        return b
      },
      oansistas: () => builder([
        { id: 'o1', nome: 'Ana', data_nascimento: nascimentoComIdade(5), turma_id: null, clube_id: 'c1', status: 'ativo', turma: null },
      ]),
      turmas: () => builder([]),
      clubes: () => builder(CLUBES),
    })
    const wrapper = await montarComPerfil()

    expect(wrapper.findAll('button').find(b => b.attributes('aria-label') === 'Progredir de clube')).toBeUndefined()
  })

  it('mostra aviso e bloqueia o salvamento de criança nascida neste ano', async () => {
    const wrapper = await montarComPerfil()

    const botaoNovo = wrapper.findAll('button').find(b => b.text() === 'Novo')
    await botaoNovo!.trigger('click')
    await flushPromises()

    await wrapper.find('form input').setValue('Ana')
    await wrapper.find('form input[type="date"]').setValue(`${new Date().getFullYear()}-01-01`)
    await flushPromises()

    expect(wrapper.text()).toContain('nasceu neste ano')

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(confirmacao.require).not.toHaveBeenCalled()
    expect(mocks.supabase.builderDe('oansistas').insert).not.toHaveBeenCalled()
  })

  it('pede confirmação quando a idade corresponde a outro clube', async () => {
    const wrapper = await montarComPerfil()

    const botaoNovo = wrapper.findAll('button').find(b => b.text() === 'Novo')
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
    expect(cfg.message).toContain('Ursinhos')

    await cfg.accept()
    await flushPromises()
    expect(mocks.supabase.builderDe('oansistas').insert).toHaveBeenCalled()
  })
})
