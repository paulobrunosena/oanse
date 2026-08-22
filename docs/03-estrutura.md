# Oanse — Estrutura de Diretórios (Nuxt 4 + Supabase)

> Estado REAL do repositório. Itens marcados como **(planejado)** ainda não
> existem e pertencem a fases futuras (ver docs/04-roadmap.md).

```
oanse/
├── .env.example
├── .env                          # credenciais locais (127.0.0.1) — NUNCA comitar
├── .env.test                     # cópia local p/ ambiente de teste (gitignored)
├── AGENTS.md                     # instruções para agentes de IA
├── README.md
├── eslint.config.mjs
├── nuxt.config.ts
├── vitest.config.ts              # ambiente nuxt (@nuxt/test-utils) + happy-dom
├── package.json
├── tsconfig.json
│
├── docs/                         # planejamento e decisões de arquitetura
│   ├── 01-schema.sql             # DDL, triggers, views + regras de negócio (RN 1..7)
│   ├── 02-rls-policies.sql       # políticas RLS por perfil (documentação viva)
│   ├── 03-estrutura.md           # este arquivo
│   └── 04-roadmap.md             # roteiro em 4 fases
│
├── .agents/checklist.md          # progresso de implementação (marcar [x])
│
├── .github/workflows/ci.yml      # lint + typecheck + testes + reset do banco + asserts RLS
│
├── supabase/                     # CLI do Supabase (npx supabase init/start)
│   ├── config.toml
│   ├── migrations/               # fonte de verdade do schema
│   │   ├── 0001_schema.sql
│   │   ├── 0002_rls.sql
│   │   ├── 0003_grants.sql
│   │   ├── 0004_folha_recalcular_presenca.sql
│   │   ├── 0005_remanejamento_select.sql
│   │   ├── 0006_transferencia_rpc.sql
│   │   └── 0007_dias_sem_oanse.sql
│   └── seed.sql                  # clubes, itens de pontuação, config de jogos
│
├── public/                       # assets estáticos servidos na raiz (/)
│   └── logos/
│       ├── oanse.png             # logo principal (sidebar, login)
│       ├── clube-ursinhos.png
│       ├── clube-faiscas.png
│       ├── clube-flamas.png
│       └── clube-tochas.png      # nomeados pelo slug (logoClube em utils/data.ts)
│
├── app/                          # (Nuxt 4: srcDir padrão é app/)
│   ├── app.vue
│   │
│   ├── assets/css/main.css       # tailwind + Nuxt UI import
│   │
│   ├── components/
│   │   ├── encontro/
│   │   │   ├── EncontroSeletor.vue  # seletor de sábado (histórico) — Chamada/Folha
│   │   │   └── EncontroSeletor.spec.ts
│   │   └── folha/
│   │       ├── FolhaSemanalRow.vue  # linha da folha com preview de total
│   │       └── FolhaSemanalRow.spec.ts
│   │   # (planejado) ui/AppSidebar, PageHeader, DataTable
│   │   # (planejado) folha/FolhaIndividualForm, VisitanteCard, VisitaTracker
│   │   # (planejado) jogos/, premiacoes/, ranking/
│   │
│   ├── composables/
│   │   ├── useAuth.ts            # user + profile + logout (+ useAuth.spec.ts)
│   │   ├── useRole.ts            # helpers: isDiretorGeral, isSecretaria... (+ .spec.ts)
│   │   ├── useEncontro.ts        # sábado corrente + histórico + RN 7 (sem Oanse) (+ .spec.ts)
│   │   ├── useFolhaSemanal.ts    # itens de pontuação + folhas + salvar (+ .spec.ts)
│   │   ├── useRemanejamentos.ts  # substituição temporária de turma (+ .spec.ts)
│   │   └── useTransferencias.ts  # transferência permanente (RPC 0006) (+ .spec.ts)
│   │   # (planejado) useTurma, useFolhaIndividual, useVisitantes,
│   │   # useJogos, useRanking, usePendencias (realtime)
│   │
│   ├── layouts/
│   │   ├── blank.vue             # tela de login
│   │   └── default.vue           # app shell + sidebar por perfil
│   │
│   ├── middleware/
│   │   ├── auth.global.ts        # exige sessão em tudo exceto /login
│   │   └── role.ts               # routeMiddleware por perfil (RBAC de rota)
│   │
│   ├── pages/
│   │   ├── login.vue
│   │   ├── index.vue             # dashboard por perfil
│   │   ├── chamada.vue           # Líder (com seletor de sábado)
│   │   ├── folha-semanal.vue     # Líder (com seletor de sábado)
│   │   ├── clube/
│   │   │   ├── turmas.vue               # Diretor de Clube
│   │   │   ├── lideres.vue              # Diretor de Clube (catálogo da equipe)
│   │   │   ├── oansistas.vue            # Diretor de Clube (CRUD + import CSV)
│   │   │   ├── remanejamentos.vue       # Diretor de Clube
│   │   │   └── transferencias.vue       # Diretor de Clube
│   │   └── admin/
│   │       ├── usuarios.vue             # Diretor Geral
│   │       ├── clubes.vue               # Diretor Geral
│   │       ├── calendario.vue           # sábados sem Oanse (RN 7) — Diretor Geral
│   │       └── configuracoes.vue        # itens de pontuação / pontos de jogos
│   │   # (planejado) encontro/[id]/, secretaria/, relatorios/
│   │
│   ├── types/
│   │   ├── database.types.ts     # gerado: npx supabase gen types typescript --local
│   │   └── route-meta.d.ts       # tipos do definePageMeta (roles)
│   │   # (planejado) domain.ts
│   │
│   └── utils/
│       ├── pontos.ts             # espelhos do cálculo p/ preview no form (+ pontos.spec.ts)
│       └── data.ts               # datas dos sábados, formatação, logoClube(slug) (+ data.spec.ts)
│
├── server/                       # Nitro (SSR/API routes; NUNCA expor service_role no client)
│   ├── api/
│   │   ├── encontros/atual.get.ts         # cria/obtém sábado corrente (RN 7)
│   │   ├── transferencias.post.ts         # transferência permanente (RPC 0006)
│   │   └── usuarios/
│   │       ├── index.get.ts               # lista usuários (service_role)
│   │       ├── index.post.ts              # cria usuário auth+profile (service_role)
│   │       └── [id].delete.ts             # exclui usuário (service_role)
│   │   # (planejado) remanejamentos.post.ts, premios/[id]/entregar.post.ts
│   │   # (planejado) testes de integração das rotas (exigem stack Supabase local)
│   └── utils/
│       ├── supabaseAdmin.ts    # client com service_role (server-only)
│       └── sabado.ts           # último sábado no fuso local (puro; sabado.spec.ts)
│
└── tests/
    └── helpers/supabase.ts     # mock de cadeia do client Supabase p/ vitest
    # (planejado) playwright e2e (fluxo de um sábado)
```

