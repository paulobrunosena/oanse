import type { Database } from '@/types/database.types'

type TabelasFolha = Database['public']['Tables']

export type ManualFolhaRow = TabelasFolha['folha_manuais']['Row']
export type SecaoFolhaRow = TabelasFolha['folha_secoes']['Row']
export type BlocoFolhaRow = TabelasFolha['folha_blocos']['Row']
export type ItemProgressoFolhaRow = TabelasFolha['folha_item_progresso']['Row']
export type PremioProgressoFolhaRow = TabelasFolha['folha_premio_progresso']['Row']
export type ObservacaoFolhaRow = TabelasFolha['folha_observacoes']['Row']

/** Item (bolinha numerada) de um bloco; `data_conclusao` null = ainda em aberto. */
export interface ItemFolha {
  item_num: number
  data_conclusao: string | null
}

/** Bloco do manual (ex.: "Exercício bíblico 01") com os N itens e o prêmio. */
export interface BlocoFolha {
  id: string
  nome: string
  ordem: number
  quantidade: number
  premio_nome: string
  /** Sempre `quantidade` itens, numerados de 1 a N (sem registro = null). */
  itens: ItemFolha[]
  premioData: string | null
}

export interface SecaoFolha {
  id: string
  nome: string
  ordem: number
  tipo: 'itens' | 'observacoes'
  blocos: BlocoFolha[]
}

export interface ManualFolha {
  id: string
  nome: string
  ordem: number
  secoes: SecaoFolha[]
  /** Texto da seção "Observações" (vazio quando nunca preenchido). */
  observacoes: string
}

/** Catálogo do clube + progresso do oansista selecionado (linhas cruas do banco). */
export interface DadosFolhaIndividual {
  manuais: ManualFolhaRow[]
  secoes: SecaoFolhaRow[]
  blocos: BlocoFolhaRow[]
  itens?: ItemProgressoFolhaRow[]
  premios?: PremioProgressoFolhaRow[]
  observacoes?: ObservacaoFolhaRow[]
}

function porOrdem(a: { ordem: number }, b: { ordem: number }): number {
  return a.ordem - b.ordem
}

function agrupar<T, K>(itens: T[], chave: (item: T) => K): Map<K, T[]> {
  const mapa = new Map<K, T[]>()
  for (const item of itens) {
    const k = chave(item)
    const lista = mapa.get(k)
    if (lista) lista.push(item)
    else mapa.set(k, [item])
  }
  return mapa
}

function montarBloco(
  bloco: BlocoFolhaRow,
  registros: ItemProgressoFolhaRow[],
  premioData: string | null,
): BlocoFolha {
  const dataPorItem = new Map(registros.map(r => [r.item_num, r.data_conclusao]))
  return {
    id: bloco.id,
    nome: bloco.nome,
    ordem: bloco.ordem,
    quantidade: bloco.quantidade,
    premio_nome: bloco.premio_nome,
    premioData,
    itens: Array.from({ length: bloco.quantidade }, (_, i) => ({
      item_num: i + 1,
      data_conclusao: dataPorItem.get(i + 1) ?? null,
    })),
  }
}

/**
 * Normaliza o catálogo (manuais > seções > blocos) + o progresso do oansista
 * (itens concluídos, prêmio recebido e observações) na árvore `ManualFolha[]`.
 * Ordena por `ordem` em todos os níveis e abre os N slots de itens de cada bloco.
 */
export function normalizarFolhaIndividual(dados: DadosFolhaIndividual): ManualFolha[] {
  const itensPorBloco = agrupar(dados.itens ?? [], i => i.bloco_id)
  const premioPorBloco = new Map<string, string>((dados.premios ?? []).map(p => [p.bloco_id, p.data_recebimento]))
  const obsPorManual = new Map<string, string>((dados.observacoes ?? []).map(o => [o.manual_id, o.texto ?? '']))
  const blocosPorSecao = agrupar(dados.blocos, b => b.secao_id)
  const secoesPorManual = agrupar(dados.secoes, s => s.manual_id)

  return [...dados.manuais]
    .sort(porOrdem)
    .map(manual => ({
      id: manual.id,
      nome: manual.nome,
      ordem: manual.ordem,
      observacoes: obsPorManual.get(manual.id) ?? '',
      secoes: (secoesPorManual.get(manual.id) ?? [])
        .slice()
        .sort(porOrdem)
        .map(secao => ({
          id: secao.id,
          nome: secao.nome,
          ordem: secao.ordem,
          tipo: secao.tipo === 'observacoes' ? 'observacoes' : 'itens',
          blocos: (blocosPorSecao.get(secao.id) ?? [])
            .slice()
            .sort(porOrdem)
            .map(bloco => montarBloco(bloco, itensPorBloco.get(bloco.id) ?? [], premioPorBloco.get(bloco.id) ?? null)),
        })),
    }))
}

/** Quantidade de itens do bloco com data de conclusão registrada. */
export function itensConcluidos(bloco: BlocoFolha): number {
  return bloco.itens.filter(item => item.data_conclusao != null).length
}

/** Bloco concluído = todos os N itens com data de conclusão. */
export function blocoConcluido(bloco: BlocoFolha): boolean {
  return bloco.quantidade > 0 && itensConcluidos(bloco) === bloco.quantidade
}

/**
 * Libera a data do prêmio somente com o bloco completo (regra do docs/06).
 * Sem bloco completo a data já registrada permanece no estado, mas não é editável.
 */
export function premioHabilitado(bloco: BlocoFolha): boolean {
  return blocoConcluido(bloco)
}

/**
 * Rótulo curto do item derivado do nome do bloco (ex.: "Exercício bíblico 3").
 * O sufixo numérico do bloco ("Exercício bíblico 01") vira o número do item e
 * "Trilha do grau" é encurtado para "Grau" (nomes das bolinhas do manual).
 */
export function rotuloItem(nomeBloco: string, itemNum: number): string {
  const semSufixo = nomeBloco.replace(/\s*\d+\s*$/, '').trim() || nomeBloco.trim()
  const base = /^trilha\s+do\s+grau$/i.test(semSufixo) ? 'Grau' : semSufixo
  return `${base} ${itemNum}`
}
