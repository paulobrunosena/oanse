// @vitest-environment node
import { describe, expect, it } from 'vitest'
import {
  blocoConcluido,
  itensConcluidos,
  normalizarFolhaIndividual,
  premioHabilitado,
  rotuloItem,
  secaoItensConcluidos,
  secaoTotalItens,
  type BlocoFolha,
  type BlocoFolhaRow,
  type ItemProgressoFolhaRow,
  type ManualFolhaRow,
  type ObservacaoFolhaRow,
  type PremioProgressoFolhaRow,
  type SecaoFolha,
  type SecaoFolhaRow,
} from './folhaIndividual'

function manualRow(over: Partial<ManualFolhaRow> & { id: string }): ManualFolhaRow {
  return { clube_id: 'clube-faiscas', created_at: '2026-09-01T00:00:00Z', nome: 'Manual', ordem: 1, ...over }
}

function secaoRow(over: Partial<SecaoFolhaRow> & { id: string, manual_id: string }): SecaoFolhaRow {
  return { nome: 'Seção', ordem: 1, tipo: 'itens', ...over }
}

function blocoRow(over: Partial<BlocoFolhaRow> & { id: string, secao_id: string }): BlocoFolhaRow {
  return { nome: 'Bloco', ordem: 1, quantidade: 1, premio_nome: 'Prêmio', premio_id: null, ...over }
}

function itemRow(over: Partial<ItemProgressoFolhaRow> & { bloco_id: string, item_num: number }): ItemProgressoFolhaRow {
  return {
    id: `item-${over.bloco_id}-${over.item_num}`,
    created_at: '2026-09-01T00:00:00Z',
    data_conclusao: '2026-09-01',
    oansista_id: 'oansista-1',
    registrado_por: 'profile-1',
    ...over,
  }
}

function premioRow(over: Partial<PremioProgressoFolhaRow> & { bloco_id: string }): PremioProgressoFolhaRow {
  return {
    id: `premio-${over.bloco_id}`,
    created_at: '2026-09-01T00:00:00Z',
    data_recebimento: '2026-09-01',
    oansista_id: 'oansista-1',
    registrado_por: 'profile-1',
    ...over,
  }
}

function observacaoRow(over: Partial<ObservacaoFolhaRow> & { id: string, manual_id: string }): ObservacaoFolhaRow {
  return { oansista_id: 'oansista-1', texto: null, updated_at: '2026-09-01T00:00:00Z', ...over }
}

function blocoFolha(over: Partial<BlocoFolha>): BlocoFolha {
  return {
    id: 'bloco-1',
    nome: 'Exercício bíblico 01',
    ordem: 1,
    quantidade: 3,
    premio_nome: 'Botão vermelho 01',
    itens: [],
    premioData: null,
    ...over,
  }
}

