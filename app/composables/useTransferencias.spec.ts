import { ref } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
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

let supabase = clienteSupabase()
let erroFetch: { data?: { statusMessage?: string } } | null = null

mockNuxtImport('useSupabaseClient', () => () => supabase)
mockNuxtImport('useFetch', () => vi.fn(() => ({ error: ref(erroFetch) })))

describe('useTransferencias', () => {
  beforeEach(() => {
    supabase = clienteSupabase({
      oansistas: () => builder(OANSISTAS),
      turmas: () => builder(TURMAS),
      transferencias: () => builder(HISTORICO),
    })
    erroFetch = null
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

      const oansistas = supabase.builderDe('oansistas')
      expect(oansistas.eq).toHaveBeenCalledWith('clube_id', 'c1')
      expect(oansistas.eq).toHaveBeenCalledWith('status', 'ativo')
    })
  })

  describe('transferir', () => {
    it('chama a API de transferência quando não há erro', async () => {
      const transferencias = useTransferencias()
      await expect(transferencias.transferir('o1', 't2', 'Conflito')).resolves.toBeUndefined()
    })

    it('lança a mensagem de statusMessage quando a API retorna erro', async () => {
      erroFetch = { data: { statusMessage: 'Transferência não permitida' } }
      const transferencias = useTransferencias()
      await expect(transferencias.transferir('o1', 't2', 'Conflito')).rejects.toThrow('Transferência não permitida')
    })

    it('lança mensagem genérica quando não há statusMessage', async () => {
      erroFetch = {}
      const transferencias = useTransferencias()
      await expect(transferencias.transferir('o1', 't2', 'Conflito')).rejects.toThrow('Erro ao transferir')
    })
  })
})
