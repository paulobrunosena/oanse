-- ============================================================================
-- OANSE - Endurecimento de autorização (auditoria de 2026-10-17).
--
-- Correções com impacto de segurança:
--  1. Signup público deixa de aceitar o papel escolhido pelo cliente: o
--     trigger fixa 'lider'. O papel real passa a ser definido pelo admin, com
--     service_role, em server/api/usuarios.
--  2. profiles.ativo passa a valer na autorização (RLS + RPCs): desativar um
--     usuário revoga o acesso de verdade (antes a flag era ignorada).
--  3. Checagens `if not (fn_role() = ...)` são NULL-inseguras: com auth.uid()
--     NULL (chamada via service_role ou anon) a condição vira NULL e o
--     `raise exception` nunca dispara — bypass silencioso. Agora usam
--     `coalesce(..., false)`.
--  4. fn_transferir_oansista autoriza pelo p_autorizado_por (a rota chama com
--     service_role, onde auth.uid() é NULL) com escopo de clube; o
--     auth.uid() era justamente o que não existia no caminho oficial.
--  5. RPCs exclusivas do servidor perdem EXECUTE de anon/authenticated (o
--     default do Postgres é EXECUTE para PUBLIC): transferência, entrega de
--     prêmio, movimentação de estoque e os recálculos internos.
--  6. Rankings deixam de vazar dados entre perfis: fn_ranking_do_encontro só
--     diretor_geral/diretor_clube e fn_ranking_cores_do_evento só
--     lider_jogos/diretor_geral; anon perde EXECUTE das RPCs do cliente.
--
-- Observação: as funções-auxiliares de RLS (fn_role, fn_clube_id,
-- fn_lider_da_turma, ...) continuam executáveis por authenticated porque as
-- políticas RLS as avaliam com o privilégio do usuário consultante.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Signup: o papel nunca vem do cliente (o admin define depois via service_role)
-- ----------------------------------------------------------------------------
create or replace function fn_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nome, telefone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', new.email),
    new.raw_user_meta_data->>'telefone',
    'lider' -- nunca ler o papel de raw_user_meta_data (controlado no signup)
  );
  return new;
end $$;

-- ----------------------------------------------------------------------------
-- 2. profiles.ativo vale na autorização (RLS + RPCs)
-- ----------------------------------------------------------------------------
create or replace function fn_role()
returns user_role language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid() and ativo;
$$;

create or replace function fn_clube_id()
returns uuid language sql stable security definer set search_path = public as $$
  select clube_id from profiles where id = auth.uid() and ativo;
$$;

create or replace function fn_lider_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
      from turmas t
      join profiles p on p.id = auth.uid() and p.ativo
     where t.id = p_turma_id and t.lider_id = auth.uid() and t.ativo
  );
$$;

create or replace function fn_substituto_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
      from remanejamentos_temporarios rt
      join profiles p on p.id = auth.uid() and p.ativo
     where rt.turma_id = p_turma_id and rt.lider_substituto_id = auth.uid()
  );
$$;

create or replace function fn_responsavel_pela_turma(p_turma_id uuid, p_encontro_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles p where p.id = auth.uid() and p.ativo)
     and (
       exists (
         select 1 from turmas
         where id = p_turma_id and lider_id = auth.uid() and ativo
       )
       or exists (
         select 1 from remanejamentos_temporarios rt
         where rt.turma_id = p_turma_id
           and rt.encontro_id = p_encontro_id
           and rt.lider_substituto_id = auth.uid()
       )
     );
$$;

-- ----------------------------------------------------------------------------
-- 3. Trigger de pendência vira SECURITY DEFINER
--    (fn_recalcular_pendencia_premio passa a ser exclusiva do sistema; sem o
--    definer, o trigger executaria como o líder e perderia o EXECUTE)
-- ----------------------------------------------------------------------------
create or replace function trg_folha_item_pendencia()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_oansista uuid;
  v_bloco    uuid;
