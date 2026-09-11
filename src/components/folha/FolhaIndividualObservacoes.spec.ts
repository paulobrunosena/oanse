import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import FolhaIndividualObservacoes from './FolhaIndividualObservacoes.vue'

const stubs = {
  Button: {
    name: 'Button',
    props: ['label', 'disabled', 'loading'],
    emits: ['click'],
    template: '<button class="btn" :disabled="disabled || loading" @click="$emit(\'click\')">{{ label }}</button>',
  },
  Textarea: {
    name: 'Textarea',
    props: ['modelValue'],
    emits: ['update:modelValue'],
    template: '<textarea class="textarea" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
}

function props(sobre: Partial<ConstructorParameters<typeof FolhaIndividualObservacoes>[0]> = {}) {
  return { texto: '', ...sobre }
}

describe('FolhaIndividualObservacoes', () => {
  it('mostra o texto salvo no textarea', () => {
    const wrapper = mount(FolhaIndividualObservacoes, {
      props: props({ texto: 'Falta decorar o versículo.' }),
      global: { stubs },
    })

    expect((wrapper.find('.textarea').element as HTMLTextAreaElement).value).toBe('Falta decorar o versículo.')
  })

  it('mantém o botão desabilitado enquanto o texto não mudou', () => {
    const wrapper = mount(FolhaIndividualObservacoes, {
      props: props({ texto: 'Igual' }),
      global: { stubs },
    })

    expect(wrapper.find('.btn').attributes('disabled')).toBeDefined()
  })

  it('libera o botão ao editar e emite salvar com o texto digitado', async () => {
    const wrapper = mount(FolhaIndividualObservacoes, {
      props: props({ texto: '' }),
      global: { stubs },
    })

    await wrapper.find('.textarea').setValue('Nova anotação')

    expect(wrapper.find('.btn').attributes('disabled')).toBeUndefined()
    await wrapper.find('.btn').trigger('click')
    expect(wrapper.emitted('salvar')?.[0]).toEqual(['Nova anotação'])
  })

  it('bloqueia o botão enquanto salva mesmo com o texto alterado', async () => {
    const wrapper = mount(FolhaIndividualObservacoes, {
      props: props({ texto: '', salvando: true }),
      global: { stubs },
    })

    await wrapper.find('.textarea').setValue('Nova anotação')

    expect(wrapper.find('.btn').attributes('disabled')).toBeDefined()
  })
})
