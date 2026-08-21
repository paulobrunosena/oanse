-- ============================================================================
-- OANSE - Sistema do Ministério Infantil
-- docs/01-schema.sql — Modelo de Dados (PostgreSQL / Supabase)
--
-- Execução (local):  npx supabase db reset   (aplica migrations + seed)
-- Este arquivo deve ser dividido em migrations:
--   supabase/migrations/0001_schema.sql      (tudo abaixo até o SEED)
--   supabase/migrations/0002_rls.sql         (docs/02-rls-policies.sql)
--   supabase/seed.sql                        (bloco SEED)
-- ============================================================================

create extension if not exists "uuid-ossp";

-- ----------------------------------------------------------------------------
-- ENUMS
-- ----------------------------------------------------------------------------
create type user_role as enum ('diretor_geral', 'secretaria', 'diretor_clube', 'lider');

create type status_oansista as enum ('ativo', 'inativo', 'transferido');

create type status_visitante as enum ('em_visitas', 'prova_ingresso', 'matriculado', 'desistente');

create type transferencia_tipo as enum ('temporaria', 'permanente');

create type premio_tipo as enum ('manual', 'botom', 'premio');

create type pendencia_status as enum ('pendente', 'entregue', 'cancelada');

create type jogo_categoria as enum ('faiscas', 'flamas_tochas');

-- ----------------------------------------------------------------------------
-- TABELAS DE APOIO / CONFIGURAÇÃO
-- ----------------------------------------------------------------------------

-- Clubes por faixa etária (seed fixo: 4 clubes)
create table clubes (
  id        uuid primary key default uuid_generate_v4(),
  nome      text not null unique,          -- 'Ursinhos', 'Faíscas', 'Flamas', 'Tochas'
  slug      text not null unique,
  idade_min int  not null,
  idade_max int  not null,
  cor       text,                          -- identidade visual (hex)
  ordem     int  not null,
  created_at timestamptz not null default now()
);

-- Catálogo de prêmios/materiais com controle de estoque (Secretaria)
create table premios (
  id          uuid primary key default uuid_generate_v4(),
  nome        text not null,
  tipo        premio_tipo not null,
  descricao   text,
  nivel       int,          -- para prêmios de conclusão de nível do manual
  secao       int,          -- para botons de conclusão de seção do manual
  estoque     int not null default 0 check (estoque >= 0),
  estoque_min int not null default 0,
  ativo       boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (tipo, nivel, secao)
);

create table premios_movimentacoes (
  id          uuid primary key default uuid_generate_v4(),
  premio_id   uuid not null references premios(id) on delete cascade,
  tipo        text not null check (tipo in ('entrada', 'saida')),
  quantidade  int  not null check (quantidade > 0),
  observacao  text,
  feito_por   uuid not null references auth.users(id),
  created_at  timestamptz not null default now()
);

-- Configuração de pontuação da Folha Semanal (editável pelo Diretor Geral)
create table itens_pontuacao (
  chave      text primary key,   -- 'presenca','uniforme','biblia','ebd','manual','conduta','secao_manual'
  descricao  text not null,
  pontos     int  not null default 0,
  ativo      boolean not null default true
);

-- Configuração de pontuação dos jogos
create table jogos_pontos_config (
  colocacao       smallint primary key check (colocacao between 1 and 4),
  pontos          int not null,
  desclassificado boolean not null default false
);

-- ----------------------------------------------------------------------------
-- USUÁRIOS E ESTRUTURA ORGANIZACIONAL
-- ----------------------------------------------------------------------------

-- Extensão de auth.users (1:1) — criada por trigger on_auth_user_created
create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  nome       text not null,
  telefone   text,
  role       user_role not null default 'lider',
  clube_id   uuid references clubes(id),  -- null p/ diretor_geral e secretaria
  ativo      boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Turma = grupo fixo de crianças sob responsabilidade de um líder
