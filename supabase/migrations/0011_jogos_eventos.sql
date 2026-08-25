-- ============================================================================
-- OANSE - Eventos de jogos por sábado + catálogo de jogos + perfil líder de jogos
--
-- Redesenha o módulo de jogos para o fluxo "cadastre o evento uma vez, depois
-- só registre o resultado de cada rodada":
--
--  - novo perfil user_role 'lider_jogos' (responsável por marcar os pontos)
--  - jogos_catalogo: nomes de jogos por clube (CRUD) — alimenta o combo do
--    registro de rodada (nomes repetidos entre clubes não aparecem duplicados)
--  - eventos_jogos: sessão de jogos do sábado (uma por encontro)
--  - evento_jogos_clubes: clubes participantes (definem o combo de jogos)
--  - evento_jogos_cores: cores participantes (verde/vermelho/amarelo/azul)
--  - evento_jogos_cores_oansistas: oansistas de cada cor
--  - jogos: rodada de um jogo dentro do evento (nome vem do catálogo)
--  - jogo_resultados: colocação/desclassificado de cada cor na rodada
--  - fn_ranking_cores_do_evento: ranking das cores do sábado (anúncio final)
--
-- Tabelas antigas (jogos_clubes, jogo_times, jogo_time_integrantes) e o RPC
-- fn_criar_jogo são substituídos pelo novo modelo.
-- ============================================================================

-- ============================================================================
-- 1. Catálogo de jogos por clube
-- ----------------------------------------------------------------------------
create table if not exists jogos_catalogo (
  id         uuid primary key default uuid_generate_v4(),
  clube_id   uuid not null references clubes(id) on delete cascade,
  nome       text not null,
  created_at timestamptz not null default now(),
  unique (clube_id, nome)
);

create index if not exists idx_jogos_catalogo_clube on jogos_catalogo(clube_id);

