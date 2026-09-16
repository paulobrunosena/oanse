-- ============================================================================
-- OANSE - Congela a situação de visitantes já matriculados (polimento Fase 3).
--
--   Uma vez que o visitante é matriculado (status 'matriculado'), a situação
--   deixa de ser editável: vira um registro histórico. Também protege o
--   visitante criado por transferência de clube (oansista_origem_id preenchido),
--   cuja situação só evolui para 'matriculado' via fn_matricular_visitante.
--
--   O trigger atua no UPDATE manual de `status` (via RLS/anon), mas NÃO
--   interfere na matrícula (RPC security definer), que é a única transição
--   legítima para 'matriculado'.
-- ============================================================================

create or replace function fn_travar_status_visitante()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Atualizações de outros campos que repetem o mesmo status são inofensivas.
  if new.status is not distinct from old.status then
    return new;
  end if;

  -- Matriculado é um estado terminal (arquivo/histórico).
  if old.status = 'matriculado' then
    raise exception 'A situação de um visitante matriculado não pode ser alterada';
  end if;

  -- Visitante vindo de transferência de clube: a situação só pode mudar para
  -- 'matriculado' (pela matrícula do clube destino), nunca manualmente.
  if old.oansista_origem_id is not null and new.status <> 'matriculado' then
    raise exception 'A situação de um visitante em transferência só muda para Matriculado';
  end if;

  return new;
end;
$$;

create trigger trg_travar_status_visitante
  before update of status on visitantes
  for each row execute function fn_travar_status_visitante();
