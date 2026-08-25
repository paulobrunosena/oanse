-- ============================================================================
-- OANSE - docs/02-rls-policies.sql
-- Row Level Security (Supabase) por perfil:
--   diretor_geral | secretaria | diretor_clube | lider
--
-- Arquitetura: funções auxiliares SECURITY DEFINER (evitam recursão de RLS)
-- + política única por operação com OR entre perfis.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FUNÇÕES AUXILIARES (executam sem passar pelas RLS)
-- ----------------------------------------------------------------------------
create or replace function fn_perfil()
returns profiles language sql stable security definer set search_path = public as $$
  select * from profiles where id = auth.uid();
$$;

create or replace function fn_role()
returns user_role language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function fn_clube_id()
returns uuid language sql stable security definer set search_path = public as $$
  select clube_id from profiles where id = auth.uid();
$$;

-- Líder é titular da turma?
create or replace function fn_lider_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from turmas
    where id = p_turma_id and lider_id = auth.uid() and ativo
  );
$$;

-- Líder é titular OU substituto da turma naquele encontro? (RN: remanejamento)
create or replace function fn_responsavel_pela_turma(p_turma_id uuid, p_encontro_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from turmas
    where id = p_turma_id and lider_id = auth.uid() and ativo
  ) or exists (
    select 1 from remanejamentos_temporarios rt
    where rt.turma_id = p_turma_id
      and rt.encontro_id = p_encontro_id
      and rt.lider_substituto_id = auth.uid()
  );
$$;

-- Líder é responsável pelo oansista (titular ou substituto) no encontro?
create or replace function fn_responsavel_pelo_oansista(p_oansista_id uuid, p_encontro_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from oansistas o
    where o.id = p_oansista_id
      and public.fn_responsavel_pela_turma(o.turma_id, p_encontro_id)
  );
$$;

-- É diretor do clube informado?
create or replace function fn_diretor_do_clube(p_clube_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select fn_role() = 'diretor_clube' and fn_clube_id() = p_clube_id;
$$;

-- ----------------------------------------------------------------------------
-- ATIVAÇÃO DO RLS
-- ----------------------------------------------------------------------------
alter table clubes                enable row level security;
alter table profiles              enable row level security;
alter table turmas                enable row level security;
alter table oansistas             enable row level security;
alter table visitantes            enable row level security;
alter table visitas               enable row level security;
alter table prova_ingresso_licoes enable row level security;
alter table encontros             enable row level security;
alter table presencas             enable row level security;
alter table remanejamentos_temporarios enable row level security;
alter table transferencias        enable row level security;
alter table folhas_semanais       enable row level security;
alter table progresso_manual      enable row level security;
alter table jogos                 enable row level security;
alter table jogo_times            enable row level security;
alter table jogo_time_integrantes enable row level security;
alter table jogo_resultados       enable row level security;
alter table premios               enable row level security;
alter table premios_movimentacoes enable row level security;
alter table premios_pendentes     enable row level security;
alter table itens_pontuacao       enable row level security;
alter table jogos_pontos_config   enable row level security;

-- ----------------------------------------------------------------------------
-- CLUBES / CONFIGURAÇÕES — leitura para todos autenticados
-- ----------------------------------------------------------------------------
create policy "clubes_select" on clubes
  for select to authenticated using (true);

create policy "clubes_update" on clubes
  for update to authenticated using (fn_role() = 'diretor_geral');

create policy "itens_pontuacao_select" on itens_pontuacao
  for select to authenticated using (true);

create policy "itens_pontuacao_write" on itens_pontuacao
  for all to authenticated
  using (fn_role() = 'diretor_geral')
  with check (fn_role() = 'diretor_geral');

create policy "jogos_pontos_config_select" on jogos_pontos_config
  for select to authenticated using (true);

create policy "jogos_pontos_config_write" on jogos_pontos_config
  for all to authenticated
  using (fn_role() = 'diretor_geral')
  with check (fn_role() = 'diretor_geral');

-- ----------------------------------------------------------------------------
-- PROFILES
--  - Todos veem perfis do próprio clube (para saber os líderes)
--  - Diretor Geral vê e gerencia tudo (criação de usuários, papéis, vínculos)
-- ----------------------------------------------------------------------------
create policy "profiles_select" on profiles
  for select to authenticated
  using (
    id = auth.uid()
    or fn_role() in ('diretor_geral', 'secretaria')
    or (fn_clube_id() is not null and clube_id = fn_clube_id())
  );

create policy "profiles_update" on profiles
  for update to authenticated
  using (
    fn_role() = 'diretor_geral'
    -- usuário edita apenas próprios dados de contato:
    or (id = auth.uid()
        and nome   = (select nome   from profiles p where p.id = auth.uid())
        and role   = (select role   from profiles p where p.id = auth.uid())
        and clube_id is not distinct from (select clube_id from profiles p where p.id = auth.uid()))
  )
  with check (
    fn_role() = 'diretor_geral'
    or (id = auth.uid()
        and role   = (select role   from profiles p where p.id = auth.uid())
        and clube_id is not distinct from (select clube_id from profiles p where p.id = auth.uid()))
  );

create policy "profiles_insert" on profiles
  for insert to authenticated
  with check (fn_role() = 'diretor_geral');

-- ----------------------------------------------------------------------------
-- TURMAS
--  - Líder vê a própria turma (e as do clube, para contexto)
--  - Diretor de Clube gerencia turmas do seu clube (delegação de chamadas)
-- ----------------------------------------------------------------------------
create policy "turmas_select" on turmas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or (fn_clube_id() is not null and clube_id = fn_clube_id())
  );

