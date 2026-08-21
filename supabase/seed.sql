-- ============================================================================
-- OANSE - Seed local: clubes, itens de pontuação e config de jogos.
-- Aplicado automaticamente após as migrations por `npx supabase db reset`.
-- ============================================================================

insert into clubes (nome, slug, idade_min, idade_max, cor, ordem) values
  ('Ursinhos', 'ursinhos', 4, 5, '#8B5CF6', 1),
  ('Faíscas',  'faiscas',  6, 8, '#F59E0B', 2),
  ('Flamas',   'flamas',   9, 10, '#EF4444', 3),
  ('Tochas',   'tochas',   11, 12, '#3B82F6', 4);

insert into itens_pontuacao (chave, descricao, pontos) values
  ('presenca',     'Presença no sábado',           10),
  ('uniforme',     'Está com o uniforme',          10),
  ('biblia',       'Trouxe a Bíblia',              10),
  ('ebd',          'Participou da EBD',            10),
  ('manual',       'Trouxe o manual',              10),
  ('conduta',      'Boa conduta no clube',         10),
  ('secao_manual', 'Por seção do manual concluída', 5);

insert into jogos_pontos_config (colocacao, pontos) values
  (1, 100), (2, 70), (3, 50), (4, 40);
