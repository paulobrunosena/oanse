import { describe, expect, it } from 'vitest'
import { sabadoCorrente, sabadosAnteriores } from './sabado'

describe('sabadosAnteriores', () => {
  it('lista os últimos n sábados começando pelo mais recente', () => {
    const sabado = new Date(2026, 7, 22) // sábado 22/08/2026

    expect(sabadosAnteriores(3, sabado)).toEqual([
      '2026-08-22',
      '2026-08-15',
      '2026-08-08',
    ])
  })

  it('considera o sábado corrente quando hoje não é sábado', () => {
    const segunda = new Date(2026, 7, 24) // segunda 24/08/2026

    expect(sabadoCorrente(segunda)).toBe('2026-08-22')
    expect(sabadosAnteriores(1, segunda)).toEqual(['2026-08-22'])
  })

  it('retorna lista vazia para n <= 0', () => {
    const sabado = new Date(2026, 7, 22)
    expect(sabadosAnteriores(0, sabado)).toEqual([])
    expect(sabadosAnteriores(-2, sabado)).toEqual([])
  })
})