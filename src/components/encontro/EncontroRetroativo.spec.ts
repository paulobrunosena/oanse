import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import EncontroRetroativo from './EncontroRetroativo.vue'
import { useEncontroStore } from '@/stores/encontro'
import { clienteSupabase } from '../../../tests/helpers/supabase'

const mocks = vi.hoisted(() => ({
  supabase: null as any,
  apiFetch: null as any,
}))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))
vi.mock('@/lib/api', () => ({
  apiFetch: (...args: unknown[]) => mocks.apiFetch(...args),
}))

const stubs = {
  Button: {
    name: 'Button',
    props: ['label', 'disabled', 'loading', 'outlined', 'icon'],
    template: '<button :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
  },
  Dialog: {
    name: 'Dialog',
    props: ['visible', 'header', 'modal'],
    template: '<div v-if="visible"><div>{{ header }}</div><slot /></div>',
  },
  Select: {
    name: 'Select',
    template: '<select :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="i in options" :key="i.value" :value="i.value">{{ i.label }}</option></select>',
    props: ['modelValue', 'options', 'optionLabel', 'optionValue', 'placeholder'],
  },
}

describe('EncontroRetroativo', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase()
    mocks.apiFetch = async (_path: string) => {
      return {
        encontro: { id: 'e9', data: '2026-08-01', ativo: true },
        criado: true,
      }
    }
  })

  it('desabilita o botão quando não há sábados em aberto', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 7, 24))
    const store = useEncontroStore()
    store.encontros = [
      '2026-08-22', '2026-08-15', '2026-08-08', '2026-08-01',
      '2026-07-25', '2026-07-18', '2026-07-11', '2026-07-04',
      '2026-06-27', '2026-06-20', '2026-06-13', '2026-06-06',
    ].map((data, i) => ({ id: `e${i}`, data, ativo: true }) as never)
    store.diasSemOanse = []
    vi.useRealTimers()

    const wrapper = mount(EncontroRetroativo, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })

    expect(wrapper.find('button').attributes('disabled')).toBeDefined()
  })

  it('emite criado com o encontro do sábado escolhido', async () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 7, 24))
    const store = useEncontroStore()
    store.encontros = []
    store.diasSemOanse = ['2026-08-08']
    vi.useRealTimers()

    const wrapper = mount(EncontroRetroativo, {
      global: { stubs, plugins: [PrimeVue, ToastService] },
    })

    await wrapper.find('button').trigger('click')
    await wrapper.find('select').setValue('2026-08-01')

    const botoes = wrapper.findAll('button')
    const criar = botoes.find(b => b.text() === 'Criar sábado')
    expect(criar).toBeDefined()
    await criar!.trigger('click')
    await flushPromises()

    const emitido = wrapper.emitted('criado')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]).toEqual(['e9'])
  })
})