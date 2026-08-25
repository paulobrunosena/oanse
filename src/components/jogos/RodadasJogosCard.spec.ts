import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import RodadasJogosCard from './RodadasJogosCard.vue'
import type { EventoCor, RodadaJogo } from '@/composables/useJogos'

const CORES: EventoCor[] = [
  { id: 'cor1', cor: 'verde', oansistas: [] },
  { id: 'cor2', cor: 'azul', oansistas: [] },
]

const RODADAS: RodadaJogo[] = [
  {
    id: 'j1',
    nome: 'maratona',
    criado_por: 'p1',
    resultados: [{ id: 'r1', cor_id: 'cor1', colocacao: 1, desclassificado: false, pontos: 100 }],
  },
]

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
    props: ['modelValue'],
    emits: ['update:modelValue'],
    template: '<input class="sel" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
  Tag: {
    name: 'Tag',
    props: ['value'],
    template: '<span>{{ value }}<slot /></span>',
  },
}

describe('RodadasJogosCard', () => {
  it('pré-preenche o jogo com o último lançado (nomeInicial)', () => {
    const wrapper = mount(RodadasJogosCard, {
      props: { rodadas: RODADAS, cores: CORES, opcoesNomes: ['maratona', 'bonanza'], nomeInicial: 'maratona' },
      global: { stubs },
    })
    const primeiro = wrapper.find('input.sel')
    expect((primeiro.element as HTMLInputElement).value).toBe('maratona')
  })

  it('emite registrar com o nome e as colocações preenchidas', async () => {
    const wrapper = mount(RodadasJogosCard, {
      props: { rodadas: [], cores: CORES, opcoesNomes: ['maratona', 'bonanza'], nomeInicial: 'maratona' },
      global: { stubs },
    })
    const inputs = wrapper.findAll('input.sel')
    await inputs[1]!.setValue('1')
    await inputs[2]!.setValue('2')

    const registrar = wrapper.findAll('button').find(b => b.text().includes('Registrar rodada'))
    await registrar!.trigger('click')

    const emitido = wrapper.emitted('registrar')![0]![0] as { nome: string, resultados: unknown[] }
    expect(emitido.nome).toBe('maratona')
    expect(emitido.resultados).toEqual([
      { cor_id: 'cor1', colocacao: 1, desclassificado: false },
      { cor_id: 'cor2', colocacao: 2, desclassificado: false },
    ])
  })

  it('emite excluir-rodada', async () => {
    const wrapper = mount(RodadasJogosCard, {
      props: { rodadas: RODADAS, cores: CORES, opcoesNomes: ['maratona'], nomeInicial: '' },
      global: { stubs },
    })
    const excluir = wrapper.findAll('button').find(b => b.attributes('title') === 'Excluir rodada')
    await excluir!.trigger('click')
    expect(wrapper.emitted('excluir-rodada')).toEqual([['j1']])
  })
})