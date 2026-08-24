import { useToast as usePrimeToast } from 'primevue/usetoast'

export interface ToastOptions {
  title: string
  description?: string
  color?: 'success' | 'error' | 'warning' | 'info' | 'neutral' | string
}

const SEVERIDADE: Record<string, string> = {
  success: 'success',
  error: 'error',
  warning: 'warn',
  info: 'info',
  neutral: 'info',
}

/**
 * Fachada do Toast do PrimeVue mantendo a API usada nas telas
 * (`toast.add({ title, description, color })`), como no Nuxt UI.
 */
export function useToast() {
  const toast = usePrimeToast()

  function add(opcoes: ToastOptions) {
    toast.add({
      severity: SEVERIDADE[opcoes.color ?? 'info'] ?? 'info',
      summary: opcoes.title,
      detail: opcoes.description,
      life: 3000,
    })
  }

  return { add }
}
