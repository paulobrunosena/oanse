# Oanse — Plano de Migração: Nuxt 4 + Nuxt UI → Vue 3 + Vite + PrimeVue

> **Decisão (2026-08-24):** migrar o frontend de Nuxt 4 + Nuxt UI/Tailwind para
> **Vue 3 + Vite + Vue Router + Pinia + PrimeVue**, mantendo todo o backend
> Supabase (schema, RLS, triggers, RPCs) **intacto**. Motivação: a pessoa que
> mantém o projeto trabalha diariamente com Vue + PrimeVue — maior produtividade
> e manutenibilidade a longo prazo.
>
> **Impacto do banco:** NENHUM. `supabase/migrations/`, RLS e triggers são 100%
> reaproveitados. `docs/01` e `docs/02` não mudam (apenas referências genéricas
> a `server/api/*` que viram `api/*`).

---

## 1. O que é portável e o que é reescrito

### Reaproveitado sem alteração
- Todo o schema/migrations (`supabase/migrations/0001..0007`) + `seed.sql`
- RLS e triggers (`docs/01`, `docs/02`)
- Tipos gerados `app/types/database.types.ts` → movem para `src/types/`
- Lógica pura: `app/utils/pontos.ts`, `app/utils/data.ts`, `server/utils/sabado.ts`

### Reescrito (camada de frontend)
- Estado global: `useState()` (Nuxt) → **Pinia stores**
- Cliente Supabase: `useSupabaseUser/Client` (`@nuxtjs/supabase`) → **`@supabase/supabase-js` + `@supabase/ssr`** (sessão manual)
- Navegação: `navigateTo/useRoute/useRouter/definePageMeta/middleware` → **Vue Router + guards**
- Requisições: `$fetch`/`useFetch` → **`fetch` nativo (wrapper `src/lib/api.ts`)**
- Backend das 3 rotas Nitro (`server/api/**`) → **funções serverless** (Vercel Functions) ou Express
- UI: Nuxt UI + Tailwind → **PrimeVue 4 (preset Aura) + PrimeIcons**
- Testes: `mockNuxtImport`/`mountSuspended` (env nuxt) → **`@vue/test-utils` puro + `vi.mock`**

---

## 2. Stack alvo

```
vue ^3.5        vite ^8        vue-router ^4        pinia ^4
primevue ^5     primeicons 8   @supabase/supabase-js  @supabase/ssr
vitest ^4 + @vue/test-utils + happy-dom
eslint 10 (flat config) + vue-tsc 3 (typecheck)
```

> **Atualização de majors (2026-08-24):** após a migração, o stack foi levado
> para as versões mais recentes: **Vite 8** (Rolldown), **vitest 4**,
> **@vitejs/plugin-vue 6**, **Pinia 4** (ESM + `@vue/devtools-api`), **ESLint 10**
> (com plugin-vue 10, vue-eslint-parser 10 e vue-tsc 3) e **PrimeVue 5**.
> O tema mudou de `@primevue/themes` para **`@primeuix/themes`**; como o layout
> Sakai usa raiz de fonte **14px**, o preset usado é **`aura-compat`**
> (variante calibrada para 14px; o padrão do v5 assume 16px). O projeto não usa
> nenhum componente removido no v5 e mantém os ícones de fonte `pi pi-*`
> (`primeicons` 8). No v5 a licença PrimeUI (community/comercial) deve ser
> configurada em `app.use(PrimeVue, { license: { key } })` — sem a chave,
> apenas um aviso no console é exibido.

> Deploy: **SPA estático** (perde-se SSR — aceitável para sistema interno de
> administração). Backend das rotas admin via **Vercel Functions** (`api/**`).
> O Nuxt hoje já é quase tudo client-side; a perda de SSR não afeta a UX.

---

## 3. Mapa de componentes Nuxt UI → PrimeVue

| Nuxt UI (atual) | PrimeVue (alvo) | Onde |
|---|---|---|
| `UButton` | `Button` | todas as telas |
| `UInput` | `InputText` | formulários |
| `USelect` | `Select` | usuários, turmas, clube |
| `USwitch` | `InputSwitch` | chamada, edição de usuário |
| `UModal` | `Dialog` | usuários, transferências |
| `UTable` | `DataTable` | usuários, oansistas, histórico |
| `UBadge` | `Tag` | perfil, situação, presença |
| `UCard` | `Card` | chamada, folha |
| `UForm`/`UFormField` | `Form`+`Message` (ou manual) | formulários |
| `UAvatar` | `Avatar` | sidebar, chamada |
| `UIcon` (`i-lucide-*`) | `PrimeIcons` (`pi pi-*`) | ícones |
| `UNavigationMenu` | `Menu` (ou sidebar custom) | sidebar |
| `UDashboardSidebar/Group/Panel` | layout custom (Drawer/Menubar) | `AppLayout` |
| `useToast()` | `useToast()` (service PrimeVue) | toasts |

