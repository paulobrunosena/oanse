import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import OansistasView from './OansistasView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretora Ursinhos', role: 'diretor_clube', clube_id: 'c1', ativo: true } as unknown as Profile

const OANSISTAS = [
  { id: 'o1', nome: 'Ana', data_nascimento: '2018-05-10', turma_id: 't1', clube_id: 'c1', status: 'ativo', turma: { nome: 'Turma 1' } },
  { id: 'o2', nome: 'Beto', data_nascimento: '2017-03-15', turma_id: null, clube_id: 'c1', status: 'ativo', turma: null },
]

const TURMAS = [
  { id: 't1', nome: 'Turma 1', ativo: true, clube_id: 'c1' },
  { id: 't2', nome: 'Turma 2', ativo: true, clube_id: 'c1' },
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
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>([])
        b.singleData = PERFIL
        return b
      },
      oansistas: () => builder(OANSISTAS),
      turmas: () => builder(TURMAS),
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
})