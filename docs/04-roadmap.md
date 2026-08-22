# Oanse — Roteiro de Implementação

> Cada fase termina com um deploy verificável (preview na Vercel + projeto Supabase de staging) e testes de RLS cobrindo os 4 perfis.

## Fase 0 — Fundação (2-3 dias)

1. `npm run nuxi init` + Nuxt UI/Tailwind; `npx supabase init`.
2. Subir ambiente: `npx supabase start` + `npm run dev` (Nuxt no host, ver AGENTS.md).
3. Aplicar migrations (docs/01 e docs/02) + seed; gerar `database.types.ts`.
4. CI: lint, typecheck, `npm run test` (vitest unit), `supabase db reset` + asserts de RLS.

## Fase 1 — Auth e Estrutura (1 semana)

**Meta:** usuários dos 4 perfis logados com escopo correto.

1. Login (magic link/senha) com `@nuxtjs/supabase`; trigger `on_auth_user_created` criando `profiles`.
2. `middleware/auth.global.ts` + `middleware/role.ts`; layout `default` com sidebar por perfil.
3. Admin (Diretor Geral): CRUD de `profiles` (definir role/clube), clubes, itens de pontuação e pontos dos jogos.
4. Cadastro de turmas e líderes (Diretor de Clube) e importação da lista de oansistas (seed/CSV).
5. **Testes de aceitação:** para cada perfil, logar e validar o que enxerga (ex.: líder vê só a própria turma via RLS).

**Entrega:** onboarding de dirigentes pronto; base de crianças cadastrada.

## Fase 2 — Lançamento Semanal (2 semanas)

**Meta:** o líder fecha a Folha Semanal de um sábado; ranking do clube gerado.

1. Tela de encontro corrente (`useEncontro` — busca/cria o sábado).
2. **Chamada**: lista da turma, marca presença/falta; falta zera pontos (trigger já garante — testar).
3. **Folha Semanal**: uniforme, bíblia, EBD, manual, conduta, seções do dia, extras; preview de total com `utils/pontos`.
4. **Remanejamento temporário** (Diretor de Clube): liberar turma a substituto no encontro; substituto passa a ver/editar a turma (`fn_responsavel_pela_turma`).
5. **Transferência permanente** (Diretor de Clube) via `server/api/transferencias.post.ts` (transação: atualiza `oansistas.turma_id` + grava histórico).
6. **Folha Individual**: progresso de seções/níveis (dispara pendências — validar na Fase 3).
7. **Folha de Visitantes**: cadastro, 3 visitas, lições da Prova de Ingresso; ação "matricular" converte visitante em oansista.
8. **Ranking** (`v_ranking_semanal` / `fn_ranking_do_encontro`) com pódio por clube.
9. E2E: fluxo completo de um sábado simulado.

**Entrega:** sistema já opera um sábado real com apoio paralelo ao papel.

## Fase 3 — Painel da Secretaria (1 semana)

**Meta:** premiação end-to-end em tempo real.

1. Catálogo de prêmios (`premios`) + movimentações de estoque com alerta de estoque mínimo.
2. **Painel de pendências** com `supabase.channel('premios_pendentes')` (postgres_changes) — filtrável por clube/status, badge sonoro/visual.
3. Fluxo de entrega: `server/api/premios/[id]/entregar.post.ts` — transação marca `entregue`, dá baixa no estoque e registra movimentação.
4. Relatório de premiações por período (Diretor Geral).

**Entrega:** Secretária deixa de receber pedidos por papel/WhatsApp.

## Fase 4 — Módulo de Jogos e Ranking Geral (1-2 semanas)

**Meta:** pontos dos jogos alimentando o ranking do sábado automaticamente.

1. Diretor de Clube cria jogos por encontro com categoria `faiscas` ou `flamas_tochas`.
2. Montagem de times (2-4) e integrantes (busca de oansistas do clube/clubes).
3. Lançamento do placar: colocação 1-4 ou desclassificado; pontos vêm de `jogos_pontos_config` (100/70/50/40/0).
4. Trigger `fn_propagar_pontos_jogos` recalcula `pontos_jogos` das folhas → ranking atualiza.
5. Ranking consolidado do sábado (por clube e geral) + relatórios de frequência/premiação acumulada.
6. Polimento: PWA/instalação no celular do líder, modo offline da chamada (fila de sincronização) se houver tempo.

**Entrega:** MVP completo. Produção: Vercel (frontend, variáveis `NUXT_PUBLIC_SUPABASE_*`) + Supabase Cloud (mesmas migrations; revisar chaves e ativar MFA no painel).

## Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Líder sem internet no sábado | Chamada otimista com fila local (Fase 4.6) |
| Erro de lançamento após o fechamento | Edição permitida até domingo 23h59 (policy de tempo) |
| Premiação duplicada | `unique(oansista_id, premio_id)` + baixa transacional |
| Complexidade de RLS | Suites de teste automatizadas por perfil desde a Fase 1 + asserts de RLS no CI (Fase 0) + vitest unit/composables/componentes |
