export function formatarDataCurta(iso: string): string {
  return new Date(`${iso}T00:00:00`).toLocaleDateString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric',
  })
}

/** Logo de um clube (arquivos em public/logos/, nomeados pelo slug). */
export function logoClube(slug: string | null | undefined): string | null {
  if (!slug) return null
  return `/logos/clube-${slug}.png`
}
