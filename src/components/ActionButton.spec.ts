import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ActionButton from './ActionButton.vue'
import { usePreferenciasStore } from '@/stores/preferencias'

const ButtonStub = {
  name: 'Button',
  props: ['label', 'icon', 'ariaLabel', 'loading', 'disabled', 'severity', 'rounded', 'size'],
  emits: ['click'],
  template: '<button :aria-label="ariaLabel" :disabled="disabled" @click="$emit(\'click\', $event)"><i v-if="icon" :class="icon" />{{ label }}</button>',
}

function montar() {
  return mount(ActionButton, {
    props: { icon: 'pi pi-pencil', label: 'Editar' },
    global: {
      stubs: { Button: ButtonStub },
      plugins: [PrimeVue],
    },
  })
}

describe('ActionButton', () => {
  beforeEach(() => {
    window.localStorage.clear()
    setActivePinia(createPinia())
  })

  it('renderiza apenas o ícone com aria-label quando os rótulos estão desligados', () => {
    const wrapper = montar()
    const botao = wrapper.get('button')

    expect(botao.attributes('aria-label')).toBe('Editar')
    expect(botao.text()).not.toContain('Editar')
    expect(wrapper.get('i').classes()).toContain('pi-pencil')
  })

  it('mostra o texto visível quando os rótulos estão ligados', () => {
    const store = usePreferenciasStore()
    store.alternarRotulosAcoes()

    const wrapper = montar()
    const botao = wrapper.get('button')

    expect(botao.text()).toContain('Editar')
    expect(botao.attributes('aria-label')).toBe('Editar')
  })

  it('emite o evento de clique', async () => {
    const wrapper = montar()
    await wrapper.get('button').trigger('click')
    expect(wrapper.emitted('click')).toHaveLength(1)
  })
})
