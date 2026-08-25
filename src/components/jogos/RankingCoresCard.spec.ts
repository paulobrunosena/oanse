import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import RankingCoresCard from './RankingCoresCard.vue'
import type { RankingCor } from '@/composables/useJogos'

const RANKING: RankingCor[] = [
  { cor: 'verde', pontos: 200, posicao: 1 },
  { cor: 'azul', pontos: 100, posicao: 2 },
  { cor: 'vermelho', pontos: 70, posicao: 3 },
]

const stubs = {
  Tag: {
    name: 'Tag',
    props: ['value'],
    template: '<span>{{ value }}<slot /></span>',
  },
}

describe('RankingCoresCard', () => {
  it('ordena as cores pela posição e mostra os pontos', () => {
    const wrapper = mount(RankingCoresCard, {
      props: { ranking: RANKING },
      global: { stubs },
    })
    expect(wrapper.text()).toContain('Ranking das cores')
    expect(wrapper.text()).toContain('verde')
    expect(wrapper.text()).toContain('azul')
    expect(wrapper.text()).toContain('vermelho')
    expect(wrapper.text()).toContain('200 pts')
    expect(wrapper.text()).toContain('100 pts')
    expect(wrapper.text()).toContain('70 pts')
  })

  it('mostra mensagem quando não há cores', () => {
    const wrapper = mount(RankingCoresCard, {
      props: { ranking: [] },
      global: { stubs },
    })
    expect(wrapper.text()).toContain('Nenhuma cor participando neste evento.')
  })
})