# Checklist de Implementação — Sistema Oanse

> Marque `[x]` ao concluir cada item. Fonte: docs/04-roadmap.md

## Fase 0 — Fundação

- [x] Inicializar projeto Nuxt 3 + Nuxt UI/Tailwind (`npx nuxi init`)
- [x] `npx supabase init` (config.toml local)
- [x] Subir ambiente: `npx supabase start` + `docker compose up nuxt`
- [x] Converter docs/01-schema.sql em `supabase/migrations/0001_schema.sql`
- [x] Converter docs/02-rls-policies.sql em `supabase/migrations/0002_rls.sql`
- [x] Criar `supabase/seed.sql` (clubes, itens de pontuação, config de jogos)
- [x] `npx supabase db reset` passando sem erros
- [x] Gerar `app/types/database.types.ts` (`npx supabase gen types`)
- [x] CI: lint + typecheck + reset do banco com asserts de RLS

> Nota: usado Nuxt 4.5 + Nuxt UI 4 (template `ui` do nuxi inacessível pela rede local;
> scaffold criado manualmente). Chaves locais no novo formato `sb_publishable_`/`sb_secret_`.

> **RESOLVIDO (revalidado em casa, rede limpa):** `docker compose up nuxt` sobe sem o
> `strict-ssl=false` — config removida do docker-compose.yml. `supabase_vector_oanse`
> ficou Up (healthy) via bind mount de `/var/run/docker.sock` (integração WSL do Docker
> Desktop), sem precisar da porta 2375. Válido para o ambiente WSL2 + Docker Desktop.

## Fase 1 — Auth e Estrutura

- [x] Login com `@nuxtjs/supabase` (e-mail/senha; usuários criados pelo Diretor Geral)
- [x] Trigger `on_auth_user_created` criando `profiles` no signup (já constava da 0001)
- [x] `app/composables/useAuth.ts` (user + profile + logout)
- [x] `app/composables/useRole.ts` (isDiretorGeral, isSecretaria, etc.)
- [x] `middleware/auth.global.ts` (exige sessão exceto /login)
- [x] `middleware/role.ts` (RBAC de rota por perfil via `definePageMeta({ roles })`)
- [x] Layout default com sidebar por perfil
- [x] Admin > Usuários: CRUD de profiles (role, clube, ativo) — Diretor Geral
- [x] Admin > Clubes: edição dos 4 clubes — Diretor Geral
- [x] Admin > Configurações: itens de pontuação e pontos dos jogos — Diretor Geral
- [x] Clube > Turmas: cadastro de turmas e vínculo de líderes — Diretor de Clube
- [x] Cadastro/importação de oansistas (formulário + CSV colado)
- [x] Teste de aceitação: líder vê APENAS a própria turma (RLS)

> Notas da Fase 1: usuários de teste no seed (senha `oanse123`):
> diretor@ / secretaria@ / diretor.ursinhos@ / tia.ana@oanse.local.
> Migration `0003_grants.sql`: policies RLS sozinhas não bastam — os grants de
> privilégio para `authenticated`/`service_role` são obrigatórios (descoberto
> no teste de aceitação). Rotas server em `server/api/usuarios/**` usam
> service_role somente para criar/excluir auth users.

## Fase 2 — Lançamento Semanal

- [x] `useEncontro` — busca/cria o encontro do sábado corrente
- [x] Tela de chamada da turma (presença/falta)
- [x] Teste: falta zera pontuação do dia (trigger `fn_calcular_total_folha`)
- [x] Folha Semanal: uniforme, bíblia, EBD, manual, conduta, seções, extras
- [x] Preview do total no formulário (`utils/pontos.ts`)
- [x] Clube > Remanejamentos: substituição temporária por encontro — Diretor de Clube
- [x] Teste: substituto enxerga/edita a turma remanejada (RLS)
- [x] Clube > Transferências: transferência permanente — Diretor de Clube
- [x] `server/api/transferencias.post.ts` (transação: update + histórico)
- [ ] Folha Individual: progresso de seções/níveis do manual
- [ ] Teste: conclusão de seção gera pendência em `premios_pendentes`
- [ ] Folha de Visitantes: cadastro + 3 visitas
- [ ] Folha de Visitantes: lições da Prova de Ingresso
- [ ] Ação "matricular": converte visitante em oansista
- [ ] Ranking do sábado por clube (`v_ranking_semanal` / pódio)
- [ ] E2E: fluxo completo de um sábado simulado

## Fase 3 — Painel da Secretaria

- [ ] Catálogo de prêmios (CRUD `premios`)
- [ ] Movimentações de estoque (entrada/saída)
- [ ] Alerta de estoque mínimo
- [ ] Painel de pendências com Realtime (`premios_pendentes`)
- [ ] Filtros por clube/status + notificação visual/sonora
- [ ] `server/api/premios/[id]/entregar.post.ts` (entrega + baixa estoque, transacional)
- [ ] Teste: entrega não duplica e dá baixa no estoque
- [ ] Relatório de premiações por período — Diretor Geral

## Fase 4 — Módulo de Jogos e Ranking Geral

- [ ] Criação de jogos por encontro (categoria faisca / flamas_tochas)
- [ ] Validação: 2 a 4 times por jogo
- [ ] Montagem de times + integrantes (busca de oansistas)
- [ ] Lançamento do placar (colocação 1-4 ou desclassificado)
- [ ] Teste: pontos 100/70/50/40/0 conforme `jogos_pontos_config`
- [ ] Teste: trigger `fn_propagar_pontos_jogos` atualiza folhas e ranking
- [ ] Ranking consolidado do sábado (por clube e geral)
- [ ] Relatório de frequência acumulada
- [ ] Relatório de premiações acumuladas
- [ ] PWA / instalação no celular do líder
- [ ] Chamada offline com fila de sincronização (opcional)
- [ ] Deploy produção: Vercel + Supabase Cloud (revisar chaves, MFA no painel)
