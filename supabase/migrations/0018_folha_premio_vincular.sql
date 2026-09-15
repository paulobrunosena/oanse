-- Vínculo do bloco da Folha Individual com o catálogo de prêmios (Fase 3).
-- O bloco passa a apontar para o prêmio real do estoque da secretaria
-- (premios), permitindo gerar pendência e dar baixa de estoque na entrega.
-- O texto livre premio_nome continua existindo (exibição/fallback).

alter table folha_blocos
  add column premio_id uuid references premios(id);

-- Catálogo de prêmios sem duplicatas de nome (o nome é a chave de integração
-- usada no seed/backfill de folha_blocos.premio_id).
create unique index idx_premios_nome on premios(nome);
