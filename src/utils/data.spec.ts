// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { formatarDataCurta, formatarDataHora, logoClube } from './data'

describe('formatarDataCurta', () => {
  it('formata data ISO como DD/MM/AAAA', () => {
    expect(formatarDataCurta('2026-08-22')).toBe('22/08/2026')
  })

  it('preserva o dia mesmo no primeiro dia do mês', () => {
    expect(formatarDataCurta('2026-01-01')).toBe('01/01/2026')
  })

  it('preserva o dia mesmo no último dia do ano', () => {
    expect(formatarDataCurta('2025-12-31')).toBe('31/12/2025')
  })
})

describe('formatarDataHora', () => {
  it('formata timestamp como DD/MM/AAAA HH:mm', () => {
    expect(formatarDataHora('2026-09-15T10:30:00')).toBe('15/09/2026 10:30')
  })
})

describe('logoClube', () => {
  it('retorna o caminho da logo para um slug', () => {
    expect(logoClube('ursinhos')).toBe('/logos/clube-ursinhos.png')
  })

  it('retorna null para slug nulo', () => {
    expect(logoClube(null)).toBeNull()
  })

  it('retorna null para slug indefinido', () => {
    expect(logoClube(undefined)).toBeNull()
  })

  it('retorna null para slug vazio', () => {
    expect(logoClube('')).toBeNull()
  })
})
