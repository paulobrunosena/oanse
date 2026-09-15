import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import FolhaIndividualView from './FolhaIndividualView.vue'
import { useAuthStore, type Profile } from '@/stores/auth'
import { builder, clienteSupabase } from '../../../tests/helpers/supabase'

const PERFIL = { id: 'u1', nome: 'Diretor Faíscas', role: 'diretor_clube', clube_id: 'c1', ativo: true } as unknown as Profile

const MANUAIS = [
  { id: 'm1', clube_id: 'c1', nome: 'Saltador', ordem: 1, created_at: '2026-09-01T00:00:00Z' },
  { id: 'm2', clube_id: 'c1', nome: 'Caminhante', ordem: 2, created_at: '2026-09-01T00:00:00Z' },
]

const SECOES = [
  { id: 's1', manual_id: 'm1', nome: 'Progresso', ordem: 1, tipo: 'itens' },
]

const BLOCOS = [
  { id: 'b1', secao_id: 's1', nome: 'Trilha do grau', ordem: 1, quantidade: 2, premio_nome: 'Distintivo do grau' },
]

const OANSISTAS = [
  { id: 'o1', nome: 'Davi Rocha', clube_id: 'c1' },
  { id: 'o2', nome: 'Laura Castro', clube_id: 'c1' },
]

const ITEM_PROGRESSO = {
  id: 'ip1', oansista_id: 'o1', bloco_id: 'b1', item_num: 1,
  data_conclusao: '2026-09-05', registrado_por: 'u1', created_at: '2026-09-05T00:00:00Z',
}

const OBSERVACAO = {
  id: 'ob1', oansista_id: 'o1', manual_id: 'm1', texto: 'texto',
  updated_at: '2026-09-10T00:00:00Z',
}

const mocks = vi.hoisted(() => ({ supabase: null as any, toast: vi.fn() }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))
vi.mock('@/composables/useToast', () => ({
  useToast: () => ({ add: mocks.toast }),
}))

const stubs = {
  Card: { name: 'Card', template: '<div class="card"><slot name="content" /></div>' },
  Tabs: { name: 'Tabs', props: ['value'], template: '<div class="tabs"><slot /></div>' },
  TabList: { name: 'TabList', template: '<div class="tablist"><slot /></div>' },
  Tab: { name: 'Tab', props: ['value'], template: '<div class="tab">{{ value }}</div>' },
  TabPanels: { name: 'TabPanels', template: '<div class="tabpanels"><slot /></div>' },
  TabPanel: { name: 'TabPanel', props: ['value'], template: '<div class="tabpanel"><slot /></div>' },
  FolhaIndividualSeletor: { name: 'FolhaIndividualSeletor', template: '<div class="seletor" />' },
  FolhaIndividualManual: {
    name: 'FolhaIndividualManual',
    props: ['manual', 'salvandoItem', 'salvandoObservacao'],
    emits: ['salvar-item', 'salvar-observacao'],
    template: `<div class="manual" :data-id="manual.id">
      <span class="manual-nome">{{ manual.nome }}</span>
      <button class="btn-item" @click="$emit('salvar-item', 'b1', 1, '2026-09-05')" />
      <button class="btn-obs" @click="$emit('salvar-observacao', 'm1', 'texto')" />
    </div>`,
  },
}

function montar() {
  const store = useAuthStore()
  store.setUser({ sub: 'u1' })
  store.profile = PERFIL
  return mount(FolhaIndividualView, {
    global: { stubs },
  })
}

