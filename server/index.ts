import { createServer } from 'node:http'
import { toNodeListener } from 'h3'
import { createApiApp } from './router'

// Carrega o .env local (chaves Supabase, PORT) para o processo do servidor.
try {
  process.loadEnvFile()
} catch {
  // Sem .env — segue com as variáveis de ambiente do processo.
}

/**
 * Servidor local da API (h3). O Vite faz proxy de /api para esta porta.
 * Rodar com: node --watch server/index.ts (ou via script npm).
 */
const port = Number(process.env.PORT ?? 8787)

createServer(toNodeListener(createApiApp())).listen(port, () => {
  console.log(`API Oanse local em http://localhost:${port}`)
})
