-- ============================================================================
-- OANSE - Ajustes na Folha de Visitantes e transferência de clube (Fase 3).
--
--   1. Lições da Prova de Ingresso por clube (`clubes.qtd_licoes`):
--      Ursinhos=2, Faíscas=6, Flamas=8, Tochas=8 (valores no seed).
--   2. Regras de matrícula reforçadas na RPC `fn_matricular_visitante`:
--      exige 3 visitas (presente) + todas as lições do clube; vínculo
--      oansista<->visitante impede re-matrícula mesmo adulterando a situação.
--   3. Vínculos `visitantes.oansista_origem_id` (transferência) e
--      `oansistas.visitante_origem_id` (proveniência da matrícula).
--   4. Transferência de clube (mudança de faixa etária): RPC
--      `fn_transferir_clube` (oansista vira visitante no clube destino,
--      pulando as 3 visitas; oansista marcado `transferido`) com histórico em
--      `transferencias_clube` e reversão via `fn_cancelar_transferencia_clube`.
-- ============================================================================

-- 1. Lições por clube --------------------------------------------------------
alter table clubes add column qtd_licoes int not null default 8;

-- 3. Vínculos -----------------------------------------------------------------
alter table visitantes add column oansista_origem_id uuid references oansistas(id) on delete set null;
alter table oansistas  add column visitante_origem_id uuid references visitantes(id) on delete set null;

create index idx_visitantes_origem on visitantes(oansista_origem_id);
create index idx_oansistas_visitante on oansistas(visitante_origem_id);

-- 4. Histórico de transferência de clube -------------------------------------
create table transferencias_clube (
  id               uuid primary key default uuid_generate_v4(),
  oansista_id      uuid not null references oansistas(id) on delete cascade,
  clube_origem_id  uuid not null references clubes(id),
  clube_destino_id uuid not null references clubes(id),
  turma_origem_id  uuid references turmas(id),
  data             date not null default current_date,
  motivo           text,
  autorizado_por   uuid not null references profiles(id),
  revertida        boolean not null default false,
  revertida_em     date,
  created_at       timestamptz not null default now(),
  check (clube_origem_id <> clube_destino_id)
);

create index idx_transferencias_clube_oansista on transferencias_clube(oansista_id);

-- Impede gravar lição fora do intervalo do clube do visitante (RN de Prova).
create or replace function fn_validar_licao_prova()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_max int;
begin
  select c.qtd_licoes into v_max
  from visitantes v
  join clubes c on c.id = v.clube_id
  where v.id = new.visitante_id;

  if v_max is null then
    raise exception 'Visitante não encontrado';
  end if;

  if new.licao < 1 or new.licao > v_max then
    raise exception 'Lição fora do intervalo do clube (1..%)', v_max;
  end if;

  return new;
end $$;

create trigger trg_validar_licao_prova
  before insert or update of licao on prova_ingresso_licoes
  for each row execute function fn_validar_licao_prova();

-- ----------------------------------------------------------------------------
-- Matrícula (v2): regras de 3 visitas + lições; suporta transferência de clube.
-- ----------------------------------------------------------------------------
create or replace function fn_matricular_visitante(
  p_visitante_id uuid,
  p_turma_id     uuid default null
)
returns oansistas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_visitante visitantes%rowtype;
  v_clube     clubes%rowtype;
  v_visitas   int;
  v_licoes    int;
  v_oansista  oansistas;
begin
  select * into v_visitante from visitantes where id = p_visitante_id;
  if not found then
    raise exception 'Visitante não encontrado';
  end if;

  if v_visitante.status = 'matriculado' then
    raise exception 'Visitante já está matriculado';
  end if;

  -- Autorização: Diretor Geral ou Diretor do clube do visitante.
  if not (fn_role() = 'diretor_geral' or fn_diretor_do_clube(v_visitante.clube_id)) then
    raise exception 'Apenas o Diretor do clube pode matricular';
  end if;

  select * into v_clube from clubes where id = v_visitante.clube_id;
  if not found then
    raise exception 'Clube do visitante não encontrado';
  end if;

  if p_turma_id is not null then
    if not exists (
      select 1 from turmas t
      where t.id = p_turma_id and t.clube_id = v_visitante.clube_id and t.ativo
    ) then
      raise exception 'Turma inválida ou de outro clube';
    end if;
  end if;

  -- Visitante novo exige as 3 visitas (presentes). Transferências pulam essa etapa.
  if v_visitante.oansista_origem_id is null then
    select count(*) into v_visitas
    from visitas
    where visitante_id = p_visitante_id and presente = true;

    if v_visitas < 3 then
      raise exception 'A criança precisa concluir as 3 visitas antes da matrícula';
    end if;

    -- Bloqueio de re-matrícula mesmo se a situação for adulterada.
    if exists (select 1 from oansistas where visitante_origem_id = p_visitante_id) then
      raise exception 'Visitante já matriculado';
    end if;
  end if;

  -- Todas as lições do clube precisam estar concluídas (comum aos dois casos).
  select count(*) into v_licoes
  from prova_ingresso_licoes
  where visitante_id = p_visitante_id
    and concluida = true
    and licao between 1 and v_clube.qtd_licoes;

  if v_licoes < v_clube.qtd_licoes then
    raise exception 'A criança precisa concluir as % lições da Prova de Ingresso', v_clube.qtd_licoes;
  end if;

  if v_visitante.oansista_origem_id is null then
    -- Matrícula comum: cria o oansista herdando os dados do visitante.
    insert into oansistas (
      nome, data_nascimento, clube_id, turma_id,
      responsavel, contato, data_matricula, status, visitante_origem_id
    )
    values (
      v_visitante.nome, v_visitante.data_nascimento, v_visitante.clube_id, p_turma_id,
      v_visitante.responsavel, v_visitante.contato, current_date, 'ativo', p_visitante_id
    )
    returning * into v_oansista;
  else
    -- Transferência de clube: reativa o oansista no clube destino.
    select * into v_oansista from oansistas where id = v_visitante.oansista_origem_id;
    if not found then
      raise exception 'Oansista de origem não encontrado';
    end if;

    if v_oansista.clube_id = v_visitante.clube_id and v_oansista.status = 'ativo' then
      raise exception 'Visitante já matriculado';
    end if;

    update oansistas
       set clube_id = v_visitante.clube_id,
           turma_id = p_turma_id,
           status = 'ativo',
           visitante_origem_id = p_visitante_id,
           updated_at = now()
     where id = v_oansista.id
     returning * into v_oansista;
  end if;

  update visitantes
     set status = 'matriculado', updated_at = now()
   where id = p_visitante_id;

  return v_oansista;
