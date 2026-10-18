// @vitest-environment node
import { describe, expect, it } from 'vitest'
import config from '../vite.config'

/**
 * Guarda contra a regressão "primeiro clique do menu não navega" em dev:
 * as deps do PrimeVue vêm do auto-import (unplugin-vue-components), então não
 * aparecem na varredura inicial do Vite. Sem o warmup, a primeira visita a cada
 * tela otimiza deps em pleno clique e o Vite força um reload que cancela a
 * navegação (a tela só abre no 2º clique).
 */
describe('vite.config', () => {
  it('pré-aquece as telas no dev server para o Vite descobrir as deps do auto-import', () => {
    const clientFiles = config.server?.warmup?.clientFiles ?? []
    expect(clientFiles).toContain('./src/views/**/*.vue')
    expect(clientFiles).toContain('./src/layouts/**/*.vue')
    expect(clientFiles).toContain('./src/components/**/*.vue')
  })

  it('mantém o proxy /api para o backend h3 local', () => {
    expect(config.server?.proxy?.['/api']).toBe('http://localhost:8787')
  })
})
