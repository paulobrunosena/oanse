-- ============================================================================
-- OANSE - Fase 3: pendência de premiação por conclusão de bloco da Folha
-- Individual + entrega pela Secretaria.
--
-- 1. `premios_pendentes.bloco_id`: identifica o bloco que originou a pendência
--    (necessário para gravar a data de recebimento na folha na entrega).
-- 2. Trigger em `folha_item_progresso`: ao concluir TODOS os itens de um bloco,
--    gera a pendência; ao desmarcar um item (bloco deixa de estar completo),
--    cancela a pendência ainda aberta.
-- 3. `fn_entregar_premio`: entrega transacional (marca entregue + baixa estoque
--    + movimentação + data na folha), validada dentro da função.
-- ============================================================================

-- 1. Vínculo da pendência com o bloco da folha
alter table premios_pendentes
  add column bloco_id uuid references folha_blocos(id);

-- 2. Recalcular pendência de um bloco para um oansista
create or replace function fn_recalcular_pendencia_premio(
  p_oansista_id uuid,
  p_bloco_id    uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_premio_id   uuid;
  v_quantidade  int;
  v_concluidos  int;
  v_clube_id    uuid;
begin
  select b.premio_id, b.quantidade
    into v_premio_id, v_quantidade
    from folha_blocos b
   where b.id = p_bloco_id;

  if v_premio_id is null then
    return; -- bloco sem prêmio vinculado ao catálogo
  end if;

  select clube_id into v_clube_id from oansistas where id = p_oansista_id;

  select count(*) into v_concluidos
    from folha_item_progresso
   where oansista_id = p_oansista_id
     and bloco_id = p_bloco_id;

  if v_concluidos >= v_quantidade then
    insert into premios_pendentes (oansista_id, premio_id, clube_id, bloco_id)
    values (p_oansista_id, v_premio_id, v_clube_id, p_bloco_id)
    on conflict (oansista_id, premio_id) do nothing;
  else
    update premios_pendentes
       set status = 'cancelada'
     where oansista_id = p_oansista_id
       and premio_id = v_premio_id
       and status = 'pendente';
  end if;
end;
$$;

create or replace function trg_folha_item_pendencia()
returns trigger
language plpgsql
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

create trigger trg_folha_item_pendencia
  after insert or delete on folha_item_progresso
  for each row execute function trg_folha_item_pendencia();

-- 3. Entrega do prêmio (transacional), chamada pelo server/api com service_role.
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

-- Cliente (via server route com service_role) e server: executam a RPC.
grant execute on function fn_entregar_premio(uuid, uuid, text) to authenticated, service_role;
