# AGENTS.md — Instruções para Agentes de IA

Guia de contexto e convenções para qualquer agente (opencode, Cursor, etc.) trabalhando neste repositório.

## O que é este projeto

Sistema web do ministério infantil Oanse (igreja local). **Vue 3 + Vite + Vue Router + Pinia + PrimeVue + Tailwind CSS (v4)** no frontend (SPA); Supabase (Postgres, Auth, RLS, Realtime) no backend. Ambientes: Docker/Supabase CLI (dev) e Vercel/Supabase Cloud (produção).

**Leia antes de começar:** `docs/03-estrutura.md` (estrutura de pastas), `docs/04-roadmap.md` (roteiro em fases) e `.agents/checklist.md` (progresso — marque `[x]` nos itens concluídos; consulte-o antes de assumir o que já existe ou falta).

> **STACK (2026-08-24):** o frontend foi migrado de **Nuxt 4 + Nuxt UI** para
> **Vue 3 + Vite + Vue Router + Pinia + PrimeVue + Tailwind CSS (v4)** (SPA). O backend Supabase
> (migrations, RLS, triggers, RPCs) permanece **intacto**. Rotas admin que usam
> `service_role` vivem no servidor h3 (`server/**` + function `api/index.ts` no
> Vercel). Histórico da migração: `docs/05-migracao-vue-primevue.md`.

## Comandos

```bash
npx supabase start             # sobe o stack local do Supabase (Docker)
npm run dev                    # Vite dev server (localhost:5173), com proxy /api -> :8787
npm run dev:api                # servidor local da API (h3, tsx watch) — necessário em dev
npm run start:api              # sobe a API uma vez
npm run lint                   # ESLint (rodar antes de todo commit)
npm run typecheck              # vue-tsc (rodar antes de todo commit)
npm run test                   # vitest (unit + stores + componentes + composables)
npm run test:watch             # vitest em modo watch
npx supabase db reset          # recria banco local (migrations + seed)
npx supabase gen types typescript --local > src/types/database.types.ts  # após mudança de schema
```

> **Como rodar os comandos npm (IMPORTANTE):** o ambiente roda no WSL2 com o Node
> gerenciado por **nvm** (Linux). Os comandos `npm`/`npx` SÓ funcionam em shell
> **interativo** do WSL (que carrega o nvm do `~/.bashrc`). Se a ferramenta de
> automação (ex.: opencode) estiver rodando pelo **PowerShell do Windows**, invoque
> sempre por um shell interativo do WSL, NÃO por `wsl bash -lc` (não-interativo, que
> não carrega o nvm e cai no `node.exe`/`npm` do Windows — não executa no Linux):
>
> ```powershell
> # escrever o script em um arquivo .sh (sem CRLF) e executar com bash interativo:
> wsl -d Ubuntu bash -c "bash -i /caminho/para/script.sh"
> ```
>
> Sintomas de shell não-interativo (falso alarme, NÃO é erro de código): `'vue-tsc'
> não é reconhecido`, `'eslint' não é reconhecido`, `node: command not found`. O
> ambiente em si está correto — apenas rode num shell interativo do WSL.

> **Dev env (importante):** o frontend roda no WSL2/host com `npm run dev` (Vite)
> e a API com `npm run dev:api` (h3 em `localhost:8787`), NÃO em container. O Docker
> fica reservado ao stack do Supabase (`npx supabase start`). Rodar em container força
> o browser a alcançar o Supabase via `host.docker.internal`, que só resolve dentro do
> Docker — causa `ERR_CONNECTION_TIMED_OUT` no login. As credenciais locais
> (`127.0.0.1`) vivem no `.env` (`VITE_*`) e funcionam para browser e server-side.

> **Testes:** vitest + @vue/test-utils + happy-dom. Arquivos `*.spec.ts` ao lado do
> código. O `.env.test` (gitignored) é uma cópia do `.env` local; sem ele os testes
> rodam mesmo assim (mockam o Supabase via `vi.mock('@/lib/supabase')`).

## Arquitetura e regras invioláveis

1. **RLS-first.** O frontend usa SOMENTE a chave `anon`. Toda autorização vive nas políticas RLS (`supabase/migrations/0002_rls.sql`). Nunca confie apenas em `src/router/guards.ts` — ele é UX, não segurança.
2. **`service_role` apenas no servidor.** A chave `VITE_SUPABASE_SERVICE_ROLE_KEY` só pode ser usada em `server/lib/supabaseAdmin.ts` e rotas `server/**` / `api/**`. Nunca importe nada que a exponha em `src/`.
3. **Schema por migrations.** Fonte de verdade: `supabase/migrations/*.sql`. Os arquivos em `docs/` são a documentação viva — ao alterar o schema, atualize a migration E o doc correspondente, depois rode `npx supabase db reset` e gere os types novamente.
4. **Lógica de negócio no banco quando for pontuação/auditoria.** Cálculos de total da folha, pontos de jogos, zeramento por falta e geração de pendências são feitos por triggers (`docs/01-schema.sql`). Não duplique essas regras no cliente além de um preview de leitura (`src/utils/pontos.ts`).
5. **Realtime é intencional.** Apenas `premios_pendentes` e `presencas` estão no publication. Não adicione tabelas ao Realtime sem justificativa.
6. **Perfis RBAC:** `diretor_geral`, `secretaria`, `diretor_clube`, `lider` (enum `user_role` em `profiles`). Escopo de clube vem de `profiles.clube_id`; escopo de turma do líder vem de `turmas.lider_id` + `remanejamentos_temporarios`.
7. **Testes automatizados em todo código novo/alteração.** Toda funcionalidade, correção ou ajuste DEVE vir acompanhado de testes `*.spec.ts` (ver convenções abaixo) e passar em `npm run test` antes de concluir a tarefa.

