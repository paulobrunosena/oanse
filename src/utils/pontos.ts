export interface ItensPontuacaoMap {
  presenca: number
  uniforme: number
  biblia: number
  ebd: number
  manual: number
  conduta: number
  secao_manual: number
}

const CHAVES = ['presenca', 'uniforme', 'biblia', 'ebd', 'manual', 'conduta', 'secao_manual'] as const

export function pontosPorChave(itens: { chave: string, pontos: number }[]): ItensPontuacaoMap {
  const mapa: ItensPontuacaoMap = { presenca: 0, uniforme: 0, biblia: 0, ebd: 0, manual: 0, conduta: 0, secao_manual: 0 }
  for (const item of itens) {
    if ((CHAVES as readonly string[]).includes(item.chave)) {
      mapa[item.chave as keyof ItensPontuacaoMap] = item.pontos
    }
  }
  return mapa
}

export interface FolhaPreview {
  uniforme: boolean
  biblia: boolean
  ebd: boolean
  manual: boolean
  conduta: boolean
  secoes_dia: number
  atividade_extra: number
  pontos_jogos?: number
}

export function previewTotalFolha(itens: ItensPontuacaoMap, folha: FolhaPreview, presente: boolean): number {
  if (!presente) return 0
  return itens.presenca
    + (folha.uniforme ? itens.uniforme : 0)
    + (folha.biblia ? itens.biblia : 0)
    + (folha.ebd ? itens.ebd : 0)
    + (folha.manual ? itens.manual : 0)
    + (folha.conduta ? itens.conduta : 0)
    + (folha.secoes_dia || 0) * itens.secao_manual
    + (folha.atividade_extra || 0)
    + (folha.pontos_jogos || 0)
}
