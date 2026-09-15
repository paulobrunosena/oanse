import { createApp, createRouter } from 'h3'
import encontroAtual from './api/encontros/atual'
import encontroRetro from './api/encontros/retro'
import transferencias from './api/transferencias'
import usuariosIndex from './api/usuarios/index'
import usuariosId from './api/usuarios/[id]'
import premioEntregar from './api/premios/[id]/entregar.post'
import premioMovimentacoes from './api/premios/[id]/movimentacoes.post'

/**
 * Monta o app h3 com todas as rotas admin. Reutilizado pelo servidor local
 * (server/index.ts) e pela function serverless (api/index.ts no Vercel).
 */
export function createApiApp() {
  const app = createApp()
  const router = createRouter()

  router.get('/api/encontros/atual', encontroAtual)
  router.post('/api/encontros/retro', encontroRetro)
  router.post('/api/transferencias', transferencias)
  router.get('/api/usuarios', usuariosIndex)
  router.post('/api/usuarios', usuariosIndex)
  router.delete('/api/usuarios/:id', usuariosId)
  router.post('/api/premios/:id/entregar', premioEntregar)
  router.post('/api/premios/:id/movimentacoes', premioMovimentacoes)

  app.use(router)
  return app
}
