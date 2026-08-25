/**
 * Data do sábado mais recente no fuso local (hoje se for sábado,
 * senão o último sábado). Usado pelo endpoint /api/encontros/atual.
 *
 * A formatação usa as partes da data local (getFullYear/getMonth/getDate),
 * NÃO `toISOString()`, que converte para UTC e pode deslocar o dia quando o
 * horário local já passou para o dia seguinte em UTC.
 */
export function sabadoCorrente(d = new Date()): string {
  const dia = d.getDay()
  const diasAtras = (dia + 7 - 6) % 7
  const sabado = new Date(d)
  sabado.setDate(sabado.getDate() - diasAtras)
  const ano = sabado.getFullYear()
  const mes = String(sabado.getMonth() + 1).padStart(2, '0')
  const diaDoMes = String(sabado.getDate()).padStart(2, '0')
  return `${ano}-${mes}-${diaDoMes}`
}

/** Converte 'YYYY-MM-DD' em Date local (meia-noite). null se inválida. */
export function parseDataLocal(data: string): Date | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(data)) return null
  const [ano, mes, dia] = data.split('-').map(Number)
  const dt = new Date(ano!, mes! - 1, dia!)
  if (dt.getFullYear() !== ano || dt.getMonth() !== mes! - 1 || dt.getDate() !== dia) {
    return null
  }
  return dt
}

/** A data é um sábado? */
export function ehSabado(data: string): boolean {
  return parseDataLocal(data)?.getDay() === 6
}

/**
 * Valida uma data para criação retroativa de encontro (sábado perdido):
 * formato/calendário válidos, precisa ser sábado e não pode estar no futuro
 * (além do sábado corrente). O sábado sem Oanse (RN 7) é checado na rota.
 */
export function validarDataRetroativa(data: string, hoje = new Date()): { ok: boolean, motivo?: string } {
  const dt = parseDataLocal(data)
  if (!dt) return { ok: false, motivo: 'Data inválida' }
  if (dt.getDay() !== 6) return { ok: false, motivo: 'A data precisa ser um sábado' }
  if (data > sabadoCorrente(hoje)) return { ok: false, motivo: 'A data não pode estar no futuro' }
  return { ok: true }
}
