# Oanse — Folha de Progresso Individual (Clube Faíscas)

> Plano de implementação da Folha Individual, começando pelo clube **Faíscas**.
> Decisões tomadas em conjunto com o usuário. Após concluir os 4 clubes, avaliar
> um refactor para algo genérico (provável que o catálogo em banco já resolva).

## 1. Modelo mental do domínio

```
Clube (Faíscas)
 └─ Manual (3)        → Saltador (Ano 01) | Caminhante (Ano 02) | Escalador (Ano 03)
     └─ Seção (6)     → Progresso, Atividades, Crédito-extra,
                         Frequência na igreja, Frequência no clube, Observações
         └─ Bloco      → ex.: "Exercício bíblico 01"  (tem um PRÊMIO + N itens)
             └─ Item   → bolinha numerada (1..N) + data de conclusão
```

- Cada **item** é apenas uma "bolinha com número" no manual → guardamos a
  quantidade por bloco e numeramos de 1 a N. Não há descrição textual.
- Cada **bloco** tem um prêmio (descrição fixa + data de recebimento) ganho ao
  concluir todos os itens.
- **Observações** = textarea livre por (oansista, manual) — não tem itens.

## 2. Decisões tomadas

| Tema | Decisão |
|---|---|
| Descrição dos itens | Genérica (bolinha numerada); **não** há texto por item |
| Estrutura (manuais/seções/blocos) | No banco (migrations + seed) |
| Premiação | Registrar só "prêmio recebido + data"; **sem** gerar `premios_pendentes` |
| Tabela legada `progresso_manual` | **Remover** + drop `trg_gerar_pendencia_premio`/`fn_gerar_pendencia_premio` e coluna `premios_pendentes.progresso_id` |

## 3. Modelo de dados — migration `0015_folha_individual.sql`

**Catálogo (config, por clube):**

```sql
create table folha_manuais (
  id uuid pk, clube_id uuid not null references clubes(id),
  nome text not null, ordem int not null,
  unique (clube_id, nome), unique (clube_id, ordem)
);

create table folha_secoes (
  id uuid pk, manual_id uuid not null references folha_manuais(id) on delete cascade,
  nome text not null, ordem int not null,
  tipo text not null check (tipo in ('itens','observacoes')),  -- Observações => 'observacoes'
  unique (manual_id, ordem), unique (manual_id, nome)
);

create table folha_blocos (
  id uuid pk, secao_id uuid not null references folha_secoes(id) on delete cascade,
  nome text not null, ordem int not null,
  quantidade int not null check (quantidade > 0),
  premio_nome text not null,              -- "Botão vermelho 01", "Distintivo do grau", etc.
  unique (secao_id, ordem)
);
```

**Progresso (por oansista):**

```sql
create table folha_item_progresso (
  id uuid pk,
  oansista_id uuid not null references oansistas(id) on delete cascade,
  bloco_id uuid not null references folha_blocos(id) on delete cascade,
  item_num int not null check (item_num >= 1),
  data_conclusao date not null default current_date,
  registrado_por uuid not null references profiles(id),
  created_at timestamptz default now(),
  unique (oansista_id, bloco_id, item_num)
);

create table folha_premio_progresso (
  id uuid pk,
  oansista_id uuid not null references oansistas(id) on delete cascade,
  bloco_id uuid not null references folha_blocos(id) on delete cascade,
  data_recebimento date not null default current_date,
  registrado_por uuid not null references profiles(id),
  created_at timestamptz default now(),
  unique (oansista_id, bloco_id)
);

create table folha_observacoes (
  id uuid pk,
  oansista_id uuid not null references oansistas(id) on delete cascade,
  manual_id uuid not null references folha_manuais(id) on delete cascade,
  texto text,
  updated_at timestamptz default now(),
  unique (oansista_id, manual_id)
);
```

**Limpeza do legado:**

```sql
drop trigger if exists trg_gerar_pendencia_premio on progresso_manual;
drop function if exists fn_gerar_pendencia_premio();
alter table premios_pendentes drop column if exists progresso_id;
drop table if exists progresso_manual;
-- grants para as novas tabelas (padrão da migration 0003)
grant select, insert, update, delete on all tables in schema public to authenticated, service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;
```

