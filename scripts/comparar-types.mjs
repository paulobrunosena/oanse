#!/usr/bin/env node
/**
 * Compara o types gerado (`supabase gen types typescript --local`) com o
 * arquivo commitado, ignorando diferenças de formatação entre versões do CLI
 * (aspas, parênteses adicionados pelo Prettier, `ComputedFields: never`,
 * `Record<PropertyKey, never>`, `(string)[]` vs `string[]`, união com `|` inicial).
 *
 * Uso: node scripts/comparar-types.mjs <gerado.ts> <commitado.ts>
 * Sai com código 1 quando os conteúdos normalizados divergem (types defasados).
 */
import { readFileSync } from 'node:fs'

export function normalizar(conteudo) {
  return conteudo
    .replace(/ComputedFields\s*:\s*never/g, '')
    .replace(/Record<PropertyKey,\s*never>/g, 'never')
    .replace(/["']/g, '')
    .replace(/(extends|[=:(<[,])\s*\|\s*/g, '$1')
    .replace(/[\s,;()]+/g, '')
}

const [gerado, commitado] = process.argv.slice(2)
if (!gerado || !commitado) {
  console.error('uso: node scripts/comparar-types.mjs <gerado.ts> <commitado.ts>')
  process.exit(2)
}

const a = normalizar(readFileSync(gerado, 'utf8'))
const b = normalizar(readFileSync(commitado, 'utf8'))

if (a !== b) {
  console.error(
    'Types defasados em relação ao schema.\n' +
    'Rode `npx supabase gen types typescript --local > src/types/database.types.ts`,\n' +
    'mantenha a formatação do repo e replique o arquivo em server/types/database.types.ts.',
  )
  process.exit(1)
}

console.log('Types em dia com o schema.')
