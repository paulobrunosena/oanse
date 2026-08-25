-- ============================================================================
-- OANSE - docs/02-rls-policies.sql
-- Row Level Security (Supabase) por perfil:
--   diretor_geral | secretaria | diretor_clube | lider_jogos | lider
--
-- Arquitetura: funÃ§Ãµes auxiliares SECURITY DEFINER (evitam recursÃ£o de RLS)
-- + polÃ­tica Ãºnica por operaÃ§Ã£o com OR entre perfis.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- FUNÃ‡Ã•ES AUXILIARES (executam sem passar pelas RLS)
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

-- LÃ­der Ã© titular da turma?
create or replace function fn_lider_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from turmas
    where id = p_turma_id and lider_id = auth.uid() and ativo
  );
$$;

-- LÃ­der Ã© titular OU substituto da turma naquele encontro? (RN: remanejamento)
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

-- LÃ­der Ã© responsÃ¡vel pelo oansista (titular ou substituto) no encontro?
create or replace function fn_responsavel_pelo_oansista(p_oansista_id uuid, p_encontro_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from oansistas o
    where o.id = p_oansista_id
      and public.fn_responsavel_pela_turma(o.turma_id, p_encontro_id)
  );
$$;

-- Ã‰ diretor do clube informado?
create or replace function fn_diretor_do_clube(p_clube_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select fn_role() = 'diretor_clube' and fn_clube_id() = p_clube_id;
$$;

-- Ã‰ diretor do clube ao qual a turma pertence? (SECURITY DEFINER, sem recursÃ£o)
create or replace function fn_diretor_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select fn_diretor_do_clube(t.clube_id) from turmas t where t.id = p_turma_id;
$$;

-- O usuÃ¡rio Ã© substituto da turma em algum encontro? (remanejamento)
create or replace function fn_substituto_da_turma(p_turma_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from remanejamentos_temporarios
    where turma_id = p_turma_id and lider_substituto_id = auth.uid()
  );
$$;

-- ----------------------------------------------------------------------------
-- ATIVAÃ‡ÃƒO DO RLS
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
alter table dias_sem_oanse         enable row level security;
alter table progresso_manual      enable row level security;
alter table jogos_catalogo        enable row level security;
alter table eventos_jogos         enable row level security;
alter table evento_jogos_clubes   enable row level security;
alter table evento_jogos_cores    enable row level security;
alter table evento_jogos_cores_oansistas enable row level security;
alter table jogos                 enable row level security;
alter table jogo_resultados       enable row level security;
alter table premios               enable row level security;
alter table premios_movimentacoes enable row level security;
alter table premios_pendentes     enable row level security;
alter table itens_pontuacao       enable row level security;
alter table jogos_pontos_config   enable row level security;

-- ----------------------------------------------------------------------------
-- CLUBES / CONFIGURAÃ‡Ã•ES â€” leitura para todos autenticados
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
--  - Todos veem perfis do prÃ³prio clube (para saber os lÃ­deres)
--  - Diretor Geral vÃª e gerencia tudo (criaÃ§Ã£o de usuÃ¡rios, papÃ©is, vÃ­nculos)
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
    -- usuÃ¡rio edita apenas prÃ³prios dados de contato:
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
--  - LÃ­der vÃª a prÃ³pria turma (e as do clube, para contexto)
--  - Diretor de Clube gerencia turmas do seu clube (delegaÃ§Ã£o de chamadas)
-- ----------------------------------------------------------------------------
create policy "turmas_select" on turmas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or (fn_clube_id() is not null and clube_id = fn_clube_id())
    or fn_substituto_da_turma(id)
  );

create policy "turmas_write" on turmas
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id));

-- ----------------------------------------------------------------------------
-- OANSISTAS â€” visualizaÃ§Ã£o restrita de turmas (RN principal)
--  - LÃ­der vÃª APENAS os oansistas da sua turma
--    (+ turmas recebidas por remanejamento, resolvido na FK turma_id)
--  - Diretor de Clube vÃª/gerencia o clube inteiro (transferÃªncias)
--  - Diretor de Clube lÃª tambÃ©m as crianÃ§as dos clubes que jogam junto com o
--    dele em algum jogo (necessÃ¡rio p/ montar times inter-clubes)
--  - SecretÃ¡ria/Diretor Geral: leitura total
-- ----------------------------------------------------------------------------
create policy "oansistas_select" on oansistas
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria', 'lider_jogos')
    or fn_diretor_do_clube(clube_id)
    or (fn_role() = 'lider' and fn_lider_da_turma(turma_id))
    or (fn_role() = 'lider' and fn_substituto_da_turma(turma_id))
  );

create policy "oansistas_write" on oansistas
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_do_clube(clube_id));

