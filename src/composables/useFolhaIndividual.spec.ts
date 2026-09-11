import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useFolhaIndividual } from './useFolhaIndividual'

const MANUAIS = [
  { id: 'm1', clube_id: 'c1', nome: 'Saltador', ordem: 1, created_at: '2026-09-01T00:00:00Z' },
  { id: 'm2', clube_id: 'c1', nome: 'Caminhante', ordem: 2, created_at: '2026-09-01T00:00:00Z' },
]

const SECOES = [
  { id: 's1', manual_id: 'm1', nome: 'Progresso', ordem: 1, tipo: 'itens' },
  { id: 's2', manual_id: 'm1', nome: 'Observações', ordem: 2, tipo: 'observacoes' },
]

const BLOCOS = [
  { id: 'b1', secao_id: 's1', nome: 'Grau', ordem: 1, quantidade: 2, premio_nome: 'Distintivo do grau' },
]

const ITENS = [
  { id: 'i1', oansista_id: 'o1', bloco_id: 'b1', item_num: 1, data_conclusao: '2026-09-01', registrado_por: 'u1', created_at: '2026-09-01T00:00:00Z' },
]

const PREMIOS = [
  { id: 'pr1', oansista_id: 'o1', bloco_id: 'b1', data_recebimento: '2026-09-02', registrado_por: 'u1', created_at: '2026-09-02T00:00:00Z' },
]

const OBSERVACOES = [
  { id: 'ob1', oansista_id: 'o1', manual_id: 'm1', texto: 'Falta decorar o versículo.', updated_at: '2026-09-01T00:00:00Z' },
]

