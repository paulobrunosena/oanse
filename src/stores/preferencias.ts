import { ref } from 'vue'
import { defineStore } from 'pinia'

const CHAVE = 'oanse:rotulos-acoes'

function lerValor(): boolean {
  try {
    return window.localStorage.getItem(CHAVE) === '1'
  }
  catch {
    return false
  }
}

/**
 * Preferências de interface do usuário (persistidas no navegador).
 */
export const usePreferenciasStore = defineStore('preferencias', () => {
  const rotulosAcoes = ref(lerValor())

  function alternarRotulosAcoes() {
    rotulosAcoes.value = !rotulosAcoes.value
    try {
      window.localStorage.setItem(CHAVE, rotulosAcoes.value ? '1' : '0')
    }
    catch {
      /* localStorage indisponível (ex.: modo privado) — mantém apenas em memória */
    }
  }

  return { rotulosAcoes, alternarRotulosAcoes }
})