begin
  if tg_op = 'DELETE' then
    v_oansista := old.oansista_id;
    v_bloco    := old.bloco_id;
  else
    v_oansista := new.oansista_id;
    v_bloco    := new.bloco_id;
  end if;

  perform fn_recalcular_pendencia_premio(v_oansista, v_bloco);
  return null;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Transferência: autorização pelo p_autorizado_por (NULL-safe) + clube
-- ----------------------------------------------------------------------------
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
  select * into v_oansista from oansistas where id = p_oansista_id;
  if not found then
    raise exception 'Oansista não encontrado';
  end if;

  -- Autorização pelo perfil informado (a rota chama com service_role, onde
  -- auth.uid() não existe) e NULL-safe: sem perfil válido => nega.
  if not exists (
    select 1
      from profiles p
     where p.id = p_autorizado_por
       and p.ativo
       and (
         p.role = 'diretor_geral'
         or (p.role = 'diretor_clube' and p.clube_id = v_oansista.clube_id)
       )
  ) then
    raise exception 'Apenas o Diretor do clube pode transferir';
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

-- ----------------------------------------------------------------------------
-- 5. Entrega de prêmio / movimentação de estoque: checam ativo
-- ----------------------------------------------------------------------------
create or replace function fn_entregar_premio(
  p_pendencia_id   uuid,
  p_autorizado_por uuid,
  p_observacao     text default null
)
returns premios_pendentes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pendencia premios_pendentes%rowtype;
begin
  -- Autorização validada pelo id informado (a RPC roda com service_role,
  -- então fn_role()/auth.uid() não se aplicam aqui).
  if not exists (
    select 1 from profiles p
    where p.id = p_autorizado_por
      and p.ativo
      and p.role in ('diretor_geral', 'secretaria')
  ) then
    raise exception 'Apenas a Secretaria pode entregar prêmios';
  end if;

  select * into v_pendencia from premios_pendentes where id = p_pendencia_id;
  if not found then
    raise exception 'Pendência não encontrada';
  end if;

  if v_pendencia.status <> 'pendente' then
    raise exception 'Pendência já resolvida';
  end if;

  if v_pendencia.bloco_id is not null
     and not exists (select 1 from premios where id = v_pendencia.premio_id and estoque > 0) then
    raise exception 'Sem estoque disponível para este prêmio';
  end if;

  update premios_pendentes
     set status = 'entregue',
         data_entrega = now(),
         entregue_por = p_autorizado_por,
         observacao = coalesce(p_observacao, observacao)
   where id = p_pendencia_id;

  update premios
     set estoque = estoque - 1
   where id = v_pendencia.premio_id
     and estoque > 0;

  insert into premios_movimentacoes (premio_id, tipo, quantidade, observacao, feito_por)
  values (v_pendencia.premio_id, 'saida', 1, p_observacao, p_autorizado_por);

  if v_pendencia.bloco_id is not null then
    insert into folha_premio_progresso (oansista_id, bloco_id, data_recebimento, registrado_por)
    values (v_pendencia.oansista_id, v_pendencia.bloco_id, current_date, p_autorizado_por)
    on conflict (oansista_id, bloco_id) do update
      set data_recebimento = excluded.data_recebimento,
          registrado_por = excluded.registrado_por;
  end if;

  return v_pendencia;
end;
$$;

create or replace function fn_movimentar_estoque(
  p_premio_id      uuid,
  p_tipo           text,
  p_quantidade     int,
  p_autorizado_por uuid,
  p_observacao     text default null
)
returns premios_movimentacoes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_premio premios%rowtype;
  v_mov    premios_movimentacoes%rowtype;
