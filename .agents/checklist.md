# Checklist de Implementação — Sistema Oanse

> Marque `[x]` ao concluir cada item. Fonte: docs/04-roadmap.md

## Fase 0 — Fundação

- [x] Inicializar projeto Nuxt 3 + Nuxt UI/Tailwind (`npx nuxi init`)
- [x] `npx supabase init` (config.toml local)
- [x] Subir ambiente: `npx supabase start` + `npm run dev` (Nuxt no host)
- [x] Converter docs/01-schema.sql em `supabase/migrations/0001_schema.sql`
- [x] Converter docs/02-rls-policies.sql em `supabase/migrations/0002_rls.sql`
- [x] Criar `supabase/seed.sql` (clubes, itens de pontuação, config de jogos)
- [x] `npx supabase db reset` passando sem erros
- [x] Gerar `app/types/database.types.ts` (`npx supabase gen types`)
- [x] CI: lint + typecheck + reset do banco com asserts de RLS
- [x] Vitest + @vue/test-utils + happy-dom configurados (`vitest.config.ts`); testes unit de utils, composables e componentes (69 testes cobrindo o que foi implementado)

> Nota: usado Nuxt 4.5 + Nuxt UI 4 (template `ui` do nuxi inacessível pela rede local;
> scaffold criado manualmente). Chaves locais no novo formato `sb_publishable_`/`sb_secret_`.

> **SUPERADO (2026-08-22):** Nuxt roda no WSL2/host (`npm run dev`); o `docker-compose.yml`
> foi removido. Rodar Nuxt em container quebrava o login no browser:
> `host.docker.internal` só resolve dentro do Docker e a entrada antiga no `/etc/hosts`
> apontava para IP inalcançável → `ERR_CONNECTION_TIMED_OUT`. Com o dev no host, as
> credenciais `127.0.0.1` do `.env` funcionam tanto no browser quanto no server-side.

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
- [x] Identidade visual: logos (public/logos/) aplicados no layout/sidebar/login/telas; cores padrão dos clubes (ursinho vermelho, faísca amarelo, flama verde, tocha azul)
- [x] Admin > Configurações: itens de pontuação e pontos dos jogos — Diretor Geral
- [x] Clube > Turmas: cadastro de turmas e vínculo de líderes — Diretor de Clube
- [x] Clube > Líderes: catálogo de leitura da equipe do clube — Diretor de Clube
- [x] Cadastro/importação de oansistas (formulário + CSV colado)
- [x] Teste de aceitação: líder vê APENAS a própria turma (RLS)

> Notas da Fase 1: usuários de teste no seed (senha `oanse123`):
> diretor@ / secretaria@ / diretor.{ursinhos,faiscas,flamas,tochas}@ /
> tia.ana@ / tia.bea@ / tio.carlos@ / tia.duda@ / lider.jogos@oanse.local.
> Migration `0003_grants.sql`: policies RLS sozinhas não bastam — os grants de
> privilégio para `authenticated`/`service_role` são obrigatórios (descoberto
> no teste de aceitação). Rotas server em `server/api/usuarios/**` usam
> service_role somente para criar/excluir auth users.

## Fase 2 — Lançamento Semanal

- [x] `useEncontro` — busca/cria o encontro do sábado corrente + histórico navegável
- [x] Tela de chamada da turma (presença/falta) — com seletor de sábado (chamadas atrasadas)
- [x] Backfill de "sábado perdido" — o líder cria o encontro de um sábado passado nunca registrado (ex.: sistema fora do ar) via `POST /api/encontros/retro` (`EncontroRetroativo.vue` + store `encontro.ts`); valida sábado/não-futuro/fora de `dias_sem_oanse`
- [x] Admin > Calendário: sábados sem Oanse (RN 7) — bloqueia chamada/folha em férias/feriados
- [x] Teste: falta zera pontuação do dia (trigger `fn_calcular_total_folha`)
- [x] Folha Semanal: uniforme, bíblia, EBD, manual, conduta, leitura bíblica, visitantes convidados, seções do manual (sem ajuda vale mais / com ajuda), atividade extra e cor do time nos jogos
- [x] Preview do total no formulário (`utils/pontos.ts`)
  - (2026-08-24) Itens ampliados na migration `0008_folha_novos_itens.sql`: `secoes_dia` vira `secoes_sem_ajuda` + `secoes_com_ajuda`; novas chaves `leitura_biblica`/`visitante`; `cor_time` é armazenado mas **não pontua** (fica para o módulo de jogos — Fase 4).
