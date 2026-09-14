import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useVisitantes } from './useVisitantes'

const VISITANTES = [
  { id: 'v1', nome: 'Ana', data_nascimento: '2017-03-10', clube_id: 'c1', indicado_por: null, responsavel: 'Mãe', contato: '8199', status: 'em_visitas', data_cadastro: '2026-09-01', created_at: '2026-09-01T00:00:00Z', updated_at: '2026-09-01T00:00:00Z' },
  { id: 'v2', nome: 'Bia', data_nascimento: '2018-05-02', clube_id: 'c1', indicado_por: 'o1', responsavel: null, contato: null, status: 'prova_ingresso', data_cadastro: '2026-09-01', created_at: '2026-09-01T00:00:00Z', updated_at: '2026-09-01T00:00:00Z' },
]

const VISITAS = [
  { id: 'vs1', visitante_id: 'v1', numero: 1, data_visita: '2026-09-05', presente: true, observacao: null },
  { id: 'vs2', visitante_id: 'v1', numero: 2, data_visita: '2026-09-12', presente: false, observacao: null },
]

const LICOES = [
  { id: 'l1', visitante_id: 'v2', licao: 1, concluida: true, data_conclusao: '2026-09-06', registrado_por: 'u1' },
]

const OANSISTAS = [{ id: 'o1', nome: 'Carlos' }]
const TURMAS = [{ id: 't1', nome: 'Turma 1' }]

