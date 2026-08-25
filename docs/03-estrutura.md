# Oanse — Estrutura de Diretórios (Vue 3 + Vite + PrimeVue)

> Estado REAL do repositório. Itens marcados como **(planejado)** ainda não
> existem e pertencem a fases futuras (ver docs/04-roadmap.md).

```
oanse/
├── .env.example                  # VITE_SUPABASE_URL / ANON_KEY / SERVICE_ROLE_KEY + PORT
├── .env                          # credenciais locais (127.0.0.1) — NUNCA comitar
├── .env.test                     # cópia local p/ ambiente de teste (gitignored)
├── AGENTS.md                     # instruções para agentes de IA
├── README.md
├── eslint.config.mjs             # flat config (ts + vue)
├── vite.config.ts                # plugin-vue + tailwindcss + alias @/src + proxy /api -> :8787
├── vitest.config.ts              # happy-dom + alias @ (vitest puro, sem nuxt)
├── vercel.json                   # rewrite /api/* -> /api/index (function única h3)
├── package.json
├── tsconfig.json                 # app (src + tests) — vue-tsc
├── tsconfig.node.json            # server/ + api/ + vite/vitest config (node types)
│
├── docs/                         # planejamento e decisões de arquitetura
│   ├── 01-schema.sql             # DDL, triggers, views + regras de negócio (RN 1..7)
│   ├── 02-rls-policies.sql       # políticas RLS por perfil (documentação viva)
│   ├── 03-estrutura.md           # este arquivo
│   ├── 04-roadmap.md             # roteiro em fases
│   └── 05-migracao-vue-primevue.md # plano + estado da migração Nuxt → Vue + PrimeVue
│
├── .agents/checklist.md          # progresso de implementação (marcar [x])
│
├── .github/workflows/ci.yml      # lint + typecheck + testes + build + reset do banco + asserts RLS
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
│   │   ├── 0007_dias_sem_oanse.sql
│   │   └── 0008_folha_novos_itens.sql
│   └── seed.sql                  # clubes, itens de pontuação, config de jogos
│
├── public/                       # assets estáticos servidos na raiz (/)
│   └── logos/
│       ├── oanse.png             # logo principal (sidebar, login)
│       ├── clube-ursinhos.png
│       ├── clube-faiscas.png
│       ├── clube-flamas.png
│       └── clube-tochas.png      # nomeados pelo slug (logoClube em src/utils/data.ts)
│
├── src/
│   ├── main.ts                   # createApp + pinia + router + PrimeVue(Aura) + ToastService + CSS (tailwind + layout)
│   ├── App.vue                   # <router-view /> + <Toast />
│   ├── assets/
│   │   ├── tailwind.css          # Tailwind v4 + plugin tailwindcss-primeui (tokens PrimeVue) + dark variant
│   │   ├── styles.scss           # primeicons + SCSS do shell do layout
│   │   └── layout/               # SCSS do app shell Sakai (core, menu, topbar, sidebar, variáveis)
│   │
│   ├── lib/
│   │   ├── supabase.ts           # client anon (browser) — SÓ anon key
│   │   └── api.ts                # apiFetch() — wrapper fetch + Bearer token + ApiError
│   │
│   ├── stores/                   # estado global (Pinia)
│   │   ├── auth.ts               # user + profile + loadProfile + logout (+ auth.spec.ts)
│   │   ├── role.ts               # isDiretorGeral, roleLabel, hasAny (+ role.spec.ts)
│   │   └── encontro.ts           # sábado corrente + histórico + RN 7 (+ encontro.spec.ts)
│   │   # (planejado) folha, remanejamento, transferência como stores se forem globais
│   │
│   ├── composables/
│   │   ├── useAuth.ts            # fachada sobre stores/auth (user, profile, logout)
│   │   ├── useRole.ts            # fachada sobre stores/role
│   │   ├── useEncontro.ts        # fachada sobre stores/encontro
│   │   ├── useFolhaSemanal.ts    # itens de pontuação + folhas + salvar (+ spec.ts)
│   │   ├── useRemanejamentos.ts  # substituição temporária de turma (+ spec.ts)
│   │   ├── useTransferencias.ts  # transferência permanente (RPC 0006) (+ spec.ts)
│   │   └── useToast.ts           # fachada do Toast do PrimeVue (api tipo Nuxt UI)
│   │   # (planejado) useTurma, useFolhaIndividual, useVisitantes,
│   │   # useJogos, useRanking, usePendencias (realtime)
│   │
│   ├── router/
│   │   ├── index.ts              # createRouter + rotas (meta.roles por rota)
│   │   └── guards.ts             # setupGuards: auth (sessão) + role (RBAC de rota)
│   │
│   ├── layouts/                  # app shell baseado no template Sakai (PrimeVue)
│   │   ├── BlankLayout.vue       # tela de login (sem shell)
│   │   ├── AppLayout.vue         # shell: wrapper + <router-view /> + <Toast />
│   │   ├── AppSidebar.vue        # sidebar + lógica de overlay/mobile/outisde-click + perfil no rodapé (mobile)
│   │   ├── AppTopbar.vue         # topbar: toggle de menu + dark mode + logo + usuário/logout
│   │   ├── AppMenu.vue           # menu lateral por perfil (RBAC via useRole)
│   │   ├── AppMenuItem.vue       # item de menu recursivo (modelo do Sakai)
│   │   ├── AppFooter.vue         # rodapé
│   │   └── composables/layout.ts # estado do layout (menu mode, dark, sidebar)
│   │
│   ├── views/                    # espelha as rotas
│   │   ├── LoginView.vue
│   │   ├── DashboardView.vue     # dashboard por perfil
│   │   ├── ChamadaView.vue       # Líder (com seletor de sábado)
│   │   ├── FolhaSemanalView.vue  # Líder (com seletor de sábado)
│   │   ├── clube/
│   │   │   ├── TurmasView.vue            # Diretor de Clube
│   │   │   ├── LideresView.vue           # Diretor de Clube (catálogo da equipe)
│   │   │   ├── OansistasView.vue         # Diretor de Clube (CRUD + import CSV)
│   │   │   ├── RemanejamentosView.vue    # Diretor de Clube
│   │   │   └── TransferenciasView.vue    # Diretor de Clube
│   │   └── admin/
│   │       ├── UsuariosView.vue          # Diretor Geral
│   │       ├── ClubesView.vue            # Diretor Geral
│   │       ├── CalendarioView.vue        # sábados sem Oanse (RN 7) — Diretor Geral
│   │       └── ConfiguracoesView.vue     # itens de pontuação / pontos de jogos
│   │   # (planejado) encontro/[id]/, secretaria/, relatorios/
│   │
│   ├── components/
│   │   ├── encontro/
│   │   │   ├── EncontroSeletor.vue  # seletor de sábado (histórico) — Chamada/Folha
│   │   │   └── EncontroSeletor.spec.ts
│   │   └── folha/
│   │       ├── FolhaSemanalRow.vue  # linha da folha com preview de total (uniformes, bíblia, EBD, manual, conduta, leitura bíblica, visitantes, seções sem/com ajuda, atividade extra, cor do time)
│   │       └── FolhaSemanalRow.spec.ts
│   │   # (planejado) ui/AppSidebar, PageHeader, DataTable
│   │   # (planejado) folha/FolhaIndividualForm, VisitanteCard, VisitaTracker
│   │   # (planejado) jogos/, premiacoes/, ranking/
│   │
│   ├── types/
│   │   ├── database.types.ts     # gerado: npx supabase gen types typescript --local
│   │   └── router.d.ts           # tipos do RouteMeta (roles)
│   │   # (planejado) domain.ts
│   │
│   └── utils/
│       ├── pontos.ts             # espelhos do cálculo p/ preview no form (+ pontos.spec.ts)
│       ├── data.ts               # formatação de datas + logoClube(slug) (+ data.spec.ts)
│       └── sabado.ts             # último sábado no fuso local (cópia p/ client, se preciso)
│
├── server/                       # API h3 (NUNCA expor service_role no client)
│   ├── index.ts                  # servidor local (tsx) — porta PORT (default 8787)
│   ├── router.ts                 # createApiApp(): monta as rotas /api/**
│   ├── lib/
│   │   ├── supabaseAdmin.ts      # client com service_role (server-only)
│   │   └── auth.ts               # getUsuarioDoRequest(): lê Bearer token e valida JWT
│   ├── api/
│   │   ├── encontros/atual.ts    # cria/obtém sábado corrente (RN 7)
│   │   ├── transferencias.ts     # transferência permanente (RPC 0006)
│   │   └── usuarios/
│   │       ├── index.ts          # GET lista + POST cria usuário (service_role)
│   │       └── [id].ts           # DELETE exclui usuário (service_role)
│   │   # (planejado) remanejamentos.post.ts, premios/[id]/entregar.post.ts
│   ├── types/database.types.ts   # cópia dos tipos p/ o servidor
│   └── utils/sabado.ts           # último sábado no fuso local (puro; sabado.spec.ts)
│
├── api/index.ts                  # Vercel Function única: exporta toNodeListener(app h3)
│
└── tests/
    └── helpers/supabase.ts     # mock de cadeia do client Supabase p/ vitest
    # (planejado) playwright e2e (fluxo de um sábado)
```

