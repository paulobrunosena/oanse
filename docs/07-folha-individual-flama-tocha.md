# Oanse — Folha de Progresso Individual (Flama e Tocha)

> Plano de implementação da Folha Individual para os clubes **Flama** e **Tocha**,
> reaproveitando a estrutura genérica já construída para o **Faíscas** (docs/06).
> O clube **Ursinhos** fica de fora desta etapa — difere demais dos outros três e
> será planejado separadamente.

## 1. Revisão — estrutura compartilhada (decisão)

**Conclusão: uma única estrutura compartilhada.** O Faíscas já foi construído
genérico por `clube_id` (catálogo no banco + frontend agnóstico). Faíscas, Flama
e Tocha são **estruturalmente idênticos** — variam apenas o dado (seed):

| | Faíscas | Flama | Tocha |
|---|---|---|---|
| Manuais | 3 (Saltador/Caminhante/Escalador) | 2 (Sabiá/Águia) | 2 (Carneiro/Leão) |
| Seções | Progresso, Atividades, Crédito-extra, Frequência, Observações | idem | idem |
| Blocos por manual | 12 | 12 | 12 |
| Bloco "grau" | "Trilha do grau" | "Prova do Grau" | "Prova do Grau" |
| Atividades | "Atividade 01–04" (genérico) | "Atividade Missões/Patriotismo/Meio Ambiente/Serviços" | idem Flama |
| Observações | textarea | textarea | textarea |

**Zero migration, zero tabela nova, zero código por clube.** A implementação é
**seed + um ajuste no `rotuloItem`**.

## 2. Decisões confirmadas (com o usuário)

| Tema | Decisão |
|---|---|
| Descrição dos itens | Genérica (bolinha numerada, rótulo derivado do nome do bloco) — igual ao Faíscas |
| Estrutura | Compartilhada entre os 3 clubes (catálogo por `clube_id` já existente) |
| Grafia dos prêmios | **Padronizar com o Faíscas** (minúsculas): "Distintivo do grau", "Botão vermelho 01", "Botão crédito extra", etc. |
| Seção Frequência | **1 seção com 2 blocos** (Igreja/Clube); ajustar o seed do Faíscas para ficar consistente |
| Ursinhos | Fora desta etapa |

### Prêmios canônicos (por bloco)

| Bloco | Prêmio |
|---|---|
| Prova do Grau / Trilha do grau | `Distintivo do grau` |
| Exercício Bíblico 01..04 | `Botão vermelho 01..04` |
| Atividade Missões / 01 | `Botão verde 01` |
| Atividade Patriotismo / 02 | `Botão verde 02` |
| Atividade Meio Ambiente / 03 | `Botão verde 03` |
| Atividade Serviços / 04 | `Botão verde 04` |
| Crédito Extra | `Botão crédito extra` |
| Frequência à Igreja | `Botão azul` |
| Frequência ao Clube | `Botão amarelo` |

## 3. Catálogo — Flama (2 manuais, 24 blocos, 147 itens)

| Manual | Progresso (itens) | Atividades (itens) | Crédito | Freq. Igreja | Freq. Clube |
|---|---|---|---|---|---|
| Sabiá (Ano 01) | grau 9 · EB1 9 · EB2 9 · EB3 9 · EB4 9 | Missões 4 · Patriotismo 2 · Meio Amb. 4 · Serviços 3 | 7 | 2 | 4 |
| Águia (Ano 02) | grau 9 · EB1 10 · EB2 9 · EB3 11 · EB4 11 | Missões 4 · Patriotismo 2 · Meio Amb. 4 · Serviços 3 | 7 | 2 | 4 |

Totais: Sabiá 71 itens · Águia 76 itens · 12 blocos por manual.

## 4. Catálogo — Tocha (2 manuais, 24 blocos, 170 itens)

| Manual | Progresso (itens) | Atividades (itens) | Crédito | Freq. Igreja | Freq. Clube |
|---|---|---|---|---|---|
| Carneiro (Ano 01) | grau 12 · EB1 11 · EB2 11 · EB3 12 · EB4 11 | Missões 4 · Patriotismo 3 · Meio Amb. 4 · Serviços 3 | 7 | 2 | 4 |
| Leão (Ano 02) | grau 11 · EB1 13 · EB2 11 · EB3 11 · EB4 13 | Missões 4 · Patriotismo 3 · Meio Amb. 4 · Serviços 3 | 7 | 2 | 4 |

Totais: Carneiro 84 itens · Leão 86 itens · 12 blocos por manual.