end;
$$;

grant execute on function fn_matricular_visitante(uuid, uuid) to authenticated, service_role;

-- ----------------------------------------------------------------------------
-- Transferência de clube (mudança de faixa etária): cria o visitante no clube
-- destino (status 'prova_ingresso', sem exigência de 3 visitas) e marca o
-- oansista como 'transferido'. Histórico em transferencias_clube.
-- ----------------------------------------------------------------------------
create or replace function fn_transferir_clube(
  p_oansista_id      uuid,
  p_clube_destino_id uuid,
  p_motivo           text default null,
  p_autorizado_por   uuid default auth.uid()
)
returns transferencias_clube
language plpgsql
security definer
set search_path = public
as $$
declare
  v_oansista oansistas%rowtype;
  v_destino  clubes%rowtype;
  v_registro transferencias_clube;
begin
  select * into v_oansista from oansistas where id = p_oansista_id;
  if not found then
    raise exception 'Oansista não encontrado';
  end if;

  if v_oansista.status <> 'ativo' then
    raise exception 'Apenas oansistas ativos podem ser transferidos';
  end if;

  -- Autorização: Diretor Geral ou Diretor do clube de ORIGEM da criança.
  if not (fn_role() = 'diretor_geral' or fn_diretor_do_clube(v_oansista.clube_id)) then
    raise exception 'Apenas o Diretor do clube pode transferir';
  end if;

  select * into v_destino from clubes where id = p_clube_destino_id;
  if not found then
    raise exception 'Clube de destino não encontrado';
  end if;

  if v_destino.id = v_oansista.clube_id then
    raise exception 'O clube de destino deve ser diferente do clube atual';
  end if;

  if exists (
    select 1 from visitantes v
    where v.oansista_origem_id = p_oansista_id
      and v.status in ('em_visitas', 'prova_ingresso')
  ) then
    raise exception 'Criança já possui uma transferência de clube em andamento';
  end if;

  insert into transferencias_clube (
    oansista_id, clube_origem_id, clube_destino_id, turma_origem_id,
    data, motivo, autorizado_por
  )
  values (
    p_oansista_id, v_oansista.clube_id, v_destino.id, v_oansista.turma_id,
    current_date, p_motivo, p_autorizado_por
  )
  returning * into v_registro;

  insert into visitantes (
    nome, data_nascimento, clube_id, indicado_por, responsavel, contato,
    status, oansista_origem_id
  )
  values (
    v_oansista.nome, v_oansista.data_nascimento, v_destino.id, null,
    v_oansista.responsavel, v_oansista.contato, 'prova_ingresso', p_oansista_id
  );

  update oansistas
     set status = 'transferido', turma_id = null, updated_at = now()
   where id = p_oansista_id;

  return v_registro;
end;
$$;

grant execute on function fn_transferir_clube(uuid, uuid, text, uuid) to authenticated, service_role;

-- ----------------------------------------------------------------------------
-- Reversão de transferência de clube: remove o visitante em andamento e
-- reativa o oansista no clube de origem (restaurando a turma anterior).
-- ----------------------------------------------------------------------------
create or replace function fn_cancelar_transferencia_clube(
  p_oansista_id    uuid,
  p_autorizado_por uuid default auth.uid()
)
returns oansistas
language plpgsql
security definer
set search_path = public
as $$
declare
  v_oansista oansistas%rowtype;
  v_registro transferencias_clube%rowtype;
begin
  select * into v_oansista from oansistas where id = p_oansista_id;
  if not found then
    raise exception 'Oansista não encontrado';
  end if;

  if v_oansista.status <> 'transferido' then
    raise exception 'A criança não está em processo de transferência';
  end if;

  -- Autorização: Diretor Geral ou Diretor do clube de ORIGEM.
  if not (fn_role() = 'diretor_geral' or fn_diretor_do_clube(v_oansista.clube_id)) then
    raise exception 'Apenas o Diretor do clube pode cancelar a transferência';
  end if;

  select * into v_registro
  from transferencias_clube
  where oansista_id = p_oansista_id and not revertida
  order by created_at desc
  limit 1;

  if not found then
    raise exception 'Transferência de clube não encontrada';
  end if;

  delete from visitantes
  where oansista_origem_id = p_oansista_id
    and status <> 'matriculado';

  update transferencias_clube
     set revertida = true, revertida_em = current_date
   where id = v_registro.id;

  update oansistas
     set status = 'ativo',
         turma_id = v_registro.turma_origem_id,
         updated_at = now()
   where id = p_oansista_id
   returning * into v_oansista;

  return v_oansista;
end;
$$;

grant execute on function fn_cancelar_transferencia_clube(uuid, uuid) to authenticated, service_role;
