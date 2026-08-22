import type { Database } from '~/types/database.types'

export type Encontro = Database['public']['Tables']['encontros']['Row']

/**
 * Encontro do sábado corrente — busca ou cria via server/api/encontros/atual.
 * Criado no servidor (service_role) para qualquer perfil autenticado conseguir
 * lançar a chamada do sábado, mesmo que o encontro ainda não exista.
 */
export function useEncontro() {
  const encontro = useState<Encontro | null>('encontro:atual', () => null)
  const carregando = useState<boolean>('encontro:carregando', () => false)
  const erro = useState<string | null>('encontro:erro', () => null)

  async function carregar() {
    carregando.value = true
    erro.value = null
    try {
      encontro.value = await $fetch<Encontro>('/api/encontros/atual')
    }
    catch {
      encontro.value = null
      erro.value = 'Não foi possível carregar o encontro do sábado.'
    }
    finally {
      carregando.value = false
    }
  }

  return { encontro, carregando, erro, carregar }
}
