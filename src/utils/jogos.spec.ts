// @vitest-environment node
import { describe, expect, it } from 'vitest'
import {
  CORES_PREDEFINIDAS,
  corHex,
  gerarNomeEvento,
  jogosDisponiveis,
  pontosDaColocacao,
  pontosDoResultado,
} from './jogos'

const CONFIG = [
  { colocacao: 1, pontos: 100, desclassificado: false },
  { colocacao: 2, pontos: 70, desclassificado: false },
  { colocacao: 3, pontos: 50, desclassificado: false },
  { colocacao: 4, pontos: 40, desclassificado: false },
]

describe('pontosDoResultado (espelho do trigger fn_definir_pontos_resultado)', () => {
  it('atribui 100/70/50/40 conforme a colocação', () => {
    expect(pontosDoResultado({ colocacao: 1, desclassificado: false }, CONFIG)).toBe(100)
    expect(pontosDoResultado({ colocacao: 2, desclassificado: false }, CONFIG)).toBe(70)
    expect(pontosDoResultado({ colocacao: 3, desclassificado: false }, CONFIG)).toBe(50)
    expect(pontosDoResultado({ colocacao: 4, desclassificado: false }, CONFIG)).toBe(40)
  })

  it('desclassificado vale 0', () => {
    expect(pontosDoResultado({ colocacao: null, desclassificado: true }, CONFIG)).toBe(0)
  })

  it('sem colocação nem desclassificação vale 0', () => {
    expect(pontosDoResultado({ colocacao: null, desclassificado: false }, CONFIG)).toBe(0)
  })

  it('colocação fora da configuração vale 0', () => {
    expect(pontosDaColocacao(9, CONFIG)).toBe(0)
  })
})

describe('CORES_PREDEFINIDAS', () => {
  it('são exatamente verde, vermelho, amarelo e azul', () => {
    expect(CORES_PREDEFINIDAS).toEqual(['verde', 'vermelho', 'amarelo', 'azul'])
  })
})

describe('corHex', () => {
  it('retorna o hex de cada cor pré-definida e um neutro para cores desconhecidas', () => {
    expect(corHex('verde')).toBe('#22C55E')
    expect(corHex('vermelho')).toBe('#EF4444')
    expect(corHex('amarelo')).toBe('#EAB308')
    expect(corHex('azul')).toBe('#3B82F6')
    expect(corHex('roxo')).toBe('#64748b')
  })
})

describe('jogosDisponiveis', () => {
  const catalogo = [
    { id: 'a', clube_id: 'flamas', nome: 'maratona' },
    { id: 'b', clube_id: 'tochas', nome: 'maratona' },
    { id: 'c', clube_id: 'tochas', nome: 'bonanza' },
    { id: 'd', clube_id: 'ursinhos', nome: 'trenzinho de mãos dadas' },
  ]

  it('une os jogos dos clubes selecionados sem duplicar nomes iguais', () => {
    const nomes = jogosDisponiveis(catalogo, ['flamas', 'tochas'])
    expect(nomes).toEqual(['bonanza', 'maratona'])
  })

  it('retorna vazio quando nenhum clube selecionado', () => {
    expect(jogosDisponiveis(catalogo, [])).toEqual([])
  })
})

describe('gerarNomeEvento', () => {
  it('gera nome com dois clubes', () => {
    expect(gerarNomeEvento(['Flamas', 'Tochas'])).toBe('Jogos dos Flamas e Tochas')
  })

  it('gera nome com três clubes', () => {
    expect(gerarNomeEvento(['Flamas', 'Tochas', 'Ursinhos'])).toBe('Jogos dos Flamas, Tochas e Ursinhos')
  })

  it('gera nome com um clube e vazio sem clube', () => {
    expect(gerarNomeEvento(['Ursinhos'])).toBe('Jogos dos Ursinhos')
    expect(gerarNomeEvento([])).toBe('')
  })
})