# Oanse — Estrutura de Diretórios (Nuxt 4 + Supabase)

```
oanse/
├── .env.example
├── nuxt.config.ts
├── app.config.ts                 # tokens do Nuxt UI (cores por clube, etc.)
├── package.json
├── tsconfig.json
├── tailwind.config.ts             # (Tailwind v4: config via CSS em app/assets/css/main.css)
├── vitest.config.ts
│
├── docs/                         # planejamento e decisões de arquitetura
│   ├── 01-schema.sql
│   ├── 02-rls-policies.sql
│   ├── 03-estrutura.md
│   └── 04-roadmap.md
│
├── supabase/                     # CLI do Supabase (npx supabase init)
│   ├── config.toml
│   ├── migrations/
│   │   ├── 0001_schema.sql
│   │   └── 0002_rls.sql
│   └── seed.sql                  # clubes, itens de pontuação, config de jogos
│
├── app/                          # (Nuxt 4: srcDir padrão é app/)
│   ├── app.vue
│   ├── error.vue
│   │
│   ├── assets/css/main.css       # tailwind + Nuxt UI import
│   │
│   ├── components/
│   │   ├── ui/                   # wrappers do Nuxt UI / shadcn-vue
│   │   │   ├── AppSidebar.vue
│   │   │   ├── PageHeader.vue
│   │   │   └── DataTable.vue
│   │   ├── folha/                # Folha Semanal / Individual / Visitantes
│   │   │   ├── FolhaSemanalForm.vue
│   │   │   ├── FolhaIndividualForm.vue
│   │   │   ├── VisitanteCard.vue
│   │   │   └── VisitaTracker.vue
│   │   ├── jogos/
│   │   │   ├── JogoEditor.vue       # times, integrantes, colocação
│   │   │   └── JogoPlacar.vue
│   │   ├── premiacoes/
│   │   │   ├── PendenciaCard.vue    # painel da secretária (realtime)
│   │   │   └── EstoqueBadge.vue
│   │   └── ranking/
│   │       ├── RankingTable.vue
│   │       └── Pódio.vue
│   │
│   ├── composables/
│   │   ├── useAuth.ts            # user + profile + logout
│   │   ├── useRole.ts            # helpers: isDiretorGeral, isSecretaria...
│   │   ├── useEncontro.ts        # sábado corrente
│   │   ├── useTurma.ts           # turma do líder (titular/substituto)
│   │   ├── useFolhaSemanal.ts
│   │   ├── useFolhaIndividual.ts
│   │   ├── useVisitantes.ts
│   │   ├── useJogos.ts
│   │   ├── useRanking.ts
│   │   └── usePendencias.ts      # realtime channel premios_pendentes
│   │
│   ├── layouts/
│   │   ├── default.vue           # app shell + sidebar por perfil
│   │   └── auth.vue              # tela de login
│   │
│   ├── middleware/
│   │   ├── auth.global.ts        # exige sessão em tudo exceto /login
│   │   └── role.ts               # routeMiddleware por perfil (RBAC de rota)
│   │
│   ├── pages/
│   │   ├── login.vue
│   │   ├── index.vue             # dashboard por perfil
│   │   ├── encontro/
│   │   │   └── [id]/
│   │   │       ├── folha-semanal.vue     # Líder
│   │   │       ├── folha-individual/
│   │   │       │   └── [oansistaId].vue  # Líder
│   │   │       ├── visitantes.vue        # Líder
│   │   │       ├── jogos.vue             # Diretor de Clube
│   │   │       └── ranking.vue           # Todos
│   │   ├── clube/
│   │   │   ├── turmas.vue               # Diretor de Clube
│   │   │   ├── remanejamentos.vue       # Diretor de Clube
│   │   │   └── transferencias.vue       # Diretor de Clube
│   │   ├── secretaria/
│   │   │   ├── pendencias.vue           # Secretária (realtime)
│   │   │   ├── premios.vue              # catálogo + estoque
│   │   │   └── movimentacoes.vue
│   │   ├── admin/
│   │   │   ├── usuarios.vue             # Diretor Geral
│   │   │   ├── clubes.vue               # Diretor Geral
│   │   │   └── configuracoes.vue        # itens de pontuação / pontos de jogos
│   │   └── relatorios/
│   │       ├── frequencia.vue           # Diretor Geral / Diretor de Clube
│   │       └── premiacoes.vue
│   │
│   ├── plugins/
│   │   └── supabase.client.ts    # cria o client Supabase (SSR-safe)
│   │
│   ├── types/
│   │   ├── database.types.ts     # gerado: npx supabase gen types typescript
│   │   └── domain.ts             # Perfil, Clube, FolhaSemanal, etc.
│   │
│   └── utils/
│       ├── pontos.ts             # espelhos do cálculo p/ preview no form
│       └── data.ts               # datas dos sábados, formatação
│
├── server/                       # Nitro (SSR/API routes; NUNCA expor service_role no client)
│   ├── api/
│   │   ├── encontros.post.ts             # cria sábado (idempotente)
│   │   ├── transferencias.post.ts        # transferência permanente (valida diretor)
│   │   ├── remanejamentos.post.ts        # substituição temporária
│   │   └── premios/[id]/entregar.post.ts # baixa de pendência + estoque
│   └── utils/supabaseAdmin.ts    # client com service_role (server-only)
│
└── tests/
    ├── unit/                     # vitest — utils/pontos, composables
    └── e2e/                      # playwright — fluxos por perfil
```

## Decisões-chave

1. **RLS-first**: o frontend usa apenas a chave `anon`; toda autorização é feita no Postgres (docs/02). Rotas server (`server/api`) existem só para operações transacionais ou que exigem `service_role`.
2. **RBAC de rota** em duas camadas: `middleware/auth.global.ts` (sessão) + `middleware/role.ts` (perfil por página). A RLS continua sendo a barreira real.
3. **Realtime** apenas em `premios_pendentes` e `presencas` (painel da Secretaria e acompanhamento do sábado).
4. **`supabase/migrations`** é a fonte de verdade do schema; docs/*.sql são a documentação viva.
```
```
