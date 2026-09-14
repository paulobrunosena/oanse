import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import FolhaIndividualManual from './FolhaIndividualManual.vue'
import type { BlocoFolha, ManualFolha } from '@/utils/folhaIndividual'

function bloco(id: string, nome: string): BlocoFolha {
  return {
    id,
    nome,
    ordem: 1,
    quantidade: 1,
    premio_nome: 'Prêmio',
    itens: [{ item_num: 1, data_conclusao: null }],
    premioData: null,
  }
}

const MANUAL: ManualFolha = {
  id: 'm1',
  nome: 'Saltador',
  ordem: 1,
  observacoes: 'Falta decorar o versículo.',
  secoes: [
    { id: 's1', nome: 'Progresso', ordem: 1, tipo: 'itens', blocos: [bloco('b1', 'Grau'), bloco('b2', 'Atividades')] },
    { id: 's2', nome: 'Observações', ordem: 2, tipo: 'observacoes', blocos: [] },
  ],
}

const stubs = {
  Accordion: {
    name: 'Accordion',
    props: { value: [String, Array], multiple: Boolean },
    template: '<div class="accordion"><slot /></div>',
  },
  AccordionPanel: {
    name: 'AccordionPanel',
    props: ['value'],
    template: '<div class="panel" :data-value="value"><slot /></div>',
  },
  AccordionHeader: {
    name: 'AccordionHeader',
    template: '<div class="header"><slot /></div>',
  },
  AccordionContent: {
    name: 'AccordionContent',
    template: '<div class="content"><slot /></div>',
  },
  FolhaIndividualBloco: {
    name: 'FolhaIndividualBloco',
    props: ['bloco', 'salvandoItem', 'salvandoPremio'],
    emits: ['salvar-item', 'salvar-premio'],
    template: `<div class="bloco" :data-id="bloco.id">
      <span class="salvando">{{ salvandoItem }}</span>
      <button class="item" @click="$emit('salvar-item', 1, '2026-09-05')" />
      <button class="premio" @click="$emit('salvar-premio', '2026-09-10')" />
    </div>`,
  },
  FolhaIndividualObservacoes: {
    name: 'FolhaIndividualObservacoes',
    props: ['texto', 'salvando'],
    emits: ['salvar'],
    template: '<div class="obs"><span class="obs-texto">{{ texto }}</span><button class="obs-btn" @click="$emit(\'salvar\', texto + \'!\')" /></div>',
  },
}

function props(sobre: Partial<ConstructorParameters<typeof FolhaIndividualManual>[0]> = {}) {
  return { manual: MANUAL, ...sobre }
}

describe('FolhaIndividualManual', () => {
  it('agrupa as seções, os blocos e a seção de observações', () => {
    const wrapper = mount(FolhaIndividualManual, { props: props(), global: { stubs } })

    expect(wrapper.text()).toContain('Progresso')
    expect(wrapper.text()).toContain('Observações')
    expect(wrapper.findAll('.bloco')).toHaveLength(2)
    expect(wrapper.find('.obs').exists()).toBe(true)
    expect(wrapper.find('.obs-texto').text()).toBe('Falta decorar o versículo.')
  })

  it('não renderiza blocos nas seções de observações', () => {
    const manual: ManualFolha = {
      ...MANUAL,
      secoes: [{ id: 's2', nome: 'Observações', ordem: 1, tipo: 'observacoes', blocos: [bloco('b-orfao', 'Ignorado')] }],
    }
    const wrapper = mount(FolhaIndividualManual, {
      props: props({ manual }),
      global: { stubs },
    })

    expect(wrapper.findAll('.bloco')).toHaveLength(0)
    expect(wrapper.find('.obs').exists()).toBe(true)
  })

  it('repassa o bloco correto em salvar-item e salvar-premio', async () => {
    const wrapper = mount(FolhaIndividualManual, { props: props(), global: { stubs } })

    await wrapper.findAll('.bloco')[1]!.find('.item').trigger('click')
    await wrapper.findAll('.bloco')[0]!.find('.premio').trigger('click')

    expect(wrapper.emitted('salvar-item')?.[0]).toEqual(['b2', 1, '2026-09-05'])
    expect(wrapper.emitted('salvar-premio')?.[0]).toEqual(['b1', '2026-09-10'])
  })

  it('repassa o manual em salvar-observacao', async () => {
    const wrapper = mount(FolhaIndividualManual, { props: props(), global: { stubs } })

    await wrapper.find('.obs-btn').trigger('click')

    expect(wrapper.emitted('salvar-observacao')?.[0]).toEqual(['m1', 'Falta decorar o versículo.!'])
  })

  it('informa ao bloco apenas o item em salvamento correspondente', () => {
    const wrapper = mount(FolhaIndividualManual, {
      props: props({ salvandoItem: 'b2:3' }),
      global: { stubs },
    })

    const blocos = wrapper.findAll('.bloco')
    expect(blocos[0]!.find('.salvando').text()).toBe('')
    expect(blocos[1]!.find('.salvando').text()).toBe('3')
  })

  it('repassa salvandoPremio apenas para o bloco correspondente', () => {
    const wrapper = mount(FolhaIndividualManual, {
      props: props({ salvandoPremio: 'b1' }),
      global: { stubs },
    })

    const blocos = wrapper.findAll('.bloco')
    expect(blocos[0]!.findComponent({ name: 'FolhaIndividualBloco' }).props('salvandoPremio')).toBe(true)
    expect(blocos[1]!.findComponent({ name: 'FolhaIndividualBloco' }).props('salvandoPremio')).toBe(false)
  })

  it('inicia com a primeira seção aberta e permite abrir várias ao mesmo tempo', () => {
    const wrapper = mount(FolhaIndividualManual, { props: props(), global: { stubs } })

    const accordion = wrapper.findComponent({ name: 'Accordion' })
    expect(accordion.props('value')).toEqual(['s1'])
    expect(accordion.props('multiple')).toBe(true)
  })

  it('mostra a contagem de itens concluídos no cabeçalho das seções de itens', () => {
    const wrapper = mount(FolhaIndividualManual, { props: props(), global: { stubs } })

    const contagens = wrapper.findAll('.secao-contagem')
    expect(contagens).toHaveLength(1)
    expect(contagens[0]!.text()).toBe('0/2')
  })

  it('reflete os itens concluídos na contagem do cabeçalho', () => {
    const manual: ManualFolha = {
      ...MANUAL,
      secoes: [
        {
          id: 's1',
          nome: 'Progresso',
          ordem: 1,
          tipo: 'itens',
          blocos: [
            { ...bloco('b1', 'Grau'), itens: [{ item_num: 1, data_conclusao: '2026-09-01' }] },
            { ...bloco('b2', 'Atividades'), itens: [{ item_num: 1, data_conclusao: null }] },
          ],
        },
      ],
    }
    const wrapper = mount(FolhaIndividualManual, { props: props({ manual }), global: { stubs } })

    expect(wrapper.find('.secao-contagem').text()).toBe('1/2')
  })
})
