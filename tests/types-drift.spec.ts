// @vitest-environment node
import { execFileSync } from 'node:child_process'
import { mkdtempSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

/** Roda o comparador como CLI (mesmo caminho do CI) e devolve o exit code. */
function comparar(gerado: string, commitado: string): number {
  const dir = mkdtempSync(join(tmpdir(), 'oanse-tipos-'))
  const a = join(dir, 'gerado.ts')
  const b = join(dir, 'commitado.ts')
  writeFileSync(a, gerado)
  writeFileSync(b, commitado)

  try {
    execFileSync(process.execPath, [join(process.cwd(), 'scripts/comparar-types.mjs'), a, b], {
      stdio: 'pipe',
    })
    return 0
  }
  catch (e) {
    return (e as { status?: number }).status ?? 1
  }
}

describe('scripts/comparar-types.mjs', () => {
  it('aceita o mesmo conteúdo com formatação/versões diferentes do CLI', () => {
    const gerado = [
      '',
      'export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]',
      'export type Database = {',
      '  "public": {',
      '    Tables: {',
      '      "clubes": {',
      '        Row: {',
      '          "id": string,"cor": string | null',
      '        }',
      '        ComputedFields: never',
      '      }',
      '    }',
      '    Functions: {',
      '      "fn_clube_id": { Args: Record<PropertyKey, never>; Returns: string }',
      '      "fn_criar_jogo": { Args: { "p_clubes": (string)[] } }',
      '    }',
      '  }',
      '}',
    ].join('\n')

    const commitado = [
      'export type Json =',
      '  | string',
      '  | number',
      '  | boolean',
      '  | null',
      '  | { [key: string]: Json | undefined }',
      '  | Json[]',
      '',
      'export type Database = {',
      '  public: {',
      '    Tables: {',
      '      clubes: {',
      '        Row: {',
      '          id: string',
      '          cor: string | null',
      '        }',
      '      }',
      '    }',
      '    Functions: {',
      '      fn_clube_id: { Args: never; Returns: string }',
      '      fn_criar_jogo: { Args: { p_clubes: string[] } }',
      '    }',
      '  }',
      '}',
    ].join('\n')

    expect(comparar(gerado, commitado)).toBe(0)
  })

  it('acusa drift quando uma tabela/coluna nova ainda não foi regenerada', () => {
    const gerado = 'export type Database = { public: { Tables: { clubes: { Row: { id: string, cor: string | null } } } } }'
    const commitado = 'export type Database = { public: { Tables: { clubes: { Row: { id: string } } } } }'

    expect(comparar(gerado, commitado)).toBe(1)
  })

  it('sai com código 2 quando falta argumento', () => {
    try {
      execFileSync(process.execPath, [join(process.cwd(), 'scripts/comparar-types.mjs')], { stdio: 'pipe' })
      expect.unreachable()
    }
    catch (e) {
      expect((e as { status?: number }).status).toBe(2)
    }
  })
})
