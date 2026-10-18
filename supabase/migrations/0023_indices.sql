-- ============================================================================
-- OANSE - Índices (auditoria de 2026-10-17, Onda 4).
--
--  1. Remove índices redundantes: eram prefixos de UNIQUE já existentes
--     (mesmas colunas, mesma ordem) — só custavam escrita.
--  2. Cria índices para FKs sem cobertura (custo em joins, cascatas e no
--     DELETE do diretor) — destaque para eventos_jogos.encontro_id, que ficou
--     sem índice quando a 0012 removeu o UNIQUE.
--  3. Painel de pendências: índice composto (status, clube, data) para o filtro
--     + ordenação da tela (substitui o antigo só de status).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Redundantes (prefixo de UNIQUE)
-- ----------------------------------------------------------------------------
drop index if exists idx_presencas_encontro;         -- unique (encontro_id, oansista_id)
drop index if exists idx_folhas_encontro;            -- unique (encontro_id, oansista_id)
drop index if exists idx_visitas_visitante;          -- unique (visitante_id, numero)
drop index if exists idx_jogos_catalogo_clube;       -- unique (clube_id, nome)
drop index if exists idx_evento_jogos_clubes_evento; -- unique (evento_id, clube_id)
drop index if exists idx_evento_jogos_cores_evento;  -- unique (evento_id, cor)
drop index if exists idx_evento_cores_oansistas_cor; -- unique (cor_id, oansista_id)
drop index if exists idx_jogo_resultados_jogo;       -- unique (jogo_id, cor_id)
drop index if exists idx_folha_manuais_clube;        -- unique (clube_id, nome)
drop index if exists idx_folha_secoes_manual;        -- unique (manual_id, ordem)
drop index if exists idx_folha_blocos_secao;         -- unique (secao_id, ordem)
drop index if exists idx_folha_item_prog_oansista;   -- unique (oansista_id, bloco_id, item_num)
drop index if exists idx_folha_premio_prog_oansista; -- unique (oansista_id, bloco_id)
drop index if exists idx_folha_observacoes_oansista; -- unique (oansista_id, manual_id)

-- Legado: a tabela progresso_manual foi removida na 0015; o índice caiu junto.
drop index if exists idx_progresso_oansista;
-- Legado: jogos.encontro_id deixou de existir na 0009/0011.
drop index if exists idx_jogos_encontro;

-- ----------------------------------------------------------------------------
-- 2. FKs sem cobertura
-- ----------------------------------------------------------------------------
create index if not exists idx_eventos_jogos_encontro        on eventos_jogos(encontro_id);
create index if not exists idx_presencas_oansista            on presencas(oansista_id);
create index if not exists idx_transferencias_oansista       on transferencias(oansista_id);
create index if not exists idx_premios_mov_premio            on premios_movimentacoes(premio_id);
create index if not exists idx_premios_mov_feito_por         on premios_movimentacoes(feito_por);
create index if not exists idx_premios_pendentes_bloco       on premios_pendentes(bloco_id);
create index if not exists idx_folha_blocos_premio           on folha_blocos(premio_id);
create index if not exists idx_folha_premio_prog_bloco       on folha_premio_progresso(bloco_id);
create index if not exists idx_folha_observacoes_manual      on folha_observacoes(manual_id);
create index if not exists idx_profiles_clube                on profiles(clube_id);
create index if not exists idx_remanejamentos_encontro       on remanejamentos_temporarios(encontro_id);
create index if not exists idx_evento_jogos_clubes_clube     on evento_jogos_clubes(clube_id);
create index if not exists idx_jogo_resultados_cor           on jogo_resultados(cor_id);
create index if not exists idx_evento_cores_oansistas_aluno  on evento_jogos_cores_oansistas(oansista_id);
create index if not exists idx_visitantes_indicado           on visitantes(indicado_por);

-- ----------------------------------------------------------------------------
-- 3. Painel de pendências: filtro (status, clube) + ordenação por data
-- ----------------------------------------------------------------------------
drop index if exists idx_pendencias_status;
create index if not exists idx_pendencias_status_clube_data
  on premios_pendentes(status, clube_id, data_geracao desc);