describe('normalizarFolhaIndividual', () => {
  it('monta a árvore ordenada por ordem, abre os N itens e associa prêmio e observações', () => {
    const manuais = normalizarFolhaIndividual({
      manuais: [
        manualRow({ id: 'm-caminhante', nome: 'Caminhante', ordem: 2 }),
        manualRow({ id: 'm-saltador', nome: 'Saltador', ordem: 1 }),
      ],
      secoes: [
        secaoRow({ id: 's-obs', manual_id: 'm-saltador', nome: 'Observações', ordem: 2, tipo: 'observacoes' }),
        secaoRow({ id: 's-progresso', manual_id: 'm-saltador', nome: 'Progresso', ordem: 1 }),
      ],
      blocos: [
        blocoRow({ id: 'b-exercicio-2', secao_id: 's-progresso', nome: 'Exercício bíblico 02', ordem: 2, quantidade: 1 }),
        blocoRow({ id: 'b-exercicio-1', secao_id: 's-progresso', nome: 'Exercício bíblico 01', ordem: 1, quantidade: 3, premio_nome: 'Botão vermelho 01' }),
      ],
      itens: [
        itemRow({ bloco_id: 'b-exercicio-1', item_num: 3, data_conclusao: '2026-09-02' }),
        itemRow({ bloco_id: 'b-exercicio-1', item_num: 1, data_conclusao: '2026-09-01' }),
        itemRow({ bloco_id: 'b-exercicio-1', item_num: 4, data_conclusao: '2026-09-03' }),
      ],
      premios: [premioRow({ bloco_id: 'b-exercicio-1', data_recebimento: '2026-09-05' })],
      observacoes: [observacaoRow({ id: 'o-1', manual_id: 'm-saltador', texto: 'Falta decorar o versículo.' })],
    })

    expect(manuais.map(m => m.nome)).toEqual(['Saltador', 'Caminhante'])
    expect(manuais[1].secoes).toEqual([])
    expect(manuais[1].observacoes).toBe('')

    const saltador = manuais[0]
    expect(saltador.observacoes).toBe('Falta decorar o versículo.')
    expect(saltador.secoes.map(s => s.nome)).toEqual(['Progresso', 'Observações'])
    expect(saltador.secoes[1]).toMatchObject({ tipo: 'observacoes', blocos: [] })

    const progresso = saltador.secoes[0]
    expect(progresso.blocos.map(b => b.nome)).toEqual(['Exercício bíblico 01', 'Exercício bíblico 02'])
    expect(progresso.blocos[0]).toEqual({
      id: 'b-exercicio-1',
      nome: 'Exercício bíblico 01',
      ordem: 1,
      quantidade: 3,
      premio_nome: 'Botão vermelho 01',
      premioData: '2026-09-05',
      itens: [
        { item_num: 1, data_conclusao: '2026-09-01' },
        { item_num: 2, data_conclusao: null },
        { item_num: 3, data_conclusao: '2026-09-02' },
      ],
    })
    expect(progresso.blocos[1].premioData).toBeNull()
  })

  it('aceita apenas o catálogo (sem progresso) e abre todos os itens em aberto', () => {
    const manuais = normalizarFolhaIndividual({
      manuais: [manualRow({ id: 'm-saltador' })],
      secoes: [secaoRow({ id: 's-progresso', manual_id: 'm-saltador' })],
      blocos: [blocoRow({ id: 'b-1', secao_id: 's-progresso', quantidade: 2 })],
    })

    expect(manuais[0].secoes[0].blocos[0]).toMatchObject({
      premioData: null,
      itens: [
        { item_num: 1, data_conclusao: null },
        { item_num: 2, data_conclusao: null },
      ],
    })
  })

  it('ignora seções, blocos e progresso órfãos (fora do catálogo recebido)', () => {
    const manuais = normalizarFolhaIndividual({
      manuais: [manualRow({ id: 'm-saltador' })],
      secoes: [
        secaoRow({ id: 's-progresso', manual_id: 'm-saltador' }),
        secaoRow({ id: 's-orfa', manual_id: 'm-orfao' }),
      ],
      blocos: [
        blocoRow({ id: 'b-1', secao_id: 's-progresso' }),
        blocoRow({ id: 'b-orfao-2', secao_id: 's-orfa' }),
      ],
      itens: [itemRow({ bloco_id: 'b-orfao', item_num: 1 })],
      premios: [premioRow({ bloco_id: 'b-orfao' })],
      observacoes: [observacaoRow({ id: 'o-1', manual_id: 'm-orfao', texto: 'x' })],
    })

    expect(manuais).toHaveLength(1)
    expect(manuais[0].secoes).toHaveLength(1)
    expect(manuais[0].secoes[0].blocos).toHaveLength(1)
    expect(manuais[0].secoes[0].blocos[0].premioData).toBeNull()
    expect(manuais[0].observacoes).toBe('')
  })
})

describe('itensConcluidos', () => {
  it('conta apenas os itens com data de conclusão', () => {
    const bloco = blocoFolha({
      itens: [
        { item_num: 1, data_conclusao: '2026-09-01' },
        { item_num: 2, data_conclusao: null },
        { item_num: 3, data_conclusao: '2026-09-02' },
      ],
    })
    expect(itensConcluidos(bloco)).toBe(2)
  })

  it('retorna 0 quando nenhum item foi concluído', () => {
    expect(itensConcluidos(blocoFolha({ itens: [] }))).toBe(0)
  })
})

