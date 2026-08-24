import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { mount } from '@vue/test-utils'
import AppSidebar from './AppSidebar.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Tia Ana', role: 'lider', clube_id: 'c1', ativo: true } as unknown as Profile

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

vi.mock('vue-router', () => ({
  useRoute: () => ({ path: '/chamada' }),
}))

const stubs = {
  AppMenu: { name: 'AppMenu', template: '<ul><li>menu</li></ul>' },
  Avatar: { name: 'Avatar', props: ['label'], template: '<div class="p-avatar">{{ label }}</div>' },
  Button: { name: 'Button', props: ['icon', 'ariaLabel'], template: '<button :aria-label="ariaLabel"><i :class="icon"></i></button>' },
}

describe('AppSidebar', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({ profiles: () => builder(PERFIL) })
  })

  it('mostra o perfil do usuário e o botão de sair no rodapé da sidebar (mobile)', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    await store.loadProfile()

    const wrapper = mount(AppSidebar, {
      global: { stubs },
    })

    const perfil = wrapper.find('.layout-sidebar-profile')
    expect(perfil.exists()).toBe(true)
    expect(perfil.classes()).toContain('lg:hidden')
    expect(perfil.text()).toContain('Tia Ana')
    expect(perfil.text()).toContain('Líder')
    expect(perfil.find('[aria-label="Sair"]').exists()).toBe(true)
  })

  it('oculta o bloco de perfil quando não há usuário logado', () => {
    const wrapper = mount(AppSidebar, {
      global: { stubs },
    })

    expect(wrapper.find('.layout-sidebar-profile').exists()).toBe(true)
    expect(wrapper.find('.layout-sidebar-profile').text()).not.toContain('Tia Ana')
    expect(wrapper.find('[aria-label="Sair"]').exists()).toBe(true)
  })
})