function cliente() {
  return clienteSupabase({
    visitantes: () => builder([...VISITANTES]),
    visitas: () => builder([...VISITAS]),
    prova_ingresso_licoes: () => builder([...LICOES]),
    oansistas: () => builder([...OANSISTAS]),
    turmas: () => builder([...TURMAS]),
  })
}

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useVisitantes', () => {
  beforeEach(() => {
    mocks.supabase = cliente()
  })

  describe('carregar', () => {
    it('carrega visitantes, oansistas e turmas e, em seguida, visitas e lições', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      expect(mocks.supabase.builderDe('visitantes').eq).toHaveBeenCalledWith('clube_id', 'c1')
      expect(mocks.supabase.builderDe('visitantes').order).toHaveBeenCalledWith('nome')
      expect(mocks.supabase.builderDe('visitas').in).toHaveBeenCalledWith('visitante_id', ['v1', 'v2'])
      expect(mocks.supabase.builderDe('prova_ingresso_licoes').in).toHaveBeenCalledWith('visitante_id', ['v1', 'v2'])

      expect(api.visitantes.value).toHaveLength(2)
      expect(api.oansistas.value).toEqual(OANSISTAS)
      expect(api.turmas.value).toEqual(TURMAS)
      expect(api.carregando.value).toBe(false)
    })

    it('agrupa visitas e lições por visitante', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      expect(api.visitasPorVisitante.value.get('v1')).toHaveLength(2)
      expect(api.visitasPorVisitante.value.get('v2')).toBeUndefined()
      expect(api.licoesPorVisitante.value.get('v2')).toHaveLength(1)
      expect(api.licoesPorVisitante.value.get('v1')).toBeUndefined()
    })

    it('não busca visitas nem lições quando não há visitantes', async () => {
      mocks.supabase = clienteSupabase({
        visitantes: () => builder([]),
        oansistas: () => builder(OANSISTAS),
        turmas: () => builder(TURMAS),
      })
      const api = useVisitantes()
      await api.carregar('c-vazio')

      expect(api.visitantes.value).toEqual([])
      expect(mocks.supabase.builderDe('visitas').in).not.toHaveBeenCalled()
      expect(mocks.supabase.builderDe('prova_ingresso_licoes').in).not.toHaveBeenCalled()
      expect(api.carregando.value).toBe(false)
    })

    it('propaga o erro do banco e desliga o carregando', async () => {
      const api = useVisitantes()
      mocks.supabase.builderDe('visitantes').error = new Error('falha ao listar')

      await expect(api.carregar('c1')).rejects.toThrow('falha ao listar')
      expect(api.carregando.value).toBe(false)
    })
  })

  describe('salvarVisitante', () => {
    it('insere um novo visitante e adiciona à lista local', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      const bVisitantes = mocks.supabase.builderDe('visitantes')
      bVisitantes.singleData = { ...VISITANTES[0], id: 'v3', nome: 'Clara' }

      const id = await api.salvarVisitante(
        { nome: 'Clara', data_nascimento: '2017-01-01', responsavel: null, contato: null, indicado_por: null, status: 'em_visitas' },
        'c1',
      )

      expect(bVisitantes.insert).toHaveBeenCalledWith(
        { nome: 'Clara', data_nascimento: '2017-01-01', responsavel: null, contato: null, indicado_por: null, status: 'em_visitas', clube_id: 'c1' },
      )
      expect(id).toBe('v3')
      expect(api.visitantes.value).toHaveLength(3)
    })

    it('atualiza um visitante existente e substitui na lista', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      const bVisitantes = mocks.supabase.builderDe('visitantes')
      bVisitantes.singleData = { ...VISITANTES[0], responsavel: 'Pai' }

      await api.salvarVisitante(
        { nome: 'Ana', data_nascimento: '2017-03-10', responsavel: 'Pai', contato: '8199', indicado_por: null, status: 'em_visitas' },
        'c1',
        'v1',
      )

      expect(bVisitantes.update).toHaveBeenCalled()
      expect(bVisitantes.eq).toHaveBeenCalledWith('id', 'v1')
      expect(api.visitantes.value[0]!.responsavel).toBe('Pai')
    })

    it('propaga erro ao salvar', async () => {
      const api = useVisitantes()
      mocks.supabase.builderDe('visitantes').error = new Error('falha ao salvar')

      await expect(api.salvarVisitante(
        { nome: 'Clara', data_nascimento: '2017-01-01', responsavel: null, contato: null, indicado_por: null, status: 'em_visitas' },
        'c1',
      )).rejects.toThrow('falha ao salvar')
    })
  })

  describe('salvarVisita', () => {
    it('faz upsert por (visitante, numero) e atualiza a lista local', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      const bVisitas = mocks.supabase.builderDe('visitas')
      bVisitas.singleData = { id: 'vs2', visitante_id: 'v1', numero: 2, data_visita: '2026-09-12', presente: true, observacao: null }

      await api.salvarVisita('v1', 2, { data_visita: '2026-09-12', presente: true })

      expect(bVisitas.upsert).toHaveBeenCalledWith(
        { visitante_id: 'v1', numero: 2, data_visita: '2026-09-12', presente: true },
        { onConflict: 'visitante_id,numero' },
      )
      expect(api.visitas.value.find(v => v.numero === 2)!.presente).toBe(true)
    })

    it('insere a visita na lista local quando ainda não havia registro', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      const bVisitas = mocks.supabase.builderDe('visitas')
      bVisitas.singleData = { id: 'vs3', visitante_id: 'v1', numero: 3, data_visita: '2026-09-19', presente: true, observacao: null }

      await api.salvarVisita('v1', 3, { data_visita: '2026-09-19', presente: true })

      expect(api.visitasPorVisitante.value.get('v1')).toHaveLength(3)
    })

    it('propaga erro ao salvar', async () => {
      const api = useVisitantes()
      mocks.supabase.builderDe('visitas').error = new Error('falha na visita')

      await expect(api.salvarVisita('v1', 1, { data_visita: '2026-09-05', presente: true })).rejects.toThrow('falha na visita')
    })
  })

  describe('salvarLicao', () => {
    it('faz upsert da lição concluída', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      const bLicoes = mocks.supabase.builderDe('prova_ingresso_licoes')
      bLicoes.singleData = { id: 'l2', visitante_id: 'v2', licao: 2, concluida: true, data_conclusao: '2026-09-13', registrado_por: 'u1' }

      await api.salvarLicao('v2', 2, '2026-09-13', 'u1')

      expect(bLicoes.upsert).toHaveBeenCalledWith(
        { visitante_id: 'v2', licao: 2, concluida: true, data_conclusao: '2026-09-13', registrado_por: 'u1' },
        { onConflict: 'visitante_id,licao' },
      )
      expect(api.licoesPorVisitante.value.get('v2')).toHaveLength(2)
    })

    it('remove a lição quando a data é null', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      const bLicoes = mocks.supabase.builderDe('prova_ingresso_licoes')
      await api.salvarLicao('v2', 1, null, null)

      expect(bLicoes.delete).toHaveBeenCalled()
      expect(bLicoes.eq).toHaveBeenCalledWith('visitante_id', 'v2')
      expect(bLicoes.eq).toHaveBeenCalledWith('licao', 1)
      expect(api.licoesPorVisitante.value.get('v2')).toBeUndefined()
    })

    it('propaga erro ao salvar e ao remover', async () => {
      const api = useVisitantes()
      mocks.supabase.builderDe('prova_ingresso_licoes').error = new Error('falha na lição')

      await expect(api.salvarLicao('v2', 1, '2026-09-06', 'u1')).rejects.toThrow('falha na lição')
      await expect(api.salvarLicao('v2', 1, null, null)).rejects.toThrow('falha na lição')
    })
  })

  describe('matricular', () => {
    it('chama a RPC e marca o visitante como matriculado', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      mocks.supabase.rpc = vi.fn(() => Promise.resolve({ data: { id: 'o2' }, error: null }))

      await api.matricular('v1', 't1')

      expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_matricular_visitante', {
        p_visitante_id: 'v1',
        p_turma_id: 't1',
      })
      expect(api.visitantes.value.find(v => v.id === 'v1')!.status).toBe('matriculado')
    })

    it('omite a turma quando é null', async () => {
      const api = useVisitantes()
      await api.carregar('c1')

      mocks.supabase.rpc = vi.fn(() => Promise.resolve({ data: { id: 'o2' }, error: null }))
      await api.matricular('v1', null)

      expect(mocks.supabase.rpc).toHaveBeenCalledWith('fn_matricular_visitante', {
        p_visitante_id: 'v1',
        p_turma_id: undefined,
      })
    })

    it('propaga erro da RPC', async () => {
      const api = useVisitantes()
      mocks.supabase.rpc = vi.fn(() => Promise.resolve({ data: null, error: new Error('Visitante já está matriculado') }))

      await expect(api.matricular('v1', null)).rejects.toThrow('Visitante já está matriculado')
    })
  })
})