Índices: `idx_folha_item_progresso_oansista`, `idx_folha_premio_progresso_oansista`,
`idx_folha_manuais_clube`, `idx_folha_secoes_manual`, `idx_folha_blocos_secao`.

## 4. RLS — migration `0016_folha_individual_rls.sql`

Reuso de `fn_role`, `fn_diretor_do_clube`, `fn_lider_da_turma`.

- **Catálogo** (`folha_manuais`/`folha_secoes`/`folha_blocos`):
  - `select` p/ todo `authenticated`;
  - escrita só `diretor_geral`.
- **Progresso** (`folha_item_progresso`, `folha_premio_progresso`,
  `folha_observacoes`): mesmo escopo da antiga `progresso_write` —
  `diretor_geral` OU `diretor_do_clube(oansista.clube_id)` OU
  `lider_da_turma(oansista.turma_id)`.
- `enable row level security` nas 6 tabelas novas.

## 5. Seed — `supabase/seed.sql`

Catalogar o Faísca (blocos e quantidades, fonte: regras do usuário).

| Manual | Progresso (itens) | Atividades (itens) | Crédito | Freq. igreja | Freq. clube |
|---|---|---|---|---|---|
| Saltador | grau 6 · EB1 4 · EB2 4 · EB3 9 · EB4 6 | At1 1 · At2 2 · At3 4 · At4 2 | 7 | 2 | 4 |
| Caminhante | grau 6 · EB1 6 · EB2 6 · EB3 10 · EB4 8 | At1 2 · At2 3 · At3 5 · At4 4 | 7 | 2 | 4 |
| Escalador | grau 6 · EB1 6 · EB2 8 · EB3 7 · EB4 7 | At1 2 · At2 3 · At3 5 · At4 4 | 7 | 2 | 4 |

Prêmios por bloco: `Distintivo do grau`, `Botão vermelho 01..04`,
`Botão verde 01..04`, `Botão crédito extra`, `Botão azul`, `Botão amarelo`
(total: 3 manuais × 12 blocos = 36 blocos).

## 6. Frontend

1. **`src/utils/folhaIndividual.ts`** (lógica pura + spec): tipos normalizados
   `ManualFolha`/`SecaoFolha`/`BlocoFolha` (catálogo + progresso por oansista)
   montados por `normalizarFolhaIndividual(dados)` (ordena por `ordem` e abre os
   N itens de cada bloco); `blocoConcluido(bloco)`, `itensConcluidos(bloco)`,
   `premioHabilitado(bloco)` (libera a data do prêmio só com o bloco completo).
2. **`src/composables/useFolhaIndividual.ts`** (+ spec):
   `carregar(clubeId)`, `carregarProgresso(oansistaId)`,
   `salvarItem(oansistaId, blocoId, itemNum, data|null, registradoPor)`,
   `salvarPremio(oansistaId, blocoId, data|null, registradoPor)`,
   `salvarObservacao(oansistaId, manualId, texto)` (upsert por `unique`).
   O `registradoPor` é passado pela view (padrão dos demais composables, ex.
   `useFolhaSemanal.salvar`), pois as tabelas de progresso exigem `registrado_por`.
   Expõe `folha` (árvore `ManualFolha[]` normalizada), `carregando` e
   `carregandoProgresso`; `data|null` null remove o registro (delete).
3. **Componentes** em `src/components/folha/`:
   - `FolhaIndividualBloco.vue` (+ spec): itens numerados (descrição derivada do
     nome do bloco, ex. "Grau 1"/"Exercício 1"/"Atividade 1") + `InputText
     type=date`, e linha do prêmio (nome + data, habilitada ao concluir o bloco).
   - `FolhaIndividualManual.vue`: agrupa seções/blocos de um manual +
     `FolhaIndividualObservacoes.vue` (textarea).
   - `FolhaIndividualSeletor.vue`: seletor de oansista do clube.
4. **`src/views/clube/FolhaIndividualView.vue`**: seleção de oansista +
   `Tabs`/`Accordion` por manual (Saltador/Caminhante/Escalador).