function clienteComCatalogo() {
  return clienteSupabase({
    folha_manuais: () => builder(MANUAIS),
    folha_secoes: () => builder(SECOES),
    folha_blocos: () => builder(BLOCOS),
    folha_item_progresso: () => builder(ITENS),
    folha_premio_progresso: () => builder(PREMIOS),
    folha_observacoes: () => builder(OBSERVACOES),
  })
}

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useFolhaIndividual', () => {
  beforeEach(() => {
    mocks.supabase = clienteComCatalogo()
  })

  describe('carregar', () => {
    it('carrega o catálogo do clube em cascata e normaliza a árvore', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')

      const bManuais = mocks.supabase.builderDe('folha_manuais')
      expect(bManuais.eq).toHaveBeenCalledWith('clube_id', 'c1')
      expect(bManuais.order).toHaveBeenCalledWith('ordem')
      expect(mocks.supabase.builderDe('folha_secoes').in).toHaveBeenCalledWith('manual_id', ['m1', 'm2'])
      expect(mocks.supabase.builderDe('folha_secoes').order).toHaveBeenCalledWith('ordem')
      expect(mocks.supabase.builderDe('folha_blocos').in).toHaveBeenCalledWith('secao_id', ['s1', 's2'])
      expect(api.carregando.value).toBe(false)

      expect(api.folha.value.map(m => m.nome)).toEqual(['Saltador', 'Caminhante'])
      expect(api.folha.value[0].secoes.map(s => s.nome)).toEqual(['Progresso', 'Observações'])
      expect(api.folha.value[0].secoes[0].blocos[0]).toMatchObject({
        id: 'b1',
        quantidade: 2,
        premio_nome: 'Distintivo do grau',
      })
      expect(api.folha.value[0].secoes[0].blocos[0].itens).toHaveLength(2)
      expect(api.folha.value[1].secoes).toEqual([])
    })

    it('não busca seções nem blocos quando o clube não tem manuais', async () => {
      mocks.supabase = clienteSupabase({ folha_manuais: () => builder([]) })
      const api = useFolhaIndividual()
      await api.carregar('c-vazio')

      expect(api.folha.value).toEqual([])
      expect(api.carregando.value).toBe(false)
      expect(mocks.supabase.builderDe('folha_secoes').in).not.toHaveBeenCalled()
      expect(mocks.supabase.builderDe('folha_blocos').in).not.toHaveBeenCalled()
    })

    it('não busca blocos quando o clube não tem seções', async () => {
      mocks.supabase = clienteSupabase({
        folha_manuais: () => builder(MANUAIS),
        folha_secoes: () => builder([]),
      })
      const api = useFolhaIndividual()
      await api.carregar('c1')

      expect(api.folha.value[0].secoes).toEqual([])
      expect(mocks.supabase.builderDe('folha_blocos').in).not.toHaveBeenCalled()
    })

    it('propaga o erro do banco e desliga o carregando', async () => {
      const api = useFolhaIndividual()
      mocks.supabase.builderDe('folha_manuais').error = new Error('falha no catálogo')

      await expect(api.carregar('c1')).rejects.toThrow('falha no catálogo')
      expect(api.carregando.value).toBe(false)
    })
  })

  describe('carregarProgresso', () => {
    it('carrega itens, prêmios e observações e aplica na árvore', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      expect(mocks.supabase.builderDe('folha_item_progresso').eq).toHaveBeenCalledWith('oansista_id', 'o1')
      expect(mocks.supabase.builderDe('folha_premio_progresso').eq).toHaveBeenCalledWith('oansista_id', 'o1')
      expect(mocks.supabase.builderDe('folha_observacoes').eq).toHaveBeenCalledWith('oansista_id', 'o1')
      expect(api.oansistaIdAtual.value).toBe('o1')
      expect(api.carregandoProgresso.value).toBe(false)

      const bloco = api.folha.value[0].secoes[0].blocos[0]
      expect(bloco.itens).toEqual([
        { item_num: 1, data_conclusao: '2026-09-01' },
        { item_num: 2, data_conclusao: null },
      ])
      expect(bloco.premioData).toBe('2026-09-02')
      expect(api.folha.value[0].observacoes).toBe('Falta decorar o versículo.')
    })

    it('limpa o progresso anterior ao trocar de oansista', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      mocks.supabase.builderDe('folha_item_progresso').data = []
      mocks.supabase.builderDe('folha_premio_progresso').data = []
      mocks.supabase.builderDe('folha_observacoes').data = []
      await api.carregarProgresso('o2')

      expect(api.oansistaIdAtual.value).toBe('o2')
      expect(api.folha.value[0].secoes[0].blocos[0].itens.every(i => i.data_conclusao === null)).toBe(true)
      expect(api.folha.value[0].secoes[0].blocos[0].premioData).toBeNull()
      expect(api.folha.value[0].observacoes).toBe('')
    })

    it('propaga o erro do banco e desliga o carregandoProgresso', async () => {
      const api = useFolhaIndividual()
      mocks.supabase.builderDe('folha_item_progresso').error = new Error('falha no progresso')

      await expect(api.carregarProgresso('o1')).rejects.toThrow('falha no progresso')
      expect(api.carregandoProgresso.value).toBe(false)
    })
  })

  describe('salvarItem', () => {
    it('faz upsert do item e atualiza o estado local', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      const bItens = mocks.supabase.builderDe('folha_item_progresso')
      bItens.singleData = { ...ITENS[0], data_conclusao: '2026-09-05' }

      await api.salvarItem('o1', 'b1', 1, '2026-09-05', 'u1')

      expect(bItens.upsert).toHaveBeenCalledWith(
        { oansista_id: 'o1', bloco_id: 'b1', item_num: 1, data_conclusao: '2026-09-05', registrado_por: 'u1' },
        { onConflict: 'oansista_id,bloco_id,item_num' },
      )
      expect(bItens.select).toHaveBeenCalled()
      expect(bItens.single).toHaveBeenCalled()
      expect(api.folha.value[0].secoes[0].blocos[0].itens[0].data_conclusao).toBe('2026-09-05')
    })

    it('insere o item na lista local quando ainda não havia registro', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      mocks.supabase.builderDe('folha_item_progresso').singleData = {
        id: 'i2',
        oansista_id: 'o1',
        bloco_id: 'b1',
        item_num: 2,
        data_conclusao: '2026-09-06',
        registrado_por: 'u1',
        created_at: '2026-09-06T00:00:00Z',
      }
      await api.salvarItem('o1', 'b1', 2, '2026-09-06', 'u1')

      expect(api.folha.value[0].secoes[0].blocos[0].itens[1].data_conclusao).toBe('2026-09-06')
    })

    it('remove o registro quando a data é null', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      const bItens = mocks.supabase.builderDe('folha_item_progresso')
      await api.salvarItem('o1', 'b1', 1, null, 'u1')

      expect(bItens.delete).toHaveBeenCalled()
      expect(bItens.eq).toHaveBeenCalledWith('oansista_id', 'o1')
      expect(bItens.eq).toHaveBeenCalledWith('bloco_id', 'b1')
      expect(bItens.eq).toHaveBeenCalledWith('item_num', 1)
      expect(bItens.upsert).not.toHaveBeenCalled()
      expect(api.folha.value[0].secoes[0].blocos[0].itens[0].data_conclusao).toBeNull()
    })

    it('propaga erro ao salvar e ao remover', async () => {
      const api = useFolhaIndividual()
      const bItens = mocks.supabase.builderDe('folha_item_progresso')
      bItens.error = new Error('falha ao salvar')

      await expect(api.salvarItem('o1', 'b1', 1, '2026-09-05', 'u1')).rejects.toThrow('falha ao salvar')
      await expect(api.salvarItem('o1', 'b1', 1, null, 'u1')).rejects.toThrow('falha ao salvar')
    })
  })

  describe('salvarPremio', () => {
    it('faz upsert do prêmio e atualiza o estado local', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      const bPremios = mocks.supabase.builderDe('folha_premio_progresso')
      bPremios.singleData = { ...PREMIOS[0], data_recebimento: '2026-09-10' }

      await api.salvarPremio('o1', 'b1', '2026-09-10', 'u1')

      expect(bPremios.upsert).toHaveBeenCalledWith(
        { oansista_id: 'o1', bloco_id: 'b1', data_recebimento: '2026-09-10', registrado_por: 'u1' },
        { onConflict: 'oansista_id,bloco_id' },
      )
      expect(api.folha.value[0].secoes[0].blocos[0].premioData).toBe('2026-09-10')
    })

    it('remove o prêmio quando a data é null', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      const bPremios = mocks.supabase.builderDe('folha_premio_progresso')
      await api.salvarPremio('o1', 'b1', null, 'u1')

      expect(bPremios.delete).toHaveBeenCalled()
      expect(bPremios.eq).toHaveBeenCalledWith('oansista_id', 'o1')
      expect(bPremios.eq).toHaveBeenCalledWith('bloco_id', 'b1')
      expect(bPremios.upsert).not.toHaveBeenCalled()
      expect(api.folha.value[0].secoes[0].blocos[0].premioData).toBeNull()
    })

    it('propaga erro ao salvar', async () => {
      const api = useFolhaIndividual()
      mocks.supabase.builderDe('folha_premio_progresso').error = new Error('falha no prêmio')

      await expect(api.salvarPremio('o1', 'b1', '2026-09-10', 'u1')).rejects.toThrow('falha no prêmio')
    })
  })

  describe('salvarObservacao', () => {
    it('faz upsert por (oansista, manual) e atualiza a árvore', async () => {
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      const bObs = mocks.supabase.builderDe('folha_observacoes')
      bObs.singleData = { ...OBSERVACOES[0], texto: 'Novo texto', updated_at: '2026-09-11T00:00:00Z' }

      await api.salvarObservacao('o1', 'm1', 'Novo texto')

      expect(bObs.upsert).toHaveBeenCalledWith(
        { oansista_id: 'o1', manual_id: 'm1', texto: 'Novo texto', updated_at: expect.any(String) },
        { onConflict: 'oansista_id,manual_id' },
      )
      expect(api.folha.value[0].observacoes).toBe('Novo texto')
    })

    it('insere a observação na lista local quando ainda não havia registro', async () => {
      mocks.supabase = clienteSupabase({
        folha_manuais: () => builder(MANUAIS),
        folha_secoes: () => builder(SECOES),
        folha_blocos: () => builder(BLOCOS),
        folha_item_progresso: () => builder([]),
        folha_premio_progresso: () => builder([]),
        folha_observacoes: () => builder([]),
      })
      const api = useFolhaIndividual()
      await api.carregar('c1')
      await api.carregarProgresso('o1')

      mocks.supabase.builderDe('folha_observacoes').singleData = {
        id: 'ob2',
        oansista_id: 'o1',
        manual_id: 'm1',
        texto: 'Primeira anotação',
        updated_at: '2026-09-11T00:00:00Z',
      }
      await api.salvarObservacao('o1', 'm1', 'Primeira anotação')

      expect(api.folha.value[0].observacoes).toBe('Primeira anotação')
    })

    it('propaga erro ao salvar', async () => {
      const api = useFolhaIndividual()
      mocks.supabase.builderDe('folha_observacoes').error = new Error('falha nas observações')

      await expect(api.salvarObservacao('o1', 'm1', 'x')).rejects.toThrow('falha nas observações')
    })
  })
})