begin
  -- Autorização validada pelo id informado (a RPC roda com service_role,
  -- então fn_role()/auth.uid() não se aplicam aqui).
  if not exists (
    select 1 from profiles p
    where p.id = p_autorizado_por
      and p.ativo
      and p.role in ('diretor_geral', 'secretaria')
  ) then
    raise exception 'Apenas a Secretaria pode registrar movimentações de estoque';
  end if;

  if p_tipo not in ('entrada', 'saida') then
    raise exception 'Tipo de movimentação inválido';
  end if;

  if p_quantidade is null or p_quantidade <= 0 then
    raise exception 'A quantidade deve ser maior que zero';
  end if;

  select * into v_premio from premios where id = p_premio_id;
  if not found then
    raise exception 'Prêmio não encontrado';
  end if;

  if p_tipo = 'saida' and v_premio.estoque < p_quantidade then
    raise exception 'Estoque insuficiente para esta saída';
  end if;

  update premios
     set estoque = estoque + case when p_tipo = 'entrada' then p_quantidade else -p_quantidade end
   where id = p_premio_id;

  insert into premios_movimentacoes (premio_id, tipo, quantidade, observacao, feito_por)
  values (p_premio_id, p_tipo, p_quantidade, nullif(trim(p_observacao), ''), p_autorizado_por)
  returning * into v_mov;

  return v_mov;
end;
$$;

-- ----------------------------------------------------------------------------
-- 6. RPCs do cliente: checagem NULL-safe (bloqueia chamada anônima)
-- ----------------------------------------------------------------------------
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
  if not coalesce(
    fn_role() = 'diretor_geral' or fn_diretor_do_clube(v_visitante.clube_id),
    false
  ) then
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

create or replace function fn_criar_jogo(
  p_encontro_id uuid,
  p_nome        text,
  p_clubes      uuid[],
  p_criado_por  uuid default auth.uid()
)
returns jogos
language plpgsql security definer set search_path = public as $$
declare
  v_jogo jogos;
  v_n    int;
begin
  select array_length(p_clubes, 1) into v_n;

  if v_n is null or v_n < 1 then
    raise exception 'O jogo precisa de ao menos 1 clube';
  end if;
  if v_n > 4 then
    raise exception 'Um jogo pode envolver no máximo os 4 clubes';
  end if;

  if not coalesce(
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube' and fn_clube_id() = any (p_clubes)),
    false
  ) then
    raise exception 'Apenas o diretor de um clube participante pode criar o jogo';
  end if;

  insert into jogos (encontro_id, nome, criado_por)
  values (p_encontro_id, p_nome, p_criado_por)
  returning * into v_jogo;

  insert into jogos_clubes (jogo_id, clube_id)
  select v_jogo.id, c
    from unnest(p_clubes) as c
  on conflict (jogo_id, clube_id) do nothing;

  return v_jogo;
end;
$$;

create or replace function fn_criar_evento_jogos(
  p_encontro_id uuid,
  p_nome        text,
  p_clubes      uuid[],
  p_cores       text[],
  p_criado_por  uuid default auth.uid()
)
returns eventos_jogos
language plpgsql security definer set search_path = public as $$
declare
  v_evento  eventos_jogos;
  v_n       int;
  v_cor     text;
begin
  select array_length(p_clubes, 1) into v_n;
  if v_n is null or v_n < 1 then
    raise exception 'Selecione ao menos um clube participante';
  end if;

  select array_length(p_cores, 1) into v_n;
  if v_n is null or v_n < 2 then
    raise exception 'Selecione ao menos 2 cores participantes';
  end if;

  if not coalesce(fn_role() in ('lider_jogos', 'diretor_geral'), false) then
    raise exception 'Apenas o líder de jogos pode criar o evento de jogos';
  end if;

  if exists (
    select 1 from evento_jogos_clubes ec
    join eventos_jogos ev on ev.id = ec.evento_id
    where ev.encontro_id = p_encontro_id
      and ec.clube_id = any (p_clubes)
  ) then
    raise exception 'Um dos clubes selecionados já participou de um evento de jogos neste sábado';
  end if;

  foreach v_cor in array p_cores loop
    if v_cor not in ('verde', 'vermelho', 'amarelo', 'azul') then
      raise exception 'Cor inválida: %', v_cor;
    end if;
  end loop;

  insert into eventos_jogos (encontro_id, nome, criado_por)
  values (p_encontro_id, p_nome, p_criado_por)
  returning * into v_evento;

  insert into evento_jogos_clubes (evento_id, clube_id)
  select v_evento.id, c from unnest(p_clubes) c
  on conflict (evento_id, clube_id) do nothing;

  insert into evento_jogos_cores (evento_id, cor)
  select v_evento.id, c from unnest(p_cores) c
  on conflict (evento_id, cor) do nothing;

  return v_evento;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7. Rankings com escopo (antes qualquer autenticado via todos os clubes)