describe('blocoConcluido', () => {
  it('é falso com o bloco parcial', () => {
    const bloco = blocoFolha({
      itens: [
        { item_num: 1, data_conclusao: '2026-09-01' },
        { item_num: 2, data_conclusao: null },
      ],
    })
    expect(blocoConcluido(bloco)).toBe(false)
  })

  it('é verdadeiro com todos os itens concluídos', () => {
    const bloco = blocoFolha({
      itens: [
        { item_num: 1, data_conclusao: '2026-09-01' },
        { item_num: 2, data_conclusao: '2026-09-02' },
        { item_num: 3, data_conclusao: '2026-09-03' },
      ],
    })
    expect(blocoConcluido(bloco)).toBe(true)
  })

  it('vale para bloco de 1 item', () => {
    expect(blocoConcluido(blocoFolha({ quantidade: 1, itens: [{ item_num: 1, data_conclusao: '2026-09-01' }] }))).toBe(true)
    expect(blocoConcluido(blocoFolha({ quantidade: 1, itens: [] }))).toBe(false)
  })
})

describe('secaoItensConcluidos', () => {
  it('soma os itens concluídos de todos os blocos da seção', () => {
    const secao: SecaoFolha = {
      id: 's1',
      nome: 'Progresso',
      ordem: 1,
      tipo: 'itens',
      blocos: [
        blocoFolha({
          itens: [
            { item_num: 1, data_conclusao: '2026-09-01' },
            { item_num: 2, data_conclusao: null },
          ],
        }),
        blocoFolha({
          quantidade: 3,
          itens: [
            { item_num: 1, data_conclusao: '2026-09-01' },
            { item_num: 2, data_conclusao: '2026-09-02' },
            { item_num: 3, data_conclusao: null },
          ],
        }),
      ],
    }
    expect(secaoItensConcluidos(secao)).toBe(3)
  })

  it('retorna 0 em seção de observações (sem blocos)', () => {
    const secao: SecaoFolha = { id: 's2', nome: 'Observações', ordem: 2, tipo: 'observacoes', blocos: [] }
    expect(secaoItensConcluidos(secao)).toBe(0)
  })
})

describe('secaoTotalItens', () => {
  it('soma a quantidade de itens de todos os blocos da seção', () => {
    const secao: SecaoFolha = {
      id: 's1',
      nome: 'Progresso',
      ordem: 1,
      tipo: 'itens',
      blocos: [
        blocoFolha({ quantidade: 2 }),
        blocoFolha({ quantidade: 3 }),
      ],
    }
    expect(secaoTotalItens(secao)).toBe(5)
  })

  it('retorna 0 em seção de observações (sem blocos)', () => {
    const secao: SecaoFolha = { id: 's2', nome: 'Observações', ordem: 2, tipo: 'observacoes', blocos: [] }
    expect(secaoTotalItens(secao)).toBe(0)
  })
})

describe('premioHabilitado', () => {
  it('libera a data do prêmio somente com o bloco completo', () => {
    const parcial = blocoFolha({
      itens: [
        { item_num: 1, data_conclusao: '2026-09-01' },
        { item_num: 2, data_conclusao: null },
      ],
    })
    const completo = blocoFolha({
      itens: [
        { item_num: 1, data_conclusao: '2026-09-01' },
        { item_num: 2, data_conclusao: '2026-09-02' },
        { item_num: 3, data_conclusao: '2026-09-03' },
      ],
    })

    expect(premioHabilitado(parcial)).toBe(false)
    expect(premioHabilitado(completo)).toBe(true)
  })
})

describe('rotuloItem', () => {
  it('remove o sufixo numérico do bloco e concatena o número do item', () => {
    expect(rotuloItem('Exercício bíblico 01', 3)).toBe('Exercício bíblico 3')
    expect(rotuloItem('Atividade 02', 1)).toBe('Atividade 1')
  })

  it('encurta "Trilha do grau" para "Grau"', () => {
    expect(rotuloItem('Trilha do grau', 2)).toBe('Grau 2')
  })

  it('encurta "Prova do Grau" para "Grau"', () => {
    expect(rotuloItem('Prova do Grau', 1)).toBe('Grau 1')
  })

  it('mantém o nome do bloco quando não há sufixo numérico', () => {
    expect(rotuloItem('Crédito extra', 5)).toBe('Crédito extra 5')
    expect(rotuloItem('Frequência à Igreja', 1)).toBe('Frequência à Igreja 1')
  })
})