- [x] Clube > Remanejamentos: substituição temporária por encontro — Diretor de Clube
- [x] Teste: substituto enxerga/edita a turma remanejada (RLS)
- [x] Clube > Transferências: transferência permanente — Diretor de Clube
- [x] `server/api/transferencias.post.ts` (transação: update + histórico)
- [x] Folha Individual do Faíscas: manuais/seções/blocos com itens numerados (data de conclusão), prêmio recebido e observações por manual — Diretor de Clube; rota `/clube/folha-individual` (`docs/06-folha-individual.md`)
- [x] Folha Individual disponível também para o Líder (escopo por turma: só os oansistas da turma do líder); diretores seguem vendo o clube inteiro
- [x] Folha Individual: seções em Accordion (`multiple`, 1ª aberta) com contagem de itens concluídos no cabeçalho (`secaoItensConcluidos`/`secaoTotalItens`)
- [x] Folha Individual do Flamas e Tochas: catálogos Sabiá/Águia e Carneiro/Leão (24 blocos cada) via seed; seção Frequência consolidada (1 seção, blocos Igreja/Clube) no Faíscas/Flamas/Tochas; `rotuloItem` reconhece "Prova do Grau" (`docs/07-folha-individual-flama-tocha.md`)
- [x] Teste: conclusão do bloco libera o prêmio (`blocoConcluido`/`premioHabilitado` + specs de utils/componentes) — decisão do `docs/06` substituiu a geração de pendência em `premios_pendentes` (premiação registra apenas "prêmio recebido + data")
- [x] Folha de Visitantes: cadastro + 3 visitas
- [x] Folha de Visitantes: lições da Prova de Ingresso
- [x] Ação "matricular": converte visitante em oansista (RPC `fn_matricular_visitante`, migration 0017; autorização diretor_geral/diretor_clube validada dentro da função — smoke test local: diretor matricula OK, líder bloqueado)
- [x] Ranking do sábado por clube (pódio via `fn_ranking_do_encontro` + `RankingView`)
- [ ] E2E: fluxo completo de um sábado simulado

## Fase 3 — Painel da Secretaria