-- ----------------------------------------------------------------------------
create or replace function fn_ranking_do_encontro(p_encontro_id uuid)
returns table (
  clube_nome     text,
  oansista_id    uuid,
  oansista_nome  text,
  total          int,
  posicao        bigint
) language plpgsql stable security definer set search_path = public as $$
begin
  if not coalesce(fn_role() in ('diretor_geral', 'diretor_clube'), false) then
    raise exception 'Sem permissão para ver o ranking do encontro';
  end if;

  return query
    select c.nome, o.id, o.nome, f.total,
           rank() over (partition by o.clube_id order by f.total desc, o.nome)
    from folhas_semanais f
    join oansistas o on o.id = f.oansista_id
    join clubes c    on c.id = o.clube_id
    where f.encontro_id = p_encontro_id;
end;
$$;

create or replace function fn_ranking_cores_do_evento(p_evento_id uuid)
returns table (cor text, pontos bigint, posicao bigint)
language plpgsql stable security definer set search_path = public as $$
begin
  if not coalesce(fn_role() in ('lider_jogos', 'diretor_geral'), false) then
    raise exception 'Sem permissão para ver o ranking do evento';
  end if;

  return query
    select c.cor,
           coalesce(sum(r.pontos), 0) as pontos,
           rank() over (order by coalesce(sum(r.pontos), 0) desc, c.cor)
      from evento_jogos_cores c
      left join jogo_resultados r on r.cor_id = c.id
     where c.evento_id = p_evento_id
     group by c.id, c.cor
     order by 2 desc, c.cor;
end;
$$;

-- ----------------------------------------------------------------------------
-- 8. Grants: RPCs server-only ficam restritas ao service_role; RPCs do cliente
--    deixam de aceitar anon (o default do Postgres era EXECUTE para PUBLIC).
-- ----------------------------------------------------------------------------
revoke execute on function fn_transferir_oansista(uuid, uuid, text, uuid) from public, anon, authenticated;
grant execute on function fn_transferir_oansista(uuid, uuid, text, uuid) to service_role;

revoke execute on function fn_entregar_premio(uuid, uuid, text) from public, anon, authenticated;
grant execute on function fn_entregar_premio(uuid, uuid, text) to service_role;

revoke execute on function fn_movimentar_estoque(uuid, text, integer, uuid, text) from public, anon, authenticated;
grant execute on function fn_movimentar_estoque(uuid, text, integer, uuid, text) to service_role;

revoke execute on function fn_recalcular_pendencia_premio(uuid, uuid) from public, anon, authenticated;
grant execute on function fn_recalcular_pendencia_premio(uuid, uuid) to service_role;

revoke execute on function fn_recalcular_pontos_jogos_encontro(uuid) from public, anon, authenticated;
grant execute on function fn_recalcular_pontos_jogos_encontro(uuid) to service_role;

revoke execute on function fn_criar_jogo(uuid, text, uuid[], uuid) from public, anon;
grant execute on function fn_criar_jogo(uuid, text, uuid[], uuid) to authenticated, service_role;

revoke execute on function fn_criar_evento_jogos(uuid, text, uuid[], text[], uuid) from public, anon;
grant execute on function fn_criar_evento_jogos(uuid, text, uuid[], text[], uuid) to authenticated, service_role;

revoke execute on function fn_matricular_visitante(uuid, uuid) from public, anon;
grant execute on function fn_matricular_visitante(uuid, uuid) to authenticated, service_role;

revoke execute on function fn_ranking_do_encontro(uuid) from public, anon;
grant execute on function fn_ranking_do_encontro(uuid) to authenticated, service_role;

revoke execute on function fn_ranking_cores_do_evento(uuid) from public, anon;
grant execute on function fn_ranking_cores_do_evento(uuid) to authenticated, service_role;
