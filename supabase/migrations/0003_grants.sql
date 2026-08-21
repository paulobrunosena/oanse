-- ============================================================================
-- OANSE - Grants de privilégio para os papéis do Supabase (anon não usa API).
-- RLS (0002) continua sendo a fonte da verdade sobre QUAIS linhas cada perfil
-- acessa; aqui apenas habilitamos as operações (Postgres exige os dois níveis).
-- ============================================================================

-- Profiles/tabelas do app: authenticated opera, service_role (server/api) tudo
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to service_role;

grant usage, select on all sequences in schema public to authenticated, service_role;

-- Pendências de prêmios: leitura + atualização de status pela Secretaria;
-- INSERT acontece apenas via trigger (security definer) — negado ao cliente.
revoke insert, delete on premios_pendentes from authenticated;
