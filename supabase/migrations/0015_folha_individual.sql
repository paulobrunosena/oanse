-- ============================================================================
-- OANSE - Folha de Progresso Individual (docs/06-folha-individual.md)
--
-- Substitui o modelo antigo `progresso_manual` (nivel/secao), nunca usado no
-- frontend. Modelo novo: catálogo (manual > seção > bloco) + progresso do
-- oansista. Cada bloco tem N itens (bolinhas numeradas 1..quantidade, sem
-- descrição textual) e um prêmio ganho ao concluir todos os itens.
--
-- Começa pelo clube Faíscas; a estrutura já é por clube, então os demais clubes
-- entram apenas com novo seed (sem mudança de schema).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CATÁLOGO
-- ----------------------------------------------------------------------------
create table folha_manuais (
  id         uuid primary key default uuid_generate_v4(),
  clube_id   uuid not null references clubes(id) on delete cascade,
  nome       text not null,
  ordem      int  not null,
  created_at timestamptz not null default now(),
  unique (clube_id, nome),
  unique (clube_id, ordem)
);

create table folha_secoes (
  id        uuid primary key default uuid_generate_v4(),
  manual_id uuid not null references folha_manuais(id) on delete cascade,
  nome      text not null,
  ordem     int  not null,
  tipo      text not null default 'itens' check (tipo in ('itens', 'observacoes')),
  unique (manual_id, ordem),
  unique (manual_id, nome)
);

create table folha_blocos (
  id          uuid primary key default uuid_generate_v4(),
  secao_id    uuid not null references folha_secoes(id) on delete cascade,
  nome        text not null,
  ordem       int  not null,
  quantidade  int  not null check (quantidade > 0),
  premio_nome text not null,
  unique (secao_id, ordem)
);

-- ----------------------------------------------------------------------------
-- PROGRESSO DO OANSISTA
-- ----------------------------------------------------------------------------
create table folha_item_progresso (
  id             uuid primary key default uuid_generate_v4(),
  oansista_id    uuid not null references oansistas(id) on delete cascade,
  bloco_id       uuid not null references folha_blocos(id) on delete cascade,
  item_num       int  not null check (item_num >= 1),
  data_conclusao date not null default current_date,
  registrado_por uuid not null references profiles(id),
  created_at     timestamptz not null default now(),
  unique (oansista_id, bloco_id, item_num)
);

create table folha_premio_progresso (
  id               uuid primary key default uuid_generate_v4(),
  oansista_id      uuid not null references oansistas(id) on delete cascade,
  bloco_id         uuid not null references folha_blocos(id) on delete cascade,
  data_recebimento date not null default current_date,
  registrado_por   uuid not null references profiles(id),
  created_at       timestamptz not null default now(),
  unique (oansista_id, bloco_id)
);

create table folha_observacoes (
  id          uuid primary key default uuid_generate_v4(),
  oansista_id uuid not null references oansistas(id) on delete cascade,
  manual_id   uuid not null references folha_manuais(id) on delete cascade,
  texto       text,
  updated_at  timestamptz not null default now(),
  unique (oansista_id, manual_id)
);

create trigger trg_folha_observacoes_updated
  before update on folha_observacoes
  for each row execute function fn_set_updated_at();

-- ----------------------------------------------------------------------------
-- ÍNDICES
-- ----------------------------------------------------------------------------
create index idx_folha_manuais_clube            on folha_manuais(clube_id);
create index idx_folha_secoes_manual            on folha_secoes(manual_id);
create index idx_folha_blocos_secao             on folha_blocos(secao_id);
create index idx_folha_item_prog_oansista       on folha_item_progresso(oansista_id);
create index idx_folha_item_prog_bloco          on folha_item_progresso(bloco_id);
create index idx_folha_premio_prog_oansista     on folha_premio_progresso(oansista_id);
create index idx_folha_observacoes_oansista     on folha_observacoes(oansista_id);

-- ----------------------------------------------------------------------------
-- GRANTS (0003 cobriu as tabelas da época; novas precisam de grant explícito)
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on
  folha_manuais, folha_secoes, folha_blocos,
  folha_item_progresso, folha_premio_progresso, folha_observacoes
to authenticated, service_role;

-- ----------------------------------------------------------------------------
-- LIMPEZA DO LEGADO
-- A pendência automática de prêmio sai junto (será redesenhada na Fase 3 —
-- Painel da Secretaria); por ora o prêmio é só registro de data no progresso.
-- ----------------------------------------------------------------------------
drop trigger if exists trg_gerar_pendencia_premio on progresso_manual;
drop function if exists fn_gerar_pendencia_premio();
alter table premios_pendentes drop column if exists progresso_id;
drop table if exists progresso_manual;
