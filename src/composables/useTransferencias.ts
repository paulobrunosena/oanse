import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { apiFetch } from '@/lib/api'

export interface OansistaTransferencia {
  id: string
  nome: string
  turma_id: string | null
  turma_nome: string | null
}

export interface TurmaOpcao {
  id: string
  nome: string
  lider_id: string
}

export interface HistoricoTransferencia {
  id: string
  data: string
  motivo: string | null
  oansista_nome: string | null
  origem_nome: string | null
  destino_nome: string | null
}

/**
 * Transferências permanentes (Diretor de Clube): move o oansista entre turmas
 * do próprio clube gravando histórico. A operação é atômica na RPC
 * fn_transferir_oansista via /api/transferencias.
 */
export function useTransferencias() {
  const oansistas = ref<OansistaTransferencia[]>([])
  const turmas = ref<TurmaOpcao[]>([])
  const historico = ref<HistoricoTransferencia[]>([])
  const carregando = ref(false)

  async function carregar(clubeId: string) {
    carregando.value = true
    const [rOansistas, rTurmas, rHistorico] = await Promise.all([
      supabase.from('oansistas')
        .select('id, nome, turma_id, turma:turmas!oansistas_turma_id_fkey(nome)')
        .eq('clube_id', clubeId)
        .eq('status', 'ativo')
        .order('nome'),
      supabase.from('turmas')
        .select('id, nome, lider_id')
        .eq('clube_id', clubeId)
        .eq('ativo', true)
        .order('nome'),
      supabase.from('transferencias')
        .select(`
          id, data, motivo,
          oansista:oansistas(nome),
          origem:turmas!transferencias_turma_origem_id_fkey(nome),
          destino:turmas!transferencias_turma_destino_id_fkey(nome)
        `)
        .order('created_at', { ascending: false })
        .limit(50),
    ])
    oansistas.value = (rOansistas.data ?? []).map(o => ({
      id: o.id,
      nome: o.nome,
      turma_id: o.turma_id,
      turma_nome: (o.turma as unknown as { nome: string } | null)?.nome ?? null,
    }))
    turmas.value = rTurmas.data ?? []
    historico.value = (rHistorico.data ?? []).map(t => ({
      id: t.id,
      data: t.data,
      motivo: t.motivo,
      oansista_nome: (t.oansista as unknown as { nome: string } | null)?.nome ?? null,
      origem_nome: (t.origem as unknown as { nome: string } | null)?.nome ?? null,
      destino_nome: (t.destino as unknown as { nome: string } | null)?.nome ?? null,
    }))
    carregando.value = false
  }

  async function transferir(
    oansistaId: string,
    turmaDestinoId: string,
    motivo: string | null,
  ): Promise<void> {
    try {
      await apiFetch('/api/transferencias', {
        method: 'POST',
        body: { oansista_id: oansistaId, turma_destino_id: turmaDestinoId, motivo },
      })
    }
    catch (e) {
      throw new Error(
        (e as { statusMessage?: string })?.statusMessage ?? 'Erro ao transferir',
        { cause: e },
      )
    }
  }

  return { oansistas, turmas, historico, carregando, carregar, transferir }
}
