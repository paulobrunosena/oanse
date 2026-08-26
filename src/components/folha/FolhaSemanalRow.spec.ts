import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { pontosPorChave, type ItensPontuacaoMap } from '../../utils/pontos'
import FolhaSemanalRow from './FolhaSemanalRow.vue'
import type { Folha } from '@/composables/useFolhaSemanal'

const PONTOS: ItensPontuacaoMap = pontosPorChave([
  { chave: 'presenca', pontos: 10 },
  { chave: 'uniforme', pontos: 5 },
  { chave: 'biblia', pontos: 5 },
  { chave: 'ebd', pontos: 5 },
  { chave: 'manual', pontos: 5 },
  { chave: 'conduta', pontos: 5 },
  { chave: 'leitura_biblica', pontos: 10 },
  { chave: 'visitante', pontos: 5 },
  { chave: 'secao_sem_ajuda', pontos: 10 },
  { chave: 'secao_com_ajuda', pontos: 5 },
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
    template: '<input type="number" :style="inputStyle" :value="modelValue" @input="$emit(\'update:modelValue\', Number($event.target.value))" />',
    props: ['modelValue', 'inputStyle'],
  },
}

function folhaCompleta(sobre: Partial<Folha> = {}): Folha {
  return {
    id: 'f1',
    encontro_id: 'e1',
    oansista_id: 'o1',
    presenca_id: 'p1',
    registrado_por: 'u1',
    uniforme: false,
    biblia: false,
    ebd: false,
    manual: false,
    conduta: false,
    leitura_biblica: false,
    visitantes_convidados: 0,
    secoes_sem_ajuda: 0,
    secoes_com_ajuda: 0,
    cor_time: null,
    atividade_extra: 0,
    pontos_jogos: 0,
    posicao_jogos: null,
    total: 10,
    created_at: '',
    updated_at: '',
    ...sobre,
  }
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
  it('aplica largura maior no input numérico para não cortar os números', () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    for (const input of wrapper.findAll('input[type="number"]')) {
      expect(input.attributes('style')).toContain('width: 5rem')
    }
  })

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

  it('recalcula o total ao editar as seções sem ajuda do manual', async () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    const numericos = wrapper.findAll('input[type="number"]')
    await numericos[0]!.setValue(3)

    expect(wrapper.find('.tag').text()).toContain('40 pts')
  })

  it('recalcula o total ao marcar a leitura bíblica', async () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    const checkboxes = wrapper.findAll('input[type="checkbox"]')
    await checkboxes[5]!.setValue(true)

    expect(wrapper.find('.tag').text()).toContain('20 pts')
  })

  it('recalcula o total ao informar visitantes convidados', async () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    const numericos = wrapper.findAll('input[type="number"]')
    await numericos[2]!.setValue(2)

    expect(wrapper.find('.tag').text()).toContain('20 pts')
  })

  it('recalcula o total com as seções com ajuda (valem menos)', async () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    const numericos = wrapper.findAll('input[type="number"]')
    await numericos[1]!.setValue(2)

    expect(wrapper.find('.tag').text()).toContain('20 pts')
  })

  it('exibe cor, posição no ranking e pontos dos jogos quando a criança participou', () => {
    const wrapper = mount(FolhaSemanalRow, {
      props: props({
        folha: folhaCompleta({ cor_time: 'verde', pontos_jogos: 170, posicao_jogos: 1 }),
      }),
      global: { stubs },
    })

    expect(wrapper.text()).toContain('verde')
    expect(wrapper.text()).toContain('1º lugar')
    expect(wrapper.text()).toContain('170 pts nos jogos')
  })

  it('mostra que a criança não participou dos jogos quando não há cor', () => {
    const wrapper = mount(FolhaSemanalRow, {
      props: props({ folha: folhaCompleta() }),
      global: { stubs },
    })

    expect(wrapper.text()).toContain('Não participou dos jogos deste sábado.')
  })

  it('habilita o botão salvar quando ainda não há folha persistida', () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    const botao = wrapper.find('.btn')
    expect(botao.attributes('disabled')).toBeUndefined()
  })

  it('desabilita o botão salvar quando o formulário está limpo em relação à folha persistida', () => {
    const wrapper = mount(FolhaSemanalRow, {
      props: props({ folha: folhaCompleta() }),
      global: { stubs },
    })

    expect(wrapper.find('.btn').attributes('disabled')).toBeDefined()
  })

  it('emite salvar com o formulário quando clica no botão', async () => {
    const wrapper = mount(FolhaSemanalRow, { props: props(), global: { stubs } })

    await wrapper.find('.btn').trigger('click')

    const emitido = wrapper.emitted('salvar')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]![0]).toEqual({ uniforme: false, biblia: false, ebd: false, manual: false, conduta: false, leitura_biblica: false, visitantes_convidados: 0, secoes_sem_ajuda: 0, secoes_com_ajuda: 0, atividade_extra: 0 })
  })
})