---

## 4. Estrutura alvo (dentro do mesmo repositório)

```
oanse/
├── index.html
├── vite.config.ts
├── vitest.config.ts          # ambiente node + happy-dom (sem nuxt)
├── tsconfig.json             # references app + node (não estende .nuxt)
├── eslint.config.mjs
├── .env                      # VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY / VITE_SUPABASE_SERVICE_ROLE_KEY
├── .env.example
│
├── supabase/                 # INALTERADO (migrations, seed, config)
├── public/logos/             # inalterado
│
├── src/
│   ├── main.ts               # cria app + pinia + router + PrimeVue
│   ├── App.vue
│   ├── lib/
│   │   ├── supabase.ts       # client anon (browser)
│   │   └── api.ts            # wrapper fetch para as rotas /api
│   ├── stores/               # (antigos composables)
│   │   ├── auth.ts           # user + profile + logout + loadProfile
│   │   ├── role.ts           # isDiretorGeral, isSecretaria, ...
│   │   ├── encontro.ts       # sábado corrente + histórico + RN 7
│   │   ├── folhaSemanal.ts
│   │   ├── remanejamentos.ts
│   │   └── transferencias.ts
│   ├── router/
│   │   ├── index.ts          # createRouter + rotas
│   │   └── guards.ts         # auth.global + role (RBAC por meta)
│   ├── layouts/
│   │   ├── BlankLayout.vue   # login
│   │   └── AppLayout.vue     # sidebar + navbar (perfil)
│   ├── views/                # (antigas pages/)
│   │   ├── LoginView.vue
│   │   ├── DashboardView.vue
│   │   ├── ChamadaView.vue
│   │   ├── FolhaSemanalView.vue
│   │   ├── clube/ (Turmas, Lideres, Oansistas, Remanejamentos, Transferencias)
│   │   └── admin/ (Usuarios, Clubes, Calendario, Configuracoes)
│   ├── components/
│   │   ├── encontro/EncontroSeletor.vue
│   │   └── folha/FolhaSemanalRow.vue
│   ├── types/database.types.ts   # movido (inalterado)
│   └── utils/                    # pontos.ts, data.ts (inalterados)
│
├── api/                      # Vercel Functions (ex-rotas Nitro)
│   ├── encontros/atual.ts
│   ├── transferencias.ts
│   └── usuarios/index.ts, usuarios/[id].ts
│
└── tests/helpers/supabase.ts # mock de cadeia (ajustar para vi.mock)
```

---

## 5. Fases de migração

