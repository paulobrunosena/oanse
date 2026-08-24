import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { pontosPorChave, type ItensPontuacaoMap } from '../../utils/pontos'
import FolhaSemanalRow from './FolhaSemanalRow.vue'

const PONTOS: ItensPontuacaoMap = pontosPorChave([
  { chave: 'presenca', pontos: 10 },
  { chave: 'uniforme', pontos: 5 },
  { chave: 'biblia', pontos: 5 },
  { chave: 'ebd', pontos: 5 },
  { chave: 'manual', pontos: 5 },
  { chave: 'conduta', pontos: 5 },
  { chave: 'secao_manual', pontos: 2 },
])

const stubs = {
  Avatar: { name: 'Avatar', template: '<span class="avatar" />' },
  Tag: { name: 'Tag', template: '<span class="tag"><slot /></span>' },
  Button: {
    name: 'Button',
    template: '<button class="btn" :disabled="disabled || loading"><slot /></button>',
    props: ['disabled', 'loading'],
  },
  Checkbox: {
    name: 'Checkbox',
    template: '<input type="checkbox" :checked="modelValue" @change="$emit(\'update:modelValue\', $event.target.checked)" />',
    props: ['modelValue'],
  },
  InputNumber: {
    name: 'InputNumber',
    template: '<input type="number" :value="modelValue" @input="$emit(\'update:modelValue\', Number($event.target.value))" />',
    props: ['modelValue'],
  },
}

function props(sobre: Partial<ConstructorParameters<typeof FolhaSemanalRow>[0]> = {}) {
  return {
    nome: 'Ana',
    folha: null,
    presente: true,
    pontos: PONTOS,
    salvando: false,
    ...sobre,
  }
}

describe('FolhaSemanalRow', () => {
  it('renderiza o cartão com fundo de superfície (padrão das outras telas)', () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    expect(wrapper.find('.rounded-lg.border').classes()).toContain('bg-[var(--surface-card)]')
  })

  it('mostra o total apenas com a presença quando não há critérios', () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    expect(wrapper.find('.tag').text()).toContain('10 pts')
  })

  it('zera o total quando o oansista faltou', () => {
    const wrapper = mount(FolhaSemanalRow, {
      props: props({ presente: false }),
      global: { stubs },
    })

    expect(wrapper.find('.tag').text()).toContain('0 pts')
  })

  it('recalcula o total ao editar as seções do manual', async () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    await wrapper.findAll('input[type="number"]')[0]!.setValue(3)

    expect(wrapper.find('.tag').text()).toContain('16 pts')
  })

  it('habilita o botão salvar quando ainda não há folha persistida', () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    const botao = wrapper.find('.btn')
    expect(botao.attributes('disabled')).toBeUndefined()
  })

  it('desabilita o botão salvar quando o formulário está limpo em relação à folha persistida', () => {
    const wrapper = mount(FolhaSemanalRow, {
      props: props({
        folha: { uniforme: false, biblia: false, ebd: false, manual: false, conduta: false, secoes_dia: 0, atividade_extra: 0 },
      }),
      global: { stubs },
    })

    expect(wrapper.find('.btn').attributes('disabled')).toBeDefined()
  })

  it('emite salvar com o formulário quando clica no botão', async () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    await wrapper.find('.btn').trigger('click')

    const emitido = wrapper.emitted('salvar')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]![0]).toEqual({ uniforme: false, biblia: false, ebd: false, manual: false, conduta: false, secoes_dia: 0, atividade_extra: 0 })
  })
})
