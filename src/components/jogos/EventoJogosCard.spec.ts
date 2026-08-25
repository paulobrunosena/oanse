import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import EventoJogosCard from './EventoJogosCard.vue'
import type { EventoJogo } from '@/composables/useJogos'

const EVENTO: EventoJogo = {
  id: 'ev1',
  encontro_id: 'e1',
  nome: 'Jogos dos Flamas e Tochas',
  status: 'em_andamento',
  criado_por: 'p1',
  clubes: [
    { clube_id: 'c1', nome: 'Flamas', slug: 'flamas', cor: '#22C55E' },
    { clube_id: 'c2', nome: 'Tochas', slug: 'tochas', cor: '#3B82F6' },
  ],
  cores: [
    { id: 'cor1', cor: 'verde', oansistas: [{ oansista_id: 'o1', nome: 'Ana', clube: null }] },
    { id: 'cor2', cor: 'azul', oansistas: [] },
  ],
}

const stubs = {
  Button: {
    name: 'Button',
    props: ['label', 'disabled'],
    inheritAttrs: false,
    emits: ['click'],
    template: '<button v-bind="$attrs" :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
  },
  Select: {
    name: 'Select',
    props: ['options', 'optionLabel', 'optionValue', 'modelValue'],
    emits: ['update:modelValue'],
    template: '<div class="select-stub"><template v-for="o in options" :key="o[optionValue]"><slot name="option" :option="o" /></template></div>',
  },
  Tag: {
    name: 'Tag',
    props: ['value'],
    template: '<span>{{ value }}<slot /></span>',
  },
}

