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
  chave      text primary key,   -- 'presenca','uniforme','biblia','ebd','manual','conduta','leitura_biblica','visitante','secao_sem_ajuda','secao_com_ajuda'
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
-- RN 6: O líder acessa o encontro do sábado corrente (criado sob demanda pelo
-- server/api/encontros/atual) e pode navegar pelo HISTÓRICO de encontros para
-- lançar chamadas atrasadas (ex.: sábado sem internet, lançado depois).
-- Backfill de "sábado perdido": server/api/encontros/retro cria o encontro de
-- um sábado passado que nunca foi registrado (ex.: sistema fora do ar o sábado
-- inteiro). Mesma autorização do atual (service_role p/ qualquer autenticado);
-- valida que é sábado, não está no futuro e não é dia sem Oanse (RN 7).
-- A leitura de encontros é aberta (RLS encontros_select = true); a escrita é
-- restrita a diretor_geral/secretaria.

create table encontros (
  id         uuid primary key default uuid_generate_v4(),
  data       date not null unique,   -- sábado
  tema       text,
  ativo      boolean not null default true,
  created_at timestamptz not null default now()
);

-- Sábados sem Oanse (férias/feriados/eventos). RN 7: impede criação de
-- encontro e lançamento nesses dias (ver server/api/encontros/atual).
create table dias_sem_oanse (
  id         uuid primary key default uuid_generate_v4(),
  data       date not null unique,
  motivo     text,
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
  id                    uuid primary key default uuid_generate_v4(),
  encontro_id           uuid not null references encontros(id) on delete cascade,
  oansista_id           uuid not null references oansistas(id) on delete cascade,
  presenca_id           uuid not null references presencas(id) on delete cascade,
  uniforme              boolean not null default false,
  biblia                boolean not null default false,
  ebd                   boolean not null default false,
  manual                boolean not null default false,   -- trouxe o manual
  conduta               boolean not null default false,
  leitura_biblica       boolean not null default false,   -- fez a leitura bíblica
  visitantes_convidados smallint not null default 0,      -- visitantes convidados
  secoes_sem_ajuda      smallint not null default 0,      -- seções do manual sem ajuda (vale mais)
  secoes_com_ajuda      smallint not null default 0,      -- seções do manual com ajuda
  cor_time              text,                             -- cor do time nos jogos do sábado (NULL = não participou)
  atividade_extra       smallint not null default 0,      -- pontos de atividades extras
  pontos_jogos          int not null default 0,           -- derivado do módulo de jogos
  total                 int not null default 0,           -- calculado por trigger
  registrado_por        uuid not null references profiles(id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
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
-- MÓDULO DE JOGOS (Líder de Jogos)
-- ----------------------------------------------------------------------------
-- RN 3 (revisado 2026-08-25): fluxo simplificado para o líder de jogos. O evento
-- é cadastrado UMA vez por sábado (clubes, cores participantes e oansistas de
-- cada cor); depois o líder só registra o resultado de cada rodada (nome do
-- jogo vindo do catálogo + colocação das cores). Ao final, finaliza o evento e
-- consulta o ranking das cores para o anúncio.
--
-- Um sábado pode ter VÁRIOS eventos (ex.: um dos Flamas+Tochas e outro dos
-- Ursinhos+Faíscas). Cada clube participa de no máximo UM evento por sábado —
-- validado por trigger em evento_jogos_clubes e pela RPC fn_criar_evento_jogos.
--
--  - jogos_catalogo: nomes de jogos por clube (CRUD) — combo do registro de
--    rodada (nomes repetidos entre clubes não aparecem duplicados)
--  - eventos_jogos: sessão de jogos do sábado (várias por encontro), status
--    em_andamento/finalizado
--  - evento_jogos_clubes: clubes participantes (definem o combo de jogos)
--  - evento_jogos_cores: cores participantes (verde/vermelho/amarelo/azul)
--  - evento_jogos_cores_oansistas: oansistas de cada cor (a busca só oferece
--    crianças dos clubes que participam do evento; a criança exibe o nome na
--    cor do clube dela e pode ser removida/trocada de cor enquanto o evento
--    está em andamento)
--  - jogos: rodada de um jogo dentro do evento (nome vem do catálogo)
--  - jogo_resultados: colocação/desclassificado de cada cor na rodada
--
-- Criação atômica do evento na RPC fn_criar_evento_jogos (valida que o autor é
-- lider_jogos ou diretor_geral). Pontos/cor_time são propagados às folhas pelo
-- trigger fn_propagar_pontos_jogos. Ranking das cores via fn_ranking_cores_do_evento.

create table jogos_catalogo (
  id         uuid primary key default uuid_generate_v4(),
  clube_id   uuid not null references clubes(id) on delete cascade,
  nome       text not null,
  created_at timestamptz not null default now(),
  unique (clube_id, nome)
);

create table eventos_jogos (
  id          uuid primary key default uuid_generate_v4(),
  encontro_id uuid not null references encontros(id) on delete cascade,
  nome        text not null,
  status      text not null default 'em_andamento'
              check (status in ('em_andamento', 'finalizado')),
  criado_por  uuid references profiles(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table evento_jogos_clubes (
  id         uuid primary key default uuid_generate_v4(),
  evento_id  uuid not null references eventos_jogos(id) on delete cascade,
  clube_id   uuid not null references clubes(id),
  unique (evento_id, clube_id)
);

create table evento_jogos_cores (
  id         uuid primary key default uuid_generate_v4(),
  evento_id  uuid not null references eventos_jogos(id) on delete cascade,
  cor        text not null check (cor in ('verde', 'vermelho', 'amarelo', 'azul')),
  unique (evento_id, cor)
);

create table evento_jogos_cores_oansistas (
  id          uuid primary key default uuid_generate_v4(),
  cor_id      uuid not null references evento_jogos_cores(id) on delete cascade,
  oansista_id uuid not null references oansistas(id) on delete cascade,
  unique (cor_id, oansista_id)
);

-- Rodada de um jogo dentro do evento
create table jogos (
  id         uuid primary key default uuid_generate_v4(),
  evento_id  uuid not null references eventos_jogos(id) on delete cascade,
  nome       text not null,
  criado_por uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- Resultado de cada cor na rodada (pontos derivados de jogos_pontos_config)
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
create index idx_jogos_catalogo_clube on jogos_catalogo(clube_id);
create index idx_evento_jogos_clubes_evento on evento_jogos_clubes(evento_id);
create index idx_evento_jogos_cores_evento on evento_jogos_cores(evento_id);
create index idx_evento_cores_oansistas_cor on evento_jogos_cores_oansistas(cor_id);
create index idx_jogos_evento         on jogos(evento_id);
create index idx_jogo_resultados_jogo on jogo_resultados(jogo_id);
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
create trigger trg_eventos_jogos_updated before update on eventos_jogos for each row execute function fn_set_updated_at();

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
  p_presenca          int := 0;
  p_uniforme          int := 0;
  p_biblia            int := 0;
  p_ebd               int := 0;
  p_manual            int := 0;
  p_conduta           int := 0;
  p_leitura           int := 0;
  p_visitante_unit    int := 0;
  p_secao_sem_ajuda   int := 0;
  p_secao_com_ajuda   int := 0;
  presente            boolean;
begin
  select pr.presente into presente
  from presencas pr where pr.id = new.presenca_id;

  if presente is null or not presente then
    -- Ausente: pontuações do dia zeradas (RN 1)
    new.leitura_biblica       := false;
    new.visitantes_convidados := 0;
    new.secoes_sem_ajuda      := 0;
    new.secoes_com_ajuda      := 0;
    new.cor_time              := null;
    new.atividade_extra       := 0;
    new.pontos_jogos          := 0;
    new.total                 := 0;
    return new;
  end if;

  select pontos into p_presenca        from itens_pontuacao where chave = 'presenca'        and ativo;
  select pontos into p_uniforme        from itens_pontuacao where chave = 'uniforme'        and ativo;
  select pontos into p_biblia          from itens_pontuacao where chave = 'biblia'          and ativo;
  select pontos into p_ebd             from itens_pontuacao where chave = 'ebd'             and ativo;
  select pontos into p_manual          from itens_pontuacao where chave = 'manual'          and ativo;
  select pontos into p_conduta         from itens_pontuacao where chave = 'conduta'         and ativo;
  select pontos into p_leitura         from itens_pontuacao where chave = 'leitura_biblica' and ativo;
  select pontos into p_visitante_unit  from itens_pontuacao where chave = 'visitante'       and ativo;
  select pontos into p_secao_sem_ajuda from itens_pontuacao where chave = 'secao_sem_ajuda' and ativo;
  select pontos into p_secao_com_ajuda from itens_pontuacao where chave = 'secao_com_ajuda' and ativo;

  new.total :=
    coalesce(p_presenca, 0)
    + (case when new.uniforme then coalesce(p_uniforme, 0) else 0 end)
    + (case when new.biblia   then coalesce(p_biblia, 0)   else 0 end)
    + (case when new.ebd      then coalesce(p_ebd, 0)      else 0 end)
    + (case when new.manual   then coalesce(p_manual, 0)   else 0 end)
    + (case when new.conduta  then coalesce(p_conduta, 0)  else 0 end)
    + (case when new.leitura_biblica then coalesce(p_leitura, 0) else 0 end)
    + (coalesce(new.visitantes_convidados, 0) * coalesce(p_visitante_unit, 0))
    + (coalesce(new.secoes_sem_ajuda, 0) * coalesce(p_secao_sem_ajuda, 0))
    + (coalesce(new.secoes_com_ajuda, 0) * coalesce(p_secao_com_ajuda, 0))
    + coalesce(new.atividade_extra, 0)
    + coalesce(new.pontos_jogos, 0);

  return new;
end $$;

create trigger trg_folha_total
  before insert or update of presenca_id, uniforme, biblia, ebd, manual, conduta,
                          leitura_biblica, visitantes_convidados, secoes_sem_ajuda,
                          secoes_com_ajuda, cor_time, atividade_extra, pontos_jogos
  on folhas_semanais
  for each row execute function fn_calcular_total_folha();

-- Alternância de presença na chamada (presente <=> falta) recalcula a folha:
-- "touch" em presenca_id dispara o trg_folha_total acima (migration 0004).
create or replace function fn_recalcular_folha_por_presenca()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update folhas_semanais
     set presenca_id = presenca_id
   where encontro_id = new.encontro_id
     and oansista_id = new.oansista_id;
  return new;
end $$;

create trigger trg_folha_recalcular_presenca
  after insert or update of presente on presencas
  for each row execute function fn_recalcular_folha_por_presenca();

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

-- Criação atômica do evento de jogos + clubes + cores (RN 3 revisado):
-- autoriza apenas lider_jogos ou diretor_geral. Permite vários eventos por
-- sábado, mas nenhum clube pode repetir em outro evento do mesmo sábado.
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

-- Garante (em qualquer via de entrada) que um clube não entra em dois eventos
-- do mesmo sábado.
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

-- Ranking das cores do evento (anúncio do placar no final da programação)
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

-- Recalcula pontos_jogos e cor_time das folhas do encontro (RN 3). Soma os
-- pontos de TODAS as rodadas do evento para cada oansista de cor; integrantes
-- de cor sem resultado ficam com 0. cor_time é informacional (não pontua).
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

-- ============================================================================
-- SEED (supabase/seed.sql)
-- ============================================================================
insert into clubes (nome, slug, idade_min, idade_max, cor, ordem) values
  ('Ursinhos', 'ursinhos', 4, 5, '#EF4444', 1),
  ('Faíscas',  'faiscas',  6, 8, '#EAB308', 2),
  ('Flamas',   'flamas',   9, 10, '#22C55E', 3),
  ('Tochas',   'tochas',   11, 12, '#3B82F6', 4);

insert into itens_pontuacao (chave, descricao, pontos) values
  ('presenca',           'Presença no sábado',                10),
  ('uniforme',           'Está com o uniforme',               10),
  ('biblia',             'Trouxe a Bíblia',                   10),
  ('ebd',                'Participou da EBD',                 10),
  ('manual',             'Trouxe o manual',                   10),
  ('conduta',            'Boa conduta no clube',              10),
  ('leitura_biblica',    'Leitura bíblica',                   10),
  ('visitante',          'Por visitante convidado',            5),
  ('secao_sem_ajuda',    'Por seção do manual sem ajuda',     10),
  ('secao_com_ajuda',    'Por seção do manual com ajuda',      5);

insert into jogos_pontos_config (colocacao, pontos) values
  (1, 100), (2, 70), (3, 50), (4, 40);

-- Catálogo de jogos por clube (combo do registro de rodada)
insert into jogos_catalogo (clube_id, nome) values
  ((select id from clubes where slug = 'ursinhos'), 'trenzinho de mãos dadas'),
  ((select id from clubes where slug = 'ursinhos'), 'de gatinhos (em pé)'),
  ((select id from clubes where slug = 'ursinhos'), 'saquinho de feijão na cabeça'),
  ((select id from clubes where slug = 'faiscas'),  'de gatinhos (de joelhos)'),
  ((select id from clubes where slug = 'faiscas'),  'saquinho de feijão na cabeça'),
  ((select id from clubes where slug = 'faiscas'),  'agilidade zigue-zague'),
  ((select id from clubes where slug = 'faiscas'),  'queimada'),
  ((select id from clubes where slug = 'faiscas'),  'boliche dos faíscas'),
  ((select id from clubes where slug = 'faiscas'),  'revezamento com bexigas'),
  ((select id from clubes where slug = 'flamas'),   'revezamento com saquinho de feijão'),
  ((select id from clubes where slug = 'flamas'),   'corrida de 3 pernas'),
  ((select id from clubes where slug = 'flamas'),   'revezamento sprint'),
  ((select id from clubes where slug = 'flamas'),   'agilidade zigue-zague'),
  ((select id from clubes where slug = 'flamas'),   'sprint'),
  ((select id from clubes where slug = 'flamas'),   'cabo de guerra'),
  ((select id from clubes where slug = 'flamas'),   'derrubando o pino'),
  ((select id from clubes where slug = 'flamas'),   'revezamento maratona'),
  ((select id from clubes where slug = 'flamas'),   'bonanza'),
  ((select id from clubes where slug = 'flamas'),   'maratona'),
  ((select id from clubes where slug = 'flamas'),   'bola no túnel'),
  ((select id from clubes where slug = 'tochas'),   'revezamento com saquinho de feijão'),
  ((select id from clubes where slug = 'tochas'),   'corrida de 3 pernas'),
  ((select id from clubes where slug = 'tochas'),   'revezamento sprint'),
  ((select id from clubes where slug = 'tochas'),   'agilidade zigue-zague'),
  ((select id from clubes where slug = 'tochas'),   'sprint'),
  ((select id from clubes where slug = 'tochas'),   'cabo de guerra'),
  ((select id from clubes where slug = 'tochas'),   'derrubando o pino'),
  ((select id from clubes where slug = 'tochas'),   'revezamento maratona'),
  ((select id from clubes where slug = 'tochas'),   'bonanza'),
  ((select id from clubes where slug = 'tochas'),   'maratona'),
  ((select id from clubes where slug = 'tochas'),   'bola no túnel'),
  ((select id from clubes where slug = 'tochas'),   'revezamento com bola de basquete');

-- Usuários de teste (senha oanse123) — inclui o Líder de Jogos
-- (diretor@, secretaria@, diretor.ursinhos@, lider.jogos@, tia.ana@)
