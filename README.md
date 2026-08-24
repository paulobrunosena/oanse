# Oanse — Sistema do Ministério Infantil

Sistema web para gestão do ministério infantil Oanse de igreja local: matrícula de crianças por faixa etária (Ursinhos, Faíscas, Flamas, Tochas), folha semanal com pontuação, ranking do sábado, módulo de jogos, controle de premiações/estoque da secretaria e acompanhamento de visitantes.

## Stack

- **Frontend:** Vue 3 + Vite + Vue Router + Pinia + PrimeVue + Tailwind CSS 4 — TypeScript
- **Backend/DB:** Supabase (PostgreSQL, Auth, Row Level Security, Realtime)
- **API (server-side):** h3 (Vercel)
- **Infra:** Docker/Supabase CLI (dev) · Vercel + Supabase Cloud (produção)

## Perfis de acesso (RBAC)

| Perfil | Escopo |
|---|---|
| Diretor Geral | Total: relatórios, clubes, usuários, configurações |
| Secretária | Estoque de materiais e painel de premiações (tempo real) |
| Diretor de Clube | Seu clube: líderes, remanejamentos, transferências, jogos |
| Líder | Folha Semanal, Individual e de Visitantes da sua turma |

## Rodando localmente

Pré-requisitos: Node 22+, Docker (para o Supabase) e [Supabase CLI](https://supabase.com/docs/guides/cli).

```bash
# 1. Dependências
npm install

# 2. Stack do Supabase local (Postgres, Auth, Studio)
npx supabase start     # aplica migrations + seed automaticamente

# 3. Copie as chaves locais para o .env
npx supabase status -o env   # cole os valores no .env (veja .env.example)

# 4. Frontend (no host/WSL2)
npm run dev
```

- App: http://localhost:5173
- API local (h3): http://localhost:8787
- Supabase Studio: http://localhost:54323

## Principais comandos

```bash
npm run dev            # dev server (Vite)
npm run dev:api        # API local (h3, tsx watch)
npm run lint           # ESLint
npx supabase db reset  # recria o banco local (migrations + seed)
npx supabase gen types typescript --local > src/types/database.types.ts
```

## Documentação

- [docs/01-schema.sql](docs/01-schema.sql) — modelo de dados (DDL, triggers, views)
- [docs/02-rls-policies.sql](docs/02-rls-policies.sql) — políticas RLS por perfil
- [docs/03-estrutura.md](docs/03-estrutura.md) — estrutura de diretórios
- [docs/04-roadmap.md](docs/04-roadmap.md) — roteiro de implementação (4 fases)
- [.agents/checklist.md](.agents/checklist.md) — checklist de tracking do progresso

## Regras de negócio essenciais

1. Criança ausente na chamada ⇒ pontuação do dia zerada (automático via trigger).
2. Ranking do sábado calculado a partir da Folha Semanal + pontos dos jogos.
3. Jogos: Faíscas entre si; Flamas e Tochas juntos; 2-4 times; 1º=100, 2º=70, 3º=50, 4º=40, desclassificado=0.
4. Conclusão de seção/nível na Folha Individual gera pendência automática no painel da Secretária (realtime).
5. Visitante: 3 visitas + lições da Prova de Ingresso antes da matrícula oficial.
