-- ============================================================================
-- OANSE - Recalculo da Folha Semanal ao alterar a presenca.
-- O trg_folha_total (0001) so dispara quando a folha e alterada. A chamada,
-- porem, alterna presenca direto em presencas (falta <=> presente). Sem esse
-- trigger, a folha ficaria com o total desatualizado ao corrigir uma presenca.
-- Fazemos um "touch" na coluna presenca_id (que esta na lista de colunas do
-- trg_folha_total) para recalcular o total conforme a nova presenca.
-- ============================================================================

create or replace function fn_recalcular_folha_por_presenca()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update folhas_semanais
     set presenca_id = presenca_id
   where encontro_id = new.encontro_id
     and oansista_id = new.oansista_id;
  return new;
end $$;

create trigger trg_folha_recalcular_presenca
  after insert or update of presente on presencas
  for each row execute function fn_recalcular_folha_por_presenca();