describe('FolhaIndividualView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mocks.supabase = clienteSupabase({
      oansistas: () => builder(OANSISTAS),
      folha_manuais: () => builder(MANUAIS),
      folha_secoes: () => builder(SECOES),
      folha_blocos: () => builder(BLOCOS),
      folha_item_progresso: () => builder([]),
      folha_premio_progresso: () => builder([]),
      folha_observacoes: () => builder([]),
    })
  })

  it('carrega o catálogo do clube, seleciona a primeira criança e monta as abas', async () => {
    const wrapper = montar()
    await flushPromises()

    expect(mocks.supabase.builderDe('folha_manuais').eq).toHaveBeenCalledWith('clube_id', 'c1')
    expect(mocks.supabase.builderDe('oansistas').eq).toHaveBeenCalledWith('clube_id', 'c1')
    expect(mocks.supabase.builderDe('folha_item_progresso').eq).toHaveBeenCalledWith('oansista_id', 'o1')
    expect(wrapper.text()).toContain('Folha Individual')
    expect(wrapper.findAll('.manual')).toHaveLength(2)
    expect(wrapper.findAll('.manual')[0]!.text()).toContain('Saltador')
  })

  it('mostra aviso quando o perfil não está vinculado a um clube', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    store.profile = { ...PERFIL, clube_id: null } as unknown as Profile

    const wrapper = mount(FolhaIndividualView, { global: { stubs } })
    await flushPromises()

    expect(wrapper.text()).toContain('Você não está vinculado a um clube')
    expect(mocks.supabase.builderDe('folha_manuais').eq).not.toHaveBeenCalled()
  })

  it('mostra aviso quando o clube não tem manuais', async () => {
    mocks.supabase = clienteSupabase({
      oansistas: () => builder(OANSISTAS),
      folha_manuais: () => builder([]),
    })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Nenhum manual da Folha Individual cadastrado')
  })

  it('mostra aviso quando o clube não tem crianças ativas', async () => {
    mocks.supabase = clienteSupabase({
      oansistas: () => builder([]),
      folha_manuais: () => builder(MANUAIS),
      folha_secoes: () => builder(SECOES),
      folha_blocos: () => builder(BLOCOS),
    })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Nenhuma criança ativa neste clube')
  })

  it('líder carrega apenas os oansistas da sua turma', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    store.profile = { ...PERFIL, role: 'lider' } as unknown as Profile

    mocks.supabase = clienteSupabase({
      turmas: () => builder({ id: 't1' }),
      oansistas: () => builder(OANSISTAS),
      folha_manuais: () => builder(MANUAIS),
      folha_secoes: () => builder(SECOES),
      folha_blocos: () => builder(BLOCOS),
      folha_item_progresso: () => builder([]),
      folha_premio_progresso: () => builder([]),
      folha_observacoes: () => builder([]),
    })

    const wrapper = mount(FolhaIndividualView, { global: { stubs } })
    await flushPromises()

    expect(mocks.supabase.builderDe('turmas').eq).toHaveBeenCalledWith('lider_id', 'u1')
    expect(mocks.supabase.builderDe('oansistas').eq).toHaveBeenCalledWith('turma_id', 't1')
    expect(mocks.supabase.builderDe('oansistas').eq).not.toHaveBeenCalledWith('clube_id', 'c1')
    expect(wrapper.findAll('.manual')).toHaveLength(2)
  })

  it('líder sem turma vê o aviso de turma vazia', async () => {
    const store = useAuthStore()
    store.setUser({ sub: 'u1' })
    store.profile = { ...PERFIL, role: 'lider' } as unknown as Profile

    mocks.supabase = clienteSupabase({
      turmas: () => builder(null),
      oansistas: () => builder([]),
      folha_manuais: () => builder(MANUAIS),
      folha_secoes: () => builder(SECOES),
      folha_blocos: () => builder(BLOCOS),
    })

    const wrapper = mount(FolhaIndividualView, { global: { stubs } })
    await flushPromises()

    expect(wrapper.text()).toContain('Nenhuma criança ativa na sua turma.')
    expect(mocks.supabase.builderDe('oansistas').eq).not.toHaveBeenCalledWith('clube_id', 'c1')
  })

  it('encaminha salvar-item para o composable com o registrante', async () => {
    const bItens = builder<unknown>([])
    bItens.singleData = ITEM_PROGRESSO
    mocks.supabase = clienteSupabase({
      oansistas: () => builder(OANSISTAS),
      folha_manuais: () => builder(MANUAIS),
      folha_secoes: () => builder(SECOES),
      folha_blocos: () => builder(BLOCOS),
      folha_item_progresso: () => bItens,
    })

    const wrapper = montar()
    await flushPromises()
    await wrapper.find('.btn-item').trigger('click')
    await flushPromises()

    expect(bItens.upsert).toHaveBeenCalledWith(
      {
        oansista_id: 'o1',
        bloco_id: 'b1',
        item_num: 1,
        data_conclusao: '2026-09-05',
        registrado_por: 'u1',
      },
      { onConflict: 'oansista_id,bloco_id,item_num' },
    )
  })

  it('encaminha salvar-observacao e mostra o toast de sucesso', async () => {
    const bObs = builder<unknown>([])
    bObs.singleData = OBSERVACAO
    mocks.supabase = clienteSupabase({
      oansistas: () => builder(OANSISTAS),
      folha_manuais: () => builder(MANUAIS),
      folha_secoes: () => builder(SECOES),
      folha_blocos: () => builder(BLOCOS),
      folha_observacoes: () => bObs,
    })

    const wrapper = montar()
    await flushPromises()
    await wrapper.find('.btn-obs').trigger('click')
    await flushPromises()

    expect(bObs.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ oansista_id: 'o1', manual_id: 'm1', texto: 'texto' }),
      { onConflict: 'oansista_id,manual_id' },
    )
    expect(mocks.toast).toHaveBeenCalledWith(expect.objectContaining({ title: 'Observações salvas' }))
  })
})
