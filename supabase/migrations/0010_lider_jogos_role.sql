-- ============================================================================
-- OANSE - Novo perfil "líder de jogos"
--
-- Migration separada porque um valor de enum recém-criado não pode ser usado
-- dentro da mesma transação em que foi adicionado (SQLSTATE 55P04). A migration
-- seguinte (0011_jogos_eventos.sql) já utiliza 'lider_jogos' nas policies RLS.
-- ============================================================================

alter type user_role add value if not exists 'lider_jogos';