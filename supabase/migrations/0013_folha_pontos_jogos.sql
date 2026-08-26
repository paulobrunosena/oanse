-- ============================================================================
-- OANSE - Folha Semanal: pontuação de jogos automática + posição no ranking
--
-- A folha semanal passa a exibir (somente leitura) os dados dos jogos:
--   cor_time      - cor em que a criança participou no evento de jogos
--   pontos_jogos  - soma dos pontos das rodadas da cor da criança
--   posicao_jogos - posição da cor da criança no ranking do evento (novo)
--
-- A propagação deixa de depender apenas de mudanças em jogo_resultados:
-- também roda quando a folha é criada (após o líder marcar a presença) e
-- quando a presença é alternada, garantindo que a cor, a posição e os pontos
-- dos jogos apareçam na folha assim que o líder abre a folha semanal,
-- independentemente da ordem dos lançamentos (jogos antes ou depois da folha).
-- ============================================================================

-- 1. Nova coluna de posição no ranking dos jogos (NULL = não participou)
alter table folhas_semanais add column posicao_jogos smallint;

-- 2. Função que recalcula pontos_jogos/cor_time/posicao_jogos de um encontro
create or replace function fn_recalcular_pontos_jogos_encontro(p_encontro uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update folhas_semanais f
     set pontos_jogos  = coalesce(d.pontos, 0),
         cor_time      = d.cor,
         posicao_jogos = rk.posicao
    from (
      select i.oansista_id, c.cor, c.id as cor_id, coalesce(sum(r.pontos), 0) as pontos
        from evento_jogos_cores_oansistas i
        join evento_jogos_cores c on c.id = i.cor_id
        join eventos_jogos ev on ev.id = c.evento_id
        left join jogo_resultados r on r.cor_id = c.id
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

-- 3. Triggers que chamam o recálculo por encontro

-- 3.1 Rodada/resultado lançado, alterado ou removido (substitui o trigger antigo)
drop trigger if exists trg_propagar_pontos_jogos on jogo_resultados;
drop function if exists fn_propagar_pontos_jogos();

create or replace function fn_propagar_pontos_jogos()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_encontro uuid;
begin
  if TG_OP = 'DELETE' then
    select ev.encontro_id into v_encontro
      from jogos j join eventos_jogos ev on ev.id = j.evento_id
     where j.id = old.jogo_id;
  else
    select ev.encontro_id into v_encontro
      from jogos j join eventos_jogos ev on ev.id = j.evento_id
     where j.id = new.jogo_id;
  end if;

  if v_encontro is not null then
    perform fn_recalcular_pontos_jogos_encontro(v_encontro);
  end if;
  return null;
end;
$$;

create trigger trg_propagar_pontos_jogos
  after insert or update or delete on jogo_resultados
  for each row execute function fn_propagar_pontos_jogos();

-- 3.2 Criança entra/sai/troca de cor no evento
create or replace function fn_propagar_pontos_jogos_integrantes()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_encontro uuid;
  v_cor_id  uuid;
begin
  if TG_OP = 'DELETE' then
    v_cor_id := old.cor_id;
  else
    v_cor_id := new.cor_id;
  end if;

  select ev.encontro_id into v_encontro
    from evento_jogos_cores c
    join eventos_jogos ev on ev.id = c.evento_id
   where c.id = v_cor_id;

  if v_encontro is not null then
    perform fn_recalcular_pontos_jogos_encontro(v_encontro);
  end if;
  return null;
end;
$$;

create trigger trg_propagar_pontos_jogos_integrantes
  after insert or update or delete on evento_jogos_cores_oansistas
  for each row execute function fn_propagar_pontos_jogos_integrantes();

-- 3.3 Folha criada depois dos jogos / presença alternada (presente <=> falta)
create or replace function fn_propagar_pontos_jogos_por_folha()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform fn_recalcular_pontos_jogos_encontro(new.encontro_id);
  return null;
end;
$$;

create trigger trg_folha_pontos_jogos_inserir
  after insert on folhas_semanais
  for each row execute function fn_propagar_pontos_jogos_por_folha();

create trigger trg_folha_pontos_jogos_presenca
  after update of presenca_id on folhas_semanais
  for each row execute function fn_propagar_pontos_jogos_por_folha();

-- 4. Ausente também zera a posição nos jogos (RN 1: total do dia zerado)
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
    new.posicao_jogos         := null;
    new.total                 := 0;
    return new;
  end if;

  select pontos into p_presenca       from itens_pontuacao where chave = 'presenca'       and ativo;
  select pontos into p_uniforme       from itens_pontuacao where chave = 'uniforme'       and ativo;
  select pontos into p_biblia         from itens_pontuacao where chave = 'biblia'         and ativo;
  select pontos into p_ebd            from itens_pontuacao where chave = 'ebd'            and ativo;
  select pontos into p_manual         from itens_pontuacao where chave = 'manual'         and ativo;
  select pontos into p_conduta        from itens_pontuacao where chave = 'conduta'        and ativo;
  select pontos into p_leitura        from itens_pontuacao where chave = 'leitura_biblica' and ativo;
  select pontos into p_visitante_unit from itens_pontuacao where chave = 'visitante'      and ativo;
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

drop trigger if exists trg_folha_total on folhas_semanais;
create trigger trg_folha_total
  before insert or update of presenca_id, uniforme, biblia, ebd, manual, conduta,
                          leitura_biblica, visitantes_convidados, secoes_sem_ajuda,
                          secoes_com_ajuda, cor_time, atividade_extra, pontos_jogos
  on folhas_semanais
  for each row execute function fn_calcular_total_folha();

-- 5. Backfill: limpa a cor manual antiga de quem não está em evento de jogos
-- (a cor passa a ser controlada exclusivamente pelo módulo de jogos)
update folhas_semanais f
   set cor_time = null
  where exists (
    select 1 from presencas pr
     where pr.id = f.presenca_id and pr.presente
  )
    and not exists (
      select 1 from evento_jogos_cores_oansistas i
      join evento_jogos_cores c on c.id = i.cor_id
      join eventos_jogos ev on ev.id = c.evento_id
       where ev.encontro_id = f.encontro_id
         and i.oansista_id = f.oansista_id
    );