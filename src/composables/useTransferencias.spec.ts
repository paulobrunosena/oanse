import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useTransferencias } from './useTransferencias'

const OANSISTAS = [
  { id: 'o1', nome: 'Ana', turma_id: 't1', turma: { nome: 'Turma 1' } },
  { id: 'o2', nome: 'Bia', turma_id: null, turma: null },
]
const TURMAS = [
  { id: 't1', nome: 'Turma 1', lider_id: 'l1' },
  { id: 't2', nome: 'Turma 2', lider_id: 'l2' },
]
const HISTORICO = [
  { id: 'h1', data: '2026-08-22', motivo: null, oansista: { nome: 'Ana' }, origem: { nome: 'Turma 1' }, destino: { nome: 'Turma 2' } },
  { id: 'h2', data: '2026-08-15', motivo: 'Conflito', oansista: null, origem: null, destino: null },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('useTransferencias', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase({
      oansistas: () => builder(OANSISTAS),
      turmas: () => builder(TURMAS),
      transferencias: () => builder(HISTORICO),
    })
  })

  describe('carregar', () => {
    it('carrega oansistas, turmas e histórico normalizado', async () => {
      const transferencias = useTransferencias()
      await transferencias.carregar('c1')

      expect(transferencias.oansistas.value).toHaveLength(2)
      expect(transferencias.oansistas.value[0]).toEqual({ id: 'o1', nome: 'Ana', turma_id: 't1', turma_nome: 'Turma 1' })
      expect(transferencias.oansistas.value[1]!.turma_nome).toBeNull()
      expect(transferencias.turmas.value).toEqual(TURMAS)
      expect(transferencias.historico.value).toHaveLength(2)
      expect(transferencias.historico.value[0]).toEqual({
        id: 'h1', data: '2026-08-22', motivo: null, oansista_nome: 'Ana', origem_nome: 'Turma 1', destino_nome: 'Turma 2',
      })
      expect(transferencias.carregando.value).toBe(false)
    })

    it('filtra oansistas ativos do clube', async () => {
      const transferencias = useTransferencias()
      await transferencias.carregar('c1')

      const oansistas = mocks.supabase.builderDe('oansistas')
      expect(oansistas.eq).toHaveBeenCalledWith('clube_id', 'c1')
      expect(oansistas.eq).toHaveBeenCalledWith('status', 'ativo')
    })
  })

  describe('transferir', () => {
    it('chama a API e resolve quando não há erro', async () => {
      global.fetch = vi.fn(() => Promise.resolve(new Response(JSON.stringify({ ok: true }), { status: 200 }))) as unknown as typeof fetch
      const transferencias = useTransferencias()
      await expect(transferencias.transferir('o1', 't2', 'Conflito')).resolves.toBeUndefined()
      expect(global.fetch).toHaveBeenCalledWith('/api/transferencias', expect.objectContaining({ method: 'POST' }))
    })

    it('lança a mensagem de statusMessage quando a API retorna erro', async () => {
      global.fetch = vi.fn(() => Promise.resolve(new Response(JSON.stringify({ statusMessage: 'Transferência não permitida' }), { status: 400 }))) as unknown as typeof fetch
      const transferencias = useTransferencias()
      await expect(transferencias.transferir('o1', 't2', 'Conflito')).rejects.toThrow('Transferência não permitida')
    })

    it('lança mensagem genérica quando não há statusMessage', async () => {
      global.fetch = vi.fn(() => Promise.resolve(new Response(JSON.stringify({}), { status: 500 }))) as unknown as typeof fetch
      const transferencias = useTransferencias()
      await expect(transferencias.transferir('o1', 't2', 'Conflito')).rejects.toThrow('Erro ao transferir')
    })
  })
})
