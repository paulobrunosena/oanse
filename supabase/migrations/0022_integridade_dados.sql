-- ============================================================================
-- OANSE - Integridade de dados (auditoria de 2026-10-17, Onda 2).
--
--  1. fn_recalcular_pontos_jogos_encontro passa a ZERAR cor/posição/pontos de
--     quem está presente mas não participa mais de nenhum evento do sábado
--     (antes, remover a criança da cor/evento deixava a folha pontuando).
--  2. Exclusões (rodada, cor e evento) recalculam DEPOIS da cascata: um
--     BEFORE DELETE guarda o encontro em `set_config` (o registro já não
--     existe no AFTER DELETE) e os AFTER DELETE das tabelas-pai recalculam.
--  3. trg_folha_total disparava só em colunas específicas; um PATCH isolado de
--     `total` gravava valor arbitrário. Agora recalcula em qualquer UPDATE.
--  4. folha_item_progresso.item_num limitado à quantidade do bloco: itens
--     "extras" davam bloco completo e geravam prêmio indevido.
--  5. fn_entregar_premio: lock da pendência (entrega concorrente não duplica),
--     estoque obrigatório para QUALQUER prêmio e baixa verificada (nunca grava
--     movimentação de saída sem baixar estoque).
--  6. Nova RPC transacional fn_registrar_rodada (jogo + resultados numa única
--     transação) — o cliente não faz mais insert + N upserts soltos.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Recálculo zera quem saiu do evento
-- ----------------------------------------------------------------------------
create or replace function fn_recalcular_pontos_jogos_encontro(p_encontro uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update folhas_semanais f
     set pontos_jogos  = coalesce(
                           (select pontos from itens_pontuacao
                             where chave = 'jogo_' || rk.posicao || '_lugar'
                               and ativo),
                           0),
         cor_time      = d.cor,
         posicao_jogos = rk.posicao
    from (
      select i.oansista_id, c.cor, c.id as cor_id
        from evento_jogos_cores_oansistas i
        join evento_jogos_cores c on c.id = i.cor_id
        join eventos_jogos ev on ev.id = c.evento_id
       where ev.encontro_id = p_encontro
       group by i.oansista_id, c.id, c.cor
    ) d
    left join (
      select t.cor_id, t.posicao
        from (
          select c.id as cor_id,
                 rank() over (partition by ev.id
                              order by coalesce(sum(r.pontos), 0) desc, c.cor) as posicao
            from evento_jogos_cores c
            join eventos_jogos ev on ev.id = c.evento_id
            left join jogo_resultados r on r.cor_id = c.id
           where ev.encontro_id = p_encontro
           group by c.id, c.cor, ev.id
        ) t
    ) rk on rk.cor_id = d.cor_id
   where f.oansista_id = d.oansista_id
     and f.encontro_id = p_encontro
     and exists (
       select 1 from presencas pr where pr.id = f.presenca_id and pr.presente
     );

  -- Presença que NÃO está em nenhum evento do sábado (saiu da cor, teve a cor
  -- ou o evento excluído): volta a zero para não pontuar sem estar no jogo.
  update folhas_semanais f
     set pontos_jogos  = 0,
         cor_time      = null,
         posicao_jogos = null
   where f.encontro_id = p_encontro
     and exists (
       select 1 from presencas pr where pr.id = f.presenca_id and pr.presente
     )
     and not exists (
       select 1
         from evento_jogos_cores_oansistas i
         join evento_jogos_cores c on c.id = i.cor_id
         join eventos_jogos ev on ev.id = c.evento_id
        where ev.encontro_id = p_encontro
          and i.oansista_id = f.oansista_id
     );
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. Exclusões recalculam depois da cascata (encontro guardado no BEFORE DELETE)
-- ----------------------------------------------------------------------------
create or replace function fn_guardar_encontro_do_delete()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_encontro uuid;
begin
  if TG_TABLE_NAME = 'eventos_jogos' then
    v_encontro := old.encontro_id;
  else
    -- jogos.evento_id e evento_jogos_cores.evento_id
    select ev.encontro_id into v_encontro from eventos_jogos ev where ev.id = old.evento_id;
  end if;

  if v_encontro is not null then
    perform set_config('oanse.recalcular_encontro', v_encontro::text, true);
  end if;
  return old;
end;
$$;

create or replace function fn_recalcular_encontro_do_delete()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_encontro uuid := nullif(current_setting('oanse.recalcular_encontro', true), '')::uuid;
begin
  if v_encontro is not null then
    perform fn_recalcular_pontos_jogos_encontro(v_encontro);
  end if;
  return old;
end;
$$;

drop trigger if exists trg_guardar_encontro_jogos on jogos;
create trigger trg_guardar_encontro_jogos
  before delete on jogos
  for each row execute function fn_guardar_encontro_do_delete();

drop trigger if exists trg_recalcular_encontro_jogos on jogos;
create trigger trg_recalcular_encontro_jogos
  after delete on jogos
  for each row execute function fn_recalcular_encontro_do_delete();

drop trigger if exists trg_guardar_encontro_cores on evento_jogos_cores;
create trigger trg_guardar_encontro_cores
  before delete on evento_jogos_cores
  for each row execute function fn_guardar_encontro_do_delete();

drop trigger if exists trg_recalcular_encontro_cores on evento_jogos_cores;
create trigger trg_recalcular_encontro_cores
  after delete on evento_jogos_cores
  for each row execute function fn_recalcular_encontro_do_delete();

drop trigger if exists trg_guardar_encontro_eventos on eventos_jogos;
create trigger trg_guardar_encontro_eventos
  before delete on eventos_jogos
  for each row execute function fn_guardar_encontro_do_delete();

drop trigger if exists trg_recalcular_encontro_eventos on eventos_jogos;
create trigger trg_recalcular_encontro_eventos
  after delete on eventos_jogos
  for each row execute function fn_recalcular_encontro_do_delete();

-- ----------------------------------------------------------------------------
-- 3. total sempre recalculado (qualquer UPDATE)
-- ----------------------------------------------------------------------------
drop trigger if exists trg_folha_total on folhas_semanais;
create trigger trg_folha_total
  before insert or update
  on folhas_semanais
  for each row execute function fn_calcular_total_folha();

-- ----------------------------------------------------------------------------
-- 4. item_num dentro da quantidade do bloco
-- ----------------------------------------------------------------------------
create or replace function fn_validar_item_num()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_quantidade int;
begin
  select quantidade into v_quantidade from folha_blocos where id = new.bloco_id;
  if v_quantidade is null then
    raise exception 'Bloco não encontrado';
  end if;

  if new.item_num < 1 or new.item_num > v_quantidade then
    raise exception 'Item fora do intervalo do bloco (1 a %)', v_quantidade;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validar_item_num on folha_item_progresso;
create trigger trg_validar_item_num
  before insert or update of item_num, bloco_id on folha_item_progresso
  for each row execute function fn_validar_item_num();

-- ----------------------------------------------------------------------------
-- 5. Entrega de prêmio: lock + estoque obrigatório + baixa verificada
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
  v_estoque   int;
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

  -- Lock da linha: uma segunda entrega concorrente espera e cai no check de
  -- status abaixo (sem baixa/registro duplicados).
  select * into v_pendencia from premios_pendentes where id = p_pendencia_id for update;
  if not found then
    raise exception 'Pendência não encontrada';
  end if;

  if v_pendencia.status <> 'pendente' then
    raise exception 'Pendência já resolvida';
  end if;

  -- Baixa verificada: nunca registra a saída sem baixar o estoque.
  update premios
     set estoque = estoque - 1
   where id = v_pendencia.premio_id
     and estoque > 0
  returning estoque into v_estoque;

  if not found then
    raise exception 'Sem estoque disponível para este prêmio';
  end if;

  update premios_pendentes
     set status = 'entregue',
         data_entrega = now(),
         entregue_por = p_autorizado_por,
         observacao = coalesce(p_observacao, observacao)
   where id = p_pendencia_id;

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

-- ----------------------------------------------------------------------------
-- 6. RPC transacional do registro de rodada (jogo + resultados)
--    p_resultados: [{ "cor_id": "...", "colocacao": 1|null, "desclassificado": false }, ...]
-- ----------------------------------------------------------------------------
create or replace function fn_registrar_rodada(
  p_evento_id  uuid,
  p_nome       text,
  p_resultados jsonb,
  p_criado_por uuid default auth.uid()
)
returns jogos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_jogo      jogos;
  v_elem      jsonb;
  v_cor_id    uuid;
  v_colocacao int;
begin
  if not coalesce(fn_role() in ('lider_jogos', 'diretor_geral'), false) then
    raise exception 'Apenas o líder de jogos pode registrar rodadas';
  end if;

  if nullif(trim(p_nome), '') is null then
    raise exception 'Informe o jogo/atividade da rodada';
  end if;

  if not exists (select 1 from eventos_jogos where id = p_evento_id) then
    raise exception 'Evento não encontrado';
  end if;

  insert into jogos (evento_id, nome, criado_por)
  values (p_evento_id, trim(p_nome), p_criado_por)
  returning * into v_jogo;

  if p_resultados is not null then
    for v_elem in select * from jsonb_array_elements(p_resultados) loop
      v_cor_id := (v_elem->>'cor_id')::uuid;

      if not exists (
        select 1 from evento_jogos_cores
        where id = v_cor_id and evento_id = p_evento_id
      ) then
        raise exception 'Cor não pertence a este evento';
      end if;

      v_colocacao := case
        when v_elem->>'colocacao' is null or v_elem->>'colocacao' = 'null' then null
        else (v_elem->>'colocacao')::int
      end;

      if v_colocacao is not null and (v_colocacao < 1 or v_colocacao > 4) then
        raise exception 'Colocação inválida (1 a 4)';
      end if;

      insert into jogo_resultados (jogo_id, cor_id, colocacao, desclassificado)
      values (
        v_jogo.id,
        v_cor_id,
        v_colocacao,
        coalesce((v_elem->>'desclassificado')::boolean, false)
      );
    end loop;
  end if;

  return v_jogo;
end;
$$;

revoke execute on function fn_registrar_rodada(uuid, text, jsonb, uuid) from public, anon;
grant execute on function fn_registrar_rodada(uuid, text, jsonb, uuid) to authenticated, service_role;
