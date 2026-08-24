import { createApp, createRouter } from 'h3'
import encontroAtual from './api/encontros/atual'
import transferencias from './api/transferencias'
import usuariosIndex from './api/usuarios/index'
import usuariosId from './api/usuarios/[id]'

/**
 * Monta o app h3 com todas as rotas admin. Reutilizado pelo servidor local
 * (server/index.ts) e pela function serverless (api/index.ts no Vercel).
 */
export function createApiApp() {
  const app = createApp()
  const router = createRouter()

  router.get('/api/encontros/atual', encontroAtual)
  router.post('/api/transferencias', transferencias)
  router.get('/api/usuarios', usuariosIndex)
  router.post('/api/usuarios', usuariosIndex)
  router.delete('/api/usuarios/:id', usuariosId)

  app.use(router)
  return app
}
