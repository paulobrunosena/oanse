import { toNodeListener } from 'h3'
import { createApiApp } from '../server/router'

// Vercel Functions: um único endpoint para /api/* (ver vercel.json rewrite).
// O h3 resolve as rotas internamente (params, métodos).
export default toNodeListener(createApiApp())
