// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { pontosPorChave, previewTotalFolha, type FolhaPreview, type ItensPontuacaoMap } from './pontos'

describe('pontosPorChave', () => {
  it('retorna mapa zerado quando não há itens', () => {
    expect(pontosPorChave([])).toEqual({
      presenca: 0, uniforme: 0, biblia: 0, ebd: 0, manual: 0, conduta: 0, secao_manual: 0,
    })
  })

  it('mapeia cada chave válida para os pontos informados', () => {
    const mapa = pontosPorChave([
      { chave: 'presenca', pontos: 10 },
      { chave: 'uniforme', pontos: 5 },
      { chave: 'biblia', pontos: 5 },
      { chave: 'ebd', pontos: 5 },
      { chave: 'manual', pontos: 5 },
      { chave: 'conduta', pontos: 5 },
      { chave: 'secao_manual', pontos: 2 },
    ])
    expect(mapa).toEqual({
      presenca: 10, uniforme: 5, biblia: 5, ebd: 5, manual: 5, conduta: 5, secao_manual: 2,
    })
  })

  it('ignora chaves fora das 7 reconhecidas', () => {
    const mapa = pontosPorChave([
      { chave: 'presenca', pontos: 10 },
      { chave: 'chave_inexistente', pontos: 999 },
      { chave: 'outra', pontos: 1 },
    ])
    expect(mapa.presenca).toBe(10)
    expect(mapa.uniforme).toBe(0)
  })

  it('sobrescreve o valor quando a mesma chave aparece duas vezes', () => {
    const mapa = pontosPorChave([
      { chave: 'presenca', pontos: 10 },
      { chave: 'presenca', pontos: 12 },
    ])
    expect(mapa.presenca).toBe(12)
  })
})

function folha(parcial: Partial<FolhaPreview> = {}): FolhaPreview {
  return {
    uniforme: false,
    biblia: false,
    ebd: false,
    manual: false,
    conduta: false,
    secoes_dia: 0,
    atividade_extra: 0,
    ...parcial,
  }
}

describe('previewTotalFolha', () => {
  const itens: ItensPontuacaoMap = {
    presenca: 10, uniforme: 5, biblia: 5, ebd: 5, manual: 5, conduta: 5, secao_manual: 2,
  }

  it('zera tudo quando o oansista faltou', () => {
    expect(previewTotalFolha(itens, folha({ uniforme: true, secoes_dia: 3 }), false)).toBe(0)
  })

  it('soma apenas a presença quando nenhum critério é atendido', () => {
    expect(previewTotalFolha(itens, folha(), true)).toBe(10)
  })

  it('soma as flags marcadas', () => {
    expect(previewTotalFolha(itens, folha({ uniforme: true, biblia: true, manual: true }), true)).toBe(10 + 5 + 5 + 5)
  })

  it('multiplica seções do manual pelo valor da seção', () => {
    expect(previewTotalFolha(itens, folha({ secoes_dia: 3 }), true)).toBe(10 + 3 * 2)
  })

  it('soma atividade extra como pontos diretos', () => {
    expect(previewTotalFolha(itens, folha({ atividade_extra: 7 }), true)).toBe(10 + 7)
  })

  it('soma pontos de jogos quando presentes', () => {
    expect(previewTotalFolha(itens, folha({ pontos_jogos: 50 }), true)).toBe(10 + 50)
  })

  it('combina todos os critérios', () => {
    const total = previewTotalFolha(
      itens,
      folha({ uniforme: true, biblia: true, ebd: true, manual: true, conduta: true, secoes_dia: 4, atividade_extra: 3, pontos_jogos: 40 }),
      true,
    )
    expect(total).toBe(10 + 5 * 5 + 4 * 2 + 3 + 40)
  })

  it('trata seções e extras como número quando vêm undefined/0', () => {
    expect(previewTotalFolha(itens, folha({ secoes_dia: 0, atividade_extra: 0 }), true)).toBe(10)
  })
})
