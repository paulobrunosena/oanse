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
    { id: 'cor1', cor: 'verde', oansistas: [{ oansista_id: 'o1', nome: 'Ana' }] },
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
  Select: { name: 'Select', template: '<div />' },
  Tag: {
    name: 'Tag',
    props: ['value'],
    template: '<span>{{ value }}<slot /></span>',
  },
}

describe('EventoJogosCard', () => {
  it('renderiza nome, clubes e cores participantes', () => {
    const wrapper = mount(EventoJogosCard, {
      props: { evento: EVENTO, oansistas: [{ id: 'o2', nome: 'Beto' }] },
      global: { stubs },
    })
    expect(wrapper.text()).toContain('Jogos dos Flamas e Tochas')
    expect(wrapper.text()).toContain('Flamas')
    expect(wrapper.text()).toContain('Tochas')
    expect(wrapper.text()).toContain('verde')
    expect(wrapper.text()).toContain('azul')
    expect(wrapper.text()).toContain('Ana')
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