## Convenções de código

- TypeScript estrito; use os tipos gerados em `src/types/database.types.ts` para queries Supabase.
- Estilo: **Tailwind CSS v4** (plugin `@tailwindcss/vite` + `tailwindcss-primeui`, que mapeia os tokens `--p-*` do PrimeVue para utilitárias como `text-surface-500`/`bg-primary-50`). CSS em `src/assets/tailwind.css`. Não adicione cores hardcoded no template; use as utilitárias ou o tema PrimeVue.
- App shell: o layout autenticado é baseado no **template Sakai** do PrimeVue (`src/layouts/`: AppLayout/AppSidebar/AppTopbar/AppMenu/AppMenuItem/AppFooter + `composables/layout.ts` + SCSS em `src/assets/layout/`). Ao alterar o shell, mantenha essa estrutura.
- Componentes: `src/components/` agrupados por domínio (`folha/`, `jogos/`, `premiacoes/`, `ranking/`).
- Estado/lógica de dados: stores em `src/stores/` (`useXStore`) e composables em `src/composables/` (`useX.ts`).
- Telas: `src/views/` espelhando as rotas (`admin/`, `clube/`).
- Commits em português, conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`.
- Nunca comitar segredos: `.env` está no `.gitignore` e deve continuar. Chaves locais do Supabase demo não vão para produção.
- Não criar arquivos de documentação além dos existentes em `docs/` sem pedido explícito.

## Convenções de teste (vitest)

- **Teste ao lado do código**: `foo.ts` → `foo.spec.ts` na mesma pasta. Imports explícitos de `vitest` (`import { describe, expect, it, vi } from 'vitest'`).
- **Lógica pura**: teste direto, sem ambiente Vue (pragma `// @vitest-environment node` no topo do arquivo).
- **Stores**: `setActivePinia(createPinia())` no `beforeEach` + mock de `@/lib/supabase` via `vi.hoisted`/getter; `tests/helpers/supabase.ts` (builder de cadeia com `singleData`).
- **Composables**: mock de `@/lib/supabase` (getter reatribuível por teste) + `global.fetch` para as rotas `apiFetch`; teste a fachada (`useX()`).
- **Componentes**: `mount` de `@vue/test-utils` com stubs dos componentes PrimeVue (`global: { stubs: { Select: ..., Button: ... } }`).
- **Rotas `server/api`**: NÃO testáveis em unidade (h3 + Supabase real); extraia a lógica pura para `server/utils/*` e teste a função. Testes de integração das rotas ficam planejados (exigem stack Supabase local).
- **Mock de reatividade do Vue**: arrays de `ref([])` são proxies — compare com `toContainEqual`/`toEqual`, não `toContain`.

## Checklist de fim de tarefa

1. `npm run lint` passando (e typecheck, quando configurado).
2. `npm run test` passando — **todo código novo ou alterado DEVE ter `*.spec.ts` cobrindo a mudança**.
3. `npx supabase db reset` sem erros se houve mudança de SQL.
4. Types regenerados se o schema mudou.
5. Item correspondente marcado em `.agents/checklist.md`.
6. Commit com mensagem conventional, em português.

## Registrar mudanças importantes (obrigatório)

Sempre que concluir algo relevante — regra de negócio nova/alterada, mudança de
schema/RLS, feature de tela, mudança de configuração/ambiente ou arquitetura —
**verifique e atualize a documentação** antes de dar a tarefa por feita:

1. **Regra de negócio** → `docs/01-schema.sql` (seção de RNs; ex.: `RN 1`..`RN 7`)
   e/ou `docs/02-rls-policies.sql` se envolver autorização.
2. **Novos arquivos** (páginas, composables, componentes, rotas server, migrations)
   → `docs/03-estrutura.md` (reflete o estado REAL; itens ainda não criados ficam
   marcados como "(planejado)").
3. **Progresso** → `.agents/checklist.md` (marcar `[x]` no item da fase).
4. **Comandos/ambiente/arquitetura** → `AGENTS.md` (seção "Comandos",
   "Arquitetura e regras invioláveis" ou "Convenções de código").
5. **Schema migrado** → nova migration `supabase/migrations/000N_*.sql` +
   `npx supabase db reset` + `npx supabase gen types` (tipos regenerados).

Regra de bolso: **se o código mudou, a doc correspondente muda junto.** Não
comitar mudança de schema/regra sem atualizar `docs/01` e `docs/02`.
