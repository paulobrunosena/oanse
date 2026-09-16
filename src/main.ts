import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ConfirmationService from 'primevue/confirmationservice'
import ToastService from 'primevue/toastservice'
import Tooltip from 'primevue/tooltip'
import { primevuePreset } from '@/lib/theme'
import '@/assets/tailwind.css'
import '@/assets/styles.scss'
import App from './App.vue'
import router from './router'
import { setupGuards } from './router/guards'
import { supabase } from './lib/supabase'
import { useAuthStore } from './stores/auth'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
setupGuards(router)
app.use(router)
app.use(PrimeVue, {
  license: import.meta.env.VITE_PRIMEUI_LICENSE_KEY || '',
  theme: {
    preset: primevuePreset,
    options: { darkModeSelector: '.app-dark' },
  },
})
app.use(ToastService)
app.use(ConfirmationService)
app.directive('tooltip', Tooltip)

// Aguarda a primeira navegação (guards de sessão/perfil) antes de montar —
// evita o flash de shell vazio/rota errada na abertura.
router.isReady().then(() => app.mount('#app'))

// Mantém a sessão sincronizada (login/logout/refresh de token)
supabase.auth.onAuthStateChange((_evento, sessao) => {
  const auth = useAuthStore()
  auth.setUser(
    sessao?.user
      ? { sub: sessao.user.id, email: sessao.user.email ?? undefined }
      : null,
  )
})