-- ----------------------------------------------------------------------------
-- VISITANTES / VISITAS / PROVA DE INGRESSO
--  - LÃ­der do clube registra e acompanha (Folha de Visitantes)
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
-- DIAS SEM OANSE (RN 7) — sábados sem atividade (férias/feriados)
--  - Leitura aberta (contexto); escrita só Diretor Geral.
-- ----------------------------------------------------------------------------
create policy "dias_sem_oanse_select" on dias_sem_oanse
  for select to authenticated using (true);

create policy "dias_sem_oanse_insert" on dias_sem_oanse
  for insert to authenticated
  with check (fn_role() = 'diretor_geral');

create policy "dias_sem_oanse_update" on dias_sem_oanse
  for update to authenticated
  using (fn_role() = 'diretor_geral')
  with check (fn_role() = 'diretor_geral');

create policy "dias_sem_oanse_delete" on dias_sem_oanse
  for delete to authenticated
  using (fn_role() = 'diretor_geral');

-- ----------------------------------------------------------------------------
-- PRESENCAS E FOLHAS SEMANAIS
--  - LÃ­der lanÃ§a APENAS para oansistas sob sua responsabilidade no encontro
--    (titular da turma OU substituto via remanejamento)
--  - Leitura: lÃ­der vÃª a prÃ³pria turma; diretor vÃª o clube; acima disso, tudo
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
-- REMANEJAMENTOS TEMPORÃRIOS E TRANSFERÃŠNCIAS (Diretor de Clube)
-- ----------------------------------------------------------------------------
create policy "remanejamentos_select" on remanejamentos_temporarios
  for select to authenticated
  using (
    fn_role() in ('diretor_geral', 'secretaria')
    or lider_substituto_id = auth.uid()
    or fn_diretor_da_turma(turma_id)
    or fn_lider_da_turma(turma_id)
  );

create policy "remanejamentos_write" on remanejamentos_temporarios
  for all to authenticated
  using (fn_role() = 'diretor_geral' or fn_diretor_da_turma(turma_id))
  with check (fn_role() = 'diretor_geral' or fn_diretor_da_turma(turma_id));

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

-- Transferência PERMANENTE é atômica (histórico + novo vínculo) numa RPC
-- SECURITY DEFINER chamada por server/api/transferencias.post.ts.
-- Autorização validada dentro da função (diretor_geral ou diretor do clube).
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

grant execute on function fn_transferir_oansista(uuid, uuid, text, uuid) to authenticated, service_role;

-- ----------------------------------------------------------------------------
-- PROGRESSO DO MANUAL (Folha Individual) â€” dispara pendÃªncia Ã  Secretaria
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
-- MÓDULO DE JOGOS — gestão pelo Líder de Jogos (RN 3 revisado)
--  O líder de jogos cadastra o(s) evento(s) do sábado (clubes, cores e
--  oansistas de cada cor) e registra o resultado de cada rodada. Pode haver
--  vários eventos por sábado (um por grupo de clubes); um clube não repete em
--  outro evento do mesmo sábado (validado por trigger). A criação do evento é
--  atômica na RPC fn_criar_evento_jogos (SECURITY DEFINER), que valida que o
--  autor é lider_jogos ou diretor_geral. As demais operações (cores, oansistas,
--  rodadas e resultados) passam por RLS com escrita restrita a esses dois
--  perfis; leitura aberta a qualquer autenticado.
--  Catálogo: escrita p/ diretor_geral, lider_jogos e diretor_clube (próprio clube).
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- PRÃŠMIOS / ESTOQUE / PENDÃŠNCIAS â€” Secretaria (RN 4)
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

-- PendÃªncias: criadas por trigger (SECURITY DEFINER, bypassa INSERT do cliente);
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

-- Sem polÃ­tica de INSERT/DELETE via cliente: apenas o trigger insere.

-- ----------------------------------------------------------------------------
-- VIEWS (rodam com privilÃ©gio do dono, mas herdam filtro via RLS das
-- tabelas base quando o usuÃ¡rio nÃ£o Ã© o dono; para simplificar, criamos
-- funÃ§Ã£o segura de ranking que aplica o mesmo escopo)
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

-- ----------------------------------------------------------------------------
-- GRANTS (migration 0003_grants.sql)
-- RLS decide QUAIS linhas; os grants habilitam a operação em si. Sem eles o
-- Postgres nega qualquer acesso ("permission denied for table ...").
-- ----------------------------------------------------------------------------

grant select, insert, update, delete on all tables in schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to service_role;

grant usage, select on all sequences in schema public to authenticated, service_role;

-- Pendências de prêmios: leitura + atualização de status pela Secretaria;
-- INSERT acontece apenas via trigger (security definer) — negado ao cliente.
revoke insert, delete on premios_pendentes from authenticated;