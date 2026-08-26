-- ============================================================================
-- OANSE - Folha Semanal: pontos dos jogos por COLOCAÇÃO da equipe
--
-- Antes: pontos_jogos da folha = soma dos pontos das rodadas da cor (escala
-- dos jogos: 100/70/50/40 conforme jogos_pontos_config), o que inflava o total
-- da folha semanal.
--
-- Agora: a folha pontua conforme a colocação que a EQUIPE da criança alcançou
-- no ranking dos jogos do sábado, com valores próprios da folha semanal,
-- configuráveis no módulo de configurações (itens_pontuacao):
--   jogo_1_lugar  (1º lugar)  5 pts
--   jogo_2_lugar  (2º lugar)  4 pts
--   jogo_3_lugar  (3º lugar)  3 pts
--   jogo_4_lugar  (4º lugar)  2 pts
--
-- O ranking (posicao_jogos) continua sendo a soma dos pontos das rodadas
-- (jogos_pontos_config); o que muda é o valor atribuído à folha.
-- ============================================================================

-- 1. Itens de pontuação da colocação nos jogos (editáveis pelo Diretor Geral)
insert into itens_pontuacao (chave, descricao, pontos) values
  ('jogo_1_lugar', 'Jogos do sábado: 1º lugar', 5),
  ('jogo_2_lugar', 'Jogos do sábado: 2º lugar', 4),
  ('jogo_3_lugar', 'Jogos do sábado: 3º lugar', 3),
  ('jogo_4_lugar', 'Jogos do sábado: 4º lugar', 2)
on conflict (chave) do nothing;

-- 2. Recalculo: pontos_jogos passa a vir da colocação da equipe no ranking
create or replace function fn_recalcular_pontos_jogos_encontro(p_encontro uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update folhas_semanais f
     set pontos_jogos  = coalesce(
                           (select pontos from itens_pontuacao
                             where chave = 'jogo_' || rk.posicao || '_lugar'
                               and ativo),
                           0),
         cor_time      = d.cor,
         posicao_jogos = rk.posicao
    from (
      select i.oansista_id, c.cor, c.id as cor_id
        from evento_jogos_cores_oansistas i
        join evento_jogos_cores c on c.id = i.cor_id
        join eventos_jogos ev on ev.id = c.evento_id
       where ev.encontro_id = p_encontro
       group by i.oansista_id, c.id, c.cor
    ) d
    left join (
      select t.cor_id, t.posicao
        from (
          select c.id as cor_id,
                 rank() over (partition by ev.id
                              order by coalesce(sum(r.pontos), 0) desc, c.cor) as posicao
            from evento_jogos_cores c
            join eventos_jogos ev on ev.id = c.evento_id
            left join jogo_resultados r on r.cor_id = c.id
           where ev.encontro_id = p_encontro
           group by c.id, c.cor, ev.id
        ) t
    ) rk on rk.cor_id = d.cor_id
   where f.oansista_id = d.oansista_id
     and f.encontro_id = p_encontro
     and exists (
       select 1 from presencas pr where pr.id = f.presenca_id and pr.presente
     );
end;
$$;

-- 3. Backfill: recalcula as folhas existentes com a nova regra de colocação
select fn_recalcular_pontos_jogos_encontro(encontro_id)
  from (select distinct encontro_id from folhas_semanais) e;