## Decisões-chave

1. **RLS-first**: o frontend usa apenas a chave `anon`; toda autorização é feita no Postgres (docs/02). Rotas server (`server/api`) existem só para operações transacionais ou que exigem `service_role`.
2. **RBAC de rota** em duas camadas: `src/router/guards.ts` (sessão) + `meta.roles` por rota (perfil). A RLS continua sendo a barreira real.
3. **Realtime** apenas em `premios_pendentes` e `presencas` (painel da Secretaria e acompanhamento do sábado).
4. **`supabase/migrations`** é a fonte de verdade do schema; `docs/*.sql` são a documentação viva (mantê-los sincronizados).
5. **Dev no host/WSL2**: `npx supabase start` (Docker) + `npm run dev` (Vite, fora de container) + `npm run dev:api` (h3 em :8787) — ver AGENTS.md.
6. **SPA pura**: sem SSR; o deploy é estático no Vercel + function `api/index.ts` (h3) para as rotas admin.

## Testes (vitest)

- Framework: **vitest + @vue/test-utils + happy-dom** (vitest puro, sem nuxt). Rodar com `npm run test`.
- Arquivos `*.spec.ts` ficam **ao lado do código** (mesma pasta).
- **Lógica pura** (`utils/pontos.ts`, `utils/data.ts`, `server/utils/sabado.ts`): testes de unidade simples com pragma `// @vitest-environment node`.
- **Stores**: `setActivePinia(createPinia())` no `beforeEach` + `vi.mock('@/lib/supabase')` (getter reatribuível) + helper `tests/helpers/supabase.ts`.
- **Composables**: mock de `@/lib/supabase` + `global.fetch` para as rotas `apiFetch`; testa-se a fachada `useX()`.
- **Componentes**: `mount` com stubs dos componentes PrimeVue (`global: { stubs: { Select: ..., Button: ... } }`).
- **Rotas server (`server/api`)** exigem o stack Supabase (h3 + service_role) → testes de integração, planejados; a lógica pura extraída (ex.: `sabado.ts`) já é coberta por unidade.
- `.env.test` (gitignored) é a fonte de variáveis do ambiente de teste; sem ele os testes rodam mesmo assim (mockam o Supabase).
