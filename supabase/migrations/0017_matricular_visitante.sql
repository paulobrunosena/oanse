-- ============================================================================
-- OANSE - Matrícula de visitante (Folha de Visitantes — Fase 2).
--
-- Converte um visitante em oansista: cria o registro em oansistas (herdando
-- nome, nascimento, clube, responsável e contato do visitante) e marca o
-- visitante como 'matriculado'. As duas operações precisam ser atômicas (uma
-- transação) — o Supabase JS não agrupa statements, então a operação vive numa
-- função RPC (SECURITY DEFINER) chamada diretamente pelo cliente (anon + JWT do
-- usuário), no mesmo padrão das RPCs do módulo de jogos (fn_criar_evento_jogos).
--
-- A autorização é validada DENTRO da função (diretor_geral ou diretor do clube
-- do visitante), então nem um cliente nem um usuário errado conseguem burlar a
-- regra mesmo invocando a RPC diretamente. A turma (opcional) deve pertencer ao
-- mesmo clube do visitante.
-- ============================================================================
create or replace function fn_matricular_visitante(
  p_visitante_id uuid,
  p_turma_id     uuid default null
)
returns oansistas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_visitante visitantes%rowtype;
  v_oansista  oansistas;
begin
  select * into v_visitante from visitantes where id = p_visitante_id;
  if not found then
    raise exception 'Visitante não encontrado';
  end if;

  if v_visitante.status = 'matriculado' then
    raise exception 'Visitante já está matriculado';
  end if;

  -- Autorização: Diretor Geral ou Diretor do clube do visitante.
  if not (fn_role() = 'diretor_geral' or fn_diretor_do_clube(v_visitante.clube_id)) then
    raise exception 'Apenas o Diretor do clube pode matricular';
  end if;

  if p_turma_id is not null then
    if not exists (
      select 1 from turmas t
      where t.id = p_turma_id and t.clube_id = v_visitante.clube_id and t.ativo
    ) then
      raise exception 'Turma inválida ou de outro clube';
    end if;
  end if;

  insert into oansistas (
    nome, data_nascimento, clube_id, turma_id,
    responsavel, contato, data_matricula, status
  )
  values (
    v_visitante.nome, v_visitante.data_nascimento, v_visitante.clube_id, p_turma_id,
    v_visitante.responsavel, v_visitante.contato, current_date, 'ativo'
  )
  returning * into v_oansista;

  update visitantes
     set status = 'matriculado', updated_at = now()
   where id = p_visitante_id;

  return v_oansista;
end;
$$;

-- Cliente (anon + JWT) e server: executam a RPC.
grant execute on function fn_matricular_visitante(uuid, uuid) to authenticated, service_role;