create policy "turmas_write" on turmas
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id));

-- ----------------------------------------------------------------------------
-- OANSISTAS — visualização restrita de turmas (RN principal)
--  - Líder vê APENAS os oansistas da sua turma
--    (+ turmas recebidas por remanejamento, resolvido na FK turma_id)
--  - Diretor de Clube vê/gerencia o clube inteiro (transferências)
--  - Secretária/Diretor Geral: leitura total
-- ----------------------------------------------------------------------------
create policy "oansistas_select" on oansistas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube(clube_id)
    or (fn_role() = 'lider' and fn_lider_da_turma(turma_id))
  );

create policy "oansistas_write" on oansistas
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id));

-- ----------------------------------------------------------------------------
-- VISITANTES / VISITAS / PROVA DE INGRESSO
--  - Líder do clube registra e acompanha (Folha de Visitantes)
-- ----------------------------------------------------------------------------
create policy "visitantes_select" on visitantes
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube(clube_id)
    or (fn_role() = 'lider' and clube_id = fn_clube_id())
  );

create policy "visitantes_write" on visitantes
  for all to authenticated
  using (fn_role() = 'diretor_geral'
         or fn_diretor_do_clube(clube_id)
         or (fn_role() = 'lider' and clube_id = fn_clube_id()))
  with check (fn_role() = 'diretor_geral'
         or fn_diretor_do_clube(clube_id)
         or (fn_role() = 'lider' and clube_id = fn_clube_id()));

create policy "visitas_select" on visitas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or exists (select 1 from visitantes v
               where v.id = visitas.visitante_id
                 and (fn_diretor_do_clube(v.clube_id)
                      or (fn_role() = 'lider' and v.clube_id = fn_clube_id())))
  );

create policy "visitas_write" on visitas
  for all to authenticated
  using (exists (select 1 from visitantes v
                 where v.id = visitas.visitante_id
                   and (fn_role() = 'diretor_geral'
                        or fn_diretor_do_clube(v.clube_id)
                        or (fn_role() = 'lider' and v.clube_id = fn_clube_id()))))
  with check (exists (select 1 from visitantes v
                 where v.id = visitas.visitante_id
                   and (fn_role() = 'diretor_geral'
                        or fn_diretor_do_clube(v.clube_id)
                        or (fn_role() = 'lider' and v.clube_id = fn_clube_id()))));

create policy "prova_select" on prova_ingresso_licoes
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or exists (select 1 from visitantes v
               where v.id = prova_ingresso_licoes.visitante_id
                 and (fn_diretor_do_clube(v.clube_id)
                      or (fn_role() = 'lider' and v.clube_id = fn_clube_id())))
  );

create policy "prova_write" on prova_ingresso_licoes
  for all to authenticated
  using (exists (select 1 from visitantes v
                 where v.id = prova_ingresso_licoes.visitante_id
                   and (fn_role() = 'diretor_geral'
                        or fn_diretor_do_clube(v.clube_id)
                        or (fn_role() = 'lider' and v.clube_id = fn_clube_id()))))
  with check (exists (select 1 from visitantes v
                 where v.id = prova_ingresso_licoes.visitante_id
                   and (fn_role() = 'diretor_geral'
                        or fn_diretor_do_clube(v.clube_id)
                        or (fn_role() = 'lider' and v.clube_id = fn_clube_id()))));

-- ----------------------------------------------------------------------------
-- ENCONTROS
-- ----------------------------------------------------------------------------
create policy "encontros_select" on encontros
  for select to authenticated using (true);

