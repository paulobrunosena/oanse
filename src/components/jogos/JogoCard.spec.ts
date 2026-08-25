import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import JogoCard from './JogoCard.vue'
import type { Jogo } from '@/composables/useJogos'

const stubs = {
  Button: {
    template: '<button :disabled="disabled">{{ label }}<slot /></button>',
    props: ['label', 'disabled'],
  },
  InputText: {
    template: '<input :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
    props: ['modelValue'],
  },
  Select: {
    name: 'Select',
    template: '<select :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)"><option v-for="i in options" :key="i.value" :value="i.value">{{ i[optionLabel] ?? i.label }}</option></select>',
    props: ['modelValue', 'options', 'optionLabel', 'optionValue'],
  },
  Tag: {
    name: 'Tag',
    template: '<span class="p-tag">{{ value }}<button v-if="removable" class="tag-remove" @click="$emit(\'remove\')">x</button></span>',
    props: { value: String, removable: Boolean, severity: String, rounded: Boolean },
  },
  Avatar: { template: '<span class="p-avatar" />' },
}

const JOGO: Jogo = {
  id: 'j1',
  nome: 'Corrida de obstáculos',
  criado_por: null,
  clubes: [{ clube_id: 'c1', nome: 'Faíscas', slug: 'faiscas', cor: '#EAB308' }],
  times: [
    {
      id: 't1', nome: 'Amarelos', cor: 'amarelo', lider_id: null,
      integrantes: [{ oansista_id: 'o1', nome: 'Ana' }],
      resultado: { id: 'r1', colocacao: 1, desclassificado: false, pontos: 100 },
    },
    {
      id: 't2', nome: 'Azuis', cor: null, lider_id: null,
      integrantes: [],
      resultado: null,
    },
  ],
}

const CONFIG = [
  { colocacao: 1, pontos: 100, desclassificado: false },
  { colocacao: 2, pontos: 70, desclassificado: false },
  { colocacao: 3, pontos: 50, desclassificado: false },
  { colocacao: 4, pontos: 40, desclassificado: false },
]

function montar(jogo = JOGO, oansistas = [{ id: 'o1', nome: 'Ana' }, { id: 'o2', nome: 'Bia' }]) {
  return mount(JogoCard, {
    props: { jogo, oansistas, pontosConfig: CONFIG },
    global: { stubs },
  })
}

describe('JogoCard', () => {
  it('renderiza clubes, times, integrantes e pontos do placar', () => {
    const wrapper = montar()

    expect(wrapper.text()).toContain('Corrida de obstáculos')
    expect(wrapper.text()).toContain('Faíscas')
    expect(wrapper.text()).toContain('Amarelos')
    expect(wrapper.text()).toContain('Azuis')
    expect(wrapper.text()).toContain('Ana')
    expect(wrapper.text()).toContain('100')
  })

  it('filtra das buscas as crianças já alocadas em algum time', () => {
    const wrapper = montar()
    const integranteSelect = wrapper.findAll('select').find(s =>
      s.findAll('option').some(o => o.text() === 'Bia'))
    const opcoes = integranteSelect!.findAll('option').map(o => o.text())
    expect(opcoes).not.toContain('Ana')
    expect(opcoes).toContain('Bia')
  })

  it('emite lancar-resultado ao definir o placar de um time', async () => {
    const wrapper = montar()
    const placar = wrapper.findAll('select')[0]!
    await placar.setValue('2')

    const emitido = wrapper.emitted('lancar-resultado')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]).toEqual(['j1', 't1', { colocacao: 2, desclassificado: false }])
  })

  it('emite remover-resultado ao escolher "Sem resultado"', async () => {
    const wrapper = montar()
    const placar = wrapper.findAll('select')[0]!
    await placar.setValue('sem')

    const emitido = wrapper.emitted('remover-resultado')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]).toEqual(['j1', 't1'])
  })

  it('emite remover-integrante ao remover uma criança do time', async () => {
    const wrapper = montar()
    await wrapper.find('.tag-remove').trigger('click')

    const emitido = wrapper.emitted('remover-integrante')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]).toEqual(['j1', 't1', 'o1'])
  })

  it('emite criar-time com nome e cor preenchidos', async () => {
    const wrapper = montar()
    const inputs = wrapper.findAll('input')
    await inputs[0]!.setValue('Verdes')
    await inputs[1]!.setValue('verde')
    const botao = wrapper.findAll('button').find(b => b.text().includes('Adicionar time'))!
    await botao.trigger('click')

    const emitido = wrapper.emitted('criar-time')
    expect(emitido).toHaveLength(1)
    expect(emitido![0]).toEqual(['j1', 'Verdes', 'verde'])
  })

  it('bloqueia criar o 5º time (máximo 4)', () => {
    const cheio: Jogo = {
      id: 'j2', nome: 'Jogo', criado_por: null, clubes: [],
      times: Array.from({ length: 4 }, (_, i) => ({
        id: `t${i}`, nome: `Time ${i}`, cor: null, lider_id: null, integrantes: [], resultado: null,
      })),
    }
    const wrapper = montar(cheio, [])

    const botoesAdicionar = wrapper.findAll('button').filter(b => b.text().includes('Adicionar time'))
    expect(botoesAdicionar).toHaveLength(0)
    expect(wrapper.text()).toContain('Máximo de 4 times por jogo.')
  })
})