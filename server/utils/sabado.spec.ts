// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { sabadoCorrente } from './sabado'

// Datas construídas em meia-noite local => resultado independente do fuso.
describe('sabadoCorrente', () => {
  it('retorna o próprio dia quando é sábado', () => {
    expect(sabadoCorrente(new Date(2026, 0, 3))).toBe('2026-01-03')
  })

  it('retorna o sábado anterior no domingo', () => {
    expect(sabadoCorrente(new Date(2026, 0, 4))).toBe('2026-01-03')
  })

  it('retorna o sábado anterior em uma quinta-feira', () => {
    expect(sabadoCorrente(new Date(2026, 0, 1))).toBe('2025-12-27')
  })

  it('retorna o sábado anterior em uma sexta-feira', () => {
    expect(sabadoCorrente(new Date(2026, 0, 9))).toBe('2026-01-03')
  })

  it('atravessa a virada do ano corretamente', () => {
    expect(sabadoCorrente(new Date(2026, 0, 1))).toBe('2025-12-27')
  })

  it('respeita o final do mês', () => {
    expect(sabadoCorrente(new Date(2026, 1, 1))).toBe('2026-01-31')
  })
})
