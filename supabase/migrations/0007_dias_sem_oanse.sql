-- ============================================================================
-- OANSE - Sábados sem atividade (férias, feriados, eventos).
--
-- RN 7: dias sem Oanse NÃO podem ter chamada/folha. A regra é imposta na
-- origem: o server/api/encontros/atual NÃO cria o encontro do sábado quando
-- a data consta em dias_sem_oanse. Sem encontro, não há presença nem folha.
-- Se um encontro já existia para uma data marcada depois como sem Oanse,
-- encontros.ativo é desligado na marcação (via aplicação), tornando a data
-- inerte para lançamento.
-- ============================================================================

create table dias_sem_oanse (
  id         uuid primary key default uuid_generate_v4(),
  data       date not null unique,
  motivo     text,
  created_at timestamptz not null default now()
);

comment on table dias_sem_oanse is
  'Sábados sem Oanse (férias/feriados). Impede criação de encontro e lançamento.';

-- ----------------------------------------------------------------------------
-- RLS: leitura aberta (contexto), escrita só Diretor Geral
-- ----------------------------------------------------------------------------
alter table dias_sem_oanse enable row level security;

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
-- Grants (0003 cobriu tabelas existentes à época; novas precisam de grant)
-- ----------------------------------------------------------------------------
grant select, insert, update, delete on dias_sem_oanse to authenticated, service_role;