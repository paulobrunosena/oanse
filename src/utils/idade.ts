export interface ClubeFaixa {
  id: string
  nome: string
  idade_min: number
  idade_max: number
}

export type AvaliacaoIdade =
  | { tipo: 'vazio' }
  | { tipo: 'invalido' }
  | { tipo: 'muito_novo' }
  | { tipo: 'clube_correto' }
  | { tipo: 'clube_diferente', clubeSugerido: ClubeFaixa }
  | { tipo: 'fora_de_todas' }

/**
 * Idade em anos completos a partir de uma data no formato AAAA-MM-DD.
 * Retorna null para data vazia, inválida ou no futuro.
 */
export function idadeEmAnos(nascimento: string, referencia: Date = new Date()): number | null {
  if (!nascimento) return null
  const nasc = new Date(`${nascimento}T00:00:00`)
  if (Number.isNaN(nasc.getTime()) || nasc.getTime() > referencia.getTime()) return null

  let anos = referencia.getFullYear() - nasc.getFullYear()
  const fezAniversario =
    referencia.getMonth() > nasc.getMonth()
    || (referencia.getMonth() === nasc.getMonth() && referencia.getDate() >= nasc.getDate())
  if (!fezAniversario) anos -= 1

  return anos
}

/** Clube cuja faixa etária (idade_min..idade_max) contém a idade informada. */
export function clubePorIdade(clubes: ClubeFaixa[], idade: number): ClubeFaixa | null {
  return clubes.find(c => idade >= c.idade_min && idade <= c.idade_max) ?? null
}

/**
 * Avalia a data de nascimento contra o clube de destino:
 * - 'muito_novo': nasceu no ano corrente (0 anos) — não pode ser cadastrada;
 * - 'clube_diferente': a idade pertence a outro clube — pedir confirmação;
 * - 'clube_correto': idade compatível com o clube de destino;
 * - 'fora_de_todas': idade válida, mas fora de qualquer faixa de clube.
 */
export function avaliarIdadeClube(
  clubes: ClubeFaixa[],
  nascimento: string,
  clubeId: string | null | undefined,
  referencia: Date = new Date(),
): AvaliacaoIdade {
  if (!nascimento || !clubeId) return { tipo: 'vazio' }

  const idade = idadeEmAnos(nascimento, referencia)
  if (idade === null) return { tipo: 'invalido' }
  if (idade === 0) return { tipo: 'muito_novo' }

  const sugerido = clubePorIdade(clubes, idade)
  if (!sugerido) return { tipo: 'fora_de_todas' }
  if (sugerido.id === clubeId) return { tipo: 'clube_correto' }

  return { tipo: 'clube_diferente', clubeSugerido: sugerido }
}
