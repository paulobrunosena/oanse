-- ============================================================================
-- OANSE - Substituto (remanejamento temporário) enxerga turma e oansistas.
-- fn_responsavel_pela_turma já autoriza presencas/folhas por encontro, mas as
-- policies de SELECT de turmas e oansistas só consideravam o titular
-- (fn_lider_da_turma) - o substituto não conseguia abrir a chamada da turma.
-- A edição continua restrita ao encontro via fn_responsavel_pelo_oansista.
--
-- Helpers SECURITY DEFINER (mesmo padrão das demais) para não consultar
-- tabelas com RLS dentro de policy e causar recursão infinita.
-- ============================================================================

-- O usuário é substituto da turma em algum encontro?
create or replace function fn_substituto_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from remanejamentos_temporarios
    where turma_id = p_turma_id and lider_substituto_id = auth.uid()
  );
$$;

-- O usuário é diretor do clube ao qual a turma pertence?
create or replace function fn_diretor_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select fn_diretor_do_clube(t.clube_id) from turmas t where t.id = p_turma_id;
$$;

drop policy "turmas_select" on turmas;
create policy "turmas_select" on turmas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or (fn_clube_id() is not null and clube_id = fn_clube_id())
    or fn_substituto_da_turma(id)
  );

drop policy "oansistas_select" on oansistas;
create policy "oansistas_select" on oansistas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube(clube_id)
    or (fn_role() = 'lider' and fn_lider_da_turma(turma_id))
    or (fn_role() = 'lider' and fn_substituto_da_turma(turma_id))
  );

-- Rewrite das policies de remanejamentos para usar os helpers (evita recursão).
drop policy "remanejamentos_select" on remanejamentos_temporarios;
create policy "remanejamentos_select" on remanejamentos_temporarios
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or lider_substituto_id = auth.uid()
    or fn_diretor_da_turma(turma_id)
    or fn_lider_da_turma(turma_id)
  );

drop policy "remanejamentos_write" on remanejamentos_temporarios;
create policy "remanejamentos_write" on remanejamentos_temporarios
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_da_turma(turma_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_da_turma(turma_id));