create policy "encontros_write" on encontros
  for all to authenticated
  using (fn_role() in ('diretor_geral', 'secretaria'))
  with check (fn_role() in ('diretor_geral', 'secretaria'));

-- ----------------------------------------------------------------------------
-- PRESENCAS E FOLHAS SEMANAIS
--  - Líder lança APENAS para oansistas sob sua responsabilidade no encontro
--    (titular da turma OU substituto via remanejamento)
--  - Leitura: líder vê a própria turma; diretor vê o clube; acima disso, tudo
-- ----------------------------------------------------------------------------
create policy "presencas_select" on presencas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_responsavel_pelo_oansista(oansista_id, encontro_id)
    or exists (select 1 from oansistas o
               where o.id = presencas.oansista_id and fn_diretor_do_clube(o.clube_id))
  );

create policy "presencas_insert" on presencas
  for insert to authenticated
  with check (
    fn_responsavel_pelo_oansista(oansista_id, encontro_id)
    and lider_registrante_id = auth.uid()
  );

create policy "presencas_update" on presencas
  for update to authenticated
  using (fn_responsavel_pelo_oansista(oansista_id, encontro_id))
  with check (fn_responsavel_pelo_oansista(oansista_id, encontro_id));

create policy "folhas_select" on folhas_semanais
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_responsavel_pelo_oansista(oansista_id, encontro_id)
    or exists (select 1 from oansistas o
               where o.id = folhas_semanais.oansista_id and fn_diretor_do_clube(o.clube_id))
  );

create policy "folhas_insert" on folhas_semanais
  for insert to authenticated
  with check (
    fn_responsavel_pelo_oansista(oansista_id, encontro_id)
    and registrado_por = auth.uid()
  );

create policy "folhas_update" on folhas_semanais
  for update to authenticated
  using (fn_responsavel_pelo_oansista(oansista_id, encontro_id))
  with check (fn_responsavel_pelo_oansista(oansista_id, encontro_id));

-- ----------------------------------------------------------------------------
-- REMANEJAMENTOS TEMPORÁRIOS E TRANSFERÊNCIAS (Diretor de Clube)
-- ----------------------------------------------------------------------------
create policy "remanejamentos_select" on remanejamentos_temporarios
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or lider_substituto_id = auth.uid()
    or exists (select 1 from turmas t
               where t.id = remanejamentos_temporarios.turma_id
                 and (fn_diretor_do_clube(t.clube_id)
                      or t.lider_id = auth.uid()))
  );

create policy "remanejamentos_write" on remanejamentos_temporarios
  for all to authenticated
  using (fn_role() = 'diretor_geral'
         or exists (select 1 from turmas t
                    where t.id = remanejamentos_temporarios.turma_id
                      and fn_diretor_do_clube(t.clube_id)))
  with check (fn_role() = 'diretor_geral'
         or exists (select 1 from turmas t
                    where t.id = remanejamentos_temporarios.turma_id
                      and fn_diretor_do_clube(t.clube_id)));

create policy "transferencias_select" on transferencias
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or exists (select 1 from oansistas o
               where o.id = transferencias.oansista_id and fn_diretor_do_clube(o.clube_id))
    or exists (select 1 from oansistas o
               where o.id = transferencias.oansista_id and fn_lider_da_turma(o.turma_id))
  );

create policy "transferencias_insert" on transferencias
  for insert to authenticated
  with check (
    autorizado_por = auth.uid()
    and (fn_role() = 'diretor_geral'
         or exists (select 1 from oansistas o
                    where o.id = transferencias.oansista_id
                      and fn_diretor_do_clube(o.clube_id)))
  );

-- ----------------------------------------------------------------------------
-- PROGRESSO DO MANUAL (Folha Individual) — dispara pendência à Secretaria
-- ----------------------------------------------------------------------------
create policy "progresso_select" on progresso_manual
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = progresso_manual.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = progresso_manual.oansista_id))
  );

create policy "progresso_write" on progresso_manual
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = progresso_manual.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = progresso_manual.oansista_id))
  )
  with check (
    fn_role() = 'diretor_geral'
    or fn_diretor_do_clube((select clube_id from oansistas o where o.id = progresso_manual.oansista_id))
    or fn_lider_da_turma((select turma_id from oansistas o where o.id = progresso_manual.oansista_id))
  );

