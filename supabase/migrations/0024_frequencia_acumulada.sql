-- ============================================================================
-- OANSE - Relatório de frequência acumulada (Fase 4)
-- Conta presenças/faltas por oansista num período de sábados (encontros.data),
-- com o mesmo escopo da RLS de presencas:
--   diretor_geral / secretaria -> todos os clubes
--   diretor_clube              -> apenas o próprio clube
--   lider                      -> apenas a própria turma (titular)
-- RPC security definer (como fn_ranking_do_encontro), autorização validada
-- dentro da função (não depende da RLS das tabelas base).
-- ============================================================================

create or replace function fn_frequencia_acumulada(p_de date, p_ate date)
returns table (
  oansista_id     uuid,
  oansista_nome   text,
  clube_nome      text,
  turma_nome      text,
  presencas       bigint,
  faltas          bigint,
  total_encontros bigint
) language sql stable security definer set search_path = public as $$
  select
    o.id,
    o.nome,
    c.nome,
    coalesce(t.nome, ''),
    count(*) filter (where p.presente)      as presencas,
    count(*) filter (where not p.presente)  as faltas,
    count(*)                                as total_encontros
  from presencas p
  join encontros e on e.id = p.encontro_id
  join oansistas o on o.id = p.oansista_id
  join clubes c    on c.id = o.clube_id
  left join turmas t on t.id = o.turma_id
  where e.data between p_de and p_ate
    and (
      fn_role() in ('diretor_geral', 'secretaria')
      or (fn_role() = 'diretor_clube' and o.clube_id = fn_clube_id())
      or (fn_role() = 'lider' and exists (
            select 1 from turmas tt
            where tt.id = o.turma_id and tt.lider_id = auth.uid()
          ))
    )
  group by o.id, o.nome, c.nome, t.nome
  order by c.nome, o.nome;
$$;

grant execute on function fn_frequencia_acumulada(date, date) to authenticated;
