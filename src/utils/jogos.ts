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

/** RN: um jogo tem no máximo 4 times. */
export function podeAdicionarTime(qtdTimes: number): boolean {
  return qtdTimes < 4
}

/** RN: um jogo tem no mínimo 2 times para lançar o placar. */
export function podeLancarResultado(qtdTimes: number): boolean {
  return qtdTimes >= 2
}