// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { avaliarIdadeClube, clubeParaProgredir, clubePorIdade, idadeEmAnos, type ClubeFaixa } from './idade'

const CLUBES: ClubeFaixa[] = [
  { id: 'c1', nome: 'Ursinhos', idade_min: 4, idade_max: 5 },
  { id: 'c2', nome: 'Faíscas', idade_min: 6, idade_max: 8 },
  { id: 'c3', nome: 'Flamas', idade_min: 9, idade_max: 10 },
  { id: 'c4', nome: 'Tochas', idade_min: 11, idade_max: 12 },
]

const REF = new Date('2026-09-16T12:00:00')

describe('idadeEmAnos', () => {
  it('calcula a idade em anos completos', () => {
    expect(idadeEmAnos('2018-09-10', REF)).toBe(8) // fez 8 anos em 10/09
    expect(idadeEmAnos('2018-09-20', REF)).toBe(7) // ainda não fez 8 em 16/09
    expect(idadeEmAnos('2018-09-16', REF)).toBe(8) // aniversário no dia
  })

  it('retorna null para data vazia, inválida ou futura', () => {
    expect(idadeEmAnos('', REF)).toBeNull()
    expect(idadeEmAnos('não-data', REF)).toBeNull()
    expect(idadeEmAnos('2027-01-01', REF)).toBeNull()
  })
})

describe('clubePorIdade', () => {
  it('encontra o clube cuja faixa contém a idade', () => {
    expect(clubePorIdade(CLUBES, 4)?.id).toBe('c1')
    expect(clubePorIdade(CLUBES, 5)?.id).toBe('c1')
    expect(clubePorIdade(CLUBES, 6)?.id).toBe('c2')
    expect(clubePorIdade(CLUBES, 12)?.id).toBe('c4')
  })

  it('retorna null quando nenhum clube cobre a idade', () => {
    expect(clubePorIdade(CLUBES, 3)).toBeNull()
    expect(clubePorIdade(CLUBES, 13)).toBeNull()
  })
})

describe('avaliarIdadeClube', () => {
  it('retorna vazio sem data ou sem clube', () => {
    expect(avaliarIdadeClube(CLUBES, '', 'c2', REF).tipo).toBe('vazio')
    expect(avaliarIdadeClube(CLUBES, '2018-01-01', null, REF).tipo).toBe('vazio')
  })

  it('retorna muito_novo para criança nascida no ano corrente', () => {
    expect(avaliarIdadeClube(CLUBES, '2026-02-01', 'c2', REF).tipo).toBe('muito_novo')
  })

  it('retorna clube_correto quando a idade bate com o clube', () => {
    expect(avaliarIdadeClube(CLUBES, '2019-01-01', 'c2', REF).tipo).toBe('clube_correto')
  })

  it('retorna clube_diferente apontando o clube sugerido', () => {
    const r = avaliarIdadeClube(CLUBES, '2022-01-01', 'c2', REF) // 4 anos => Ursinhos
    expect(r.tipo).toBe('clube_diferente')
    if (r.tipo === 'clube_diferente') expect(r.clubeSugerido.nome).toBe('Ursinhos')
  })

  it('retorna fora_de_todas para idade sem clube correspondente', () => {
    expect(avaliarIdadeClube(CLUBES, '2010-01-01', 'c2', REF).tipo).toBe('fora_de_todas') // 16 anos
  })
})

describe('clubeParaProgredir', () => {
  it('sugere o clube seguinte quando a idade avançou para a faixa à frente', () => {
    expect(clubeParaProgredir(CLUBES, '2019-01-01', 'c1', REF)?.nome).toBe('Faíscas') // 7 anos, estava em Ursinhos
  })

  it('retorna null quando a idade ainda pertence ao clube atual', () => {
    expect(clubeParaProgredir(CLUBES, '2022-01-01', 'c1', REF)).toBeNull() // 4 anos, segue em Ursinhos
  })

  it('pula clubes quando a idade avançou mais de uma faixa', () => {
    expect(clubeParaProgredir(CLUBES, '2014-01-01', 'c2', REF)?.nome).toBe('Tochas') // 12 anos, do Faíscas direto p/ Tochas
  })

  it('retorna null para regressão (idade de clube anterior)', () => {
    expect(clubeParaProgredir(CLUBES, '2022-01-01', 'c3', REF)).toBeNull() // 4 anos, mas está em Flamas
  })

  it('retorna null quando a idade saiu de todas as faixas', () => {
    expect(clubeParaProgredir(CLUBES, '2010-01-01', 'c4', REF)).toBeNull() // 16 anos, acima de Tochas
  })

  it('retorna null para data inválida', () => {
    expect(clubeParaProgredir(CLUBES, '', 'c1', REF)).toBeNull()
  })
})
