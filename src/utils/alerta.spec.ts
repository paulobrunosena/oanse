// @vitest-environment node
import { describe, expect, it } from 'vitest'
import { tocarSomAlerta } from './alerta'

describe('tocarSomAlerta', () => {
  it('não lança erro sem AudioContext (ambientes headless)', () => {
    expect(() => tocarSomAlerta()).not.toThrow()
  })
})
