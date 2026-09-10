-- ============================================================================
-- OANSE - RLS da Folha de Progresso Individual (docs/06-folha-individual.md)
--
-- Catálogo: leitura para todos autenticados; escrita só Diretor Geral.
-- Progresso: mesmo escopo do antigo `progresso_manual` (diretor_geral,
-- diretor do clube do oansista, líder titular da turma do oansista).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ATIVAÇÃO DO RLS
-- ----------------------------------------------------------------------------
alter table folha_manuais          enable row level security;
alter table folha_secoes           enable row level security;
alter table folha_blocos           enable row level security;
alter table folha_item_progresso   enable row level security;
alter table folha_premio_progresso enable row level security;
alter table folha_observacoes      enable row level security;

-- ----------------------------------------------------------------------------
-- CATÁLOGO
-- ----------------------------------------------------------------------------
create policy "folha_manuais_select" on folha_manuais
  for select to authenticated using (true);

create policy "folha_manuais_write" on folha_manuais
  for all to authenticated
  using (fn_role() = 'diretor_geral')
  with check (fn_role() = 'diretor_geral');

create policy "folha_secoes_select" on folha_secoes
  for select to authenticated using (true);

create policy "folha_secoes_write" on folha_secoes
  for all to authenticated
  using (fn_role() = 'diretor_geral')
  with check (fn_role() = 'diretor_geral');

create policy "folha_blocos_select" on folha_blocos
  for select to authenticated using (true);

create policy "folha_blocos_write" on folha_blocos
  for all to authenticated
  using (fn_role() = 'diretor_geral')
  with check (fn_role() = 'diretor_geral');

-- ----------------------------------------------------------------------------
-- PROGRESSO
-- ----------------------------------------------------------------------------
create policy "folha_item_progresso_select" on folha_item_progresso
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_item_progresso.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_item_progresso.oansista_id))
  );

create policy "folha_item_progresso_write" on folha_item_progresso
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_item_progresso.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_item_progresso.oansista_id))
  )
  with check (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_item_progresso.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_item_progresso.oansista_id))
  );

create policy "folha_premio_progresso_select" on folha_premio_progresso
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_premio_progresso.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_premio_progresso.oansista_id))
  );

create policy "folha_premio_progresso_write" on folha_premio_progresso
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_premio_progresso.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_premio_progresso.oansista_id))
  )
  with check (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_premio_progresso.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_premio_progresso.oansista_id))
  );

create policy "folha_observacoes_select" on folha_observacoes
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_observacoes.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_observacoes.oansista_id))
  );

create policy "folha_observacoes_write" on folha_observacoes
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_observacoes.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_observacoes.oansista_id))
  )
  with check (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = folha_observacoes.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = folha_observacoes.oansista_id))
  );
