import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

vi.mock('@/lib/api', () => ({
  apiFetch: async () => [],
}))

import UsuariosView from './UsuariosView.vue'

const stubs = {
  Button: { name: 'Button', template: '<button><slot /></button>' },
  Column: { name: 'Column', template: '<div><slot name="body" :data="{}" /></div>' },
  DataTable: {
    name: 'DataTable',
    props: ['value'],
    template: '<div class="dt"><div v-for="(row, i) in value" :key="i"><slot /></div></div>',
  },
  Dialog: { name: 'Dialog', template: '<div><slot /></div>' },
  InputText: { name: 'InputText', template: '<input />' },
  Select: { name: 'Select', props: ['options'], template: '<div class="p-select" />' },
  Tag: { name: 'Tag', props: ['value'], template: '<span>{{ value }}</span>' },
  ToggleSwitch: { name: 'ToggleSwitch', template: '<div />' },
}

describe('UsuariosView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      clubes: () => builder([]),
    })
  })

  it('oferece o perfil "Líder de Jogos" no combo do dialog de novo usuário', async () => {
    const wrapper = mount(UsuariosView, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })
    await flushPromises()

    const selects = wrapper.findAllComponents({ name: 'Select' })
    const perfil = selects.find(s => {
      const opts = (s.props('options') ?? []) as { value: string, label: string }[]
      return opts.some(o => o.value === 'lider_jogos')
    })

    expect(perfil).toBeDefined()
    const opcoes = perfil!.props('options') as { value: string, label: string }[]
    expect(opcoes).toContainEqual({ label: 'Líder de Jogos', value: 'lider_jogos' })
  })
})