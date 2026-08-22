import { describe, expect, it } from 'vitest'
import { mountSuspended } from '@nuxt/test-utils/runtime'
import EncontroSeletor from './EncontroSeletor.vue'

const stubs = {
  USelect: {
    template: '<select :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="i in items" :key="i.value" :value="i.value">{{ i.label }}</option></select>',
    props: ['modelValue', 'items'],
  },
}

const ENCONTROS = [
  { id: 'e1', data: '2026-08-22', ativo: true },
  { id: 'e0', data: '2026-08-15', ativo: true },
] as unknown as ConstructorParameters<typeof EncontroSeletor>[0]['encontros']

describe('EncontroSeletor', () => {
  it('renderiza os sábados formatados como opções', async () => {
    const wrapper = await mountSuspended(EncontroSeletor, {
      props: { encontros: ENCONTROS, encontro: ENCONTROS[0] },
      global: { stubs },
    })

    const opcoes = wrapper.findAll('option')
    expect(opcoes).toHaveLength(2)
    expect(opcoes[0]!.text()).toBe('22/08/2026')
    expect(opcoes[1]!.text()).toBe('15/08/2026')
  })

  it('emite selecionar com o id do encontro escolhido', async () => {
    const wrapper = await mountSuspended(EncontroSeletor, {
      props: { encontros: ENCONTROS, encontro: ENCONTROS[0] },
      global: { stubs },
    })

    await wrapper.find('select').setValue('e0')

    const emitido = wrapper.emitted('selecionar')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]).toEqual(['e0'])
  })
})
