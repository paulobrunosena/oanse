import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { podeAdicionarTime, podeLancarResultado } from '@/utils/jogos'
import { useJogos } from './useJogos'

const JOGOS = [
  {
    id: 'j1',
    nome: 'Corrida de obstáculos',
    criado_por: 'p1',
    jogos_clubes: [{ clube_id: 'c1', clubes: { nome: 'Faíscas', slug: 'faiscas', cor: '#EAB308' } }],
    jogo_times: [
      {
        id: 't1', nome: 'Amarelos', cor: 'amarelo', lider_id: null,
        jogo_time_integrantes: [{ oansista_id: 'o1', oansistas: { nome: 'Ana' } }],
        jogo_resultados: [{ id: 'r1', colocacao: 1, desclassificado: false, pontos: 100 }],
      },
      {
        id: 't2', nome: 'Azuis', cor: 'azul', lider_id: null,
        jogo_time_integrantes: [],
        jogo_resultados: [],
      },
    ],
  },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useJogos', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase({
      jogos: () => builder(JOGOS),
      jogo_times: () => builder({ id: 't3' }),
    })
  })

  describe('carregar', () => {
    it('normaliza jogos, clubes, times, integrantes e resultados', async () => {
      const jogos = useJogos()
      await jogos.carregar('e1')

      expect(jogos.jogos.value).toHaveLength(1)
      const jogo = jogos.jogos.value[0]!
      expect(jogo.nome).toBe('Corrida de obstáculos')
      expect(jogo.clubes).toEqual([{ clube_id: 'c1', nome: 'Faíscas', slug: 'faiscas', cor: '#EAB308' }])
      expect(jogo.times).toHaveLength(2)
      expect(jogo.times[0]!.integrantes).toEqual([{ oansista_id: 'o1', nome: 'Ana' }])
      expect(jogo.times[0]!.resultado).toEqual({ id: 'r1', colocacao: 1, desclassificado: false, pontos: 100 })
      expect(jogo.times[1]!.resultado).toBeNull()
      expect(jogos.carregando.value).toBe(false)
    })

    it('filtra pelo encontro', async () => {
      const jogos = useJogos()
      await jogos.carregar('e1')
      expect(mocks.supabase.builderDe('jogos').eq).toHaveBeenCalledWith('encontro_id', 'e1')
    })
  })

  describe('criarJogo', () => {
    it('chama a RPC fn_criar_jogo e recarrega a lista', async () => {
      mocks.supabase.rpc.mockResolvedValue({ data: { id: 'j2' }, error: null })
      const jogos = useJogos()
      await jogos.carregar('e1')
      const id = await jogos.criarJogo('Caça ao tesouro', ['c1', 'c2'], 'p1')

      expect(id).toBe('j2')
      expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_criar_jogo', {
        p_encontro_id: 'e1',
        p_nome: 'Caça ao tesouro',
        p_clubes: ['c1', 'c2'],
        p_criado_por: 'p1',
      })
      expect(mocks.supabase.builderDe('jogos').eq).toHaveBeenCalledWith('encontro_id', 'e1')
    })

    it('lança erro quando a RPC falha', async () => {
      mocks.supabase.rpc.mockResolvedValue({ data: null, error: { message: 'Apenas o diretor de um clube participante pode criar o jogo' } })
      const jogos = useJogos()
      await jogos.carregar('e1')
      await expect(jogos.criarJogo('X', ['c1'], 'p1')).rejects.toThrow('Apenas o diretor de um clube participante pode criar o jogo')
    })
  })

  describe('criarTime', () => {
    it('insere o time e retorna o id', async () => {
      const jogos = useJogos()
      const id = await jogos.criarTime('j1', 'Verdes', 'verde')
      expect(id).toBe('t3')
      const times = mocks.supabase.builderDe('jogo_times')
      expect(times.insert).toHaveBeenCalledWith({ jogo_id: 'j1', nome: 'Verdes', cor: 'verde' })
    })
  })

  describe('lancarResultado', () => {
    it('faz upsert em jogo_resultados com onConflict por jogo+time', async () => {
      const jogos = useJogos()
      await jogos.lancarResultado('j1', 't2', { colocacao: 2, desclassificado: false })
      const resultados = mocks.supabase.builderDe('jogo_resultados')
      expect(resultados.upsert).toHaveBeenCalledWith(
        { jogo_id: 'j1', time_id: 't2', colocacao: 2, desclassificado: false },
        { onConflict: 'jogo_id,time_id' },
      )
    })
  })

  describe('validações (RN: 2 a 4 times)', () => {
    it('permite adicionar time até o 4º e bloqueia o 5º', () => {
      expect(podeAdicionarTime(4)).toBe(false)
      expect(podeAdicionarTime(3)).toBe(true)
    })

    it('exige no mínimo 2 times para lançar o placar', () => {
      expect(podeLancarResultado(1)).toBe(false)
      expect(podeLancarResultado(2)).toBe(true)
    })
  })
})