describe('EventoJogosCard', () => {
  it('renderiza nome, clubes e cores participantes', () => {
    const wrapper = mount(EventoJogosCard, {
      props: { evento: EVENTO, oansistas: [{ id: 'o2', nome: 'Beto', clube_id: 'c1', clube: { nome: 'Flamas', cor: '#22C55E' } }] },
      global: { stubs },
    })
    expect(wrapper.text()).toContain('Jogos dos Flamas e Tochas')
    expect(wrapper.text()).toContain('Flamas')
    expect(wrapper.text()).toContain('Tochas')
    expect(wrapper.text()).toContain('verde')
    expect(wrapper.text()).toContain('azul')
    expect(wrapper.text()).toContain('Ana')
  })

  it('mostra o clube como badge nas opções de busca de criança', () => {
    const comCoresVazias = {
      ...EVENTO,
      cores: [
        { id: 'cor1', cor: 'verde', oansistas: [] },
        { id: 'cor2', cor: 'azul', oansistas: [] },
      ],
    }
    const wrapper = mount(EventoJogosCard, {
      props: {
        evento: comCoresVazias,
        oansistas: [
          { id: 'o3', nome: 'Beto', clube_id: 'c1', clube: { nome: 'Flamas', cor: '#22C55E' } },
          { id: 'o4', nome: 'Cida', clube_id: 'c2', clube: { nome: 'Tochas', cor: '#3B82F6' } },
        ],
      },
      global: { stubs },
    })
    const opcoes = wrapper.findAll('.select-stub').at(0)!
    expect(opcoes.text()).toContain('Beto')
    expect(opcoes.text()).toContain('Flamas')
    expect(opcoes.text()).toContain('Cida')
    expect(opcoes.text()).toContain('Tochas')
  })

  it('colore o nome da criança com a cor do clube dela', () => {
    const comIntegrantes = {
      ...EVENTO,
      cores: [
        {
          id: 'cor1',
          cor: 'verde',
          oansistas: [
            { oansista_id: 'o1', nome: 'Ana', clube: { nome: 'Flamas', cor: '#22C55E' } },
            { oansista_id: 'o5', nome: 'Duda', clube: { nome: 'Tochas', cor: '#3B82F6' } },
          ],
        },
        { id: 'cor2', cor: 'azul', oansistas: [] },
      ],
    }
    const wrapper = mount(EventoJogosCard, {
      props: { evento: comIntegrantes },
      global: { stubs },
    })
    const corVerde = wrapper.findAll('.rounded-md.border.p-3').at(0)!
    const ana = corVerde.findAll('span').find(s => s.text() === 'Ana')!
    const duda = corVerde.findAll('span').find(s => s.text() === 'Duda')!
    expect(ana.attributes('style')).toContain('#22C55E')
    expect(duda.attributes('style')).toContain('#3B82F6')
  })

  it('usa a cor do clube no nome mesmo quando há um único clube', () => {
    const umClube = {
      ...EVENTO,
      clubes: [{ clube_id: 'c1', nome: 'Flamas', slug: 'flamas', cor: '#22C55E' }],
      cores: [
        {
          id: 'cor1',
          cor: 'verde',
          oansistas: [{ oansista_id: 'o1', nome: 'Ana', clube: { nome: 'Flamas', cor: '#22C55E' } }],
        },
        { id: 'cor2', cor: 'azul', oansistas: [] },
      ],
    }
    const wrapper = mount(EventoJogosCard, {
      props: { evento: umClube },
      global: { stubs },
    })
    const corVerde = wrapper.findAll('.rounded-md.border.p-3').at(0)!
    const ana = corVerde.findAll('span').find(s => s.text() === 'Ana')!
    expect(ana.attributes('style')).toContain('#22C55E')
  })

  it('emite remover-oansista ao clicar no botão de remover a criança da cor', async () => {
    const wrapper = mount(EventoJogosCard, {
      props: { evento: EVENTO },
      global: { stubs },
    })
    const botao = wrapper.find('button[title="Remover Ana desta cor"]')
    await botao.trigger('click')
    expect(wrapper.emitted('remover-oansista')).toEqual([['cor1', 'o1']])
  })

  it('não permite remover criança quando o evento está finalizado', () => {
    const finalizado = { ...EVENTO, status: 'finalizado' as const }
    const wrapper = mount(EventoJogosCard, {
      props: { evento: finalizado },
      global: { stubs },
    })
    expect(wrapper.find('button[title="Remover Ana desta cor"]').exists()).toBe(false)
  })

  it('emite finalizar ao clicar no botão de finalizar jogos', async () => {
    const wrapper = mount(EventoJogosCard, {
      props: { evento: EVENTO },
      global: { stubs },
    })
    const botao = wrapper.findAll('button').find(b => b.text().includes('Finalizar jogos'))
    await botao!.trigger('click')
    expect(wrapper.emitted('finalizar')).toHaveLength(1)
  })

  it('emite excluir ao clicar no botão de excluir evento', async () => {
    const wrapper = mount(EventoJogosCard, {
      props: { evento: EVENTO },
      global: { stubs },
    })
    const botao = wrapper.findAll('button').find(b => b.attributes('title') === 'Excluir evento')
    await botao!.trigger('click')
    expect(wrapper.emitted('excluir')).toHaveLength(1)
  })

  it('emite adicionar-cor com a cor disponível', async () => {
    const wrapper = mount(EventoJogosCard, {
      props: { evento: EVENTO },
      global: { stubs },
    })
    const botaoVermelho = wrapper.findAll('button').find(b => b.text().includes('vermelho'))
    await botaoVermelho!.trigger('click')
    expect(wrapper.emitted('adicionar-cor')).toEqual([['vermelho']])
  })

  it('emite remover-cor quando há mais de 2 cores', async () => {
    const comQuatro = {
      ...EVENTO,
      cores: [
        { id: 'cor1', cor: 'verde', oansistas: [] },
        { id: 'cor2', cor: 'vermelho', oansistas: [] },
        { id: 'cor3', cor: 'amarelo', oansistas: [] },
        { id: 'cor4', cor: 'azul', oansistas: [] },
      ],
    }
    const wrapper = mount(EventoJogosCard, {
      props: { evento: comQuatro },
      global: { stubs },
    })
    const botoesRemover = wrapper.findAll('button').filter(b => b.attributes('title') === 'Remover cor')
    await botoesRemover[0]!.trigger('click')
    expect(wrapper.emitted('remover-cor')).toEqual([['cor1']])
  })

  it('mostra estado finalizado com botão de reabrir', async () => {
    const finalizado = { ...EVENTO, status: 'finalizado' as const }
    const wrapper = mount(EventoJogosCard, {
      props: { evento: finalizado },
      global: { stubs },
    })
    expect(wrapper.text()).toContain('Finalizado')
    const botaoReabrir = wrapper.findAll('button').find(b => b.text().includes('Reabrir'))
    await botaoReabrir!.trigger('click')
    expect(wrapper.emitted('reabrir')).toHaveLength(1)
  })
})