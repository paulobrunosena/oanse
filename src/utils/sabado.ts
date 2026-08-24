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
  sabado.setDate(d.getDate() - diasAtras)
  const ano = sabado.getFullYear()
  const mes = String(sabado.getMonth() + 1).padStart(2, '0')
  const diaDoMes = String(sabado.getDate()).padStart(2, '0')
  return `${ano}-${mes}-${diaDoMes}`
}
