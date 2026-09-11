import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import FolhaIndividualBloco from './FolhaIndividualBloco.vue'
import type { BlocoFolha } from '@/utils/folhaIndividual'

const stubs = {
  InputText: {
    name: 'InputText',
    props: ['modelValue', 'type', 'disabled', 'ariaLabel'],
    emits: ['update:modelValue'],
    template: '<input class="input" :type="type" :value="modelValue" :disabled="disabled" :aria-label="ariaLabel" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
  Tag: {
    name: 'Tag',
    props: ['value', 'severity'],
    template: '<span class="tag">{{ value }}</span>',
  },
}

function bloco(sobre: Partial<BlocoFolha> = {}): BlocoFolha {
  return {
    id: 'b1',
    nome: 'Exercício bíblico 01',
    ordem: 1,
    quantidade: 2,
    premio_nome: 'Botão vermelho 01',
    itens: [
      { item_num: 1, data_conclusao: null },
      { item_num: 2, data_conclusao: null },
    ],
    premioData: null,
    ...sobre,
  }
}

function props(sobre: Partial<ConstructorParameters<typeof FolhaIndividualBloco>[0]> = {}) {
  return { bloco: bloco(), ...sobre }
}

describe('FolhaIndividualBloco', () => {
  it('abre uma linha por item com o rótulo derivado do bloco', () => {
    const wrapper = mount(FolhaIndividualBloco, { props: props(), global: { stubs } })

    expect(wrapper.findAll('input[type="date"]')).toHaveLength(3)
    expect(wrapper.text()).toContain('Exercício bíblico 1')
    expect(wrapper.text()).toContain('Exercício bíblico 2')
  })

  it('mostra o progresso de itens concluídos do bloco', () => {
    const wrapper = mount(FolhaIndividualBloco, {
      props: props({
        bloco: bloco({
          itens: [
            { item_num: 1, data_conclusao: '2026-09-01' },
            { item_num: 2, data_conclusao: null },
          ],
        }),
      }),
      global: { stubs },
    })

    expect(wrapper.find('.tag').text()).toBe('1 / 2')
  })

  it('marca a bolinha do item concluído', () => {
    const wrapper = mount(FolhaIndividualBloco, {
      props: props({
        bloco: bloco({
          itens: [
            { item_num: 1, data_conclusao: '2026-09-01' },
            { item_num: 2, data_conclusao: null },
          ],
        }),
      }),
      global: { stubs },
    })

    const bolinhas = wrapper.findAll('span.flex.h-6.w-6')
    expect(bolinhas[0]!.classes()).toContain('bg-primary')
    expect(bolinhas[1]!.classes()).toContain('border-surface-300')
  })

  it('emite salvar-item com a data digitada', async () => {
    const wrapper = mount(FolhaIndividualBloco, { props: props(), global: { stubs } })

    await wrapper.findAll('input[type="date"]')[0]!.setValue('2026-09-05')

    expect(wrapper.emitted('salvar-item')?.[0]).toEqual([1, '2026-09-05'])
  })

  it('emite salvar-item com null ao limpar a data', async () => {
    const wrapper = mount(FolhaIndividualBloco, {
      props: props({
        bloco: bloco({
          itens: [
            { item_num: 1, data_conclusao: '2026-09-01' },
            { item_num: 2, data_conclusao: null },
          ],
        }),
      }),
      global: { stubs },
    })

    await wrapper.findAll('input[type="date"]')[0]!.setValue('')

    expect(wrapper.emitted('salvar-item')?.[0]).toEqual([1, null])
  })

  it('desabilita apenas o item em salvamento', () => {
    const wrapper = mount(FolhaIndividualBloco, {
      props: props({ salvandoItem: 2 }),
      global: { stubs },
    })

    const inputs = wrapper.findAll('input[type="date"]')
    expect(inputs[0]!.attributes('disabled')).toBeUndefined()
    expect(inputs[1]!.attributes('disabled')).toBeDefined()
  })

  it('mantém o prêmio bloqueado enquanto o bloco não está completo', () => {
    const wrapper = mount(FolhaIndividualBloco, { props: props(), global: { stubs } })

    const premio = wrapper.findAll('input[type="date"]')[2]!
    expect(premio.attributes('disabled')).toBeDefined()
    expect(wrapper.text()).toContain('Conclua todos os itens para liberar o prêmio.')
    expect(wrapper.text()).toContain('Botão vermelho 01')
  })

  it('libera o prêmio com o bloco completo e emite salvar-premio', async () => {
    const wrapper = mount(FolhaIndividualBloco, {
      props: props({
        bloco: bloco({
          itens: [
            { item_num: 1, data_conclusao: '2026-09-01' },
            { item_num: 2, data_conclusao: '2026-09-02' },
          ],
        }),
      }),
      global: { stubs },
    })

    const premio = wrapper.findAll('input[type="date"]')[2]!
    expect(premio.attributes('disabled')).toBeUndefined()
    expect(wrapper.text()).not.toContain('Conclua todos os itens para liberar o prêmio.')

    await premio.setValue('2026-09-10')
    expect(wrapper.emitted('salvar-premio')?.[0]).toEqual(['2026-09-10'])
  })

  it('bloqueia o prêmio durante o salvamento', () => {
    const wrapper = mount(FolhaIndividualBloco, {
      props: props({
        salvandoPremio: true,
        bloco: bloco({
          itens: [
            { item_num: 1, data_conclusao: '2026-09-01' },
            { item_num: 2, data_conclusao: '2026-09-02' },
          ],
        }),
      }),
      global: { stubs },
    })

    expect(wrapper.findAll('input[type="date"]')[2]!.attributes('disabled')).toBeDefined()
  })
})
