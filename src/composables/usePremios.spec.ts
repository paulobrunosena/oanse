// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { builder, clienteSupabase } from '../../tests/helpers/supabase'
import { usePremios } from './usePremios'

const PREMIOS = [
  { id: 'p1', nome: 'Botão vermelho 01', tipo: 'botom', descricao: null, estoque: 5, estoque_min: 2, ativo: true },
  { id: 'p2', nome: 'Distintivo do grau', tipo: 'premio', descricao: 'Grau', estoque: 1, estoque_min: 3, ativo: true },
]

const mocks = vi.hoisted(() => ({ supabase: null as any }))
vi.mock('@/lib/supabase', () => ({
  get supabase() { return mocks.supabase },
}))

describe('usePremios', () => {
  beforeEach(() => {
    mocks.supabase = clienteSupabase({ premios: () => builder(PREMIOS) })
  })

  it('carrega o catálogo ordenado por nome', async () => {
    const { premios, carregando, carregar } = usePremios()
    await carregar()

    expect(mocks.supabase.from).toHaveBeenCalledWith('premios')
    expect(premios.value).toEqual(PREMIOS)
    expect(carregando.value).toBe(false)
  })

  it('propaga erro ao carregar', async () => {
    mocks.supabase = clienteSupabase({ premios: () => builder(null, new Error('boom')) })
    const { carregar } = usePremios()

    await expect(carregar()).rejects.toThrow('boom')
  })

  it('cria um prêmio', async () => {
    const { criar } = usePremios()
    await criar({ nome: 'Botão azul', tipo: 'botom', descricao: null, estoque: 0, estoque_min: 0, ativo: true })

    expect(mocks.supabase.builderDe('premios').insert).toHaveBeenCalledWith({
      nome: 'Botão azul', tipo: 'botom', descricao: null, estoque: 0, estoque_min: 0, ativo: true,
    })
  })

  it('atualiza um prêmio', async () => {
    const { atualizar } = usePremios()
    await atualizar('p1', { estoque: 10 })

    expect(mocks.supabase.builderDe('premios').update).toHaveBeenCalledWith({ estoque: 10 })
    expect(mocks.supabase.builderDe('premios').eq).toHaveBeenCalledWith('id', 'p1')
  })

  it('exclui um prêmio', async () => {
    const { excluir } = usePremios()
    await excluir('p1')

    expect(mocks.supabase.builderDe('premios').delete).toHaveBeenCalled()
    expect(mocks.supabase.builderDe('premios').eq).toHaveBeenCalledWith('id', 'p1')
  })
})