-- ----------------------------------------------------------------------------
-- 3. Evento de jogos do sábado + cores + oansistas por cor
-- ----------------------------------------------------------------------------
create table if not exists eventos_jogos (
  id          uuid primary key default uuid_generate_v4(),
  encontro_id uuid not null references encontros(id) on delete cascade,
  nome        text not null,
  status      text not null default 'em_andamento'
              check (status in ('em_andamento', 'finalizado')),
  criado_por  uuid references profiles(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (encontro_id)
);

create table if not exists evento_jogos_clubes (
  id         uuid primary key default uuid_generate_v4(),
  evento_id  uuid not null references eventos_jogos(id) on delete cascade,
  clube_id   uuid not null references clubes(id),
  unique (evento_id, clube_id)
);

create table if not exists evento_jogos_cores (
  id         uuid primary key default uuid_generate_v4(),
  evento_id  uuid not null references eventos_jogos(id) on delete cascade,
  cor        text not null check (cor in ('verde', 'vermelho', 'amarelo', 'azul')),
  unique (evento_id, cor)
);

create table if not exists evento_jogos_cores_oansistas (
  id          uuid primary key default uuid_generate_v4(),
  cor_id      uuid not null references evento_jogos_cores(id) on delete cascade,
  oansista_id uuid not null references oansistas(id) on delete cascade,
  unique (cor_id, oansista_id)
);

create index if not exists idx_evento_jogos_clubes_evento on evento_jogos_clubes(evento_id);
create index if not exists idx_evento_jogos_cores_evento on evento_jogos_cores(evento_id);
create index if not exists idx_evento_cores_oansistas_cor on evento_jogos_cores_oansistas(cor_id);

create trigger trg_eventos_jogos_updated
  before update on eventos_jogos for each row execute function fn_set_updated_at();

-- ----------------------------------------------------------------------------
-- 4. Rodadas (jogos) e resultados — novo domínio
-- ----------------------------------------------------------------------------
drop trigger if exists trg_propagar_pontos_jogos on jogo_resultados;
drop trigger if exists trg_resultado_pontos on jogo_resultados;
drop table if exists jogo_resultados, jogo_time_integrantes, jogo_times, jogos_clubes, jogos cascade;

drop function if exists fn_criar_jogo(uuid, text, uuid[], uuid);
drop function if exists fn_diretor_do_jogo(uuid);
drop function if exists fn_diretor_do_jogo_do_time(uuid);

create table jogos (
  id         uuid primary key default uuid_generate_v4(),
  evento_id  uuid not null references eventos_jogos(id) on delete cascade,
  nome       text not null,
  criado_por uuid references profiles(id),
  created_at timestamptz not null default now()
);

create index idx_jogos_evento on jogos(evento_id);

create table jogo_resultados (
  id              uuid primary key default uuid_generate_v4(),
  jogo_id         uuid not null references jogos(id) on delete cascade,
  cor_id          uuid not null references evento_jogos_cores(id) on delete cascade,
  colocacao       smallint check (colocacao between 1 and 4),
  desclassificado boolean not null default false,
  pontos          int not null default 0,   -- derivado de jogos_pontos_config
  created_at      timestamptz not null default now(),
  unique (jogo_id, cor_id),
  check (desclassificado or colocacao is not null)
);

create index idx_jogo_resultados_jogo on jogo_resultados(jogo_id);

-- ----------------------------------------------------------------------------
-- 5. RPC: criação atômica do evento + clubes + cores (lider_jogos / diretor_geral)
-- ----------------------------------------------------------------------------
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

  if exists (select 1 from eventos_jogos where encontro_id = p_encontro_id) then
    raise exception 'Já existe um evento de jogos para este encontro';
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

-- ----------------------------------------------------------------------------
-- 6. Pontos do resultado (colocação) conforme jogos_pontos_config
-- ----------------------------------------------------------------------------
create or replace function fn_definir_pontos_resultado()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.desclassificado then
    new.pontos := 0;
    new.colocacao := null;
  else
    select pontos into new.pontos
    from jogos_pontos_config where colocacao = new.colocacao;
  end if;
  return new;
end $$;

create trigger trg_resultado_pontos
  before insert or update of colocacao, desclassificado
  on jogo_resultados
  for each row execute function fn_definir_pontos_resultado();

-- ----------------------------------------------------------------------------
-- 7. Propagação de pontos/cor para as folhas do encontro
-- ----------------------------------------------------------------------------
drop function if exists fn_propagar_pontos_jogos();

create or replace function fn_propagar_pontos_jogos()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_evento   uuid;
  v_encontro uuid;
begin
  if TG_OP = 'DELETE' then
    select evento_id into v_evento from jogos where id = old.jogo_id;
  else
    select evento_id into v_evento from jogos where id = new.jogo_id;
  end if;

  select encontro_id into v_encontro from eventos_jogos where id = v_evento;

  -- Soma os pontos de TODAS as rodadas do evento para cada oansista de cor.
  -- Oansistas de cor sem resultado (ex.: rodada apagada) ficam com 0.
  update folhas_semanais f
     set pontos_jogos = coalesce(sub.pontos, 0)
    from (
      select distinct i.oansista_id
        from evento_jogos_cores_oansistas i
        join evento_jogos_cores c on c.id = i.cor_id
        join eventos_jogos ev on ev.id = c.evento_id and ev.encontro_id = v_encontro
    ) participante
    left join (
      select i.oansista_id, sum(r.pontos) as pontos
        from jogo_resultados r
        join jogos j on j.id = r.jogo_id
        join eventos_jogos ev on ev.id = j.evento_id and ev.encontro_id = v_encontro
        join evento_jogos_cores c on c.id = r.cor_id
        join evento_jogos_cores_oansistas i on i.cor_id = c.id
       group by i.oansista_id
    ) sub on sub.oansista_id = participante.oansista_id
   where f.oansista_id = participante.oansista_id
     and f.encontro_id = v_encontro;

  -- Cor do evento nos oansistas participantes (informacional; não pontua).
  update folhas_semanais f
     set cor_time = c.cor
    from evento_jogos_cores_oansistas i
    join evento_jogos_cores c on c.id = i.cor_id
   where c.evento_id = v_evento
     and f.oansista_id = i.oansista_id
     and f.encontro_id = v_encontro;

  return null;
end;
$$;

create trigger trg_propagar_pontos_jogos
  after insert or update or delete
  on jogo_resultados
  for each row execute function fn_propagar_pontos_jogos();

-- ----------------------------------------------------------------------------
-- 8. Ranking das cores do evento (anúncio no final da programação)
-- ----------------------------------------------------------------------------
create or replace function fn_ranking_cores_do_evento(p_evento_id uuid)
returns table (cor text, pontos bigint, posicao bigint)
language sql stable security definer set search_path = public as $$
  select c.cor,
         coalesce(sum(r.pontos), 0) as pontos,
         rank() over (order by coalesce(sum(r.pontos), 0) desc, c.cor)
  from evento_jogos_cores c
  left join jogo_resultados r on r.cor_id = c.id
  where c.evento_id = p_evento_id
  group by c.id, c.cor
  order by 2 desc, c.cor;
$$;

grant execute on function fn_ranking_cores_do_evento(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 9. RLS
-- ----------------------------------------------------------------------------
-- Catálogo: leitura aberta; escrita p/ diretor_geral, lider_jogos e
-- diretor_clube (apenas do próprio clube).
alter table jogos_catalogo enable row level security;

create policy "jogos_catalogo_select" on jogos_catalogo
  for select to authenticated using (true);

create policy "jogos_catalogo_write" on jogos_catalogo
  for all to authenticated
  using (
    fn_role() in ('diretor_geral', 'lider_jogos')
    or (fn_role() = 'diretor_clube' and clube_id = fn_clube_id())
  )
  with check (
    fn_role() in ('diretor_geral', 'lider_jogos')
    or (fn_role() = 'diretor_clube' and clube_id = fn_clube_id())
  );

-- Evento + clubes + cores + oansistas: lider_jogos/diretor_geral gerem.
alter table eventos_jogos enable row level security;
alter table evento_jogos_clubes enable row level security;
alter table evento_jogos_cores enable row level security;
alter table evento_jogos_cores_oansistas enable row level security;

create policy "eventos_jogos_select" on eventos_jogos
  for select to authenticated using (true);

create policy "eventos_jogos_write" on eventos_jogos
  for all to authenticated
  using (fn_role() in ('lider_jogos', 'diretor_geral'))
  with check (fn_role() in ('lider_jogos', 'diretor_geral'));

create policy "evento_jogos_clubes_select" on evento_jogos_clubes
  for select to authenticated using (true);

create policy "evento_jogos_clubes_write" on evento_jogos_clubes
  for all to authenticated
  using (fn_role() in ('lider_jogos', 'diretor_geral'))
  with check (fn_role() in ('lider_jogos', 'diretor_geral'));

create policy "evento_jogos_cores_select" on evento_jogos_cores
  for select to authenticated using (true);

create policy "evento_jogos_cores_write" on evento_jogos_cores
  for all to authenticated
  using (fn_role() in ('lider_jogos', 'diretor_geral'))
  with check (fn_role() in ('lider_jogos', 'diretor_geral'));

create policy "evento_cores_oansistas_select" on evento_jogos_cores_oansistas
  for select to authenticated using (true);

create policy "evento_cores_oansistas_write" on evento_jogos_cores_oansistas
  for all to authenticated
  using (fn_role() in ('lider_jogos', 'diretor_geral'))
  with check (fn_role() in ('lider_jogos', 'diretor_geral'));

-- Rodadas e resultados: lider_jogos/diretor_geral gerem.
alter table jogos enable row level security;
alter table jogo_resultados enable row level security;

create policy "jogos_select" on jogos
  for select to authenticated using (true);

create policy "jogos_write" on jogos
  for all to authenticated
  using (fn_role() in ('lider_jogos', 'diretor_geral'))
  with check (fn_role() in ('lider_jogos', 'diretor_geral'));

create policy "jogo_resultados_select" on jogo_resultados
  for select to authenticated using (true);

create policy "jogo_resultados_write" on jogo_resultados
  for all to authenticated
  using (fn_role() in ('lider_jogos', 'diretor_geral'))
  with check (fn_role() in ('lider_jogos', 'diretor_geral'));

-- oansistas: líder de jogos lê o clube inteiro (monta as cores no evento).
drop policy if exists "oansistas_select" on oansistas;
create policy "oansistas_select" on oansistas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria', 'lider_jogos')
    or fn_diretor_do_clube(clube_id)
    or (fn_role() = 'lider' and fn_lider_da_turma(turma_id))
    or (fn_role() = 'lider' and fn_substituto_da_turma(turma_id))
  );

-- ----------------------------------------------------------------------------
-- 10. Grants (tabelas criadas/após a migration 0003)
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on jogos_catalogo, eventos_jogos,
      evento_jogos_clubes, evento_jogos_cores, evento_jogos_cores_oansistas,
      jogos, jogo_resultados to authenticated, service_role;

grant usage, select on all sequences in schema public to authenticated, service_role;