## Decisões-chave

1. **RLS-first**: o frontend usa apenas a chave `anon`; toda autorização é feita no Postgres (docs/02). Rotas server (`server/api`) existem só para operações transacionais ou que exigem `service_role`.
2. **RBAC de rota** em duas camadas: `middleware/auth.global.ts` (sessão) + `middleware/role.ts` (perfil por página). A RLS continua sendo a barreira real.
3. **Realtime** apenas em `premios_pendentes` e `presencas` (painel da Secretaria e acompanhamento do sábado).
4. **`supabase/migrations`** é a fonte de verdade do schema; `docs/*.sql` são a documentação viva (mantê-los sincronizados).
5. **Dev no host/WSL2**: `npx supabase start` (Docker) + `npm run dev` (Nuxt fora de container) — ver AGENTS.md.

## Testes (vitest)

- Framework: **vitest + @vue/test-utils + happy-dom**, ambiente `nuxt` via `@nuxt/test-utils` (`vitest.config.ts`). Rodar com `npm run test`.
- Arquivos `*.spec.ts` ficam **ao lado do código** (mesma pasta), seguindo o padrão da própria função/componente testado.
- **Lógica pura** (`utils/pontos.ts`, `utils/data.ts`, `server/utils/sabado.ts`): testes de unidade simples com pragma `// @vitest-environment node`.
- **Composables**: `mockNuxtImport` (ex.: `useSupabaseClient`, `$fetch`, `useFetch`) + helper `tests/helpers/supabase.ts` (builder de cadeia com `singleData`).
- **Componentes**: `mountSuspended` com stubs dos componentes Nuxt UI (evita depender do CSS/portal no teste).
- **Rotas server (`server/api`)** exigem o stack Supabase (alias `#supabase/server` é do Nitro) → testes de integração, planejados; a lógica pura extraída (ex.: `sabado.ts`) já é coberta por unidade.
- `.env.test` (gitignored) é a fonte de variáveis do ambiente de teste; sem ele os testes rodam mesmo assim (mockam o Supabase).