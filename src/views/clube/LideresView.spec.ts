import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import LideresView from './LideresView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretora Ursinhos', role: 'diretor_clube', clube_id: 'c1', ativo: true } as unknown as Profile

const LIDERES = [
  { id: 'l1', nome: 'Tia Ana', role: 'lider', clube_id: 'c1', ativo: true, telefone: '(81) 99999-8888', turma: { nome: 'Turma 1' } },
  { id: 'l2', nome: 'Tio Beto', role: 'lider', clube_id: 'c1', ativo: true, telefone: '(81) 98888-7777', turma: { nome: 'Turma 2' } },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

const stubs = {
  Column: { name: 'Column', template: '<div><slot name="body" :data="{}" /></div>' },
  DataTable: {
    name: 'DataTable',
    props: ['value'],
    template: '<div class="dt"><div v-for="(row, i) in value" :key="i"><slot /></div></div>',
  },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
}

describe('LideresView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      profiles: () => {
        const b = builder<unknown>(LIDERES)
        b.singleData = PERFIL
        return b
      },
    })
  })

  it('envolve a DataTable em um container com rolagem horizontal (overflow-x-auto)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    await store.loadProfile()

    const wrapper = mount(LideresView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    expect(wrapper.find('.overflow-x-auto').exists()).toBe(true)
  })
})