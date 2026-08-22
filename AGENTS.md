# AGENTS.md — Instruções para Agentes de IA

Guia de contexto e convenções para qualquer agente (opencode, Cursor, etc.) trabalhando neste repositório.

## O que é este projeto

Sistema web do ministério infantil Oanse (igreja local). Nuxt 4 + Tailwind + Nuxt UI no frontend; Supabase (Postgres, Auth, RLS, Realtime) no backend. Ambientes: Docker/Supabase CLI (dev) e Vercel/Supabase Cloud (produção).

**Leia antes de começar:** `docs/03-estrutura.md` (estrutura de pastas), `docs/04-roadmap.md` (roteiro em fases) e `.agents/checklist.md` (progresso — marque `[x]` nos itens concluídos; consulte-o antes de assumir o que já existe ou falta).

## Comandos

```bash
npx supabase start             # sobe o stack local do Supabase (Docker)
npm run dev                    # dev server no HOST (localhost:3000)
npm run lint                   # ESLint (rodar antes de todo commit)
npm run typecheck              # nuxt typecheck (rodar antes de todo commit)
npx supabase db reset          # recria banco local (migrations + seed)
npx supabase gen types typescript --local > app/types/database.types.ts  # após mudança de schema
```

> **Dev env (importante):** o Nuxt roda no WSL2/host com `npm run dev`, NÃO em container.
> O Docker fica reservado ao stack do Supabase (`npx supabase start`). Rodar o Nuxt em
> container força o browser a alcançar o Supabase via `host.docker.internal`, que só
> resolve dentro do Docker e depende de entradas obsoletas no `/etc/hosts` — causa
> `ERR_CONNECTION_TIMED_OUT` no login. As credenciais locais (`127.0.0.1`) vivem no
> `.env` e funcionam para browser e server-side (localhost forwarding do WSL2).

Sem testes automatizados ainda; quando existirem, atualize esta seção com o comando de teste.

## Arquitetura e regras invioláveis

1. **RLS-first.** O frontend usa SOMENTE a chave `anon`. Toda autorização vive nas políticas RLS (`supabase/migrations/0002_rls.sql`). Nunca confie apenas em `middleware/role.ts` — ele é UX, não segurança.
2. **`service_role` apenas no servidor.** A chave `SUPABASE_SERVICE_ROLE_KEY` só pode ser usada em `server/utils/supabaseAdmin.ts` e rotas `server/api/**`. Nunca importe nada que a exponha em `app/`.
3. **Schema por migrations.** Fonte de verdade: `supabase/migrations/*.sql`. Os arquivos em `docs/` são a documentação viva — ao alterar o schema, atualize a migration E o doc correspondente, depois rode `npx supabase db reset` e gere os types novamente.
4. **Lógica de negócio no banco quando for pontuação/auditoria.** Cálculos de total da folha, pontos de jogos, zeramento por falta e geração de pendências são feitos por triggers (`docs/01-schema.sql`). Não duplique essas regras no cliente além de um preview de leitura (`app/utils/pontos.ts`).
5. **Realtime é intencional.** Apenas `premios_pendentes` e `presencas` estão no publication. Não adicione tabelas ao Realtime sem justificativa.
6. **Perfis RBAC:** `diretor_geral`, `secretaria`, `diretor_clube`, `lider` (enum `user_role` em `profiles`). Escopo de clube vem de `profiles.clube_id`; escopo de turma do líder vem de `turmas.lider_id` + `remanejamentos_temporarios`.

## Convenções de código

- TypeScript estrito; use os tipos gerados em `app/types/database.types.ts` para queries Supabase.
- Componentes: `app/components/` agrupados por domínio (`folha/`, `jogos/`, `premiacoes/`, `ranking/`).
- Estado/lógica de dados: composables em `app/composables/` (`useX.ts`), um por domínio.
- Commits em português, conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`.
- Nunca comitar segredos: `.env` está no `.gitignore` e deve continuar. Chaves locais do Supabase demo não vão para produção.
- Não criar arquivos de documentação além dos existentes em `docs/` sem pedido explícito.

## Checklist de fim de tarefa

1. `npm run lint` passando (e typecheck, quando configurado).
2. `npx supabase db reset` sem erros se houve mudança de SQL.
3. Types regenerados se o schema mudou.
4. Item correspondente marcado em `.agents/checklist.md`.
5. Commit com mensagem conventional, em português.

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
