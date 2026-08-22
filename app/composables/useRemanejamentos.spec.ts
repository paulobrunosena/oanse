import { beforeEach, describe, expect, it } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { useRemanejamentos, type TurmaRemanejamento } from './useRemanejamentos'

const TURMAS = [
  { id: 't1', nome: 'Turma 1', lider_id: 'l1', lider: { nome: 'Tia Ana' } },
  { id: 't2', nome: 'Turma 2', lider_id: 'l2', lider: null },
]
const LIDERES = [
  { id: 'l1', nome: 'Tia Ana' },
  { id: 'l2', nome: 'Tia Bia' },
]
const REMANEJAMENTOS = [
  { id: 'r1', encontro_id: 'e1', turma_id: 't1', lider_titular_id: 'l1', lider_substituto_id: 'l2', criado_por: 'l2' },
]

let supabase = clienteSupabase()

mockNuxtImport('useSupabaseClient', () => () => supabase)

describe('useRemanejamentos', () => {
  beforeEach(() => {
    supabase = clienteSupabase({
      turmas: () => builder(TURMAS),
      profiles: () => builder(LIDERES),
      remanejamentos_temporarios: () => builder(REMANEJAMENTOS),
    })
  })

  describe('carregar', () => {
    it('carrega turmas com nome do líder, líderes disponíveis e remanejamentos do encontro', async () => {
      const remanejamentos = useRemanejamentos()
      await remanejamentos.carregar('c1', 'e1')

      expect(remanejamentos.turmas.value).toHaveLength(2)
      expect(remanejamentos.turmas.value[0]).toEqual({ id: 't1', nome: 'Turma 1', lider_id: 'l1', lider_nome: 'Tia Ana' })
      expect(remanejamentos.turmas.value[1]!.lider_nome).toBeNull()
      expect(remanejamentos.lideres.value).toEqual(LIDERES)
      expect(remanejamentos.remanejamentos.value).toEqual(REMANEJAMENTOS)
      expect(remanejamentos.carregando.value).toBe(false)
    })

    it('filtra líderes pelo clube e role', async () => {
      const remanejamentos = useRemanejamentos()
      await remanejamentos.carregar('c1', 'e1')

      const perfis = supabase.builderDe('profiles')
      expect(perfis.eq).toHaveBeenCalledWith('clube_id', 'c1')
      expect(perfis.eq).toHaveBeenCalledWith('role', 'lider')
    })
  })

  describe('remanejamentoDe', () => {
    it('retorna o remanejamento da turma quando existe', async () => {
      const remanejamentos = useRemanejamentos()
      await remanejamentos.carregar('c1', 'e1')
      expect(remanejamentos.remanejamentoDe('t1')?.id).toBe('r1')
      expect(remanejamentos.remanejamentoDe('t2')).toBeUndefined()
    })
  })

  describe('salvar', () => {
    it('atualiza o substituto quando já existe remanejamento', async () => {
      const remanejamentos = useRemanejamentos()
      await remanejamentos.carregar('c1', 'e1')

      await remanejamentos.salvar('e1', TURMAS[0] as unknown as TurmaRemanejamento, 'l1', 'l1')

      const bRem = supabase.builderDe('remanejamentos_temporarios')
      expect(bRem.update).toHaveBeenCalledWith({ lider_substituto_id: 'l1' })
      expect(bRem.eq).toHaveBeenCalledWith('id', 'r1')
      expect(remanejamentos.remanejamentoDe('t1')?.lider_substituto_id).toBe('l1')
    })

    it('insere um novo remanejamento quando não existe', async () => {
      supabase = clienteSupabase({
        turmas: () => builder(TURMAS),
        profiles: () => builder(LIDERES),
        remanejamentos_temporarios: () => builder([]),
      })
      const remanejamentos = useRemanejamentos()
      await remanejamentos.carregar('c1', 'e1')

      const novo = { id: 'r2', encontro_id: 'e1', turma_id: 't2', lider_titular_id: 'l2', lider_substituto_id: 'l1', criado_por: 'l1' }
      supabase.builderDe('remanejamentos_temporarios').singleData = novo

      await remanejamentos.salvar('e1', TURMAS[1] as unknown as TurmaRemanejamento, 'l1', 'l1')

      const bRem = supabase.builderDe('remanejamentos_temporarios')
      expect(bRem.insert).toHaveBeenCalledWith({
        encontro_id: 'e1', turma_id: 't2', lider_titular_id: 'l2', lider_substituto_id: 'l1', criado_por: 'l1',
      })
      expect(remanejamentos.remanejamentos.value).toContainEqual(novo)
    })
  })

  describe('remover', () => {
    it('remove o remanejamento existente', async () => {
      const remanejamentos = useRemanejamentos()
      await remanejamentos.carregar('c1', 'e1')

      await remanejamentos.remover('t1')

      const bRem = supabase.builderDe('remanejamentos_temporarios')
      expect(bRem.delete).toHaveBeenCalled()
      expect(bRem.eq).toHaveBeenCalledWith('id', 'r1')
      expect(remanejamentos.remanejamentos.value).toHaveLength(0)
    })

    it('não chama o banco quando não existe remanejamento', async () => {
      const remanejamentos = useRemanejamentos()
      await remanejamentos.carregar('c1', 'e1')

      await remanejamentos.remover('t2')

      expect(supabase.builderDe('remanejamentos_temporarios').delete).not.toHaveBeenCalled()
    })
  })
})
