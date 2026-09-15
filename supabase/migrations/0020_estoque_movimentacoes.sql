-- ============================================================================
-- OANSE - Fase 3 (polimento): movimentações de estoque manuais (entrada/saída).
--
-- 1. `premios_movimentacoes.feito_por` passa a referenciar `profiles` (em vez
--    de `auth.users`), alinhando com `premios_pendentes.entregue_por` e
--    permitindo o join do nome no painel da Secretaria.
-- 2. `fn_movimentar_estoque`: entrada/saída transacional (valida autorização,
--    quantidade e saldo; atualiza `premios.estoque` e grava a movimentação).
-- ============================================================================

-- 1. Vínculo do responsável pela movimentação com o perfil
alter table premios_movimentacoes
  drop constraint if exists premios_movimentacoes_feito_por_fkey;

alter table premios_movimentacoes
  add constraint premios_movimentacoes_feito_por_fkey
  foreign key (feito_por) references profiles(id) on delete cascade;

-- 2. Movimentação de estoque (transacional), chamada pelo server/api.
create or replace function fn_movimentar_estoque(
  p_premio_id      uuid,
  p_tipo           text,
  p_quantidade     int,
  p_autorizado_por uuid,
  p_observacao     text default null
)
returns premios_movimentacoes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_premio premios%rowtype;
  v_mov    premios_movimentacoes%rowtype;
begin
  -- Autorização validada pelo id informado (a RPC roda com service_role,
  -- então fn_role()/auth.uid() não se aplicam aqui).
  if not exists (
    select 1 from profiles p
    where p.id = p_autorizado_por
      and p.role in ('diretor_geral', 'secretaria')
  ) then
    raise exception 'Apenas a Secretaria pode registrar movimentações de estoque';
  end if;

  if p_tipo not in ('entrada', 'saida') then
    raise exception 'Tipo de movimentação inválido';
  end if;

  if p_quantidade is null or p_quantidade <= 0 then
    raise exception 'A quantidade deve ser maior que zero';
  end if;

  select * into v_premio from premios where id = p_premio_id;
  if not found then
    raise exception 'Prêmio não encontrado';
  end if;

  if p_tipo = 'saida' and v_premio.estoque < p_quantidade then
    raise exception 'Estoque insuficiente para esta saída';
  end if;

  update premios
     set estoque = estoque + case when p_tipo = 'entrada' then p_quantidade else -p_quantidade end
   where id = p_premio_id;

  insert into premios_movimentacoes (premio_id, tipo, quantidade, observacao, feito_por)
  values (p_premio_id, p_tipo, p_quantidade, nullif(trim(p_observacao), ''), p_autorizado_por)
  returning * into v_mov;

  return v_mov;
end;
$$;

-- Cliente (via server route com service_role) e server: executam a RPC.
grant execute on function fn_movimentar_estoque(uuid, text, int, uuid, text) to authenticated, service_role;
