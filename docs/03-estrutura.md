# Oanse — Estrutura de Diretórios (Nuxt 4 + Supabase)

> Estado REAL do repositório. Itens marcados como **(planejado)** ainda não
> existem e pertencem a fases futuras (ver docs/04-roadmap.md).

```
oanse/
├── .env.example
├── .env                          # credenciais locais (127.0.0.1) — NUNCA comitar
├── AGENTS.md                     # instruções para agentes de IA
├── README.md
├── eslint.config.mjs
├── nuxt.config.ts
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
├── .github/workflows/ci.yml      # lint + typecheck + reset do banco + asserts RLS
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
│   │   │   └── EncontroSeletor.vue  # seletor de sábado (histórico) — Chamada/Folha
│   │   └── folha/
│   │       └── FolhaSemanalRow.vue  # linha da folha com preview de total
│   │   # (planejado) ui/AppSidebar, PageHeader, DataTable
│   │   # (planejado) folha/FolhaIndividualForm, VisitanteCard, VisitaTracker
│   │   # (planejado) jogos/, premiacoes/, ranking/
│   │
│   ├── composables/
│   │   ├── useAuth.ts            # user + profile + logout
│   │   ├── useRole.ts            # helpers: isDiretorGeral, isSecretaria...
│   │   ├── useEncontro.ts        # sábado corrente + histórico + RN 7 (sem Oanse)
│   │   ├── useFolhaSemanal.ts    # itens de pontuação + folhas + salvar
│   │   ├── useRemanejamentos.ts  # substituição temporária de turma
│   │   └── useTransferencias.ts  # transferência permanente (RPC 0006)
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
│       ├── pontos.ts             # espelhos do cálculo p/ preview no form
│       └── data.ts               # datas dos sábados, formatação, logoClube(slug)
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
│   └── utils/supabaseAdmin.ts    # client com service_role (server-only)
│
└── tests/                        # (planejado) vitest unit + playwright e2e
```

## Decisões-chave

1. **RLS-first**: o frontend usa apenas a chave `anon`; toda autorização é feita no Postgres (docs/02). Rotas server (`server/api`) existem só para operações transacionais ou que exigem `service_role`.
2. **RBAC de rota** em duas camadas: `middleware/auth.global.ts` (sessão) + `middleware/role.ts` (perfil por página). A RLS continua sendo a barreira real.
3. **Realtime** apenas em `premios_pendentes` e `presencas` (painel da Secretaria e acompanhamento do sábado).
4. **`supabase/migrations`** é a fonte de verdade do schema; `docs/*.sql` são a documentação viva (mantê-los sincronizados).
5. **Dev no host/WSL2**: `npx supabase start` (Docker) + `npm run dev` (Nuxt fora de container) — ver AGENTS.md.