> **Decisão de fluxo (2026-09-15):** a folha individual (docs/06) removeu o
> gatilho que gerava `premios_pendentes`. Novo desenho acordado: **pendência
> automática + entrega pela secretaria**. Ao completar todos os itens de um bloco
> da Folha Individual, um trigger gera a pendência (`premios_pendentes`); a
> secretaria entrega pelo painel Realtime (status→`entregue` + baixa no estoque +
> movimentação + data na folha via `server/api/premios/[id]/entregar.post.ts`).
> A folha mostra o prêmio como só-leitura ("Aguardando entrega" → "Entregue em
> DD/MM"). Requer vínculo `folha_blocos.premio_id → premios.id` (migration nova).

- [x] Catálogo de prêmios (CRUD `premios`) + migration `folha_blocos.premio_id` + seed do catálogo
- [ ] Movimentações de estoque (entrada/saída)
- [ ] Alerta de estoque mínimo
- [x] Trigger `trg_folha_item_pendencia`/`fn_recalcular_pendencia_premio` (conclusão de bloco → pendência; desmarcar item cancela)
- [x] Painel de pendências com Realtime (`premios_pendentes`)
- [ ] Filtros por clube/status + notificação visual/sonora
- [x] `server/api/premios/[id]/entregar.post.ts` + `fn_entregar_premio` (entrega + baixa estoque, transacional)
- [ ] Folha individual: prêmio só-leitura com status (aguardando/entregue)
- [ ] Teste: entrega não duplica e dá baixa no estoque
- [ ] Relatório de premiações por período — Diretor Geral

## Fase 4 — Módulo de Jogos e Ranking Geral

- [x] Novo perfil `lider_jogos` (`user_role`) + usuário de teste no seed/login (`lider.jogos@oanse.local`)
- [x] Eventos de jogos por sábado (VÁRIOS por sábado — ex.: Flamas+Tochas e Ursinhos+Faíscas): cadastro único por evento (clubes participantes + cores pré-definidas verde/vermelho/amarelo/azul + oansistas de cada cor) via RPC `fn_criar_evento_jogos` (migration `0010`/`0011`/`0012`); clubes que já jogaram no sábado não aparecem para novo evento (RPC + trigger `trg_clube_evento_duplicado`)
- [x] Catálogo de jogos por clube (`jogos_catalogo`): CRUD (Ursinhos/Faíscas/Flamas/Tochas); combo do registro de rodada une os jogos dos clubes participantes sem duplicar nomes iguais (`jogosDisponiveis`)
- [x] Registro de rodada: nome do jogo (pré-preenchido com o último lançado) + colocação das cores; `jogo_resultados` por cor
- [x] Finalização do evento + ranking das cores do sábado (`fn_ranking_cores_do_evento`) para o anúncio final
- [x] Teste: pontos 100/70/50/40/0 conforme `jogos_pontos_config` (trigger + espelho `utils/jogos.ts`; smoke test local RLS: evento, rodadas, ranking, propagação)
- [x] Teste: `fn_recalcular_pontos_jogos_encontro` atualiza folhas (pontos_jogos + cor_time + posicao_jogos) — validado via smoke test local
- [x] Folha Semanal com pontuação de jogos automática: cor, pontos e **posição no ranking dos jogos** (`posicao_jogos`) vêm do módulo de jogos e aparecem na folha assim que o líder marca presença — em qualquer ordem de lançamento (folha antes/depois dos jogos; alternância de presença re-deriva). Cor deixou de ser selecionada à mão (bloco somente leitura). Smoke test local cobre as duas ordens + alternância de presença.
- [x] Pontuação dos jogos na folha por **colocação da equipe** (migration `0014_folha_pontos_por_colocacao.sql`): itens configuráveis no módulo de configurações (`jogo_1_lugar`..`jogo_4_lugar`, default 5/4/3/2); `fn_recalcular_pontos_jogos_encontro` atribui `pontos_jogos` pela colocação no ranking (e não mais pela soma das rodadas, que segue alimentando o ranking dos jogos via `jogos_pontos_config`). Preview do total do cartão inclui os pontos dos jogos.
- [x] RLS do módulo: escrita só `lider_jogos`/`diretor_geral` (evento, cores, oansistas, rodadas, resultados); diretor de clube NÃO cria evento (validado no smoke test)
- [x] Ranking consolidado do sábado (por clube e geral)
- [x] UX do módulo: busca de criança no evento lista só os clubes participantes (badge do clube nas opções); criança distribuída mostra o nome na cor do clube (chip com fundo suave + botão de remover, removível antes de finalizar); excluir evento dentro do card (não "flutua" fora); refresh após ações não derruba o scroll da página (mantém conteúdo montado)
- [x] UX: `JogosView` reorganizada em **stepper** (PrimeVue) de 3 etapas — 1) configuração das cores/crianças, 2) registro das rodadas, 3) placar final; seleção de evento e "Novo evento" fora do stepper; ações Finalizar/Reabrir/Excluir centralizadas no último passo; evento finalizado abre direto no placar e a etapa de rodadas orienta a reabrir (2026-09-11)
- [x] UX: ajuste visual do stepper dos jogos (2026-09-11) — painel externo vira o card (`rounded-lg border p-4 sm:p-6`) e os cards internos (`EventoJogosCard`/`RodadasJogosCard`/`RankingCoresCard`) perdem a borda própria (headers/seções com divisores); rodapés de ações com `border-t pt-4` (botões não ficam mais colados); botão "Voltar" com fundo cinza (`severity="secondary"` sem `text`, como no exemplo do PrimeVue)
- [ ] Relatório de frequência acumulada
- [ ] Relatório de premiações acumuladas
- [ ] PWA / instalação no celular do líder
- [ ] Chamada offline com fila de sincronização (opcional)
- [ ] Deploy produção: Vercel + Supabase Cloud (revisar chaves, MFA no painel)

## Fase M — Migração Nuxt → Vue 3 + Vite + PrimeVue

> **Concluída (2026-08-24).** Frontend em Vue 3 + Vite + Pinia + PrimeVue (SPA),
> backend admin em h3 (`server/**` + function `api/index.ts`). Backend Supabase
> **intacto**. Plano: `docs/05-migracao-vue-primevue.md`.

