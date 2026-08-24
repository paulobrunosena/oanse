import { storeToRefs } from 'pinia'
import { useEncontroStore, type Encontro } from '@/stores/encontro'

export type { Encontro }

/**
 * Encontro do sábado corrente + histórico (fachada sobre a store).
 */
export function useEncontro() {
  const store = useEncontroStore()
  return {
    ...storeToRefs(store),
    carregar: store.carregar,
    carregarHistorico: store.carregarHistorico,
    selecionar: store.selecionar,
  }
}
