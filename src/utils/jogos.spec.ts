// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { pontosDaColocacao, pontosDoResultado } from './jogos'

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