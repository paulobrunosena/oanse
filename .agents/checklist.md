# Checklist de Implementação — Sistema Oanse

> Marque `[x]` ao concluir cada item. Fonte: docs/04-roadmap.md

## Fase 0 — Fundação

- [ ] Inicializar projeto Nuxt 3 + Nuxt UI/Tailwind (`npx nuxi init`)
- [ ] `npx supabase init` (config.toml local)
- [ ] Subir ambiente: `npx supabase start` + `docker compose up nuxt`
- [ ] Converter docs/01-schema.sql em `supabase/migrations/0001_schema.sql`
- [ ] Converter docs/02-rls-policies.sql em `supabase/migrations/0002_rls.sql`
- [ ] Criar `supabase/seed.sql` (clubes, itens de pontuação, config de jogos)
- [ ] `npx supabase db reset` passando sem erros
- [ ] Gerar `app/types/database.types.ts` (`npx supabase gen types`)
- [ ] CI: lint + typecheck + reset do banco com asserts de RLS

## Fase 1 — Auth e Estrutura

- [ ] Login com `@nuxtjs/supabase` (magic link ou senha)
- [ ] Trigger `on_auth_user_created` criando `profiles` no signup
- [ ] `app/composables/useAuth.ts` (user + profile + logout)
- [ ] `app/composables/useRole.ts` (isDiretorGeral, isSecretaria, etc.)
- [ ] `middleware/auth.global.ts` (exige sessão exceto /login)
- [ ] `middleware/role.ts` (RBAC de rota por perfil)
- [ ] Layout default com sidebar por perfil
- [ ] Admin > Usuários: CRUD de profiles (role, clube, ativo) — Diretor Geral
- [ ] Admin > Clubes: edição dos 4 clubes — Diretor Geral
- [ ] Admin > Configurações: itens de pontuação e pontos dos jogos — Diretor Geral
- [ ] Clube > Turmas: cadastro de turmas e vínculo de líderes — Diretor de Clube
- [ ] Cadastro/importação de oansistas (CSV ou seed)
- [ ] Teste de aceitação: líder vê APENAS a própria turma (RLS)

## Fase 2 — Lançamento Semanal

- [ ] `useEncontro` — busca/cria o encontro do sábado corrente
- [ ] Tela de chamada da turma (presença/falta)
- [ ] Teste: falta zera pontuação do dia (trigger `fn_calcular_total_folha`)
- [ ] Folha Semanal: uniforme, bíblia, EBD, manual, conduta, seções, extras
- [ ] Preview do total no formulário (`utils/pontos.ts`)
- [ ] Clube > Remanejamentos: substituição temporária por encontro — Diretor de Clube
- [ ] Teste: substituto enxerga/edita a turma remanejada (RLS)
- [ ] Clube > Transferências: transferência permanente — Diretor de Clube
- [ ] `server/api/transferencias.post.ts` (transação: update + histórico)
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
