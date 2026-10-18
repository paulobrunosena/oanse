// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { ehSabado, parseDataLocal, sabadoCorrente, semanasAtras, validarDataRetroativa } from './sabado'

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

describe('parseDataLocal', () => {
  it('converte uma data ISO local válida', () => {
    const dt = parseDataLocal('2026-08-22')
    expect(dt?.getFullYear()).toBe(2026)
    expect(dt?.getMonth()).toBe(7)
    expect(dt?.getDate()).toBe(22)
  })

  it('rejeita formatos inválidos e datas impossíveis', () => {
    expect(parseDataLocal('22/08/2026')).toBeNull()
    expect(parseDataLocal('2026-13-01')).toBeNull()
    expect(parseDataLocal('2026-02-30')).toBeNull()
    expect(parseDataLocal('abc')).toBeNull()
  })
})

describe('ehSabado', () => {
  it('reconhece um sábado', () => {
    expect(ehSabado('2026-08-22')).toBe(true)
  })

  it('rejeita outros dias', () => {
    expect(ehSabado('2026-08-23')).toBe(false)
  })
})

describe('validarDataRetroativa', () => {
  const sabado = new Date(2026, 7, 22) // sábado 22/08/2026

  it('aceita um sábado passado', () => {
    expect(validarDataRetroativa('2026-08-15', sabado)).toEqual({ ok: true })
  })

  it('aceita o próprio sábado corrente', () => {
    expect(validarDataRetroativa('2026-08-22', sabado)).toEqual({ ok: true })
  })

  it('rejeita data inválida', () => {
    expect(validarDataRetroativa('2026-02-30', sabado).ok).toBe(false)
    expect(validarDataRetroativa('abc', sabado).ok).toBe(false)
  })

  it('rejeita dia que não é sábado', () => {
    expect(validarDataRetroativa('2026-08-23', sabado)).toEqual({ ok: false, motivo: 'A data precisa ser um sábado' })
  })

  it('rejeita data futura (além do sábado corrente)', () => {
    expect(validarDataRetroativa('2026-08-29', sabado)).toEqual({ ok: false, motivo: 'A data não pode estar no futuro' })
  })
})

describe('semanasAtras', () => {
  const quarta = new Date(2026, 9, 14) // quarta 14/10/2026 (sábado corrente: 10/10)

  it('conta os sábados atrás do sábado corrente', () => {
    expect(semanasAtras('2026-10-10', quarta)).toBe(0)
    expect(semanasAtras('2026-10-03', quarta)).toBe(1)
    expect(semanasAtras('2026-09-12', quarta)).toBe(4)
    expect(semanasAtras('2026-07-18', quarta)).toBe(12)
    expect(semanasAtras('2026-07-11', quarta)).toBe(13)
  })

  it('devolve null para data inválida', () => {
    expect(semanasAtras('2026-02-30', quarta)).toBeNull()
    expect(semanasAtras('abc', quarta)).toBeNull()
  })
})