5. **Rota + menu**:
   - `router/index.ts`: `/clube/folha-individual` →
     `meta.roles: ['diretor_geral', 'diretor_clube']` (v1 para o Diretor de
     Clube; entrada do Líder depois, reusando composable/view com escopo por turma).
   - `AppMenu.vue`: item "Folha Individual" no grupo "Clube".

## 7. Tipos

`npx supabase gen types typescript --local > src/types/database.types.ts` após as migrations.

## 8. Testes

- `utils/folhaIndividual.spec.ts` (node): conclusão de bloco, habilitação de prêmio.
- `composables/useFolhaIndividual.spec.ts`: mock de `@/lib/supabase`
  (helper `tests/helpers/supabase.ts`).
- `components/folha/FolhaIndividualBloco.spec.ts`: `mount` com stubs PrimeVue.
- Smoke test local opcional (stack Supabase): RLS do progresso
  (diretor vê clube, líder vê turma).

## 9. Ordem de execução

1. Migration `0015` (schema + limpeza do legado + grants) + `0016` (RLS).
2. `npx supabase db reset` + `gen types`.
3. Seed do catálogo Faísca (36 blocos).
4. `utils/folhaIndividual.ts` + spec.
5. `useFolhaIndividual.ts` + spec.
6. Componentes + view + rota + menu.
7. Testes verdes + `npm run lint` + `npm run typecheck` + `npm run test`.
8. Atualizar `docs/01`, `docs/02`, `docs/03`, `.agents/checklist.md`.
9. Commit(s) convencionais em português (`feat:` migration, `feat:` frontend).

## 10. Demais clubes (depois)

Ursinhos, Flamas e Tochas terão manuais/seções/blocos/quantidades próprios — com
o catálogo em banco, basta **novo seed por clube** (sem mudança de schema). O
refactor genérico só vale se as estruturas forem idênticas; senão, o catálogo já
é a "genericidade" sem esforço extra.

## Progresso

> Registrar aqui a cada passo concluído (regra do AGENTS.md: registrar + commitar).

- [x] **Passo 1 — Migrations**: `0015_folha_individual.sql` (catálogo + progresso + limpeza do `progresso_manual` legado + grants) e `0016_folha_individual_rls.sql` (RLS). Docs `01`/`02`/`03` atualizados.
- [x] **Passo 2 — Reset + types**: `npx supabase db reset` sem erros (migrations 0015/0016 aplicadas) e `npx supabase gen types` regenerado (novas tabelas presentes; `progresso_manual` removida).
- [x] **Passo 3 — Seed**: catálogo do Faísca em `supabase/seed.sql` (3 manuais, 18 seções, 36 blocos, 175 itens; Observações sem blocos) + espelho em `docs/01`; validado com `db reset` e queries (itens por manual: Saltador 51, Caminhante 63, Escalador 61).
- [x] **Passo 4 — Lógica pura**: `src/utils/folhaIndividual.ts` (tipos `ManualFolha`/`SecaoFolha`/`BlocoFolha` + `normalizarFolhaIndividual` + `itensConcluidos`/`blocoConcluido`/`premioHabilitado`) e `folhaIndividual.spec.ts` (9 testes); lint/typecheck/test verdes (187 testes).
- [x] **Passo 5 — Composable**: `useFolhaIndividual.ts` (catálogo em cascata `folha_manuais`→`folha_secoes`→`folha_blocos`, progresso do oansista em `itens`/`premios`/`observacoes` e árvore derivada `folha`; `salvarItem`/`salvarPremio` com upsert por unique e delete quando `data|null`; `salvarObservacao` com upsert por `(oansista, manual)`) e `useFolhaIndividual.spec.ts` (17 testes).
- [ ] **Passo 6 — UI**: componentes `src/components/folha/*`, `src/views/clube/FolhaIndividualView.vue`, rota e menu.
- [ ] **Passo 7 — Qualidade**: `npm run lint` + `npm run typecheck` + `npm run test`.
- [ ] **Passo 8 — Docs finais + checklist**: `.agents/checklist.md` e ajustes finais.
