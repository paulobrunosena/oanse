import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import FolhaIndividualSeletor from './FolhaIndividualSeletor.vue'

const OANSISTAS = [
  { id: 'o1', nome: 'Davi Rocha' },
  { id: 'o2', nome: 'Laura Castro' },
]

const stubs = {
  Select: {
    name: 'Select',
    props: ['modelValue', 'options', 'optionLabel', 'optionValue', 'filter'],
    emits: ['update:modelValue'],
    template: '<select class="select" :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="o in options" :key="o.value" :value="o.value">{{ o.label }}</option></select>',
  },
}

describe('FolhaIndividualSeletor', () => {
  it('lista as crianças do clube como opções do seletor', () => {
    const wrapper = mount(FolhaIndividualSeletor, {
      props: { oansistas: OANSISTAS, oansistaId: null },
      global: { stubs },
    })

    const opcoes = wrapper.findAll('option')
    expect(opcoes.map(o => o.text())).toEqual(['Davi Rocha', 'Laura Castro'])
    expect(opcoes.map(o => o.attributes('value'))).toEqual(['o1', 'o2'])
  })

  it('emite selecionar quando a criança é escolhida', async () => {
    const wrapper = mount(FolhaIndividualSeletor, {
      props: { oansistas: OANSISTAS, oansistaId: null },
      global: { stubs },
    })

    await wrapper.find('.select').setValue('o2')

    expect(wrapper.emitted('selecionar')?.[0]).toEqual(['o2'])
  })

  it('habilita a busca por nome no seletor', () => {
    const wrapper = mount(FolhaIndividualSeletor, {
      props: { oansistas: OANSISTAS, oansistaId: 'o1' },
      global: { stubs },
    })

    expect(wrapper.findComponent({ name: 'Select' }).props('filter')).toBe(true)
  })
})
