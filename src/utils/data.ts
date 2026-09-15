export function formatarDataCurta(iso: string): string {
  return new Date(`${iso}T00:00:00`).toLocaleDateString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric',
  })
}

/** Formata um timestamp (ISO) como DD/MM/AAAA HH:mm no fuso local. */
export function formatarDataHora(iso: string): string {
  const d = new Date(iso)
  const dia = String(d.getDate()).padStart(2, '0')
  const mes = String(d.getMonth() + 1).padStart(2, '0')
  const ano = d.getFullYear()
  const h = String(d.getHours()).padStart(2, '0')
  const min = String(d.getMinutes()).padStart(2, '0')
  return `${dia}/${mes}/${ano} ${h}:${min}`
}

/** Logo de um clube (arquivos em public/logos/, nomeados pelo slug). */
export function logoClube(slug: string | null | undefined): string | null {
  if (!slug) return null
  return `/logos/clube-${slug}.png`
}
