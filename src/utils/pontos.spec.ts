// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { pontosPorChave, previewTotalFolha, type FolhaPreview, type ItensPontuacaoMap } from './pontos'

describe('pontosPorChave', () => {
  it('retorna mapa zerado quando não há itens', () => {
    expect(pontosPorChave([])).toEqual({
      presenca: 0, uniforme: 0, biblia: 0, ebd: 0, manual: 0, conduta: 0,
      leitura_biblica: 0, visitante: 0, secao_sem_ajuda: 0, secao_com_ajuda: 0,
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
      { chave: 'leitura_biblica', pontos: 10 },
      { chave: 'visitante', pontos: 5 },
      { chave: 'secao_sem_ajuda', pontos: 10 },
      { chave: 'secao_com_ajuda', pontos: 5 },
    ])
    expect(mapa).toEqual({
      presenca: 10, uniforme: 5, biblia: 5, ebd: 5, manual: 5, conduta: 5,
      leitura_biblica: 10, visitante: 5, secao_sem_ajuda: 10, secao_com_ajuda: 5,
    })
  })

  it('ignora chaves fora das reconhecidas', () => {
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
    leitura_biblica: false,
    visitantes_convidados: 0,
    secoes_sem_ajuda: 0,
    secoes_com_ajuda: 0,
    atividade_extra: 0,
    ...parcial,
  }
}

describe('previewTotalFolha', () => {
  const itens: ItensPontuacaoMap = {
    presenca: 10, uniforme: 5, biblia: 5, ebd: 5, manual: 5, conduta: 5,
    leitura_biblica: 10, visitante: 5, secao_sem_ajuda: 10, secao_com_ajuda: 5,
  }

  it('zera tudo quando o oansista faltou', () => {
    expect(previewTotalFolha(itens, folha({ uniforme: true, secoes_sem_ajuda: 3 }), false)).toBe(0)
  })

  it('soma apenas a presença quando nenhum critério é atendido', () => {
    expect(previewTotalFolha(itens, folha(), true)).toBe(10)
  })

  it('soma as flags marcadas', () => {
    expect(previewTotalFolha(itens, folha({ uniforme: true, biblia: true, manual: true }), true)).toBe(10 + 5 + 5 + 5)
  })

  it('soma a leitura bíblica quando marcada', () => {
    expect(previewTotalFolha(itens, folha({ leitura_biblica: true }), true)).toBe(10 + 10)
  })

  it('multiplica visitantes convidados pelo valor por visitante', () => {
    expect(previewTotalFolha(itens, folha({ visitantes_convidados: 2 }), true)).toBe(10 + 2 * 5)
  })

  it('multiplica seções sem ajuda pelo valor maior e com ajuda pelo menor', () => {
    expect(previewTotalFolha(itens, folha({ secoes_sem_ajuda: 2, secoes_com_ajuda: 1 }), true)).toBe(10 + 2 * 10 + 1 * 5)
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
      folha({ uniforme: true, biblia: true, ebd: true, manual: true, conduta: true, leitura_biblica: true, visitantes_convidados: 1, secoes_sem_ajuda: 3, secoes_com_ajuda: 2, atividade_extra: 3, pontos_jogos: 40 }),
      true,
    )
    expect(total).toBe(10 + 5 * 5 + 10 + 1 * 5 + 3 * 10 + 2 * 5 + 3 + 40)
  })

  it('trata números como zero quando vêm undefined/0', () => {
    expect(previewTotalFolha(itens, folha(), true)).toBe(10)
  })
})