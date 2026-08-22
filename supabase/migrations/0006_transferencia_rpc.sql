-- ============================================================================
-- OANSE - Transferência permanente de oansista entre turmas do mesmo clube.
--
-- A transferência é AUDITORIA: além de mover o vínculo em oansistas.turma_id,
-- deve gravar o histórico em transferencias. As duas operações precisam ser
-- atômicas (uma transação) — o Supabase JS não agrupa statements, então a
-- operação vive numa função RPC (SECURITY DEFINER) chamada pelo
-- server/api/transferencias.post.ts com service_role.
--
-- A autorização é validada DENTRO da função (diretor_geral ou diretor do clube
-- da criança), então nem um cliente nem um usuário errado conseguem burlar a
-- regra mesmo invocando a RPC diretamente.
-- ============================================================================
create or replace function fn_transferir_oansista(
  p_oansista_id       uuid,
  p_turma_destino_id  uuid,
  p_motivo            text default null,
  p_autorizado_por    uuid default auth.uid()
)
returns transferencias
language plpgsql
security definer
set search_path = public
as $$
declare
  v_oansista    oansistas%rowtype;
  v_destino     turmas%rowtype;
  v_registro    transferencias;
begin
  -- Autorização: Diretor Geral ou Diretor do clube ao qual a criança pertence.
  if not (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas where id = p_oansista_id))
  ) then
    raise exception 'Apenas o Diretor do clube pode transferir';
  end if;

  select * into v_oansista from oansistas where id = p_oansista_id;
  if not found then
    raise exception 'Oansista não encontrado';
  end if;

  select * into v_destino from turmas where id = p_turma_destino_id and ativo;
  if not found then
    raise exception 'Turma de destino não encontrada ou inativa';
  end if;

  if v_destino.clube_id <> v_oansista.clube_id then
    raise exception 'A turma de destino deve pertencer ao mesmo clube';
  end if;

  if v_oansista.turma_id = p_turma_destino_id then
    raise exception 'A criança já está nesta turma';
  end if;

  -- Histórico (auditoria) + novo vínculo, numa única transação.
  insert into transferencias (
    oansista_id, tipo, turma_origem_id, turma_destino_id,
    lider_origem_id, lider_destino_id, data, motivo, autorizado_por
  )
  values (
    p_oansista_id, 'permanente', v_oansista.turma_id, v_destino.id,
    (select lider_id from turmas where id = v_oansista.turma_id),
    v_destino.lider_id,
    current_date, p_motivo, p_autorizado_por
  )
  returning * into v_registro;

  update oansistas
     set turma_id = p_turma_destino_id, updated_at = now()
   where id = p_oansista_id;

  return v_registro;
end;
$$;

-- Cliente (via server route com service_role) e server: executam a RPC.
grant execute on function fn_transferir_oansista(uuid, uuid, text, uuid) to authenticated, service_role;