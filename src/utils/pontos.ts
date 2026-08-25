export interface ItensPontuacaoMap {
  presenca: number
  uniforme: number
  biblia: number
  ebd: number
  manual: number
  conduta: number
  leitura_biblica: number
  visitante: number
  secao_sem_ajuda: number
  secao_com_ajuda: number
}

const CHAVES = [
  'presenca', 'uniforme', 'biblia', 'ebd', 'manual', 'conduta',
  'leitura_biblica', 'visitante', 'secao_sem_ajuda', 'secao_com_ajuda',
] as const

export function pontosPorChave(itens: { chave: string, pontos: number }[]): ItensPontuacaoMap {
  const mapa: ItensPontuacaoMap = {
    presenca: 0, uniforme: 0, biblia: 0, ebd: 0, manual: 0, conduta: 0,
    leitura_biblica: 0, visitante: 0, secao_sem_ajuda: 0, secao_com_ajuda: 0,
  }
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
  leitura_biblica: boolean
  visitantes_convidados: number
  secoes_sem_ajuda: number
  secoes_com_ajuda: number
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
    + (folha.leitura_biblica ? itens.leitura_biblica : 0)
    + (folha.visitantes_convidados || 0) * itens.visitante
    + (folha.secoes_sem_ajuda || 0) * itens.secao_sem_ajuda
    + (folha.secoes_com_ajuda || 0) * itens.secao_com_ajuda
    + (folha.atividade_extra || 0)
    + (folha.pontos_jogos || 0)
}