## 5. Consolidação da Frequência (ajuste no Faíscas)

Hoje o Faíscas usa **2 seções** (`Frequência na igreja`, `Frequência no clube`),
cada uma com 1 bloco. Padronizar para **1 seção `Frequência` com 2 blocos**:

- Bloco `Frequência à Igreja` (2 itens, `Botão azul`)
- Bloco `Frequência ao Clube` (4 itens, `Botão amarelo`)

Isso altera o seed do Faíscas (18 → 15 seções; 36 blocos mantidos) e deve ser
refletido em `supabase/seed.sql`, no espelho de `docs/01-schema.sql` e na tabela
de seções do `docs/06` (seção 5). Aplica-se a mesma nomenclatura nos 3 clubes.

## 6. Ajuste de código — `rotuloItem`

`src/utils/folhaIndividual.ts:150` já gera os rótulos corretos para a maioria dos
blocos (ex.: "Exercício Bíblico 1", "Atividade Missões 1", "Frequência à Igreja 1").
Falta apenas mapear "Prova do Grau" → "Grau N" (hoje o caso especial só cobre
"Trilha do grau"). Trocar o regex por:

```ts
const base = /^(trilha|prova)\s+do\s+grau$/i.test(semSufixo) ? 'Grau' : semSufixo
```

Acompanha spec novo em `folhaIndividual.spec.ts`. (Opcional, cosmético: encurtar
"Atividade Missões" → "Missões" e "Frequência à Igreja" → "Igreja" — deixar como
melhoria se não atrapalhar a legibilidade.)

## 7. Seed — `supabase/seed.sql`

Adicionar dois blocos `do $$` (padrão do Faíscas) para `flamas` e `tochas`,
com os manuais, seções e blocos das tabelas acima (12 blocos por manual).
Nome dos blocos:

- Progresso: `Prova do Grau`, `Exercício Bíblico 01..04`
- Atividades: `Atividade Missões`, `Atividade Patriotismo`, `Atividade Meio Ambiente`, `Atividade Serviços`
- Crédito-extra: `Crédito Extra`
- Frequência: `Frequência à Igreja`, `Frequência ao Clube`

## 8. Testes

- `utils/folhaIndividual.spec.ts`: novos casos do `rotuloItem` ("Prova do Grau" → "Grau N").
- Composable/componentes: **sem mudança** (já genéricos e cobertos).
- Smoke opcional (stack Supabase): `diretor.flamas@` / `diretor.tochas@` enxergando os 24 blocos de cada clube.

## 9. Ordem de execução

1. Ajustar seed do Faíscas (Frequência consolidada) em `supabase/seed.sql`.
2. Adicionar seed do Flama e do Tocha em `supabase/seed.sql`.
3. Atualizar espelho do catálogo em `docs/01-schema.sql` (Faíscas + Flama + Tocha).
4. Ajustar `rotuloItem` + spec (`src/utils/folhaIndividual.ts` / `folhaIndividual.spec.ts`).
5. `npx supabase db reset` (valida seed) — sem `gen types` (schema inalterado).
6. `npm run lint` + `npm run typecheck` + `npm run test`.
7. Docs: `docs/03-estrutura.md`, `docs/06` (tabela de seções/seed), `.agents/checklist.md`.
8. Commits convencionais em português:
   - `refactor: consolida seção Frequência do Faíscas (1 seção, 2 blocos)`
   - `feat: catálogo Folha Individual Flama`
   - `feat: catálogo Folha Individual Tocha`
   - `feat: rotuloItem reconhece "Prova do Grau"`

## Progresso

> Registrar aqui a cada passo concluído (regra do AGENTS.md: registrar + commitar).

- [ ] **Passo 1 — Seed Faíscas**: consolidar Frequência (1 seção, 2 blocos) em `supabase/seed.sql` + espelho `docs/01`.
- [ ] **Passo 2 — Seed Flama**: catálogo Sabiá/Águia (24 blocos) em `supabase/seed.sql` + espelho `docs/01`.
- [ ] **Passo 3 — Seed Tocha**: catálogo Carneiro/Leão (24 blocos) em `supabase/seed.sql` + espelho `docs/01`.
- [ ] **Passo 4 — rotuloItem**: reconhecer "Prova do Grau" + spec.
- [ ] **Passo 5 — Qualidade**: `db reset` + `lint` + `typecheck` + `test` verdes.
- [ ] **Passo 6 — Docs + checklist**: `docs/03`, `docs/06`, `.agents/checklist.md`.
