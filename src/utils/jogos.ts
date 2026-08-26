export interface PontosJogosConfig {
  colocacao: number
  pontos: number
  desclassificado: boolean
}

export type ResultadoJogo = {
  colocacao: number | null
  desclassificado: boolean
}

export const PONTOS_DESCLASSIFICADO = 0

/** Cores pré-definidas dos times nos jogos (combo sem digitação). */
export const CORES_PREDEFINIDAS = ['verde', 'vermelho', 'amarelo', 'azul'] as const
export type CorPredefinida = (typeof CORES_PREDEFINIDAS)[number]

const CORES_HEX: Record<CorPredefinida, string> = {
  verde: '#22C55E',
  vermelho: '#EF4444',
  amarelo: '#EAB308',
  azul: '#3B82F6',
}

/** Hex da cor pré-definida (identidade visual; espelha as cores dos clubes). */
export function corHex(cor: string): string {
  return CORES_HEX[cor as CorPredefinida] ?? '#64748b'
}

export interface JogoCatalogoItem {
  id: string
  clube_id: string
  nome: string
}

/**
 * Nomes de jogos disponíveis para o combo do registro de rodada, a partir dos
 * clubes participantes do evento. Nomes repetidos entre clubes não duplicam.
 */
export function jogosDisponiveis(catalogo: JogoCatalogoItem[], clubeIds: string[]): string[] {
  const nomes = catalogo
    .filter(i => clubeIds.includes(i.clube_id))
    .map(i => i.nome)
  return [...new Set(nomes)].sort((a, b) => a.localeCompare(b, 'pt-BR'))
}

/**
 * Nome sugerido do evento a partir dos clubes selecionados.
 * Ex.: ['Flamas', 'Tochas'] -> 'Jogos dos Flamas e Tochas'.
 */
export function gerarNomeEvento(nomesClubes: string[]): string {
  const lista = [...nomesClubes]
  if (lista.length === 0) return ''
  if (lista.length === 1) return `Jogos dos ${lista[0]}`
  const ultimo = lista.pop()!
  return `Jogos dos ${lista.join(', ')} e ${ultimo}`
}

/**
 * Pontos de uma colocação conforme `jogos_pontos_config` (espelho do trigger
 * fn_definir_pontos_resultado para preview no formulário).
 */
export function pontosDaColocacao(colocacao: number, config: PontosJogosConfig[]): number {
  return config.find(c => c.colocacao === colocacao)?.pontos ?? 0
}

export function pontosDoResultado(resultado: ResultadoJogo, config: PontosJogosConfig[]): number {
  if (resultado.desclassificado) return PONTOS_DESCLASSIFICADO
  if (resultado.colocacao == null) return 0
  return pontosDaColocacao(resultado.colocacao, config)
}

/** Rótulo ordinal da posição no ranking dos jogos (ex.: 1 -> '1º lugar'). */
export function posicaoLabel(posicao: number): string {
  return `${posicao}º lugar`
}