create table turmas (
  id         uuid primary key default uuid_generate_v4(),
  clube_id   uuid not null references clubes(id),
  lider_id   uuid not null references profiles(id),
  nome       text not null,                -- ex.: 'Turma 1 - Tio João'
  ativo      boolean not null default true,
  created_at timestamptz not null default now(),
  unique (lider_id)                        -- 1 líder => 1 turma ativa
);

-- ----------------------------------------------------------------------------
-- OANSISTAS (crianças matriculadas) E VISITANTES
-- ----------------------------------------------------------------------------

create table oansistas (
  id             uuid primary key default uuid_generate_v4(),
  nome           text not null,
  data_nascimento date not null,
  clube_id       uuid not null references clubes(id),
  turma_id       uuid references turmas(id),   -- líder fixo = turma.lider_id
  responsavel    text,
  contato        text,
  data_matricula date not null default current_date,
  status         status_oansista not null default 'ativo',
  observacoes    text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table visitantes (
  id             uuid primary key default uuid_generate_v4(),
  nome           text not null,
  data_nascimento date not null,
  clube_id       uuid not null references clubes(id),  -- clube pretendido
  indicado_por   uuid references oansistas(id),        -- quem convidou
  responsavel    text,
  contato        text,
  status         status_visitante not null default 'em_visitas',
  data_cadastro  date not null default current_date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Acompanhamento das 3 primeiras visitas
create table visitas (
  id           uuid primary key default uuid_generate_v4(),
  visitante_id uuid not null references visitantes(id) on delete cascade,
  numero       smallint not null check (numero between 1 and 3),
  data_visita  date not null default current_date,
  presente     boolean not null default true,
  observacao   text,
  unique (visitante_id, numero)
);

-- Lições da Prova de Ingresso antes da matrícula oficial
create table prova_ingresso_licoes (
  id           uuid primary key default uuid_generate_v4(),
  visitante_id uuid not null references visitantes(id) on delete cascade,
  licao        smallint not null check (licao between 1 and 10),
  concluida    boolean not null default false,
  data_conclusao date,
  registrado_por uuid references profiles(id),
  unique (visitante_id, licao)
);

-- ----------------------------------------------------------------------------
-- ENCONTROS SEMANAIS (sábados) E CHAMADA
-- ----------------------------------------------------------------------------

create table encontros (
  id         uuid primary key default uuid_generate_v4(),
  data       date not null unique,   -- sábado
  tema       text,
  ativo      boolean not null default true,
  created_at timestamptz not null default now()
);

-- Chamada: registra presença/falta e quem fez o lançamento
create table presencas (
  id                    uuid primary key default uuid_generate_v4(),
  encontro_id           uuid not null references encontros(id) on delete cascade,
  oansista_id           uuid not null references oansistas(id) on delete cascade,
  presente              boolean not null default true,
  lider_registrante_id  uuid not null references profiles(id), -- titular ou substituto
  observacao            text,
  created_at            timestamptz not null default now(),
  unique (encontro_id, oansista_id)
);

-- ----------------------------------------------------------------------------
-- REMANEJAMENTO TEMPORÁRIO E TRANSFERÊNCIA PERMANENTE
-- ----------------------------------------------------------------------------

-- Libera a turma de um líder ausente para outro líder NAQUELE encontro
create table remanejamentos_temporarios (
  id                  uuid primary key default uuid_generate_v4(),
  turma_id            uuid not null references turmas(id),
  encontro_id         uuid not null references encontros(id) on delete cascade,
  lider_titular_id    uuid not null references profiles(id),
  lider_substituto_id uuid not null references profiles(id),
  criado_por          uuid not null references profiles(id),
  created_at          timestamptz not null default now(),
  unique (turma_id, encontro_id),
  check (lider_titular_id <> lider_substituto_id)
);

-- Histórico de transferências permanentes de crianças entre líderes/turmas
create table transferencias (
  id              uuid primary key default uuid_generate_v4(),
  oansista_id     uuid not null references oansistas(id),
  tipo            transferencia_tipo not null,
  turma_origem_id uuid references turmas(id),
  turma_destino_id uuid references turmas(id),
  lider_origem_id uuid references profiles(id),
  lider_destino_id uuid references profiles(id),
  data            date not null default current_date,
  motivo          text,
  autorizado_por  uuid not null references profiles(id), -- diretor do clube
  created_at      timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- FOLHA SEMANAL (pontuação por encontro)
-- ----------------------------------------------------------------------------
-- pontos_jogos e total são calculados por triggers. Ausente => total = 0.

create table folhas_semanais (
  id                 uuid primary key default uuid_generate_v4(),
  encontro_id        uuid not null references encontros(id) on delete cascade,
  oansista_id        uuid not null references oansistas(id) on delete cascade,
  presenca_id        uuid not null references presencas(id) on delete cascade,
  uniforme           boolean not null default false,
  biblia             boolean not null default false,
  ebd                boolean not null default false,
  manual             boolean not null default false,   -- trouxe o manual
  conduta            boolean not null default false,
  secoes_dia         smallint not null default 0,      -- seções concluídas no dia
  atividade_extra    smallint not null default 0,      -- pontos de atividades extras
  pontos_jogos       int not null default 0,           -- derivado do módulo de jogos
  total              int not null default 0,           -- calculado por trigger
  registrado_por     uuid not null references profiles(id),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (encontro_id, oansista_id)
);

-- ----------------------------------------------------------------------------
-- FOLHA INDIVIDUAL: progresso de seções/níveis do manual
-- ----------------------------------------------------------------------------

create table progresso_manual (
  id             uuid primary key default uuid_generate_v4(),
  oansista_id    uuid not null references oansistas(id) on delete cascade,
  nivel          int not null,
  secao          int not null,
  concluida      boolean not null default true,
  data_conclusao date not null default current_date,
  registrado_por uuid not null references profiles(id),
  created_at     timestamptz not null default now(),
  unique (oansista_id, nivel, secao)
);

-- ----------------------------------------------------------------------------
-- MÓDULO DE JOGOS
-- ----------------------------------------------------------------------------

create table jogos (
  id          uuid primary key default uuid_generate_v4(),
  encontro_id uuid not null references encontros(id) on delete cascade,
  categoria   jogo_categoria not null,   -- 'faiscas' | 'flamas_tochas'
  nome        text not null,
  criado_por  uuid references profiles(id),
  created_at  timestamptz not null default now()
);

create table jogo_times (
  id       uuid primary key default uuid_generate_v4(),
  jogo_id  uuid not null references jogos(id) on delete cascade,
  nome     text not null,
  cor      text,
  lider_id uuid references profiles(id)  -- líder responsável pelo time
);

-- Composição dos times (para propagar pontos ao ranking individual)
create table jogo_time_integrantes (
  id          uuid primary key default uuid_generate_v4(),
  time_id     uuid not null references jogo_times(id) on delete cascade,
  oansista_id uuid not null references oansistas(id) on delete cascade,
  unique (time_id, oansista_id)
);

create table jogo_resultados (
  id              uuid primary key default uuid_generate_v4(),
  jogo_id         uuid not null references jogos(id) on delete cascade,
  time_id         uuid not null references jogo_times(id) on delete cascade,
  colocacao       smallint check (colocacao between 1 and 4),
  desclassificado boolean not null default false,
  pontos          int not null default 0,   -- derivado de jogos_pontos_config
  created_at      timestamptz not null default now(),
  unique (jogo_id, time_id),
  check (desclassificado or colocacao is not null)
);

-- ----------------------------------------------------------------------------
-- PREMIAÇÕES PENDENTES (integração Líder -> Secretaria, em tempo real)
-- ----------------------------------------------------------------------------

create table premios_pendentes (
  id            uuid primary key default uuid_generate_v4(),
  oansista_id   uuid not null references oansistas(id),
  premio_id     uuid not null references premios(id),
  clube_id      uuid not null references clubes(id),
  progresso_id  uuid references progresso_manual(id),
  status        pendencia_status not null default 'pendente',
  data_geracao  timestamptz not null default now(),
  data_entrega  timestamptz,
  entregue_por  uuid references profiles(id),
  observacao    text,
  unique (oansista_id, premio_id)
);

-- ----------------------------------------------------------------------------
-- ÍNDICES
-- ----------------------------------------------------------------------------
create index idx_profiles_role      on profiles(role);
create index idx_turmas_clube       on turmas(clube_id);
create index idx_oansistas_clube    on oansistas(clube_id);
create index idx_oansistas_turma    on oansistas(turma_id);
create index idx_presencas_encontro on presencas(encontro_id);
create index idx_folhas_encontro    on folhas_semanais(encontro_id);
create index idx_folhas_oansista    on folhas_semanais(oansista_id);
create index idx_progresso_oansista on progresso_manual(oansista_id);
create index idx_jogos_encontro     on jogos(encontro_id);
create index idx_pendencias_status  on premios_pendentes(status);
create index idx_visitas_visitante  on visitas(visitante_id);

-- ----------------------------------------------------------------------------
-- FUNÇÕES E TRIGGERS
-- ----------------------------------------------------------------------------

-- updated_at automático
create or replace function fn_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger trg_profiles_updated  before update on profiles  for each row execute function fn_set_updated_at();
create trigger trg_oansistas_updated before update on oansistas for each row execute function fn_set_updated_at();
create trigger trg_folhas_updated     before update on folhas_semanais for each row execute function fn_set_updated_at();

-- Cria profile automaticamente no signup (role/nome vindos dos metadados)
create or replace function fn_handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nome, telefone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nome', new.email),
    new.raw_user_meta_data->>'telefone',
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'lider')
  );
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function fn_handle_new_user();

-- Calcula o total da Folha Semanal a partir da configuração
create or replace function fn_calcular_total_folha()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  p_presenca    int := 0;
  p_uniforme    int := 0;
  p_biblia      int := 0;
  p_ebd         int := 0;
  p_manual      int := 0;
  p_conduta     int := 0;
  p_secao_unit  int := 0;
  presente      boolean;
begin
  select pr.presente into presente
  from presencas pr where pr.id = new.presenca_id;

  if presente is null or not presente then
    -- Ausente: pontuações do dia zeradas (RN 1)
    new.secoes_dia      := 0;
    new.atividade_extra := 0;
    new.pontos_jogos    := 0;
    new.total           := 0;
    return new;
  end if;

  select pontos into p_presenca   from itens_pontuacao where chave = 'presenca'      and ativo;
  select pontos into p_uniforme   from itens_pontuacao where chave = 'uniforme'      and ativo;
  select pontos into p_biblia     from itens_pontuacao where chave = 'biblia'        and ativo;
  select pontos into p_ebd        from itens_pontuacao where chave = 'ebd'           and ativo;
  select pontos into p_manual     from itens_pontuacao where chave = 'manual'        and ativo;
  select pontos into p_conduta    from itens_pontuacao where chave = 'conduta'       and ativo;
  select pontos into p_secao_unit from itens_pontuacao where chave = 'secao_manual'  and ativo;

  new.total :=
    coalesce(p_presenca, 0)
    + (case when new.uniforme then coalesce(p_uniforme, 0) else 0 end)
    + (case when new.biblia   then coalesce(p_biblia, 0)   else 0 end)
    + (case when new.ebd      then coalesce(p_ebd, 0)      else 0 end)
    + (case when new.manual   then coalesce(p_manual, 0)   else 0 end)
    + (case when new.conduta  then coalesce(p_conduta, 0)  else 0 end)
    + (coalesce(new.secoes_dia, 0) * coalesce(p_secao_unit, 0))
    + coalesce(new.atividade_extra, 0)
    + coalesce(new.pontos_jogos, 0);

  return new;
end $$;

create trigger trg_folha_total
  before insert or update of presenca_id, uniforme, biblia, ebd, manual, conduta,
                          secoes_dia, atividade_extra, pontos_jogos
  on folhas_semanais
  for each row execute function fn_calcular_total_folha();

-- Pontos do resultado de um jogo, conforme configuração (1º=100, 2º=70, ...)
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

-- Recalcula pontos_jogos das folhas dos integrantes do time (RN 3)
create or replace function fn_propagar_pontos_jogos()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_encontro uuid;
  v_oansista uuid;
begin
  select encontro_id into v_encontro from jogos where id = new.jogo_id;

  perform 1; -- atualiza as folhas de todos os integrantes do time
  update folhas_semanais f
     set pontos_jogos = sub.pontos
    from (
      select i.oansista_id, sum(r.pontos) as pontos
      from jogo_resultados r
      join jogo_times t on t.id = r.time_id
      join jogos j on j.id = r.jogo_id and j.encontro_id = v_encontro
      join jogo_time_integrantes i on i.time_id = t.id
      group by i.oansista_id
    ) sub
   where f.oansista_id = sub.oansista_id
     and f.encontro_id = v_encontro;

  return new;
end $$;

create trigger trg_propagar_pontos_jogos
  after insert or update or delete
  on jogo_resultados
  for each row execute function fn_propagar_pontos_jogos();

-- Conclusão de seção/nível do manual gera pendência para a Secretaria (RN 4)
create or replace function fn_gerar_pendencia_premio()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_premio uuid;
  v_clube  uuid;
begin
  select clube_id into v_clube from oansistas where id = new.oansista_id;

  select id into v_premio
  from premios
  where ativo and (
        (tipo in ('botom','premio') and nivel = new.nivel and secao = new.secao)
     or (tipo = 'manual'  and nivel = new.nivel and secao is null)
  )
  order by tipo limit 1;

  if v_premio is not null then
    insert into premios_pendentes (oansista_id, premio_id, clube_id, progresso_id)
    values (new.oansista_id, v_premio, v_clube, new.id)
    on conflict (oansista_id, premio_id) do nothing;
  end if;

  return new;
end $$;

create trigger trg_gerar_pendencia_premio
  after insert on progresso_manual
  for each row execute function fn_gerar_pendencia_premio();

-- ----------------------------------------------------------------------------
-- VIEWS
-- ----------------------------------------------------------------------------

-- Ranking do sábado por clube (RN 2)
create or replace view v_ranking_semanal as
select
  e.id                       as encontro_id,
  e.data                     as encontro_data,
  o.clube_id,
  c.nome                     as clube_nome,
  f.oansista_id,
  o.nome                     as oansista_nome,
  f.total,
  rank() over (
    partition by e.id, o.clube_id
    order by f.total desc, o.nome asc
  ) as posicao
from folhas_semanais f
join oansistas o on o.id = f.oansista_id
join clubes c    on c.id = o.clube_id
join encontros e on e.id = f.encontro_id;

-- Painel de premiações pendentes da Secretaria
create or replace view v_premios_pendentes as
select
  pp.id, pp.status, pp.data_geracao, pp.data_entrega,
  o.nome  as oansista_nome,
  c.nome  as clube_nome,
  p.nome  as premio_nome,
  p.tipo  as premio_tipo,
  p.estoque
from premios_pendentes pp
join oansistas o on o.id = pp.oansista_id
join clubes c    on c.id = pp.clube_id
join premios p   on p.id = pp.premio_id;

-- ----------------------------------------------------------------------------
-- REALTIME (painel da Secretaria em tempo real)
-- ----------------------------------------------------------------------------
alter publication supabase_realtime add table premios_pendentes;
alter publication supabase_realtime add table presencas;