### Fase A — Scaffold do projeto Vue (0.5–1 dia)
1. Instalar dependências: `vue`, `vite`, `@vitejs/plugin-vue`, `vue-router`, `pinia`, `primevue`, `primeicons`, `@supabase/supabase-js`, `@supabase/ssr`.
2. `index.html`, `vite.config.ts`, `tsconfig`, `eslint.config.mjs`, `vitest.config.ts` (ambiente `node` + `happy-dom`, sem nuxt).
3. `src/main.ts`: cria app, registra Pinia, Vue Router e **PrimeVue** com preset Aura.
4. Configurar `.env` (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_SUPABASE_SERVICE_ROLE_KEY`).
5. **Aceite:** `npm run dev` sobe SPA em branco com tema PrimeVue.

### Fase B — Cliente Supabase + stores de dados (1–1.5 dia)
1. `src/lib/supabase.ts`: client anon + `onAuthStateChange` mantendo sessão (usar `@supabase/ssr` ou storage localStorage).
2. Portar os 6 composables → **Pinia stores**, trocando:
   - `useState('chave', ...)` → `ref` na store (Pinia já é global).
   - `useSupabaseClient()` → client importado de `src/lib/supabase.ts`.
   - `$fetch('/api/...')` / `useFetch` → `fetch('/api/...')` via `src/lib/api.ts`.
3. `auth` store: manter user + profile + `loadProfile()` + `logout()`.
4. **Aceite:** stores funcionam; login/logout com sessão persistida.

### Fase C — Router, guards e layouts (0.5–1 dia)
1. `src/router/`: definir todas as rotas com `meta.roles` (replicar `definePageMeta`).
2. `guards.ts`:
   - `beforeEach` global = exige sessão exceto `/login` (equivalente `auth.global.ts`).
   - guard de role por `meta.roles` (equivalente `role.ts`, UX apenas — RLS é a barreira).
3. `AppLayout.vue` + `BlankLayout.vue`: reproduzir sidebar por perfil e navbar com PrimeVue.
4. **Aceite:** navegação com RBAC funcionando; menu por perfil correto.

### Fase D — Backend (rotas admin) (0.5–1 dia)
> As 3 rotas usam `service_role` → **nunca** no client. Hoje vivem no Nitro
> (`server/api/**`); movem para fora do bundle do SPA.
1. Opção recomendada: **Vercel Functions** (`api/**`) usando `@supabase/supabase-js` com service_role e leitura do usuário via **token JWT** do header `Authorization` (em vez de `serverSupabaseUser`).
2. Endpoints a portar:
   - `GET /api/encontros/atual` → `api/encontros/atual.ts`
   - `POST /api/transferencias` → `api/transferencias.ts`
   - `GET/POST/DELETE /api/usuarios(/:id)` → `api/usuarios/**`
3. Autenticar cada rota verificando o JWT (ler claims do `sub`) — manter o mesmo contrato atual.
4. **Aceite:** as telas de usuários/transferências/encontro funcionam contra o novo backend local (dev via `vite` proxy para as functions ou servidor Express).

### Fase E — UI: portar as 13 páginas (2–2.5 dias)
1. Seguir o mapa da seção 3 (Nuxt UI → PrimeVue).
2. Ordem sugerida por dependência: Login → Layout → Dashboard → Chamada → Folha Semanal → Clube (Turmas/Líderes/Oansistas/Remanejamentos/Transferências) → Admin (Usuários/Clubes/Calendário/Configurações).
3. Manter os IDs/classes dos testes e a lógica de dados nas stores (não duplicar regra de negócio no template).
4. **Aceite:** todas as telas com comportamento equivalente ao Nuxt.

### Fase F — Testes (1 dia)
1. Trocar `vitest.config.ts` (remover env `nuxt`).
2. Specs de **lógica pura** (`pontos.spec`, `data.spec`, `sabado.spec`) — inalteradas.
3. Specs de **stores** (ex-composables): remover `mockNuxtImport`, usar `vi.mock('@supabase/supabase-js')` + helper `tests/helpers/supabase.ts`; testar a store via `createPinia + setActivePinia`.
4. Specs de **componentes**: trocar `mountSuspended` por `mount` (`@vue/test-utils`) com stubs de PrimeVue.
5. **Aceite:** `npm run test` verde com a mesma cobertura (~69 casos).

### Fase G — CI + Deploy (0.5 dia)
1. `.github/workflows/ci.yml`: ajustar jobs — `npm run lint`, `npm run typecheck` (vue-tsc), `npm run test`, e o job `database` **inalterado**.
2. Vercel: configurar build de SPA (`vite build`) + Functions `api/**`; variáveis `VITE_*` no painel.
3. **Aceite:** preview Vercel com login e RLS funcionando; CI verde.

---

## 6. Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Sessão Supabase precisa ser reconstruída no SPA | Usar `@supabase/ssr` (padrão oficial) + `onAuthStateChange`; testar refresh de token |
| Guard de role depende do profile carregado | Chamar `loadProfile()` antes do `next()` nos guards (mesmo fluxo do middleware atual) |
| Regressão de comportamento nas telas | Portar por página com verificação manual + specs existentes adaptados |
| Backend admin exposto | Funções `api/**` validam JWT; service_role só no servidor (mantém regra RLS-first) |
| Perda de SSR | Aceitável para sistema interno; SPA puro |

---

## 7. Esforço estimado

- **Total: ~6–8 dias de trabalho dedicado** (Fases A–G).
- Reaproveitamento real: backend + dados ≈ 60% do esforço total já existente fica intacto; a maior fatia é a UI (Fase E).

---

## 8. Estado de conclusão

> **Migração concluída em 2026-08-24.** Frontend rodando em Vue 3 + Vite + Pinia +
> PrimeVue; backend admin movido para h3 (`server/**` + function `api/index.ts`).
> Lint, typecheck, 70 testes e build passando.

- [x] Fase A — Scaffold Vue + Vite + PrimeVue
- [x] Fase B — Cliente Supabase + stores Pinia
- [x] Fase C — Router + guards + layouts
- [x] Fase D — Backend admin (h3 + Vercel Functions)
- [x] Fase E — Portar 13 páginas para PrimeVue
- [x] Fase F — Portar testes (vitest puro)
- [x] Fase G — CI + Deploy