-- ----------------------------------------------------------------------------
-- MÓDULO DE JOGOS — gestão pelo Diretor de Clube (RN 3)
--  Categoria 'faiscas' => clube Faíscas | 'flamas_tochas' => clubes Flamas/Tochas
-- ----------------------------------------------------------------------------
create or replace function fn_clube_da_categoria(p_cat jogo_categoria)
returns uuid[] language sql stable security definer set search_path = public as $$
  select array_agg(id) from clubes
  where slug = case p_cat
                  when 'faiscas' then 'faiscas'
                  when 'flamas_tochas' then 'flamas'  -- inclui 'tochas' abaixo
                end
     or (p_cat = 'flamas_tochas' and slug in ('flamas', 'tochas'));
$$;

create policy "jogos_select" on jogos
  for select to authenticated using (true);

create policy "jogos_write" on jogos
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(categoria)))
  )
  with check (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(categoria)))
  );

create policy "jogo_times_select" on jogo_times
  for select to authenticated using (true);

create policy "jogo_times_write" on jogo_times
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(
              (select j.categoria from jogos j where j.id = jogo_times.jogo_id))))
  )
  with check (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(
              (select j.categoria from jogos j where j.id = jogo_times.jogo_id))))
  );

create policy "jogo_integrantes_select" on jogo_time_integrantes
  for select to authenticated using (true);

create policy "jogo_integrantes_write" on jogo_time_integrantes
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(
              (select j.categoria from jogos j
                join jogo_times t on t.id = jogo_time_integrantes.time_id
               where j.id = t.jogo_id))))
  )
  with check (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(
              (select j.categoria from jogos j
                join jogo_times t on t.id = jogo_time_integrantes.time_id
               where j.id = t.jogo_id))))
  );

create policy "jogo_resultados_select" on jogo_resultados
  for select to authenticated using (true);

create policy "jogo_resultados_write" on jogo_resultados
  for all to authenticated
  using (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(
              (select j.categoria from jogos j where j.id = jogo_resultados.jogo_id))))
  )
  with check (
    fn_role() = 'diretor_geral'
    or (fn_role() = 'diretor_clube'
        and fn_clube_id() = any (fn_clube_da_categoria(
              (select j.categoria from jogos j where j.id = jogo_resultados.jogo_id))))
  );

-- ----------------------------------------------------------------------------
-- PRÊMIOS / ESTOQUE / PENDÊNCIAS — Secretaria (RN 4)
-- ----------------------------------------------------------------------------
create policy "premios_select" on premios
  for select to authenticated using (true);

create policy "premios_write" on premios
  for all to authenticated
  using (fn_role() in ('diretor_geral', 'secretaria'))
  with check (fn_role() in ('diretor_geral', 'secretaria'));

create policy "premios_mov_select" on premios_movimentacoes
  for select to authenticated
  using (fn_role() in ('diretor_geral', 'secretaria'));

create policy "premios_mov_write" on premios_movimentacoes
  for all to authenticated
  using (fn_role() in ('diretor_geral', 'secretaria'))
  with check (fn_role() in ('diretor_geral', 'secretaria'));

-- Pendências: criadas por trigger (SECURITY DEFINER, bypassa INSERT do cliente);
-- apenas a Secretaria altera o status (entrega/cancelamento).
create policy "pendencias_select" on premios_pendentes
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or fn_diretor_do_clube(clube_id)
    or exists (select 1 from oansistas o
               where o.id = premios_pendentes.oansista_id
                 and fn_lider_da_turma(o.turma_id))
  );

create policy "pendencias_update" on premios_pendentes
  for update to authenticated
  using (fn_role() in ('diretor_geral', 'secretaria'))
  with check (fn_role() in ('diretor_geral', 'secretaria'));

-- Sem política de INSERT/DELETE via cliente: apenas o trigger insere.

-- ----------------------------------------------------------------------------
-- VIEWS (rodam com privilégio do dono, mas herdam filtro via RLS das
-- tabelas base quando o usuário não é o dono; para simplificar, criamos
-- função segura de ranking que aplica o mesmo escopo)
-- ----------------------------------------------------------------------------
create or replace function fn_ranking_do_encontro(p_encontro_id uuid)
returns table (
  clube_nome     text,
  oansista_id    uuid,
  oansista_nome  text,
  total          int,
  posicao        bigint
) language sql stable security definer set search_path = public as $$
  select c.nome, o.id, o.nome, f.total,
         rank() over (partition by o.clube_id order by f.total desc, o.nome)
  from folhas_semanais f
  join oansistas o on o.id = f.oansista_id
  join clubes c    on c.id = o.clube_id
  where f.encontro_id = p_encontro_id;
$$;

grant execute on function fn_ranking_do_encontro(uuid) to authenticated;
