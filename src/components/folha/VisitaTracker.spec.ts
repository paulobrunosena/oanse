import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import VisitaTracker from './VisitaTracker.vue'
import type { Database } from '@/types/database.types'

type VisitaRow = Database['public']['Tables']['visitas']['Row']

const stubs = {
  InputText: {
    name: 'InputText',
    props: ['modelValue', 'type', 'disabled', 'ariaLabel'],
    emits: ['update:modelValue'],
    template: '<input class="data" type="date" :value="modelValue" :disabled="disabled" :aria-label="ariaLabel" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
  Checkbox: {
    name: 'Checkbox',
    props: ['modelValue', 'binary', 'disabled', 'inputId'],
    emits: ['update:modelValue'],
    template: '<input class="chk" type="checkbox" :checked="modelValue" :disabled="disabled" :id="inputId" @change="$emit(\'update:modelValue\', $event.target.checked)" />',
  },
}

function visita(sobre: Partial<VisitaRow> = {}): VisitaRow {
  return {
    id: 'vs1',
    visitante_id: 'v1',
    numero: 1,
    data_visita: '2026-09-05',
    presente: true,
    observacao: null,
    ...sobre,
  }
}

describe('VisitaTracker', () => {
  it('abre uma linha para cada uma das 3 visitas', () => {
    const wrapper = mount(VisitaTracker, { props: { visitas: [] }, global: { stubs } })

    expect(wrapper.findAll('input[type="date"]')).toHaveLength(3)
    expect(wrapper.text()).toContain('1ª visita')
    expect(wrapper.text()).toContain('2ª visita')
    expect(wrapper.text()).toContain('3ª visita')
  })

  it('preenche a data e o presente a partir das visitas existentes', () => {
    const wrapper = mount(VisitaTracker, {
      props: { visitas: [visita(), visita({ numero: 2, presente: false, data_visita: '2026-09-12' })] },
      global: { stubs },
    })

    const datas = wrapper.findAll('input[type="date"]')
    const checkboxes = wrapper.findAll('input[type="checkbox"]')
    expect(datas[0]!.attributes('value')).toBe('2026-09-05')
    expect(checkboxes[0]!.attributes('checked')).toBeDefined()
    expect(checkboxes[1]!.attributes('checked')).toBeUndefined()
    expect(checkboxes[1]!.attributes('disabled')).toBeUndefined()
  })

  it('mantém o checkbox desabilitado enquanto a visita não tem data', () => {
    const wrapper = mount(VisitaTracker, { props: { visitas: [] }, global: { stubs } })

    expect(wrapper.findAll('input[type="checkbox"]')[0]!.attributes('disabled')).toBeDefined()
  })

  it('emite salvar-visita com presente true ao preencher a data de uma nova visita', async () => {
    const wrapper = mount(VisitaTracker, { props: { visitas: [] }, global: { stubs } })

    await wrapper.findAll('input[type="date"]')[0]!.setValue('2026-09-05')

    expect(wrapper.emitted('salvar-visita')?.[0]).toEqual([1, { data_visita: '2026-09-05', presente: true }])
  })

  it('emite salvar-visita com o presente alterado ao desmarcar', async () => {
    const wrapper = mount(VisitaTracker, { props: { visitas: [visita()] }, global: { stubs } })

    await wrapper.findAll('input[type="checkbox"]')[0]!.setValue(false)

    expect(wrapper.emitted('salvar-visita')?.[0]).toEqual([1, { data_visita: '2026-09-05', presente: false }])
  })

  it('desabilita apenas a visita em salvamento', () => {
    const wrapper = mount(VisitaTracker, {
      props: { visitas: [visita(), visita({ numero: 2, data_visita: '2026-09-12' }), visita({ numero: 3, data_visita: '2026-09-19' })], salvando: 2 },
      global: { stubs },
    })

    const datas = wrapper.findAll('input[type="date"]')
    expect(datas[0]!.attributes('disabled')).toBeUndefined()
    expect(datas[1]!.attributes('disabled')).toBeDefined()
    expect(datas[2]!.attributes('disabled')).toBeUndefined()
  })
})
