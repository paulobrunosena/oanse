// @vitest-environment node
import { describe, expect, it } from 'vitest'
import {
  podeCriarEncontroRetroativo,
  podeGerenciarUsuarios,
  podeTransferirOansista,
  type PerfilAutorizacao,
} from './autorizacao'

const perfil = (over: Partial<PerfilAutorizacao> = {}): PerfilAutorizacao => ({
  role: 'lider',
  ativo: true,
  clube_id: 'clube-1',
  ...over,
})

describe('podeGerenciarUsuarios', () => {
  it('libera apenas diretor_geral ativo', () => {
    expect(podeGerenciarUsuarios(perfil({ role: 'diretor_geral', clube_id: null }))).toBe(true)
    expect(podeGerenciarUsuarios(perfil({ role: 'diretor_geral', ativo: false }))).toBe(false)
    expect(podeGerenciarUsuarios(perfil({ role: 'secretaria' }))).toBe(false)
    expect(podeGerenciarUsuarios(perfil({ role: 'diretor_clube', clube_id: null }))).toBe(false)
  })

  it('nega quando não há perfil', () => {
    expect(podeGerenciarUsuarios(null)).toBe(false)
    expect(podeGerenciarUsuarios(undefined)).toBe(false)
  })
})

describe('podeTransferirOansista', () => {
  it('diretor_geral pode transferir em qualquer clube', () => {
    expect(podeTransferirOansista(perfil({ role: 'diretor_geral', clube_id: null }), 'clube-9')).toBe(true)
  })

  it('diretor_clube só transfere criança do próprio clube', () => {
    expect(podeTransferirOansista(perfil({ role: 'diretor_clube' }), 'clube-1')).toBe(true)
    expect(podeTransferirOansista(perfil({ role: 'diretor_clube' }), 'clube-2')).toBe(false)
  })

  it('diretor_clube sem clube definido não transfere', () => {
    expect(podeTransferirOansista(perfil({ role: 'diretor_clube', clube_id: null }), 'clube-1')).toBe(false)
  })

  it('líder, secretaria e inativo não transferem', () => {
    expect(podeTransferirOansista(perfil({ role: 'lider' }), 'clube-1')).toBe(false)
    expect(podeTransferirOansista(perfil({ role: 'secretaria' }), 'clube-1')).toBe(false)
    expect(podeTransferirOansista(perfil({ ativo: false, role: 'diretor_geral' }), 'clube-1')).toBe(false)
  })

  it('nega quando não há perfil ou a criança não tem clube', () => {
    expect(podeTransferirOansista(null, 'clube-1')).toBe(false)
    expect(podeTransferirOansista(perfil({ role: 'diretor_clube' }), null)).toBe(false)
  })
})

describe('podeCriarEncontroRetroativo', () => {
  it('libera os perfis operacionais ativos', () => {
    for (const role of ['diretor_geral', 'secretaria', 'diretor_clube', 'lider']) {
      expect(podeCriarEncontroRetroativo(perfil({ role }))).toBe(true)
    }
  })

  it('nega lider_jogos, inativos e sem perfil', () => {
    expect(podeCriarEncontroRetroativo(perfil({ role: 'lider_jogos' }))).toBe(false)
    expect(podeCriarEncontroRetroativo(perfil({ role: 'diretor_geral', ativo: false }))).toBe(false)
    expect(podeCriarEncontroRetroativo(null)).toBe(false)
  })
})
