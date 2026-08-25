-- ============================================================================
-- OANSE - Múltiplos eventos de jogos por sábado
--
-- Permite mais de um evento de jogos no mesmo sábado (ex.: um evento dos
-- Flamas+Tochas e outro dos Ursinhos+Faíscas). Um clube não pode ter mais de
-- um evento no mesmo sábado — validado por trigger em evento_jogos_clubes
-- (qualquer via de entrada, inclusive insert direto) e pela RPC
-- fn_criar_evento_jogos (mensagem antecipada no fluxo normal).
-- ============================================================================

-- 1. Remove a restrição de um evento por encontro
alter table eventos_jogos drop constraint if exists eventos_jogos_encontro_id_key;

-- 2. Trigger: clube com evento no sábado não entra em outro evento do mesmo sábado
create or replace function fn_validar_clube_sem_evento_no_sabado()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_encontro uuid;
begin
  select ev.encontro_id into v_encontro from eventos_jogos ev where ev.id = new.evento_id;

  if exists (
    select 1 from evento_jogos_clubes ec
    join eventos_jogos ev on ev.id = ec.evento_id
    where ev.encontro_id = v_encontro
      and ec.clube_id = new.clube_id
      and ec.id <> new.id
  ) then
    raise exception 'O clube já participou de um evento de jogos neste sábado';
  end if;

  return new;
end;
$$;

create trigger trg_clube_evento_duplicado
  before insert or update of clube_id on evento_jogos_clubes
  for each row execute function fn_validar_clube_sem_evento_no_sabado();

-- 3. RPC atualizada: sem limite de um evento por sábado; valida que nenhum dos
-- clubes selecionados já participou de um evento de jogos naquele sábado.
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

  if not (fn_role() in ('lider_jogos', 'diretor_geral')) then
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

grant execute on function fn_criar_evento_jogos(uuid, text, uuid[], text[], uuid) to authenticated;