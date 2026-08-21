/**
 * Guarda global de autenticação: exige sessão em toda rota exceto /login
 * e garante que o profile esteja carregado antes das páginas.
 */
export default defineNuxtRouteMiddleware(async (to) => {
  const { user, loadProfile } = useAuth()

  if (!user.value) {
    if (to.path === '/login') return
    return navigateTo('/login')
  }

  if (to.path === '/login') return navigateTo('/')
  await loadProfile()
})
