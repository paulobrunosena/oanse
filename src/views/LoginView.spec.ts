import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
}))

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      signInWithPassword: vi.fn(async () => ({ error: null })),
    },
  },
}))

import LoginView from './LoginView.vue'

const stubs = {
  Card: {
    name: 'Card',
    template: '<div class="card"><slot name="title" /><slot name="content" /></div>',
  },
  InputText: { name: 'InputText', props: ['modelValue'], template: '<input />' },
  Password: { name: 'Password', props: ['modelValue'], template: '<input />' },
  Button: { name: 'Button', props: ['label', 'loading'], template: '<button>{{ label }}</button>' },
}

describe('LoginView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('mostra as contas de teste em desenvolvimento', () => {
    const wrapper = mount(LoginView, { global: { stubs, plugins: [PrimeVue] } })
    expect(wrapper.text()).toContain('Contas de teste')
  })

  it('esconde as contas de teste fora de desenvolvimento', () => {
    vi.stubEnv('DEV', false)
    try {
      const wrapper = mount(LoginView, { global: { stubs, plugins: [PrimeVue] } })
      expect(wrapper.text()).not.toContain('Contas de teste')
      expect(wrapper.text()).not.toContain('oanse123')
    }
    finally {
      vi.unstubAllEnvs()
    }
  })
})