- [x] Fase A — Scaffold Vue + Vite + PrimeVue (router, pinia, tema Aura, env VITE_*)
- [x] Fase B — Cliente Supabase (`@supabase/supabase-js` + `@supabase/ssr`) + stores Pinia (auth, role, encontro, folha, remanejamento, transferência)
- [x] Fase C — Router + guards (auth.global + role RBAC) + layouts (AppLayout/BlankLayout)
- [x] Fase D — Backend admin: mover as 3 rotas Nitro (`server/api/**`) para Vercel Functions (`api/**`) validando JWT
- [x] Fase E — Portar as 13 páginas de Nuxt UI → PrimeVue
- [x] Fase F — Portar testes: remover env `nuxt`, `mockNuxtImport`/`mountSuspended` → `@vue/test-utils` puro + `vi.mock`
- [x] Fase G — CI (`vue-tsc`) + Deploy Vercel (SPA + Functions)
- [x] Limpeza: remover `nuxt.config.ts`, `app/` (Nuxt), `server/` (Nitro) e dependências Nuxt/Nuxt UI após conclusão
- [x] **App shell Sakai (PrimeVue)** — integrado ao layout autenticado: `src/layouts/` (AppLayout/AppSidebar/AppTopbar/AppMenu/AppMenuItem/AppFooter + `composables/layout.ts`), SCSS em `src/assets/layout/`, dark mode (`.app-dark`), menu por perfil (RBAC), Tailwind via `tailwindcss-primeui` + `sass`
- [x] **Ajustes de UI pós-migração (2026-08-24)** — perfil (avatar, nome, cargo, logout) fixo no rodapé da sidebar no mobile (`AppSidebar.vue` + SCSS `layout-sidebar-profile`); fundo `bg-[var(--surface-card)]` nas telas do líder (Chamada, Folha Semanal, Remanejamentos) para o padrão claro/dark; InputNumber com largura maior (`5rem`, `w-36`/`w-40`) para não cortar os números (Folha Semanal e Configurações); limpeza de artefatos Nuxt (`.nuxt/`, container/volume/rede Docker órfãos)
- [x] **Upgrade de majors (2026-08-24)** — Vite 8 (Rolldown), vitest 4, plugin-vue 6, Pinia 4 (ESM + `@vue/devtools-api`), ESLint 10 (plugin-vue 10, parser 10, vue-tsc 3) e PrimeVue 5 (tema via `@primeuix/themes`, preset `aura-compat` p/ raiz 14px, `primeicons` 8). Lint/typecheck/build/72 testes verdes.
- [x] **Auditoria e ajustes de responsividade mobile (2026-08-26)** — auditoria geral das telas (360-768px) e correções: DataTables (Usuários, Clubes, Configurações, Turmas, Líderes, Oansistas) envoltas em `overflow-x-auto`; grids de formulários (clube, oansista) colapsam para `grid-cols-1 sm:grid-cols-2`; cabeçalhos de Chamada/Folha Semanal/Ranking empilham no mobile (`flex-col sm:flex-row`); Turmas/Oansistas/EventoJogosCard/Remanejamentos ganham `flex-wrap`; dialog "Novo evento de jogos" com `w-full max-w-md` (antes 28rem fixo estourava ≤487px); InputNumber de configuração com `max-w-[10rem]`. Specs novos: Clubes, Turmas, Líderes, Oansistas, Ranking. Lint/typecheck/178 testes verdes.
- [x] **Fix: scroll horizontal no dialog de editar clube (2026-09-11)** — `min-w-0` no form/grids/filhos e `:input-style="{ minWidth: '0', width: '100%' }"` nos InputNumbers de idade/ordem (mesmo padrão de Configurações); corrige a sobreposição de Idade mínima/máxima e o campo Ordem de exibição largo demais. Spec cobrindo classes e `input-style` em `ClubesView.spec.ts`. Lint/typecheck/244 testes verdes.
- [x] **Melhoria: seletor de cor no dialog de editar clube (2026-09-11)** — troca do `<InputText type="color">` (linha fina) pelo `InputColor` do PrimeVue (`format="hex"`, substitui o `ColorPicker` deprecado desde a v5): swatch clicável abre `Popover` com área, slider de matiz e input hex; computed `corSelecionada` normaliza `#RRGGBB`; campo "Ordem de exibição" movido para antes de "Cor". Specs cobrindo ordem dos campos, presença/format do InputColor e normalização no save em `ClubesView.spec.ts` (stubs de DataTable/Column propagam a linha). Lint/typecheck/247 testes + build verdes.
- [x] **Refactor: auto-import de componentes PrimeVue (2026-09-11)** — `unplugin-vue-components` + `@primevue/auto-import-resolver` em `vite.config.ts`/`vitest.config.ts`; removidos os `import X from 'primevue/...'` de todos os `.vue` (os componentes passam a ser resolvidos pelo template; tipos globais em `src/components.d.ts`). Serviços/composables (`primevue/config`, `toastservice`, `confirmationservice`, `useToast`, `useConfirm`) seguem com import explícito. Lint/typecheck/247 testes + build verdes.
