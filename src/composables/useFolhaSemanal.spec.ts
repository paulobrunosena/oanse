import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useFolhaSemanal, type FormFolha } from './useFolhaSemanal'

const ITENS = [
  { id: 'i1', chave: 'presenca', pontos: 10, ativo: true },
  { id: 'i2', chave: 'uniforme', pontos: 5, ativo: true },
  { id: 'i3', chave: 'secao_sem_ajuda', pontos: 10, ativo: true },
]

const FOLHAS = [
  { id: 'f1', encontro_id: 'e1', oansista_id: 'o1', presenca_id: 'p1', registrado_por: 'u1', uniforme: true, biblia: false, ebd: false, manual: false, conduta: false, leitura_biblica: false, visitantes_convidados: 0, secoes_sem_ajuda: 2, secoes_com_ajuda: 0, cor_time: 'verde', atividade_extra: 0, total: 29, pontos_jogos: 0, posicao_jogos: null },
]

function form(): FormFolha {
  return { uniforme: true, biblia: false, ebd: false, manual: false, conduta: false, leitura_biblica: false, visitantes_convidados: 0, secoes_sem_ajuda: 2, secoes_com_ajuda: 0, atividade_extra: 0 }
}

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useFolhaSemanal', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase({
      itens_pontuacao: () => builder(ITENS),
      folhas_semanais: () => builder(FOLHAS),
    })
  })

  describe('carregar', () => {
    it('carrega itens ativos e folhas do encontro', async () => {
      const folha = useFolhaSemanal()
      await folha.carregar('e1', ['o1'])

      expect(folha.itens.value).toEqual(ITENS)
      expect(folha.folhas.value).toEqual(FOLHAS)
      expect(folha.carregando.value).toBe(false)
      expect(mocks.supabase.builderDe('itens_pontuacao').eq).toHaveBeenCalledWith('ativo', true)
    })

    it('carrega apenas os itens quando não há oansistas', async () => {
      const folha = useFolhaSemanal()
      await folha.carregar('e1', [])

      expect(folha.folhas.value).toEqual([])
      expect(folha.itens.value).toEqual(ITENS)
    })

    it('expõe o mapa de pontos por chave', async () => {
      const folha = useFolhaSemanal()
      await folha.carregar('e1', ['o1'])

      expect(folha.pontos.value.presenca).toBe(10)
      expect(folha.pontos.value.uniforme).toBe(5)
      expect(folha.pontos.value.secao_sem_ajuda).toBe(10)
    })
  })

  describe('folhaDe', () => {
    it('retorna a folha do oansista quando existe', async () => {
      const folha = useFolhaSemanal()
      await folha.carregar('e1', ['o1'])
      expect(folha.folhaDe('o1')?.id).toBe('f1')
      expect(folha.folhaDe('inexistente')).toBeUndefined()
    })
  })

  describe('salvar', () => {
    it('atualiza a folha existente e devolve a versão persistida', async () => {
      const folha = useFolhaSemanal()
      await folha.carregar('e1', ['o1'])

      const atualizada = { ...FOLHAS[0], biblia: true, total: 34 }
      const bFolhas = mocks.supabase.builderDe('folhas_semanais')
      bFolhas.singleData = atualizada

      const retornada = await folha.salvar('e1', 'o1', 'p1', 'u1', form())

      expect(retornada).toEqual(atualizada)
      expect(bFolhas.update).toHaveBeenCalledWith(form())
      expect(bFolhas.eq).toHaveBeenCalledWith('id', 'f1')
    })

    it('insere uma folha nova quando o oansista não tem folha', async () => {
      mocks.supabase = clienteSupabase({
        itens_pontuacao: () => builder(ITENS),
        folhas_semanais: () => builder([]),
      })
      const folha = useFolhaSemanal()
      await folha.carregar('e1', ['o1'])

      const nova = { id: 'f2', encontro_id: 'e1', oansista_id: 'o9', presenca_id: 'p9', registrado_por: 'u1', uniforme: true, biblia: false, ebd: false, manual: false, conduta: false, leitura_biblica: false, visitantes_convidados: 0, secoes_sem_ajuda: 2, secoes_com_ajuda: 0, cor_time: null, atividade_extra: 0, total: 29, pontos_jogos: 0, posicao_jogos: null }
      const bFolhas = mocks.supabase.builderDe('folhas_semanais')
      bFolhas.singleData = nova

      const retornada = await folha.salvar('e1', 'o9', 'p9', 'u1', form())

      expect(retornada).toEqual(nova)
      expect(bFolhas.insert).toHaveBeenCalledWith(expect.objectContaining({ encontro_id: 'e1', oansista_id: 'o9', presenca_id: 'p9', registrado_por: 'u1' }))
      expect(folha.folhas.value).toContainEqual(nova)
    })

    it('propaga o erro do banco ao atualizar', async () => {
      const folha = useFolhaSemanal()
      await folha.carregar('e1', ['o1'])

      const bFolhas = mocks.supabase.builderDe('folhas_semanais')
      bFolhas.error = new Error('falha no banco')

      await expect(folha.salvar('e1', 'o1', 'p1', 'u1', form())).rejects.toThrow('falha no banco')
    })
  })
})
