-- ============================================================================
-- OANSE - Folha Semanal: novos itens de pontuação
--
-- - leitura_biblica (bool):         criança fez a leitura bíblica
-- - visitantes_convidados (int):    visitantes convidados no sábado
-- - secoes_sem_ajuda / com_ajuda:   substituem secoes_dia (separação de valor:
--                                   sem ajuda vale mais que com ajuda)
-- - cor_time (text, nullable):      cor do time do sábado nos jogos (pontuação
--                                   do módulo de jogos será ligada futuramente;
--                                   NULL = não participou)
-- ============================================================================

-- trigger antigo referencia secoes_dia — removê-lo antes de alterar as colunas
drop trigger if exists trg_folha_total on folhas_semanais;

alter table folhas_semanais
  add column leitura_biblica       boolean  not null default false,
  add column visitantes_convidados smallint not null default 0,
  add column secoes_sem_ajuda      smallint not null default 0,
  add column secoes_com_ajuda      smallint not null default 0,
  add column cor_time              text;

-- secoes_dia passa a ser contabilizada como "sem ajuda" e é removida
update folhas_semanais set secoes_sem_ajuda = secoes_dia where secoes_dia > 0;
alter table folhas_semanais drop column secoes_dia;

-- ============================================================================
-- Recalcula o total da folha com os novos itens
-- ============================================================================
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