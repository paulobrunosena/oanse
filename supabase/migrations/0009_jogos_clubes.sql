-- ============================================================================
-- OANSE - Jogos marcados por 1..N clubes
--
-- Muda o domínio do módulo de jogos: em vez da categoria fixa 'faiscas' /
-- 'flamas_tochas', um jogo passa a ser marcado explicitamente com os clubes
-- participantes (mínimo 1, máximo todos — os 4 clubes). Isso permite qualquer
-- combinação (ex.: Faíscas + Flamas jogam juntos), e a categoria vira obsoleta.
--
--  - nova tabela jogos_clubes (jogo x clube, unique por par)
--  - jogos.categoria removida (e o enum jogo_categoria)
--  - RPC fn_criar_jogo: cria jogo + clubes atomicamente, validando que o autor
--    é diretor_geral ou diretor de um dos clubes participantes
--  - RLS de jogos/times/integrantes/resultados passa a checar os clubes do jogo
--  - oansistas: diretor de clube lê crianças dos clubes que jogam junto com o
--    dele (necessário para montar times em jogos inter-clubes)
--  - fn_propagar_pontos_jogos: além dos pontos, grava cor_time (informacional,
--    não pontua) e zera pontos_jogos de integrantes sem resultado (fix no DELETE)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Remove políticas antigas que referenciam categoria / fn_clube_da_categoria
-- ----------------------------------------------------------------------------
drop policy if exists "jogos_write" on jogos;
drop policy if exists "jogo_times_write" on jogo_times;
drop policy if exists "jogo_integrantes_write" on jogo_time_integrantes;
drop policy if exists "jogo_resultados_write" on jogo_resultados;

-- ----------------------------------------------------------------------------
-- 2. Tabela de ligação jogo x clube
-- ----------------------------------------------------------------------------
create table jogos_clubes (
  id       uuid primary key default uuid_generate_v4(),
  jogo_id  uuid not null references jogos(id) on delete cascade,
  clube_id uuid not null references clubes(id),
  unique (jogo_id, clube_id)
);

create index idx_jogos_clubes_clube on jogos_clubes(clube_id);

-- ----------------------------------------------------------------------------
-- 3. Remove categoria (função antiga primeiro, depois a coluna e o enum)
-- ----------------------------------------------------------------------------
drop function if exists fn_clube_da_categoria(jogo_categoria);
alter table jogos drop column categoria;
drop type jogo_categoria;

-- ----------------------------------------------------------------------------
-- 4. RPC de criação atômica do jogo + clubes
-- ----------------------------------------------------------------------------
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

  if not (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube' and fn_clube_id() = any (p_clubes))
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

grant execute on function fn_criar_jogo(uuid, text, uuid[], uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 5. Helpers de autorização por clube do jogo
-- ----------------------------------------------------------------------------

-- Diretor de clube participante do jogo?
create or replace function fn_diretor_do_jogo(p_jogo_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from jogos_clubes jc
    where jc.jogo_id = p_jogo_id and jc.clube_id = fn_clube_id()
  );
$$;

-- Diretor de clube participante do jogo ao qual o time pertence?
create or replace function fn_diretor_do_jogo_do_time(p_time_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from jogo_times t
    join jogos_clubes jc on jc.jogo_id = t.jogo_id
    where t.id = p_time_id and jc.clube_id = fn_clube_id()
  );
$$;

-- ----------------------------------------------------------------------------
-- 6. RLS atualizada
-- ----------------------------------------------------------------------------

-- jogos: criação apenas via RPC fn_criar_jogo (sem policy de INSERT);
-- update/delete para diretor_geral ou diretor de clube participante.
create policy "jogos_update" on jogos
  for update to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(id));

create policy "jogos_delete" on jogos
  for delete to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(id));

create policy "jogo_times_write" on jogo_times
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(jogo_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(jogo_id));

create policy "jogo_integrantes_write" on jogo_time_integrantes
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_jogo_do_time(time_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_jogo_do_time(time_id));

create policy "jogo_resultados_write" on jogo_resultados
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(jogo_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(jogo_id));

-- jogos_clubes: leitura aberta; escrita só diretor_geral ou diretor participante
-- (a criação em si é atômica na RPC).
alter table jogos_clubes enable row level security;

create policy "jogos_clubes_select" on jogos_clubes
  for select to authenticated using (true);

create policy "jogos_clubes_write" on jogos_clubes
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(jogo_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_jogo(jogo_id));

-- oansistas: diretor de clube lê também crianças dos clubes que jogam junto com
-- o dele em algum jogo (necessário para montar times inter-clubes).
drop policy if exists "oansistas_select" on oansistas;
create policy "oansistas_select" on oansistas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube(clube_id)
    or (fn_role() = 'lider' and fn_lider_da_turma(turma_id))
    or (fn_role() = 'lider' and fn_substituto_da_turma(turma_id))
    or (fn_role() = 'diretor_clube' and exists (
          select 1 from jogos j
          join jogos_clubes jc  on jc.jogo_id = j.id and jc.clube_id = oansistas.clube_id
          join jogos_clubes jc2 on jc2.jogo_id = j.id and jc2.clube_id = fn_clube_id()
        ))
  );

-- ----------------------------------------------------------------------------
-- 7. Propagação de pontos (soma de todos os jogos do encontro) + cor_time
-- ----------------------------------------------------------------------------
drop trigger if exists trg_propagar_pontos_jogos on jogo_resultados;

create or replace function fn_propagar_pontos_jogos()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_encontro uuid;
  v_jogo_id  uuid;
begin
  if TG_OP = 'DELETE' then
    v_jogo_id := old.jogo_id;
  else
    v_jogo_id := new.jogo_id;
  end if;

  select encontro_id into v_encontro from jogos where id = v_jogo_id;

  -- Soma os pontos de TODOS os jogos do encontro para cada integrante.
  -- Integrantes sem resultado (ex.: resultado apagado) ficam com 0.
  update folhas_semanais f
     set pontos_jogos = coalesce(sub.pontos, 0)
    from (
      select distinct i.oansista_id
        from jogo_time_integrantes i
        join jogo_times t on t.id = i.time_id
        join jogos j on j.id = t.jogo_id and j.encontro_id = v_encontro
    ) participante
    left join (
      select i.oansista_id, sum(r.pontos) as pontos
        from jogo_resultados r
        join jogo_times t on t.id = r.time_id
        join jogos j on j.id = r.jogo_id and j.encontro_id = v_encontro
        join jogo_time_integrantes i on i.time_id = t.id
       group by i.oansista_id
    ) sub on sub.oansista_id = participante.oansista_id
   where f.oansista_id = participante.oansista_id
     and f.encontro_id = v_encontro;

  -- Cor do time deste jogo nos integrantes (informacional; não pontua).
  update folhas_semanais f
     set cor_time = t.cor
    from jogo_time_integrantes i
    join jogo_times t on t.id = i.time_id
   where t.jogo_id = v_jogo_id
     and f.oansista_id = i.oansista_id
     and f.encontro_id = v_encontro;

  return null;
end;
$$;

create trigger trg_propagar_pontos_jogos
  after insert or update or delete
  on jogo_resultados
  for each row execute function fn_propagar_pontos_jogos();