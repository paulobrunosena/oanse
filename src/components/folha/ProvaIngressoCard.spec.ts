import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ProvaIngressoCard from './ProvaIngressoCard.vue'
import type { Database } from '@/types/database.types'

type LicaoRow = Database['public']['Tables']['prova_ingresso_licoes']['Row']

const stubs = {
  InputText: {
    name: 'InputText',
    props: ['modelValue', 'type', 'disabled', 'ariaLabel'],
    emits: ['update:modelValue'],
    template: '<input class="data" type="date" :value="modelValue" :disabled="disabled" :aria-label="ariaLabel" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
}

function licao(sobre: Partial<LicaoRow> = {}): LicaoRow {
  return {
    id: 'l1',
    visitante_id: 'v1',
    licao: 1,
    concluida: true,
    data_conclusao: '2026-09-06',
    registrado_por: 'u1',
    ...sobre,
  }
}

describe('ProvaIngressoCard', () => {
  it('abre uma linha para cada uma das 10 lições', () => {
    const wrapper = mount(ProvaIngressoCard, { props: { licoes: [] }, global: { stubs } })

    expect(wrapper.findAll('input[type="date"]')).toHaveLength(10)
    expect(wrapper.text()).toContain('Lição 1')
    expect(wrapper.text()).toContain('Lição 10')
  })

  it('marca a bolinha da lição concluída e preenche a data', () => {
    const wrapper = mount(ProvaIngressoCard, {
      props: { licoes: [licao()] },
      global: { stubs },
    })

    const bolinhas = wrapper.findAll('span.flex.h-6.w-6')
    expect(bolinhas[0]!.classes()).toContain('bg-primary')
    expect(bolinhas[1]!.classes()).toContain('border-surface-300')
    expect(wrapper.findAll('input[type="date"]')[0]!.attributes('value')).toBe('2026-09-06')
  })

  it('emite salvar-licao com a data concluída', async () => {
    const wrapper = mount(ProvaIngressoCard, { props: { licoes: [] }, global: { stubs } })

    await wrapper.findAll('input[type="date"]')[2]!.setValue('2026-09-08')

    expect(wrapper.emitted('salvar-licao')?.[0]).toEqual([3, '2026-09-08'])
  })

  it('emite salvar-licao com null ao limpar a data', async () => {
    const wrapper = mount(ProvaIngressoCard, { props: { licoes: [licao()] }, global: { stubs } })

    await wrapper.findAll('input[type="date"]')[0]!.setValue('')

    expect(wrapper.emitted('salvar-licao')?.[0]).toEqual([1, null])
  })

  it('desabilita apenas a lição em salvamento', () => {
    const wrapper = mount(ProvaIngressoCard, {
      props: { licoes: [licao(), licao({ licao: 2, data_conclusao: '2026-09-07' })], salvando: 2 },
      global: { stubs },
    })

    const inputs = wrapper.findAll('input[type="date"]')
    expect(inputs[0]!.attributes('disabled')).toBeUndefined()
    expect(inputs[1]!.attributes('disabled')).toBeDefined()
  })
})
